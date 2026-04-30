#!/usr/bin/env bash
# Merge package-level lcov.info files into repo-root coverage/lcov.info for CI.
# Rewrites SF:lib/... to absolute paths so packages with the same relative layout
# do not corrupt each other's coverage when merged.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
mkdir -p coverage
tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

i=0
# Example app is omitted — coverage gate is per-package under packages/ only.
for f in packages/*/coverage/lcov.info; do
  if [[ -f "$f" ]]; then
    pkg_dir="$(dirname "$(dirname "$f")")"
    abs_lib="${root}/${pkg_dir}/lib"
    sed "s|^SF:lib/|SF:${abs_lib}/|g" "$f" >"${tmp}/part${i}.info"
    ((i += 1)) || true
  fi
done

if ((i == 0)); then
  echo "No coverage/lcov.info files found. Run: dart run melos run test:coverage --no-select" >&2
  exit 1
fi

args=()
for pf in "${tmp}"/part*.info; do
  [[ -f "$pf" ]] || continue
  args+=(-a "$pf")
done

lcov "${args[@]}" -o coverage/lcov.info --ignore-errors unused,empty
echo "Wrote coverage/lcov.info"
