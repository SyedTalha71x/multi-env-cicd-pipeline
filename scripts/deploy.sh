#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
APP_NAME="multi-env-cicd-app"

# Set default values if not provided
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-}
AWS_REGION=${AWS_REGION:-us-east-1}
GITHUB_SHA=${GITHUB_SHA:-latest}

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "ERROR: AWS_ACCOUNT_ID is not set"
    exit 1
fi

if [ -z "$AWS_REGION" ]; then
    echo "ERROR: AWS_REGION is not set"
    exit 1
fi

DOCKER_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}:${GITHUB_SHA}"

echo "Starting deployment to ${ENVIRONMENT} environment"
echo "AWS Account: ${AWS_ACCOUNT_ID}"
echo "AWS Region: ${AWS_REGION}"
echo "Docker image: ${DOCKER_IMAGE}"
echo "Commit SHA: ${GITHUB_SHA}"

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker pull ${DOCKER_IMAGE}

docker stop ${APP_NAME}-${ENVIRONMENT} || true
docker rm ${APP_NAME}-${ENVIRONMENT} || true

docker run -d \
  --name ${APP_NAME}-${ENVIRONMENT} \
  --restart always \
  -p 3000:3000 \
  -e NODE_ENV=${ENVIRONMENT} \
  -e PORT=3000 \
  -e APP_VERSION=${GITHUB_SHA} \
  ${DOCKER_IMAGE}

echo "Deployment completed for $ENVIRONMENT"
