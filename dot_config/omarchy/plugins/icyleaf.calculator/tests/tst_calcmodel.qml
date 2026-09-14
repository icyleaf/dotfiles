import QtQuick 2.15
import QtTest 1.3
import "../CalcModel.js" as CalcModel

TestCase {
  id: root
  name: "CalcModel"

  // ── parseHistory ─────────────────────────────────────────────────────────
  function test_parseHistoryRejectsBadJson() {
    compare(CalcModel.parseHistory("").length, 0)
    compare(CalcModel.parseHistory("not json").length, 0)
    compare(CalcModel.parseHistory("{}").length, 0)
    compare(CalcModel.parseHistory("null").length, 0)
  }

  function test_parseHistoryKeepsValidEntries() {
    var raw = JSON.stringify([
      { expression: "2+2", result: "4" },
      { expression: "", result: "4" },
      { expression: "1/0", result: "" },
      { expression: "1 usd in eur", result: "€0.87" }
    ])
    var entries = CalcModel.parseHistory(raw)
    compare(entries.length, 2)
    compare(entries[0].expression, "2+2")
    compare(entries[1].expression, "1 usd in eur")
  }

  function test_parseHistoryAcceptsLegacyExprKey() {
    var entries = CalcModel.parseHistory(JSON.stringify([{ expr: "3*3", result: "9" }]))
    compare(entries.length, 1)
    compare(entries[0].expression, "3*3")
  }

  // ── addHistoryEntry ──────────────────────────────────────────────────────
  function test_addHistoryEntryPrependsAndCaps() {
    var entries = []
    for (var i = 0; i < 60; i++) entries = CalcModel.addHistoryEntry(entries, { expression: "e" + i, result: String(i) }, 50)
    compare(entries.length, 50)
    compare(entries[0].expression, "e59")
    compare(entries[49].expression, "e10")
  }

  function test_addHistoryEntryDeduplicatesByExpression() {
    var entries = CalcModel.addHistoryEntry([], { expression: "2+2", result: "4" })
    entries = CalcModel.addHistoryEntry(entries, { expression: "3+3", result: "6" })
    entries = CalcModel.addHistoryEntry(entries, { expression: "2+2", result: "4" })
    compare(entries.length, 2)
    compare(entries[0].expression, "2+2")
    compare(entries[1].expression, "3+3")
  }

  function test_addHistoryEntryRejectsEmpty() {
    var entries = CalcModel.addHistoryEntry([], { expression: "2+2", result: "" })
    compare(entries.length, 0)
    entries = CalcModel.addHistoryEntry([], { expression: "", result: "4" })
    compare(entries.length, 0)
  }

  function test_serializeHistoryRoundTrips() {
    var entries = CalcModel.addHistoryEntry([], { expression: "2+2", result: "4" })
    var parsed = CalcModel.parseHistory(CalcModel.serializeHistory(entries))
    compare(parsed.length, 1)
    compare(parsed[0].expression, "2+2")
    compare(parsed[0].result, "4")
  }

  // ── isEvaluable ──────────────────────────────────────────────────────────
  function test_isEvaluableAcceptsRealAnswers() {
    compare(CalcModel.isEvaluable("2+2", "4"), true)
    compare(CalcModel.isEvaluable("29 inches to cm", "73.66 cm"), true)
    compare(CalcModel.isEvaluable("sqrt(625)", "25"), true)
    compare(CalcModel.isEvaluable("2^10", "1024"), true)
  }

  function test_isEvaluableRejectsPartialEcho() {
    // qalc -t "1 +" prints "1"; showing that would be a lie.
    compare(CalcModel.isEvaluable("1 +", "1"), false)
    compare(CalcModel.isEvaluable("2+", "2"), false)
  }

  function test_isEvaluableRejectsOutputEqualInput() {
    compare(CalcModel.isEvaluable("2+2", "2+2"), false)
  }

  function test_isEvaluableRejectsEmpty() {
    compare(CalcModel.isEvaluable("", "4"), false)
    compare(CalcModel.isEvaluable("   ", "4"), false)
    compare(CalcModel.isEvaluable("2+2", ""), false)
  }

  function test_isEvaluableRejectsPromptAndUnknown() {
    compare(CalcModel.isEvaluable("2+2", "> "), false)
    compare(CalcModel.isEvaluable("2+2", "Unrecognized option."), false)
  }

  function test_cleanResultStripsPromptAndEquals() {
    compare(CalcModel.cleanResult("= 4"), "4")
    compare(CalcModel.cleanResult("4\n> "), "4")
    compare(CalcModel.cleanResult("73.66 cm"), "73.66 cm")
  }

  // ── Help ─────────────────────────────────────────────────────────────────
  function test_helpSectionsAreWellFormed() {
    var sections = CalcModel.helpSections()
    verify(sections.length > 0)
    for (var i = 0; i < sections.length; i++) {
      verify(sections[i].title.length > 0)
      verify(sections[i].rows.length > 0)
      for (var j = 0; j < sections[i].rows.length; j++) {
        verify(sections[i].rows[j].syntax.length > 0)
        verify(sections[i].rows[j].note.length > 0)
      }
    }
  }

  function test_helpRowCountMatchesSections() {
    var sections = CalcModel.helpSections()
    var expected = 0
    for (var i = 0; i < sections.length; i++) expected += sections[i].rows.length + 1
    compare(CalcModel.helpRowCount(), expected)
  }

  function test_helpNeverTeachesTheInKeyword() {
    // `in` is the inch unit in qalc; only `to` converts.
    var sections = CalcModel.helpSections()
    for (var i = 0; i < sections.length; i++) {
      for (var j = 0; j < sections[i].rows.length; j++) {
        var syntax = sections[i].rows[j].syntax.toLowerCase()
        verify(syntax.indexOf(" in ") === -1)
      }
    }
  }
}
