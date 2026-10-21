// SPDX-License-Identifier: MIT
import QtQuick
import qs.Commons as Commons

// Loaded only when the 4.5 translation component is present.
Item {
    readonly property string language: Commons.I18n.language
    readonly property bool rightToLeft: Commons.I18n.rightToLeft
    Commons.Translations {
        id: translations
        directory: Qt.resolvedUrl("i18n")
    }
    function t(key) {
        return translations.t(key);
    }
    function number(value) {
        return Commons.I18n.formatNumber(value);
    }
}
