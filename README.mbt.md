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
# 1) Prepare direct-api token (refresh + verify)
opz direct-api-dev -- just direct-prepare-rest
# If this is your first run or refresh fails:
# opz direct-api-dev -- just direct-login-rest

# 2) Full run (s3 prepare + strict env check + app run)
opz daab-dev -- just app
```

Split run:

```bash
just app-prepare
opz daab-dev -- just app-run
```

Defaults used by `app-run`:

- `S3_ENDPOINT_URL=http://127.0.0.1:9000`
- `S3_BUCKET=airlock-attachments`
- `S3_PREFIX=direct4b`
- `AWS_ACCESS_KEY_ID=rustfsadmin`
- `AWS_SECRET_ACCESS_KEY=rustfsadmin`
- `AWSLIM_S3_BIN=../awslim/awslim-s3`
- `DIRECT4B_API_TOKEN=<direct bot token>` (WebSocket bridge 用)
- `DIRECT4B_DIRECT_API_TOKEN=<direct-api token>` (ユーザー名解決用, talks.read, required)
- `AIRLOCK_ATTACHMENT_UPLOAD_CMD=./src/cmd/it_support_app/scripts/upload_to_s3_compatible.sh`

Attachment behavior:

- On success: the timeline message includes a clickable S3 URL.
- On upload failure: the message still includes a clickable Direct4B URL (`[attachment-upload-failed]` is appended).

Useful commands:

```bash
just help
opz daab-dev -- just app-debug-auth
just s3-logs
just s3-down
```
