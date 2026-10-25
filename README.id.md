# Senandung Plasma

**Widget lirik tersinkron (LRC) untuk KDE Plasma 6.** Mendeteksi lagu yang sedang diputar, mengunduh lirik bertanda waktu dari [LRCLIB](https://lrclib.net), lalu menampilkannya di desktop dengan latar transparan. Baris yang sedang dinyanyikan disorot sesuai musik.

[English](README.md)

Proyek saudara dari [Senandung](https://github.com/mazerangga/senandung-lirik) (overlay mandiri untuk Linux dan Windows). Keduanya membaca file LRC dengan cara yang sama, jadi lirik dan offsetnya cocok.

## Fitur

- Bekerja dengan pemutar apa pun yang mendukung MPRIS lewat `playerctl` (Spotify, VLC, Elisa, Amarok, Strawberry, dan lainnya)
- Lirik otomatis dari LRCLIB, disimpan sebagai `.lrc` sehingga putar berikutnya bisa offline
- **Cari lirik online**, **tempel teks LRC**, atau **buka file `.lrc`** (menu klik kanan, atau tombol cari saat kursor di atas widget); file juga bisa diseret ke widget
- Geser waktu per lagu: putar roda mouse di atas widget, tersimpan sebagai tag `[offset:]` di file `.lrc`
- Geser waktu global di Pengaturan
- Romanisasi lirik Jepang, Mandarin, Korea, dan aksara lain (opsional)
- Font, ukuran, warna, perataan, dan garis tepi teks bisa diatur
- Tidak menampilkan apa pun bila lirik tidak ada

## Kebutuhan

| Apa | Fungsi | Dibutuhkan untuk |
|-----|--------|------------------|
| KDE Plasma 6 (sudah termasuk `kpackagetool6`) | menjalankan widget | semuanya |
| [`playerctl`](https://github.com/altdesktop/playerctl) | membaca lagu dan posisi dari pemutar (MPRIS) | semuanya |
| `git` | meng-clone repositori | instal dari sumber |
| `zip` dan `python3` | `build.sh` membuat `.plasmoid` | membangun `.plasmoid` sendiri |
| Python 3 + `pykakasi`, `pypinyin`, `korean-romanizer`, `unidecode` | romanisasi Jepang, Mandarin, Korea... | opsional |

Pasang paket sistem sesuai distro Anda:

```bash
# Arch / Manjaro / EndeavourOS
sudo pacman -S playerctl git zip python

# Debian / Ubuntu / KDE neon
sudo apt install playerctl git zip python3 python3-venv

# Fedora
sudo dnf install playerctl git zip python3

# openSUSE
sudo zypper install playerctl git zip python3
```

Cek bahwa semuanya ada:

```bash
command -v kpackagetool6 playerctl git zip
playerctl -l        # saat lagu diputar: pemutar Anda harus muncul
```

## Instalasi

### Cara 1: dari rilis (tanpa build)

Unduh `senandung-plasma_<versi>.plasmoid` dari halaman [Releases](../../releases), lalu:

```bash
kpackagetool6 -t Plasma/Applet -i senandung-plasma_1.0.plasmoid
```

### Cara 2: clone lalu instal dari sumber

```bash
git clone https://github.com/mazerangga/senandung-plasma.git
cd senandung-plasma
kpackagetool6 -t Plasma/Applet -i .
```

### Cara 3: clone, bangun `.plasmoid` sendiri, lalu instal

```bash
git clone https://github.com/mazerangga/senandung-plasma.git
cd senandung-plasma
./build.sh                                   # menghasilkan dist/senandung-plasma_<versi>.plasmoid
kpackagetool6 -t Plasma/Applet -i dist/senandung-plasma_*.plasmoid
```

`build.sh` hanya mem-zip `metadata.json` dan `contents/` (file `.plasmoid` memang file zip). Kalau mau manual, setaranya:

```bash
zip -r senandung-plasma.plasmoid metadata.json contents
```

### Cara 4: salin manual (kalau `kpackagetool6` bermasalah)

Nama folder harus persis sama dengan ID widget:

```bash
dest="$HOME/.local/share/plasma/plasmoids/io.github.mazerangga.senandungplasma"
mkdir -p "$dest"
cp -r metadata.json contents "$dest"
```

### Setelah instal

Muat ulang Plasma agar widget terbaca, lalu tambahkan: klik kanan desktop, **Tambah Widget**, cari **Senandung Plasma**, seret ke desktop.

```bash
kquitapp6 plasmashell && kstart plasmashell      # atau: plasmashell --replace &
```

`kpackagetool6` kadang mencetak baris seperti `KPackageStructure ... does not match requested format "Plasma/Applet"`. Itu berasal dari widget lain di folder plasmoids Anda yang tidak punya tipe paket, dan tidak berbahaya. Yang dicari adalah `Successfully installed` atau `Successfully upgraded` di akhir.

## Pembaruan

Dari hasil clone:

```bash
cd senandung-plasma
git pull
kpackagetool6 -t Plasma/Applet -u .          # pakai -i kalau belum pernah dipasang
kquitapp6 plasmashell && kstart plasmashell
```

Dari file rilis baru: `kpackagetool6 -t Plasma/Applet -u senandung-plasma_<versi>.plasmoid`

## Mencopot

```bash
kpackagetool6 -t Plasma/Applet -r io.github.mazerangga.senandungplasma
```

Lirik yang sudah diunduh di `~/lyrics` tidak ikut terhapus.

## Opsional: romanisasi

Untuk menampilkan lirik Jepang, Mandarin, atau Korea dalam huruf Latin, buat lingkungan Python berisi modulnya. Path ini adalah bawaan di Pengaturan:

```bash
python3 -m venv ~/.local/share/lyrics-venv
~/.local/share/lyrics-venv/bin/pip install pykakasi pypinyin korean-romanizer unidecode
```

Lalu aktifkan **Romanisasi** di pengaturan widget. Kalau path Python di Pengaturan tidak ada, widget memakai `python3` sistem.

## Penggunaan

| Aksi | Fungsi |
|------|--------|
| Roda mouse di atas widget | Geser waktu lirik lagu ini (tersimpan di `.lrc`) |
| Klik kanan, "Cari lirik online…" | Pilih versi lirik lain |
| Klik kanan, "Tempel teks lirik (.lrc)…" | Tempel teks LRC |
| Klik kanan, "Buka file lirik (.lrc)…" | Pilih file |
| Seret file `.lrc` ke widget | Pakai file itu untuk lagu saat ini |

Folder lirik bawaan `~/lyrics`, file bernama `Artis - Judul.lrc`. File lokal selalu dipakai sebelum mencari online.

## Pengaturan

Font, ukuran, warna, perataan, garis tepi, geser waktu, folder lirik, romanisasi, path Python, daftar pemutar yang dibaca (pisahkan koma, nama dari `playerctl -l`; kosong berarti semua pemutar), dan blacklist (bawaannya browser, supaya video YouTube tidak dikira lagu; nama yang diketik di daftar pemutar selalu didahulukan dari blacklist).

## Pemecahan masalah

- **Widget tidak ada di daftar setelah instal:** muat ulang Plasma (perintah di atas), lalu cari lagi.
- **Masih versi lama:** lihat baris log `SenandungPlasma v<versi> dimulai`. Kalau masih lama, Plasma belum dimuat ulang.
- **Tidak ada tampilan apa pun:** itu normal kalau lirik tidak ada. Cek `playerctl -l` (apakah pemutar Anda muncul?) dan kolom **Pemutar** serta **Blacklist** di Pengaturan. Bawaannya kolom Pemutar kosong (semua pemutar) dan browser diabaikan lewat blacklist. Kalau ingin lirik untuk pemutar di browser, ketik namanya di **Pemutar**.
- **Lirik terlalu cepat atau lambat:** putar roda mouse di atas widget untuk lagu ini, atau atur geser waktu global di Pengaturan.
- **Versi lirik salah:** klik kanan, **Cari lirik online…**, pilih yang durasinya paling dekat dengan lagu Anda.
- **Romanisasi tidak jalan:** cek path Python di Pengaturan dan pastikan modulnya terpasang di lingkungan itu.

## Pengembangan

Ubah file langsung, lalu perbarui dan muat ulang:

```bash
kpackagetool6 -t Plasma/Applet -u . && kquitapp6 plasmashell && kstart plasmashell
```

Untuk pratinjau tanpa mengganggu desktop, pakai `plasmoidviewer` (paket `plasma-sdk`):

```bash
plasmoidviewer -a .
```

Pantau log saat menguji:

```bash
journalctl --user -f | grep SenandungPlasma
```

Cek sintaks QML cepat (butuh `qmllint` dari Qt): `qmllint contents/ui/main.qml`

## Merilis (untuk maintainer)

1. Ubah `"Version"` di `metadata.json` lalu commit.
2. Dorong tag yang sama. GitHub Actions membangun `.plasmoid` dan melampirkannya ke rilis:

```bash
git tag v1.0 && git push origin v1.0
```

Workflow gagal kalau tag tidak sama dengan versi di `metadata.json`. Push ke `main` dan pull request juga membangun paketnya, sebagai artifact yang bisa diunduh di tab Actions.

## Struktur

```
senandung-plasma/
├── metadata.json              # nama, id, versi widget
├── contents/
│   ├── ui/main.qml            # widget: tampilan, sinkronisasi, cari/terapkan LRC
│   ├── ui/configGeneral.qml   # halaman pengaturan
│   ├── config/{config.qml,main.xml}
│   └── code/romanize.py       # pembantu romanisasi (opsional)
├── build.sh
└── .github/workflows/release.yml
```

## Kredit

Lirik berasal dari [LRCLIB](https://lrclib.net). Lirik adalah milik pemegang hak ciptanya; widget ini hanya menampilkannya untuk penggunaan pribadi dan tidak menyertakan lirik. Dikembangkan dengan bantuan asisten AI ([Claude](https://www.anthropic.com/claude) dari Anthropic). Lisensi: [GPL-3.0-or-later](LICENSE).
