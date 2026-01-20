FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build binary - CGO disabled (modernc.org/sqlite is pure Go)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /server ./cmd/server

# Final stage - minimal image
FROM alpine:3.21

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Copy binary from builder
COPY --from=builder /server .

# Create data directory for SQLite database
RUN mkdir -p /app/data

# Set environment variables
ENV PORT=8080

EXPOSE 8080

# Run the binary
CMD ["./server"]
