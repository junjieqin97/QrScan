#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
svg_file="${script_dir}/QrScanIcon.svg"
outdir="${script_dir}/../Assets.xcassets/AppIcon.appiconset"
output_file="${outdir}/icon_1024x1024.png"
temporary_file="${outdir}/icon_1024x1024.with-alpha.png"

command -v inkscape >/dev/null 2>&1 || {
    echo "Error: Inkscape is required to render the app icon." >&2
    exit 1
}

command -v xcrun >/dev/null 2>&1 || {
    echo "Error: Xcode command-line tools are required to remove PNG alpha." >&2
    exit 1
}

mkdir -p "$outdir"

inkscape \
    --export-type=png \
    --export-background="#F5F3EE" \
    --export-background-opacity=255 \
    "$svg_file" \
    -o "$temporary_file" \
    -w 1024 \
    -h 1024

xcrun pngcrush -q -rem alla "$temporary_file" "$output_file"
rm "$temporary_file"

echo "Generated: $output_file"
