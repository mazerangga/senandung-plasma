#!/usr/bin/env bash
# Mengunduh modul romanisasi (pykakasi, pypinyin, korean-romanizer, unidecode)
# ke contents/code/vendor supaya ikut terpasang bersama widget.
# Hanya butuh python3 + pip + internet saat dijalankan (bukan saat widget dipakai).
set -euo pipefail
cd "$(dirname "$0")"
dest="contents/code/vendor"
rm -rf "$dest"
python3 -m pip install --quiet --no-compile --upgrade --target "$dest" \
    -r requirements-vendor.txt
# buang yang tidak perlu / khusus platform (wrapt punya fallback Python murni)
rm -rf "$dest/bin" "$dest"/wrapt-stubs
find "$dest" -name '*.so' -delete
find "$dest" -name '__pycache__' -prune -exec rm -rf {} +
echo "Modul romanisasi terpasang di $dest ($(du -sh "$dest" | cut -f1))"
