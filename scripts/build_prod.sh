#!/usr/bin/env bash
set -euo pipefail  # Kết thúc khi có lỗi, biến không được đặt và lỗi trong pipeline

# Đường dẫn tệp .env cho môi trường production
ENV_FILE=".env.production"

# Kiểm tra sự tồn tại của tệp .env
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: Tệp $ENV_FILE không tồn tại." >&2
  exit 1
fi

# Tải các biến môi trường từ tệp .env một cách an toàn
# Bỏ qua các dòng trống và dòng bắt đầu bằng '#'
set -o allexport
while IFS='=' read -r key value; do
  # Bỏ qua các dòng trống hoặc dòng bắt đầu bằng '#'
  if [[ -z "$key" || "$key" =~ ^# ]]; then
    continue
  fi
  # Loại bỏ khoảng trắng xung quanh key và value
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)
  # Kiểm tra xem key có hợp lệ không
  if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "WARNING: Biến môi trường '$key' không hợp lệ và sẽ bị bỏ qua." >&2
    continue
  fi
  export "$key=$value"
done < <(grep -v '^[[:space:]]*$' "$ENV_FILE")
set +o allexport

# Xây dựng và khởi động các dịch vụ với Docker Compose
docker-compose --env-file "$ENV_FILE" -f docker-compose.prod.yml build --no-cache --pull
docker-compose --env-file "$ENV_FILE" -f docker-compose.prod.yml up -d

# Thiết lập kiểm tra sức khỏe với số lần thử và khoảng thời gian giữa các lần thử
MAX_RETRIES=5
RETRY_INTERVAL=10
HEALTHY=false

# Vòng lặp kiểm tra trạng thái sức khỏe của container
for ((i=1; i<=MAX_RETRIES; i++)); do
  CONTAINER_ID=$(docker-compose ps -q app)

  if [[ -z "$CONTAINER_ID" ]]; then
    echo "Không tìm thấy container. Thử lại lần $i/$MAX_RETRIES..."
    sleep $RETRY_INTERVAL
    continue
  fi

  HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_ID" 2>/dev/null || true)

  if [[ "$HEALTH_STATUS" == "healthy" ]]; then
    HEALTHY=true
    break
  fi

  echo "Đang chờ container trở nên khỏe mạnh (healthy) lần $i/$MAX_RETRIES..."
  sleep $RETRY_INTERVAL
done

# Kiểm tra kết quả cuối cùng của trạng thái sức khỏe
if [[ "$HEALTHY" == false ]]; then
  echo "ERROR: Container không khởi động đúng cách."
  docker-compose logs --tail=50 app
  docker-compose down -v
  exit 1
fi

# Thực hiện kiểm tra sơ bộ (smoke test) để đảm bảo ứng dụng hoạt động
SMOKE_TEST_URL="http://localhost:${SERVER_PORT:-8080}/actuator/health"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SMOKE_TEST_URL" || true)

if [[ "$HTTP_STATUS" -eq 200 ]]; then
  echo "Triển khai production THÀNH CÔNG."
  exit 0
else
  echo "Kiểm tra sơ bộ THẤT BẠI (HTTP $HTTP_STATUS)."
  docker-compose logs --tail=50 app
  exit 1
fi
