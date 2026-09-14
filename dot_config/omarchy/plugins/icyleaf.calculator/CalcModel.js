.pragma library

// Pure-JS seam for the calculator overlay: history persistence and the
// "is this worth showing?" gate that keeps qalc's interactive echo (typing
// `1 +` answers `1`) out of the UI. No QML, no process calls, so it is
// testable with plain fixtures.

var HISTORY_LIMIT = 50

// ── Help ────────────────────────────────────────────────────────────────────

// Every example below was checked against the installed qalc. Keep them in
// `to` form: qalc treats `in` as the inch unit, so `5 ft in m` silently answers
// `0.0387096 m³` instead of converting, and the overlay should not teach it.
function helpSections() {
  return [
    {
      title: "Math",
      rows: [
        { syntax: "2+2 · 60 + 74 · (3+5)*2", note: "arithmetic" },
        { syntax: "2^10 · 3**3", note: "powers" },
        { syntax: "sqrt(625) · 5!", note: "functions, factorial" },
        { syntax: "sin(pi/2) · log10(100) · ln(e)", note: "trig / log" },
        { syntax: "abs(-3) · round(3.7)", note: "rounding" },
        { syntax: "0x1F · 0b1010", note: "hex / binary input" },
        { syntax: "1/3 · pi", note: "constants and fractions" }
      ]
    },
    {
      title: "Percent",
      rows: [
        { syntax: "20% * 50", note: "percent of a value" },
        { syntax: "100 + 15%", note: "increase by a percent" },
        { syntax: "19m + 47%", note: "percent of a quantity" }
      ]
    },
    {
      title: "Conversions",
      rows: [
        { syntax: "29 inches to cm", note: "length" },
        { syntax: "5 kg to lb", note: "mass" },
        { syntax: "20 celsius to fahrenheit", note: "temperature" },
        { syntax: "100 km/h to mph", note: "speed" },
        { syntax: "1 hour to seconds", note: "time" },
        { syntax: "100 MB to GB", note: "data" },
        { syntax: "1 mile to km", note: "use `to`, not `in`" }
      ]
    },
    {
      title: "Currency",
      rows: [
        { syntax: "10 usd to gbp · 45 jpy to inr", note: "fiat" },
        { syntax: "1 btc to usd", note: "crypto" },
        { syntax: "1 EUR to JPY", note: "cached ECB / market rates" }
      ]
    },
    {
      title: "Keys",
      rows: [
        { syntax: "Enter", note: "copy answer and close" },
        { syntax: "Alt+Enter", note: "copy answer, stay open" },
        { syntax: "Up / Down", note: "browse history" },
        { syntax: "Ctrl+/", note: "toggle this help" },
        { syntax: "Esc", note: "close" }
      ]
    }
  ]
}

// Flat count of visible rows, used to size the help card.
function helpRowCount() {
  var sections = helpSections()
  var count = 0
  for (var i = 0; i < sections.length; i++) count += sections[i].rows.length + 1
  return count
}

// ── History ─────────────────────────────────────────────────────────────────

function parseHistory(raw) {
  if (!raw) return []
  var parsed
  try {
    parsed = JSON.parse(raw)
  } catch (e) {
    return []
  }
  if (!Array.isArray(parsed)) return []

  var out = []
  for (var i = 0; i < parsed.length; i++) {
    var entry = normalizeEntry(parsed[i])
    if (entry) out.push(entry)
  }
  return out
}

function normalizeEntry(value) {
  if (!value || typeof value !== "object") return null
  var expression = String(value.expression === undefined ? value.expr || "" : value.expression).trim()
  var result = String(value.result === undefined ? "" : value.result).trim()
  if (!expression || !result) return null
  return { expression: expression, result: result }
}

function serializeHistory(entries) {
  return JSON.stringify(capHistory(entries, HISTORY_LIMIT), null, 2) + "\n"
}

function capHistory(entries, limit) {
  if (!Array.isArray(entries)) return []
  var max = limit > 0 ? limit : HISTORY_LIMIT
  return entries.slice(0, max)
}

// Newest first. Re-computing the same expression moves it to the top instead
// of duplicating it, and the most recent result wins.
function addHistoryEntry(entries, entry, limit) {
  var normalized = normalizeEntry(entry)
  if (!normalized) return capHistory(entries, limit)

  var out = [normalized]
  var existing = Array.isArray(entries) ? entries : []
  for (var i = 0; i < existing.length; i++) {
    var prev = normalizeEntry(existing[i])
    if (!prev) continue
    if (prev.expression === normalized.expression) continue
    out.push(prev)
  }
  return capHistory(out, limit)
}

// ── Evaluation gate ─────────────────────────────────────────────────────────

// True when the qalc output is a real answer for the current input rather than
// a partial echo. `qalc -t "1 +"` prints `1`, and `qalc -t "abc"` treats the
// letters as units, so both the trailing-operator case and the
// output-equals-input case are rejected here.
function isEvaluable(expression, output) {
  var expr = String(expression || "").trim()
  if (!expr) return false
  if (hasIncompleteEnding(expr)) return false

  var result = cleanResult(output)
  if (!result) return false
  if (result.indexOf(">") !== -1) return false
  if (result.toLowerCase().indexOf("unrecognized") !== -1) return false
  if (result === expr) return false
  return true
}

function hasIncompleteEnding(expr) {
  return /[+\-*/^%<>=,(]$/.test(String(expr).trim())
}

// qalc -t prints the bare answer, but guard against a stray leading `= ` or a
// trailing interactive prompt if a future version changes its output.
function cleanResult(output) {
  var text = String(output === undefined || output === null ? "" : output)
  text = text.replace(/\r/g, "").trim()
  if (text.charAt(0) === "=") text = text.slice(1).trim()
  text = text.replace(/>\s*$/, "").trim()
  return text
}
