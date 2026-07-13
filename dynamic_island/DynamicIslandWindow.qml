import IslandBackend
import QtQml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

PanelWindow {
    // Timer restart is handled inside calendarShell which lives in
    // islandContainer scope — see onCalendarOpenChanged Connections there.

    id: root

    property var shellRootController: null
    property string overviewPhase: "closed"
    property bool overviewPreloading: false
    readonly property bool overviewPreparing: overviewPhase === "preparing"
    readonly property bool overviewVisible: overviewPhase === "preparing" || overviewPhase === "opening" || overviewPhase === "open"
    readonly property bool overviewLoaderActive: overviewPhase !== "closed" || overviewPreloading
    readonly property bool overviewDataReady: overviewLoader.item ? !!overviewLoader.item.overviewDataReady : false
    readonly property bool overviewWallpaperReady: overviewWallpaperCacheLoader.item ? (overviewWallpaperCacheLoader.item.cacheAvailable || !overviewWallpaperCacheLoader.item.busy) : false
    readonly property bool overviewVisualReady: overviewDataReady && overviewWallpaperReady
    readonly property bool overviewContentVisible: (overviewPhase === "opening" || overviewPhase === "open") && overviewVisualReady
    readonly property var hyprMonitor: screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
    readonly property string hyprMonitorName: hyprMonitor && hyprMonitor.name ? String(hyprMonitor.name) : ""
    readonly property bool monitorFocused: hyprMonitor ? hyprMonitor.focused : false
    readonly property bool connectivityPromptActive: controlCenterLoader.item ? controlCenterLoader.item.hasConnectivityPrompt : false
    readonly property int currentMonitorWorkspaceId: hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.id : 1
    readonly property bool anyPopupOpen: {
        if (!islandContainer)
            return false;

        const s = islandContainer.islandState;
        const islandExpanded = s === "expanded" || s === "control_center";
        return islandExpanded || root.wifiConnectivityDetailOpen || root.bluetoothConnectivityDetailOpen || root.calendarOpen;
    }
    readonly property bool anyActiveUiHovered: {
        const capsuleHovered = typeof capsuleHoverHandler !== "undefined" && capsuleHoverHandler && capsuleHoverHandler.hovered;
        const wifiHovered = wifiConnectivityDetailShell.visible && typeof wifiHoverHandler !== "undefined" && wifiHoverHandler && wifiHoverHandler.hovered;
        const bluetoothHovered = bluetoothConnectivityDetailShell.visible && typeof bluetoothHoverHandler !== "undefined" && bluetoothHoverHandler && bluetoothHoverHandler.hovered;
        const calendarHovered = calendarShell.visible && typeof calendarHoverHandler !== "undefined" && calendarHoverHandler && calendarHoverHandler.hovered;
        return capsuleHovered || wifiHovered || bluetoothHovered || calendarHovered;
    }
    readonly property bool activeWorkspaceHasFullscreen: globalHyprlandData.activeWorkspace ? !!globalHyprlandData.activeWorkspace.hasfullscreen : false
    readonly property bool shouldHideClockPill: {
        if (root.overviewVisible)
            return false;

        if (!islandContainer)
            return false;

        const s = islandContainer.islandState;
        const isResting = s === "normal" || s === "lyrics" || s === "custom";
        return activeWorkspaceHasFullscreen && isResting;
    }
    readonly property bool swActive: root.stopwatchMounted && stopwatchLoader.item && stopwatchLoader.item.isRunning
    readonly property bool tmActive: root.timerMounted && timerLoader.item && (timerLoader.item.running || timerLoader.item.finished)
    readonly property bool pmActive: pomodoroLoader.item && pomodoroLoader.item.active
    readonly property int activeRingCount: (swActive ? 1 : 0) + (tmActive ? 1 : 0) + (pmActive ? 1 : 0)
    readonly property bool bothRunning: activeRingCount >= 2
    readonly property bool persistentRingActive: activeRingCount >= 1
    readonly property string rightRingType: {
        if (tmActive)
            return "timer";

        if (pmActive)
            return "pomodoro";

        if (swActive)
            return "stopwatch";

        return "";
    }
    readonly property string leftRingType: {
        if (!bothRunning)
            return "";

        if (tmActive) {
            if (pmActive)
                return "pomodoro";

            if (swActive)
                return "stopwatch";

        } else if (pmActive) {
            if (swActive)
                return "stopwatch";

        }
        return "";
    }
    readonly property real normalPillWidth: {
        let leftPadding = root.bothRunning ? 56 : (userConfig.petEnabled ? 58 : 16);
        let rightPadding = root.persistentRingActive ? 56 : 16;
        return leftPadding + dummyTimeMeasureText.implicitWidth + rightPadding;
    }
    readonly property string iconFontFamily: userConfig.iconFontFamily
    readonly property string textFontFamily: userConfig.textFontFamily
    readonly property string heroFontFamily: userConfig.heroFontFamily
    readonly property string timeFontFamily: userConfig.timeFontFamily
    readonly property int dynamicIslandAcceptedButtons: userConfig.mouseButtonsMask([userConfig.dynamicIslandSwipeButton, userConfig.dynamicIslandPrimaryButton, userConfig.dynamicIslandSecondaryButton, userConfig.dynamicIslandMiddleButton])
    readonly property real overviewWallpaperScale: 0.18
    readonly property real overviewWallpaperCacheScaleMultiplier: 1.75
    readonly property int overviewWallpaperTargetWidth: {
        const screenWidth = hyprMonitor ? hyprMonitor.width : (screen ? screen.width : 1920);
        const monitorScale = hyprMonitor && hyprMonitor.scale ? hyprMonitor.scale : 1;
        const workspaceWidth = Math.max(180, screenWidth * overviewWallpaperScale / monitorScale);
        return Math.max(1, Math.round(workspaceWidth * overviewWallpaperCacheScaleMultiplier));
    }
    readonly property int overviewWallpaperTargetHeight: {
        const screenHeight = hyprMonitor ? hyprMonitor.height : (screen ? screen.height : 1080);
        const monitorScale = hyprMonitor && hyprMonitor.scale ? hyprMonitor.scale : 1;
        const workspaceHeight = Math.max(120, screenHeight * overviewWallpaperScale / monitorScale);
        return Math.max(1, Math.round(workspaceHeight * overviewWallpaperCacheScaleMultiplier));
    }
    readonly property real overviewCapsuleWidth: islandContainer.overviewView ? islandContainer.overviewView.width : 760
    readonly property real overviewCapsuleHeight: islandContainer.overviewView ? islandContainer.overviewView.height : 308
    readonly property real overviewCapsuleRadius: islandContainer.overviewView ? islandContainer.overviewView.largeWorkspaceRadius + islandContainer.overviewView.outerPadding : 44
    readonly property color overviewCapsuleColor: islandContainer.overviewView ? islandContainer.overviewView.cardColor : "#ee17181b"
    readonly property color overviewCapsuleBorderColor: islandContainer.overviewView ? islandContainer.overviewView.cardBorderColor : "#33ffffff"
    property bool wifiConnectivityDetailOpen: false
    property bool wifiConnectivityDetailMounted: false
    property bool bluetoothConnectivityDetailOpen: false
    property bool bluetoothConnectivityDetailMounted: false
    property bool calendarOpen: false
    property bool calendarMounted: false
    property bool aiPromptOpen: false
    property bool aiPromptMounted: false
    property bool stopwatchMounted: false
    property bool timerMounted: false
    property bool pomodoroIsOnBreak: false
    property bool overviewWallpaperRefreshPending: false
    readonly property bool anyConnectivityDetailMounted: wifiConnectivityDetailMounted || bluetoothConnectivityDetailMounted
    readonly property real connectivityDetailWidth: 318
    readonly property real connectivityDetailHeight: 404
    readonly property real connectivityDetailGap: 16
    readonly property int connectivityDetailAnimationDuration: 360
    readonly property real calendarPanelWidth: 320
    readonly property real calendarPanelHeight: 348
    readonly property int calendarAnimationDuration: 360
    readonly property string overviewWallpaperSource: overviewWallpaperCacheLoader.item ? overviewWallpaperCacheLoader.item.effectiveSource : userConfig.wallpaperPath

    function togglePomodoro() {
        if (pomodoroLoader.item)
            pomodoroLoader.item.toggle();

    }



    function toggleClipboard() {
        islandContainer.handleConfiguredClickAction("toggleClipboard");
    }

    function toggleVolumeMixer() {
        islandContainer.handleConfiguredClickAction("toggleVolumeMixer");
    }


    function closeControlCenter() {
        if (islandContainer.islandState === "control_center")
            islandContainer.restoreRestingCapsule(false);

    }

    function beginOverviewOpening() {
        if (!overviewPreparing)
            return ;

        if (overviewLoader.status !== Loader.Ready || !overviewVisualReady)
            return ;

        overviewPreloading = false;
        overviewPhase = "opening";
        overviewRevealTimer.restart();
    }

    function prepareOverview() {
        if (overviewPhase !== "closed")
            return ;

        overviewPreloading = true;
        overviewPreloadExpireTimer.restart();
    }

    function cancelPreparedOverview() {
        if (overviewPhase !== "closed")
            return ;

        overviewPreloadExpireTimer.stop();
        overviewPreloading = false;
    }

    function tempShowTime() {
        if (islandContainer)
            islandContainer.tempShowTime();
    }

    function restoreFromTempShowTime() {
        if (islandContainer)
            islandContainer.restoreFromTempShowTime();
    }


    function openOverview() {
        if (overviewPhase !== "closed")
            return ;

        overviewPreloadExpireTimer.stop();
        overviewPreloading = true;
        overviewPhase = "preparing";
        if (overviewLoader.status === Loader.Ready)
            beginOverviewOpening();

    }

    function closeOverview() {
        if (!overviewLoaderActive)
            return ;

        overviewRevealTimer.stop();
        overviewPreloadExpireTimer.stop();
        islandContainer.restoreRestingCapsule(true);
        overviewPreloading = false;
        overviewPhase = "closed";
    }

    function closeOverviewEverywhere() {
        if (shellRootController && shellRootController.closeOverviewAll) {
            shellRootController.closeOverviewAll();
            return ;
        }
        closeOverview();
    }

    function setConnectivityDetailVisible(kind, open) {
        const nextOpen = !!open;
        if (kind === "wifi") {
            if (nextOpen) {
                wifiConnectivityDetailCleanupTimer.stop();
                wifiConnectivityDetailMounted = true;
                wifiConnectivityDetailOpen = true;
            } else {
                if (!wifiConnectivityDetailMounted && !wifiConnectivityDetailOpen)
                    return ;

                wifiConnectivityDetailOpen = false;
                wifiConnectivityDetailCleanupTimer.restart();
            }
            return ;
        }
        if (kind === "bluetooth") {
            if (nextOpen) {
                bluetoothConnectivityDetailCleanupTimer.stop();
                bluetoothConnectivityDetailMounted = true;
                bluetoothConnectivityDetailOpen = true;
            } else {
                if (!bluetoothConnectivityDetailMounted && !bluetoothConnectivityDetailOpen)
                    return ;

                bluetoothConnectivityDetailOpen = false;
                bluetoothConnectivityDetailCleanupTimer.restart();
            }
        }
    }

    function closeAllConnectivityDetails() {
        setConnectivityDetailVisible("wifi", false);
        setConnectivityDetailVisible("bluetooth", false);
    }

    function setCalendarVisible(open) {
        const nextOpen = !!open;
        if (nextOpen) {
            calendarCleanupTimer.stop();
            calendarMounted = true;
            calendarOpen = true;
        } else {
            if (!calendarMounted && !calendarOpen)
                return ;

            calendarOpen = false;
            calendarCleanupTimer.restart();
        }
    }

    function toggleCalendar() {
        if (calendarOpen)
            setCalendarVisible(false);
        else
            setCalendarVisible(true);
    }

    function setAiPromptVisible(open) {
        const nextOpen = !!open;
        if (nextOpen) {
            aiPromptCleanupTimer.stop();
            aiPromptMounted = true;
            aiPromptOpen = true;
        } else {
            if (!aiPromptMounted && !aiPromptOpen)
                return ;

            aiPromptOpen = false;
            aiPromptCleanupTimer.restart();
        }
    }

    function toggleAiPrompt() {
        if (aiPromptOpen)
            setAiPromptVisible(false);
        else
            setAiPromptVisible(true);
    }

    function collapseAll() {
        if (islandContainer)
            islandContainer.restoreRestingCapsule(false);

        root.wifiConnectivityDetailOpen = false;
        root.bluetoothConnectivityDetailOpen = false;
        root.setCalendarVisible(false);
    }

    function openOverviewEverywhere() {
        if (shellRootController && shellRootController.openOverviewAll) {
            shellRootController.openOverviewAll();
            return ;
        }
        openOverview();
    }

    function prepareOverviewEverywhere() {
        if (shellRootController && shellRootController.prepareOverviewAll) {
            shellRootController.prepareOverviewAll();
            return ;
        }
        prepareOverview();
    }

    function cancelPreparedOverviewEverywhere() {
        if (shellRootController && shellRootController.cancelPreparedOverviewAll) {
            shellRootController.cancelPreparedOverviewAll();
            return ;
        }
        cancelPreparedOverview();
    }

    function toggleOverviewEverywhere() {
        if (shellRootController && shellRootController.toggleOverviewAll) {
            shellRootController.toggleOverviewAll();
            return ;
        }
        if (overviewLoaderActive)
            closeOverviewEverywhere();
        else
            openOverviewEverywhere();
    }

    function normalizeWorkspaceId(rawValue) {
        const parsed = parseInt(String(rawValue === undefined || rawValue === null ? "" : rawValue), 10);
        return isNaN(parsed) ? -1 : parsed;
    }

    function syncWorkspaceState() {
        if (currentMonitorWorkspaceId >= 1)
            islandContainer.currentWs = currentMonitorWorkspaceId;

    }

    function showWorkspaceForThisMonitor(workspaceId) {
        const targetWorkspaceId = normalizeWorkspaceId(workspaceId);
        if (targetWorkspaceId >= 1)
            islandContainer.showWorkspaceCapsule(targetWorkspaceId);

    }

    function prewarmWallpaperCache() {
        overviewWallpaperRefreshPending = true;
        overviewWallpaperCacheKeepAliveTimer.restart();
        if (overviewWallpaperCacheLoader.item) {
            overviewWallpaperCacheLoader.item.refreshNow();
            overviewWallpaperRefreshPending = false;
        }
    }

    function handleWorkspaceEvent(event) {
        if (!event)
            return ;

        if (hyprMonitorName === "")
            return ;

        if (event.name === "workspacev2" || event.name === "workspace") {
            const args = event.parse(event.name === "workspacev2" ? 2 : 1);
            const targetWorkspaceId = normalizeWorkspaceId(args.length > 0 ? args[0] : "");
            if (targetWorkspaceId < 1)
                return ;

            Qt.callLater(() => {
                const focusedWorkspace = Hyprland.focusedWorkspace;
                if (!root.monitorFocused || !focusedWorkspace)
                    return ;

                if (focusedWorkspace.id !== targetWorkspaceId)
                    return ;

                root.showWorkspaceForThisMonitor(targetWorkspaceId);
            });
            return ;
        }
        if (event.name === "focusedmonv2" || event.name === "focusedmon") {
            const args = event.parse(2);
            const targetMonitorName = args.length > 0 ? String(args[0]) : "";
            const targetWorkspaceId = normalizeWorkspaceId(args.length > 1 ? args[1] : "");
            if (targetWorkspaceId < 1)
                return ;

            if (hyprMonitorName !== "" && targetMonitorName !== hyprMonitorName)
                return ;

            // `focusedmonv2` covers jumping to a workspace that already lives on another monitor.
            showWorkspaceForThisMonitor(targetWorkspaceId);
        }
    }

    color: "transparent"
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: root.anyPopupOpen
    implicitHeight: {
        if (root.overviewVisible) {
            return Math.max(Math.ceil(4 + root.connectivityDetailHeight + 12), Math.ceil(4 + root.overviewCapsuleHeight + 8));
        }
        
        let height = Math.max(Math.ceil(4 + root.connectivityDetailHeight + 12), 0);
        
        if (root.calendarMounted) {
            height = Math.max(height, Math.ceil(4 + 38 + 8 + root.calendarPanelHeight + 8));
        }
        if (root.aiPromptMounted) {
            height = Math.max(height, Math.ceil(4 + 38 + 8 + 340 + 8));
        }
        
        return height;
    }
    exclusiveZone: -1
    aboveWindows: true
    focusable: root.monitorFocused && (root.overviewVisible || root.connectivityPromptActive || root.aiPromptOpen)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: {
        const needsKeys = root.monitorFocused && (root.overviewVisible || root.connectivityPromptActive || root.aiPromptOpen || (islandContainer && islandContainer.islandState === "timer" && timerLoader.item && timerLoader.item.inputMode));
        return needsKeys ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None;
    }
    WlrLayershell.onKeyboardFocusChanged: {
        console.log("DynamicIslandWindow: keyboardFocus changed to", WlrLayershell.keyboardFocus, "on monitor", screen.name, "monitorFocused=", root.monitorFocused, "aiPromptOpen=", root.aiPromptOpen);
    }

    HyprlandFocusGrab {
        id: aiPromptFocusGrab
        windows: [ root ]
        active: root.aiPromptOpen && root.monitorFocused
    }
    onOverviewVisibleChanged: {
        if (overviewVisible && monitorFocused)
            overviewFocusTimer.restart();

    }
    onConnectivityPromptActiveChanged: {
        if (connectivityPromptActive && monitorFocused)
            connectivityPromptFocusTimer.restart();

    }
    onOverviewVisualReadyChanged: {
        if (overviewVisualReady)
            beginOverviewOpening();

    }
    onMonitorFocusedChanged: {
        if (overviewVisible && monitorFocused)
            overviewFocusTimer.restart();

        if (connectivityPromptActive && monitorFocused)
            connectivityPromptFocusTimer.restart();

    }
    onHyprMonitorChanged: syncWorkspaceState()

    UserConfig {
        id: userConfig
    }

    HyprlandData {
        id: globalHyprlandData
    }

    Text {
        id: dummyTimeMeasureText

        text: timeObj.currentTime
        font.pixelSize: 17
        font.family: root.heroFontFamily
        font.weight: Font.Bold
        font.letterSpacing: -0.25
        visible: false
    }

    Timer {
        id: overviewFocusTimer

        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: connectivityPromptFocusTimer

        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: overviewRevealTimer

        interval: 0
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "opening")
                root.overviewPhase = "open";

        }
    }

    Timer {
        id: overviewPreloadExpireTimer

        interval: 1200
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "closed")
                root.overviewPreloading = false;

        }
    }

    Timer {
        id: wifiConnectivityDetailCleanupTimer

        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.wifiConnectivityDetailMounted = false
    }

    Timer {
        id: bluetoothConnectivityDetailCleanupTimer

        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.bluetoothConnectivityDetailMounted = false
    }

    Timer {
        id: calendarCleanupTimer

        interval: root.calendarAnimationDuration
        repeat: false
        onTriggered: root.calendarMounted = false
    }

    Timer {
        id: aiPromptCleanupTimer

        interval: 180
        repeat: false
        onTriggered: root.aiPromptMounted = false
    }

    Timer {
        id: overviewWallpaperCacheKeepAliveTimer

        interval: 3000
        repeat: false
    }

    Loader {
        id: overviewWallpaperCacheLoader

        active: root.overviewLoaderActive || overviewWallpaperCacheKeepAliveTimer.running || (item && item.busy)
        asynchronous: false
        visible: false
        onLoaded: {
            if (root.overviewWallpaperRefreshPending && item) {
                item.refreshNow();
                root.overviewWallpaperRefreshPending = false;
            }
        }

        sourceComponent: Component {
            WallpaperThumbnailCache {
                sourcePath: userConfig.wallpaperPath
                targetWidth: root.overviewWallpaperTargetWidth
                targetHeight: root.overviewWallpaperTargetHeight
            }

        }

    }

    // --- 基础时钟引擎 ---
    QtObject {
        id: timeObj

        property string currentTime: "00:00"
        property string currentDateLabel: "Mon, Jan 01"
        readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        readonly property var dayNames: ["Sun", "Mon", "Tues", "Wed", "Thus", "Fri", "Sat"]

        function padTwoDigits(value) {
            return value < 10 ? "0" + value : String(value);
        }

        function formatDateLabel(now) {
            return dayNames[now.getDay()] + ", " + monthNames[now.getMonth()] + " " + padTwoDigits(now.getDate());
        }

    }

    Timer {
        id: clockTimer

        running: true
        repeat: true
        triggeredOnStart: true
        interval: 1000
        onTriggered: {
            let now = new Date();
            const h12 = now.getHours() % 12 || 12;
            const mins = now.getMinutes();
            const mStr = mins < 10 ? "0" + mins : "" + mins;
            timeObj.currentTime = now.getDate() + "  " + timeObj.dayNames[now.getDay()] + "  " + h12 + ":" + mStr;
            timeObj.currentDateLabel = timeObj.formatDateLabel(now);
            interval = (60 - now.getSeconds()) * 1000 - now.getMilliseconds();
        }
    }

    // --- 灵动岛主容器与全局状态 ---
    FocusScope {
        id: islandContainer

        property string islandState: "normal"
        property string splitIcon: userConfig.statusIcons["default"]
        property real osdProgress: -1
        property bool osdProgressAnimationEnabled: true
        property string osdCustomText: ""
        property int currentWs: root.currentMonitorWorkspaceId > 0 ? root.currentMonitorWorkspaceId : 1
        property int batteryCapacity: SysBackend.batteryCapacity
        property bool isCharging: SysBackend.batteryStatus === "Charging" || SysBackend.batteryStatus === "Full"
        property real currentVolume: -1
        property bool isMuted: false
        property real currentBrightness: -1
        property real currentCpuUsage: -1
        property real currentRamUsage: -1
        property real currentDiskUsage: -1
        property real currentCpuTemp: -1
        property real currentRamTotalGB: 0
        property real currentRamUsedGB: 0
        property real currentDiskTotalGB: 0
        property real currentDiskUsedGB: 0
        property string currentCpuFreq: "0.00 GHz"
        property string currentCpuProcesses: "0/0"
        readonly property bool customStatsHovered: islandState === "custom" && capsuleHoverHandler.hovered
        onCustomStatsHoveredChanged: {
            if (customStatsHovered) {
                autoHideTimer.stop();
            } else {
                if (islandState === "custom") {
                    restartAutoHideTimer(10000);
                }
            }
        }
        property string notificationAppName: ""
        property string notificationSummary: ""
        property string notificationBody: ""
        property real _lastCpuTotal: -1
        property real _lastCpuIdle: -1
        property var cavaLevels: [0, 0, 0, 0, 0, 0, 0, 0]
        property string _lastChargeStatus: SysBackend.batteryStatus
        property string _pendingVolType: ""
        property real _pendingVolVal: 0
        property string _lastVolType: ""
        property real _lastVolVal: -1
        property bool btJustConnected: false
        property real _pendingBlVal: 0
        property real swipeTransitionProgress: 0
        property string workspaceOriginSide: "none"
        property string splitOriginSide: "none"
        property string restingState: "normal"
        property bool expandedByPlayerAutoOpen: false
        property real customCapsuleWidth: 220
        property real lyricsCapsuleWidth: 220
        property bool sideSwipeSettling: false
        readonly property int defaultAutoHideInterval: 1250
        readonly property int notificationAutoHideInterval: 4200
        readonly property int swipeAnimationDuration: 220
        readonly property bool blocksTransientSplit: islandState === "expanded" || islandState === "control_center" || islandState === "notification"
        readonly property bool splitShowsProgress: islandState === "split" && osdProgress >= 0
        readonly property bool splitShowsText: islandState === "split" && osdProgress < 0 && osdCustomText !== ""
        readonly property bool splitShowsIconOnly: islandState === "split" && osdProgress < 0 && osdCustomText === ""
        readonly property bool splitUsesExtendedLayout: splitShowsProgress || splitShowsText
        readonly property real splitCapsuleWidth: splitShowsProgress ? 248 : (splitShowsText ? 220 : 140)
        readonly property bool canShowSideSwipe: islandState === "normal" || islandState === "custom" || islandState === "lyrics" || (islandState === "long_capsule" && workspaceOriginSide === "none")
        readonly property real rightSwipeProgress: Math.max(0, swipeTransitionProgress)
        readonly property var configuredLeftSwipeIds: buildNormalizedSwipeItemIds(userConfig.dynamicIslandLeftSwipeItems)
        readonly property bool usesSystemStatsModule: configuredLeftSwipeIds.indexOf("cpu") !== -1 || configuredLeftSwipeIds.indexOf("ram") !== -1 || configuredLeftSwipeIds.indexOf("disk") !== -1 || configuredLeftSwipeIds.indexOf("temp") !== -1
        readonly property bool usesCavaModule: configuredLeftSwipeIds.indexOf("cava") !== -1
        readonly property var customLeftItems: buildCustomSwipeItems(userConfig.dynamicIslandLeftSwipeItems)
        readonly property bool hasCustomLeftItems: customLeftItems.length > 0
        readonly property bool customSwipeVisible: !root.overviewVisible && hasCustomLeftItems && (capsuleMouseArea.sideSwipeInteractive ? swipeTransitionProgress < 0 : (islandState === "custom" || (islandState === "normal" && swipeTransitionProgress < 0) || (islandState === "split" && splitOriginSide === "left") || (islandState === "long_capsule" && (workspaceOriginSide === "left" || swipeTransitionProgress < 0))))
        readonly property bool lyricsSwipeVisible: !root.overviewVisible && (capsuleMouseArea.sideSwipeInteractive ? swipeTransitionProgress >= 0 : (islandState === "lyrics" || (islandState === "normal" && swipeTransitionProgress >= 0) || (islandState === "split" && splitOriginSide === "right") || (islandState === "long_capsule" && (workspaceOriginSide === "right" || swipeTransitionProgress > 0))))
        readonly property bool expandedLayerVisible: !root.overviewVisible && islandState === "expanded"
        readonly property bool notificationLayerVisible: !root.overviewVisible && islandState === "notification"
        readonly property bool controlCenterLayerVisible: !root.overviewVisible && islandState === "control_center"
        readonly property bool clipboardLayerVisible: !root.overviewVisible && islandState === "clipboard"
        readonly property bool volumeMixerLayerVisible: !root.overviewVisible && islandState === "volume_mixer"
        readonly property string lyricsDisplayText: lyricsBridge.displayText
        readonly property var overviewView: overviewLoader.item && overviewLoader.item.overviewView ? overviewLoader.item.overviewView : null
        property string lastActivePlayerDbusName: ""
        property var playersList: Mpris.players.values !== undefined ? Mpris.players.values : Mpris.players
        property var activePlayer: null
        property bool userSelectedPlayer: false
        property string manuallySelectedPlayerDbusName: ""
        property string activePlayerName: {
            if (!activePlayer)
                return "";

            if (activePlayer.identity)
                return activePlayer.identity;

            if (activePlayer.dbusName) {
                const parts = activePlayer.dbusName.split('.');
                const last = parts[parts.length - 1];
                if (last.startsWith("MediaPlayer2."))
                    return last.replace("MediaPlayer2.", "");

                return last;
            }
            return "Player";
        }
        property string lyricsLookupTitle: activePlayer ? (activePlayer.trackTitle || activePlayer.title || "") : ""
        property string lyricsLookupArtist: {
            if (!activePlayer)
                return "";

            let a = activePlayer.artist;
            if (!a && activePlayer.metadata)
                a = activePlayer.metadata["xesam:artist"];

            if (a)
                return Array.isArray(a) ? a.join(", ") : String(a);

            return "";
        }
        property string currentTrack: activePlayer ? (lyricsLookupTitle !== "" ? lyricsLookupTitle : "Unknown") : ""
        property string currentArtist: {
            if (!activePlayer)
                return "";

            if (lyricsLookupArtist !== "")
                return lyricsLookupArtist;

            return "Unknown";
        }
        property string currentArtUrl: activePlayer ? (activePlayer.trackArtUrl || activePlayer.artUrl || "") : ""
        property string inlineLyricsRaw: {
            if (!activePlayer || !activePlayer.metadata)
                return "";

            let inlineLyrics = activePlayer.metadata["xesam:asText"];
            if (!inlineLyrics)
                inlineLyrics = activePlayer.metadata["xesam:comment"];

            if (Array.isArray(inlineLyrics))
                return inlineLyrics.join("\n");

            return inlineLyrics ? String(inlineLyrics) : "";
        }
        property real trackProgress: 0
        property string timePlayed: "0:00"
        property string timeTotal: "0:00"

        function handleConfiguredClickAction(actionName) {
            switch (actionName) {
            case "":
            case "none":
                return ;
            case "toggleExpandedPlayer":
                if (islandState === "expanded") {
                    autoHideTimer.stop();
                    smartRestoreState();
                } else {
                    showExpandedPlayer(false);
                }
                return ;
            case "openExpandedPlayer":
                showExpandedPlayer(false);
                return ;
            case "closeExpandedPlayer":
                if (islandState === "expanded")
                    smartRestoreState();

                return ;
            case "toggleControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                else
                    showControlCenter();
                return ;
            case "openControlCenter":
                showControlCenter();
                return ;
            case "closeControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();

                return ;
            case "toggleAiPrompt":
                if (islandState === "aiprompt")
                    smartRestoreState();
                else
                    showAiPrompt();
                return ;
            case "openAiPrompt":
                showAiPrompt();
                return ;
            case "closeAiPrompt":
                if (islandState === "aiprompt")
                    smartRestoreState();
                return ;
            case "toggleClipboard":
                if (islandState === "clipboard")
                    smartRestoreState();
                else
                    showClipboard();
                return ;
            case "openClipboard":
                showClipboard();
                return ;
            case "closeClipboard":
                if (islandState === "clipboard")
                    smartRestoreState();
                return ;
            case "toggleVolumeMixer":
                if (islandState === "volume_mixer")
                    smartRestoreState();
                else
                    showVolumeMixer();
                return ;
            case "openVolumeMixer":
                showVolumeMixer();
                return ;
            case "closeVolumeMixer":
                if (islandState === "volume_mixer")
                    smartRestoreState();
                return ;
            case "toggleOverview":
                root.toggleOverviewEverywhere();
                return ;
            case "openOverview":
                root.openOverviewEverywhere();
                return ;
            case "closeOverview":
                root.closeOverviewEverywhere();
                return ;
            case "toggleLyrics":
                if (restingState === "lyrics") {
                    islandContainer.userSwipedAwayFromLyrics = true;
                    showTimeCapsule();
                } else {
                    islandContainer.userSwipedAwayFromLyrics = false;
                    showLyricsCapsule();
                }
                return ;
            case "showLyrics":
                islandContainer.userSwipedAwayFromLyrics = false;
                showLyricsCapsule();
                return ;
            case "showTime":
                islandContainer.userSwipedAwayFromLyrics = true;
                showTimeCapsule();
                return ;
            case "restoreRestingCapsule":
                smartRestoreState();
                return ;
            default:
                console.warn("Unknown Dynamic Island click action:", actionName);
            }
        }

        function normalizeSwipeItemId(rawId) {
            return String(rawId === undefined || rawId === null ? "" : rawId).trim().toLowerCase();
        }

        function formatPercentText(value) {
            return Math.round(Math.max(0, value) * 100) + "%";
        }

        function clamp01(value) {
            return Math.max(0, Math.min(1, value));
        }

        function applyBrightnessOutput(text) {
            const match = String(text === undefined || text === null ? "" : text).match(/,(\d+)%/);
            if (!match)
                return ;

            currentBrightness = clamp01(parseInt(match[1], 10) / 100);
        }

        function applyVolumeOutput(text) {
            const source = String(text === undefined || text === null ? "" : text);
            const match = source.match(/([0-9]*\.?[0-9]+)/);
            if (match)
                currentVolume = clamp01(parseFloat(match[1]));

            isMuted = /\bMUTED\b/i.test(source);
        }

        function refreshMissingLeftSwipeValues() {
            if (currentBrightness < 0 && !brightnessSnapshot.running)
                brightnessSnapshot.exec(["brightnessctl", "-m"]);

            if (currentVolume < 0 && !volumeSnapshot.running)
                volumeSnapshot.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]);

            if (usesSystemStatsModule && !systemStatsSnapshot.running)
                systemStatsSnapshot.exec(systemStatsSnapshot.command);

        }

        function buildNormalizedSwipeItemIds(rawItems) {
            const source = Array.isArray(rawItems) ? rawItems : [];
            const resolved = [];
            const seen = {
            };
            for (let index = 0; index < source.length; index++) {
                const itemId = normalizeSwipeItemId(source[index]);
                if (itemId === "" || seen[itemId])
                    continue;

                seen[itemId] = true;
                resolved.push(itemId);
            }
            return resolved;
        }

        function applySystemStatsOutput(text) {
            const lines = String(text === undefined || text === null ? "" : text).trim().split(/\r?\n/);
            for (let index = 0; index < lines.length; index++) {
                const line = lines[index].trim();
                if (line === "")
                    continue;

                const parts = line.split(/\s+/);
                if (parts[0] === "cpu" && parts.length >= 6) {
                    let total = 0;
                    for (let valueIndex = 1; valueIndex < parts.length; valueIndex++) total += Number(parts[valueIndex]) || 0
                    const idle = (Number(parts[4]) || 0) + (Number(parts[5]) || 0);
                    if (_lastCpuTotal >= 0 && _lastCpuIdle >= 0 && total > _lastCpuTotal) {
                        const totalDiff = total - _lastCpuTotal;
                        const idleDiff = idle - _lastCpuIdle;
                        currentCpuUsage = totalDiff > 0 ? clamp01((totalDiff - idleDiff) / totalDiff) : 0;
                    } else {
                        currentCpuUsage = currentCpuUsage >= 0 ? currentCpuUsage : 0;
                    }
                    _lastCpuTotal = total;
                    _lastCpuIdle = idle;
                    continue;
                }
                if (parts[0] === "mem" && parts.length >= 3) {
                    const totalMem = Number(parts[1]) || 0;
                    const availableMem = Number(parts[2]) || 0;
                    if (totalMem > 0) {
                        currentRamUsage = clamp01((totalMem - availableMem) / totalMem);
                        currentRamTotalGB = totalMem / 1024 / 1024;
                        currentRamUsedGB = (totalMem - availableMem) / 1024 / 1024;
                    }
                }
                if (parts[0] === "disk" && parts.length >= 3) {
                    const totalDisk = Number(parts[1]) || 0;
                    const availableDisk = Number(parts[2]) || 0;
                    if (totalDisk > 0) {
                        currentDiskUsage = clamp01((totalDisk - availableDisk) / totalDisk);
                        currentDiskTotalGB = totalDisk / 1024 / 1024;
                        currentDiskUsedGB = (totalDisk - availableDisk) / 1024 / 1024;
                    }
                }
                if (parts[0] === "temp" && parts.length >= 2) {
                    currentCpuTemp = Number(parts[1]) || 0;
                }
                if (parts[0] === "proc" && parts.length >= 2) {
                    currentCpuProcesses = parts[1];
                }
                if (parts[0] === "freq" && parts.length >= 2) {
                    currentCpuFreq = parts[1] + " GHz";
                }
            }
        }

        function applyCavaOutput(line) {
            const values = String(line === undefined || line === null ? "" : line).split(";").filter((value) => {
                return value !== "";
            });
            if (values.length === 0)
                return ;

            const nextLevels = [];
            for (let index = 0; index < values.length; index++) {
                const parsed = Number(values[index]);
                nextLevels.push(clamp01((isNaN(parsed) ? 0 : parsed) / 7));
            }
            cavaLevels = nextLevels;
        }

        function buildCustomSwipeItem(itemId) {
            switch (itemId) {
            case "time":
                return {
                    "id": itemId,
                    "icon": "",
                    "text": timeObj.currentTime
                };
            case "date":
                return {
                    "id": itemId,
                    "icon": "",
                    "text": timeObj.currentDateLabel
                };
            case "battery":
                if (batteryCapacity < 0)
                    return null;

                return {
                    "id": itemId,
                    "kind": "battery",
                    "level": Math.max(0, Math.min(100, batteryCapacity)),
                    "icon": "",
                    "text": Math.max(0, batteryCapacity) + "%"
                };
            case "volume":
                if (currentVolume < 0)
                    return null;

                return {
                    "id": itemId,
                    "icon": isMuted ? userConfig.statusIcons["mute"] : userConfig.statusIcons["volume"],
                    "text": formatPercentText(currentVolume)
                };
            case "brightness":
                if (currentBrightness < 0)
                    return null;

                return {
                    "id": itemId,
                    "icon": brightnessStatusIcon(currentBrightness),
                    "text": formatPercentText(currentBrightness)
                };
            case "workspace":
                return {
                    "id": itemId,
                    "icon": "",
                    "text": "Workspace " + currentWs
                };
            case "cpu":
                if (currentCpuUsage < 0)
                    return null;

                return {
                    "id": itemId,
                    "icon": userConfig.statusIcons["cpu"],
                    "text": formatPercentText(currentCpuUsage)
                };
            case "ram":
                if (currentRamUsage < 0)
                    return null;

                return {
                    "id": itemId,
                    "icon": userConfig.statusIcons["ram"],
                    "text": formatPercentText(currentRamUsage)
                };
            case "disk":
                if (currentDiskUsage < 0)
                    return null;

                return {
                    "id": itemId,
                    "icon": userConfig.statusIcons["disk"],
                    "text": formatPercentText(currentDiskUsage)
                };
            case "temp":
                if (currentCpuTemp < 0)
                    return null;

                return {
                    "id": itemId,
                    "icon": userConfig.statusIcons["temp"],
                    "text": Math.round(currentCpuTemp) + "°C"
                };
            case "cava":
                return {
                    "id": itemId,
                    "kind": "cava"
                };
            default:
                return null;
            }
        }

        function buildCustomSwipeItems(rawItems) {
            const source = Array.isArray(rawItems) ? rawItems : [];
            const resolved = [];
            const seen = {
            };
            for (let index = 0; index < source.length; index++) {
                const itemId = normalizeSwipeItemId(source[index]);
                if (itemId === "" || seen[itemId])
                    continue;

                seen[itemId] = true;
                const nextItem = buildCustomSwipeItem(itemId);
                if (nextItem)
                    resolved.push(nextItem);

            }
            return resolved;
        }

        function normalizeRestingState(nextState) {
            if (nextState === "lyrics")
                return "lyrics";

            if (nextState === "custom" && hasCustomLeftItems)
                return "custom";

            return "normal";
        }

        function restingStateProgress(nextState) {
            switch (normalizeRestingState(nextState)) {
            case "custom":
                return -1;
            case "lyrics":
                return 2;
            default:
                return 0;
            }
        }

        function restingStateSide(nextState) {
            switch (normalizeRestingState(nextState)) {
            case "custom":
                return "left";
            case "lyrics":
                return "right";
            default:
                return "none";
            }
        }

        function swipeRestProgressForState() {
            switch (islandState) {
            case "custom":
                return -1;
            case "lyrics":
                return 2;
            default:
                return 0;
            }
        }

        function currentTransientOriginSide() {
            switch (islandState) {
            case "custom":
                return "left";
            case "lyrics":
                return "right";
            case "long_capsule":
                return workspaceOriginSide;
            case "split":
                return splitOriginSide;
            default:
                return "none";
            }
        }

        function setOsdProgress(nextProgress, animate) {
            osdProgressAnimationReset.stop();
            osdProgressAnimationEnabled = animate;
            osdProgress = nextProgress;
            if (!animate)
                osdProgressAnimationReset.restart();

        }

        function abortSideTransientMode() {
            sideTransientRestoreTimer.stop();
            workspaceOriginSide = "none";
            splitOriginSide = "none";
        }

        function clearTransientCapsule() {
            setOsdProgress(-1, false);
            osdCustomText = "";
            notificationAppName = "";
            notificationSummary = "";
            notificationBody = "";
        }

        function prepareRestingCapsuleGeometry() {
            if (restingState === "custom")
                syncCustomCapsuleWidth();

            if (restingState === "lyrics")
                syncLyricsCapsuleWidth();

        }

        function applyRestingVisuals() {
            prepareRestingCapsuleGeometry();
            swipeTransitionProgress = restingStateProgress(restingState);
        }

        function sideSwipeRestProgressForProgress(progressValue) {
            if (progressValue <= -0.5)
                return -1;

            if (progressValue >= 0.5)
                return 2;

            return 0;
        }

        function sideSwipeRestWidthForProgress(progressValue) {
            if (progressValue <= -0.5)
                return customCapsuleWidth;

            if (progressValue >= 0.5)
                return lyricsCapsuleWidth;

            return root.normalPillWidth;
        }

        function customSideSwipeDragDistance() {
            const view = customSwipeLoader.item;
            if (view && view.dragDistance > 0)
                return view.dragDistance;

            return Math.max(root.normalPillWidth, customCapsuleWidth + 4);
        }

        function lyricsSideSwipeDragDistance() {
            const view = lyricsSwipeLoader.item;
            if (view && view.dragDistance > 0)
                return view.dragDistance;

            return Math.max(root.normalPillWidth, lyricsCapsuleWidth + 2);
        }

        function sideSwipeDragDistanceForDirection(direction) {
            if (direction === "left")
                return customSideSwipeDragDistance();

            if (direction === "right")
                return lyricsSideSwipeDragDistance();

            return root.normalPillWidth;
        }

        function advanceSideSwipeProgress(currentProgress, deltaX) {
            const minProgress = hasCustomLeftItems ? -1 : 0;
            const maxProgress = 2;
            let nextProgress = Math.max(minProgress, Math.min(maxProgress, currentProgress));
            let remainingDelta = deltaX;
            if (remainingDelta > 0) {
                if (nextProgress < 0) {
                    const leftDistance = Math.max(1, sideSwipeDragDistanceForDirection("left"));
                    const progressToCenter = Math.min(-nextProgress, remainingDelta / leftDistance);
                    nextProgress += progressToCenter;
                    remainingDelta -= progressToCenter * leftDistance;
                }
                if (remainingDelta > 0 && nextProgress < maxProgress) {
                    const rightDistance = Math.max(1, sideSwipeDragDistanceForDirection("right"));
                    nextProgress = Math.min(maxProgress, nextProgress + remainingDelta / rightDistance);
                }
            } else if (remainingDelta < 0) {
                if (nextProgress > 0) {
                    const rightDistance = Math.max(1, sideSwipeDragDistanceForDirection("right"));
                    const progressToCenter = Math.min(nextProgress, -remainingDelta / rightDistance);
                    nextProgress -= progressToCenter;
                    remainingDelta += progressToCenter * rightDistance;
                }
                if (remainingDelta < 0 && nextProgress > minProgress) {
                    const leftDistance = Math.max(1, sideSwipeDragDistanceForDirection("left"));
                    nextProgress = Math.max(minProgress, nextProgress + remainingDelta / leftDistance);
                }
            }
            return Math.max(minProgress, Math.min(maxProgress, nextProgress));
        }

        function resolveSideSwipeSettle(startProgress, finalProgress) {
            let settleAction = "time";
            let settleProgress = 0;
            let settleWidth = root.normalPillWidth;

            if (hasCustomLeftItems && finalProgress <= -0.44) {
                settleAction = "custom";
                settleProgress = -1;
                settleWidth = customCapsuleWidth;
            } else if (finalProgress > -0.44 && finalProgress < 0.44) {
                settleAction = "time";
                settleProgress = 0;
                settleWidth = root.normalPillWidth;
            } else if (finalProgress >= 0.44) {
                settleAction = "lyrics";
                settleProgress = 2;
                settleWidth = lyricsCapsuleWidth;
            } else {
                settleProgress = sideSwipeRestProgressForProgress(startProgress);
                settleWidth = sideSwipeRestWidthForProgress(startProgress);
                if (settleProgress === -1) settleAction = "custom";
                else if (settleProgress === 2) settleAction = "lyrics";
                else settleAction = "time";
            }

            return {
                "action": settleAction,
                "progress": settleProgress,
                "width": settleWidth
            };
        }

        function beginSideSwipeSettle(targetWidth) {
            sideSwipeSettling = true;
            mainCapsule.displayedWidth = targetWidth;
            sideSwipeSettleReset.restart();
        }

        function cancelSideSwipeSettle() {
            sideSwipeSettleReset.stop();
            sideSwipeSettling = false;
        }

        function finishSideSwipeSettle() {
            sideSwipeSettling = false;
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
        }

        function restartAutoHideTimer(duration) {
            autoHideTimer.interval = duration === undefined ? defaultAutoHideInterval : duration;
            autoHideTimer.restart();
        }

        function stopAutoHideTimer() {
            autoHideTimer.stop();
            autoHideTimer.interval = defaultAutoHideInterval;
        }

        function showTransientCapsule(icon, progress, customText) {
            if (progress === undefined)
                progress = -1;

            if (customText === undefined)
                customText = "";

            if (blocksTransientSplit)
                return ;

            const nextProgress = progress >= 0 ? progress : -1;
            const animateProgress = islandState === "split" && osdProgress >= 0 && nextProgress >= 0;
            const animateFromSide = currentTransientOriginSide();
            abortSideTransientMode();
            splitIcon = icon;
            osdCustomText = customText;
            setOsdProgress(nextProgress, animateProgress);
            splitOriginSide = animateFromSide;
            islandState = "split";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        function showNotificationCapsule(appName, summary, body) {
            if (root.overviewVisible || islandState === "control_center" || islandState === "expanded")
                return ;

            const cleanedAppName = cleanNotificationText(appName);
            const cleanedSummary = cleanNotificationText(summary);
            const cleanedBody = cleanNotificationText(body);
            const resolvedSummary = cleanedSummary !== "" ? cleanedSummary : (cleanedBody !== "" ? cleanedBody : "New notification");
            abortSideTransientMode();
            clearTransientCapsule();
            notificationAppName = cleanedAppName !== "" ? cleanedAppName : "Notification";
            notificationSummary = resolvedSummary;
            notificationBody = cleanedSummary !== "" ? cleanedBody : "";
            islandState = "notification";
            restartAutoHideTimer(notificationAutoHideInterval);
        }

        function suppressCapsuleClick() {
            capsuleMouseArea.suppressNextClick = true;
            swipeSuppressReset.restart();
        }

        function restoreRestingCapsule(forceImmediate) {
            if (forceImmediate === undefined)
                forceImmediate = false;

            const normalizedRestingState = normalizeRestingState(restingState);
            const targetSide = restingStateSide(normalizedRestingState);
            const shouldAnimateToSide = targetSide !== "none" && ((islandState === "long_capsule" && workspaceOriginSide === targetSide) || (islandState === "split" && splitOriginSide === targetSide));
            if (!forceImmediate && shouldAnimateToSide) {
                expandedByPlayerAutoOpen = false;
                prepareRestingCapsuleGeometry();
                swipeTransitionProgress = restingStateProgress(normalizedRestingState);
                stopAutoHideTimer();
                sideTransientRestoreTimer.restart();
                return ;
            }
            abortSideTransientMode();
            prepareRestingCapsuleGeometry();
            islandState = normalizedRestingState;
            clearTransientCapsule();
            applyRestingVisuals();
            expandedByPlayerAutoOpen = false;
            stopAutoHideTimer();
        }

        function setRestingState(nextState) {
            restingState = normalizeRestingState(nextState);
        }

        function smartRestoreState() {
            restoreRestingCapsule();
        }

        function showRestingCapsule(nextState) {
            setRestingState(nextState);
            restoreRestingCapsule();
            stopAutoHideTimer();
        }

        function showExpandedPlayer(autoOpened) {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "expanded";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            expandedByPlayerAutoOpen = autoOpened;
            root.setCalendarVisible(false);
            if (autoOpened)
                restartAutoHideTimer();
            else
                restartAutoHideTimer(10000);
        }

        function showControlCenter() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "control_center";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.setCalendarVisible(false);
            restartAutoHideTimer(10000);
        }

        function showAiPrompt() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "aiprompt";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.setCalendarVisible(false);
            stopAutoHideTimer();
        }

        function showClipboard() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "clipboard";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.setCalendarVisible(false);
            stopAutoHideTimer();
        }

        function showVolumeMixer() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "volume_mixer";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.setCalendarVisible(false);
            stopAutoHideTimer();
        }

        function showCustomCapsule() {
            if (!hasCustomLeftItems) {
                showTimeCapsule();
                return ;
            }
            refreshMissingLeftSwipeValues();
            showRestingCapsule("custom");
        }

        function showLyricsCapsule() {
            showRestingCapsule("lyrics");
        }

        function showTimeCapsule() {
            showRestingCapsule("normal");
        }

        function showStopwatch() {
            root.stopwatchMounted = true;
            clearTransientCapsule();
            islandState = "stopwatch";
            swipeTransitionProgress = 0;
            autoHideTimer.interval = 10000;
            autoHideTimer.restart();
        }

        function showTimer() {
            root.timerMounted = true;
            clearTransientCapsule();
            islandState = "timer";
            swipeTransitionProgress = 0;
            autoHideTimer.interval = 10000;
            autoHideTimer.restart();
        }

        function showPomodoro() {
            clearTransientCapsule();
            islandState = "pomodoro";
            swipeTransitionProgress = 0;
            autoHideTimer.interval = 10000;
            autoHideTimer.restart();
        }

        function showWorkspaceCapsule(wsId) {
            currentWs = wsId;
            if (islandState === "control_center" || islandState === "notification")
                return ;

            const animateFromSide = currentTransientOriginSide();
            clearTransientCapsule();
            sideTransientRestoreTimer.stop();
            workspaceOriginSide = animateFromSide;
            splitOriginSide = "none";
            islandState = "long_capsule";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        function brightnessStatusIcon(value) {
            if (value < 0.3)
                return userConfig.statusIcons["brightnessLow"];

            if (value < 0.7)
                return userConfig.statusIcons["brightnessMedium"];

            return userConfig.statusIcons["brightnessHigh"];
        }

        function syncCustomCapsuleWidth() {
            const view = customSwipeLoader.item;
            if (!view)
                return ;

            customCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        function syncLyricsCapsuleWidth() {
            const view = lyricsSwipeLoader.item;
            if (!view)
                return ;

            lyricsCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        // --- MPRIS 音乐控制逻辑 ---
        function formatTime(val) {
            let num = Number(val);
            if (isNaN(num) || num <= 0)
                return "0:00";

            let totalSeconds = 0;
            if (num < 10000)
                totalSeconds = Math.floor(num);
            else if (num < 1e+08)
                totalSeconds = Math.floor(num / 1000);
            else
                totalSeconds = Math.floor(num / 1e+06);
            let m = Math.floor(totalSeconds / 60);
            let s = Math.floor(totalSeconds % 60);
            return m + ":" + (s < 10 ? "0" : "") + s;
        }

        function cleanLyricLineText(text) {
            return String(text === undefined || text === null ? "" : text).replace(/\s+/g, " ").trim();
        }

        function parsePlainLyrics(rawLyrics) {
            const source = String(rawLyrics === undefined || rawLyrics === null ? "" : rawLyrics);
            const rows = source.split(/\r?\n/);
            const parsed = [];
            for (let i = 0; i < rows.length; i++) {
                const row = rows[i].trim();
                if (row === "")
                    continue;

                if (/^\[[a-zA-Z]+:.*\]$/.test(row))
                    continue;

                const lineText = cleanLyricLineText(row.replace(/\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g, ""));
                if (lineText !== "")
                    parsed.push(lineText);

            }
            return parsed;
        }

        function cleanNotificationText(text) {
            return String(text === undefined || text === null ? "" : text).replace(/<[^>]*>/g, " ").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&quot;/g, "\"").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/\s+/g, " ").trim();
        }

        function playerHasTrackInfo(player) {
            if (!player)
                return false;

            if ((player.trackTitle || player.title || "") !== "")
                return true;

            if (!player.metadata)
                return false;

            return Boolean(player.metadata["xesam:title"] || player.metadata["mpris:trackid"] || player.metadata["xesam:url"]);
        }

        function findPlayerByDbusName(dbusName) {
            if (!playersList || !dbusName)
                return null;

            for (let i = 0; i < playersList.length; i++) {
                if (playersList[i].dbusName === dbusName)
                    return playersList[i];

            }
            return null;
        }

        function resolveActivePlayer() {
            if (!playersList || playersList.length === 0)
                return null;

            if (userSelectedPlayer && manuallySelectedPlayerDbusName !== "") {
                const manual = findPlayerByDbusName(manuallySelectedPlayerDbusName);
                if (manual)
                    return manual;
                else
                    userSelectedPlayer = false;
            }

            for (let i = 0; i < playersList.length; i++) {
                if (playersList[i].playbackState === MprisPlaybackState.Playing)
                    return playersList[i];

            }
            const rememberedPlayer = findPlayerByDbusName(lastActivePlayerDbusName);
            if (rememberedPlayer && (playerHasTrackInfo(rememberedPlayer) || rememberedPlayer.canControl))
                return rememberedPlayer;

            for (let i = 0; i < playersList.length; i++) {
                if (playersList[i].playbackState === MprisPlaybackState.Paused && playerHasTrackInfo(playersList[i]))
                    return playersList[i];

            }
            for (let i = 0; i < playersList.length; i++) {
                if (playersList[i].canControl)
                    return playersList[i];

            }
            return playersList[0];
        }

        function cycleActivePlayer() {
            if (!playersList || playersList.length <= 1)
                return;

            let currentIndex = -1;
            const current = activePlayer;
            if (current) {
                for (let i = 0; i < playersList.length; i++) {
                    if (playersList[i].dbusName === current.dbusName) {
                        currentIndex = i;
                        break;
                    }
                }
            }

            let nextIndex = (currentIndex + 1) % playersList.length;
            const next = playersList[nextIndex];
            if (next) {
                userSelectedPlayer = true;
                manuallySelectedPlayerDbusName = next.dbusName;
                _refreshActivePlayer();
            }
        }

        function _refreshActivePlayer() {
            const next = resolveActivePlayer();
            if (next !== activePlayer) {
                if (next && next.dbusName)
                    lastActivePlayerDbusName = next.dbusName;
                else if (!next)
                    lastActivePlayerDbusName = "";
                activePlayer = next;
            }
        }

        anchors.fill: parent
        focus: root.monitorFocused && (root.overviewVisible || root.connectivityPromptActive)
        onControlCenterLayerVisibleChanged: {
            if (!controlCenterLayerVisible) {
                if (controlCenterLoader.item)
                    controlCenterLoader.item.closeConnectivityPanels();
                else
                    root.closeAllConnectivityDetails();
            }
        }
        onCustomLeftItemsChanged: {
            if (restingState === "custom" && !hasCustomLeftItems) {
                restingState = "normal";
                if (islandState === "custom" || (islandState === "split" && splitOriginSide === "left") || (islandState === "long_capsule" && workspaceOriginSide === "left"))
                    restoreRestingCapsule(true);
                else
                    applyRestingVisuals();
            } else if (restingState === "custom") {
                syncCustomCapsuleWidth();
            }
        }
        Keys.onPressed: (event) => {
            if (!root.overviewVisible)
                return ;

            if (userConfig.overviewCloseKey && event.key === userConfig.overviewCloseKey) {
                root.closeOverviewEverywhere();
                event.accepted = true;
            } else if (userConfig.overviewPreviousWorkspaceKey && event.key === userConfig.overviewPreviousWorkspaceKey) {
                Hyprland.dispatch("workspace r-1");
                event.accepted = true;
            } else if (userConfig.overviewNextWorkspaceKey && event.key === userConfig.overviewNextWorkspaceKey) {
                Hyprland.dispatch("workspace r+1");
                event.accepted = true;
            }
        }
        Component.onCompleted: refreshMissingLeftSwipeValues()
        onPlayersListChanged: _refreshActivePlayer()
        onCurrentTrackChanged: {
            userSwipedAwayFromLyrics = false;
            if (currentTrack !== "" && islandState !== "control_center" && islandState !== "notification") {
                if (islandState === "expanded" && !expandedByPlayerAutoOpen) {
                    updateRestingStateForLyrics();
                    return ;
                }

                showExpandedPlayer(true);
            }
            updateRestingStateForLyrics();
        }

        property string lastCheckedTrack: ""
        property string preTempRestingState: ""
        property bool isTempShowingTime: false
        property bool userSwipedAwayFromLyrics: false

        Timer {
            id: tempShowTimeSafetyTimer
            interval: 1000
            onTriggered: {
                console.log("[DynamicIsland] tempShowTimeSafetyTimer triggered - auto-restoring");
                islandContainer.restoreFromTempShowTime();
            }
        }

        function tempShowTime() {
            console.log("[DynamicIsland] tempShowTime() called - currently showing time:", isTempShowingTime, "preTempRestingState:", preTempRestingState);
            if (isTempShowingTime) {
                tempShowTimeSafetyTimer.restart();
                return;
            }
            isTempShowingTime = true;
            preTempRestingState = restingState;

            setRestingState("normal");
            showTimeCapsule();
            tempShowTimeSafetyTimer.start();
        }

        function restoreFromTempShowTime() {
            console.log("[DynamicIsland] restoreFromTempShowTime() called - currently showing time:", isTempShowingTime, "preTempRestingState:", preTempRestingState);
            tempShowTimeSafetyTimer.stop();
            if (!isTempShowingTime) return;
            isTempShowingTime = false;

            setRestingState(preTempRestingState);
            if (preTempRestingState === "lyrics") {
                showLyricsCapsule();
            } else if (preTempRestingState === "custom") {
                showCustomCapsule();
            } else {
                showTimeCapsule();
            }
        }



        function updateRestingStateForLyrics() {
            if (currentTrack === "" || currentTrack === "Unknown") {
                lastCheckedTrack = "";
                if (isTempShowingTime) {
                    preTempRestingState = "normal";
                } else {
                    setRestingState("normal");
                    if (islandState === "lyrics") {
                        showTimeCapsule();
                    }
                }
                return;
            }

            let hasLyrics = false;
            if (lyricsBridge.backendStatus === "missing" || lyricsBridge.backendStatus === "error") {
                hasLyrics = false;
            } else if (lyricsBridge.isSynced || lyricsBridge.plainLyric !== "" || lyricsBridge.currentLyric !== "" || inlineLyricsRaw !== "") {
                hasLyrics = true;
            } else {
                if (lyricsBridge.backendStatus === "starting" || lyricsBridge.backendStatus === "idle") {
                    return;
                }
            }

            lastCheckedTrack = currentTrack;

            let targetState = hasLyrics ? "lyrics" : "normal";
            if (isTempShowingTime) {
                preTempRestingState = targetState;
            } else {
                if (hasLyrics) {
                    if (!userSwipedAwayFromLyrics) {
                        setRestingState("lyrics");
                        if (islandState === "normal") {
                            showLyricsCapsule();
                        }
                    }
                } else {
                    setRestingState("normal");
                    if (islandState === "lyrics") {
                        showTimeCapsule();
                    }
                }
            }
        }

        function handlePlayStateTriggered() {
            if (currentTrack === "" || currentTrack === "Unknown") {
                return;
            }
            updateRestingStateForLyrics();
        }

        Connections {
            target: lyricsBridge

            function onBackendStatusChanged() {
                islandContainer.updateRestingStateForLyrics();
            }

            function onIsSyncedChanged() {
                islandContainer.updateRestingStateForLyrics();
            }

            function onPlainLyricChanged() {
                islandContainer.updateRestingStateForLyrics();
            }

            function onCurrentLyricChanged() {
                islandContainer.updateRestingStateForLyrics();
            }
        }


        Instantiator {
            model: islandContainer.playersList

            delegate: Connections {
                function onPlaybackStateChanged() {
                    islandContainer._refreshActivePlayer();
                    if (target === islandContainer.activePlayer) {
                        if (target.playbackState === MprisPlaybackState.Playing) {
                            islandContainer.handlePlayStateTriggered();
                        } else {
                            if (islandContainer.isTempShowingTime) {
                                islandContainer.preTempRestingState = "normal";
                            } else {
                                if (islandContainer.restingState === "lyrics") {
                                    islandContainer.showTimeCapsule();
                                }
                            }
                        }
                    }
                }

                function onMetadataChanged() {
                    islandContainer._refreshActivePlayer();
                }

                target: modelData
            }

        }

        Timer {
            id: autoHideTimer

            interval: islandContainer.defaultAutoHideInterval
            onTriggered: {
                islandContainer.smartRestoreState();
                root.setCalendarVisible(false);
            }
        }

        Timer {
            id: lyricsPauseTimer

            interval: 0
            running: islandContainer.restingState === "lyrics" && islandContainer.activePlayer !== null && islandContainer.activePlayer.playbackState === MprisPlaybackState.Paused
            repeat: false
            onTriggered: {
                islandContainer.showTimeCapsule();
            }
        }

        Timer {
            id: osdProgressAnimationReset

            interval: 0
            onTriggered: islandContainer.osdProgressAnimationEnabled = true
        }

        Timer {
            id: sideTransientRestoreTimer

            interval: islandContainer.swipeAnimationDuration
            onTriggered: {
                islandContainer.workspaceOriginSide = "none";
                islandContainer.splitOriginSide = "none";
                islandContainer.prepareRestingCapsuleGeometry();
                islandContainer.islandState = islandContainer.normalizeRestingState(islandContainer.restingState);
                islandContainer.clearTransientCapsule();
                islandContainer.applyRestingVisuals();
                islandContainer.expandedByPlayerAutoOpen = false;
            }
        }

        Timer {
            id: sideSwipeSettleReset

            interval: mainCapsule.morphDuration
            onTriggered: islandContainer.finishSideSwipeSettle()
        }

        Process {
            id: brightnessSnapshot

            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: islandContainer.applyBrightnessOutput(text)
            }

        }

        Process {
            id: volumeSnapshot

            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: islandContainer.applyVolumeOutput(text)
            }

        }

        Process {
            id: systemStatsSnapshot

            command: ["sh", "-lc", "awk 'NR == 1 { print \"cpu\", $2, $3, $4, $5, $6, $7, $8, $9, $10 } $1 == \"MemTotal:\" { total = $2 } $1 == \"MemAvailable:\" { available = $2 } END { print \"mem\", total, available }' /proc/stat /proc/meminfo; df -kP / | awk 'NR==2 {print \"disk\", $2, $4}'; cat /sys/class/hwmon/hwmon6/temp1_input 2>/dev/null | awk '{print \"temp\", $1/1000}'; cat /proc/loadavg | awk '{print \"proc\", $4}'; cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | awk '{sum+=$1; count++} END {if (count > 0) { printf \"freq %.2f\\n\", sum/count/1000000 } else { exit 1 }}' || awk '/cpu MHz/ {sum+=$4; count++} END {if (count > 0) printf \"freq %.2f\\n\", sum/count/1000}' /proc/cpuinfo"]

            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: islandContainer.applySystemStatsOutput(text)
            }

        }

        Timer {
            id: systemStatsPollTimer

            interval: islandContainer.customStatsHovered ? 1000 : 3000
            repeat: true
            running: islandContainer.usesSystemStatsModule && customSwipeLoader.active
            triggeredOnStart: true
            onTriggered: {
                if (!systemStatsSnapshot.running)
                    systemStatsSnapshot.exec(systemStatsSnapshot.command);

            }
        }

        Timer {
            id: cavaRestartTimer

            interval: 1200
            repeat: false
            onTriggered: {
                if (islandContainer.usesCavaModule && customSwipeLoader.active)
                    cavaMonitor.running = true;

            }
        }

        Process {
            id: cavaMonitor

            running: islandContainer.usesCavaModule && customSwipeLoader.active
            command: ["sh", "-lc", "exec cava -p /dev/stdin <<'EOF'\n[general]\nframerate = 60\nbars = 8\nautosens = 1\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 7\nchannels = mono\nEOF"]
            onExited: {
                if (islandContainer.usesCavaModule && customSwipeLoader.active)
                    cavaRestartTimer.restart();

            }

            stdout: SplitParser {
                splitMarker: "\n"
                onRead: function(data) {
                    islandContainer.applyCavaOutput(data);
                }
            }

        }

        Timer {
            id: btBlockVolTimer

            interval: 2000
            onTriggered: islandContainer.btJustConnected = false
        }

        Timer {
            id: volDebounce

            interval: 16
            onTriggered: {
                if (islandContainer.btJustConnected)
                    return ;

                if (islandContainer._pendingVolType !== islandContainer._lastVolType || Math.abs(islandContainer._pendingVolVal - islandContainer._lastVolVal) > 0.001) {
                    islandContainer._lastVolType = islandContainer._pendingVolType;
                    islandContainer._lastVolVal = islandContainer._pendingVolVal;
                    islandContainer.showTransientCapsule(islandContainer._pendingVolType === "MUTE" ? userConfig.statusIcons["mute"] : userConfig.statusIcons["volume"], islandContainer._pendingVolVal, "");
                }
            }
        }

        Timer {
            id: blDebounce

            interval: 16
            onTriggered: {
                islandContainer.showTransientCapsule(islandContainer.brightnessStatusIcon(islandContainer._pendingBlVal), islandContainer._pendingBlVal, "");
            }
        }

        Connections {
            function onVolumeChanged(volPercentage, isMuted) {
                islandContainer._pendingVolType = isMuted ? "MUTE" : "VOL";
                islandContainer._pendingVolVal = volPercentage / 100;
                islandContainer.currentVolume = volPercentage / 100;
                islandContainer.isMuted = isMuted;
                volDebounce.restart();
            }

            function onBatteryChanged(capacity, statusString) {
                islandContainer.batteryCapacity = capacity;
                islandContainer.isCharging = (statusString === "Charging" || statusString === "Full");
                if (islandContainer._lastChargeStatus !== "" && islandContainer._lastChargeStatus !== statusString) {
                    if (statusString === "Charging")
                        islandContainer.showTransientCapsule(userConfig.statusIcons["charging"]);
                    else if (statusString === "Discharging")
                        islandContainer.showTransientCapsule(userConfig.statusIcons["discharging"]);
                }
                islandContainer._lastChargeStatus = statusString;
            }

            function onBrightnessChanged(val) {
                islandContainer._pendingBlVal = val;
                islandContainer.currentBrightness = val;
                blDebounce.restart();
            }

            function onCapsLockChanged(isOn) {
                islandContainer.showTransientCapsule(isOn ? userConfig.statusIcons["capsLockOn"] : userConfig.statusIcons["capsLockOff"], -1, isOn ? "Caps Lock ON" : "Caps Lock OFF");
            }

            function onBluetoothChanged(isConnected) {
                islandContainer.btJustConnected = true;
                btBlockVolTimer.restart();
                islandContainer.showTransientCapsule(userConfig.statusIcons["bluetooth"], -1, isConnected ? "Connected" : "Disconnected");
            }

            target: SysBackend
        }

        Connections {
            function onRawEvent(event) {
                root.handleWorkspaceEvent(event);
            }

            target: Hyprland
        }

        Connections {
            function onActiveWorkspaceChanged() {
                root.syncWorkspaceState();
            }

            target: root.hyprMonitor
        }

        QtObject {
            id: notificationBridge

            property bool captureActive: false
            property int captureStage: -1
            property string pendingAppName: ""
            property string pendingSummary: ""
            property string pendingBody: ""

            function resetCapture() {
                captureActive = false;
                captureStage = -1;
                pendingAppName = "";
                pendingSummary = "";
                pendingBody = "";
            }

            function beginCapture() {
                resetCapture();
                captureActive = true;
                captureStage = 0;
            }

            function decodeMonitorString(line) {
                const match = line.match(/^\s*string "(.*)"\s*$/);
                if (!match)
                    return "";

                try {
                    return JSON.parse("\"" + match[1] + "\"");
                } catch (error) {
                    return match[1].replace(/\\"/g, "\"").replace(/\\\\/g, "\\");
                }
            }

            function commitCapture() {
                islandContainer.showNotificationCapsule(pendingAppName, pendingSummary, pendingBody);
                resetCapture();
            }

            function handleLine(rawLine) {
                const line = String(rawLine === undefined || rawLine === null ? "" : rawLine).trim();
                if (line === "")
                    return ;

                if (line.indexOf("member=Notify") !== -1) {
                    beginCapture();
                    return ;
                }
                if (!captureActive)
                    return ;

                switch (captureStage) {
                case 0:
                    if (!line.startsWith("string "))
                        return ;

                    pendingAppName = decodeMonitorString(line);
                    captureStage = 1;
                    return ;
                case 1:
                    if (!line.startsWith("uint32 "))
                        return ;

                    captureStage = 2;
                    return ;
                case 2:
                    if (!line.startsWith("string "))
                        return ;

                    captureStage = 3;
                    return ;
                case 3:
                    if (!line.startsWith("string "))
                        return ;

                    pendingSummary = decodeMonitorString(line);
                    captureStage = 4;
                    return ;
                case 4:
                    if (!line.startsWith("string "))
                        return ;

                    pendingBody = decodeMonitorString(line);
                    commitCapture();
                    return ;
                default:
                    resetCapture();
                }
            }

        }

        Timer {
            id: notificationMonitorRestartTimer

            interval: 1200
            repeat: false
            onTriggered: notificationMonitor.running = true
        }

        Process {
            id: notificationMonitor

            running: true
            command: ["dbus-monitor", "--session", "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"]
            onExited: notificationMonitorRestartTimer.restart()

            stdout: SplitParser {
                splitMarker: "\n"
                onRead: function(data) {
                    notificationBridge.handleLine(data);
                }
            }

        }

        QtObject {
            id: lyricsBridge

            readonly property string title: islandContainer.currentTrack
            readonly property string artist: islandContainer.currentArtist
            readonly property string currentLyric: SysBackend && SysBackend.lyricsCurrentLyric !== undefined ? SysBackend.lyricsCurrentLyric : ""
            readonly property bool isSynced: SysBackend && SysBackend.lyricsIsSynced !== undefined ? SysBackend.lyricsIsSynced : false
            readonly property string backendStatus: SysBackend && SysBackend.lyricsBackendStatus !== undefined ? SysBackend.lyricsBackendStatus : "idle"
            readonly property var plainLines: islandContainer.parsePlainLyrics(islandContainer.inlineLyricsRaw)
            readonly property string plainLyric: plainLines.length > 0 ? plainLines[0] : ""
            readonly property string displayText: {
                if (title === "")
                    return "No music playing";

                if (backendStatus === "missing" || backendStatus === "error")
                    return "no lyrics";

                if (isSynced && currentLyric !== "")
                    return currentLyric;

                if (plainLyric !== "")
                    return plainLyric;

                return artist !== "" && artist !== "Unknown" ? title + " - " + artist : title;
            }
        }

        Timer {
            id: progressPoller

            interval: 500
            running: islandContainer.activePlayer !== null && islandContainer.islandState === "expanded"
            repeat: true
            onTriggered: {
                let player = islandContainer.activePlayer;
                if (!player)
                    return ;

                let currentPos = Number(player.position) || 0;
                let totalLen = Number(player.length) || 0;
                if (totalLen <= 0 && player.metadata && player.metadata["mpris:length"])
                    totalLen = Number(player.metadata["mpris:length"]);

                if (totalLen > 0) {
                    islandContainer.trackProgress = currentPos / totalLen;
                    islandContainer.timePlayed = islandContainer.formatTime(currentPos);
                    islandContainer.timeTotal = islandContainer.formatTime(totalLen);
                } else {
                    islandContainer.trackProgress = 0;
                    islandContainer.timePlayed = islandContainer.formatTime(currentPos);
                    islandContainer.timeTotal = "0:00";
                }
            }
        }

        // Background dismiss area to collapse dynamic island on click outside
        MouseArea {
            id: dismissArea

            anchors.fill: parent
            z: -10
            enabled: root.anyPopupOpen
            onPressed: {
                root.collapseAll();
            }
        }

        // --- UI 渲染：灵动岛主干 ---
        Rectangle {
            id: mainCapsule

            property int morphDuration: 400
            property real outlineWidth: root.overviewContentVisible ? 1 : 0
            property color outlineColor: root.overviewContentVisible ? root.overviewCapsuleBorderColor : "#00000000"
            property real displayedWidth: baseTargetWidth
            readonly property real baseTargetWidth: {
                if (root.overviewVisible)
                    return root.overviewCapsuleWidth;

                if (sideTransientRestoreTimer.running) {
                    if (islandContainer.restingState === "lyrics" && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "right") || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "right")))
                        return islandContainer.lyricsCapsuleWidth;

                    if (islandContainer.restingState === "aiprompt" && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "right") || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "right")))
                        return 420;

                    if (islandContainer.restingState === "custom" && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "left") || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "left")))
                        return islandContainer.customCapsuleWidth;

                }
                switch (islandContainer.islandState) {
                case "split":
                    return islandContainer.splitCapsuleWidth;
                case "long_capsule":
                    return 220;
                case "custom":
                    return islandContainer.customStatsHovered ? 340 : islandContainer.customCapsuleWidth;
                case "aiprompt":
                    return 420;
                case "clipboard":
                    return 360;
                case "volume_mixer":
                    return 360;
                case "lyrics":
                    return islandContainer.lyricsCapsuleWidth;
                case "stopwatch":
                    return 368;
                case "timer":
                    return 368;
                case "pomodoro":
                    return 340;
                case "control_center":
                    return 420;
                case "expanded":
                    return 400;
                case "notification":
                    if (!notificationLoader.item)
                        return 272;

                    return Math.max(notificationLoader.item.minimumWidth, Math.min(notificationLoader.item.maximumWidth, notificationLoader.item.preferredWidth));
                default:
                    return root.normalPillWidth;
                }
            }
            readonly property real targetHeight: {
                if (root.overviewVisible)
                    return root.overviewCapsuleHeight;



                switch (islandContainer.islandState) {
                case "control_center":
                    return 390;
                case "stopwatch":
                    return 126;
                case "timer":
                    return 142;
                case "pomodoro":
                    return 114;
                case "expanded":
                    return 165;
                case "aiprompt":
                    return 340;
                case "clipboard":
                    return 300;
                case "volume_mixer":
                    return 260;
                case "custom":
                    return islandContainer.customStatsHovered ? 130 : 38;
                case "notification":
                    return notificationLoader.item ? Math.max(56, Math.min(68, notificationLoader.item.preferredHeight)) : 56;
                default:
                    return 38;
                }
            }
            readonly property real targetRadius: {
                if (root.overviewVisible)
                    return root.overviewCapsuleRadius;



                switch (islandContainer.islandState) {
                case "control_center":
                    return 34;
                case "expanded":
                    return 40;
                case "aiprompt":
                    return 24;
                case "clipboard":
                    return 24;
                case "volume_mixer":
                    return 24;
                case "custom":
                    return islandContainer.customStatsHovered ? 24 : 19;
                case "notification":
                    return mainCapsule.targetHeight / 2;
                default:
                    return 19;
                }
            }
            readonly property real sideSwipePreviewWidth: mainCapsule.sideSwipeWidthForProgress(islandContainer.swipeTransitionProgress)

            function sideSwipeWidthForProgress(progressValue) {
                if (progressValue < 0)
                    return root.normalPillWidth + (islandContainer.customCapsuleWidth - root.normalPillWidth) * islandContainer.clamp01(-progressValue);

                if (progressValue > 0) {
                    return root.normalPillWidth + (islandContainer.lyricsCapsuleWidth - root.normalPillWidth) * (progressValue / 2.0);
                }

                return root.normalPillWidth;
            }

            z: 5
            visible: !root.shouldHideClockPill
            color: root.overviewContentVisible ? root.overviewCapsuleColor : "black"
            y: 4
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true
            width: displayedWidth
            height: targetHeight
            radius: targetRadius
            onBaseTargetWidthChanged: {
                if (!capsuleMouseArea.sideSwipeInteractive && !islandContainer.sideSwipeSettling)
                    displayedWidth = baseTargetWidth;

            }
            border.width: outlineWidth
            border.color: outlineColor

            HoverHandler {
                id: capsuleHoverHandler
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(parent.radius - 1, 0)
                color: "transparent"
                border.width: 1
                border.color: "#12ffffff"
                opacity: root.overviewContentVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.overviewContentVisible ? 260 : 140
                        easing.type: Easing.InOutQuad
                    }

                }

            }

            MouseArea {
                id: capsuleMouseArea

                property real swipeStartX: 0
                property real swipeStartY: 0
                property real swipeStartProgress: 0
                property real swipeLastX: 0
                readonly property real sideSwipeVerticalTolerance: 24
                property bool swipeArmed: false
                property bool swipeMoved: false
                property bool sideSwipeInteractive: false
                property bool suppressNextClick: false
                property bool preparedOverviewOnPress: false
                // Delays primary-button single-click action by a short window so
                // a double-click can intercept it and open the calendar instead.
                property string _pendingClickKind: ""
                // "primary" | "secondary" | ""
                property var lastClickTime: 0

                anchors.fill: parent
                z: -1
                enabled: !root.overviewVisible
                acceptedButtons: root.dynamicIslandAcceptedButtons
                preventStealing: true
                onWheel: (wheel) => {
                    // Vertical swipe: up=stopwatch, down=timer (always available)
                    let deltaY = 0;
                    if (Math.abs(wheel.pixelDelta.y) > 0)
                        deltaY = wheel.pixelDelta.y;
                    else if (Math.abs(wheel.angleDelta.y) > 0)
                        deltaY = wheel.angleDelta.y / 3;
                    let deltaX = 0;
                    if (Math.abs(wheel.pixelDelta.x) > 0)
                        deltaX = wheel.pixelDelta.x;
                    else if (Math.abs(wheel.angleDelta.x) > 0)
                        deltaX = wheel.angleDelta.x / 3;
                    if (Math.abs(deltaY) > 2 && Math.abs(deltaY) >= Math.abs(deltaX)) {
                        if (deltaY < -2)
                            islandContainer.showStopwatch();
                        else if (deltaY > 2)
                            islandContainer.showTimer();
                        wheel.accepted = true;
                        return ;
                    }
                    if (!islandContainer.canShowSideSwipe) {
                        wheel.accepted = false;
                        return ;
                    }
                    if (Math.abs(deltaX) > 0) {
                        if (!wheelReleaseTimer.running) {
                            swipeStartProgress = islandContainer.swipeTransitionProgress;
                            sideSwipeInteractive = true;
                            islandContainer.cancelSideSwipeSettle();
                        }
                        wheelReleaseTimer.restart();
                        const nextProgress = islandContainer.advanceSideSwipeProgress(islandContainer.swipeTransitionProgress, deltaX * 2);
                        islandContainer.swipeTransitionProgress = nextProgress;
                        mainCapsule.displayedWidth = mainCapsule.sideSwipePreviewWidth;
                        wheel.accepted = true;
                    } else {
                        wheel.accepted = false;
                    }
                }
                onPressed: (mouse) => {
                    const mappedPoint = capsuleMouseArea.mapToItem(islandContainer, mouse.x, mouse.y);
                    swipeStartX = mappedPoint.x;
                    swipeStartY = mappedPoint.y;
                    islandContainer.cancelSideSwipeSettle();
                    swipeArmed = mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSwipeButton) && islandContainer.canShowSideSwipe;
                    swipeStartProgress = islandContainer.swipeTransitionProgress;
                    swipeLastX = mappedPoint.x;
                    swipeMoved = false;
                    sideSwipeInteractive = swipeArmed;
                    islandContainer.swipeTransitionProgress = swipeStartProgress;
                    let pressedAction = "";
                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton))
                        pressedAction = userConfig.dynamicIslandPrimaryAction;
                    else if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton))
                        pressedAction = userConfig.dynamicIslandSecondaryAction;
                    preparedOverviewOnPress = pressedAction === "openOverview" || (pressedAction === "toggleOverview" && root.overviewPhase === "closed");
                    if (preparedOverviewOnPress)
                        root.prepareOverviewEverywhere();

                }
                onPositionChanged: (mouse) => {
                    if (!pressed || !swipeArmed || suppressNextClick)
                        return ;

                    const mappedPoint = capsuleMouseArea.mapToItem(islandContainer, mouse.x, mouse.y);
                    const deltaX = mappedPoint.x - swipeLastX;
                    const deltaY = Math.abs(mappedPoint.y - swipeStartY);
                    const adjustedDeltaX = deltaY < sideSwipeVerticalTolerance ? deltaX : 0;
                    const nextProgress = islandContainer.advanceSideSwipeProgress(islandContainer.swipeTransitionProgress, adjustedDeltaX);
                    swipeMoved = swipeMoved || Math.abs(nextProgress - swipeStartProgress) > 0.03 || deltaY > 6;
                    swipeLastX = mappedPoint.x;
                    islandContainer.swipeTransitionProgress = nextProgress;
                    mainCapsule.displayedWidth = mainCapsule.sideSwipePreviewWidth;
                }
                onReleased: {
                    if (swipeMoved) {
                        if (preparedOverviewOnPress)
                            root.cancelPreparedOverviewEverywhere();

                        preparedOverviewOnPress = false;
                        suppressNextClick = true;
                        swipeSuppressReset.restart();
                    }
                    let settleResult = {
                        "action": "",
                        "progress": islandContainer.sideSwipeRestProgressForProgress(swipeStartProgress),
                        "width": islandContainer.sideSwipeRestWidthForProgress(swipeStartProgress)
                    };
                    if (swipeArmed)
                        settleResult = islandContainer.resolveSideSwipeSettle(swipeStartProgress, islandContainer.swipeTransitionProgress);

                    sideSwipeInteractive = false;
                    if (swipeArmed)
                        islandContainer.beginSideSwipeSettle(settleResult.width);
                    else
                        mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
                    if (swipeArmed) {
                        switch (settleResult.action) {
                        case "time":
                            islandContainer.userSwipedAwayFromLyrics = true;
                            islandContainer.showTimeCapsule();
                            break;
                        case "custom":
                            islandContainer.userSwipedAwayFromLyrics = true;
                            islandContainer.showCustomCapsule();
                            break;
                        case "aiprompt":
                            islandContainer.userSwipedAwayFromLyrics = true;
                            islandContainer.showAiPrompt();
                            break;
                        case "lyrics":
                            islandContainer.userSwipedAwayFromLyrics = false;
                            islandContainer.showLyricsCapsule();
                            break;
                        default:
                            islandContainer.swipeTransitionProgress = settleResult.progress;
                        }
                    } else {
                        islandContainer.swipeTransitionProgress = settleResult.progress;
                    }
                    swipeArmed = false;
                    swipeMoved = false;
                }
                onCanceled: {
                    if (preparedOverviewOnPress)
                        root.cancelPreparedOverviewEverywhere();

                    swipeArmed = false;
                    swipeMoved = false;
                    sideSwipeInteractive = false;
                    suppressNextClick = false;
                    preparedOverviewOnPress = false;
                    swipeSuppressReset.stop();
                    mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
                    islandContainer.swipeTransitionProgress = islandContainer.swipeRestProgressForState();
                }
                onClicked: (mouse) => {
                    if (suppressNextClick) {
                        swipeSuppressReset.stop();
                        suppressNextClick = false;
                        preparedOverviewOnPress = false;
                        return ;
                    }
                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)) {
                        preparedOverviewOnPress = false;
                        let currentTime = Date.now();
                        if (currentTime - lastClickTime < 300) {
                            // Double click!
                            singleClickDelayTimer.stop();
                            _pendingClickKind = "";
                            lastClickTime = 0;
                            if (preparedOverviewOnPress) {
                                root.cancelPreparedOverviewEverywhere();
                                preparedOverviewOnPress = false;
                            }
                            const blockingStates = ["stopwatch", "timer", "pomodoro", "aiprompt", "clipboard", "volume_mixer"];
                            if (blockingStates.indexOf(islandContainer.islandState) === -1)
                                islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandPrimaryAction);

                        } else {
                            // First click of potential double click (single-click action: calendar)
                            lastClickTime = currentTime;
                            _pendingClickKind = "calendar";
                            singleClickDelayTimer.restart();
                        }
                        return ;
                    }
                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton)) {
                        preparedOverviewOnPress = false;
                        islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandSecondaryAction);
                    }
                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandMiddleButton)) {
                        preparedOverviewOnPress = false;
                        islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandMiddleAction);
                    }
                }

                Timer {
                    id: swipeSuppressReset

                    interval: 180
                    repeat: false
                    onTriggered: capsuleMouseArea.suppressNextClick = false
                }

                Timer {
                    id: wheelReleaseTimer

                    interval: 200
                    onTriggered: {
                        if (!capsuleMouseArea.sideSwipeInteractive)
                            return ;

                        let settleResult = islandContainer.resolveSideSwipeSettle(capsuleMouseArea.swipeStartProgress, islandContainer.swipeTransitionProgress);
                        capsuleMouseArea.sideSwipeInteractive = false;
                        islandContainer.beginSideSwipeSettle(settleResult.width);
                        switch (settleResult.action) {
                        case "time":
                            islandContainer.userSwipedAwayFromLyrics = true;
                            islandContainer.showTimeCapsule();
                            break;
                        case "custom":
                            islandContainer.userSwipedAwayFromLyrics = true;
                            islandContainer.showCustomCapsule();
                            break;
                        case "aiprompt":
                            islandContainer.userSwipedAwayFromLyrics = true;
                            islandContainer.showAiPrompt();
                            break;
                        case "lyrics":
                            islandContainer.userSwipedAwayFromLyrics = false;
                            islandContainer.showLyricsCapsule();
                            break;
                        default:
                            islandContainer.swipeTransitionProgress = settleResult.progress;
                        }
                    }
                }

                Timer {
                    id: singleClickDelayTimer

                    interval: 300 // comfortable double-click window
                    repeat: false
                    onTriggered: {
                        const kind = capsuleMouseArea._pendingClickKind;
                        capsuleMouseArea._pendingClickKind = "";
                        if (kind === "calendar") {
                            root.toggleCalendar();
                        } else if (kind === "primary") {
                            const blockingStates = ["stopwatch", "timer", "pomodoro", "aiprompt", "clipboard", "volume_mixer"];
                            if (blockingStates.indexOf(islandContainer.islandState) === -1)
                                islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandPrimaryAction);

                        } else if (kind === "secondary") {
                            islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandSecondaryAction);
                        }
                    }
                }

            }

            Loader {
                id: customSwipeLoader

                anchors.fill: parent
                active: islandContainer.customSwipeVisible
                asynchronous: false
                visible: active
                onLoaded: islandContainer.syncCustomCapsuleWidth()

                sourceComponent: Component {
                    SwipeCustomInfoLayer {
                        items: islandContainer.customLeftItems
                        cavaLevels: islandContainer.cavaLevels
                        timeText: timeObj.currentTime
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.heroFontFamily
                        timeFontFamily: root.heroFontFamily
                        persistentRingActive: root.persistentRingActive
                        bothRunning: root.bothRunning
                        minimumWidth: 220
                        maximumWidth: Math.max(220, root.width - 48)
                        transitionProgress: islandContainer.swipeTransitionProgress
                        showSecondaryText: islandContainer.workspaceOriginSide !== "left" && islandContainer.splitOriginSide !== "left"
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncCustomCapsuleWidth()

                        hovered: islandContainer.customStatsHovered
                        cpuUsage: islandContainer.currentCpuUsage
                        cpuTemp: islandContainer.currentCpuTemp
                        cpuFreq: islandContainer.currentCpuFreq
                        cpuProcesses: islandContainer.currentCpuProcesses
                        ramUsage: islandContainer.currentRamUsage
                        ramTotalGB: islandContainer.currentRamTotalGB
                        ramUsedGB: islandContainer.currentRamUsedGB
                        diskUsage: islandContainer.currentDiskUsage
                        diskTotalGB: islandContainer.currentDiskTotalGB
                        diskUsedGB: islandContainer.currentDiskUsedGB
                    }

                }

            }

            Loader {
                id: lyricsSwipeLoader

                anchors.fill: parent
                active: islandContainer.lyricsSwipeVisible
                asynchronous: false
                visible: active
                onLoaded: islandContainer.syncLyricsCapsuleWidth()

                sourceComponent: Component {
                    SwipeLyricsLayer {
                        lyricText: islandContainer.lyricsDisplayText
                        timeText: timeObj.currentTime
                        textFontFamily: root.textFontFamily
                        timeFontFamily: root.timeFontFamily
                        persistentRingActive: root.persistentRingActive
                        bothRunning: root.bothRunning
                        textPixelSize: 16
                        minimumWidth: 220
                        maximumWidth: Math.max(220, root.width - 48)
                        transitionProgress: islandContainer.swipeTransitionProgress
                        showSecondaryText: islandContainer.workspaceOriginSide !== "right" && islandContainer.splitOriginSide !== "right"
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncLyricsCapsuleWidth()
                    }

                }

            }

            Loader {
                id: splitIconLoader

                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.splitShowsIconOnly
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    SplitIconLayer {
                        iconText: islandContainer.splitIcon
                        iconFontFamily: root.iconFontFamily
                        transitionProgress: islandContainer.swipeTransitionProgress
                        slideDirection: islandContainer.splitOriginSide
                        showCondition: true
                    }

                }

            }

            Loader {
                id: osdLayerLoader

                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.splitUsesExtendedLayout
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    OsdLayer {
                        iconText: islandContainer.splitIcon
                        progress: islandContainer.osdProgress
                        customText: islandContainer.osdCustomText
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        transitionProgress: islandContainer.swipeTransitionProgress
                        slideDirection: islandContainer.splitOriginSide
                        showCondition: true
                    }

                }

            }

            Loader {
                id: workspaceLayerLoader

                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.islandState === "long_capsule" && (islandContainer.workspaceOriginSide !== "none" || Math.abs(islandContainer.swipeTransitionProgress) < 0.001)
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    WorkspaceLayer {
                        workspaceId: islandContainer.currentWs
                        displayText: "Workspace " + islandContainer.currentWs
                        textFontFamily: root.textFontFamily
                        textPixelSize: 16
                        animateVisibility: islandContainer.restingState === "normal"
                        transitionProgress: islandContainer.swipeTransitionProgress
                        showCondition: true
                        slideDirection: islandContainer.workspaceOriginSide
                    }

                }

            }

            Loader {
                id: expandedPlayerLoader

                anchors.fill: parent
                active: islandContainer.expandedLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    ExpandedPlayerLayer {
                        currentArtUrl: islandContainer.currentArtUrl
                        currentTrack: islandContainer.currentTrack
                        currentArtist: islandContainer.currentArtist
                        timePlayed: islandContainer.timePlayed
                        timeTotal: islandContainer.timeTotal
                        trackProgress: islandContainer.trackProgress
                        activePlayer: islandContainer.activePlayer
                        activePlayerName: islandContainer.activePlayerName
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.expandedLayerVisible
                        onControlPressed: {
                            islandContainer.suppressCapsuleClick();
                            if (!islandContainer.expandedByPlayerAutoOpen)
                                islandContainer.restartAutoHideTimer(10000);

                        }
                        onCyclePlayerRequested: {
                            islandContainer.cycleActivePlayer();
                        }
                    }

                }

            }

            Loader {
                id: notificationLoader

                anchors.fill: parent
                active: islandContainer.notificationLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    NotificationLayer {
                        appName: islandContainer.notificationAppName
                        summary: islandContainer.notificationSummary
                        body: islandContainer.notificationBody
                        iconText: userConfig.statusIcons["notification"]
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: true
                    }

                }

            }

            Loader {
                id: controlCenterLoader

                anchors.fill: parent
                active: islandContainer.controlCenterLayerVisible || root.anyConnectivityDetailMounted
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    ControlCenterLayer {
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        sliderIntroDelay: mainCapsule.morphDuration
                        currentTime: timeObj.currentTime
                        currentDateLabel: timeObj.currentDateLabel
                        batteryCapacity: islandContainer.batteryCapacity
                        isCharging: islandContainer.isCharging
                        volumeLevel: islandContainer.currentVolume
                        brightnessLevel: islandContainer.currentBrightness
                        currentWorkspace: islandContainer.currentWs
                        currentTrack: islandContainer.currentTrack
                        currentArtist: islandContainer.currentArtist
                        showCondition: islandContainer.controlCenterLayerVisible
                        onTodoToggle: function() {
                            if (root.shellRootController && root.shellRootController.toggleTodo)
                                root.shellRootController.toggleTodo();

                        }
                        onPomodoroToggle: function() {
                            if (pomodoroLoader.item)
                                pomodoroLoader.item.toggle();

                        }
                        onClipboardToggle: function() {
                            root.toggleClipboard();
                        }
                        onVolumeMixerToggle: function() {
                            root.toggleVolumeMixer();
                        }
                        onConnectivityPanelRequested: function(kind, open) {
                            root.setConnectivityDetailVisible(kind, open);
                        }
                    }

                }

            }



            Loader {
                id: clipboardLoader

                anchors.fill: parent
                active: islandContainer.clipboardLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    ClipboardLayer {
                        showCondition: islandContainer.clipboardLayerVisible
                        textFontFamily: root.textFontFamily
                    }
                }
            }

            Loader {
                id: volumeMixerLoader

                anchors.fill: parent
                active: islandContainer.volumeMixerLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    VolumeMixerLayer {
                        showCondition: islandContainer.volumeMixerLayerVisible
                        textFontFamily: root.textFontFamily
                    }
                }
            }

            Loader {
                id: overviewLoader

                anchors.fill: parent
                active: root.overviewLoaderActive
                asynchronous: false
                visible: root.overviewContentVisible
                onStatusChanged: {
                    if (status === Loader.Ready && root.overviewPreparing)
                        root.beginOverviewOpening();

                }

                sourceComponent: Component {
                    Item {
                        id: overviewScene

                        property alias overviewView: overviewView
                        property alias overviewDataReady: hyprlandData.ready

                        anchors.fill: parent

                        HyprlandData {
                            id: hyprlandData
                        }

                        WorkspaceOverviewLayer {
                            id: overviewView

                            anchors.centerIn: parent
                            screen: root.screen
                            hyprlandData: hyprlandData
                            showCondition: root.overviewVisible
                            textFontFamily: root.textFontFamily
                            heroFontFamily: root.heroFontFamily
                            wallpaperPath: root.overviewWallpaperSource
                            windowCornerRadius: userConfig.workspaceOverviewWindowRadius
                            onCloseRequested: root.closeOverviewEverywhere()
                        }

                    }

                }

            }

            // ── Stopwatch layer ──────────────────────────────────────────────
            Loader {
                id: stopwatchLoader

                anchors.fill: parent
                active: root.stopwatchMounted
                asynchronous: false
                visible: active && islandContainer.islandState === "stopwatch"

                sourceComponent: Component {
                    StopwatchLayer {
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: islandContainer.islandState === "stopwatch"
                    }

                }

            }

            // ── Timer layer ──────────────────────────────────────────────────
            Loader {
                id: timerLoader

                anchors.fill: parent
                active: root.timerMounted
                asynchronous: false
                visible: active && islandContainer.islandState === "timer"

                sourceComponent: Component {
                    TimerLayer {
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: islandContainer.islandState === "timer"
                    }

                }

            }

            // ── Pomodoro layer ───────────────────────────────────────────────
            Loader {
                id: pomodoroLoader

                anchors.fill: parent
                active: true
                asynchronous: false
                visible: islandContainer.islandState === "pomodoro"

                sourceComponent: Component {
                    PomodoroLayer {
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        iconFontFamily: root.iconFontFamily
                        showCondition: islandContainer.islandState === "pomodoro"
                        onOnBreakChanged: root.pomodoroIsOnBreak = onBreak
                        onActiveChanged: {
                            if (active && islandContainer.islandState !== "pomodoro")
                                islandContainer.showPomodoro();

                        }
                    }

                }

            }

            Item {
                id: persistentRing

                readonly property bool active: root.rightRingType !== ""
                readonly property bool isTimer: root.rightRingType === "timer"
                readonly property bool isPomodoro: root.rightRingType === "pomodoro"
                readonly property color ringCol: (timerLoader.item && timerLoader.item.finished && isTimer) ? "#f38ba8" : isPomodoro ? (root.pomodoroIsOnBreak ? "#a6e3a1" : "#cba6f7") : "#cba6f7"
                readonly property real ringProg: isTimer ? (timerLoader.item ? timerLoader.item.ringProgress : 0) : isPomodoro ? (pomodoroLoader.item ? pomodoroLoader.item.ringProgress : 0) : (stopwatchLoader.item ? stopwatchLoader.item.ringProgress : 0)
                readonly property string ringTime: isTimer ? (timerLoader.item ? timerLoader.item.timeString : "") : isPomodoro ? (pomodoroLoader.item ? pomodoroLoader.item.timeString : "") : (stopwatchLoader.item ? stopwatchLoader.item.timeString : "")

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                visible: active && (islandContainer.islandState === "normal" || islandContainer.islandState === "custom" || islandContainer.islandState === "lyrics")
                opacity: visible ? 1 : 0

                Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        const cx = width / 2, cy = height / 2, r = cx - 3;
                        ctx.clearRect(0, 0, width, height);
                        ctx.lineWidth = 2.5;
                        ctx.strokeStyle = "#313244";
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.stroke();
                    }
                }

                Canvas {
                    property real prog: persistentRing.ringProg
                    property color col: persistentRing.ringCol

                    anchors.fill: parent
                    antialiasing: true
                    onProgChanged: requestPaint()
                    onColChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        const cx = width / 2, cy = height / 2, r = cx - 3;
                        const s = -Math.PI / 2, e = s + Math.PI * 2 * Math.max(0, Math.min(1, prog));
                        ctx.clearRect(0, 0, width, height);
                        if (prog <= 0)
                            return ;

                        ctx.lineWidth = 2.5;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = col;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, s, e, false);
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: persistentRing.ringTime
                    color: persistentRing.ringCol
                    font.pixelSize: 8
                    font.family: root.heroFontFamily
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: persistentRing.ringCol
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 1
                    visible: persistentRing.active

                    SequentialAnimation on opacity {
                        running: persistentRing.active
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.2
                            duration: 600
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: 600
                            easing.type: Easing.InOutSine
                        }

                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }

                }

            }

            Item {
                id: persistentLeftRing

                readonly property bool active: root.leftRingType !== ""
                readonly property bool isTimer: root.leftRingType === "timer"
                readonly property bool isPomodoro: root.leftRingType === "pomodoro"
                readonly property color ringCol: (timerLoader.item && timerLoader.item.finished && isTimer) ? "#f38ba8" : isPomodoro ? (root.pomodoroIsOnBreak ? "#a6e3a1" : "#cba6f7") : "#cba6f7"
                readonly property real ringProg: isTimer ? (timerLoader.item ? timerLoader.item.ringProgress : 0) : isPomodoro ? (pomodoroLoader.item ? pomodoroLoader.item.ringProgress : 0) : (stopwatchLoader.item ? stopwatchLoader.item.ringProgress : 0)
                readonly property string ringTime: isTimer ? (timerLoader.item ? timerLoader.item.timeString : "") : isPomodoro ? (pomodoroLoader.item ? pomodoroLoader.item.timeString : "") : (stopwatchLoader.item ? stopwatchLoader.item.timeString : "")

                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                visible: active && (islandContainer.islandState === "normal" || islandContainer.islandState === "custom" || islandContainer.islandState === "lyrics")
                opacity: visible ? 1 : 0

                Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        const cx = width / 2, cy = height / 2, r = cx - 3;
                        ctx.clearRect(0, 0, width, height);
                        ctx.lineWidth = 2.5;
                        ctx.strokeStyle = "#313244";
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.stroke();
                    }
                }

                Canvas {
                    property real prog: persistentLeftRing.ringProg
                    property color col: persistentLeftRing.ringCol

                    anchors.fill: parent
                    antialiasing: true
                    onProgChanged: requestPaint()
                    onColChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        const cx = width / 2, cy = height / 2, r = cx - 3;
                        const s = -Math.PI / 2, e = s + Math.PI * 2 * Math.max(0, Math.min(1, prog));
                        ctx.clearRect(0, 0, width, height);
                        if (prog <= 0)
                            return ;

                        ctx.lineWidth = 2.5;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = col;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, s, e, false);
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: persistentLeftRing.ringTime
                    color: persistentLeftRing.ringCol
                    font.pixelSize: 8
                    font.family: root.heroFontFamily
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: persistentLeftRing.ringCol
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 1
                    visible: persistentLeftRing.active

                    SequentialAnimation on opacity {
                        running: persistentLeftRing.active
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.2
                            duration: 600
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: 600
                            easing.type: Easing.InOutSine
                        }

                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }

                }

            }

            // ── PetCat ────────────────────────────────────────────────────────
            Loader {
                id: petCatLoader

                active: userConfig.petEnabled
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 58
                opacity: !root.overviewVisible && (islandContainer.islandState === "normal" || islandContainer.islandState === "custom" || islandContainer.islandState === "lyrics") ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }

                }

                sourceComponent: Component {
                    PetCat {
                        musicPlaying: islandContainer.activePlayer !== null && islandContainer.activePlayer.playbackState === MprisPlaybackState.Playing
                        cpuUsage: islandContainer.currentCpuUsage * 100
                        notificationIn: islandContainer.islandState === "notification"
                        pomodoroBreak: root.pomodoroIsOnBreak
                        timerFinished: timerLoader.item ? timerLoader.item.timerFinished : false
                    }

                }

            }

            Behavior on displayedWidth {
                NumberAnimation {
                    duration: capsuleMouseArea.sideSwipeInteractive ? 0 : mainCapsule.morphDuration
                    easing.type: Easing.OutQuint
                }

            }

            Behavior on height {
                NumberAnimation {
                    duration: mainCapsule.morphDuration
                    easing.type: Easing.OutQuint
                }

            }

            Behavior on radius {
                NumberAnimation {
                    duration: mainCapsule.morphDuration
                    easing.type: Easing.OutQuint
                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 280
                    easing.type: Easing.InOutQuad
                }

            }

            Behavior on outlineWidth {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.InOutQuad
                }

            }

            Behavior on outlineColor {
                ColorAnimation {
                    duration: 260
                    easing.type: Easing.InOutQuad
                }

            }

        }

        Item {
            id: wifiConnectivityDetailShell

            property real revealProgress: 0
            readonly property real shownX: Math.max(16, mainCapsule.x - width - root.connectivityDetailGap)
            readonly property real hiddenX: mainCapsule.x + 28
            readonly property real hiddenY: mainCapsule.y + 20
            readonly property real panelScale: revealProgress

            function startPanelAnimation(open) {
                wifiRevealAnimation.stop();
                if (open) {
                    wifiRevealAnimation.to = 1;
                    wifiRevealAnimation.duration = 420;
                    wifiRevealAnimation.easing.type = Easing.OutBack;
                    wifiRevealAnimation.easing.overshoot = 0.5;
                    wifiRevealAnimation.start();
                } else {
                    wifiRevealAnimation.to = 0;
                    wifiRevealAnimation.duration = 180;
                    wifiRevealAnimation.easing.type = Easing.InCubic;
                    wifiRevealAnimation.start();
                }
            }

            x: hiddenX + (shownX - hiddenX) * revealProgress
            y: hiddenY + (mainCapsule.y - hiddenY) * revealProgress
            width: root.connectivityDetailWidth
            height: root.connectivityDetailHeight
            opacity: revealProgress
            visible: root.wifiConnectivityDetailMounted || opacity > 0.001
            z: 3
            Component.onCompleted: revealProgress = root.wifiConnectivityDetailOpen ? 1 : 0

            HoverHandler {
                id: wifiHoverHandler
            }

            NumberAnimation {
                id: wifiRevealAnimation

                target: wifiConnectivityDetailShell
                property: "revealProgress"
            }

            Connections {
                function onWifiConnectivityDetailOpenChanged() {
                    wifiConnectivityDetailShell.startPanelAnimation(root.wifiConnectivityDetailOpen);
                }

                target: root
            }

            Item {
                id: wifiPanelBody

                anchors.fill: parent

                Loader {
                    anchors.fill: parent
                    active: root.wifiConnectivityDetailMounted
                    asynchronous: false
                    visible: active

                    sourceComponent: Component {
                        ConnectivityDetailPanel {
                            provider: controlCenterLoader.item
                            panelKind: "wifi"
                            iconFontFamily: root.iconFontFamily
                            textFontFamily: root.textFontFamily
                            heroFontFamily: root.heroFontFamily
                            presentationProgress: wifiConnectivityDetailShell.revealProgress
                        }

                    }

                }

                transform: Scale {
                    origin.x: wifiPanelBody.width
                    origin.y: Math.min(wifiPanelBody.height - 32, Math.max(36, mainCapsule.height - 215))
                    xScale: wifiConnectivityDetailShell.panelScale
                    yScale: wifiConnectivityDetailShell.panelScale
                }

            }

        }

        Item {
            id: bluetoothConnectivityDetailShell

            property real revealProgress: 0
            readonly property real shownX: Math.min(root.width - width - 16, mainCapsule.x + mainCapsule.width + root.connectivityDetailGap)
            readonly property real hiddenX: mainCapsule.x + mainCapsule.width - width - 28
            readonly property real hiddenY: mainCapsule.y + 20
            readonly property real panelScale: revealProgress

            function startPanelAnimation(open) {
                bluetoothRevealAnimation.stop();
                if (open) {
                    bluetoothRevealAnimation.to = 1;
                    bluetoothRevealAnimation.duration = 420;
                    bluetoothRevealAnimation.easing.type = Easing.OutBack;
                    bluetoothRevealAnimation.easing.overshoot = 0.5;
                    bluetoothRevealAnimation.start();
                } else {
                    bluetoothRevealAnimation.to = 0;
                    bluetoothRevealAnimation.duration = 180;
                    bluetoothRevealAnimation.easing.type = Easing.InCubic;
                    bluetoothRevealAnimation.start();
                }
            }

            x: hiddenX + (shownX - hiddenX) * revealProgress
            y: hiddenY + (mainCapsule.y - hiddenY) * revealProgress
            width: root.connectivityDetailWidth
            height: root.connectivityDetailHeight
            opacity: revealProgress
            visible: root.bluetoothConnectivityDetailMounted || opacity > 0.001
            z: 3
            Component.onCompleted: revealProgress = root.bluetoothConnectivityDetailOpen ? 1 : 0

            HoverHandler {
                id: bluetoothHoverHandler
            }

            NumberAnimation {
                id: bluetoothRevealAnimation

                target: bluetoothConnectivityDetailShell
                property: "revealProgress"
            }

            Connections {
                function onBluetoothConnectivityDetailOpenChanged() {
                    bluetoothConnectivityDetailShell.startPanelAnimation(root.bluetoothConnectivityDetailOpen);
                }

                target: root
            }

            Item {
                id: bluetoothPanelBody

                anchors.fill: parent

                Loader {
                    anchors.fill: parent
                    active: root.bluetoothConnectivityDetailMounted
                    asynchronous: false
                    visible: active

                    sourceComponent: Component {
                        ConnectivityDetailPanel {
                            provider: controlCenterLoader.item
                            panelKind: "bluetooth"
                            iconFontFamily: root.iconFontFamily
                            textFontFamily: root.textFontFamily
                            heroFontFamily: root.heroFontFamily
                            presentationProgress: bluetoothConnectivityDetailShell.revealProgress
                        }

                    }

                }

                transform: Scale {
                    origin.x: 0
                    origin.y: Math.min(bluetoothPanelBody.height - 32, Math.max(36, mainCapsule.height - 215))
                    xScale: bluetoothConnectivityDetailShell.panelScale
                    yScale: bluetoothConnectivityDetailShell.panelScale
                }

            }

        }

        // ── Calendar panel — opens below the capsule on double-click ──────
        Item {
            id: calendarShell

            readonly property real panelW: root.calendarPanelWidth
            readonly property real panelH: root.calendarPanelHeight
            // Centred horizontally under the capsule
            readonly property real shownX: Math.round((root.width - panelW) / 2)
            readonly property real shownY: mainCapsule.y + mainCapsule.height + 10
            readonly property real hiddenY: mainCapsule.y + mainCapsule.height - 12
            property real revealProgress: 0

            x: shownX
            y: hiddenY + (shownY - hiddenY) * revealProgress
            width: panelW
            height: panelH
            opacity: revealProgress
            visible: root.calendarMounted || opacity > 0.001
            z: 3
            Component.onCompleted: revealProgress = root.calendarOpen ? 1 : 0

            HoverHandler {
                id: calendarHoverHandler
            }

            NumberAnimation {
                id: calendarRevealAnimation

                target: calendarShell
                property: "revealProgress"
            }

            Connections {
                function onCalendarOpenChanged() {
                    calendarRevealAnimation.stop();
                    if (root.calendarOpen) {
                        calendarRevealAnimation.to = 1;
                        calendarRevealAnimation.duration = 420;
                        calendarRevealAnimation.easing.type = Easing.OutBack;
                        calendarRevealAnimation.easing.overshoot = 0.45;
                        // restartAutoHideTimer lives on islandContainer; calendarShell is a
                        // direct child of islandContainer so we are already in that scope.
                        autoHideTimer.interval = 10000;
                        autoHideTimer.restart();
                    } else {
                        calendarRevealAnimation.to = 0;
                        calendarRevealAnimation.duration = 180;
                        calendarRevealAnimation.easing.type = Easing.InCubic;
                    }
                    calendarRevealAnimation.start();
                }

                target: root
            }

            // Scale-from-top-centre reveal
            Item {
                id: calendarBody

                anchors.fill: parent

                Loader {
                    anchors.fill: parent
                    active: root.calendarMounted
                    asynchronous: false
                    visible: active
                    // Reset the shared inactivity timer whenever the user interacts
                    // with the calendar (month nav, day selection, Today chip).
                    onLoaded: {
                        if (item)
                            item.userInteracted.connect(function() {
                            autoHideTimer.interval = 10000;
                            autoHideTimer.restart();
                        });

                    }

                    sourceComponent: Component {
                        CalendarLayer {
                            textFontFamily: root.textFontFamily
                            heroFontFamily: root.heroFontFamily
                            iconFontFamily: root.iconFontFamily
                            presentationProgress: calendarShell.revealProgress
                        }

                    }

                }

                transform: Scale {
                    origin.x: calendarBody.width / 2
                    origin.y: 0
                    xScale: calendarShell.revealProgress
                    yScale: calendarShell.revealProgress
                }

            }

        }

        Item {
            id: aiPromptShell

            readonly property real panelW: 420
            readonly property real panelH: 340
            readonly property real shownX: Math.round((root.width - panelW) / 2)
            readonly property real shownY: mainCapsule.y + mainCapsule.height + 10
            readonly property real hiddenY: mainCapsule.y + mainCapsule.height - 12
            property real revealProgress: 0

            x: shownX
            y: hiddenY + (shownY - hiddenY) * revealProgress
            width: panelW
            height: panelH
            opacity: revealProgress
            visible: root.aiPromptMounted || opacity > 0.001
            z: 3
            Component.onCompleted: revealProgress = root.aiPromptOpen ? 1 : 0

            HoverHandler {
                id: aiPromptHoverHandler
            }

            NumberAnimation {
                id: aiPromptRevealAnimation

                target: aiPromptShell
                property: "revealProgress"
            }

            Connections {
                function onAiPromptOpenChanged() {
                    aiPromptRevealAnimation.stop();
                    if (root.aiPromptOpen) {
                        aiPromptRevealAnimation.to = 1;
                        aiPromptRevealAnimation.duration = 420;
                        aiPromptRevealAnimation.easing.type = Easing.OutBack;
                        aiPromptRevealAnimation.easing.overshoot = 0.45;
                    } else {
                        aiPromptRevealAnimation.to = 0;
                        aiPromptRevealAnimation.duration = 180;
                        aiPromptRevealAnimation.easing.type = Easing.InCubic;
                    }
                    aiPromptRevealAnimation.start();
                }

                target: root
            }

            Item {
                id: aiPromptBody

                anchors.fill: parent

                Loader {
                    anchors.fill: parent
                    active: root.aiPromptMounted
                    asynchronous: false
                    visible: active

                    sourceComponent: Component {
                        AiPromptLayer {
                            textFontFamily: root.textFontFamily
                            ollamaEndpoint: userConfig.ollamaEndpoint
                            ollamaModel: userConfig.ollamaModel
                            ollamaApiKey: userConfig.ollamaApiKey
                            onCloseRequested: root.setAiPromptVisible(false)
                        }
                    }
                }

                transform: Scale {
                    origin.x: aiPromptBody.width / 2
                    origin.y: 0
                    xScale: aiPromptShell.revealProgress
                    yScale: aiPromptShell.revealProgress
                }
            }
        }

        Connections {
            function onAnyActiveUiHoveredChanged() {
                if (root.anyActiveUiHovered) {
                    autoHideTimer.stop();
                } else {
                    const state = islandContainer.islandState;
                    if (root.anyPopupOpen || state === "expanded" || state === "long_capsule" || state === "notification" || state === "split") {
                        autoHideTimer.interval = state === "notification" ? islandContainer.notificationAutoHideInterval : 10000;
                        autoHideTimer.restart();
                    }
                }
            }

            target: root
        }

        Behavior on osdProgress {
            enabled: islandContainer.osdProgressAnimationEnabled

            SmoothedAnimation {
                velocity: 1.2
                duration: 180
                easing.type: Easing.InOutQuad
            }

        }

        Behavior on swipeTransitionProgress {
            NumberAnimation {
                duration: capsuleMouseArea.sideSwipeInteractive ? 0 : islandContainer.swipeAnimationDuration
                easing.type: Easing.OutCubic
            }

        }

    }

    mask: Region {
        Region {
            item: mainCapsule.visible ? mainCapsule : null
        }

        // Fullscreen input mask when a popup is open to capture clicks outside
        Region {
            intersection: Intersection.Combine
            x: 0
            y: 0
            width: root.anyPopupOpen ? root.width : 0
            height: root.anyPopupOpen ? root.height : 0
        }

        // Keep pointer delivery stable while a side swipe is active, even over empty workspace space.
        Region {
            intersection: Intersection.Combine
            x: 0
            y: capsuleMouseArea.sideSwipeInteractive ? Math.max(0, Math.floor(mainCapsule.y - capsuleMouseArea.sideSwipeVerticalTolerance)) : 0
            width: capsuleMouseArea.sideSwipeInteractive ? root.width : 0
            height: capsuleMouseArea.sideSwipeInteractive ? Math.ceil(mainCapsule.height + capsuleMouseArea.sideSwipeVerticalTolerance * 2) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(wifiConnectivityDetailShell.x)
            y: Math.floor(wifiConnectivityDetailShell.y)
            width: wifiConnectivityDetailShell.visible ? Math.ceil(wifiConnectivityDetailShell.width) : 0
            height: wifiConnectivityDetailShell.visible ? Math.ceil(wifiConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(bluetoothConnectivityDetailShell.x)
            y: Math.floor(bluetoothConnectivityDetailShell.y)
            width: bluetoothConnectivityDetailShell.visible ? Math.ceil(bluetoothConnectivityDetailShell.width) : 0
            height: bluetoothConnectivityDetailShell.visible ? Math.ceil(bluetoothConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(calendarShell.x)
            y: Math.floor(calendarShell.y)
            width: calendarShell.visible ? Math.ceil(calendarShell.width) : 0
            height: calendarShell.visible ? Math.ceil(calendarShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(aiPromptShell.x)
            y: Math.floor(aiPromptShell.y)
            width: aiPromptShell.visible ? Math.ceil(aiPromptShell.width) : 0
            height: aiPromptShell.visible ? Math.ceil(aiPromptShell.height) : 0
        }

    }

    Process {
        id: clipboardDaemon
        command: ["wl-paste", "--watch", "python3", "/home/cipheroot/.config/quickshell/dynamic_island/bin/append_clip.py"]
        Component.onCompleted: exec(command)
    }

}
