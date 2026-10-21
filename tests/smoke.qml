import QtQuick
import Quickshell

// Isolated loader: no desktop shell, bar, notifications, lock, or polkit service.
ShellRoot {
    id: root
    property bool failed: false
    property int launches: 0
    function check(condition, message) {
        if (!condition) {
            failed = true;
            console.error("QUICK_APPS_SMOKE_FAIL:", message);
        }
    }
    QtObject {
        id: facade
        property var appLibrary: library
        function hide(id) {
        }
    }
    Item {
        id: library
        signal appsChanged
        function sortedEntries(query) {
            var entries = [];
            for (var i = 0; i < 10; i++)
                entries.push({
                    id: "quick-apps-smoke-" + i,
                    name: "Test App " + i,
                    execString: "quick-apps-smoke-" + i,
                    icon: "application-x-executable"
                });
            entries.push({
                id: "quick-apps-smoke-markup",
                name: '<img src="https://example.invalid/test">',
                execString: "quick-apps-smoke-markup",
                icon: "application-x-executable"
            });
            return entries.filter(function (entry) {
                return !query || entry.name.toLowerCase().indexOf(String(query).toLowerCase()) >= 0;
            }).map(function (entry) {
                return {
                    entry: entry
                };
            });
        }
        function refreshIcons() {
        }
        function iconSource(icon) {
            return Quickshell.iconPath("application-x-executable", true);
        }
        function entryName(entry) {
            return entry.name;
        }
        function launch(id, name) {
            root.launches++;
        }
    }
    Loader {
        id: plugin
        source: "file://" + Quickshell.env("QUICK_APPS_SOURCE") + "/Menu.qml"
        onLoaded: {
            item.omarchyPath = Quickshell.env("QUICK_APPS_OMARCHY");
            item.shell = facade;
        }
        onStatusChanged: if (status === Loader.Error) {
            root.failed = true;
            console.error("QUICK_APPS_SMOKE_FAIL: loader error");
            Qt.quit();
        }
    }
    Timer {
        interval: 750
        running: true
        onTriggered: {
            root.check(!!plugin.item, "Plugin loads");
            if (plugin.item) {
                var menu = plugin.item;
                root.check(JSON.parse(menu.status()).historyReady, "State directory initialized");
                menu.open("{}");
                root.check(menu.opened && menu.apps.length === 8, "Eight apps on opening");
                menu.select(1);
                root.check(menu.selectedIndex === 1, "Arrow selection");
                menu.setQuery("Test App 9");
                root.check(menu.apps.length === 1 && menu.apps[0].id === "quick-apps-smoke-9", "Searches beyond the first eight apps");
                menu.activate(0);
                root.check(root.launches === 1 && !menu.opened, "Launches through the library and closes");
                menu.activate(0);
                root.check(root.launches === 1, "Ignores stale activation when closed");
                menu.open("{}");
                menu.setQuery("<img");
                root.check(menu.apps.length === 1 && menu.apps[0].name.indexOf("<img") === 0, "Markup-shaped app names remain text data");
                menu.setQuery("no-such-app-9999");
                root.check(menu.apps.length === 0, "Empty results");
                menu.close();
                root.check(!menu.opened, "Closes");
            }
            console.log(root.failed ? "QUICK_APPS_SMOKE_FAILED" : "QUICK_APPS_SMOKE_PASSED");
            Qt.quit();
        }
    }
}
