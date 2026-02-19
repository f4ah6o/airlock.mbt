# https://github.com/mizchi/moonbit-template
# SPDX-License-Identifier: MIT
# MoonBit Project Commands

set shell := ["bash", "-ceu"]

target := "js"
rustfs_container := "airlock-rustfs"
rustfs_data_dir := "_local/rustfs-data"
rustfs_endpoint := "http://127.0.0.1:9000"
rustfs_console := "http://127.0.0.1:9001"
rustfs_access_key := "rustfsadmin"
rustfs_secret_key := "rustfsadmin"
rustfs_bucket := "airlock-attachments"
awslim_s3_bin := "../awslim/awslim-s3"
airlock_upload_cmd := "./src/cmd/it_support_app/scripts/upload_to_s3_compatible.sh"
direct_api_env_file := "../direct-api.mbt/.env"

default: help

# Show task list for human/AI operators
help:
    @printf "%s\n" \
      "Airlock just tasks" \
      "" \
      "Main flow:" \
      "  just app                # s3 prepare + env check + run app" \
      "  opz daab-dev -- just app  # recommended (bot env from opz)" \
      "  just app-up             # same as app" \
      "  just app-prepare        # s3 prepare + direct env check" \
      "  just app-run            # run it_support_app (native, upload hook on)" \
      "" \
      "Direct auth/token:" \
      "  just direct-login-bot" \
      "  just direct-login-rest" \
      "  just direct-rest-token-print" \
      "  just direct-env-check" \
      "" \
      "S3 (rustfs):" \
      "  just s3-prepare | s3-up | s3-bucket-ready | s3-logs | s3-down" \
      "" \
      "CI:" \
      "  just fmt check test info ci-check release-check"

# CI / development checks
fmt:
    moon fmt

check:
    moon check --deny-warn --target {{target}}

test:
    moon test --target {{target}}

test-update:
    moon test --update --target {{target}}

info:
    moon info

ci-check: fmt info check test

release-check: ci-check

clean:
    moon clean

run:
    moon run src/main --target {{target}}

run-native:
    moon run src/cmd/it_support_app --target native

# direct auth / token

direct-login-bot:
    @if command -v opz >/dev/null 2>&1; then \
      opz daab-dev -- moon -C ../direct_sdk.mbt run src/daab --target native -- login --force; \
    else \
      moon -C ../direct_sdk.mbt run src/daab --target native -- login --force; \
    fi

direct-login-bot-token token:
    @if command -v opz >/dev/null 2>&1; then \
      opz daab-dev -- moon -C ../direct_sdk.mbt run src/daab --target native -- login --token "{{token}}" --force; \
    else \
      moon -C ../direct_sdk.mbt run src/daab --target native -- login --token "{{token}}" --force; \
    fi

# Generate REST token (includes talks.read) and save to ../direct-api.mbt/.env
direct-login-rest:
    @if command -v opz >/dev/null 2>&1; then \
      opz direct-api-dev -- moon -C ../direct-api.mbt run src/main --target native -- login; \
    else \
      moon -C ../direct-api.mbt run src/main --target native -- login; \
    fi

# Print token for AIRLOCK user-name lookup (DIRECT4B_DIRECT_API_TOKEN)
direct-rest-token-print:
    @env_file="{{direct_api_env_file}}"; \
    if [[ ! -f "$env_file" ]]; then \
      echo "missing $env_file. run: just direct-login-rest"; \
      exit 2; \
    fi; \
    token="$(sed -n "s/^DIRECT_API_ACCESS_TOKEN=//p" "$env_file" | tail -n 1)"; \
    if [[ -z "$token" ]]; then \
      echo "DIRECT_API_ACCESS_TOKEN is empty. run: just direct-login-rest"; \
      exit 2; \
    fi; \
    printf "%s\n" "$token"

# Print `export` line for shell use
direct-rest-token-export:
    @token="$(just --justfile {{justfile()}} --quiet direct-rest-token-print)"; \
    printf "export DIRECT4B_DIRECT_API_TOKEN=%q\n" "$token"

# Validate direct-related env vars needed by app
direct-env-check:
    @missing=0; \
    if [[ -z "${DIRECT4B_API_TOKEN:-}" ]]; then \
      echo "missing env: DIRECT4B_API_TOKEN (bot token)."; \
      echo "hint: export DIRECT4B_API_TOKEN='<bot-token>'"; \
      missing=1; \
    fi; \
    if [[ -z "${DIRECT4B_BOT_USER_ID:-}" ]]; then \
      echo "missing env: DIRECT4B_BOT_USER_ID."; \
      echo "hint: export DIRECT4B_BOT_USER_ID='<bot-user-id-or-email>'"; \
      missing=1; \
    fi; \
    rest_token="${DIRECT4B_DIRECT_API_TOKEN:-${DIRECT_API_ACCESS_TOKEN:-}}"; \
    if [[ -z "$rest_token" && -f "{{direct_api_env_file}}" ]]; then \
      rest_token="$(sed -n "s/^DIRECT_API_ACCESS_TOKEN=//p" "{{direct_api_env_file}}" | tail -n 1)"; \
    fi; \
    if [[ -z "$rest_token" ]]; then \
      echo "warning: DIRECT4B_DIRECT_API_TOKEN is empty (username lookup fallback may not work)."; \
      echo "hint: run 'just direct-login-rest' (in opz if needed)"; \
    fi; \
    if [[ "$missing" -ne 0 ]]; then \
      exit 2; \
    fi; \
    echo "direct env check: ok"

# Print only safe hints (does not print secret values)
direct-env-hint:
    @printf "%s\n" \
      "Required:" \
      "  opz daab-dev -- just app" \
      "  (or set DIRECT4B_API_TOKEN / DIRECT4B_BOT_USER_ID manually)" \
      "Optional (recommended for username lookup):" \
      "  just direct-login-rest"

# s3 (rustfs)

s3-up:
    @mkdir -p "{{rustfs_data_dir}}"; \
    chmod 0777 "{{rustfs_data_dir}}" || true; \
    if docker ps -a --format "{{"{{"}}.Names{{"}}"}}" | grep -qx "{{rustfs_container}}"; then \
      docker rm -f "{{rustfs_container}}" >/dev/null; \
    fi; \
    docker run -d \
      --name "{{rustfs_container}}" \
      -p 9000:9000 \
      -p 9001:9001 \
      -e RUSTFS_ACCESS_KEY="{{rustfs_access_key}}" \
      -e RUSTFS_SECRET_KEY="{{rustfs_secret_key}}" \
      -e RUSTFS_CONSOLE_ENABLE=true \
      -v "$PWD/{{rustfs_data_dir}}:/data" \
      rustfs/rustfs:latest \
      /data; \
    echo "rustfs started: {{rustfs_endpoint}} (console: {{rustfs_console}})"

s3-down:
    @if docker ps -a --format "{{"{{"}}.Names{{"}}"}}" | grep -qx "{{rustfs_container}}"; then \
      docker rm -f "{{rustfs_container}}" >/dev/null; \
      echo "rustfs stopped: {{rustfs_container}}"; \
    else \
      echo "rustfs container not found: {{rustfs_container}}"; \
    fi

s3-logs:
    docker logs -f {{rustfs_container}}

s3-bucket-ready:
    @awslim_bin="${AWSLIM_S3_BIN:-{{awslim_s3_bin}}}"; \
    if [[ ! -x "$awslim_bin" ]]; then \
      echo "awslim-s3 binary is required: $awslim_bin"; \
      exit 2; \
    fi; \
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-{{rustfs_access_key}}}"; \
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-{{rustfs_secret_key}}}"; \
    export AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"; \
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-$AWS_REGION}"; \
    endpoint="${S3_ENDPOINT_URL:-{{rustfs_endpoint}}}"; \
    export AWS_ENDPOINT_URL_S3="${AWS_ENDPOINT_URL_S3:-$endpoint}"; \
    bucket="${S3_BUCKET:-{{rustfs_bucket}}}"; \
    "$awslim_bin" s3 create-bucket "{\"Bucket\":\"$bucket\"}" >/dev/null 2>&1 || true; \
    "$awslim_bin" s3 head-bucket "{\"Bucket\":\"$bucket\"}" --api-output=false; \
    echo "bucket ready: $bucket at $endpoint"

s3-prepare: s3-up s3-bucket-ready

# app flow

app-prepare: s3-prepare direct-env-check

app-run:
    @export AWSLIM_S3_BIN="${AWSLIM_S3_BIN:-{{awslim_s3_bin}}}"; \
    if [[ ! -x "$AWSLIM_S3_BIN" ]]; then \
      echo "awslim-s3 binary is required: $AWSLIM_S3_BIN"; \
      exit 2; \
    fi; \
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-{{rustfs_access_key}}}"; \
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-{{rustfs_secret_key}}}"; \
    export AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"; \
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-$AWS_REGION}"; \
    export S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-{{rustfs_endpoint}}}"; \
    export AWS_ENDPOINT_URL_S3="${AWS_ENDPOINT_URL_S3:-$S3_ENDPOINT_URL}"; \
    export S3_BUCKET="${S3_BUCKET:-{{rustfs_bucket}}}"; \
    export S3_PREFIX="${S3_PREFIX:-direct4b}"; \
    if [[ -z "${DIRECT4B_DIRECT_API_TOKEN:-}" && -z "${DIRECT_API_ACCESS_TOKEN:-}" && -f "{{direct_api_env_file}}" ]]; then \
      rest_token="$(sed -n "s/^DIRECT_API_ACCESS_TOKEN=//p" "{{direct_api_env_file}}" | tail -n 1)"; \
      if [[ -n "$rest_token" ]]; then \
        export DIRECT4B_DIRECT_API_TOKEN="$rest_token"; \
      fi; \
    fi; \
    export AIRLOCK_ATTACHMENT_UPLOAD_CMD="{{airlock_upload_cmd}}"; \
    moon run src/cmd/it_support_app --target native -- --attachment-upload-s3

app: app-up

app-up: app-prepare app-run

app-debug-auth:
    @bot_token="${DIRECT4B_API_TOKEN:-}"; \
    rest_token="${DIRECT4B_DIRECT_API_TOKEN:-}"; \
    fallback_rest_token="${DIRECT_API_ACCESS_TOKEN:-}"; \
    printf "%s\n" \
      "DIRECT4B_API_TOKEN length: ${#bot_token}" \
      "DIRECT4B_BOT_USER_ID: ${DIRECT4B_BOT_USER_ID:-<empty>}" \
      "DIRECT4B_DIRECT_API_TOKEN length: ${#rest_token}" \
      "DIRECT_API_ACCESS_TOKEN length: ${#fallback_rest_token}" \
      "S3_ENDPOINT_URL: ${S3_ENDPOINT_URL:-{{rustfs_endpoint}}}" \
      "S3_BUCKET: ${S3_BUCKET:-{{rustfs_bucket}}}"

# backward-compatible aliases

login: direct-login-bot

login-token token:
    @just --justfile {{justfile()}} direct-login-bot-token "{{token}}"

token-rest-login: direct-login-rest

token-rest-print: direct-rest-token-print

token-rest-export: direct-rest-token-export

s3-rustfs-up: s3-up

s3-rustfs-down: s3-down

s3-rustfs-logs: s3-logs

s3-rustfs-mk-bucket: s3-bucket-ready

rustfs-up: s3-prepare

run-native-rustfs: app-run
