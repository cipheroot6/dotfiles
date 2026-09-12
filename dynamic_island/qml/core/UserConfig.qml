pragma Singleton
import QtQuick
import IslandBackend

QtObject {
    id: userConfig

    property string wallpaperPath: BackendUserConfig.wallpaperPath
    property bool petEnabled: BackendUserConfig.petEnabled
    property real workspaceOverviewWindowRadius: 12
    property string iconFontFamily: BackendUserConfig.iconFontFamily
    property string textFontFamily: BackendUserConfig.textFontFamily
    property string heroFontFamily: BackendUserConfig.heroFontFamily
    property string timeFontFamily: BackendUserConfig.timeFontFamily
    
    // Black Hole Dropzone Items
    property var dropzoneItems: []
    
    // Set these to `0` if you want to disable the in-overview key handling.
    property int overviewCloseKey: Qt.Key_Escape
    property int overviewPreviousWorkspaceKey: Qt.Key_Left
    property int overviewNextWorkspaceKey: Qt.Key_Right
    // This registers a Hyprland global shortcut action for the workspace overview.
    property string overviewGlobalShortcutAppid: "quickshell"
    property string overviewGlobalShortcutName: "dynamic-island-overview"
    // Workspace overview mouse bindings.
    property int workspaceOverviewWorkspaceActivateButton: 1
    property int workspaceOverviewWindowDragButton: 1
    property int workspaceOverviewWindowFocusButton: 1
    property int workspaceOverviewWindowCloseButton: 3

    property int dynamicIslandSwipeButton: 1
    property int dynamicIslandPrimaryButton: 1
    property string dynamicIslandPrimaryAction: "toggleExpandedPlayer"
    property int dynamicIslandSecondaryButton: 3
    property string dynamicIslandSecondaryAction: "toggleControlCenter"
    property int dynamicIslandMiddleButton: 2
    property string dynamicIslandMiddleAction: "toggleAiPrompt"
    property var dynamicIslandLeftSwipeItems: (["cpu", "ram", "disk", "temp"])
    
    // AI Prompt Config
    property string ollamaEndpoint: BackendUserConfig.ollamaEndpoint
    property string ollamaModel: BackendUserConfig.ollamaModel
    property string ollamaApiKey: BackendUserConfig.ollamaApiKey

    property var scriptPaths: ({
        "button_1": "/home/cipheroot/.local/bin/quickshell_script/wifi-menu.sh",
        "button_2": "/home/cipheroot/.local/bin/quickshell_script/bluetooth-menu.sh",
        "button_3": "/home/cipheroot/.local/bin/quickshell_script/wallpaper-switch.sh",
        "button_4": "/home/cipheroot/.local/bin/quickshell_script/powermenu"
    })
    property var controlCenterActions: ([{
        "icon": "󰅍",
        "command": "__clipboard__"
    }, {
        "icon": "",
        "command": "hyprctl dispatch exec /home/cipheroot/.config/quickshell/dynamic_island/dynamic-island-config-app"
    }, {
        "icon": "󰄬",
        "command": "__todo__"
    }, {
        "icon": "󰔛",
        "command": "__pomodoro__"
    }])
    property var controlCenterIcons: ({
        "charging": "",
        "brightness": "󰃟",
        "volume": "󰕾"
    })
    property var statusIcons: ({
        "default": "🎧",
        "notification": "",
        "volume": "󰕾",
        "mute": "󰝟",
        "brightnessLow": "󰃞",
        "brightnessMedium": "󰃟",
        "brightnessHigh": "󰃠",
        "charging": "",
        "discharging": "",
        "cpu": "󰻠",
        "ram": "",
        "disk": "󰋊",
        "temp": "",
        "capsLockOn": "",
        "capsLockOff": "",
        "bluetooth": "󰋋"
    })

    function mouseButton(button) {
        switch (button) {
        case 1:
            return Qt.LeftButton;
        case 2:
            return Qt.MiddleButton;
        case 3:
            return Qt.RightButton;
        default:
            return typeof button === "number" ? button : Qt.NoButton;
        }
    }

    function mouseButtonsMask(buttons) {
        if (buttons === undefined || buttons === null)
            return Qt.NoButton;

        if (Array.isArray(buttons)) {
            let mask = Qt.NoButton;
            for (let index = 0; index < buttons.length; index++) mask |= mouseButton(buttons[index])
            return mask;
        }
        return mouseButton(buttons);
    }
}
