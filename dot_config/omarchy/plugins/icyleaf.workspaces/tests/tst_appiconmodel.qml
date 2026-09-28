import QtQuick 2.15
import QtTest 1.3
import "../AppIconModel.js" as AppIconModel

TestCase {
  id: root
  name: "AppIconModel"

  // ── Process name sanitization / override normalization ──────────────────

  function test_sanitizeProcessNameLowercasesAndStripsUnsafeChars() {
    compare(AppIconModel.sanitizeProcessName("NeoVim"), "neovim")
    compare(AppIconModel.sanitizeProcessName(" my app! "), "myapp")
    compare(AppIconModel.sanitizeProcessName("foo-bar_baz"), "foo-bar_baz")
    compare(AppIconModel.sanitizeProcessName("$(rm -rf /)"), "rm-rf")
    compare(AppIconModel.sanitizeProcessName(""), "")
    compare(AppIconModel.sanitizeProcessName(null), "")
  }

  function test_normalizeIconOverridesDropsInvalidEntries() {
    var out = AppIconModel.normalizeIconOverrides([
      { process: "nvim", icon: "icons/neovim.png" },
      { process: "NVIM", icon: "icons/neovim.svg" },
      { process: "", icon: "icons/x.png" },
      { process: "yazi", icon: "" },
      null,
      { process: "k9s", icon: "icons/k9s.png" }
    ])
    compare(out.length, 3)
    compare(out[0].process, "nvim")
    compare(out[0].icon, "icons/neovim.png")
    compare(out[1].process, "nvim")
    compare(out[2].process, "k9s")
  }

  function test_normalizeIconOverridesHandlesNonArray() {
    compare(AppIconModel.normalizeIconOverrides(null).length, 0)
    compare(AppIconModel.normalizeIconOverrides(undefined).length, 0)
    compare(AppIconModel.normalizeIconOverrides("nope").length, 0)
  }

  // ── Probe name list ──────────────────────────────────────────────────────
  // Order is overrides → bundled basenames → curated defaults; duplicates and
  // unsafe characters are removed so a name can never break the probe regex.

  function test_probeNamesDeduplicatesAndOrders() {
    var names = AppIconModel.probeNames(
      [{ process: "customtool", icon: "icons/customtool.png" }],
      { btop: "btop.png", lazygit: "lazygit.svg" },
      ["btop", "nvim", "Vim!"]
    )
    compare(names[0], "customtool")
    compare(names[1], "btop")
    compare(names[2], "lazygit")
    compare(names[3], "nvim")
    compare(names[4], "vim")
    compare(names.length, 5)
  }

  function test_probeNamesEmptyWhenNoSources() {
    compare(AppIconModel.probeNames([], {}, []).length, 0)
    compare(AppIconModel.probeNames(null, null, null).length, 0)
  }

  // ── Probe command and output parsing ─────────────────────────────────────

  function test_buildProbeCommandTargetsPidAndNames() {
    var cmd = AppIconModel.buildProbeCommand(1234, ["btop", "nvim"])
    verify(cmd.indexOf("pstree -p 1234") !== -1)
    verify(cmd.indexOf("(btop|nvim)") !== -1)
  }

  function test_buildProbeCommandSanitizesInjectedNames() {
    var cmd = AppIconModel.buildProbeCommand(7, ["$(rm -rf /)", "foo;bar"])
    verify(cmd.indexOf("$(") === -1)
    verify(cmd.indexOf(";") === -1)
    verify(cmd.indexOf("rm-rf") !== -1)
    verify(cmd.indexOf("foobar") !== -1)
  }

  function test_buildProbeCommandWithNoNamesCannotMatchEverything() {
    var cmd = AppIconModel.buildProbeCommand(7, [])
    verify(cmd.indexOf("pstree -p 7") !== -1)
    // No empty alternation like "()" that would match every process line.
    verify(cmd.indexOf("()") === -1)
  }

  function test_parseProbeOutputTakesFirstSanitizedMatch() {
    compare(AppIconModel.parseProbeOutput("lazygit\n"), "lazygit")
    compare(AppIconModel.parseProbeOutput("btop\nsomething"), "btop")
    compare(AppIconModel.parseProbeOutput("BT-OP\n"), "bt-op")
    compare(AppIconModel.parseProbeOutput(""), "")
    compare(AppIconModel.parseProbeOutput("   \n"), "")
    compare(AppIconModel.parseProbeOutput(null), "")
  }

  // ── hyprctl clients parsing ──────────────────────────────────────────────

  function test_parseClientsBuildsAddressMapWithAreaAndClass() {
    var map = AppIconModel.parseClients(JSON.stringify([
      { address: "0xabc", pid: 42, size: [100, 200], class: "kitty" },
      { address: "0xDEF", pid: 0, size: [0, 0], class: "" }
    ]))
    compare(map["0xabc"].pid, 42)
    compare(map["0xabc"].area, 20000)
    compare(map["0xabc"].klass, "kitty")
    compare(map["0xdef"].pid, 0)
    compare(map["0xdef"].area, 0)
  }

  function test_parseClientsToleratesGarbageAndMissingFields() {
    compare(Object.keys(AppIconModel.parseClients("not json")).length, 0)
    compare(Object.keys(AppIconModel.parseClients("")).length, 0)
    compare(Object.keys(AppIconModel.parseClients("null")).length, 0)
    var map = AppIconModel.parseClients(JSON.stringify([{ address: "0x1" }]))
    compare(map["0x1"].pid, 0)
    compare(map["0x1"].area, 0)
    compare(map["0x1"].klass, "")
  }

  // ── Biggest window selection ─────────────────────────────────────────────

  function test_biggestWindowPrefersLiveClientArea() {
    var clientInfo = {
      "0x10": { pid: 1, area: 100, klass: "small" },
      "0x20": { pid: 2, area: 5000, klass: "big" }
    }
    var tls = [
      { address: "0x10", title: "first", size: [100, 100] },
      { address: "0x20", title: "second", size: [100, 100] }
    ]
    compare(AppIconModel.biggestWindow(tls, clientInfo).title, "second")
  }

  function test_biggestWindowFallsBackToToplevelSize() {
    var clientInfo = { "0x20": { pid: 2, area: 900, klass: "b" } }
    var tls = [
      { address: "0x10", title: "large-by-size", size: [800, 600] },
      { address: "0x20", title: "small-live", size: [300, 300] }
    ]
    compare(AppIconModel.biggestWindow(tls, clientInfo).title, "large-by-size")
  }

  function test_biggestWindowReadsSizeFromLastIpcObject() {
    var tls = [
      { address: "0x1", title: "stale", lastIpcObject: { size: [10, 10] } },
      { address: "0x2", title: "fresh", lastIpcObject: { size: [500, 500] } }
    ]
    compare(AppIconModel.biggestWindow(tls, {}).title, "fresh")
  }

  function test_biggestWindowEmptyReturnsNull() {
    compare(AppIconModel.biggestWindow([], {}), null)
    compare(AppIconModel.biggestWindow(null, {}), null)
  }

  function test_windowPidPrefersLiveClientInfoThenIpc() {
    var clientInfo = { "0x20": { pid: 2, area: 0, klass: "" } }
    compare(AppIconModel.windowPid({ address: "0x20", lastIpcObject: { pid: 9 } }, clientInfo), 2)
    compare(AppIconModel.windowPid({ address: "0x99", lastIpcObject: { pid: 9 } }, clientInfo), 9)
    compare(AppIconModel.windowPid(null, clientInfo), 0)
  }

  function test_windowClassFallbackChain() {
    var clientInfo = { "0x20": { pid: 2, area: 0, klass: "live-class" } }
    compare(AppIconModel.windowClass({ address: "0x20" }, clientInfo), "live-class")
    compare(AppIconModel.windowClass({ address: "0x99", class: "ipc-class" }, clientInfo), "ipc-class")
    compare(AppIconModel.windowClass({ address: "0x99", lastIpcObject: { class: "nested" } }, clientInfo), "nested")
    compare(AppIconModel.windowClass({ address: "0x99", wayland: { appId: "app-id" } }, clientInfo), "app-id")
    compare(AppIconModel.windowClass({ address: "0x99", title: "just title" }, clientInfo), "just title")
  }

  // ── Bundled icons directory scan ─────────────────────────────────────────

  function test_scanIconListingKeepsPngAndSvgByBasename() {
    var map = AppIconModel.scanIconListing(
      "claude.png\nopencode.svg\nREADME.md\n.svg\ndir.png/\nFoo.PNG\nclaude.svg\n")
    compare(map["claude"], "claude.png")
    compare(map["opencode"], "opencode.svg")
    compare(map["foo"], "Foo.PNG")
    compare(map["readme"], undefined)
    compare(map["dir"], undefined)
  }

  // ── Process name -> icon resolution ──────────────────────────────────────

  function test_resolveProcessIconOverrideBeatsBundled() {
    var overrides = AppIconModel.normalizeIconOverrides([
      { process: "nvim", icon: "icons/neovim.png" }
    ])
    var bundled = { claude: "claude.png", nvim: "nvim.png" }
    compare(AppIconModel.resolveProcessIcon("NVIM", overrides, bundled), "icons/neovim.png")
    compare(AppIconModel.resolveProcessIcon("claude", overrides, bundled), "icons/claude.png")
    compare(AppIconModel.resolveProcessIcon("unknown", overrides, bundled), "")
    compare(AppIconModel.resolveProcessIcon("", overrides, bundled), "")
    compare(AppIconModel.resolveProcessIcon(null, overrides, bundled), "")
  }

  // ── Window class -> icon name candidates ─────────────────────────────────

  function test_iconNameCandidatesOrderAndDedup() {
    compare(AppIconModel.iconNameCandidates("com.spotify.Client").join("|"),
      "com.spotify.Client|com.spotify.client|Client|client")
    compare(AppIconModel.iconNameCandidates("zen").join("|"), "zen")
    compare(AppIconModel.iconNameCandidates("Code").join("|"), "Code|code")
    compare(AppIconModel.iconNameCandidates("").length, 0)
    compare(AppIconModel.iconNameCandidates(null).length, 0)
  }

  // ── Curated TUI app list ─────────────────────────────────────────────────

  function test_knownTuiAppsExcludesShellsAndMultiplexers() {
    var apps = AppIconModel.knownTuiApps()
    verify(apps.indexOf("btop") !== -1)
    verify(apps.indexOf("nvim") !== -1)
    verify(apps.indexOf("yazi") !== -1)
    verify(apps.indexOf("claude") !== -1)
    verify(apps.indexOf("bash") === -1)
    verify(apps.indexOf("zsh") === -1)
    verify(apps.indexOf("fish") === -1)
    verify(apps.indexOf("tmux") === -1)
    verify(apps.indexOf("screen") === -1)
  }

  function test_knownTuiAppsAreProbeSafe() {
    var apps = AppIconModel.knownTuiApps()
    for (var i = 0; i < apps.length; i++)
      compare(AppIconModel.sanitizeProcessName(apps[i]), apps[i])
  }
}
