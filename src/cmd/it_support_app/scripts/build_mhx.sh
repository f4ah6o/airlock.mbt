#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
MHX_DIR="$ROOT_DIR/repos/mhx.mbt"
OUT_JS="$MHX_DIR/dist/mhx.umd.js"
TARGET="$ROOT_DIR/repos/airlock.mbt/src/cmd/it_support_app/public/mhx.js"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm is required to build mhx runtime." >&2
  exit 1
fi

cd "$MHX_DIR"
pnpm build

if [[ ! -f "$OUT_JS" ]]; then
  echo "bundle not found: $OUT_JS" >&2
  exit 1
fi

cp "$OUT_JS" "$TARGET"
echo "Copied: $OUT_JS -> $TARGET"
