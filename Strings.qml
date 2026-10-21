// SPDX-License-Identifier: MIT
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"
    property bool hasNativeTranslations: false
    property var english: ({})
    property var localized: ({})
    readonly property string language: nativeLoader.item ? nativeLoader.item.language : Qt.locale().name.replace(/_/g, "-")
    readonly property bool rightToLeft: nativeLoader.item ? nativeLoader.item.rightToLeft : Qt.locale().textDirection === Qt.RightToLeft
    function parse(raw) {
        try {
            return JSON.parse(raw);
        } catch (e) {
            return {};
        }
    }
    function t(key) {
        if (nativeLoader.item)
            return nativeLoader.item.t(key);
        return localized[key] || english[key] || key;
    }
    function number(value) {
        return nativeLoader.item ? nativeLoader.item.number(value) : Number(value).toLocaleString(Qt.locale(), "f", 0);
    }
    function readingKey(event) {
        if (!rightToLeft)
            return event.key;
        if (event.key === Qt.Key_Left)
            return Qt.Key_Right;
        if (event.key === Qt.Key_Right)
            return Qt.Key_Left;
        return event.key;
    }
    FileView {
        path: root.omarchyPath + "/shell/Commons/Translations.qml"
        printErrors: false
        onLoaded: root.hasNativeTranslations = true
        onLoadFailed: root.hasNativeTranslations = false
    }
    Loader {
        id: nativeLoader
        active: root.hasNativeTranslations
        source: active ? Qt.resolvedUrl("NativeStrings.qml") : ""
    }
    FileView {
        path: Qt.resolvedUrl("i18n/en.json").toString().replace(/^file:\/\//, "")
        blockLoading: true
        printErrors: false
        onLoaded: root.english = root.parse(text())
    }
    FileView {
        path: Qt.resolvedUrl("i18n/" + root.language.split("-")[0] + ".json").toString().replace(/^file:\/\//, "")
        blockLoading: true
        printErrors: false
        onLoaded: root.localized = root.parse(text())
        onLoadFailed: root.localized = ({})
    }
}
