FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum first for layer caching
COPY go.mod go.sum ./

RUN go mod download

# Copy source code
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bot-army-context ./cmd/bot-army-context

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add tzdata

WORKDIR /app

COPY --from=builder /app/bot-army-context /usr/local/bin/bot-army-context

# Create non-root user
RUN addgroup -g 1000 botarmy && \
    adduser -u 1000 -G botarmy -h /home/botarmy -s /bin/sh -D botarmy

USER botarmy

ENV BOT_ARMY_CONTEXT_SOCKET=/tmp/bot-army-context.sock
ENV NATS_SERVERS=localhost:4223

EXPOSE 4223

CMD ["bot-army-context"]
