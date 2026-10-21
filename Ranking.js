// SPDX-License-Identifier: MIT
function own(object, key) { return Object.prototype.hasOwnProperty.call(object, key) }
function clean(value, now) {
  var out = {}
  if (!value || typeof value !== "object" || Array.isArray(value)) return out
  Object.keys(value).slice(0, 1000).forEach(function(id) {
    var row = value[id]
    if (!id || id.length > 256 || /[\x00-\x1f\x7f]/.test(id) || !row || typeof row !== "object") return
    var score = row.score, at = row.at
    if (typeof score !== "number" || !isFinite(score) || score < 0 || typeof at !== "number" || !isFinite(at) || at < 0 || at > now + 60000) return
    Object.defineProperty(out, id, {value: {score: Math.min(score, 1000000), at: at}, enumerable: true, writable: true, configurable: true})
  })
  return out
}
function score(row, now, halfLifeDays) {
  return row ? row.score * Math.pow(0.5, Math.max(0, now - row.at) / ((halfLifeDays || 14) * 86400000)) : 0
}
function record(stats, id, now, options) {
  if (typeof id !== "string" || !id || id.length > 256 || /[\x00-\x1f\x7f]/.test(id)) return null
  var settings = options || {}, next = clean(stats, now), old = own(next, id) ? next[id] : null
  if (old && now - old.at < (settings.cooldownSeconds || 60) * 1000) return null
  Object.defineProperty(next, id, {value: {score: Math.min(1000000, score(old, now, settings.halfLifeDays) + 1), at: now}, enumerable: true, writable: true, configurable: true})
  // Retain the most recently used records when an app collection reaches the cap.
  var keys = Object.keys(next).sort(function(a, b) { return next[b].at - next[a].at })
  keys.slice(1000).forEach(function(key) { delete next[key] })
  return next
}
function ranked(entries, stats, now, starters, running, halfLifeDays) {
  var priorities = (starters || []).concat(running || [])
  return entries.slice().sort(function(a, b) {
    var sa = own(stats, a.id) ? score(stats[a.id], now, halfLifeDays) : 0
    var sb = own(stats, b.id) ? score(stats[b.id], now, halfLifeDays) : 0
    if (Math.abs(sb - sa) > 0.000001) return sb - sa
    var ai = priorities.indexOf(a.id), bi = priorities.indexOf(b.id)
    if (ai < 0) ai = priorities.length
    if (bi < 0) bi = priorities.length
    return ai - bi || String(a.name).localeCompare(String(b.name)) || String(a.id).localeCompare(String(b.id))
  })
}
if (typeof module !== "undefined") module.exports = {clean: clean, score: score, record: record, ranked: ranked}
