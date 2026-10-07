#!/usr/bin/env bash
# Single-command release build for the Weather app.
#
# Usage:
#   tool/build.sh                    # release APK, prod flavor, split per ABI
#   tool/build.sh --flavor dev       # dev flavor build
#   tool/build.sh --target ipa       # release IPA (macOS only)
#
# The Sentry DSN is injected at build time (never in source):
#   SENTRY_DSN='https://<key>@o0.ingest.sentry.io/<id>' tool/build.sh   (EU DSN)
set -euo pipefail

cd "$(dirname "$0")/.."

FLAVOR="prod"
TARGET="apk"

while [ $# -gt 0 ]; do
  case "$1" in
    --flavor)
      FLAVOR="${2:?--flavor needs dev|prod}"; shift 2 ;;
    --flavor=*)
      FLAVOR="${1#--flavor=}"; shift ;;
    --target)
      TARGET="${2:?--target needs apk|ipa}"; shift 2 ;;
    --target=*)
      TARGET="${1#--target=}"; shift ;;
    *)
      echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

EXTRA_ARGS=()
if [ -n "${SENTRY_DSN:-}" ]; then
  EXTRA_ARGS+=("--dart-define=SENTRY_DSN=$SENTRY_DSN")
fi

echo "== flutter pub get --enforce-lockfile =="
flutter pub get --enforce-lockfile

echo "== analyze =="
flutter analyze

echo "== tests =="
flutter test

if [ "$TARGET" = "apk" ]; then
  echo "== build apk (flavor=$FLAVOR, split per ABI) =="
  flutter build apk --release --split-per-abi --flavor "$FLAVOR" "${EXTRA_ARGS[@]}"
  echo "== size gate (35 MB per ABI) =="
  for f in build/app/outputs/flutter-apk/*.apk; do
    size_mb=$(du -m "$f" | cut -f1)
    echo "  $f: ${size_mb} MB"
    if [ "$size_mb" -gt 35 ]; then
      echo "ERROR: $f exceeds the 35 MB per-ABI gate" >&2
      exit 1
    fi
  done
else
  echo "== build ipa (flavor=$FLAVOR) =="
  flutter build ipa --release --flavor "$FLAVOR" "${EXTRA_ARGS[@]}"
  ipa=$(find build/ios/ipa -name '*.ipa' | head -1)
  size_mb=$(du -m "$ipa" | cut -f1)
  echo "  $ipa: ${size_mb} MB"
  if [ "$size_mb" -gt 50 ]; then
    echo "ERROR: $ipa exceeds the 50 MB IPA gate" >&2
    exit 1
  fi
fi

echo "BUILD OK"
