#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

decode_base64() {
  if base64 --help 2>&1 | grep -q -- '--decode'; then
    base64 --decode
  else
    base64 -D
  fi
}

write_required_base64_file() {
  local env_var="$1"
  local relative_path="$2"
  local value="${!env_var:-}"

  if [[ -z "$value" ]]; then
    echo "Missing required environment variable: $env_var" >&2
    exit 1
  fi

  local target_path="$repo_root/$relative_path"
  mkdir -p "$(dirname "$target_path")"
  printf '%s' "$value" | decode_base64 > "$target_path"
  echo "Wrote $relative_path"
}

write_required_base64_file "ANDROID_GOOGLE_SERVICES_JSON_B64" "apps/mobile_app/android/app/google-services.json"
write_required_base64_file "IOS_GOOGLE_SERVICE_INFO_PLIST_B64" "apps/mobile_app/ios/Runner/GoogleService-Info.plist"
write_required_base64_file "FIREBASE_OPTIONS_DART_B64" "apps/mobile_app/lib/firebase_options.dart"
write_required_base64_file "FIREBASE_JSON_B64" "apps/mobile_app/firebase.json"
