ARG HOST_UID=1000
ARG HOST_GID=1000

# Build stage
FROM eclipse-temurin:21-jdk-jammy AS builder
WORKDIR /app
COPY . .
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline -B

RUN apt-get update && \
    apt-get install -y maven

# Runtime stage
FROM eclipse-temurin:21-jre-jammy
COPY --from=builder /app/target/*.jar /app/app.jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

# Development image
FROM eclipse-temurin:21-jdk-jammy AS dev
WORKDIR /app
# COPY --from=builder /app/target/dependency/ ./lib/
COPY --from=builder /app/target/*.jar ./app.jar
ARG HOST_UID
ARG HOST_GID
RUN if ! getent group ${HOST_GID}; then \
      groupadd -g ${HOST_GID} appgroup; \
    else \
      groupmod -n appgroup $(getent group ${HOST_GID} | cut -d: -f1); \
    fi && \
    useradd -u ${HOST_UID} -g ${HOST_GID} -d /app -s /bin/bash appuser && \
    mkdir -p /app && \
    chown -R ${HOST_UID}:${HOST_GID} /app
USER appuser

CMD ["mvn", "spring-boot:run", "-Dspring-boot.run.arguments=--spring.jpa.properties.hibernate.globally_quoted_identifiers=true", "-Dspring-boot.run.jvmArguments=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"]

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