#!/usr/bin/env bash
# CI: writes ./debug.keystore for the Android export. Same file in every game repo.
#   1. The keystone (signing/keystone.keystore.enc, unlocked by the KEYSTONE_PASS secret). If this
#      repo has no copy yet it is fetched from godot-game-starter (public), and its fingerprint must
#      match signing/keystone.sha256.
#   2. Else a throwaway key + a warning (that APK can't update an installed copy).
# Key inside: alias androiddebugkey, store/key password android. The encryption is the real lock.
set -uo pipefail
cd "$(dirname "$0")/.."
SRC=https://raw.githubusercontent.com/duffpowell-commits/godot-game-starter/main/signing
ENC=signing/keystone.keystore.enc
FP=signing/keystone.sha256
OUT=debug.keystore
strip() { printf '%s' "$1" | tr -d '[:space:]`'; }
fp_of() { keytool -list -keystore "$1" -storepass android 2>/dev/null \
  | grep -o '[0-9A-F]\{2\}\(:[0-9A-F]\{2\}\)\{31\}' | head -1; }
rm -f "$OUT"
if [ ! -f "$ENC" ] || [ ! -f "$FP" ]; then
  mkdir -p signing
  if curl -fsSL -o "$ENC.tmp" "$SRC/keystone.keystore.enc" && curl -fsSL -o "$FP.tmp" "$SRC/keystone.sha256"; then
    mv "$ENC.tmp" "$ENC"; mv "$FP.tmp" "$FP"; echo "Fetched the keystone from godot-game-starter"
  else
    rm -f "$ENC.tmp" "$FP.tmp"; echo "No keystone yet (run make keystone in godot-game-starter)"
  fi
fi
KP=$(strip "${KEYSTONE_PASS:-}")
if [ -n "$KP" ] && [ -f "$ENC" ]; then
  export KP
  if openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -in "$ENC" -out "$OUT" -pass env:KP 2>/dev/null \
     && [ "$(fp_of "$OUT")" = "$(tr -d '[:space:]' < "$FP")" ]; then
    echo "Signing with the keystone key, SHA-256 $(cat "$FP")"; exit 0
  fi
  rm -f "$OUT"
  echo "::error::KEYSTONE_PASS doesn't unlock the keystone (wrong passphrase, or the file changed)."
  exit 1
fi
[ -f "$ENC" ] && echo "::warning::KEYSTONE_PASS not set in this repo (docs/SIGNING.md)."
rm -f "$OUT"  # a failed decrypt can leave junk that keytool would refuse to overwrite
echo "::warning::Throwaway signing key: this APK can't update an installed copy. See docs/SIGNING.md"
keytool -genkeypair -keystore "$OUT" -storepass android -alias androiddebugkey -keypass android \
  -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" 2>&1 | grep -v "_JAVA_OPTIONS\|JAVA_TOOL_OPTIONS" || true
keytool -list -keystore "$OUT" -storepass android -alias androiddebugkey >/dev/null 2>&1 || { echo "::error::throwaway keystore unreadable"; exit 1; }
