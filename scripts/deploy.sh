#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
AWS_ACCOUNT_ID=${2:-$AWS_ACCOUNT_ID}
AWS_REGION=${3:-$AWS_REGION}
GITHUB_SHA=${4:-$GITHUB_SHA}

APP_NAME="multi-env-cicd-app"

# Validate required variables
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "ERROR: AWS_ACCOUNT_ID is not set"
    echo "Usage: $0 <environment> <aws_account_id> <aws_region> <github_sha>"
    exit 1
fi

if [ -z "$AWS_REGION" ]; then
    echo "ERROR: AWS_REGION is not set"
    exit 1
fi

if [ -z "$GITHUB_SHA" ]; then
    echo "ERROR: GITHUB_SHA is not set"
    exit 1
fi

DOCKER_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}:${GITHUB_SHA}"

echo "Starting deployment to ${ENVIRONMENT} environment"
echo "AWS Account: ${AWS_ACCOUNT_ID}"
echo "AWS Region: ${AWS_REGION}"
echo "Docker image: ${DOCKER_IMAGE}"
echo "Commit SHA: ${GITHUB_SHA}"

# Login to ECR (needs AWS credentials in environment)
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Pull the image
echo "Pulling image: ${DOCKER_IMAGE}"
docker pull ${DOCKER_IMAGE}

# Stop and remove old container
echo "Stopping old container..."
docker stop ${APP_NAME}-${ENVIRONMENT} 2>/dev/null || true
docker rm ${APP_NAME}-${ENVIRONMENT} 2>/dev/null || true

# Determine which .env file to use
PROJECT_DIR="/home/ubuntu/multi-env-cicd-pipeline"
ENV_FILE="${PROJECT_DIR}/.env.${ENVIRONMENT}"

# Check if environment-specific .env file exists
if [ ! -f "$ENV_FILE" ]; then
    ENV_FILE="${PROJECT_DIR}/.env"
    echo "Using default .env file"
else
    echo "Using environment-specific .env file: $ENV_FILE"
fi

# Verify .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "WARNING: .env file not found at $ENV_FILE"
    echo "Container will run without environment variables from .env file"
fi

# Run new container with .env file
echo "Starting new container..."
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from: $ENV_FILE"
    docker run -d \
      --name ${APP_NAME}-${ENVIRONMENT} \
      --restart always \
      -p 3000:3000 \
      --env-file "$ENV_FILE" \
      -e NODE_ENV=${ENVIRONMENT} \
      -e APP_VERSION=${GITHUB_SHA} \
      ${DOCKER_IMAGE}
else
    echo "Starting container without .env file"
    docker run -d \
      --name ${APP_NAME}-${ENVIRONMENT} \
      --restart always \
      -p 3000:3000 \
      -e NODE_ENV=${ENVIRONMENT} \
      -e APP_VERSION=${GITHUB_SHA} \
      ${DOCKER_IMAGE}
fi

echo "Deployment completed for $ENVIRONMENT"