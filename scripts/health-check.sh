#!/bin/bash

ENVIRONMENT=${1:-dev}
APP_NAME="multi-env-cicd-app"
MAX_RETRIES=15  # Increased for app startup time
RETRY_INTERVAL=10  # Increased interval

echo "Starting health check for ${APP_NAME} in ${ENVIRONMENT} environment"

# First, check if container is running
CONTAINER_NAME="${APP_NAME}-${ENVIRONMENT}"
if ! docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep -q "${CONTAINER_NAME}"; then
    echo "❌ ERROR: Container ${CONTAINER_NAME} is not running!"
    echo "Checking all containers..."
    docker ps -a
    exit 1
fi

echo "✅ Container ${CONTAINER_NAME} is running"

# Wait for app to initialize
echo "Waiting 15 seconds for application to initialize..."
sleep 15

for i in $(seq 1 $MAX_RETRIES); do 
    echo "Attempt $i/$MAX_RETRIES: Checking health endpoint..."
    
    # Try multiple endpoints
    ENDPOINTS=("/api/health" "/health" "/" "/api/status")
    RESPONSE="000"
    
    for endpoint in "${ENDPOINTS[@]}"; do
        TEMP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000${endpoint} 2>/dev/null || echo "000")
        
        if [ "$TEMP_RESPONSE" != "000" ] && [ "$TEMP_RESPONSE" != "" ]; then
            RESPONSE="$TEMP_RESPONSE"
            echo "Endpoint ${endpoint} returned: $RESPONSE"
            break
        fi
    done
    
    if [ "$RESPONSE" = "200" ]; then
      echo "✅ Health check passed! Application is running."
      exit 0
    else
        if [ $i -eq $MAX_RETRIES ]; then
            echo "❌ Final attempt failed with status code $RESPONSE."
            
            # Debug info
            echo "=== Container Logs (last 30 lines) ==="
            docker logs ${CONTAINER_NAME} --tail 30 2>/dev/null || echo "No logs available"
            
            echo "=== Checking container processes ==="
            docker top ${CONTAINER_NAME} 2>/dev/null || echo "Cannot check processes"
            
        else
            echo "⚠️ Health check failed with status code $RESPONSE. Retrying in $RETRY_INTERVAL seconds..."
            sleep $RETRY_INTERVAL
        fi
    fi
done

echo "❌ Health check failed after $MAX_RETRIES attempts"
echo "Initiating rollback..."

# Trigger rollback
./scripts/rollback.sh $ENVIRONMENT
exit 1