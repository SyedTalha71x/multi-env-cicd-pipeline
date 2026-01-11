#!/bin/bash

ENVIRONMENT=${1:-dev}
APP_NAME="multi-env-cicd-app"

echo "Starting rollback for $ENVIRONMENT environment"

PREVIOUS_IMAGE=$(docker images --filter "reference=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}" --format "{{.Tag}}" | grep -v ${GITHUB_SHA} | head -1)

if [ -z "$PREVIOUS_IMAGE" ]; then
    echo "No previous image found for rollback"
    exit 1
fi

echo "Rolling back to image with tag: $PREVIOUS_IMAGE"

docker stop ${APP_NAME}-${ENVIRONMENT} || true
docker rm ${APP_NAME}-${ENVIRONMENT} || true

docker run -d \
  --name ${APP_NAME}-${ENVIRONMENT} \
  --restart always \
  -p 3000:3000 \
  -e NODE_ENV=${ENVIRONMENT} \
  -e PORT=3000 \
  -e APP_VERSION=${PREVIOUS_IMAGE} \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}:${PREVIOUS_IMAGE}

echo "Rollback completed successfully"

curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"Rollback triggered for $ENVIRONMENT environment. Reverted to version: $PREVIOUS_IMAGE\"}" \
  ${SLACK_WEBHOOK_URL}