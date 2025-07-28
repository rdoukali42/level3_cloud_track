FROM golang:1.23-alpine AS build
RUN apk add --no-cache git
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go mod tidy && go build -o paas-api

FROM alpine:latest
WORKDIR /app
COPY --from=build /app/paas-api .
EXPOSE 80
ENTRYPOINT ["./paas-api"]