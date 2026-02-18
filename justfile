# https://github.com/mizchi/moonbit-template
# SPDX-License-Identifier: MIT
# MoonBit Project Commands

target := "js"
rustfs_container := "airlock-rustfs"
rustfs_data_dir := "_local/rustfs-data"
rustfs_endpoint := "http://127.0.0.1:9000"
rustfs_console := "http://127.0.0.1:9001"
rustfs_access_key := "rustfsadmin"
rustfs_secret_key := "rustfsadmin"
rustfs_bucket := "airlock-attachments"
awslim_s3_bin := "../awslim/awslim-s3"

default: check test

fmt:
    moon fmt

check:
    moon check --deny-warn --target {{target}}

test:
    moon test --target {{target}}

test-update:
    moon test --update --target {{target}}

run:
    moon run src/main --target {{target}}

run-native:
    moon run src/cmd/it_support_app --target native

login:
    @bash -ceu 'set -euo pipefail; \
      if command -v opz >/dev/null 2>&1; then \
        opz daab-dev -- moon -C ../direct_sdk.mbt run src/daab --target native -- login --force; \
      else \
        moon -C ../direct_sdk.mbt run src/daab --target native -- login --force; \
      fi'

login-token token:
    @bash -ceu 'set -euo pipefail; \
      if command -v opz >/dev/null 2>&1; then \
        opz daab-dev -- moon -C ../direct_sdk.mbt run src/daab --target native -- login --token "{{token}}" --force; \
      else \
        moon -C ../direct_sdk.mbt run src/daab --target native -- login --token "{{token}}" --force; \
      fi'

s3-rustfs-up:
    @bash -ceu 'set -euo pipefail; \
      mkdir -p "{{rustfs_data_dir}}"; \
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
      echo "rustfs started: {{rustfs_endpoint}} (console: {{rustfs_console}})"'

s3-rustfs-down:
    @bash -ceu 'set -euo pipefail; \
      if docker ps -a --format "{{"{{"}}.Names{{"}}"}}" | grep -qx "{{rustfs_container}}"; then \
        docker rm -f "{{rustfs_container}}" >/dev/null; \
        echo "rustfs stopped: {{rustfs_container}}"; \
      else \
        echo "rustfs container not found: {{rustfs_container}}"; \
      fi'

s3-rustfs-logs:
    docker logs -f {{rustfs_container}}

s3-rustfs-mk-bucket:
    @bash -ceu 'set -euo pipefail; \
      awslim_bin="${AWSLIM_S3_BIN:-{{awslim_s3_bin}}}"; \
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
      echo "bucket ready: $bucket at $endpoint"'

rustfs-up: s3-rustfs-up s3-rustfs-mk-bucket

run-native-rustfs:
    @bash -ceu 'set -euo pipefail; \
      export AWSLIM_S3_BIN="${AWSLIM_S3_BIN:-{{awslim_s3_bin}}}"; \
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
      export AIRLOCK_ATTACHMENT_UPLOAD_CMD="./src/cmd/it_support_app/scripts/upload_to_s3_compatible.sh"; \
      moon run src/cmd/it_support_app --target native'

info:
    moon info

clean:
    moon clean

release-check: fmt info check test
