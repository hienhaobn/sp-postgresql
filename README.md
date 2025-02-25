# 🐘 SP PostgreSQL Project

![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue?logo=docker)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16%2B-brightgreen?logo=postgresql)
![Java](https://img.shields.io/badge/Java-21-yellow?logo=openjdk)

Project quản lý cấu hình PostgreSQL và ứng dụng Spring Boot trong môi trường Docker

## 🚀 Bắt đầu nhanh

### Yêu cầu hệ thống
- Docker 20.10+
- Docker Compose 2.20+
- OpenSSL 3.0+

### Khởi tạo cấu hình
```bash
# Tạo file .env.production với các giá trị ngẫu nhiên
{
  echo "# Auto-generated production env"
  echo "POSTGRES_PASSWORD=$(openssl rand -base64 32)"
  echo "JWT_SECRET_KEY=$(openssl rand -hex 64)"
  echo "MANAGEMENT_ENDPOINT_API_KEY=$(uuidgen)"
} > .env.production
```

## 🐳 Docker Management

### Development Environment
```bash
# Build và khởi động services
docker-compose --env-file .env.development up --build --force-recreate

# Xem logs ứng dụng
docker-compose logs -f app

# Truy cập container
docker-compose exec app sh
```

### Production Environment
```bash
# Kiểm tra cấu hình
docker-compose --env-file .env.production config

# Khởi động production stack
docker-compose --env-file .env.production up -d
```

## 🔍 System Diagnostics
| Lệnh | Mô tả |
|------|-------|
| `docker system df` | Kiểm tra dung lượng sử dụng |
| `docker stats` | Giám sát resource real-time |
| `docker system prune -a --volumes` | Dọn dẹp toàn bộ (⚠️ Cẩn thận mất dữ liệu) |

## 🛠️ Troubleshooting

### Lỗi Maven Dependency
```bash
# Build với log chi tiết
DOCKER_BUILDKIT=1 docker build --progress=plain -t app:dev .
```

### Lỗi Database Connection
```bash
# Kiểm tra kết nối database
docker-compose exec db psql -U $POSTGRES_USER -d $POSTGRES_DB
```

### Lỗi Permission
```bash
# Sửa quyền thư mục
docker-compose exec app chown -R appuser:appgroup /home/appuser
```

## 📂 Thư mục quan trọng
```
/
├── .env.development    # Cấu hình môi trường dev
├── .env.production     # Cấu hình môi trường prod
├── docker/             # Docker-related files
│   ├── Dockerfile
│   └── .mvn/
└── init-db.sh          # Database initialization script
```

> **Warning**  
> Luôn backup các file .env và volume trước khi chạy lệnh prune