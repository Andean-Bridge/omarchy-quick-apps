// SPDX-License-Identifier: MIT
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Kept local so the plugin does not require the OverlayWindow added in 4.5.
PanelWindow {
    id: root
    property bool shown: false
    property bool rightToLeft: false
    property var targetScreen: null
    function focusedScreen() {
        var monitor = Hyprland.focusedMonitor;
        for (var i = 0; i < Quickshell.screens.length; i++)
            if (monitor && Quickshell.screens[i].name === monitor.name)
                return Quickshell.screens[i];
        return Quickshell.screens.length ? Quickshell.screens[0] : null;
    }
    onShownChanged: {
        targetScreen = shown ? focusedScreen() : null;
        if (shown)
            Hyprland.refreshMonitors();
    }
    visible: shown && !!targetScreen
    screen: targetScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "andean-bridge-quick-apps"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.shown && Quickshell.screens.indexOf(root.targetScreen) < 0)
                root.targetScreen = root.focusedScreen();
        }
    }
    Binding {
        target: root.contentItem
        property: "LayoutMirroring.enabled"
        value: root.rightToLeft
    }
    Binding {
        target: root.contentItem
        property: "LayoutMirroring.childrenInherit"
        value: true
    }
}
