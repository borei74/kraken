# Use official Go image for building
FROM golang:1.24 AS builder

# Set working directory inside builder container
WORKDIR /app

# Copy Go module files and source code from "go" directory
COPY go/go.mod ./
RUN go mod download

COPY go/ ./

# Build the Go binary
RUN go build -o web-service .

# Minimal runtime image
FROM debian:bookworm-slim

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/web-service .

# Expose the service port
EXPOSE 8080

# Set the default command
CMD ["./web-service"]

