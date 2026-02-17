# airlock/airlock

## Run it-support-app (native)

```bash
cd src
moon run cmd/it_support_app --target native
```

The server listens on `http://0.0.0.0:8080`.

## Local S3-compatible test with rustfs (Docker)

Requirements:

- `docker`
- `aws` CLI
- `curl`

```bash
# 1) Start rustfs
just s3-rustfs-up

# 2) Create/check bucket (default: airlock-attachments)
just s3-rustfs-mk-bucket

# 3) Run it-support-app with upload hook enabled
just run-native-rustfs
```

Defaults used by `run-native-rustfs`:

- `S3_ENDPOINT_URL=http://127.0.0.1:9000`
- `S3_BUCKET=airlock-attachments`
- `S3_PREFIX=direct4b`
- `AWS_ACCESS_KEY_ID=rustfsadmin`
- `AWS_SECRET_ACCESS_KEY=rustfsadmin`
- `AIRLOCK_ATTACHMENT_UPLOAD_CMD=./src/cmd/it_support_app/scripts/upload_to_s3_compatible.sh`

Useful commands:

```bash
just s3-rustfs-logs
just s3-rustfs-down
```
