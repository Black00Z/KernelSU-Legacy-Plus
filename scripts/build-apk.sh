#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANAGER="$ROOT/manager"
KSUD="$ROOT/userspace/ksud"
OUT="$ROOT/out"

say() { printf '\n==> %s\n' "$*"; }
fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

command -v java >/dev/null 2>&1 || fail "Java 21 is required. Install JDK 21 first."
command -v cargo >/dev/null 2>&1 || fail "Rust/Cargo is required. Install rustup + stable Rust first."
command -v rustup >/dev/null 2>&1 || fail "rustup is required."

JAVA_MAJOR="$(java -version 2>&1 | awk -F'[\".]' '/version/ {print $2; exit}')"
if [[ "${JAVA_MAJOR:-0}" -lt 21 ]]; then
  fail "Java 21+ required; found Java ${JAVA_MAJOR:-unknown}."
fi

SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$SDK" ]]; then
  for c in "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"; do
    [[ -d "$c" ]] && SDK="$c" && break
  done
fi
[[ -n "$SDK" && -d "$SDK" ]] || fail "Android SDK not found. Set ANDROID_SDK_ROOT (or ANDROID_HOME)."

NDK_VER="27.0.12077973"
NDK="$SDK/ndk/$NDK_VER"
[[ -d "$NDK" ]] || fail "Android NDK $NDK_VER not found at $NDK. Install it from Android Studio > SDK Manager > SDK Tools."

PREBUILT=""
for d in "$NDK/toolchains/llvm/prebuilt"/*; do
  [[ -d "$d/bin" ]] && PREBUILT="$d" && break
done
[[ -n "$PREBUILT" ]] || fail "NDK LLVM toolchain not found under $NDK/toolchains/llvm/prebuilt."

CLANG="$PREBUILT/bin/aarch64-linux-android26-clang"
[[ -x "$CLANG" ]] || fail "Android clang not found: $CLANG"

mkdir -p "$OUT" "$MANAGER/app/src/main/jniLibs/arm64-v8a"
printf 'sdk.dir=%s\n' "${SDK//\\//}" > "$MANAGER/local.properties"

say "Preparing Rust target"
rustup target add aarch64-linux-android

say "Building patched legacy ksud (arm64)"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$CLANG"
export CC_aarch64_linux_android="$CLANG"
export AR_aarch64_linux_android="$PREBUILT/bin/llvm-ar"
(
  cd "$KSUD"
  cargo build --target aarch64-linux-android --release --locked
)

KSUD_BIN="$KSUD/target/aarch64-linux-android/release/ksud"
[[ -f "$KSUD_BIN" ]] || fail "ksud build completed but binary was not found."
cp -f "$KSUD_BIN" "$MANAGER/app/src/main/jniLibs/arm64-v8a/libksud.so"

say "Building KernelSU Legacy+ debug APK"
(
  cd "$MANAGER"
  chmod +x ./gradlew
  ./gradlew --no-daemon clean assembleDebug
)

APK="$(find "$MANAGER/app/build/outputs/apk/debug" -maxdepth 1 -type f -name '*.apk' | head -n1 || true)"
[[ -n "$APK" ]] || fail "Gradle completed but no APK was found."
cp -f "$APK" "$OUT/KernelSU-LegacyPlus-Companion-debug.apk"

say "DONE"
printf 'APK: %s\n' "$OUT/KernelSU-LegacyPlus-Companion-debug.apk"
