import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: shellRoot

    UserConfig {
        id: userConfig
    }

    function toggleTodo() {
        // Close control center on all windows first
        shellRoot.forEachWindow((w) => { if (w && w.closeControlCenter) w.closeControlCenter(); });
        todoVariants.instances.forEach((w) => { if (w) w.toggle(); });
    }

    function forEachWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window)
                callback(window);
        }
    }

    function anyOverviewOpen() {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && window.overviewPhase !== "closed")
                return true;
        }

        return false;
    }

    function prepareOverviewAll() {
        shellRoot.forEachWindow((window) => window.prepareOverview());
    }

    function cancelPreparedOverviewAll() {
        shellRoot.forEachWindow((window) => window.cancelPreparedOverview());
    }

    function openOverviewAll() {
        shellRoot.forEachWindow((window) => window.openOverview());
    }

    function closeOverviewAll() {
        shellRoot.forEachWindow((window) => window.closeOverview());
    }

    function toggleOverviewAll() {
        if (shellRoot.anyOverviewOpen())
            shellRoot.closeOverviewAll();
        else
            shellRoot.openOverviewAll();
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            shellRoot.toggleOverviewAll();
        }

        function open() {
            shellRoot.openOverviewAll();
        }

        function close() {
            shellRoot.closeOverviewAll();
        }

        function refreshWallpaperCache() {
            shellRoot.forEachWindow((window) => {
                if (window && window.prewarmWallpaperCache)
                    window.prewarmWallpaperCache();
            });
        }
    }

    GlobalShortcut {
        appid: userConfig.overviewGlobalShortcutAppid
        name: userConfig.overviewGlobalShortcutName

        onPressed: shellRoot.toggleOverviewAll()
    }

    GlobalShortcut {
        appid: userConfig.overviewGlobalShortcutAppid
        name: "dynamic-island-time-hold"

        onPressed: {
            shellRoot.forEachWindow((w) => {
                if (w && w.tempShowTime)
                    w.tempShowTime();
            });
        }

        onReleased: {
            shellRoot.forEachWindow((w) => {
                if (w && w.restoreFromTempShowTime)
                    w.restoreFromTempShowTime();
            });
        }
    }

    IpcHandler {
        target: "time-hold"

        function press() {
            shellRoot.forEachWindow((w) => {
                if (w && w.tempShowTime)
                    w.tempShowTime();
            });
        }

        function release() {
            shellRoot.forEachWindow((w) => {
                if (w && w.restoreFromTempShowTime)
                    w.restoreFromTempShowTime();
            });
        }
    }




    IpcHandler {
        target: "todo"
        function toggle() {
            todoVariants.instances.forEach((w) => { if (w) w.toggle(); });
        }
    }

    IpcHandler {
        target: "pomodoro"
        function toggle() {
            shellRoot.forEachWindow((w) => { if (w && w.togglePomodoro) w.togglePomodoro(); });
        }
    }

    IpcHandler {
        target: "aiprompt"
        function toggle() {
            shellRoot.forEachWindow((w) => { if (w && w.toggleAiPrompt) w.toggleAiPrompt(); });
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle() {
            shellRoot.forEachWindow((w) => { if (w && w.toggleClipboard) w.toggleClipboard(); });
        }
    }

    IpcHandler {
        target: "volume-mixer"
        function toggle() {
            shellRoot.forEachWindow((w) => { if (w && w.toggleVolumeMixer) w.toggleVolumeMixer(); });
        }
    }


    Variants {
        id: panelVariants

        model: Quickshell.screens

        DynamicIslandWindow {
            required property var modelData

            screen: modelData
            shellRootController: shellRoot
        }
    }

    Variants {
        id: todoVariants

        model: Quickshell.screens

        TodoPopup {
            required property var modelData
            screen: modelData
        }
    }
}
