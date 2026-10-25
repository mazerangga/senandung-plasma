#!/usr/bin/env bash
# Membuat dist/senandung-plasma_<versi>.plasmoid dari folder sumber ini.
set -euo pipefail
cd "$(dirname "$0")"
ver="$(python3 -c "import json;print(json.load(open('metadata.json'))['KPlugin']['Version'])")"
mkdir -p dist
out="dist/senandung-plasma_${ver}.plasmoid"
rm -f "$out"
zip -qr "$out" metadata.json contents
echo "Dibuat: $out"
