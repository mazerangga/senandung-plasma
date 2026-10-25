#!/usr/bin/env bash
# Pasang/perbarui widget dari source, lengkap dengan modul romanisasi.
set -euo pipefail
cd "$(dirname "$0")"
[ -d contents/code/vendor ] || ./vendor.sh
id="$(python3 -c "import json;print(json.load(open('metadata.json'))['KPlugin']['Id'])")"
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$id"; then
    kpackagetool6 -t Plasma/Applet -u .
else
    kpackagetool6 -t Plasma/Applet -i .
fi
echo "Selesai. Muat ulang Plasma: kquitapp6 plasmashell && kstart plasmashell"
