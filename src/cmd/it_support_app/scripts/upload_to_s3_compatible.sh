#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${AIRLOCK_ATTACHMENT_URL:-}" ]]; then
  echo "AIRLOCK_ATTACHMENT_URL is required" >&2
  exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 2
fi
if ! command -v aws >/dev/null 2>&1; then
  echo "aws cli is required" >&2
  exit 2
fi

S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-http://127.0.0.1:9000}"
S3_BUCKET="${S3_BUCKET:-airlock-attachments}"
S3_PREFIX="${S3_PREFIX:-direct4b}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-rustfsadmin}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-rustfsadmin}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

raw_name="${AIRLOCK_ATTACHMENT_NAME:-attachment.bin}"
raw_name="${raw_name##*/}"
safe_name="$(printf '%s' "$raw_name" | tr -cd 'A-Za-z0-9._-')"
if [[ -z "$safe_name" ]]; then
  safe_name="attachment.bin"
fi

external_id="${AIRLOCK_MESSAGE_EXTERNAL_ID:-msg}"
safe_external_id="$(printf '%s' "$external_id" | tr -cd 'A-Za-z0-9._-')"
if [[ -z "$safe_external_id" ]]; then
  safe_external_id="msg"
fi

platform="${AIRLOCK_PLATFORM:-direct4b}"
safe_platform="$(printf '%s' "$platform" | tr -cd 'A-Za-z0-9._-')"
if [[ -z "$safe_platform" ]]; then
  safe_platform="direct4b"
fi

date_path="$(date -u +%Y/%m/%d)"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

curl -fsSL "${AIRLOCK_ATTACHMENT_URL}" -o "$tmp_file"

object_key="${S3_PREFIX}/${safe_platform}/${date_path}/${safe_external_id}-${stamp}-${safe_name}"
s3_uri="s3://${S3_BUCKET}/${object_key}"
aws --endpoint-url "${S3_ENDPOINT_URL}" s3 cp "$tmp_file" "$s3_uri" >/dev/null

printf '%s/%s/%s\n' "${S3_ENDPOINT_URL%/}" "${S3_BUCKET}" "${object_key}"
