#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 mazerangga
# SPDX-License-Identifier: GPL-3.0-or-later
"""Romanisasi baris lirik.

stdin : JSON array of string (teks tiap baris lirik)
stdout: JSON array of string (hasil romanisasi, panjang sama)

Jepang  -> pykakasi (Hepburn)
Mandarin-> pypinyin (pinyin dengan tanda nada)
Korea   -> korean-romanizer
Lainnya (Cyrillic, Yunani, Arab, Thai, ...) -> unidecode
Modul yang tidak terpasang dilewati; barisnya dikembalikan apa adanya.
"""
import json
import os
import re
import sys

# Modul bawaan widget (contents/code/vendor), dipakai bila tidak ada di environment Python.
_VENDOR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vendor")
if os.path.isdir(_VENDOR):
    sys.path.append(_VENDOR)

try:
    sys.stdin.reconfigure(encoding="utf-8")
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

KANA = re.compile(r"[\u3040-\u30ff\u31f0-\u31ff]")
HAN = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff]")
HANGUL = re.compile(r"[\u1100-\u11ff\u3130-\u318f\uac00-\ud7af]")
OTHER = re.compile(r"[\u0370-\u03ff\u0400-\u052f\u0590-\u06ff\u0900-\u0dff\u0e00-\u0eff]")

_cache = {}


def lib(name):
    if name not in _cache:
        try:
            if name == "kakasi":
                import pykakasi
                _cache[name] = pykakasi.kakasi()
            elif name == "pinyin":
                from pypinyin import lazy_pinyin, Style
                _cache[name] = (lazy_pinyin, Style)
            elif name == "korean":
                from korean_romanizer.romanizer import Romanizer
                _cache[name] = Romanizer
            elif name == "unidecode":
                from unidecode import unidecode
                _cache[name] = unidecode
        except Exception as e:
            sys.stderr.write("romanize: modul '%s' tidak tersedia (%s)\n" % (name, e))
            _cache[name] = None
    return _cache[name]


PUNCT = str.maketrans({
    "，": ",", "。": ".", "、": ",", "！": "!", "？": "?", "：": ":", "；": ";",
    "（": "(", "）": ")", "　": " ",
})


def tidy(s):
    s = s.translate(PUNCT)
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"\s+([,.!?;:)\]」』”’])", r"\1", s)
    s = re.sub(r"([(\[「『“‘])\s+", r"\1", s)
    return s[:1].upper() + s[1:] if s else s


def japanese(text):
    k = lib("kakasi")
    if not k:
        return ""
    return tidy(" ".join(i["hepburn"] for i in k.convert(text)))


def chinese(text):
    p = lib("pinyin")
    if not p:
        return ""
    lazy_pinyin, Style = p
    return tidy(" ".join(lazy_pinyin(text, style=Style.TONE)))


def korean(text):
    R = lib("korean")
    if R:
        try:
            return tidy(R(text).romanize())
        except Exception:
            pass
    return other(text)


def other(text):
    u = lib("unidecode")
    return tidy(u(text)) if u else ""


def main():
    lines = json.load(sys.stdin)
    song_is_japanese = any(KANA.search(l) for l in lines)
    out = []
    for l in lines:
        if KANA.search(l):
            r = japanese(l)
        elif HAN.search(l):
            r = japanese(l) if song_is_japanese else chinese(l)
        elif HANGUL.search(l):
            r = korean(l)
        elif OTHER.search(l):
            r = other(l)
        else:
            r = ""          # sudah huruf Latin: tidak perlu romanisasi
        out.append(r)
    json.dump(out, sys.stdout, ensure_ascii=True)   # ASCII murni: aman dari salah-decode


main()
