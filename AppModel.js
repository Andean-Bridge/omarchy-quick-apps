// SPDX-License-Identifier: MIT
function signature(entry) {
  return String(entry.name || "").toLowerCase() + "|" + String(entry.execString || entry.id).trim()
}
function unique(entries, starters) {
  var out = [], seen = {}, preferred = starters || []
  entries.forEach(function(entry) {
    var key = signature(entry)
    if (Object.prototype.hasOwnProperty.call(seen, key)) {
      var index = seen[key], a = preferred.indexOf(entry.id), b = preferred.indexOf(out[index].id)
      if ((a >= 0 && (b < 0 || a < b)) || (a < 0 && b < 0 && String(entry.id).length < String(out[index].id).length)) out[index] = entry
      return
    }
    seen[key] = out.length
    out.push(entry)
  })
  return out
}
function visible(entries, hidden, starters) {
  var excluded = {}
  entries.forEach(function(entry) {
    if ((hidden || []).indexOf(String(entry.id)) >= 0) excluded[signature(entry)] = true
  })
  return unique(entries.filter(function(entry) { return !Object.prototype.hasOwnProperty.call(excluded, signature(entry)) }), starters)
}
function canonical(entry, entries) {
  if (!entry) return null
  for (var i = 0; i < entries.length; i++)
    if (entries[i].id === entry.id || signature(entries[i]) === signature(entry)) return entries[i]
  return null
}
function match(appId, entries, aliases) {
  var key = String(appId || "").toLowerCase()
  if (!key) return null
  var alias = Object.prototype.hasOwnProperty.call(aliases || {}, key) ? String(aliases[key]).toLowerCase() : ""
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i], id = String(entry.id).toLowerCase()
    if (alias ? id === alias : (id === key || String(entry.startupClass || "").toLowerCase() === key)) return entry
  }
  if (alias) return null
  // Recognize Omarchy terminal launchers without guessing from window titles.
  for (var j = 0; j < entries.length; j++) {
    var candidate = entries[j], words = String(candidate.execString || "").split(/\s+/)
    if (words.indexOf("--app-id=" + String(appId)) >= 0) return candidate
    var command = String((candidate.command || [])[0] || "").split("/").pop()
    if (candidate.runInTerminal && key.indexOf("org.omarchy.") === 0 && command === key.slice(12)) return candidate
  }
  return null
}
function focusCommand(address, workspaceId, workspaceName, currentWorkspaceId) {
  var value = String(address || "")
  if (!/^(0x)?[0-9a-f]{1,16}$/i.test(value)) return ""
  if (value.indexOf("0x") !== 0) value = "0x" + value
  var target = 'window = "address:' + value + '"', actions = []
  if (workspaceName === "special:minimized") {
    var current = currentWorkspaceId
    if (!Number.isInteger(current) || current <= 0 || current > 2147483647) return ""
    actions.push('hl.dispatch(hl.dsp.window.move({ workspace = "' + current + '", ' + target + ' }))')
  } else if (Number.isInteger(workspaceId) && workspaceId > 0 && workspaceId <= 2147483647) {
    actions.push('hl.dispatch(hl.dsp.focus({ workspace = "' + workspaceId + '" }))')
  }
  // The compositor handles special workspaces during focus; toggling them here
  // would hide an already-visible scratchpad instead of bringing it forward.
  actions.push('hl.dispatch(hl.dsp.focus({ ' + target + ' }))')
  actions.push('hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", ' + target + ' }))')
  return "function() " + actions.join("; ") + " end"
}
if (typeof module !== "undefined") module.exports = {signature: signature, unique: unique, visible: visible, canonical: canonical, match: match, focusCommand: focusCommand}
