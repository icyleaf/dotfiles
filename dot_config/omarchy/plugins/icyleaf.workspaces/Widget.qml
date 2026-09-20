import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "AppIconModel.js" as AppIconModel

BarWidget {
  id: root
  moduleName: "icyleaf.workspaces"

  readonly property string fontFamily: root.bar && root.bar.fontFamily ? root.bar.fontFamily : Style.font.family

  // -------------------------------------------------------------- Special Workspaces Configuration
  readonly property var defaultSpecials: [
    { name: "silent", icon: "󰏤", label: "silent" },
    { name: "term", icon: "", label: "term" },
    { name: "chat", icon: "󰭹", label: "chat" },
    { name: "music", icon: "󰎆", label: "music" }
  ]

  readonly property var specialsList: {
    var custom = root.setting("specials", null)
    if (Array.isArray(custom) && custom.length > 0) {
      var iconMap = { silent: "󰏤", term: "", chat: "󰭹", music: "󰎆", scratch: "󰘳", notes: "󰠮" }
      return custom.map(function(item) {
        if (typeof item === "string") {
          return { name: item, icon: iconMap[item] || "󰘳", label: item }
        }
        return item
      })
    }
    return defaultSpecials
  }

  readonly property string specialDisplayMode: String(root.setting("specialDisplayMode", "all"))
  readonly property bool isPrimaryMonitor: root.monitorId === 0
  readonly property bool shouldShowSpecials: {
    if (root.specialDisplayMode === "none") return false
    if (root.specialDisplayMode === "primaryOnly") return root.isPrimaryMonitor
    return true // "all" (default) or "allWhenOccupied"
  }

  property bool specialMenuOpen: false

  onSpecialMenuOpenChanged: {
    if (specialMenuOpen) {
      pickerFocusTimer.restart()
    }
  }

  Timer {
    id: pickerFocusTimer
    interval: 50
    onTriggered: {
      if (pickerCard) pickerCard.forceActiveFocus()
    }
  }

  function openSpecialMenu() {
    root.specialMenuOpen = true
  }

  function closeSpecialMenu() {
    root.specialMenuOpen = false
  }

  function toggleSpecialMenu() {
    root.specialMenuOpen = !root.specialMenuOpen
  }

  // -------------------------------------------------------------- Monitor Layout Preview
  // Only one preview overlay may be open across all monitors. This instance's
  // overlay is screen-anchored to the bar it lives on, so opening a preview
  // for a given monitor is done by right-clicking that monitor's own badge.
  //
  // Because a full-screen overlay covers only its own screen, a badge on any
  // other monitor remains reachable; right-clicking it closes whatever preview
  // is open elsewhere and opens one on that monitor instead. Re-right-clicking
  // the badge underneath the open overlay lands on the overlay, which dismisses
  // on right-click — yielding the toggle-close gesture. The broadcast methods
  // below coordinate across per-monitor instances so only one overlay exists.
  function previewOpenHere() {
    return layoutPreviewItem !== null && layoutPreviewItem.open
  }

  function closeAllPreviews() {
    root.broadcast("closeLayoutPreview")
  }

  // Open the preview on the monitor that currently holds global focus. Used by
  // the IPC `preview` entry point: broadcast to every per-monitor instance and
  // let the one whose bar is on the focused monitor do the opening.
  function openLayoutPreviewOnFocused() {
    root.broadcast("openLayoutPreviewIfFocused")
  }

  function openLayoutPreviewIfFocused() {
    var focused = Hyprland.focusedMonitor
    var focusedName = focused ? String(focused.name || "") : ""
    if (focusedName !== "" && focusedName === root.monitorName) {
      root.openLayoutPreviewHere()
    }
  }

  function toggleLayoutPreview() {
    if (root.previewOpenHere()) {
      // This badge's own overlay is open → toggle it off.
      root.closeAllPreviews()
      return
    }
    // No overlay here. If one is open on another monitor it is closed by the
    // open path below (closeAllPreviews), then we open on this monitor.
    root.openLayoutPreviewHere()
  }

  function openLayoutPreviewHere() {
    root.closeAllPreviews()
    if (layoutPreviewItem) {
      layoutPreviewItem.preselectMonitorId = root.monitorId
      layoutPreviewItem.openFor(root.monitorId)
    }
  }

  function closeLayoutPreview() {
    if (layoutPreviewItem) layoutPreviewItem.close()
  }

  function getDigitIndex(event) {
    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
      return event.key - Qt.Key_1
    }
    var shiftKeys = [
      Qt.Key_Exclam,      // 1 -> !
      Qt.Key_At,          // 2 -> @
      Qt.Key_NumberSign,  // 3 -> #
      Qt.Key_Dollar,      // 4 -> $
      Qt.Key_Percent,     // 5 -> %
      Qt.Key_AsciiCircum, // 6 -> ^
      Qt.Key_Ampersand,   // 7 -> &
      Qt.Key_Asterisk,    // 8 -> *
      Qt.Key_ParenLeft    // 9 -> (
    ]
    var sIdx = shiftKeys.indexOf(event.key)
    if (sIdx !== -1) return sIdx

    var ch = String(event.text || "")
    if (ch >= "1" && ch <= "9") return parseInt(ch, 10) - 1
    var syms = "!@#$%^&*("
    var symIdx = syms.indexOf(ch)
    if (symIdx !== -1) return symIdx

    return -1
  }

  // -------------------------------------------------------------- IPC Handler
  IpcHandler {
    target: "icyleaf.workspaces"

    function focus(slotStr: string): string {
      var slot = parseInt(String(slotStr), 10)
      if (isNaN(slot)) return "invalid slot"
      root.focusActiveMonitorWorkspace(slot)
      return "ok"
    }

    function move(slotStr: string): string {
      var slot = parseInt(String(slotStr), 10)
      if (isNaN(slot)) return "invalid slot"
      root.moveActiveMonitorWindow(slot, true)
      return "ok"
    }

    function movesilent(slotStr: string): string {
      var slot = parseInt(String(slotStr), 10)
      if (isNaN(slot)) return "invalid slot"
      root.moveActiveMonitorWindow(slot, false)
      return "ok"
    }

    function toggleSpecial(nameStr: string): string {
      var name = String(nameStr || "").trim()
      if (name === "") return "invalid name"
      root.toggleSpecial(name)
      return "ok"
    }

    function moveSpecial(nameStr: string): string {
      var name = String(nameStr || "").trim()
      if (name === "") return "invalid name"
      root.moveSpecial(name, false)
      return "ok"
    }

    function moveSpecialFollow(nameStr: string): string {
      var name = String(nameStr || "").trim()
      if (name === "") return "invalid name"
      root.moveSpecial(name, true)
      return "ok"
    }

    function selectSpecial(): string {
      root.toggleSpecialMenu()
      return "ok"
    }

    function toggleSpecialMenu(): string {
      root.toggleSpecialMenu()
      return "ok"
    }

    function preview(): string {
      // Summon the layout preview for the globally focused monitor. Only one
      // instance hosts the live IPC handler, so the actual open must happen on
      // whichever instance's bar belongs to the focused monitor — broadcast to
      // all instances and let each decide locally.
      root.openLayoutPreviewOnFocused()
      return "ok"
    }
  }

  // -------------------------------------------------------------- monitor anchor
  readonly property var barWindow: root.QsWindow ? root.QsWindow.window : null
  readonly property var monitor: barWindow && barWindow.screen ? Hyprland.monitorFor(barWindow.screen) : null
  readonly property int monitorId: monitor !== null && monitor.id !== undefined ? monitor.id : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.id : 0)
  readonly property string monitorName: monitor ? String(monitor.name || "") : ""
  readonly property string monitorDesc: monitor ? String(monitor.description || "") : ""
  readonly property bool isFocusedMonitor: monitor !== null && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.id === monitor.id

  readonly property int offset: monitorId * 10
  readonly property string monitorBadgeText: "󰍹 M" + (monitorId + 1)
  readonly property string monitorTooltip: {
    var desc = monitorDesc ? (monitorDesc + (monitorName ? " (" + monitorName + ")" : "")) : (monitorName ? monitorName : ("Monitor " + (monitorId + 1)))
    return desc + (isFocusedMonitor ? " · [Focused]" : "")
  }

  // Active Special Workspace on this monitor
  property string activeSpecialName: {
    if (root.monitor && root.monitor.lastIpcObject && root.monitor.lastIpcObject.specialWorkspace) {
      var n = String(root.monitor.lastIpcObject.specialWorkspace.name || "")
      if (n.indexOf("special:") === 0) return n.substring(8)
      return n
    }
    return ""
  }
  readonly property bool hasActiveSpecial: activeSpecialName !== ""

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && event.name === "activespecial") {
        var parts = String(event.data || "").split(",")
        var ws = parts[0] ? parts[0].trim() : ""
        var mon = parts[1] ? parts[1].trim() : ""
        if (mon === "" || mon === root.monitorName) {
          if (ws.indexOf("special:") === 0) {
            root.activeSpecialName = ws.substring(8)
          } else {
            root.activeSpecialName = ""
          }
        }
      }
    }
  }

  // -------------------------------------------------------------- App Icons
  // Each occupied workspace slot shows the icon of its largest window's app,
  // resolved by the pure AppIconModel seam. Terminal windows are probed with
  // `pstree` so the TUI app running inside them gets its own icon.
  readonly property bool showAppIcons: root.setting("showAppIcons", true) !== false
  readonly property bool monochromeIcons: root.setting("monochromeIcons", true) !== false
  readonly property real iconScale: {
    var value = Number(root.setting("iconScale", 1.0))
    return isFinite(value) && value > 0 ? value : 1.0
  }
  readonly property int iconSize: Math.max(8, Math.round(Style.space(12) * root.iconScale))
  readonly property var iconOverrides: AppIconModel.normalizeIconOverrides(root.setting("iconOverrides", []))

  property var bundledIcons: ({})
  property var clientInfo: ({})
  property var probeCache: ({})
  property var probeQueue: []
  property int probeBusyPid: 0
  property int probeTick: 0
  property int syncToken: 0

  readonly property color iconTintColor: root.bar ? root.bar.barForeground : Color.foreground
  readonly property bool isLightTheme: {
    var color = root.bar ? root.bar.background : Color.background
    var tint = Qt.color(color)
    return (tint.r * 0.299 + tint.g * 0.587 + tint.b * 0.114) > 0.5
  }
  // On light themes (and transparent bars) icons keep their own colours: a
  // tinted monochrome mark would not read against a light bar.
  readonly property bool tintIcons: root.monochromeIcons
    && !(root.bar ? root.bar.transparent : false) && !root.isLightTheme
  readonly property string genericIcon: Quickshell.iconPath("application-x-executable", true)

  function bumpSync() { root.syncToken++ }

  function probeNameList() {
    return AppIconModel.probeNames(root.iconOverrides, root.bundledIcons, AppIconModel.knownTuiApps())
  }

  function resolveProcessIcon(name) {
    return AppIconModel.resolveProcessIcon(name, root.iconOverrides, root.bundledIcons)
  }

  function biggestWindowFor(workspace) {
    if (!workspace || !workspace.toplevels) return null
    return AppIconModel.biggestWindow(workspace.toplevels.values, root.clientInfo)
  }

  // Process name detected inside a window's process tree, or "" when it was
  // not probed yet or runs no known TUI app.
  function windowProbeName(toplevel) {
    var pid = AppIconModel.windowPid(toplevel, root.clientInfo)
    if (pid <= 0) return ""
    return root.probeCache[String(pid)] || ""
  }

  // Final icon source for a slot. A probed TUI process wins: an explicit
  // override or bundled file first, then the process name itself against the
  // icon theme. With no probe match, the window class is resolved against
  // desktop entries and the theme, falling back to a generic executable icon.
  function windowIconSource(toplevel) {
    if (!toplevel) return ""
    var probeName = root.windowProbeName(toplevel)
    if (probeName !== "") {
      var resolved = root.resolveProcessIcon(probeName)
      if (resolved !== "") return Qt.resolvedUrl(resolved)
      var themed = root.iconUrlForName(probeName)
      if (themed) return themed
    }
    return root.iconSourceForClass(AppIconModel.windowClass(toplevel, root.clientInfo))
  }

  function iconUrlForName(name) {
    var value = String(name || "")
    if (!value) return ""
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return Util.fileUrl(value)
    return Quickshell.iconPath(value, true)
  }

  function desktopEntryForClass(klass) {
    var candidates = AppIconModel.iconNameCandidates(klass)
    for (var i = 0; i < candidates.length; i++) {
      try {
        var entry = DesktopEntries.byId(candidates[i])
        if (entry) return entry
      } catch (error) {
      }
    }
    try {
      var applications = DesktopEntries.applications.values
      var lower = String(klass || "").toLowerCase()
      for (var j = 0; j < applications.length; j++) {
        var startupClass = String(applications[j].startupClass || "")
        if (startupClass && startupClass.toLowerCase() === lower) return applications[j]
      }
    } catch (error2) {
    }
    return null
  }

  function iconSourceForClass(klass) {
    var value = String(klass || "")
    var entry = root.desktopEntryForClass(value)
    if (entry && entry.icon) {
      var fromEntry = root.iconUrlForName(String(entry.icon))
      if (fromEntry) return fromEntry
    }
    var candidates = AppIconModel.iconNameCandidates(value)
    for (var i = 0; i < candidates.length; i++) {
      var source = root.iconUrlForName(candidates[i])
      if (source) return source
    }
    return root.genericIcon
  }

  function scanBundledIcons() {
    if (iconScanProcess.running) return
    var dir = String(Qt.resolvedUrl("icons")).replace(/^file:\/\//, "")
    iconScanProcess.command = ["bash", "-c", "ls -1 '" + dir.replace(/'/g, "") + "' 2>/dev/null"]
    iconScanProcess.running = true
  }

  // Bundled icons can change without touching the probe cache: the cache holds
  // detected process names, and the icon is re-resolved on every probeTick, so
  // nothing is blanked and no terminal↔app flicker is introduced.
  function onIconsScanned(text) {
    root.bundledIcons = AppIconModel.scanIconListing(text)
    root.probeTick++
  }

  function onClientsFetched(text) {
    root.clientInfo = AppIconModel.parseClients(text)
    root.pumpProbe()
  }

  function pumpProbe() {
    if (root.probeBusyPid !== 0 || root.probeQueue.length === 0) return
    root.probeBusyPid = root.probeQueue.shift()
    probeProcess.command = ["bash", "-c",
      AppIconModel.buildProbeCommand(root.probeBusyPid, root.probeNameList())]
    probeProcess.running = true
  }

  // Queue one process-tree probe per occupied workspace on THIS monitor only,
  // using the workspace's largest window. Dead pids are pruned, but the cache
  // is never blanked before a fresh probe lands, so icons never flicker.
  function probeOverrideWindows() {
    if (root.probeNameList().length === 0) return
    var seen = {}
    var wanted = []
    for (var slot = 1; slot <= 10; slot++) {
      var workspace = root.workspaceById(root.offset + slot)
      if (!workspace || !workspace.toplevels) continue
      var pid = AppIconModel.windowPid(root.biggestWindowFor(workspace), root.clientInfo)
      if (pid <= 0 || seen[pid]) continue
      seen[pid] = true
      wanted.push(pid)
    }
    var pruned = {}
    for (var key in root.probeCache) {
      if (seen[Number(key)]) pruned[key] = root.probeCache[key]
    }
    root.probeCache = pruned
    for (var i = 0; i < wanted.length; i++) {
      var wantedPid = wanted[i]
      if (wantedPid === root.probeBusyPid || root.probeQueue.indexOf(wantedPid) !== -1) continue
      root.probeQueue.push(wantedPid)
    }
    if (!clientFetchProcess.running) clientFetchProcess.running = true
  }

  Timer {
    id: probeTimer
    interval: 3000
    repeat: true
    running: root.probeNameList().length > 0
    onTriggered: root.probeOverrideWindows()
  }

  Timer {
    interval: 30000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.scanBundledIcons()
  }

  // One reused process scans one window per run; results are attributed via
  // probeBusyPid rather than by timing assumptions.
  Process {
    id: probeProcess
    stdout: StdioCollector {
      id: probeCollector
      waitForEnd: true
    }
    onExited: function() {
      if (root.probeBusyPid !== 0) {
        // Store the detected process name, not the resolved icon, so icon
        // resolution can be re-run later without re-probing the process tree.
        root.probeCache[String(root.probeBusyPid)] = AppIconModel.parseProbeOutput(probeCollector.text)
        root.probeTick++
      }
      root.probeBusyPid = 0
      root.pumpProbe()
    }
  }

  Process {
    id: iconScanProcess
    stdout: StdioCollector {
      id: iconScanCollector
      waitForEnd: true
    }
    onExited: function() {
      root.onIconsScanned(iconScanCollector.text)
    }
  }

  // Live pid/area/class for every window, keyed by hex address. Quickshell only
  // fills lastIpcObject during its initial sync, so this covers windows opened
  // after the shell started.
  Process {
    id: clientFetchProcess
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      id: clientFetchCollector
      waitForEnd: true
    }
    onExited: function() {
      root.onClientsFetched(clientFetchCollector.text)
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event) return
      var name = String(event.name || "")
      if (name === "openwindow" || name === "closewindow" || name === "movewindow"
          || name === "createworkspace" || name === "destroyworkspace") {
        root.bumpSync()
        root.probeOverrideWindows()
        return
      }
      if (name === "workspace" || name === "focusedworkspace"
          || name === "activewindow" || name === "urgent" || name === "activespecial") {
        root.bumpSync()
      }
    }
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function specialWorkspaceByName(name) {
    var targetName = "special:" + name
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (String(values[i].name) === targetName) return values[i]
    }
    return null
  }

  function isSpecialActive(name) {
    return root.activeSpecialName === String(name || "")
  }

  // -------------------------------------------------------------- actions & ipc
  function quoteLua(value) {
    return "\"" + String(value)
      .replace(/\\/g, "\\\\")
      .replace(/"/g, "\\\"")
      .replace(/\n/g, "\\n")
      .replace(/\r/g, "\\r")
      + "\""
  }

  function runLua(body) {
    Hyprland.dispatch("function() " + body + " end")
  }

  function focusMonitor() {
    if (!root.monitorName) return
    root.runLua("hl.dispatch(hl.dsp.focus({ monitor = " + root.quoteLua(root.monitorName) + " }))")
  }

  function focusWorkspace(slot) {
    var wsId = root.offset + slot
    if (!root.monitorName) {
      root.runLua("hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua(String(wsId)) + " }))")
      return
    }
    root.runLua("hl.dispatch(hl.dsp.focus({ monitor = " + root.quoteLua(root.monitorName) + " })); "
      + "hl.dispatch(hl.dsp.workspace.move({ workspace = " + root.quoteLua(String(wsId)) + ", monitor = " + root.quoteLua(root.monitorName) + " })); "
      + "hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua(String(wsId)) + " }));")
  }

  function moveWindowTo(slot) {
    var wsId = root.offset + slot
    if (!root.monitorName) return
    root.runLua("local w = hl.get_active_window(); if not w then return end; "
      + "hl.dispatch(hl.dsp.workspace.move({ workspace = " + root.quoteLua(String(wsId)) + ", monitor = " + root.quoteLua(root.monitorName) + " })); "
      + "hl.dispatch(hl.dsp.window.move({ workspace = " + root.quoteLua(String(wsId)) + ", window = \"address:\" .. w.address, follow = false }));")
  }

  function focusActiveMonitorWorkspace(slot) {
    var mon = Hyprland.focusedMonitor
    if (!mon) return
    var monName = String(mon.name || "")
    var monId = mon.id !== undefined ? mon.id : 0
    var wsId = monId * 10 + slot

    if (monName === "") {
      root.runLua("hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua(String(wsId)) + " }))")
      return
    }
    root.runLua("hl.dispatch(hl.dsp.focus({ monitor = " + root.quoteLua(monName) + " })); "
      + "hl.dispatch(hl.dsp.workspace.move({ workspace = " + root.quoteLua(String(wsId)) + ", monitor = " + root.quoteLua(monName) + " })); "
      + "hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua(String(wsId)) + " }));")
  }

  function moveActiveMonitorWindow(slot, follow) {
    var mon = Hyprland.focusedMonitor
    if (!mon) return
    var monName = String(mon.name || "")
    var monId = mon.id !== undefined ? mon.id : 0
    var wsId = monId * 10 + slot

    root.runLua("local w = hl.get_active_window(); if not w then return end; "
      + "hl.dispatch(hl.dsp.workspace.move({ workspace = " + root.quoteLua(String(wsId)) + ", monitor = " + root.quoteLua(monName) + " })); "
      + "hl.dispatch(hl.dsp.window.move({ workspace = " + root.quoteLua(String(wsId)) + ", window = \"address:\" .. w.address, follow = " + (follow ? "true" : "false") + " }));")
  }

  function toggleSpecial(name) {
    root.runLua("hl.dispatch(hl.dsp.workspace.toggle_special(" + root.quoteLua(name) + "))")
  }

  function moveSpecial(name, follow) {
    root.runLua("local w = hl.get_active_window(); if not w then return end; "
      + "hl.dispatch(hl.dsp.window.move({ workspace = " + root.quoteLua("special:" + name)
      + ", window = \"address:\" .. w.address, follow = " + (follow ? "true" : "false") + " }));")
  }

  // -------------------------------------------------------------- wheel cycling
  property real wheelAccumulator: 0

  function cycleBy(step) {
    var currentSlot = 1
    if (root.monitor && root.monitor.activeWorkspace) {
      var activeId = root.monitor.activeWorkspace.id
      var rel = activeId - root.offset
      if (rel >= 1 && rel <= 10) currentSlot = rel
    }
    var nextSlot = ((currentSlot - 1 + step) % 10 + 10) % 10 + 1
    root.focusWorkspace(nextSlot)
  }

  function onWheel(delta) {
    var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
    root.wheelAccumulator = wheel.remainder
    if (wheel.steps !== 0) root.cycleBy(wheel.steps > 0 ? -1 : 1)
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: layoutContainer.implicitWidth + trailingGap
  implicitHeight: layoutContainer.implicitHeight

  RowLayout {
    id: layoutContainer
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    spacing: Style.space(1)

    // Monitor Badge Pill
    WidgetButton {
      bar: root.bar
      text: root.monitorBadgeText
      useActiveColor: false
      tooltipText: root.monitorTooltip
      opacity: root.isFocusedMonitor ? 1.0 : 0.5
      horizontalMargin: 6
      verticalPadding: 6
      fixedWidth: root.vertical ? root.barSize : Style.space(34)
      fixedHeight: root.barSize
      onPressed: function(button) {
        if (button === Qt.RightButton) {
          root.toggleLayoutPreview()
        } else {
          root.focusMonitor()
        }
      }
      onWheelMoved: function(delta) { root.onWheel(delta) }
    }

    // 1..10 Regular Workspaces
    Repeater {
      model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      WidgetButton {
        id: wsSlot
        required property int modelData

        readonly property int wsId: root.offset + modelData
        // Hyprland collections are constant (non-notifying) models, so the
        // syncToken/clientInfo reads force this binding to re-evaluate when
        // windows and workspace occupancy change.
        readonly property var workspace: {
          var _sync = root.syncToken
          var _clients = root.clientInfo
          return root.workspaceById(wsId)
        }
        readonly property bool occupied: workspace !== null && workspace.toplevels && workspace.toplevels.values.length > 0
        readonly property bool activeOnMonitor: root.monitor !== null && root.monitor.activeWorkspace !== null && root.monitor.activeWorkspace.id === wsId
        readonly property bool focusedGlobally: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
        readonly property bool isActive: activeOnMonitor || focusedGlobally
        readonly property var biggestWindow: root.biggestWindowFor(workspace)
        readonly property string iconSource: {
          var _tick = root.probeTick
          var _clients = root.clientInfo
          return root.showAppIcons ? root.windowIconSource(biggestWindow) : ""
        }
        readonly property bool showsIcon: root.showAppIcons && occupied && iconSource !== ""

        bar: root.bar
        text: (isActive && !showsIcon) ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        labelVisible: !showsIcon
        useActiveColor: false
        tooltipText: "Workspace " + wsId + " (Slot " + (modelData === 10 ? 0 : modelData) + ")"
        opacity: showsIcon ? (isActive ? 1.0 : 0.9) : (isActive || occupied ? 1.0 : 0.4)
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function(button) {
          if (button === Qt.RightButton) {
            root.moveWindowTo(modelData)
          } else {
            root.focusWorkspace(modelData)
          }
        }
        onWheelMoved: function(delta) { root.onWheel(delta) }

        // Largest window's app icon for an occupied slot.
        Item {
          id: wsIconHost
          anchors.centerIn: parent
          width: root.iconSize
          height: root.iconSize
          visible: wsSlot.showsIcon

          Image {
            id: wsIcon
            anchors.fill: parent
            source: wsSlot.iconSource
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            sourceSize.width: Math.round(root.iconSize * Screen.devicePixelRatio)
            sourceSize.height: Math.round(root.iconSize * Screen.devicePixelRatio)
            smooth: true
            layer.enabled: root.monochromeIcons
            layer.smooth: true
          }

          MultiEffect {
            anchors.fill: parent
            source: wsIcon
            visible: root.monochromeIcons
            colorization: root.tintIcons ? 1.0 : 0.0
            colorizationColor: root.iconTintColor
          }
        }

        // Active indicator line when the slot is showing an icon instead of
        // the active glyph.
        Rectangle {
          visible: wsSlot.showsIcon && wsSlot.isActive
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottomMargin: Style.space(1)
          width: Style.space(12)
          height: Style.space(2)
          radius: Style.space(1)
          color: root.bar ? root.bar.barForeground : Color.foreground
        }
      }
    }

    // Separator before Specials
    Rectangle {
      visible: root.shouldShowSpecials && root.specialsList.length > 0
      implicitWidth: root.vertical ? (root.barSize - Style.space(8)) : 1
      implicitHeight: root.vertical ? 1 : Style.space(12)
      Layout.alignment: Qt.AlignVCenter
      color: Util.alpha(root.bar ? root.bar.barForeground : Color.foreground, 0.2)
    }

    // Special Workspaces (Scratchpads)
    Repeater {
      model: root.shouldShowSpecials ? root.specialsList : []

      WidgetButton {
        required property var modelData

        readonly property string specialName: String(modelData.name || "")
        readonly property string specialIcon: String(modelData.icon || "󰘳")
        readonly property var ws: root.specialWorkspaceByName(specialName)
        readonly property bool occupied: ws !== null && ws.toplevels && ws.toplevels.values.length > 0
        readonly property bool activeOnScreen: root.isSpecialActive(specialName)

        visible: {
          if (root.specialDisplayMode === "allWhenOccupied" && !root.isPrimaryMonitor) {
            return occupied || activeOnScreen
          }
          return true
        }

        bar: root.bar
        text: specialIcon
        active: activeOnScreen
        useActiveColor: false
        tooltipText: "Special: " + specialName + (activeOnScreen ? " [Active]" : (occupied ? " (" + ws.toplevels.values.length + " windows)" : " [Empty]"))
        opacity: activeOnScreen ? 1.0 : (occupied ? 0.7 : 0.35)
        horizontalMargin: 4
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function(button) {
          if (button === Qt.RightButton) {
            root.moveSpecial(specialName, false)
          } else {
            root.toggleSpecial(specialName)
          }
        }

        // Active indicator line
        Rectangle {
          visible: activeOnScreen
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottomMargin: Style.space(1)
          width: Style.space(12)
          height: Style.space(2)
          radius: Style.space(1)
          color: root.bar ? root.bar.barForeground : Color.foreground
        }
      }
    }
  }

  // -------------------------------------------------------------- Quick Picker Overlay (SUPER + ALT + S)
  PanelWindow {
    id: specialPickerWindow
    visible: root.specialMenuOpen && root.isPrimaryMonitor
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "icyleaf.workspaces.picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.specialMenuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Util.alpha(Color.background, 0.55)
      opacity: root.specialMenuOpen ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 120 } }

      MouseArea {
        anchors.fill: parent
        onClicked: root.closeSpecialMenu()
      }

      Rectangle {
        id: pickerCard
        anchors.centerIn: parent
        width: Style.space(380)
        implicitHeight: pickerContent.implicitHeight + Style.space(32)
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : 12
        color: Color.surface || Color.background
        border.width: 1
        border.color: Util.alpha(Color.foreground, 0.18)
        focus: root.specialMenuOpen

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.closeSpecialMenu()
            event.accepted = true
            return
          }
          var digitIdx = root.getDigitIndex(event)
          if (digitIdx >= 0 && digitIdx < root.specialsList.length) {
            var item = root.specialsList[digitIdx]
            var specialName = String(item.name || "")
            if (event.modifiers & Qt.ShiftModifier) {
              root.moveSpecial(specialName, false)
            } else {
              root.toggleSpecial(specialName)
            }
            root.closeSpecialMenu()
            event.accepted = true
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) {}
        }

        ColumnLayout {
          id: pickerContent
          anchors.fill: parent
          anchors.margins: Style.space(16)
          spacing: Style.space(12)

          // Header
          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "󰘳  SPECIAL SCRATCHPADS"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              color: Util.alpha(Color.foreground, 0.6)
            }
            Item { Layout.fillWidth: true }
            Text {
              text: "Esc to close"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Util.alpha(Color.foreground, 0.4)
            }
          }

          // Specials List
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Repeater {
              model: root.specialsList

              Rectangle {
                required property var modelData
                required property int index

                readonly property string spName: String(modelData.name || "")
                readonly property string spIcon: String(modelData.icon || "󰘳")
                readonly property var spWs: root.specialWorkspaceByName(spName)
                readonly property int winCount: (spWs && spWs.toplevels) ? spWs.toplevels.values.length : 0
                readonly property bool isActive: root.isSpecialActive(spName)
                readonly property bool isHovered: itemMouse.containsMouse

                Layout.fillWidth: true
                implicitHeight: Style.space(38)
                radius: 8
                color: isActive ? Util.alpha(Color.foreground, 0.12) : (isHovered ? Util.alpha(Color.foreground, 0.06) : "transparent")
                border.width: isActive ? 1 : 0
                border.color: Util.alpha(Color.foreground, 0.25)

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  spacing: Style.space(10)

                  // Number badge [1]
                  Rectangle {
                    implicitWidth: Style.space(22)
                    implicitHeight: Style.space(22)
                    radius: 4
                    color: Util.alpha(Color.foreground, 0.08)
                    border.width: 1
                    border.color: Util.alpha(Color.foreground, 0.15)
                    Text {
                      anchors.centerIn: parent
                      text: String(index + 1)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                      color: Color.foreground
                    }
                  }

                  // Icon
                  Text {
                    text: spIcon
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    color: Color.foreground
                  }

                  // Name
                  Text {
                    text: spName
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    color: Color.foreground
                  }

                  Item { Layout.fillWidth: true }

                  // Status
                  Text {
                    text: isActive ? "Active" : (winCount > 0 ? (winCount + (winCount === 1 ? " window" : " windows")) : "empty")
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: isActive ? Color.foreground : Util.alpha(Color.foreground, 0.5)
                  }
                }

                MouseArea {
                  id: itemMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                      root.moveSpecial(spName, false)
                    } else {
                      root.toggleSpecial(spName)
                    }
                    root.closeSpecialMenu()
                  }
                }
              }
            }
          }

          // Footer
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Util.alpha(Color.foreground, 0.1)
          }

          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "⌨ 1-4 Switch · Shift+1-4 Move"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Util.alpha(Color.foreground, 0.45)
            }
            Item { Layout.fillWidth: true }
            Text {
              text: "🖱 Left: Toggle · Right: Move"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Util.alpha(Color.foreground, 0.45)
            }
          }
        }
      }
    }
  }

  // -------------------------------------------------------------- Monitor Layout Preview Overlay
  // One full-screen preview per widget instance, anchored to this instance's
  // own bar screen (each bar surface sits on exactly one monitor). Only the
  // instance whose badge is right-clicked opens its overlay.
  MonitorPreview {
    id: layoutPreviewItem
    hostBar: root.bar
  }
}
