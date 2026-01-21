#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../../../.." && pwd)"
BUNDLE_DIR="$ROOT_DIR/htmx_bundle.mbt"
OUT_JS="$BUNDLE_DIR/_build/js/release/build/cmd/htmx_bundle/htmx_bundle.js"
TARGET="$ROOT_DIR/airlock/src/cmd/it_support_app/public/htmx.js"

cd "$BUNDLE_DIR"
moon build --target js

if [[ ! -f "$OUT_JS" ]]; then
  echo "bundle not found: $OUT_JS" >&2
  exit 1
fi

cp "$OUT_JS" "$TARGET"
echo "Copied: $OUT_JS -> $TARGET"
