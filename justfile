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
      if ! command -v aws >/dev/null 2>&1; then \
        echo "aws cli is required (install AWS CLI first)"; \
        exit 2; \
      fi; \
      endpoint="${S3_ENDPOINT_URL:-{{rustfs_endpoint}}}"; \
      bucket="${S3_BUCKET:-{{rustfs_bucket}}}"; \
      aws --endpoint-url "$endpoint" s3api create-bucket --bucket "$bucket" >/dev/null 2>&1 || true; \
      aws --endpoint-url "$endpoint" s3api head-bucket --bucket "$bucket"; \
      echo "bucket ready: $bucket at $endpoint"'

run-native-rustfs:
    @bash -ceu 'set -euo pipefail; \
      export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-{{rustfs_access_key}}}"; \
      export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-{{rustfs_secret_key}}}"; \
      export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"; \
      export S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-{{rustfs_endpoint}}}"; \
      export S3_BUCKET="${S3_BUCKET:-{{rustfs_bucket}}}"; \
      export S3_PREFIX="${S3_PREFIX:-direct4b}"; \
      export AIRLOCK_ATTACHMENT_UPLOAD_CMD="./src/cmd/it_support_app/scripts/upload_to_s3_compatible.sh"; \
      moon run src/cmd/it_support_app --target native'

info:
    moon info

clean:
    moon clean

release-check: fmt info check test
