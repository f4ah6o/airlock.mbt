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
- `repos/awslim/awslim-s3` binary (or set `AWSLIM_S3_BIN`)
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
- `AWSLIM_S3_BIN=../awslim/awslim-s3`
- `DIRECT4B_API_TOKEN=<direct bot token>` (WebSocket bridge 用)
- `DIRECT4B_DIRECT_API_TOKEN=<direct-api token>` (ユーザー名解決用, talks.read)
- `AIRLOCK_ATTACHMENT_UPLOAD_CMD=./src/cmd/it_support_app/scripts/upload_to_s3_compatible.sh`

Attachment behavior:

- On success: the timeline message includes a clickable S3 URL.
- On upload failure: the message still includes a clickable Direct4B URL (`[attachment-upload-failed]` is appended).

Useful commands:

```bash
just s3-rustfs-logs
just s3-rustfs-down
```
