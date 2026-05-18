#!/usr/bin/env bash
#
# Build the Rust NIF and copy the artefact into priv/lib/.
# Called by rebar3_cargo at compile time, but usable standalone for
# debugging the native crate.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

cd "$ROOT/native/hecate_vector_nif"
cargo build --release

mkdir -p "$ROOT/priv/lib"
case "$(uname -s)" in
    Linux*)   ext=so ;;
    Darwin*)  ext=dylib ;;
    MINGW*|MSYS*|CYGWIN*) ext=dll ;;
    *) echo "Unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

src="$ROOT/native/hecate_vector_nif/target/release/libhecate_vector_nif.${ext}"
dst="$ROOT/priv/lib/libhecate_vector_nif.${ext}"
cp "$src" "$dst"

echo "Built: $dst"
