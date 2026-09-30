# Spring Boot Backend

REST API for the Student Registration app (`/api/register`, `/api/users`, `/api/users/{id}`), backed by MySQL
(Cloud SQL for MySQL 8.4 on GCP, or a local MySQL / Docker container for development).

## Prerequisites

- JDK 17 or higher
- Maven (or use the included `./mvnw`)
- A MySQL 8.x database

## Configuration

The app reads its database settings from environment variables (see `src/main/resources/application.properties`):

| Variable | Default | Description |
|---|---|---|
| `DB_HOST` | `localhost` | Database host (Cloud SQL private IP on GCP) |
| `DB_PORT` | `3306` | Database port |
| `DB_NAME` | `student_registration` | Database name |
| `DB_USER` | - (required) | Database user |
| `DB_PASSWORD` | - (required) | Database password |

## Run locally

Start a throw-away MySQL (or use the repository's `docker compose up`, which does this for you):

```bash
docker run -d --name student-mysql -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=change-me -e MYSQL_DATABASE=student_registration \
  mysql:8.4
```

Then run the API:

```bash
export DB_USER=root
export DB_PASSWORD=change-me
./mvnw spring-boot:run        # http://localhost:8080
```

Health check: `curl http://localhost:8080/actuator/health`

## Tests

Tests run against an in-memory H2 database (`src/test/resources/application.properties`), so no MySQL is needed:

```bash
./mvnw clean test
```

## Build the jar / image

```bash
./mvnw clean package
docker build -t student-backend -f dockerfile .
```
