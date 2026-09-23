#!/usr/bin/env bash
# Check that the published packages resolve and analyze on the Flutter/Dart SDK
# currently on PATH. CI runs this with Flutter pinned to the declared floor
# (see design/adr/0008-dependency-and-sdk-support-policy.md).
#
# Generated code (*.g.dart, *.freezed.dart) must already exist: run
# `melos run generate` with the contributor toolchain first.
#
# Each package is copied out of the workspace with its dev_dependencies removed,
# because the dev tooling needs a newer SDK than the published floor. Only lib/
# is analyzed, both at the latest and at the lowest allowed dependency versions.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
packages=(
  health_forge_core
  health_forge
  health_forge_apple
  health_forge_ghc
  health_forge_oura
  health_forge_strava
)
tmp="$(mktemp -d "${TMPDIR:-/tmp}/check_min_sdk.XXXXXX")"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

echo "SDK: $(dart --version 2>&1)"

for pkg in "${packages[@]}"; do
  src="${root}/packages/${pkg}"
  dst="${tmp}/packages/${pkg}"
  mkdir -p "$dst"
  cp -R "${src}/lib" "$dst/"
  # Drop workspace membership and dev dependencies.
  awk '
    /^resolution: workspace/ { next }
    /^dev_dependencies:/ { skip = 1; next }
    skip && /^[^[:space:]#]/ { skip = 0 }
    !skip { print }
  ' "${src}/pubspec.yaml" >"${dst}/pubspec.yaml"
  # Resolve the sibling core package from the local copy, since this version
  # may not be published yet.
  if [[ "$pkg" != health_forge_core ]]; then
    printf '\ndependency_overrides:\n  health_forge_core:\n    path: ../health_forge_core\n' \
      >>"${dst}/pubspec.yaml"
  fi
done

for pkg in "${packages[@]}"; do
  echo "::group::${pkg}"
  cd "${tmp}/packages/${pkg}"
  flutter pub get
  dart analyze lib
  flutter pub downgrade
  dart analyze lib
  echo "::endgroup::"
done

echo "All published packages resolve and analyze on this SDK."
