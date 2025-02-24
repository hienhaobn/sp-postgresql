#!/usr/bin/env bash
set -eo pipefail  # Exit on error, pipefail

# Load env vars with validation
ENV_FILE=".env.production"
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: Missing $ENV_FILE file" >&2
  exit 1
fi

# Export variables safely (handle special chars)
export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')

# Build and start
docker-compose --env-file "$ENV_FILE" -f docker-compose.prod.yml build --no-cache --pull
docker-compose --env-file "$ENV_FILE" -f docker-compose.prod.yml up -d

# Health check with retries
MAX_RETRIES=5
RETRY_INTERVAL=10
HEALTHY=false

for ((i=1; i<=$MAX_RETRIES; i++)); do
  CONTAINER_ID=$(docker-compose ps -q app)
  
  if [ -z "$CONTAINER_ID" ]; then
    echo "Container not found. Retrying ($i/$MAX_RETRIES)..."
    sleep $RETRY_INTERVAL
    continue
  fi

  HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_ID" 2>/dev/null || true)
  
  if [ "$HEALTH_STATUS" = "healthy" ]; then
    HEALTHY=true
    break
  fi
  
  echo "Waiting for container to become healthy ($i/$MAX_RETRIES)..."
  sleep $RETRY_INTERVAL
done

# Final check
if [ "$HEALTHY" = false ]; then
  echo "ERROR: Container failed to start properly"
  docker-compose logs --tail=50 app
  docker-compose down -v
  exit 1
fi

# Run smoke test
SMOKE_TEST_URL="http://localhost:${SERVER_PORT:-8080}/actuator/health"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SMOKE_TEST_URL" || true)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "Production deployment SUCCESSFUL"
  exit 0
else
  echo "Smoke test FAILED (HTTP $HTTP_STATUS)"
  docker-compose logs --tail=50 app
  exit 1
fi
