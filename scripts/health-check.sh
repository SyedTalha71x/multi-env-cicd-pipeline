#!/bin/bash

ENVIRONMENT=${1:-dev}
APP_NAME="multi-env-cicd-app"
MAX_RETRIES=10
RETRY_INTERVAL=5

echo "starting health check for ${APP_NAME} in ${ENVIRONMENT} environment"

for i in $(seq 1 $MAX_RETRIES); do 
    echo "Attempt $i: Checking health endpoint..."

    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health || echo "000")


    if [ "RESPONSE" -eq 200 ]; then
      echo "Health check passed! Application is running."
        exit 0
    else
        echo "Health check failed with status code $RESPONSE. Retrying in $RETRY_INTERVAL seconds..."
        sleep $RETRY_INTERVAL
    fi
done


echo "Health check failed after $MAX_RETRIES attempts"
echo "Initiating rollback..."

# Trigger rollback
./scripts/rollback.sh $ENVIRONMENT
exit 1