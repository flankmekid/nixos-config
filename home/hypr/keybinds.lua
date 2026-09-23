-- Local copy of Caelestia's hyprland/keybinds.lua (see home/caelestia-hypr.nix).
-- Changes from upstream:
--   * every bind has a description, so HyprMod and `hyprctl binds` show it
--   * the launcher toggles through IPC, so pressing Super again closes it
--   * restart/restore binds use the systemd user service instead of `qs`
--     (not on PATH) or `caelestia shell -d` (starts a second shell whose
--     global shortcuts clash with the service's)
-- When the upstream file changes, compare it with this one and copy over the
-- changes you want.

local vars = require("variables")
local fn   = require("utils.functions")


-- Flags
local locked           = { locked = true }
local mouse            = { mouse = true }
local release          = { release = true }
local repeating        = { repeating = true }
local locked_repeating = { locked = true, repeating = true }

local function normalise_keybind(key)
    return key:gsub("%s+", ""):lower()
end

local function valid_keybind(key)
    return type(key) == "string" and key:match("%S") ~= nil
end

local function repeating_unless_mouse(key)
    return not normalise_keybind(key):find("mouse", 1, true) and repeating or nil
end

local function flatten_keybinds(keybinds, keys)
    keys = keys or {}

    if type(keybinds) == "table" then
        for _, keybind in pairs(keybinds) do
            flatten_keybinds(keybind, keys)
        end
    elseif valid_keybind(keybinds) then
        keys[#keys + 1] = keybinds
    end

    return keys
end

local function create_bind(keybinds, action, flags, description)
    local get_flags = type(flags) == "function" and flags or function()
        return flags
    end

    for _, key in ipairs(flatten_keybinds(keybinds)) do
        local opts = {}
        for k, v in pairs(get_flags(key) or {}) do
            opts[k] = v
        end
        opts.description = description
        hl.bind(key, action, opts)
    end
end

local function extend_keybind(base, suffix)
    return valid_keybind(base) and base .. " + " .. suffix or nil
end

-- Launcher
local launcher_default = normalise_keybind("SUPER + SUPER_L")
create_bind(
    vars.kbLauncher,
    hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"),
    function(key)
        return normalise_keybind(key) == launcher_default and release or nil
    end,
    "Toggle launcher"
)

-- Misc
create_bind(vars.kbSession, hl.dsp.global("caelestia:session"), nil, "Toggle session menu")
create_bind(vars.kbShowSidebar, hl.dsp.global("caelestia:sidebar"), nil, "Toggle sidebar")
create_bind(vars.kbClearNotifs, hl.dsp.global("caelestia:clearNotifs"), locked, "Clear all notifications")
create_bind(vars.kbShowPanels, hl.dsp.global("caelestia:showall"), nil, "Show launcher, dashboard and OSD")
create_bind(vars.kbLock, hl.dsp.global("caelestia:lock"), nil, "Lock screen")

-- Restore lock: start the shell if it crashed, then lock again
create_bind(vars.kbRestoreLock, function()
    hl.dispatch(hl.dsp.exec_cmd("systemctl --user start caelestia"))
    hl.dispatch(hl.dsp.global("caelestia:lock"))
end, nil, "Restore lock screen (restarts shell if needed)")

-- Kill/restart
create_bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("systemctl --user stop caelestia"), release, "Stop shell")
create_bind(
    "CTRL + SUPER + ALT + R",
    hl.dsp.exec_cmd("systemctl --user restart caelestia"),
    release,
    "Restart shell"
)

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    create_bind(extend_keybind(vars.kbGoToWs, key), fn.wsaction("focus", "", i), nil, "Go to workspace " .. i)
    create_bind(extend_keybind(vars.kbMoveWinToWs, key), fn.wsaction("move", "", i), nil,
        "Move window to workspace " .. i)
    create_bind(extend_keybind(vars.kbGoToWsGroup, key), fn.wsaction("focus", "group", i), nil,
        "Go to workspace group " .. i)
    create_bind(extend_keybind(vars.kbMoveWinToWsGroup, key), fn.wsaction("move", "group", i), nil,
        "Move window to workspace group " .. i)
end

-- Go to workspace -1/+1
create_bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), repeating_unless_mouse, "Previous workspace")
create_bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), repeating_unless_mouse, "Next workspace")

-- Go to workspace group -1/+1
create_bind(vars.kbPrevWsGroup, hl.dsp.focus({ workspace = "-10" }), repeating_unless_mouse, "Previous workspace group")
create_bind(vars.kbNextWsGroup, hl.dsp.focus({ workspace = "+10" }), repeating_unless_mouse, "Next workspace group")

-- Move window to workspace -1/+1
create_bind(vars.kbMoveWinToWsNext, hl.dsp.window.move({ workspace = "+1" }), repeating_unless_mouse,
    "Move window to next workspace")
create_bind(vars.kbMoveWinToWsPrev, hl.dsp.window.move({ workspace = "-1" }), repeating_unless_mouse,
    "Move window to previous workspace")

-- Move window to/from special workspace
create_bind(vars.kbMoveWinToWsSpecial, hl.dsp.window.move({ workspace = "special:special" }), nil,
    "Move window to special workspace")
create_bind(vars.kbMoveWinFromWsSpecial, hl.dsp.window.move({ workspace = "e+0" }), nil,
    "Move window out of special workspace")

-- Window groups
create_bind(vars.kbWindowCycleNext, hl.dsp.window.cycle_next(), repeating, "Focus next window")
create_bind(vars.kbWindowCyclePrev, hl.dsp.window.cycle_next({ next = false }), repeating, "Focus previous window")
create_bind(vars.kbWindowGroupCycleNext, hl.dsp.group.next(), repeating, "Next window in group")
create_bind(vars.kbWindowGroupCyclePrev, hl.dsp.group.prev(), repeating, "Previous window in group")
create_bind(vars.kbToggleGroup, hl.dsp.group.toggle(), nil, "Toggle window group")
create_bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }), nil, "Move window out of group")
create_bind(vars.kbGroupLockActive, hl.dsp.group.lock_active(), nil, "Lock active group")

-- Window actions
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    create_bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }), nil, "Focus window " .. dir)
    create_bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }), nil, "Move window " .. dir)
end

create_bind(vars.kbWindowDecreaseWidth, fn.resize_active_window(-10, 0), repeating, "Decrease window width")
create_bind(vars.kbWindowIncreaseWidth, fn.resize_active_window(10, 0), repeating, "Increase window width")
create_bind(vars.kbWindowDecreaseHeight, fn.resize_active_window(0, -10), repeating, "Decrease window height")
create_bind(vars.kbWindowIncreaseHeight, fn.resize_active_window(0, 10), repeating, "Increase window height")

create_bind({ vars.kbMoveWindow, "SUPER + mouse:272" }, hl.dsp.window.drag(), mouse, "Drag window")
create_bind({ vars.kbResizeWindow, "SUPER + mouse:273" }, hl.dsp.window.resize(), mouse, "Resize window")
create_bind(vars.kbCenterWindow, hl.dsp.window.center(), nil, "Center window")
create_bind(vars.kbNormalizeWindow, function()
    hl.dispatch(hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
    hl.dispatch(hl.dsp.window.center())
end, nil, "Resize window to default size and center")
create_bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end, nil, "Picture-in-picture window")
create_bind(vars.kbPinWindow, hl.dsp.window.pin(), nil, "Pin window")
create_bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }), nil, "Fullscreen")
create_bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }), nil, "Maximize")
create_bind(vars.kbToggleWindowFloating, hl.dsp.window.float(), nil, "Toggle floating")
create_bind(vars.kbCloseWindow, hl.dsp.window.close(), nil, "Close window")

-- Special workspace toggles
create_bind(vars.kbSpecialWs, fn.toggle("specialws"), nil, "Toggle special workspace")
create_bind(vars.kbSystemMonitorWs, fn.toggle("sysmon"), nil, "Toggle system monitor")
create_bind(vars.kbMusicWs, fn.toggle("music"), nil, "Toggle music workspace")
create_bind(vars.kbCommunicationWs, fn.toggle("communication"), nil, "Toggle communication workspace")
create_bind(vars.kbTodoWs, fn.toggle("todo"), nil, "Toggle todo workspace")

-- Apps
create_bind(vars.kbTerminal, hl.dsp.exec_cmd(vars.terminal), nil, "Open terminal")
create_bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser), nil, "Open browser")
create_bind(vars.kbEditor, hl.dsp.exec_cmd(vars.editor), nil, "Open editor")
create_bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer), nil, "Open file manager")
create_bind(vars.kbAudioSettings, hl.dsp.exec_cmd(vars.audioSettings), nil, "Open audio settings")

-- Utilities
create_bind(vars.kbScreenshot, hl.dsp.exec_cmd("caelestia screenshot"), locked, "Screenshot")
create_bind(vars.kbScreenshotFreeze, hl.dsp.global("caelestia:screenshotFreeze"), nil, "Screenshot region (freeze)")
-- The Copilot key sends SUPER + SHIFT + F23; use it as a second region screenshot key.
create_bind("SUPER + SHIFT + F23", hl.dsp.global("caelestia:screenshotFreeze"), nil, "Screenshot region (Copilot key)")
create_bind(vars.kbScreenshotRegion, hl.dsp.global("caelestia:screenshot"), nil, "Screenshot region")
create_bind(vars.kbRecord, hl.dsp.exec_cmd("caelestia record"), nil, "Record screen")
create_bind(vars.kbRecordSound, hl.dsp.exec_cmd("caelestia record -s"), nil, "Record screen with sound")
create_bind(vars.kbRecordRegion, hl.dsp.exec_cmd("caelestia record -r"), nil, "Record region")
create_bind(vars.kbColorPicker, hl.dsp.exec_cmd("hyprpicker -a"), nil, "Colour picker")

-- Brightness
create_bind("XF86MonBrightnessUp", hl.dsp.global("caelestia:brightnessUp"), locked, "Brightness up")
create_bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), locked, "Brightness down")

-- Media
create_bind({ vars.kbMediaToggle, "XF86AudioPlay", "XF86AudioPause" }, hl.dsp.global("caelestia:mediaToggle"), locked,
    "Play/pause media")
create_bind({ vars.kbMediaNext, "XF86AudioNext" }, hl.dsp.global("caelestia:mediaNext"), locked, "Next track")
create_bind({ vars.kbMediaPrev, "XF86AudioPrev" }, hl.dsp.global("caelestia:mediaPrev"), locked, "Previous track")
create_bind({ vars.kbMediaStop, "XF86AudioStop" }, hl.dsp.global("caelestia:mediaStop"), locked, "Stop media")

-- Volume
create_bind({ vars.kbVolumeMute, "XF86AudioMute" }, hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked,
    "Mute audio")
create_bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked, "Mute microphone")
create_bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+"
    ),
    locked_repeating,
    "Volume up"
)
create_bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-"
    ),
    locked_repeating,
    "Volume down"
)

-- Sleep
create_bind(vars.kbSleep, hl.dsp.exec_cmd(vars.sleepGestureCmd), locked, "Sleep")

-- Vesktop mute/deafen from anywhere. Vesktop has no global shortcuts, so these
-- send Discord's own shortcuts (Ctrl+Shift+M / Ctrl+Shift+D) straight to its
-- window, even when it is unfocused or on its special workspace.
create_bind("KP_Divide", hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "M", window = "class:vesktop" }), nil,
    "Vesktop: toggle mute")
create_bind("KP_Multiply", hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "D", window = "class:vesktop" }), nil,
    "Vesktop: toggle deafen")

-- Clipboard and emoji picker
-- Clipboard history with image previews (Vicinae, home/clipboard.nix).
-- Escape or clicking away closes it.
create_bind(vars.kbClipboard, hl.dsp.exec_cmd("vicinae cmd launch clipboard:history"), nil, "Clipboard history")

-- clipse in a floating kitty window (home/clipboard.nix); pressing again closes it.
-- -xf matches only the UI, whose whole command line is "clipse", not the
-- listener or the sh -c running this command.
create_bind("SUPER + SHIFT + V",
    hl.dsp.exec_cmd("pkill -xf clipse || kitty --class clipse -o background_opacity=0.97 -e clipse"),
    nil, "Clipboard history (terminal)")
create_bind(vars.kbClipboardDel, hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard -d"), nil,
    "Delete from clipboard history")
create_bind(vars.kbEmoji, hl.dsp.exec_cmd("pkill fuzzel || caelestia emoji -p"), nil, "Emoji picker")
create_bind(
    vars.kbClipboardPasteLatest,
    hl.dsp.exec_cmd('sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"'),
    locked,
    "Type latest clipboard entry"
)

-- Testing
create_bind(
    "SUPER + ALT + F12",
    hl.dsp.exec_cmd(
        "notify-send -u low -i dialog-information-symbolic 'Test notification' " ..
        [["Here's a really long message to test truncation and wrapping\nYou can middle click or flick this notification to dismiss it!"]] ..
        " -a 'Shell' -A 'Test1=I got it!' -A 'Test2=Another action'"
    ),
    nil,
    "Send test notification"
)
