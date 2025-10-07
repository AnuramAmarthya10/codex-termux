#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIG =====
REPO_DIR="$(dirname "$0")/.."  # Assuming script is in ci/
CODEX_DIR="$REPO_DIR/codex-rs"
OUTPUT_DIR="$REPO_DIR/termux_bin"
ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-/usr/local/lib/android/sdk/ndk/27.3.13750724}"

TARGETS=(
    "aarch64-linux-android:arm64-v8a:codex-aarch64"
    "armv7-linux-androideabi:armeabi-v7a:codex-armv7"
)

echo "🔹 Starting Android build for Codex"
echo "Repository directory: $REPO_DIR"
echo "Codex source: $CODEX_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "NDK root: $ANDROID_NDK_ROOT"
echo

# ===== Ensure Rust is installed =====
if ! command -v rustc &>/dev/null; then
    echo "Rust not found! Installing stable toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

echo "Using Rust: $(rustc --version)"
echo "Using Cargo: $(cargo --version)"
echo

# ===== Ensure cargo-ndk installed =====
if ! command -v cargo-ndk &>/dev/null; then
    echo "Installing cargo-ndk..."
    cargo install cargo-ndk --no-confirm
fi

echo "cargo-ndk version: $(cargo-ndk --version)"
echo

# ===== Prepare output directory =====
mkdir -p "$OUTPUT_DIR"

# ===== Loop over targets =====
for entry in "${TARGETS[@]}"; do
    IFS=":" read -r RUST_TARGET NDK_TARGET BIN_NAME <<< "$entry"
    
    echo "🔹 Building for $RUST_TARGET ($NDK_TARGET)..."

    # Ensure Rust target installed
    rustup target add "$RUST_TARGET"

    pushd "$CODEX_DIR" >/dev/null

    # Build using cargo-ndk
    cargo ndk -t "$NDK_TARGET" build --release

    # Copy binary to output dir
    cp "target/$RUST_TARGET/release/codex" "$OUTPUT_DIR/$BIN_NAME"

    echo "✅ Built binary: $OUTPUT_DIR/$BIN_NAME"
    popd >/dev/null
done

echo
echo "🎉 All builds completed!"
