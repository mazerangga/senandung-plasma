![Senandung Plasma](assets/icons/png/senandung-128.png)

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
- Bahasa antarmuka: Bahasa Indonesia (bawaan) atau English, bisa diganti di Pengaturan
- Font, ukuran, warna, perataan, dan garis tepi teks bisa diatur
- Tidak menampilkan apa pun bila lirik tidak ada

## Kebutuhan

| Apa | Fungsi | Dibutuhkan untuk |
|-----|--------|------------------|
| KDE Plasma 6 (sudah termasuk `kpackagetool6`) | menjalankan widget | semuanya |
| [`playerctl`](https://github.com/altdesktop/playerctl) | membaca lagu dan posisi dari pemutar (MPRIS) | semuanya |
| `git` | meng-clone repositori | instal dari sumber |
| `zip` dan `python3` | `build.sh` membuat `.plasmoid` | membangun `.plasmoid` sendiri |
| Python 3 | menjalankan pembantu romanisasi (modulnya sudah dibundel di `.plasmoid` rilis) | opsional |

Pasang paket sistem sesuai distro Anda:

```bash
# Arch / Manjaro / EndeavourOS
sudo pacman -S playerctl git zip python

# Debian / Ubuntu / KDE neon
sudo apt install playerctl git zip python3

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

### Cara 1: dari rilis (disarankan, tidak perlu pasang apa-apa lagi)

Unduh `senandung-plasma_<versi>.plasmoid` dari halaman [Releases](../../releases). File ini sudah berisi modul romanisasi, jadi tidak perlu `pip` atau virtual environment. Lalu:

```bash
kpackagetool6 -t Plasma/Applet -i senandung-plasma_1.0.plasmoid
```

### Cara 2: clone lalu instal dari sumber

```bash
git clone https://github.com/mazerangga/senandung-plasma.git
cd senandung-plasma
./install.sh        # mengunduh modul romanisasi, lalu memasang (atau memperbarui) widget
```

`install.sh` butuh `python3` dengan `pip` dan internet sekali saja. Kalau tidak butuh romanisasi, pakai `kpackagetool6 -t Plasma/Applet -i .`.

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

## Romanisasi

File `.plasmoid` rilis dan `./install.sh` sudah menyertakan modulnya (`pykakasi`, `pypinyin`, `korean-romanizer`, `unidecode`) di `contents/code/vendor`, jadi tidak perlu memasang apa pun lagi. Cukup aktifkan **Romanisasi** di pengaturan widget.

Kalau memasang dari clone dengan `kpackagetool6 -i .` biasa, jalankan `./vendor.sh` sekali dulu (atau pakai `./install.sh`).

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

Bahasa (Indonesia / English), font, ukuran, warna, perataan, garis tepi, geser waktu, folder lirik, romanisasi, daftar pemutar yang dibaca (pisahkan koma, nama dari `playerctl -l`; kosong berarti semua pemutar), dan blacklist (bawaannya browser, supaya video YouTube tidak dikira lagu; nama yang diketik di daftar pemutar selalu didahulukan dari blacklist).

## Pemecahan masalah

- **Widget tidak ada di daftar setelah instal:** muat ulang Plasma (perintah di atas), lalu cari lagi.
- **Masih versi lama:** lihat baris log `SenandungPlasma v<versi> dimulai`. Kalau masih lama, Plasma belum dimuat ulang.
- **Tidak ada tampilan apa pun:** itu normal kalau lirik tidak ada. Cek `playerctl -l` (apakah pemutar Anda muncul?) dan kolom **Pemutar** serta **Blacklist** di Pengaturan. Bawaannya kolom Pemutar kosong (semua pemutar) dan browser diabaikan lewat blacklist. Kalau ingin lirik untuk pemutar di browser, ketik namanya di **Pemutar**.
- **Lirik terlalu cepat atau lambat:** putar roda mouse di atas widget untuk lagu ini, atau atur geser waktu global di Pengaturan.
- **Versi lirik salah:** klik kanan, **Cari lirik online…**, pilih yang durasinya paling dekat dengan lagu Anda.
- **Romanisasi tidak jalan:** cek `python3` ada dan folder `contents/code/vendor` ikut terpasang (jalankan `./vendor.sh`, lalu `./install.sh`).

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
2. Dorong tag yang sama. GitHub Actions menjalankan `vendor.sh` (mengunduh modul romanisasi sesuai versi di `requirements-vendor.txt`), membangun `.plasmoid` dengan `build.sh`, lalu melampirkannya ke rilis:

```bash
git tag v1.0 && git push origin v1.0
```

Workflow gagal kalau tag tidak sama dengan versi di `metadata.json`, atau kalau ada modul romanisasi yang tidak ikut terbungkus. Untuk memperbarui modul bawaan, ubah versinya di `requirements-vendor.txt`. Push ke `main` dan pull request juga membangun paketnya, sebagai artifact yang bisa diunduh di tab Actions.

## Struktur

```
senandung-plasma/
├── metadata.json              # nama, id, versi widget
├── contents/
│   ├── ui/main.qml            # widget: tampilan, sinkronisasi, cari/terapkan LRC
│   ├── ui/configGeneral.qml   # halaman pengaturan
│   ├── config/{config.qml,main.xml}
│   └── code/
│       ├── romanize.py        # pembantu romanisasi (opsional)
│       ├── strings.js         # terjemahan antarmuka (sumber Indonesia, English)
│       └── vendor/            # modul bawaan (dibuat vendor.sh, tidak masuk git)
├── assets/icons/             # ikon (source/ + ukuran png/), sama dengan Senandung
├── build.sh                   # membuat dist/*.plasmoid (menjalankan vendor.sh bila perlu)
├── vendor.sh                  # mengunduh modul di requirements-vendor.txt
├── install.sh                 # vendor + pasang/perbarui dari sumber
├── requirements-vendor.txt    # versi modul bawaan yang dikunci
└── .github/workflows/release.yml
```

## Kredit

Lirik berasal dari [LRCLIB](https://lrclib.net). Lirik adalah milik pemegang hak ciptanya; widget ini hanya menampilkannya untuk penggunaan pribadi dan tidak menyertakan lirik. Dikembangkan dengan bantuan asisten AI ([Claude](https://www.anthropic.com/claude) dari Anthropic). Lisensi: [GPL-3.0-or-later](LICENSE).

`.plasmoid` rilis membundel modul Python berikut (lisensi masing-masing ada di `contents/code/vendor/*.dist-info`): [pykakasi](https://github.com/miurahr/pykakasi) (GPL-3.0), [pypinyin](https://github.com/mozillazg/python-pinyin) (MIT), [korean-romanizer](https://github.com/osori/korean-romanizer) (MIT), [Unidecode](https://github.com/avian2/unidecode) (GPL-2.0-or-later), beserta dependensi kecilnya jaconv, Deprecated, dan wrapt.
