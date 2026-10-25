// SPDX-FileCopyrightText: 2026 mazerangga
// SPDX-License-Identifier: GPL-3.0-or-later
// Terjemahan antarmuka. Teks sumber = bahasa Indonesia (bawaan); "en" = English.
.pragma library

var en = {
    "Jenis font:": "Font:",
    "Kosongkan untuk memakai font sistem": "Leave empty to use the system font",
    "Ukuran font (pt):": "Font size (pt):",
    "Warna teks:": "Text color:",
    "Warna baris aktif:": "Active line color:",
    "Perataan:": "Alignment:",
    "Kiri": "Left",
    "Tengah": "Center",
    "Kanan": "Right",
    "Garis tepi teks:": "Text outline:",
    "Aktifkan (agar terbaca di wallpaper terang)": "Enable (keeps text readable on bright wallpapers)",
    "Geser waktu (ms):": "Time offset (ms):",
    "File .lrc lokal:": "Local .lrc files:",
    "Simpan lirik dari LRCLIB sebagai file .lrc": "Save lyrics from LRCLIB as .lrc files",
    "Folder lirik:": "Lyrics folder:",
    "Romanisasi:": "Romanization:",
    "Ubah lirik Jepang/Mandarin/Korea dll ke huruf Latin": "Convert Japanese/Chinese/Korean etc. lyrics to Latin letters",
    "Tampilan romanisasi:": "Romanization display:",
    "Hanya romaji": "Romanization only",
    "Asli + romaji (dua baris)": "Original + romanization (two lines)",
    "Pemutar:": "Players:",
    "Pisahkan dengan koma. Yang sedang Playing diutamakan, lalu urutan daftar. Kosongkan untuk semua pemutar (kecuali blacklist di bawah). Cek nama dengan: playerctl -l": "Comma separated. The one that is Playing comes first, then list order. Leave empty for all players (except the blacklist below). Check names with: playerctl -l",
    "Blacklist:": "Blacklist:",
    "Pemutar yang diabaikan saat kolom Pemutar kosong, supaya video di browser tidak dikira lagu. Kolom Pemutar yang diisi selalu didahulukan dari blacklist.": "Players ignored when the Players field is empty, so browser videos are not mistaken for songs. Names typed in Players always win over the blacklist.",
    "Menunggu pemutar…": "Waiting for a player…",
    "Cari lirik online…": "Search lyrics online…",
    "Tempel teks lirik (.lrc)…": "Paste lyrics text (.lrc)…",
    "Buka file lirik (.lrc)…": "Open lyrics file (.lrc)…",
    "Lirik tersinkron tidak ditemukan": "Synced lyrics not found",
    "Mencari lirik…": "Searching for lyrics…",
    "Geser waktu lagu ini: %1 ms": "Offset for this song: %1 ms",
    "Isi artis dan/atau judul, lalu tekan Cari.": "Enter artist and/or title, then press Search.",
    "Mencari…": "Searching…",
    "%1 lirik tersinkron ditemukan. Klik dua kali untuk memakai.": "%1 synced lyrics found. Double-click to use one.",
    "Pencarian gagal (cek koneksi internet).": "Search failed (check your internet connection).",
    "Tidak ada lirik tersinkron ditemukan.": "No synced lyrics found.",
    "selisih %1 dtk": "%1 s difference",
    "Tidak ada lagu aktif": "No active song",
    "Bukan lirik .lrc bertanda waktu ([mm:ss.xx])": "Not a timestamped .lrc lyric ([mm:ss.xx])",
    "Gagal menyimpan lirik": "Failed to save lyrics",
    "Lirik disimpan: %1": "Lyrics saved: %1",
    "Gagal membaca file": "Failed to read file",
    "Dialog file tidak tersedia, ketik path-nya.": "File dialog unavailable, type the path instead.",
    "Cari / ganti lirik": "Search / change lyrics",
    "Cari": "Search",
    "Tempel": "Paste",
    "File": "File",
    "Artis": "Artist",
    "Judul": "Title",
    "Pakai lirik terpilih": "Use selected lyrics",
    "Pakai lirik ini": "Use these lyrics",
    "Pilih file .lrc / .txt, atau seret filenya ke widget.": "Choose an .lrc / .txt file, or drag it onto the widget.",
    "Telusuri…": "Browse…",
    "Pakai": "Use"
}

function tr(lang, text, args) {
    var s = (lang === "en" && en[text] !== undefined) ? en[text] : text
    if (args)
        for (var i = 0; i < args.length; i++)
            s = s.split("%" + (i + 1)).join(String(args[i]))
    return s
}
