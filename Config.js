// SPDX-License-Identifier: MIT
function own(object, key) { return Object.prototype.hasOwnProperty.call(object, key) }
function object(value) { return value !== null && typeof value === "object" && !Array.isArray(value) }
function id(value) {
  return typeof value === "string" && value.length > 0 && value.length <= 256 && !/[\x00-\x1f\x7f]/.test(value)
    ? value.replace(/\.desktop$/, "") : ""
}
function ids(value, limit) {
  if (!Array.isArray(value)) return []
  return value.slice(0, limit).map(id).filter(function(value, index, all) { return value && all.indexOf(value) === index })
}
function number(value, fallback, low, high) {
  return typeof value === "number" && isFinite(value) ? Math.max(low, Math.min(high, value)) : fallback
}
function normalize(value) {
  var input = object(value) && (!own(value, "version") || value.version === 1) ? value : {}
  var aliases = {}
  if (object(input.appAliases)) {
    Object.keys(input.appAliases).slice(0, 128).forEach(function(key) {
      var target = id(input.appAliases[key])
      if (id(key) && target) Object.defineProperty(aliases, key.toLowerCase(), {value: target, enumerable: true, configurable: true})
    })
  }
  return {
    version: 1,
    starterApps: ids(input.starterApps, 64),
    hiddenApps: ids(input.hiddenApps, 512),
    appAliases: aliases,
    learning: typeof input.learning === "boolean" ? input.learning : true,
    focusDelayMs: Math.round(number(input.focusDelayMs, 1800, 500, 30000)),
    cooldownSeconds: number(input.cooldownSeconds, 60, 10, 3600),
    halfLifeDays: number(input.halfLifeDays, 14, 1, 365)
  }
}
if (typeof module !== "undefined") module.exports = {own: own, object: object, id: id, ids: ids, normalize: normalize}
