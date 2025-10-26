# PaaS API - Database Management API

A secure REST API for managing PostgreSQL databases on Kubernetes, featuring JWT authentication via ZITADEL OAuth.

## Features

- **JWT Authentication**: Secure endpoints with ZITADEL OAuth 2.0
- **Database Management**: Create, list, and delete PostgreSQL databases
- **CORS Support**: Configurable cross-origin requests
- **Production Ready**: Environment-based configuration

## API Endpoints

### Public Endpoints

- `GET /` - Health check endpoint

### Protected Endpoints (Require JWT)

- `GET /api/v1/databases` - List all databases
- `POST /api/v1/databases` - Create a new database
  ```json
  {
    "Name": "database_name"
  }
  ```
- `DELETE /api/v1/databases/:name` - Delete a database

## Configuration

Set these environment variables:

```bash
POSTGRES_DSN="postgres://user:password@host:5432/dbname?sslmode=disable"
ZITADEL_ISSUER="https://your-instance.zitadel.cloud"
ZITADEL_API_CLIENT_ID="your-api-client-id"
ALLOWED_ORIGINS="http://localhost:8086,https://your-domain.com"
```

## Running Locally

```bash
# Install dependencies
go mod download

# Run the server
go run main.go

# Or build and run
go build -o paas-api .
./paas-api
```

## Deploying to Kubernetes

```bash
# Build Docker image
docker build -t your-registry/paas-api:latest .

# Push to registry
docker push your-registry/paas-api:latest

# Deploy
kubectl apply -f ../paas-manifests/paas-api-deployment.yaml
```

## Security Notes

⚠️ **SQL Injection Warning**: The current implementation concatenates user input into SQL queries. In production, you MUST:

1. Validate database names with strict regex: `^[a-zA-Z_][a-zA-Z0-9_]*$`
2. Use parameterized queries where possible
3. Implement proper input sanitization
4. Add rate limiting
5. Enable audit logging

## Development

```bash
# Run with hot reload (install air first)
go install github.com/cosmtrek/air@latest
air

# Run tests
go test ./...
```
