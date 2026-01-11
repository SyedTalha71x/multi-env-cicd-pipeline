#!/bin/bash

ENVIRONMENT=${1:-dev}
APP_NAME="multi-env-cicd-app"

# Get AWS credentials from environment or parameters
AWS_ACCOUNT_ID=${2:-$AWS_ACCOUNT_ID}
AWS_REGION=${3:-$AWS_REGION}
GITHUB_SHA=${4:-$GITHUB_SHA}

echo "Starting rollback for $ENVIRONMENT environment"
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"

# Validate AWS credentials
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
    echo "❌ ERROR: AWS_ACCOUNT_ID or AWS_REGION not set"
    echo "Usage: $0 <environment> [aws_account_id] [aws_region] [github_sha]"
    exit 1
fi

CONTAINER_NAME="${APP_NAME}-${ENVIRONMENT}"
IMAGE_PREFIX="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}"

# Check if container exists and get current image
CURRENT_IMAGE=$(docker ps -a --filter "name=${CONTAINER_NAME}" --format "{{.Image}}" | head -1)

if [ -z "$CURRENT_IMAGE" ]; then
    echo "❌ No container found for ${CONTAINER_NAME}"
    echo "Checking all containers:"
    docker ps -a
    exit 1
fi

echo "Current image: $CURRENT_IMAGE"

# Get current image tag
CURRENT_TAG=$(echo "$CURRENT_IMAGE" | cut -d: -f2)

# Get all available images for this app (excluding current)
PREVIOUS_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | \
    grep "^${IMAGE_PREFIX}:" | \
    grep -v ":${CURRENT_TAG}$" | \
    sort -r)  # Sort to get newest first

if [ -z "$PREVIOUS_IMAGES" ]; then
    echo "❌ No previous image found for rollback"
    echo "Available images:"
    docker images | grep "${IMAGE_PREFIX}" || echo "None"
    exit 1
fi

# Get the most recent previous image
PREVIOUS_IMAGE=$(echo "$PREVIOUS_IMAGES" | head -1)
PREVIOUS_TAG=$(echo "$PREVIOUS_IMAGE" | cut -d: -f2)

echo "Rolling back from ${CURRENT_TAG} to: ${PREVIOUS_TAG}"

# Login to ECR first (needs AWS credentials in environment)
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Pull the previous image
echo "Pulling rollback image: $PREVIOUS_IMAGE"
docker pull "$PREVIOUS_IMAGE"

# Stop and remove current container
echo "Stopping current container..."
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

# Determine which .env file to use
PROJECT_DIR="/home/ubuntu/multi-env-cicd-pipeline"
ENV_FILE="${PROJECT_DIR}/.env.${ENVIRONMENT}"
[ ! -f "$ENV_FILE" ] && ENV_FILE="${PROJECT_DIR}/.env"

# Run previous container
echo "Starting rollback container..."
if [ -f "$ENV_FILE" ]; then
    docker run -d \
      --name ${CONTAINER_NAME} \
      --restart always \
      -p 3000:3000 \
      --env-file "$ENV_FILE" \
      -e NODE_ENV=${ENVIRONMENT} \
      -e APP_VERSION=${PREVIOUS_TAG} \
      ${PREVIOUS_IMAGE}
else
    docker run -d \
      --name ${CONTAINER_NAME} \
      --restart always \
      -p 3000:3000 \
      -e NODE_ENV=${ENVIRONMENT} \
      -e APP_VERSION=${PREVIOUS_TAG} \
      ${PREVIOUS_IMAGE}
fi

echo "✅ Rollback completed successfully to version: $PREVIOUS_TAG"

# Optional Slack notification (if SLACK_WEBHOOK_URL is set)
if [ ! -z "${SLACK_WEBHOOK_URL}" ]; then
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"🚨 Rollback triggered for $ENVIRONMENT environment. Reverted from \`$CURRENT_TAG\` to \`$PREVIOUS_TAG\`\"}" \
      ${SLACK_WEBHOOK_URL} 2>/dev/null || echo "Slack notification skipped"
fi