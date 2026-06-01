# Bot Army Shell - Go Build Configuration

## Build

```bash
go build -o bot-army-context cmd/bot-army-context/main.go
```

## Run

```bash
# With defaults
./bot-army-context

# With custom NATS servers
NATS_SERVERS="localhost:4222 localhost:14223" ./bot-army-context

# With custom socket path
BOT_ARMY_CONTEXT_SOCKET="/tmp/custom.sock" ./bot-army-context
```

## Docker Build

```bash
docker build -t bot-army-context -f Dockerfile .
```
