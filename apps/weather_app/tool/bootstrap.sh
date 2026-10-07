#!/usr/bin/env bash
# Bootstrap the Weather app's platform scaffolds + dependency lock.
#
# What it does (idempotent — safe to re-run):
#   1. Requires a Flutter SDK on PATH (per .fvmrc: 3.44.4; `fvm use` if you
#      use FVM). Exits 1 with install instructions otherwise.
#   2. Runs `flutter create --platforms=<missing> .` ONLY for platforms
#      whose scaffold is missing. It never clobbers existing files:
#      android/app/src/main/res/xml/data_extraction_rules.xml (B-5 backup
#      rules) is checksummed before/after and restored on any mismatch.
#   3. Runs `flutter pub get` (generates pubspec.lock on first run).
#   4. Prints the manual platform steps the operator must apply by hand
#      (Android manifest additions, iOS Hive backup exclusion) — also
#      documented in README.md "Manual platform steps".
#
# After the first successful run: COMMIT pubspec.lock (CI's
# --enforce-lockfile stays as-is).
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: Flutter SDK not found on PATH." >&2
  echo "Install Flutter $(cat .fvmrc 2>/dev/null | tr -d '\n') per README.md" >&2
  echo "(or: fvm use), then re-run tool/bootstrap.sh." >&2
  exit 1
fi

RULES_XML="android/app/src/main/res/xml/data_extraction_rules.xml"
BACKUP=""
if [ -f "$RULES_XML" ]; then
  BACKUP="$(mktemp -d)/data_extraction_rules.xml"
  cp "$RULES_XML" "$BACKUP"
  echo "== backed up $RULES_XML (checksum $(sha256sum "$RULES_XML" | cut -d' ' -f1 | cut -c1-12)) =="
fi

# Scaffold markers: a platform counts as present only if flutter create's
# own marker files exist. The bare android/ dir in this repo holds just the
# hand-placed backup-rules file — not a scaffold.
MISSING=""
if [ ! -f "android/app/src/main/AndroidManifest.xml" ]; then
  MISSING="android"
fi
if [ ! -d "ios/Runner.xcodeproj" ] && [ ! -f "ios/Runner/AppDelegate.swift" ]; then
  MISSING="${MISSING:+$MISSING,}ios"
fi

if [ -n "$MISSING" ]; then
  echo "== flutter create --platforms=$MISSING . =="
  flutter create --org com.example --platforms="$MISSING" .
else
  echo "== platform scaffolds already present; skipping flutter create =="
fi

# B-6: the backup-rules file must survive, byte-for-byte.
if [ -n "$BACKUP" ]; then
  if [ ! -f "$RULES_XML" ]; then
    echo "error: $RULES_XML went missing during flutter create — restoring" >&2
    mkdir -p "$(dirname "$RULES_XML")"
    cp "$BACKUP" "$RULES_XML"
  elif ! cmp -s "$BACKUP" "$RULES_XML"; then
    echo "error: $RULES_XML was modified by flutter create — restoring the B-5 original" >&2
    cp "$BACKUP" "$RULES_XML"
  fi
  echo "== verified $RULES_XML intact =="
  rm -rf "$(dirname "$BACKUP")"
fi

echo "== flutter pub get =="
flutter pub get

cat <<'MANUAL'

================================================================
Manual platform steps (operator) — also in README.md:
================================================================

1) Android — android/app/src/main/AndroidManifest.xml, on <application>:
     android:usesCleartextTraffic="false"
     android:dataExtractionRules="@xml/data_extraction_rules"
   (Backup exclusion, B-5. The rules file ships at
   android/app/src/main/res/xml/data_extraction_rules.xml.)

2) iOS — exclude the Hive directory from backup. hive_ce_flutter's
   Hive.initFlutter() (called with no subDir in lib/main.dart) stores its
   boxes directly in the app's Documents directory
   (path_provider's getApplicationDocumentsDirectory). In
   ios/Runner/AppDelegate.swift, inside
   application(_:didFinishLaunchingWithOptions:) — BEFORE GeneratedPluginRegistrant:

     if var hiveDir = FileManager.default.urls(
         for: .documentDirectory, in: .userDomainMask).first {
         var values = URLResourceValues()
         values.isExcludedFromBackup = true
         try? hiveDir.setResourceValues(values)
     }

3) Commit pubspec.lock (generated above). CI's --enforce-lockfile
   verifies it; tool/build.sh resolves dependencies from it.
================================================================
MANUAL
