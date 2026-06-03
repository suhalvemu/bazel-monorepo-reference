# Google Cloud Storage Remote Cache

Use a GCS bucket as Bazel's remote cache. Ideal for teams already on GCP — no extra infrastructure, costs only what you store and transfer.

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed and authenticated
- `storage.objectAdmin` role on the bucket (or `roles/storage.admin`)

## Create the Bucket

```bash
# Run the setup script (creates bucket + 30-day lifecycle policy)
chmod +x setup.sh && ./setup.sh YOUR_GCP_PROJECT_ID
```

The lifecycle policy auto-deletes objects older than 30 days, preventing unbounded cost.

## Authenticate

```bash
gcloud auth application-default login
```

Bazel uses Application Default Credentials (`--google_default_credentials`). In CI, use a service account key or Workload Identity.

## Connect Bazel

```bash
export GCS_BUCKET=bazel-cache-YOUR_PROJECT_ID

bazel build //apps/go-service --config=gcs
```

Or add to `user.bazelrc`:
```ini
build --config=gcs
```

And set `GCS_BUCKET` in your shell profile.

## IAM for CI

For GitHub Actions or Cloud Build:

```bash
# Grant the CI service account cache access
gcloud storage buckets add-iam-policy-binding gs://$GCS_BUCKET \
  --member="serviceAccount:ci@YOUR_PROJECT.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

In GitHub Actions, use Workload Identity Federation (no long-lived keys):
```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/123/locations/global/workloadIdentityPools/...
    service_account: ci@YOUR_PROJECT.iam.gserviceaccount.com
```

## Cost Estimate

| Team size | Cache size | Monthly cost (approx.) |
|-----------|-----------|----------------------|
| 5 devs | 5 GB | ~$0.10 storage + transfer |
| 20 devs | 20 GB | ~$0.40 + transfer |
| 100 devs | 50 GB | ~$1.00 + transfer |

GCS is essentially free for Bazel caching at typical team sizes. The 30-day TTL keeps storage bounded.
