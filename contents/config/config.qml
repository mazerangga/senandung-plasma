// SPDX-FileCopyrightText: 2026 mazerangga
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Tampilan")
        icon: "preferences-desktop-font"
        source: "configGeneral.qml"
    }
}
