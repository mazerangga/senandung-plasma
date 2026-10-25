# Senandung Plasma

**Synced lyrics (LRC) widget for KDE Plasma 6.** It detects the song playing in your media player, downloads time-synced lyrics from [LRCLIB](https://lrclib.net) and shows them on your desktop with a transparent background, highlighting the current line in time with the music.

[Bahasa Indonesia](README.id.md)

Sister project of [Senandung](https://github.com/mazerangga/senandung-lirik) (the standalone overlay for Linux and Windows). Both read LRC files the same way, so lyrics and offsets match.

## Features

- Works with any MPRIS player through `playerctl` (Spotify, VLC, Elisa, Amarok, Strawberry, ...)
- Automatic lyrics from LRCLIB, saved as `.lrc` so the next play works offline
- **Search lyrics online**, **paste LRC text** or **open an `.lrc` file** (right-click menu, or the search button on hover); you can also drag a file onto the widget
- Per-song time offset: scroll the mouse wheel over the widget; it is saved as an `[offset:]` tag in the `.lrc` file
- Global time offset in Settings
- Romanization for Japanese, Chinese, Korean and other scripts (optional)
- Custom font, size, colors, alignment and text outline
- Nothing is drawn when there are no lyrics

## Requirements

| What | Why | Needed for |
|------|-----|-----------|
| KDE Plasma 6 (includes `kpackagetool6`) | runs the widget | everything |
| [`playerctl`](https://github.com/altdesktop/playerctl) | reads the song and position from your player (MPRIS) | everything |
| `git` | clone the repository | install from source |
| `zip` and `python3` | `build.sh` makes the `.plasmoid` | building a `.plasmoid` yourself |
| Python 3 + `pykakasi`, `pypinyin`, `korean-romanizer`, `unidecode` | romanization of Japanese, Chinese, Korean... | optional |

Install the system packages for your distro:

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

Check that everything is there:

```bash
command -v kpackagetool6 playerctl git zip
playerctl -l        # while a song is playing: should list your player
```

## Install

### Option 1: from a release (no build needed)

Download `senandung-plasma_<version>.plasmoid` from the [Releases](../../releases) page, then:

```bash
kpackagetool6 -t Plasma/Applet -i senandung-plasma_1.0.plasmoid
```

### Option 2: clone and install from source

```bash
git clone https://github.com/mazerangga/senandung-plasma.git
cd senandung-plasma
kpackagetool6 -t Plasma/Applet -i .
```

### Option 3: clone, build the `.plasmoid` yourself, then install

```bash
git clone https://github.com/mazerangga/senandung-plasma.git
cd senandung-plasma
./build.sh                                   # creates dist/senandung-plasma_<version>.plasmoid
kpackagetool6 -t Plasma/Applet -i dist/senandung-plasma_*.plasmoid
```

`build.sh` only zips `metadata.json` and `contents/` (a `.plasmoid` is a zip file). If you prefer, the manual equivalent is:

```bash
zip -r senandung-plasma.plasmoid metadata.json contents
```

### Option 4: manual copy (if `kpackagetool6` gives trouble)

The folder name must be exactly the widget id:

```bash
dest="$HOME/.local/share/plasma/plasmoids/io.github.mazerangga.senandungplasma"
mkdir -p "$dest"
cp -r metadata.json contents "$dest"
```

### After installing

Reload Plasma so it sees the widget, then add it: right-click the desktop, **Add Widgets**, search **Senandung Plasma**, and drag it to the desktop.

```bash
kquitapp6 plasmashell && kstart plasmashell      # or: plasmashell --replace &
```

`kpackagetool6` may print lines like `KPackageStructure ... does not match requested format "Plasma/Applet"`. They come from other widgets in your plasmoids folder that lack a package type, and are harmless. Look for `Successfully installed` or `Successfully upgraded` at the end.

## Update

From a clone:

```bash
cd senandung-plasma
git pull
kpackagetool6 -t Plasma/Applet -u .          # use -i if it was never installed
kquitapp6 plasmashell && kstart plasmashell
```

From a new release file: `kpackagetool6 -t Plasma/Applet -u senandung-plasma_<version>.plasmoid`

## Uninstall

```bash
kpackagetool6 -t Plasma/Applet -r io.github.mazerangga.senandungplasma
```

Your downloaded lyrics in `~/lyrics` are not removed.

## Optional: romanization

To show Japanese, Chinese or Korean lyrics in Latin letters, create a Python environment with the modules. This path is the default in Settings:

```bash
python3 -m venv ~/.local/share/lyrics-venv
~/.local/share/lyrics-venv/bin/pip install pykakasi pypinyin korean-romanizer unidecode
```

Then enable **Romanization** in the widget settings. If the Python path in Settings does not exist, the widget falls back to the system `python3`.

## Usage

| Action | What it does |
|--------|--------------|
| Mouse wheel over the widget | Shift lyric timing for the current song (saved in the `.lrc`) |
| Right-click, "Search lyrics online…" | Pick another version of the lyrics |
| Right-click, "Paste lyrics text (.lrc)…" | Paste LRC text |
| Right-click, "Open lyrics file (.lrc)…" | Choose a file |
| Drag a `.lrc` file onto the widget | Use that file for the current song |

Lyrics folder defaults to `~/lyrics`; files are named `Artist - Title.lrc`. Local files are always used before searching online.

## Settings

Font, size, colors, alignment, outline, time offset, lyrics folder, romanization, Python path, the list of players to watch (comma separated, names from `playerctl -l`; empty means all players) and a blacklist (browsers by default, so a YouTube video is not mistaken for a song; a name typed in the players list always wins over the blacklist).

## Troubleshooting

- **Widget not in the list after install:** reload Plasma (command above), then search again.
- **Still shows the old version:** check the log line `SenandungPlasma v<version> dimulai`. If it is old, Plasma was not reloaded.
- **Nothing is shown:** that is normal when there are no lyrics. Check `playerctl -l` (is your player listed?) and the **Players** and **Blacklist** fields in Settings. By default the Players field is empty (all players) and browsers are ignored through the blacklist. If you want to show lyrics for a browser player, type its name in **Players**.
- **Lyrics too early or late:** scroll the mouse wheel over the widget for this song, or set the global offset in Settings.
- **Wrong version of the lyrics:** right-click, **Search lyrics online…**, and pick the one whose duration is closest to your song.
- **Romanization does nothing:** check the Python path in Settings and that the modules are installed in that environment.

## Developing

Edit the files in place, then update and reload:

```bash
kpackagetool6 -t Plasma/Applet -u . && kquitapp6 plasmashell && kstart plasmashell
```

To preview without touching your desktop, use `plasmoidviewer` (package `plasma-sdk`):

```bash
plasmoidviewer -a .
```

Watch the log while testing:

```bash
journalctl --user -f | grep SenandungPlasma
```

Quick syntax check of the QML (needs Qt's `qmllint`): `qmllint contents/ui/main.qml`

## Releasing (maintainers)

1. Change `"Version"` in `metadata.json` and commit.
2. Push a matching tag. GitHub Actions builds the `.plasmoid` and attaches it to a release:

```bash
git tag v1.0 && git push origin v1.0
```

The workflow fails if the tag does not match the version in `metadata.json`. Pushes to `main` and pull requests also build the package, as a downloadable artifact in the Actions tab.

## Structure

```
senandung-plasma/
├── metadata.json              # widget name, id, version
├── contents/
│   ├── ui/main.qml            # the widget: display, sync, search/apply LRC
│   ├── ui/configGeneral.qml   # settings page
│   ├── config/{config.qml,main.xml}
│   └── code/romanize.py       # optional romanization helper
├── build.sh
└── .github/workflows/release.yml
```

## Credits

Lyrics come from [LRCLIB](https://lrclib.net). Lyrics belong to their copyright holders; this widget only displays them for personal use and ships none. Developed with the help of an AI assistant ([Claude](https://www.anthropic.com/claude) by Anthropic). License: [GPL-3.0-or-later](LICENSE).
