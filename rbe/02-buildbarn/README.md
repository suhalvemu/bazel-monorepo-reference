# Buildbarn (Self-Hosted RBE)

[Buildbarn](https://github.com/buildbarn) is the leading open-source implementation of the Bazel Remote Execution API. Run your own RBE cluster with no external dependencies.

## Architecture

```
Bazel client
    │
    ▼
bb-frontend (gRPC :8980)
    ├── bb-scheduler  (distributes actions to workers)
    ├── bb-storage    (CAS + Action Cache)
    └── bb-worker x N (executes build actions in containers)
```

The Docker Compose in this directory runs a minimal single-worker cluster suitable for local testing and learning.

## Start the Cluster

```bash
docker-compose up -d

# Verify all containers are healthy
docker-compose ps
```

Services:
- **storage** — Content Addressable Storage + Action Cache (gRPC :8981)
- **scheduler** — distributes actions to available workers (gRPC :8982)
- **worker** — executes actions (requires `privileged: true` for container isolation)
- **frontend** — unified gRPC endpoint for Bazel clients (:8980)
- **browser** — web UI for inspecting builds (:7984)

## Connect Bazel

```bash
bazel build //apps/go-service --config=buildbarn
```

The `buildbarn` config in `.bazelrc`:
```ini
build:buildbarn --remote_cache=grpc://localhost:8980
build:buildbarn --remote_executor=grpc://localhost:8980
build:buildbarn --remote_upload_local_results=true
```

## View Build Results

Open [http://localhost:7984](http://localhost:7984) — the Buildbarn browser shows:
- Action cache entries
- CAS blobs
- Execution history per invocation

## Production Considerations

This Docker Compose is for local experimentation only. Production Buildbarn deployments:
- Run multiple workers for parallelism
- Use persistent storage (GCS, S3, or dedicated block storage)
- Deploy on Kubernetes (official Helm charts available)
- Add authentication (mTLS or JWT)

## vs BuildBuddy

| | Buildbarn | BuildBuddy |
|--|--|--|
| Hosting | Self-managed | Managed SaaS |
| Cost | Infrastructure only | Free tier + paid plans |
| Customization | Full control | Limited |
| Setup complexity | High | Low (API key only) |
| Production use | Pinterest, Spotify | Stripe, Uber |
