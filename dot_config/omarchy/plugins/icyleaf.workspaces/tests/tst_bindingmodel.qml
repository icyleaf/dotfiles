import QtQuick 2.15
import QtTest 1.3
import "../BindingModel.js" as BindingModel

TestCase {
  id: root
  name: "BindingModel"

  function monitor(id, name, description, extra) {
    var m = {
      id: id,
      name: name,
      description: description,
      enabled: true,
      mirrored: false,
      offset: id * 10
    }
    if (extra) {
      for (var key in extra) m[key] = extra[key]
    }
    return m
  }

  function sampleMonitors() {
    return [
      monitor(0, "DP-1", "LG Electronics LG HDR 4K 0x0001C243"),
      monitor(1, "DP-2", "LG Electronics LG HDR 4K 0x0000323A"),
      monitor(2, "eDP-1", "Tianma Microelectronics Ltd. TL140ADXP24-0")
    ]
  }

  // ------------------------------------------------------------- normalize

  function test_normalizeDropsInvalidEntries() {
    var out = BindingModel.normalizeBindings([
      { class: "^discord$", target: { monitor: { name: "DP-1" }, slot: 10 }, focus: true },
      { class: "", target: { monitor: { id: 0 }, slot: 9 } },
      { class: "^x$", target: { monitor: {}, slot: 9 } },
      { class: "^y$", target: { monitor: { id: 0, name: "DP-1" }, slot: 9 } },
      { class: "^z$", target: { monitor: { id: 0 }, slot: 0 } },
      { class: "^w$", target: { monitor: { id: 0 }, slot: 11 } },
      { class: "^v$", target: { monitor: { id: 0 }, slot: 9 }, focus: "yes" }
    ])
    compare(out.length, 2)
    compare(out[0].class, "^discord$")
    compare(out[0].matcher.kind, "name")
    compare(out[0].matcher.value, "DP-1")
    compare(out[0].slot, 10)
    compare(out[0].focus, true)
    compare(out[1].class, "^v$")
    compare(out[1].focus, false)
  }

  function test_normalizeHandlesNonArray() {
    compare(BindingModel.normalizeBindings(null).length, 0)
    compare(BindingModel.normalizeBindings(undefined).length, 0)
    compare(BindingModel.normalizeBindings("nope").length, 0)
    compare(BindingModel.normalizeBindings({ bindings: [] }).length, 0)
  }

  function test_normalizeDropsUncompilableRegex() {
    var out = BindingModel.normalizeBindings([
      { class: "([", target: { monitor: { id: 0 }, slot: 1 } },
      { class: "bogus title (", title: "(", target: { monitor: { id: 0 }, slot: 1 } }
    ])
    compare(out.length, 0)
  }

  function test_normalizeTruncatesFloatSlot() {
    var out = BindingModel.normalizeBindings([
      { class: "^a$", target: { monitor: { id: 0 }, slot: 3.9 } }
    ])
    compare(out.length, 1)
    compare(out[0].slot, 3)
  }

  function test_normalizeKeepsOptionalTitle() {
    var out = BindingModel.normalizeBindings([
      { class: "^chrome-.*$", title: "(LINE|Line)", target: { monitor: { desc: "YTH" }, slot: 8 } }
    ])
    compare(out.length, 1)
    compare(out[0].title, "(LINE|Line)")
    compare(out[0].matcher.kind, "desc")
    compare(out[0].matcher.value, "YTH")
  }

  // ---------------------------------------------------------- class matching

  function test_classIsAnchored() {
    var bindings = BindingModel.normalizeBindings([
      { class: "discord", target: { monitor: { id: 0 }, slot: 1 } }
    ])
    compare(BindingModel.resolve(bindings, { initialClass: "discord" }, sampleMonitors()).status, "apply")
    compare(BindingModel.resolve(bindings, { initialClass: "discord-canary" }, sampleMonitors()).status, "none")
    compare(BindingModel.resolve(bindings, { initialClass: "xdiscord" }, sampleMonitors()).status, "none")
  }

  function test_classRegexMatches() {
    var bindings = BindingModel.normalizeBindings([
      { class: "^chrome-.*$", target: { monitor: { id: 0 }, slot: 1 } }
    ])
    compare(BindingModel.resolve(bindings, { initialClass: "chrome-abc__-LINE" }, sampleMonitors()).status, "apply")
  }

  // ------------------------------------------------------- monitor matchers

  function test_resolveMonitorById() {
    var m = BindingModel.resolveMonitor({ kind: "id", value: 1 }, sampleMonitors())
    compare(m.name, "DP-2")
  }

  function test_resolveMonitorByName() {
    var m = BindingModel.resolveMonitor({ kind: "name", value: "eDP-1" }, sampleMonitors())
    compare(m.id, 2)
    compare(BindingModel.resolveMonitor({ kind: "name", value: "DP-9" }, sampleMonitors()), null)
  }

  function test_resolveMonitorDescSubstringAmbiguousFallsToLowestId() {
    var m = BindingModel.resolveMonitor({ kind: "desc", value: "LG HDR 4K" }, sampleMonitors())
    compare(m.id, 0)
  }

  function test_resolveMonitorDescExactBeatsSubstring() {
    var m = BindingModel.resolveMonitor(
      { kind: "desc", value: "LG Electronics LG HDR 4K 0x0000323A" }, sampleMonitors())
    compare(m.id, 1)
  }

  function test_resolveMonitorDescCaseInsensitive() {
    var m = BindingModel.resolveMonitor({ kind: "desc", value: "lg hdr 4k" }, sampleMonitors())
    compare(m.id, 0)
  }

  function test_resolveMonitorSkipsDisabledAndMirrored() {
    var monitors = sampleMonitors()
    monitors[0].enabled = false
    monitors[1].mirrored = true
    var m = BindingModel.resolveMonitor({ kind: "desc", value: "LG HDR 4K" }, monitors)
    compare(m, null)
  }

  // ---------------------------------------------------------------- resolve

  function test_resolveComputesGlobalWorkspaceFromOffset() {
    var bindings = BindingModel.normalizeBindings([
      { class: "^discord$", target: { monitor: { name: "DP-2" }, slot: 5 }, focus: true }
    ])
    var result = BindingModel.resolve(bindings, { initialClass: "discord" }, sampleMonitors())
    compare(result.status, "apply")
    compare(result.workspaceId, 15)
    compare(result.follow, true)
  }

  function test_resolveDerivesOffsetFromMonitorIdWhenAbsent() {
    var monitors = [{ id: 2, name: "eDP-1", description: "x", enabled: true, mirrored: false }]
    var bindings = BindingModel.normalizeBindings([
      { class: "^code$", target: { monitor: { name: "eDP-1" }, slot: 3 } }
    ])
    var result = BindingModel.resolve(bindings, { initialClass: "code" }, monitors)
    compare(result.status, "apply")
    compare(result.workspaceId, 23)
    compare(result.monitorName, "eDP-1")
  }

  function test_resolveDefaultsToSilent() {
    var bindings = BindingModel.normalizeBindings([
      { class: "^wechat$", target: { monitor: { id: 0 }, slot: 9 } }
    ])
    var result = BindingModel.resolve(bindings, { initialClass: "wechat" }, sampleMonitors())
    compare(result.status, "apply")
    compare(result.workspaceId, 9)
    compare(result.follow, false)
  }

  function test_resolveSkipsBindingWhoseMonitorIsAbsent() {
    var bindings = BindingModel.normalizeBindings([
      { class: "^vesktop$", target: { monitor: { name: "HDMI-A-1" }, slot: 10 } },
      { class: "^vesktop$", target: { monitor: { name: "DP-1" }, slot: 4 } }
    ])
    var result = BindingModel.resolve(bindings, { initialClass: "vesktop" }, sampleMonitors())
    compare(result.status, "apply")
    compare(result.workspaceId, 4)
  }

  function test_resolveReturnsNoneWhenOnlyAbsentMonitorMatchesClass() {
    var bindings = BindingModel.normalizeBindings([
      { class: "^vesktop$", target: { monitor: { name: "HDMI-A-1" }, slot: 10 } }
    ])
    compare(BindingModel.resolve(bindings, { initialClass: "vesktop" }, sampleMonitors()).status, "none")
  }

  function test_resolveIsPendingWhenTitlePresentButNotYetMatched() {
    var bindings = BindingModel.normalizeBindings([
      { class: "^chrome-.*$", title: "(LINE|Line)", target: { monitor: { id: 0 }, slot: 8 } }
    ])
    compare(BindingModel.resolve(
      bindings, { initialClass: "chrome-abc", title: "chrome-abc" }, sampleMonitors()).status, "pending")
    compare(BindingModel.resolve(
      bindings, { initialClass: "chrome-abc", title: "LINE" }, sampleMonitors()).status, "apply")
  }

  function test_resolveConcreteBindingBeatsPending() {
    var bindings = BindingModel.normalizeBindings([
      { class: "^chrome-.*$", title: "(LINE|Line)", target: { monitor: { id: 0 }, slot: 8 } },
      { class: "^chrome-.*$", target: { monitor: { id: 0 }, slot: 3 } }
    ])
    var result = BindingModel.resolve(
      bindings, { initialClass: "chrome-abc", title: "chrome-abc" }, sampleMonitors())
    compare(result.status, "apply")
    compare(result.workspaceId, 3)
  }

  function test_resolvePendingOnlyWhenMonitorPresent() {
    var bindings = BindingModel.normalizeBindings([
      { class: "^chrome-.*$", title: "(LINE|Line)", target: { monitor: { name: "HDMI-A-1" }, slot: 8 } }
    ])
    compare(BindingModel.resolve(
      bindings, { initialClass: "chrome-abc", title: "chrome-abc" }, sampleMonitors()).status, "none")
  }

  function test_resolveEmptyOrGarbage() {
    compare(BindingModel.resolve([], { initialClass: "x" }, sampleMonitors()).status, "none")
    compare(BindingModel.resolve(null, { initialClass: "x" }, sampleMonitors()).status, "none")
    compare(BindingModel.resolve(
      BindingModel.normalizeBindings([{ class: "^x$", target: { monitor: { id: 0 }, slot: 1 } }]),
      { initialClass: "x" }, []).status, "none")
  }

  // ------------------------------------------------------------ client parse

  function test_parseClientWindowsBuildsAddressMap() {
    var text = JSON.stringify([
      { address: "0xABC", initialClass: "chrome-abc", class: "Google-chrome", title: "LINE", workspace: { id: 8 } },
      { address: "0xdef", initialClass: "", class: "kitty", title: "sh", workspace: { id: 1 } }
    ])
    var map = BindingModel.parseClientWindows(text)
    compare(map["0xabc"].initialClass, "chrome-abc")
    compare(map["0xabc"].title, "LINE")
    compare(map["0xdef"].initialClass, "kitty")
  }

  function test_parseClientWindowsToleratesGarbage() {
    compare(Object.keys(BindingModel.parseClientWindows("not json")).length, 0)
    compare(Object.keys(BindingModel.parseClientWindows("")).length, 0)
    compare(Object.keys(BindingModel.parseClientWindows("null")).length, 0)
  }
}
