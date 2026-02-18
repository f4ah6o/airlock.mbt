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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AIRLOCK_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
DEFAULT_AWSLIM_S3_BIN="$AIRLOCK_ROOT/../awslim/awslim-s3"
AWSLIM_S3_BIN="${AWSLIM_S3_BIN:-$DEFAULT_AWSLIM_S3_BIN}"
if [[ ! -x "$AWSLIM_S3_BIN" ]]; then
  echo "awslim-s3 binary not found or not executable: $AWSLIM_S3_BIN" >&2
  exit 2
fi

S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-http://127.0.0.1:9000}"
S3_BUCKET="${S3_BUCKET:-airlock-attachments}"
S3_PREFIX="${S3_PREFIX:-direct4b}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-rustfsadmin}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-rustfsadmin}"
AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_REGION
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-$AWS_REGION}"
export AWS_ENDPOINT_URL_S3="${AWS_ENDPOINT_URL_S3:-$S3_ENDPOINT_URL}"

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

download_ok=0
auth_method=""
last_curl_error=""
download_url="${AIRLOCK_ATTACHMENT_DOWNLOAD_URL:-${AIRLOCK_ATTACHMENT_URL}}"
download_headers="${AIRLOCK_ATTACHMENT_DOWNLOAD_HEADERS:-}"
if [[ -n "$download_headers" ]]; then
  curl_args=(-fsSL)
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      curl_args+=(-H "$line")
    fi
  done <<< "$download_headers"
  if curl "${curl_args[@]}" "$download_url" -o "$tmp_file"; then
    download_ok=1
    auth_method="download_auth_headers"
    echo "downloaded attachment with download-auth headers" >&2
  else
    echo "failed to download attachment with download-auth headers" >&2
    exit 31
  fi
fi
token="${DIRECT4B_API_TOKEN:-${DIRECT_API_TOKEN:-}}"
if [[ "$download_ok" -ne 1 && -n "$token" ]]; then
  alb_url="$download_url"
  if [[ "$alb_url" == https://api.direct4b.com/* || "$alb_url" == http://api.direct4b.com/* ]]; then
    if [[ "$alb_url" != *"Authorization="* ]]; then
      if [[ "$alb_url" == *"?"* ]]; then
        alb_url="${alb_url}&Authorization=ALB%20${token}"
      else
        alb_url="${alb_url}?Authorization=ALB%20${token}"
      fi
    fi
    if curl -fsSL "$alb_url" -o "$tmp_file"; then
      download_ok=1
      auth_method="Authorization=ALB query"
      echo "downloaded attachment with Authorization=ALB query" >&2
    else
      last_curl_error="Authorization=ALB query failed"
    fi
  fi
  if [[ "$download_ok" -ne 1 ]] && curl -fsSL -H "Authorization: Bearer ${token}" "$download_url" -o "$tmp_file"; then
    download_ok=1
    auth_method="Authorization: Bearer"
    echo "downloaded attachment with Authorization: Bearer" >&2
  else
    if [[ "$download_ok" -ne 1 ]]; then
      last_curl_error="${last_curl_error}; Authorization: Bearer failed"
    fi
  fi
  if [[ "$download_ok" -ne 1 ]] && curl -fsSL -H "X-Auth-Token: ${token}" "$download_url" -o "$tmp_file"; then
    download_ok=1
    auth_method="X-Auth-Token"
    echo "downloaded attachment with X-Auth-Token" >&2
  else
    if [[ "$download_ok" -ne 1 ]]; then
      last_curl_error="${last_curl_error}; X-Auth-Token failed"
    fi
  fi
  if [[ "$download_ok" -ne 1 ]] && curl -fsSL -H "X-API-Token: ${token}" "$download_url" -o "$tmp_file"; then
    download_ok=1
    auth_method="X-API-Token"
    echo "downloaded attachment with X-API-Token" >&2
  else
    if [[ "$download_ok" -ne 1 ]]; then
      last_curl_error="${last_curl_error}; X-API-Token failed"
      echo "token auth download failed for Direct4B attachment URL (${last_curl_error#; })" >&2
    fi
  fi
fi
if [[ "$download_ok" -ne 1 ]]; then
  if ! curl -fsSL "$download_url" -o "$tmp_file"; then
    echo "failed to download attachment URL without auth; set DIRECT4B_API_TOKEN if protected." >&2
    exit 31
  fi
  echo "downloaded attachment without token auth" >&2
else
  echo "download auth method: ${auth_method}" >&2
fi

object_key="${S3_PREFIX}/${safe_platform}/${date_path}/${safe_external_id}-${stamp}-${safe_name}"
if ! "$AWSLIM_S3_BIN" s3 put-object \
  "{\"Bucket\":\"${S3_BUCKET}\",\"Key\":\"${object_key}\"}" \
  --input-stream "$tmp_file" \
  --api-output=false >/dev/null; then
  echo "failed to upload object to S3 compatible storage: s3://${S3_BUCKET}/${object_key}" >&2
  exit 41
fi

printf '%s/%s/%s\n' "${S3_ENDPOINT_URL%/}" "${S3_BUCKET}" "${object_key}"
