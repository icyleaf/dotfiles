import QtQuick 2.15
import QtTest 1.3
import "../LayoutModel.js" as LayoutModel

TestCase {
  id: root
  name: "LayoutModel"

  // ── Fixture: the real three-monitor topology, in logical (Hyprland) units ──
  // eDP-1 (M1) at origin; DP-1 (M2) up-left abutting its top edge (negative
  // coords); DP-2 (M3) to the right with a small gap.
  function realSnapshot() {
    return {
      focusedWorkspaceId: 1,
      monitors: [
        {
          id: 0, name: "eDP-1", description: "Tianma TL140ADXP24-0",
          x: 0, y: 0, width: 1600, height: 1000, focused: true,
          physicalWidth: 2880, physicalHeight: 1800, scale: 1.8,
          offset: 0, activeWorkspaceId: 1, occupiedIds: [1, 4],
          windows: [
            { address: "a1", title: "Left", at: [0, 0], size: [800, 1000], floating: false, groupSize: 1 },
            { address: "a2", title: "Right", at: [800, 0], size: [800, 1000], floating: false, groupSize: 1 }
          ]
        },
        {
          id: 1, name: "DP-1", description: "RTK UHD demoset-1",
          x: -10, y: -1080, width: 1620, height: 1080, focused: false,
          offset: 10, activeWorkspaceId: 11, occupiedIds: [11, 15, 17],
          windows: [
            { address: "0xb1", title: "GroupedA", at: [-10, -1080], size: [1620, 1080], grouped: ["0xb2"], hidden: false, visible: true, acceptsInput: true, focusHistoryID: 1 },
            { address: "0xb2", title: "GroupedB", at: [-10, -1080], size: [1620, 1080], grouped: ["0xb1"], hidden: false, visible: false, acceptsInput: false, focusHistoryID: 5 }
          ]
        },
        {
          id: 2, name: "DP-2", description: "YTH HS-140KP",
          x: 1610, y: 0, width: 1920, height: 1080, focused: false,
          offset: 20, activeWorkspaceId: 21, occupiedIds: [22, 25],
          windows: []
        }
      ]
    }
  }

  function build(snapshot, w, h, gap) {
    return LayoutModel.build(snapshot, w || 1000, h || 600, gap === undefined ? 0 : gap, 20)
  }

  function fuzzyCompare(actual, expected) {
    verify(Math.abs(actual - expected) < 0.01,
      "Expected " + expected + ", got " + actual)
  }

  function test_noMonitorsYieldsNoCards() {
    var result = build({ monitors: [], focusedWorkspaceId: 0 }, 1000, 600)
    compare(result.cards.length, 0)
  }

  function test_threeCardsMatchMonitorCountInOrder() {
    var result = build(realSnapshot())
    compare(result.cards.length, 3)
    compare(result.cards[0].name, "eDP-1")
    compare(result.cards[1].name, "DP-1")
    compare(result.cards[2].name, "DP-2")
    // badge text M1..M3
    compare(result.cards[0].badgeText, "M1")
    compare(result.cards[1].badgeText, "M2")
    compare(result.cards[2].badgeText, "M3")
  }

  // Compact-pack semantics. Fixture rows: DP-1 (1620x1080, its own top row)
  // above a bottom row [eDP-1 1600x1000, DP-2 1920x1080].
  // blockWidth = bottom row width = 1600 + 1920 (gap 0) = 3520.
  // blockHeight = 1080 (DP-1) + 1080 (bottom row max) = 2160.
  // canvas 1000x600 → scale = min(1000/3520, 600/2160) = 5/18.
  function packScale() { return 5 / 18 }

  function test_allCardsFitInsideCanvasNoClip() {
    var result = build(realSnapshot())
    compare(result.cards.length, 3)
    for (var i = 0; i < result.cards.length; i++) {
      var c = result.cards[i]
      verify(c.x >= -0.01)
      verify(c.y >= -0.01)
      verify(c.x + c.width <= 1000 + 0.01)
      verify(c.y + c.height <= 600 + 0.01)
    }
  }

  function test_uniformScalePreservesLogicalSizes() {
    var result = build(realSnapshot())
    var S = result.scale
    fuzzyCompare(result.cards[0].width, 1600 * S)
    fuzzyCompare(result.cards[1].width, 1620 * S)
    fuzzyCompare(result.cards[2].width, 1920 * S)
  }

  function test_rowsPackTightlyIntoCompactBlock() {
    var S = packScale()
    var result = build(realSnapshot())
    var c0 = result.cards[0] // eDP-1
    var c1 = result.cards[1] // DP-1
    var c2 = result.cards[2] // DP-2

    // Whole block is height-limited (2160*S = 600 = canvas height), so it is
    // horizontally centered: bottom-block left margin = (1000-3520*S)/2.
    var blockOffsetX = (1000 - (1600 + 1920) * S) / 2
    fuzzyCompare(c0.x, blockOffsetX)
    // DP-1 (top row) centered above the bottom block.
    fuzzyCompare(c1.x + c1.width / 2, 500)
    compare(c1.y, 0)
    // Bottom row begins directly under the top row (no vertical gap at gap=0).
    fuzzyCompare(c0.y, c1.height)
    fuzzyCompare(c2.y, c1.height)
    // Bottom row: eDP-1 flush at the block left, DP-2 immediately right.
    fuzzyCompare(c2.x, c0.x + c0.width)
    // DP-1 sits above both bottom cards.
    compare(c1.y < c0.y, true)
  }

  function test_minimumGapSeparatesPackedCards() {
    var result = build(realSnapshot(), 1000, 600, 24)
    var c0 = result.cards[0]
    var c2 = result.cards[2]
    // Bottom-row horizontal gap becomes >= the requested px.
    verify(c2.x - (c0.x + c0.width) >= 24 - 0.5)
    // All cards still fit.
    for (var i = 0; i < result.cards.length; i++) {
      var c = result.cards[i]
      verify(c.x >= -0.01)
      verify(c.x + c.width <= 1000 + 0.01)
      verify(c.y >= -0.01)
      verify(c.y + c.height <= 600 + 0.01)
    }
  }

  function test_cardAspectRatiosPreserved() {
    var result = build(realSnapshot())
    var aspects = [[1600 / 1000, 0], [1620 / 1080, 1], [1920 / 1080, 2]]
    for (var i = 0; i < aspects.length; i++) {
      var card = result.cards[aspects[i][1]]
      fuzzyCompare(card.width / card.height, aspects[i][0])
    }
  }

  function test_activeMonitorFocusedFlag() {
    var result = build(realSnapshot())
    compare(result.cards[0].focused, true)
    compare(result.cards[1].focused, false)
    compare(result.cards[2].focused, false)
  }

  function test_physicalResolutionPassthrough() {
    var result = build(realSnapshot())
    compare(result.cards[0].physicalWidth, 2880)
    compare(result.cards[0].physicalHeight, 1800)
    fuzzyCompare(result.cards[0].scale, 1.8)
    // Cards without explicit physical size derive it from logical * scale.
    compare(result.cards[1].physicalWidth, 1620)
    compare(result.cards[1].physicalHeight, 1080)
  }

  function test_slotClassificationPerMonitor() {
    var result = build(realSnapshot())
    var aSlots = result.cards[0].slots
    compare(aSlots.length, 10)
    compare(aSlots[0].id, 1)
    compare(aSlots[0].active, true)
    compare(aSlots[0].focused, true)
    compare(aSlots[0].occupied, true)
    compare(aSlots[3].id, 4)
    compare(aSlots[3].active, false)
    compare(aSlots[3].focused, false)
    compare(aSlots[3].occupied, true)
    // all others empty
    compare(aSlots[1].occupied, false)
    compare(aSlots[9].occupied, false)

    var bSlots = result.cards[1].slots
    compare(bSlots[0].id, 11)
    compare(bSlots[0].active, true)
    compare(bSlots[0].occupied, true)
    compare(bSlots[4].occupied, true) // id 15
    compare(bSlots[6].occupied, true) // id 17
    compare(bSlots[1].occupied, false)

    var cSlots = result.cards[2].slots
    compare(cSlots[0].id, 21)
    compare(cSlots[0].active, true)
    compare(cSlots[0].occupied, false) // empty active workspace
    compare(cSlots[1].occupied, true)  // id 22
    compare(cSlots[4].occupied, true)  // id 25
  }

  function test_tiledWindowProjection() {
    var result = build(realSnapshot())
    var card = result.cards[0]
    var S = result.scale
    compare(card.windows.length, 2)
    compare(card.empty, false)

    // Windows are card-local, relative to card top-left. Tiled left window
    // fills the full height from the top.
    var w0 = card.windows[0]
    var w1 = card.windows[1]
    fuzzyCompare(w0.x, 0)
    fuzzyCompare(w0.y, 0)
    fuzzyCompare(w0.width, 800 * S)
    fuzzyCompare(w0.height, 1000 * S)
    fuzzyCompare(w1.x, 800 * S)
    fuzzyCompare(w1.y, 0)
    fuzzyCompare(w1.width, 800 * S)
    compare(w0.title, "Left")
    compare(w1.title, "Right")
  }

  function test_groupCollapsesToSingleFrameFillingCard() {
    var result = build(realSnapshot())
    var card = result.cards[1]
    compare(card.windows.length, 1)
    compare(card.windows[0].groupSize, 2)
    compare(card.windows[0].title, "GroupedA")
    // group occupies the whole active workspace (card-local)
    fuzzyCompare(card.windows[0].x, 0)
    fuzzyCompare(card.windows[0].y, 0)
    fuzzyCompare(card.windows[0].width, card.width)
    fuzzyCompare(card.windows[0].height, card.height)
  }

  function test_emptyActiveWorkspaceIsIdleCard() {
    var result = build(realSnapshot())
    var card = result.cards[2]
    compare(card.empty, true)
    compare(card.windows.length, 0)
  }

  function test_tinyWindowGetsReadableMinimum() {
    var snapshot = {
      focusedWorkspaceId: 1,
      monitors: [{
        id: 0, name: "eDP-1", description: "",
        x: 0, y: 0, width: 1600, height: 1000, focused: true,
        offset: 0, activeWorkspaceId: 1, occupiedIds: [1],
        windows: [
          { address: "tiny", title: "Tiny", at: [798, 494], size: [4, 4], floating: true, groupSize: 1 }
        ]
      }]
    }
    var result = build(snapshot, 1000, 600)
    var card = result.cards[0]
    var win = card.windows[0]
    var S = result.scale
    // min 20x14 enforced, expanded around the window's center (card-local)
    verify(win.width >= 20 - 0.01)
    verify(win.height >= 14 - 0.01)
    fuzzyCompare(win.x + win.width / 2, (798 + 2) * S)
    fuzzyCompare(win.y + win.height / 2, (494 + 2) * S)
    // and it stays inside the card
    verify(win.x >= 0 - 0.01)
    verify(win.y >= 0 - 0.01)
    verify(win.x + win.width <= card.width + 0.01)
    verify(win.y + win.height <= card.height + 0.01)
  }

  function test_wideCanvasStillFitsAllWithGap() {
    // 1600x900 canvas, min gap 20: whole topology fits, no clipping.
    var result = build(realSnapshot(), 1600, 900, 20)
    for (var i = 0; i < result.cards.length; i++) {
      var c = result.cards[i]
      verify(c.x >= -0.01)
      verify(c.y >= -0.01)
      verify(c.x + c.width <= 1600 + 0.01)
      verify(c.y + c.height <= 900 + 0.01)
    }
  }

  function test_gapScalesWholeLayoutSlightlySmaller() {
    // With a min gap the fit box grows, so scale shrinks vs gap=0.
    var tight = build(realSnapshot())
    var spaced = build(realSnapshot(), 1000, 600, 24)
    verify(spaced.scale < tight.scale)
  }

  // ── collapseGroups: plain toplevel DTOs → preview units ──
  function dto(address, grouped, extra) {
    var base = {
      address: address, grouped: grouped || [],
      hidden: false, visible: true, acceptsInput: true, focusHistoryID: 10,
      title: "w-" + address, floating: false, at: [0, 0], size: [100, 100]
    }
    for (var key in (extra || {})) base[key] = extra[key]
    return base
  }

  function test_collapseTwoIndependentGroupsAndWindow() {
    var units = LayoutModel.collapseGroups([
      dto("0x1", ["0x2"]),
      dto("0x2", ["0x1"]),
      dto("0x3", []),
      dto("0x4", ["0x5", "0x6"]),
      dto("0x5", ["0x4", "0x6"]),
      dto("0x6", ["0x4", "0x5"])
    ])
    compare(units.length, 3)
    var group = null
    var group3 = null
    for (var i = 0; i < units.length; i++) {
      if (units[i].groupSize === 2) group = units[i]
      if (units[i].groupSize === 3) group3 = units[i]
      verify(units[i].groupSize >= 1)
    }
    verify(group !== null)
    verify(group3 !== null)
  }

  function test_collapsePrefersVisibleActiveMember() {
    var units = LayoutModel.collapseGroups([
      dto("0xa", ["0xb"], { hidden: true, visible: false, title: "hidden" }),
      dto("0xb", ["0xa"], { focusHistoryID: 1, acceptsInput: true, title: "visible-active" })
    ])
    compare(units.length, 1)
    compare(units[0].groupSize, 2)
    compare(units[0].title, "visible-active")
  }

  function test_collapseLeavesNormalWindowAlone() {
    var units = LayoutModel.collapseGroups([dto("0x7", [])])
    compare(units.length, 1)
    compare(units[0].groupSize, 1)
    compare(units[0].address, "0x7")
  }
}
