// SPDX-License-Identifier: MIT
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "."
import "Ranking.js" as Ranking
import "AppModel.js" as AppModel
import "Config.js" as Config

Item {
    id: root
    property var shell: null
    property var manifest: null
    property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"
    readonly property var appLibrary: shell ? shell.appLibrary : null
    property bool opened: false
    property bool storageReady: false
    property bool historyReady: false
    property string historyError: ""
    property var options: Config.normalize({})
    property var allApps: []
    property var stats: ({})
    property string query: ""
    property var apps: []
    property int selectedIndex: 0
    property string pendingApp: ""
    readonly property string stateDirectory: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/quick-apps"
    readonly property string historyPath: stateDirectory + "/history.json"
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/quick-apps.json"
    readonly property int cellWidth: Style.space(122)
    readonly property int cellHeight: Style.space(112)
    readonly property int columns: Math.max(1, Math.min(4, Math.floor((panel.width - Style.space(100)) / cellWidth)))
    readonly property int iconSize: Style.space(44)

    Strings {
        id: strings
        omarchyPath: root.omarchyPath
    }

    function open(payloadJson) {
        query = "";
        selectedIndex = 0;
        if (appLibrary)
            appLibrary.refreshIcons();
        refreshCatalog();
        opened = true;
        Qt.callLater(function () {
            keys.forceActiveFocus();
        });
    }

    function close() {
        opened = false;
    }
    function status() {
        return JSON.stringify({
            opened: opened,
            query: query,
            selectedIndex: selectedIndex,
            apps: apps.map(function (entry) {
                return {
                    id: entry.id,
                    name: String(entry.name)
                };
            }),
            historyReady: historyReady,
            historyError: historyError,
            learning: options.learning,
            language: strings.language,
            card: {
                x: panel.screen ? panel.screen.x + card.x : 0,
                y: panel.screen ? panel.screen.y + card.y : 0,
                width: card.width,
                height: card.height
            }
        });
    }
    function dismiss() {
        opened = false;
        if (shell)
            shell.hide("andean-bridge.quick-apps");
    }

    function refreshCatalog() {
        if (!appLibrary)
            return;
        var entries = appLibrary.sortedEntries("").map(function (row) {
            return row.entry;
        });
        allApps = AppModel.visible(entries, options.hiddenApps, options.starterApps);
        rebuild();
        if (historyReady)
            observeActive();
    }

    function canonical(entry) {
        return AppModel.canonical(entry, allApps);
    }

    function entryFor(appId) {
        var key = String(appId || "").toLowerCase();
        if (Config.own(options.appAliases, key)) {
            var aliasEntry = DesktopEntries.byId(options.appAliases[key]);
            if (aliasEntry)
                return canonical(aliasEntry);
        }
        var matched = AppModel.match(appId, allApps, options.appAliases);
        if (matched)
            return matched;
        if (Config.own(options.appAliases, String(appId || "").toLowerCase()))
            return null;
        return canonical(DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId));
    }

    function record(id) {
        if (!options.learning || !historyReady || !id)
            return;
        var next = Ranking.record(stats, id, Date.now(), options);
        if (!next)
            return;
        stats = next;
        saveHistory.restart();
    }

    function observeActive() {
        if (!options.learning) {
            activityDelay.stop();
            return;
        }
        var active = ToplevelManager.activeToplevel;
        var entry = active ? entryFor(active.appId) : null;
        pendingApp = entry ? String(entry.id) : "";
        activityDelay.restart();
    }

    function rebuild() {
        if (!appLibrary) {
            apps = [];
            return;
        }
        var entries = appLibrary.sortedEntries(query).map(function (row) {
            return root.canonical(row.entry);
        }).filter(function (entry) {
            return !!entry;
        });
        entries = AppModel.unique(entries, options.starterApps);
        var running = [];
        var tops = ToplevelManager.toplevels.values;
        for (var i = 0; i < tops.length; i++) {
            var entry = entryFor(tops[i].appId);
            if (entry && running.indexOf(entry.id) < 0)
                running.push(entry.id);
        }
        // Freeze the order while open; it updates when opened again.
        apps = (query.trim() ? entries : Ranking.ranked(entries, stats, Date.now(), options.starterApps, running, options.halfLifeDays)).slice(0, 8);
        selectedIndex = Math.max(0, Math.min(selectedIndex, apps.length - 1));
        gridScroll.contentY = 0;
    }

    function setQuery(value) {
        query = String(value || "").slice(0, 256);
        selectedIndex = 0;
        rebuild();
    }
    function select(delta) {
        selectedIndex = Math.max(0, Math.min(apps.length - 1, selectedIndex + delta));
        var top = Math.floor(selectedIndex / columns) * cellHeight;
        if (top < gridScroll.contentY)
            gridScroll.contentY = top;
        else if (top + cellHeight > gridScroll.contentY + gridScroll.height)
            gridScroll.contentY = Math.min(gridScroll.contentHeight - gridScroll.height, top + cellHeight - gridScroll.height);
    }

    function windowFor(entry) {
        var values = Hyprland.toplevels.values;
        var best = null;
        var monitor = Hyprland.focusedMonitor;
        var currentWorkspace = monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1;
        for (var i = 0; i < values.length; i++) {
            var w = values[i], top = w.wayland;
            if (!top || top.parent)
                continue;
            var candidate = entryFor(top.appId);
            if (!candidate || candidate.id !== entry.id)
                continue;
            if (top.activated)
                return w;
            if (!best || (w.workspace && w.workspace.id === currentWorkspace && (!best.workspace || best.workspace.id !== currentWorkspace)))
                best = w;
        }
        return best;
    }

    function activate(index) {
        var number = Number(index);
        if (!opened || !Number.isInteger(number) || number < 0 || number >= apps.length)
            return;
        var entry = apps[number];
        if (!entry || !appLibrary)
            return;
        var window = windowFor(entry);
        record(String(entry.id));
        dismiss();
        if (!window) {
            appLibrary.launch(entry.id, appLibrary.entryName(entry));
            return;
        }
        var monitor = Hyprland.focusedMonitor;
        var current = monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1;
        var command = AppModel.focusCommand(window.address, window.workspace ? window.workspace.id : -1, window.workspace ? window.workspace.name : "", current);
        if (command)
            Quickshell.execDetached(["hyprctl", "dispatch", command]);
        else
            window.wayland.activate();
    }

    Process {
        command: ["mkdir", "-p", "-m", "700", "--", root.stateDirectory]
        running: true
        onExited: function (code) {
            if (code === 0)
                secureState.running = true;
            else
                root.historyError = "Cannot create history directory";
        }
    }
    Process {
        id: secureState
        command: ["chmod", "700", "--", root.stateDirectory]
        onExited: function (code) {
            root.storageReady = code === 0;
            if (code !== 0)
                root.historyError = "Cannot secure history directory";
        }
    }
    FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                var raw = text();
                if (raw.length > 262144)
                    throw new Error("Configuration exceeds 256 KiB");
                root.options = Config.normalize(JSON.parse(raw));
            } catch (e) {
                console.warn("Quick Apps: invalid configuration; using defaults:", e);
                root.options = Config.normalize({});
            }
            root.refreshCatalog();
        }
        onLoadFailed: {
            root.options = Config.normalize({});
            root.refreshCatalog();
        }
        onFileChanged: reload()
    }
    FileView {
        id: history
        path: root.storageReady ? root.historyPath : ""
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                var raw = text();
                if (raw.length > 1048576)
                    throw new Error("History exceeds 1 MiB");
                var data = JSON.parse(raw);
                root.stats = data.version === 1 ? Ranking.clean(data.apps, Date.now()) : ({});
            } catch (e) {
                console.warn("Quick Apps: invalid history; starting empty:", e);
                root.stats = ({});
            }
            root.historyReady = true;
            if (root.opened)
                root.rebuild();
            root.observeActive();
        }
        onLoadFailed: {
            if (root.storageReady) {
                root.historyReady = true;
                root.observeActive();
            }
        }
        onSaveFailed: {
            root.historyError = "Cannot save usage history";
            console.warn("Quick Apps:", root.historyError);
        }
    }
    Timer {
        id: saveHistory
        interval: 250
        onTriggered: history.setText(JSON.stringify({
            version: 1,
            apps: root.stats
        }, null, 2) + "\n")
    }
    Timer {
        id: activityDelay
        interval: root.options.focusDelayMs
        onTriggered: {
            var active = ToplevelManager.activeToplevel;
            var entry = active ? root.entryFor(active.appId) : null;
            if (entry && entry.id === root.pendingApp)
                root.record(String(entry.id));
        }
    }
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            root.observeActive();
        }
    }
    Connections {
        target: root.appLibrary
        function onAppsChanged() {
            root.refreshCatalog();
        }
    }
    onAppLibraryChanged: refreshCatalog()
    Component.onDestruction: if (saveHistory.running && historyReady)
        history.setText(JSON.stringify({
            version: 1,
            apps: stats
        }) + "\n")

    QuickOverlay {
        id: panel
        shown: root.opened
        rightToLeft: strings.rightToLeft
        Rectangle {
            anchors.fill: parent
            color: Commons.Color.menu.scrim
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
        }
        BorderSurface {
            id: card
            anchors.centerIn: parent
            width: root.columns * root.cellWidth + Style.space(40)
            height: Math.min(panel.height - Style.space(40), Style.space(162) + Math.ceil(Math.max(1, root.apps.length) / root.columns) * root.cellHeight)
            radius: Style.cornerRadius
            color: Commons.Color.menu.background
            borderSpec: Border.surfaceSpec("menu", "border", Commons.Color.menu.border, Style.normalBorderWidth)
            MouseArea {
                anchors.fill: parent
            }
            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: function (event) {
                    if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_8)
                        root.activate(event.key - Qt.Key_1);
                    else if (event.key === Qt.Key_Escape) {
                        if (root.query)
                            root.setQuery("");
                        else
                            root.dismiss();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        root.activate(root.selectedIndex);
                    else if (strings.readingKey(event) === Qt.Key_Left || event.key === Qt.Key_Backtab)
                        root.select(-1);
                    else if (strings.readingKey(event) === Qt.Key_Right || event.key === Qt.Key_Tab)
                        root.select(1);
                    else if (event.key === Qt.Key_Up)
                        root.select(-root.columns);
                    else if (event.key === Qt.Key_Down)
                        root.select(root.columns);
                    else if (Util.editsFilter(event, root.query))
                        root.setQuery(Util.editedFilter(event, root.query));
                    else if (!(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32)
                        root.setQuery(root.query + event.text);
                    else
                        return;
                    event.accepted = true;
                }
            }
            Column {
                x: Style.space(20)
                y: Style.space(20)
                width: parent.width - Style.space(40)
                spacing: Style.space(12)
                Item {
                    width: parent.width
                    height: Style.space(24)
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.PlainText
                        text: strings.t("title")
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.heading
                        color: Commons.Color.menu.text
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.PlainText
                        text: strings.t(root.query ? "results" : "frequent")
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.caption
                        color: Commons.Color.menu.text
                        opacity: 0.55
                    }
                }
                Rectangle {
                    width: parent.width
                    height: Style.space(38)
                    radius: Style.cornerRadius
                    color: Util.alpha(Commons.Color.menu.text, 0.06)
                    Text {
                        anchors.fill: parent
                        anchors.margins: Style.space(10)
                        verticalAlignment: Text.AlignVCenter
                        textFormat: Text.PlainText
                        text: root.query || strings.t("search")
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.body
                        color: Commons.Color.menu.text
                        opacity: root.query ? 1 : 0.55
                        elide: Text.ElideRight
                    }
                }
                Flickable {
                    id: gridScroll
                    width: parent.width
                    height: Math.max(Style.space(30), card.height - Style.space(162))
                    contentWidth: width
                    contentHeight: Math.ceil(Math.max(1, root.apps.length) / root.columns) * root.cellHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Grid {
                        columns: root.columns
                        Repeater {
                            model: root.apps
                            delegate: Item {
                                id: cell
                                required property int index
                                required property var modelData
                                width: root.cellWidth
                                height: root.cellHeight
                                readonly property bool selected: index === root.selectedIndex
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: Style.space(3)
                                    radius: Style.cornerRadius
                                    color: cell.selected ? Commons.Color.menu.selectedBackground : "transparent"
                                }
                                Image {
                                    id: icon
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: Style.space(12)
                                    width: root.iconSize
                                    height: root.iconSize
                                    sourceSize: Qt.size(width * 2, height * 2)
                                    source: root.appLibrary ? root.appLibrary.iconSource(cell.modelData.icon) : ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }
                                Text {
                                    anchors.top: icon.bottom
                                    anchors.topMargin: Style.space(10)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width - Style.space(12)
                                    textFormat: Text.PlainText
                                    text: root.appLibrary ? root.appLibrary.entryName(cell.modelData) : ""
                                    font.family: Style.font.menuFamily
                                    font.pixelSize: Style.font.body
                                    color: cell.selected ? Commons.Color.menu.selectedText : Commons.Color.menu.text
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Style.space(10)
                                    y: Style.space(7)
                                    textFormat: Text.PlainText
                                    text: strings.number(cell.index + 1)
                                    font.family: Style.font.menuFamily
                                    font.pixelSize: Style.font.caption
                                    color: Commons.Color.menu.text
                                    opacity: 0.35
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: root.selectedIndex = cell.index
                                    onClicked: root.activate(cell.index)
                                }
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.apps.length === 0
                        textFormat: Text.PlainText
                        text: strings.t("empty")
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.body
                        color: Commons.Color.menu.text
                        opacity: 0.6
                    }
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    textFormat: Text.PlainText
                    text: strings.t("hint")
                    font.family: Style.font.menuFamily
                    font.pixelSize: Style.font.caption
                    color: Commons.Color.menu.text
                    opacity: 0.45
                }
            }
        }
    }
}
