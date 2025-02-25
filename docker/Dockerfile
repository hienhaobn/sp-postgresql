ARG HOST_UID=1000
ARG HOST_GID=1000

# Build stage
FROM eclipse-temurin:21-jdk-jammy AS builder
WORKDIR /app
COPY . .
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
# RUN ./mvnw dependency:go-offline -B

RUN apt-get update && \
  apt-get install -y maven && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

  # Build
  RUN mvn clean package -DskipTests
# Runtime stage
FROM eclipse-temurin:21-jre-jammy
COPY --from=builder /app/target/*.jar /app/app.jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

# Development image
FROM eclipse-temurin:21-jdk-jammy AS dev

# Tạo nhóm và người dùng
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -m -d /home/appuser appuser

# Tạo thư mục làm việc
WORKDIR /app

# 1. Copy Maven Wrapper trước để tận dụng cache
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# 2. Tạo thư mục .m2 trong thư mục home và thiết lập quyền
RUN mkdir -p /home/appuser/.m2 && \
    chown -R appuser:appgroup /home/appuser/.m2 && \
    chmod +x mvnw && \
    ./mvnw dependency:go-offline -B

# 3. Copy source code
COPY src src/

# 4. Chạy ứng dụng bằng Maven Wrapper
CMD ["./mvnw", "spring-boot:run"]

# Production image
FROM eclipse-temurin:21-jre-jammy as prod
WORKDIR /app
COPY --from=builder /app/target/*.jar ./app.jar
RUN groupadd -g ${HOST_GID} appgroup && \
  useradd -u ${HOST_UID} -g appgroup -m -d /app appuser && \
  chown -R ${HOST_UID}:${HOST_GID} /app && \
  chmod 550 /app/app.jar

USER appuser
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--spring.profiles.active=prod"]

# Security metadata
LABEL org.opencontainers.image.authors="Hien Hao"
LABEL org.opencontainers.image.source="https://github.com/hienhaobn"