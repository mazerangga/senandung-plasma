// SPDX-FileCopyrightText: 2026 mazerangga
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/strings.js" as Strings

KCM.SimpleKCM {
    property string cfg_language
    property string cfg_languageDefault
    property string cfg_fontFamily
    property string cfg_fontFamilyDefault
    property alias cfg_fontSize: sizeSpin.value
    property int cfg_fontSizeDefault
    property string cfg_textColor
    property string cfg_textColorDefault
    property string cfg_highlightColor
    property string cfg_highlightColorDefault
    property alias cfg_alignment: alignBox.currentIndex
    property int cfg_alignmentDefault
    property alias cfg_outline: outlineCheck.checked
    property bool cfg_outlineDefault
    property alias cfg_offsetMs: offsetSpin.value
    property int cfg_offsetMsDefault
    property alias cfg_saveLocal: saveCheck.checked
    property bool cfg_saveLocalDefault
    property alias cfg_lyricsDir: dirField.text
    property string cfg_lyricsDirDefault
    property alias cfg_romanize: romanCheck.checked
    property bool cfg_romanizeDefault
    property alias cfg_romanMode: romanModeBox.currentIndex
    property int cfg_romanModeDefault
    property alias cfg_playerName: playerField.text
    property string cfg_playerNameDefault
    property alias cfg_blacklist: blacklistField.text
    property string cfg_blacklistDefault

    function tr(text) {
        return Strings.tr(cfg_language, text, Array.prototype.slice.call(arguments, 1))
    }

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: languageBox
            Kirigami.FormData.label: "Bahasa / Language:"
            model: ["Bahasa Indonesia", "English"]
            currentIndex: cfg_language === "en" ? 1 : 0
            onActivated: cfg_language = (currentIndex === 1 ? "en" : "id")
        }
        QQC2.ComboBox {
            id: fontBox
            Kirigami.FormData.label: tr("Jenis font:")
            editable: true
            model: Qt.fontFamilies()
            Component.onCompleted: editText = cfg_fontFamily
            onActivated: cfg_fontFamily = currentText
            onEditTextChanged: cfg_fontFamily = editText
        }
        QQC2.Label {
            text: tr("Kosongkan untuk memakai font sistem")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
        QQC2.SpinBox {
            id: sizeSpin
            Kirigami.FormData.label: tr("Ukuran font (pt):")
            from: 6
            to: 120
        }
        QQC2.TextField {
            id: textColorField
            Kirigami.FormData.label: tr("Warna teks:")
            text: cfg_textColor
            validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$/ }
            onTextChanged: if (acceptableInput) cfg_textColor = text
        }
        QQC2.TextField {
            id: hlColorField
            Kirigami.FormData.label: tr("Warna baris aktif:")
            text: cfg_highlightColor
            validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$/ }
            onTextChanged: if (acceptableInput) cfg_highlightColor = text
        }
        QQC2.ComboBox {
            id: alignBox
            Kirigami.FormData.label: tr("Perataan:")
            model: [tr("Kiri"), tr("Tengah"), tr("Kanan")]
        }
        QQC2.CheckBox {
            id: outlineCheck
            Kirigami.FormData.label: tr("Garis tepi teks:")
            text: tr("Aktifkan (agar terbaca di wallpaper terang)")
        }
        QQC2.SpinBox {
            id: offsetSpin
            Kirigami.FormData.label: tr("Geser waktu (ms):")
            from: -10000
            to: 10000
            stepSize: 100
            editable: true
        }
        QQC2.CheckBox {
            id: saveCheck
            Kirigami.FormData.label: tr("File .lrc lokal:")
            text: tr("Simpan lirik dari LRCLIB sebagai file .lrc")
        }
        QQC2.TextField {
            id: dirField
            Kirigami.FormData.label: tr("Folder lirik:")
            placeholderText: "~/lyrics"
            enabled: saveCheck.checked
        }
        QQC2.CheckBox {
            id: romanCheck
            Kirigami.FormData.label: tr("Romanisasi:")
            text: tr("Ubah lirik Jepang/Mandarin/Korea dll ke huruf Latin")
        }
        QQC2.ComboBox {
            id: romanModeBox
            Kirigami.FormData.label: tr("Tampilan romanisasi:")
            enabled: romanCheck.checked
            model: [tr("Hanya romaji"), tr("Asli + romaji (dua baris)")]
        }
        QQC2.TextField {
            id: playerField
            Kirigami.FormData.label: tr("Pemutar:")
            placeholderText: "spotify,vlc,elisa"
        }
        QQC2.Label {
            text: tr("Pisahkan dengan koma. Yang sedang Playing diutamakan, lalu urutan daftar. Kosongkan untuk semua pemutar (kecuali blacklist di bawah). Cek nama dengan: playerctl -l")
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            opacity: 0.7
        }
        QQC2.TextField {
            id: blacklistField
            Kirigami.FormData.label: tr("Blacklist:")
            placeholderText: "firefox,chromium,chrome"
        }
        QQC2.Label {
            text: tr("Pemutar yang diabaikan saat kolom Pemutar kosong, supaya video di browser tidak dikira lagu. Kolom Pemutar yang diisi selalu didahulukan dari blacklist.")
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            opacity: 0.7
        }
    }
}
