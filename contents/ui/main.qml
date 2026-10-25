// SPDX-FileCopyrightText: 2026 mazerangga
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import "../code/strings.js" as Strings

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Component.onCompleted: console.log("SenandungPlasma v1.0 dimulai, geser waktu global = " + cfg.offsetMs + " ms")

    // ---- state ----
    property string playState: ""
    property real positionMs: 0
    property real basePosMs: 0          // posisi terakhir dari pemutar
    property double baseStamp: 0        // kapan posisi itu dibaca (Date.now)
    property real lengthMs: 0
    property string artist: ""
    property string title: ""
    property string trackKey: ""
    property var lyrics: []
    property int currentIndex: -1
    property string message: tr("Menunggu pemutar…")
    property var cache: ({})
    property int songOffset: 0          // geser waktu khusus lagu ini (tag [offset:] di file .lrc)
    property string toastText: ""
    property bool toastOn: false
    // panel cari / tempel / file
    property bool panelOpen: false
    property int panelTab: 0
    property var panelSong: ({ artist: "", title: "", length: 0 })
    property string searchArtist: ""
    property string searchTitle: ""
    property string searchStatus: ""
    property var searchResults: []

    readonly property var cfg: Plasmoid.configuration

    // terjemahan antarmuka: Indonesia (bawaan) atau English, sesuai pengaturan Bahasa
    function tr(text) {
        return Strings.tr(cfg.language, text, Array.prototype.slice.call(arguments, 1))
    }
    readonly property var allowedPlayers: (cfg.playerName || "").toLowerCase()
        .split(",").map(function (x) { return x.trim() }).filter(function (x) { return x !== "" })
    // Pemutar yang diabaikan saat daftar "Pemutar" kosong (browser dianggap bukan pemutar musik,
    // supaya video YouTube dsb. tidak dikira lagu). Nama "firefox.instance123" dicocokkan lewat "firefox".
    readonly property var blockedPlayers: (cfg.blacklist || "").toLowerCase()
        .split(",").map(function (x) { return x.trim() }).filter(function (x) { return x !== "" })
    readonly property string cmd: "playerctl -a metadata --format "
        + "'{{playerName}}|||{{status}}|||{{position}}|||{{mpris:length}}|||{{artist}}|||{{title}}' 2>/dev/null"
        + " | while IFS= read -r l; do printf %s \"$l\" | base64 -w0; printf '\\n'; done"
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: tr("Cari lirik online…")
            icon.name: "edit-find"
            onTriggered: root.openPanel(0)
        },
        PlasmaCore.Action {
            text: tr("Tempel teks lirik (.lrc)…")
            icon.name: "edit-paste"
            onTriggered: root.openPanel(1)
        },
        PlasmaCore.Action {
            text: tr("Buka file lirik (.lrc)…")
            icon.name: "document-open"
            onTriggered: root.openPanel(2)
        }
    ]

    readonly property var alignments: [Text.AlignLeft, Text.AlignHCenter, Text.AlignRight]

    Plasma5Support.DataSource {
        engine: "executable"
        connectedSources: [root.cmd]
        interval: 300
        onNewData: (sourceName, data) => root.handleOutput((data["stdout"] || "").trim())
    }

    function handleOutput(out) {
        var best = null
        var bestScore = -100000
        var lines = out === "" ? [] : out.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var p = b64dec(lines[i]).split("|||")
            if (p.length < 6) continue
            var rank = 0
            if (allowedPlayers.length > 0) {
                rank = allowedPlayers.indexOf(p[0].toLowerCase())
                if (rank < 0) continue          // bukan pemutar yang dipilih
            } else if (blockedPlayers.indexOf(p[0].toLowerCase().split(".")[0]) >= 0) {
                continue                        // pemutar masuk blacklist (mis. browser)
            }
            // utamakan yang sedang Playing, lalu Paused, lalu urutan daftar
            var score = (p[1] === "Playing" ? 1000 : (p[1] === "Paused" ? 500 : 0)) - rank
            if (score > bestScore) {
                bestScore = score
                best = p
            }
        }
        if (best === null) {
            if (out === "")
                diag("playerctl tidak mengembalikan pemutar (belum ada lagu diputar, atau playerctl tidak terpasang)")
            else
                diag("tidak ada pemutar yang cocok (daftar pemutar: '" + (cfg.playerName || "") + "', blacklist: '" + (cfg.blacklist || "") + "')")
            message = tr("Menunggu pemutar…")
            if (trackKey !== "" || lyrics.length > 0) {
                trackKey = ""
                lyrics = []
                currentIndex = -1
            }
            return
        }
        var prevState = playState
        playState = best[1]
        var reported = parseInt(best[2]) / 1000
        var now = Date.now()
        var est = prevState === "Playing" ? basePosMs + (now - baseStamp) : basePosMs
        var diff = reported - est
        var sameTrack = trackKey === artistTitleKey(best)
        if (prevState === "Playing" && best[1] === "Playing" && sameTrack && diff <= 0 && diff > -1500) {
            // Posisi dari pemutar tertinggal dari perkiraan kita (pemutar sering membulatkan
            // posisi atau melapor telat, mis. Amarok). Jangan mundur: pertahankan perkiraan.
            // Perkiraan otomatis maju lagi begitu laporan pemutar menyusul.
        } else {
            basePosMs = reported        // maju / lompat posisi / lagu baru / baru lanjut play
            baseStamp = now
        }
        positionMs = estimatedPos(now)
        lengthMs = parseInt(best[3]) / 1000
        artist = best[4]
        title = best[5]
        var key = artist + "|" + title
        if (key !== trackKey) {
            trackKey = key
            loadLyrics(artist, title, Math.round(lengthMs / 1000))
        }
        updateIndex()
    }

    function artistTitleKey(p) {
        return p[4] + "|" + p[5]
    }

    // posisi lagu saat ini diperkirakan dari pembacaan terakhir + waktu yang berlalu
    function estimatedPos(now) {
        if (playState === "Playing") return basePosMs + (now - baseStamp)
        return basePosMs
    }

    // perbarui baris aktif tiap 50 ms (tanpa menunggu polling berikutnya)
    Timer {
        interval: 50
        repeat: true
        running: root.playState === "Playing" && root.lyrics.length > 0
        onTriggered: root.updateIndex()
    }

    function updateIndex() {
        positionMs = estimatedPos(Date.now())
        var t = positionMs + cfg.offsetMs + songOffset
        var idx = -1
        for (var i = 0; i < lyrics.length; i++) {
            if (lyrics[i].time <= t) idx = i
            else break
        }
        if (idx !== currentIndex) currentIndex = idx
    }

    // Mendukung [mm:ss.xx], [mm:ss.xxx], [mm:ss:xx], beberapa tag per baris, dan
    // membuang tag kata <mm:ss.xx> (enhanced LRC). Teks dalam kurung siku di isi lirik dipertahankan.
    function parseLrc(text) {
        var out = []
        var lines = String(text).split(/\r?\n/)
        var tagRe = /^\s*\[\s*(\d+)\s*:\s*(\d{1,2}(?:[.:]\d+)?)\s*\]/
        for (var i = 0; i < lines.length; i++) {
            var rest = lines[i]
            var times = []
            var m
            while ((m = tagRe.exec(rest)) !== null) {
                times.push(parseInt(m[1], 10) * 60000 + Math.round(parseFloat(m[2].replace(":", ".")) * 1000))
                rest = rest.substring(m[0].length)
            }
            if (times.length === 0) continue          // metadata ([ar:], [ti:], [offset:] ...)
            var txt = rest.replace(/<\d+:\d{1,2}(?:[.:]\d+)?>/g, "").trim()
            for (var j = 0; j < times.length; j++)
                out.push({ time: times[j], text: txt })
        }
        out.sort(function (a, b) { return a.time - b.time })
        return out
    }

    // [offset:+300] -> lirik tampil 300 ms lebih awal (standar LRC)
    function parseOffset(raw) {
        var m = /^\s*\[offset:\s*([+-]?\d+)\s*\]\s*$/im.exec(String(raw))
        return m ? parseInt(m[1], 10) : 0
    }

    function parseLrcWithOffset(raw) {
        var list = parseLrc(raw)
        if (list.length > 0) list[0]._offset = parseOffset(raw)   // dititipkan di baris pertama
        return list
    }

    function setLyrics(list, key) {
        if (key !== trackKey) return
        if (list.length === 0) {
            lyrics = []
            currentIndex = -1
            message = tr("Lirik tersinkron tidak ditemukan")
        } else {
            songOffset = list[0]._offset || 0
            lyrics = list
            updateIndex()
        }
    }

    function fetchJson(url, cb) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            var res = null
            if (xhr.status !== 200) console.log("SenandungPlasma: HTTP " + xhr.status + " untuk " + url)
            if (xhr.status === 200) {
                try { res = JSON.parse(xhr.responseText) } catch (e) { res = null }
            }
            cb(res)
        }
        xhr.open("GET", url)
        xhr.send()
    }

    // ---- eksekusi perintah shell satu kali (baca/tulis file lokal) ----
    property var shellCallbacks: ({})
    property int shellCounter: 0

    Plasma5Support.DataSource {
        id: shell
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            var cb = root.shellCallbacks[sourceName]
            delete root.shellCallbacks[sourceName]
            if (cb) cb((data["stdout"] || ""), data["exit code"])
        }
    }

    function runShell(command, cb) {
        var c = ": " + (++shellCounter) + "; " + command
        shellCallbacks[c] = cb
        shell.connectSource(c)
    }

    function shq(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    // Semua teks non-ASCII (judul, nama file, isi lirik) dilewatkan sebagai base64
    // karena keluaran/argumen perintah shell bisa salah di-decode (mojibake).
    // Codec ditulis murni JavaScript agar tidak bergantung pada fungsi base64 bawaan Qt.
    readonly property string b64chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    function toUtf8Bytes(str) {
        var out = []
        for (var i = 0; i < str.length; i++) {
            var c = str.charCodeAt(i)
            if (c >= 0xD800 && c < 0xDC00 && i + 1 < str.length) {
                var d = str.charCodeAt(i + 1)
                if (d >= 0xDC00 && d < 0xE000) {
                    c = 0x10000 + ((c - 0xD800) << 10) + (d - 0xDC00)
                    i++
                }
            }
            if (c < 0x80) out.push(c)
            else if (c < 0x800) out.push(0xC0 | (c >> 6), 0x80 | (c & 63))
            else if (c < 0x10000) out.push(0xE0 | (c >> 12), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63))
            else out.push(0xF0 | (c >> 18), 0x80 | ((c >> 12) & 63), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63))
        }
        return out
    }

    function fromUtf8Bytes(b) {
        var s = ""
        var i = 0
        while (i < b.length) {
            var c = b[i++]
            if (c < 0x80) {
                s += String.fromCharCode(c)
            } else if (c >= 0xC0 && c < 0xE0) {
                var c1 = b[i++] & 63
                s += String.fromCharCode(((c & 31) << 6) | c1)
            } else if (c >= 0xE0 && c < 0xF0) {
                var d1 = b[i++] & 63
                var d2 = b[i++] & 63
                s += String.fromCharCode(((c & 15) << 12) | (d1 << 6) | d2)
            } else if (c >= 0xF0) {
                var e1 = b[i++] & 63
                var e2 = b[i++] & 63
                var e3 = b[i++] & 63
                var cp = (((c & 7) << 18) | (e1 << 12) | (e2 << 6) | e3) - 0x10000
                s += String.fromCharCode(0xD800 + (cp >> 10), 0xDC00 + (cp & 1023))
            }
        }
        return s
    }

    function b64enc(str) {
        var b = toUtf8Bytes(String(str))
        var ch = b64chars
        var o = ""
        for (var i = 0; i < b.length; i += 3) {
            var n = (b[i] << 16) | ((b[i + 1] || 0) << 8) | (b[i + 2] || 0)
            o += ch.charAt((n >> 18) & 63) + ch.charAt((n >> 12) & 63)
                + (i + 1 < b.length ? ch.charAt((n >> 6) & 63) : "=")
                + (i + 2 < b.length ? ch.charAt(n & 63) : "=")
        }
        return o
    }

    function b64dec(str) {
        var clean = String(str).replace(/[^A-Za-z0-9+\/]/g, "")
        var bytes = []
        var buf = 0
        var bits = 0
        for (var i = 0; i < clean.length; i++) {
            buf = (buf << 6) | b64chars.indexOf(clean.charAt(i))
            bits += 6
            if (bits >= 8) {
                bits -= 8
                bytes.push((buf >> bits) & 255)
                buf &= (1 << bits) - 1
            }
        }
        return fromUtf8Bytes(bytes)
    }

    // jalankan fn setelah ms milidetik (jaring pengaman bila perintah shell tidak membalas)
    function afterDelay(ms, fn) {
        var t = Qt.createQmlObject('import QtQuick; Timer { repeat: false }', root)
        t.interval = ms
        t.triggered.connect(function () { fn(); t.destroy() })
        t.start()
    }

    property string lastDiag: ""
    function diag(msg) {
        if (msg !== lastDiag) {
            lastDiag = msg
            console.log("SenandungPlasma: " + msg)
        }
    }

    // d=<folder> (~ diperluas ke $HOME)
    function dirSnippet() {
        return 'd="$(printf %s ' + b64enc(cfg.lyricsDir || "~/lyrics") + ' | base64 -d)"; '
            + 'case "$d" in "~"*) d="$HOME${d#"~"}";; esac; '
    }

    // f=<nama file>
    function fileSnippet(name) {
        return 'f="$(printf %s ' + b64enc(name) + ' | base64 -d)"; '
    }

    function lrcFileName(artistName, trackName) {
        var n = (artistName + " - " + trackName)
            .replace(/[\/\\:*?"<>|\n\r\t]/g, " ")
            .replace(/\s+/g, " ").trim()
        if (n.length > 150) n = n.substring(0, 150).trim()
        return n + ".lrc"
    }

    function readLocal(artistName, trackName, cb) {
        var cmd = dirSnippet() + fileSnippet(lrcFileName(artistName, trackName))
            + 'base64 -w0 "$d"/"$f" 2>/dev/null'
        runShell(cmd, function (out) { cb(b64dec(out)) })
    }

    function saveLocal(artistName, trackName, raw) {
        if (!cfg.saveLocal) return
        var b64 = b64enc(raw)
        var cmd = dirSnippet() + fileSnippet(lrcFileName(artistName, trackName))
            + 'mkdir -p "$d" && printf %s ' + b64 + ' | base64 -d > "$d"/"$f"'
        runShell(cmd, function () {})
    }

    // ---- romanisasi (Jepang, Mandarin, Korea, dll) ----
    readonly property string romanScript:
        decodeURIComponent(Qt.resolvedUrl("../code/romanize.py").toString().replace(/^file:\/\//, ""))

    function needsRoman(list) {
        var re = /[\u0370-\u052f\u0590-\u06ff\u0900-\u0eff\u1100-\u11ff\u3040-\u30ff\u3130-\u318f\u3400-\u9fff\uac00-\ud7af]/
        for (var i = 0; i < list.length; i++)
            if (re.test(list[i].text)) return true
        return false
    }

    function runRoman(list, cb) {
        var texts = list.map(function (x) { return x.text })
        var b64 = b64enc(JSON.stringify(texts))
        var cmd = "printf %s " + b64 + " | base64 -d | python3 " + shq(romanScript)
        runShell(cmd, function (out, code) {
            var res = null
            try { res = JSON.parse(out) } catch (e) { res = null }
            if (!res || res.length !== list.length) {
                console.log("SenandungPlasma: romanisasi gagal (exit " + code + "). Cek modul Python.")
                res = null
            }
            cb(res)
        })
    }

    function pad2(n) { return (n < 10 ? "0" : "") + n }

    function fmtTime(ms) {
        var cs = Math.round(ms / 10)
        return "[" + pad2(Math.floor(cs / 6000)) + ":" + pad2(Math.floor((cs % 6000) / 100))
            + "." + pad2(cs % 100) + "]"
    }

    function romanFileName(artistName, trackName) {
        return lrcFileName(artistName, trackName).replace(/\.lrc$/, ".romaji.lrc")
    }

    // file romaji dianggap valid jika jumlah baris dan waktunya sama dengan lirik asli
    function romanFileMatches(list, rlist) {
        if (rlist.length !== list.length) return false
        for (var i = 0; i < list.length; i++)
            if (Math.abs(list[i].time - rlist[i].time) > 30) return false
        return true
    }

    function applyRoman(list, texts) {
        for (var i = 0; i < list.length; i++) {
            var r = texts[i] || ""
            list[i].roman = (r === list[i].text) ? "" : r
        }
    }

    function saveRomanFile(artistName, trackName, list) {
        if (!cfg.saveLocal) return
        var any = false
        var rows = []
        for (var i = 0; i < list.length; i++) {
            var r = list[i].roman || ""
            if (r !== "") any = true
            rows.push(fmtTime(list[i].time) + (r !== "" ? r : list[i].text))
        }
        if (!any) return                       // tidak ada yang berhasil dikonversi
        var b64 = b64enc(rows.join("\n") + "\n")
        var cmd = dirSnippet() + fileSnippet(romanFileName(artistName, trackName))
            + 'mkdir -p "$d" && printf %s ' + b64 + ' | base64 -d > "$d"/"$f"'
        runShell(cmd, function () {})
    }

    // satu pintu keluar: romaji dari file lokal -> atau konversi baru + simpan -> tampilkan
    function deliver(list, key, artistName, trackName) {
        var shown = false
        function show() {
            if (shown) return
            shown = true
            cache[key] = list
            setLyrics(list, key)
        }

        if (list.length === 0 || !cfg.romanize || !needsRoman(list)) {
            show()
            return
        }

        // jaring pengaman: apa pun yang terjadi, lirik tetap tampil
        afterDelay(12000, show)

        var converting = false
        function convert() {
            if (converting) return
            converting = true
            runRoman(list, function (res) {
                if (res) {
                    applyRoman(list, res)
                    saveRomanFile(artistName, trackName, list)
                    console.log("SenandungPlasma: romanisasi selesai")
                }
                show()
            })
        }

        if (!cfg.saveLocal) {
            convert()
            return
        }
        afterDelay(4000, convert)
        var cmd = dirSnippet() + fileSnippet(romanFileName(artistName, trackName))
            + 'base64 -w0 "$d"/"$f" 2>/dev/null'
        runShell(cmd, function (raw) {
            if (converting) return
            var out = b64dec(raw)
            if (out.trim() !== "") {
                var rlist = parseLrc(out)
                if (romanFileMatches(list, rlist)) {
                    converting = true
                    console.log("SenandungPlasma: romaji dimuat dari file lokal")
                    applyRoman(list, rlist.map(function (x) { return x.text }))
                    show()
                    return
                }
            }
            convert()
        })
    }

    // ganti pengaturan -> muat ulang lirik lagu yang sedang diputar
    Connections {
        target: Plasmoid.configuration
        function onRomanizeChanged() { root.reload() }
        function onRomanModeChanged() { root.reload() }
        function onLanguageChanged() { root.reload() }
    }

    function reload() {
        cache = {}
        trackKey = ""
    }

    function loadLyrics(artistName, trackName, durationSec) {
        var key = artistName + "|" + trackName
        lyrics = []
        currentIndex = -1
        songOffset = 0
        console.log("SenandungPlasma: lagu: " + artistName + " - " + trackName)
        if (cache[key]) {
            setLyrics(cache[key], key)
            return
        }
        message = tr("Mencari lirik…")

        var proceeded = false
        function proceed(out) {
            if (proceeded) return
            proceeded = true
            if (key !== trackKey) return
            // 1) file .lrc lokal
            if (out && out.trim() !== "") {
                var local = parseLrcWithOffset(out)
                if (local.length > 0) {
                    console.log("SenandungPlasma: lirik dimuat dari file lokal")
                    deliver(local, key, artistName, trackName)
                    return
                }
            }
            // 2) tidak ada: ambil dari LRCLIB lalu simpan
            fetchOnline(artistName, trackName, durationSec, key)
        }
        readLocal(artistName, trackName, proceed)
        afterDelay(4000, function () { proceed("") })    // jaring pengaman
    }

    function fetchOnline(artistName, trackName, durationSec, key) {
        var base = "https://lrclib.net/api/"
        var q = "artist_name=" + encodeURIComponent(artistName)
              + "&track_name=" + encodeURIComponent(trackName)

        function finish(raw) {
            var list = raw ? parseLrcWithOffset(raw) : []
            console.log("SenandungPlasma: LRCLIB " + (list.length > 0 ? "menemukan " + list.length + " baris" : "tidak menemukan lirik tersinkron"))
            if (list.length > 0) saveLocal(artistName, trackName, raw)
            deliver(list, key, artistName, trackName)
        }

        fetchJson(base + "get?" + q + (durationSec > 0 ? "&duration=" + durationSec : ""), function (res) {
            if (res && res.syncedLyrics) {
                finish(res.syncedLyrics)
                return
            }
            fetchJson(base + "search?" + q, function (arr) {
                // versi live/remaster beda durasi -> ambil yang durasinya paling dekat dengan lagu
                var best = null
                if (arr && arr.length) {
                    for (var i = 0; i < arr.length; i++) {
                        if (!arr[i].syncedLyrics) continue
                        if (best === null || (durationSec > 0
                                && Math.abs((arr[i].duration || 0) - durationSec)
                                   < Math.abs((best.duration || 0) - durationSec)))
                            best = arr[i]
                    }
                }
                if (best && durationSec > 0 && Math.abs((best.duration || 0) - durationSec) > 5)
                    console.log("SenandungPlasma: peringatan, durasi LRCLIB " + best.duration + " dtk vs pemutar " + durationSec + " dtk")
                finish(best ? best.syncedLyrics : "")
            })
        })
    }

    // ---- toast, offset per lagu, cari / tempel / buka file ----
    function showToast(text) {
        toastText = text
        toastOn = true
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 2200
        onTriggered: root.toastOn = false
    }

    property string offsetArtist: ""
    property string offsetTitle: ""

    function nudgeOffset(d) {
        songOffset = Math.max(-10000, Math.min(10000, songOffset + d))
        if (lyrics.length > 0) lyrics[0]._offset = songOffset      // supaya cache ikut benar
        offsetArtist = artist
        offsetTitle = title
        offsetSaveTimer.restart()
        updateIndex()
        showToast(tr("Geser waktu lagu ini: %1 ms", songOffset))
    }

    Timer {
        id: offsetSaveTimer
        interval: 1200
        onTriggered: root.saveSongOffset()
    }

    // tulis tag [offset:] ke file .lrc lagu (kalau filenya ada)
    function saveSongOffset() {
        if (offsetTitle === "") return
        var n = songOffset
        var cmd = dirSnippet() + fileSnippet(lrcFileName(offsetArtist, offsetTitle))
            + '[ -f "$d"/"$f" ] || exit 0; t="$(mktemp)" || exit 1; '
            + '{ ' + (n !== 0 ? 'printf "[offset:%s]\\n" ' + shq((n > 0 ? "+" : "") + n) + '; ' : '')
            + 'grep -v -i "^[[:space:]]*\\[offset:" "$d"/"$f" || true; } > "$t" '
            + '&& chmod 644 "$t" && mv "$t" "$d"/"$f"'
        runShell(cmd, function (out, code) {
            if (code === 0) console.log("SenandungPlasma: offset lagu disimpan: " + n + " ms")
        })
    }

    function currentSong() {
        return { artist: artist, title: title, length: Math.round(lengthMs / 1000) }
    }

    function openPanel(tab) {
        panelSong = currentSong()
        searchArtist = artist
        searchTitle = title
        searchResults = []
        searchStatus = ""
        panelTab = tab
        panelOpen = true
        if (tab === 0 && (artist !== "" || title !== "")) runSearch()
    }

    function closePanel() {
        panelOpen = false
    }

    function enc(x) { return encodeURIComponent(x) }

    function cleanTitle(t) {
        return String(t)
            .replace(/[\(\[][^\)\]]*(feat|ft\.|remaster|live|version|official|lyrics?|video)[^\)\]]*[\)\]]/ig, "")
            .replace(/\s+-\s+(remaster(ed)?|live|single version|radio edit).*$/i, "")
            .replace(/\s+/g, " ").trim()
    }

    // beberapa variasi query digabung; satu query gagal tidak membatalkan yang lain
    function searchLrclib(artistName, trackName, cb) {
        var base = "https://lrclib.net/api/search?"
        var tries = []
        if (artistName !== "" && trackName !== "") {
            tries.push("artist_name=" + enc(artistName) + "&track_name=" + enc(trackName))
            tries.push("q=" + enc(artistName + " " + trackName))
            var ct = cleanTitle(trackName)
            if (ct !== "" && ct !== trackName) tries.push("q=" + enc(artistName + " " + ct))
        } else {
            tries.push("q=" + enc(artistName !== "" ? artistName : trackName))
        }
        var out = []
        var seen = {}
        var failed = false
        var i = 0
        function next() {
            if (i >= tries.length || out.length >= 5) {
                cb(out.slice(0, 40), failed && out.length === 0)
                return
            }
            fetchJson(base + tries[i++], function (arr) {
                if (arr === null) failed = true
                else for (var k = 0; k < arr.length; k++) {
                    if (arr[k].syncedLyrics && !seen[arr[k].id]) {
                        seen[arr[k].id] = true
                        out.push(arr[k])
                    }
                }
                next()
            })
        }
        next()
    }

    function runSearch() {
        var a = searchArtist.trim()
        var t = searchTitle.trim()
        if (a === "" && t === "") {
            searchStatus = tr("Isi artis dan/atau judul, lalu tekan Cari.")
            return
        }
        searchStatus = tr("Mencari…")
        searchResults = []
        var len = panelSong.length
        searchLrclib(a, t, function (res, failed) {
            if (len > 0)
                res.sort(function (x, y) {
                    return Math.abs((x.duration || 0) - len) - Math.abs((y.duration || 0) - len)
                })
            searchResults = res
            searchStatus = res.length > 0
                ? tr("%1 lirik tersinkron ditemukan. Klik dua kali untuk memakai.", res.length)
                : (failed ? tr("Pencarian gagal (cek koneksi internet).") : tr("Tidak ada lirik tersinkron ditemukan."))
        })
    }

    function resultLabel(it) {
        var d = Math.round(it.duration || 0)
        var diff = (panelSong.length > 0 && d > 0)
            ? "  (" + tr("selisih %1 dtk", Math.abs(d - panelSong.length)) + ")" : ""
        return (it.artistName || "?") + " - " + (it.trackName || "?") + "  ·  " + (it.albumName || "-")
            + "  ·  " + Math.floor(d / 60) + ":" + pad2(d % 60) + diff
    }

    // simpan teks LRC sebagai file lirik lagu (menimpa yang lama), lalu muat ulang
    function applyLrc(raw, song) {
        if (!song || song.title === "") {
            showToast(tr("Tidak ada lagu aktif"))
            return false
        }
        raw = String(raw).replace(/\r\n?/g, "\n").replace(/^\uFEFF/, "")
        if (parseLrc(raw).length === 0) {
            showToast(tr("Bukan lirik .lrc bertanda waktu ([mm:ss.xx])"))
            return false
        }
        var name = lrcFileName(song.artist, song.title)
        var key = song.artist + "|" + song.title
        var cmd = dirSnippet() + fileSnippet(name)
            + 'mkdir -p "$d" && printf %s ' + b64enc(raw.replace(/\n+$/, "") + "\n")
            + ' | base64 -d > "$d"/"$f" && rm -f "$d"/"${f%.lrc}.romaji.lrc"'
        runShell(cmd, function (out, code) {
            if (code !== 0) {
                showToast(tr("Gagal menyimpan lirik"))
                return
            }
            delete cache[key]
            if (key === trackKey) trackKey = ""        // paksa muat ulang dari file lokal
            showToast(tr("Lirik disimpan: %1", name))
        })
        closePanel()
        return true
    }

    // path teks, file:// URL, atau ~/...
    function loadLrcFile(src) {
        var p = String(src).trim()
        if (p.indexOf("file://") === 0) p = decodeURIComponent(p.substring(7))
        if (p === "") return
        var song = (panelOpen && panelSong.title !== "") ? panelSong : currentSong()
        var cmd = 'p="$(printf %s ' + b64enc(p) + ' | base64 -d)"; '
            + 'case "$p" in "~"*) p="$HOME${p#"~"}";; esac; base64 -w0 -- "$p" 2>/dev/null'
        runShell(cmd, function (out, code) {
            var txt = b64dec(out)
            if (code !== 0 || txt.trim() === "") {
                showToast(tr("Gagal membaca file"))
                return
            }
            applyLrc(txt, song)
        })
    }

    // dialog pilih file (bila modul QtQuick.Dialogs tak ada, pakai kolom path)
    function browseFile() {
        try {
            var dlg = Qt.createQmlObject('import QtQuick.Dialogs\nFileDialog { '
                + 'nameFilters: ["Lirik (*.lrc *.txt)", "Semua file (*)"] }', root, "fileDlg")
            dlg.accepted.connect(function () { root.loadLrcFile(dlg.selectedFile.toString()); dlg.destroy() })
            dlg.rejected.connect(function () { dlg.destroy() })
            dlg.open()
        } catch (e) {
            showToast(tr("Dialog file tidak tersedia, ketik path-nya."))
        }
    }

    fullRepresentation: Item {
        // Ukuran HANYA ditentukan oleh pengguna (resize widget), bukan oleh isi lirik.
        Layout.preferredWidth: 420
        Layout.preferredHeight: 240
        Layout.minimumWidth: 120
        Layout.minimumHeight: 60

        ListView {
            id: view
            anchors.fill: parent
            clip: true
            interactive: false
            visible: root.lyrics.length > 0
            model: root.lyrics
            spacing: 8
            currentIndex: Math.max(0, root.currentIndex)

            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (height - (currentItem ? currentItem.height : 0)) / 2
            preferredHighlightEnd: (height + (currentItem ? currentItem.height : 0)) / 2
            highlightMoveDuration: 180
            highlightMoveVelocity: -1

            delegate: Column {
                id: lineItem
                readonly property int dist: Math.abs(index - root.currentIndex)
                readonly property bool active: index === root.currentIndex
                readonly property string roman: modelData.roman || ""
                readonly property string orig: modelData.text !== "" ? modelData.text : "♪"
                readonly property bool both: roman !== "" && root.cfg.romanMode === 1
                width: ListView.view.width
                spacing: 2
                opacity: root.currentIndex < 0 ? 0.35 : (active ? 1.0 : Math.max(0.12, 0.55 - dist * 0.15))
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    visible: lineItem.roman === "" || lineItem.both
                    width: parent.width
                    text: lineItem.orig
                    wrapMode: Text.WordWrap
                    horizontalAlignment: root.alignments[root.cfg.alignment] || Text.AlignHCenter
                    font.family: root.cfg.fontFamily !== "" ? root.cfg.fontFamily : Qt.application.font.family
                    font.pointSize: root.cfg.fontSize
                    font.bold: lineItem.active
                    color: lineItem.active ? root.cfg.highlightColor : root.cfg.textColor
                    style: root.cfg.outline ? Text.Outline : Text.Normal
                    styleColor: "#aa000000"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    visible: lineItem.roman !== ""
                    width: parent.width
                    text: lineItem.roman
                    wrapMode: Text.WordWrap
                    horizontalAlignment: root.alignments[root.cfg.alignment] || Text.AlignHCenter
                    font.family: root.cfg.fontFamily !== "" ? root.cfg.fontFamily : Qt.application.font.family
                    font.pointSize: lineItem.both ? Math.max(6, root.cfg.fontSize * 0.8) : root.cfg.fontSize
                    font.bold: lineItem.active
                    color: lineItem.active ? root.cfg.highlightColor : root.cfg.textColor
                    style: root.cfg.outline ? Text.Outline : Text.Normal
                    styleColor: "#aa000000"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        // Kalibrasi cepat per lagu: putar roda mouse di atas widget.
        // Gulir ke atas = lirik tampil lebih awal (+100 ms), ke bawah = lebih lambat (-100 ms).
        // Tersimpan sebagai tag [offset:] di file .lrc lagu itu (pengaturan global tidak berubah).
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: !root.panelOpen
            onWheel: (wheel) => {
                root.nudgeOffset(wheel.angleDelta.y > 0 ? 100 : -100)
                wheel.accepted = true
            }
        }

        // Seret file .lrc/.txt ke widget untuk memakainya
        DropArea {
            anchors.fill: parent
            onDropped: (drop) => {
                if (drop.hasUrls && drop.urls.length > 0)
                    root.loadLrcFile(String(drop.urls[0]))
            }
        }

        // Tombol cari muncul saat kursor di atas widget
        HoverHandler { id: hover }
        QQC2.ToolButton {
            anchors.top: parent.top
            anchors.right: parent.right
            icon.name: "edit-find"
            opacity: hover.hovered && !root.panelOpen ? 0.9 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            QQC2.ToolTip.text: tr("Cari / ganti lirik")
            QQC2.ToolTip.visible: hovered
            onClicked: root.openPanel(0)
        }

        Text {
            id: toast
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.toastText
            opacity: root.toastOn ? 1 : 0
            color: "white"
            font.pointSize: 11
            style: Text.Outline
            styleColor: "#cc000000"
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // ---- panel cari / tempel / file ----
        Rectangle {
            id: panel
            anchors.fill: parent
            visible: root.panelOpen
            z: 10
            radius: 8
            color: "#f01b1d23"
            border.color: "#44ffffff"

            MouseArea {                      // cegah klik/gulir tembus ke lirik
                anchors.fill: parent
                onWheel: (wheel) => { wheel.accepted = true }
            }

            Connections {
                target: root
                function onPanelTabChanged() { tabs.currentIndex = root.panelTab }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    QQC2.TabBar {
                        id: tabs
                        Layout.fillWidth: true
                        onCurrentIndexChanged: root.panelTab = currentIndex
                        QQC2.TabButton { text: tr("Cari") }
                        QQC2.TabButton { text: tr("Tempel") }
                        QQC2.TabButton { text: tr("File") }
                    }
                    QQC2.ToolButton {
                        icon.name: "window-close"
                        onClicked: root.closePanel()
                    }
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    opacity: 0.75
                    color: "white"
                    text: root.panelSong.title !== ""
                        ? root.panelSong.artist + " - " + root.panelSong.title
                        : tr("Tidak ada lagu aktif")
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.panelTab

                    // 0: cari online
                    ColumnLayout {
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            QQC2.TextField {
                                Layout.fillWidth: true
                                placeholderText: tr("Artis")
                                text: root.searchArtist
                                onTextEdited: root.searchArtist = text
                                onAccepted: root.runSearch()
                            }
                            QQC2.TextField {
                                Layout.fillWidth: true
                                placeholderText: tr("Judul")
                                text: root.searchTitle
                                onTextEdited: root.searchTitle = text
                                onAccepted: root.runSearch()
                            }
                            QQC2.Button {
                                text: tr("Cari")
                                onClicked: root.runSearch()
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: "white"
                            opacity: 0.75
                            text: root.searchStatus
                        }
                        ListView {
                            id: resList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: root.searchResults
                            onCountChanged: currentIndex = count > 0 ? 0 : -1
                            delegate: QQC2.ItemDelegate {
                                width: ListView.view.width
                                text: root.resultLabel(modelData)
                                highlighted: ListView.isCurrentItem
                                onClicked: resList.currentIndex = index
                                onDoubleClicked: root.applyLrc(modelData.syncedLyrics, root.panelSong)
                            }
                            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
                        }
                        QQC2.Button {
                            Layout.alignment: Qt.AlignRight
                            text: tr("Pakai lirik terpilih")
                            enabled: resList.currentIndex >= 0 && root.searchResults.length > 0
                            onClicked: root.applyLrc(root.searchResults[resList.currentIndex].syncedLyrics, root.panelSong)
                        }
                    }

                    // 1: tempel teks LRC
                    ColumnLayout {
                        spacing: 4
                        QQC2.ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            QQC2.TextArea {
                                id: pasteArea
                                placeholderText: "[00:12.34] ..."
                                wrapMode: TextEdit.NoWrap
                                selectByMouse: true
                            }
                        }
                        QQC2.Button {
                            Layout.alignment: Qt.AlignRight
                            text: tr("Pakai lirik ini")
                            onClicked: root.applyLrc(pasteArea.text, root.panelSong)
                        }
                    }

                    // 2: buka file
                    ColumnLayout {
                        spacing: 6
                        QQC2.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: "white"
                            text: tr("Pilih file .lrc / .txt, atau seret filenya ke widget.")
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            QQC2.TextField {
                                id: pathField
                                Layout.fillWidth: true
                                placeholderText: "~/Music/lagu.lrc"
                                onAccepted: root.loadLrcFile(text)
                            }
                            QQC2.Button {
                                text: tr("Telusuri…")
                                onClicked: root.browseFile()
                            }
                            QQC2.Button {
                                text: tr("Pakai")
                                onClicked: root.loadLrcFile(pathField.text)
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
