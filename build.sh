#!/usr/bin/env bash
# Membuat dist/senandung-plasma_<versi>.plasmoid dari folder sumber ini.
set -euo pipefail
cd "$(dirname "$0")"
ver="$(python3 -c "import json;print(json.load(open('metadata.json'))['KPlugin']['Version'])")"
[ -d contents/code/vendor ] || ./vendor.sh
# terjemahan: po/<bahasa>.po -> contents/locale/<bahasa>/LC_MESSAGES/*.mo
# (bahasa sumber = Indonesia; tanpa msgfmt widget tetap jalan, hanya tanpa terjemahan)
id="$(python3 -c "import json;print(json.load(open('metadata.json'))['KPlugin']['Id'])")"
rm -rf contents/locale
if command -v msgfmt >/dev/null 2>&1; then
    for po in po/*.po; do
        [ -e "$po" ] || continue
        lang="$(basename "$po" .po)"
        mkdir -p "contents/locale/$lang/LC_MESSAGES"
        msgfmt -o "contents/locale/$lang/LC_MESSAGES/plasma_applet_${id}.mo" "$po"
    done
else
    echo "Peringatan: msgfmt tidak ada (paket gettext); terjemahan dilewati." >&2
fi
mkdir -p dist
out="dist/senandung-plasma_${ver}.plasmoid"
rm -f "$out"
zip -qr "$out" metadata.json contents
echo "Dibuat: $out"
