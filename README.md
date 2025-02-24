# SP Postgresql

## Generate .env.production

```bash
{
  echo "# Auto-generated production env"
  echo "POSTGRES_PASSWORD=$(openssl rand -base64 32)"
  echo "JWT_SECRET_KEY=$(openssl rand -hex 64)"
  echo "MANAGEMENT_ENDPOINT_API_KEY=$(uuidgen)"
} > .env.production

```

## Docker

### Development

- Kiểm tra biến môi trường đã load

```bash
  docker-compose --env-file .env.development config
```

- Xem logs

```bash
   docker-compose logs -f app
```

- Debug trong container

```bash
  docker-compose exec app sh
```

- Build development

```bash
  docker-compose --env-file .env.development up --build
```
