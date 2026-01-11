#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
APP_NAME="multi-env-cicd-app"
DOCKER_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}:${GITHUB_SHA}"


echo "Starting deployment to ${ENVIRONMENT} environment"
echo "docker image: ${DOCKER_IMAGE}"


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
  $DOCKER_IMAGE

echo "Deployment completed for $ENVIRONMENT"


