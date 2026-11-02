#!/usr/bin/env bash
# Read-only checks before building the TG Cipher standalone client.
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
ok() { printf 'OK: %s\n' "$1"; }
prop() {
  local key="$1"
  if [[ -f local.properties ]]; then
    grep -m1 "^$key=" local.properties | cut -d= -f2- | tr -d '\r' || true
  fi
}

[[ -f gradle.properties ]] || fail "gradle.properties tidak ditemukan"
[[ -f TMessagesProj/google-services.json ]] || fail "google-services.json tidak ditemukan"

app_package="$(sed -n 's/^APP_PACKAGE=//p' gradle.properties | tail -n 1 | tr -d '\r')"
[[ "$app_package" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$ ]] || fail "APP_PACKAGE belum valid"
[[ "$app_package" != org.telegram.messenger* ]] || fail "Ganti APP_PACKAGE bawaan Telegram terlebih dahulu"
ok "Package khusus fork sudah diatur"

api_id="${TG_CIPHER_API_ID:-$(prop TG_CIPHER_API_ID)}"
api_hash="${TG_CIPHER_API_HASH:-$(prop TG_CIPHER_API_HASH)}"
[[ "$api_id" =~ ^[0-9]+$ && "$api_id" != "0" && "$api_id" != "4" ]] || fail "TG_CIPHER_API_ID belum diisi dengan API ID milik Anda"
[[ "$api_hash" =~ ^[a-fA-F0-9]{32}$ && "$api_hash" != "014b35b6184100b085b0d0572f9b5103" ]] || fail "TG_CIPHER_API_HASH belum diisi dengan API hash milik Anda"
ok "Kredensial Telegram tersedia (nilai tidak ditampilkan)"

# Standalone uses APP_PACKAGE exactly (no upstream .web suffix).
effective_package="$app_package"
if ! grep -Fq "$effective_package" TMessagesProj/google-services.json; then
  fail "Firebase config tidak mencantumkan package $effective_package"
fi
ok "Firebase config mencantumkan package standalone"

# Original release.keystore is a tracked upstream dummy. It must be replaced
# temporarily at build time, not committed.
if git cat-file -e HEAD:TMessagesProj/config/release.keystore 2>/dev/null; then
  if git show HEAD:TMessagesProj/config/release.keystore | cmp -s - TMessagesProj/config/release.keystore; then
    fail "release.keystore masih identik dengan dummy bawaan Git"
  fi
fi
ok "Signing keystore tidak identik dengan dummy yang terlacak"

printf 'READY: Pemeriksaan dasar lolos. Keberhasilan build/login belum diuji.\n'
