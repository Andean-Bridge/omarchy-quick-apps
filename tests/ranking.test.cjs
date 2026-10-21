const {test} = require('node:test');
const assert = require('node:assert/strict');
const R = require('../Ranking.js');
const now = 1800000000000;
test('corrupt, oversized, inherited and future history is bounded', () => {
  assert.deepEqual(R.clean(null, now), {});
  assert.deepEqual(R.clean([], now), {});
  assert.deepEqual(R.clean({bad: {score: '1', at: now}, future: {score: 1, at: now + 100001}, negative: {score: -1, at: now}}, now), {});
  assert.equal(Object.keys(R.clean(Object.fromEntries(Array.from({length: 1100}, (_, i) => [String(i), {score: 1, at: now}])), now)).length, 1000);
  assert.equal(R.clean({big: {score: 1e20, at: now}}, now).big.score, 1000000);
  const hostile = R.clean(JSON.parse('{"__proto__":{"score":1,"at":1800000000000}}'), now);
  assert.equal(Object.getPrototypeOf(hostile), Object.prototype);
  assert.equal({}.score, undefined);
});
test('a focus session counts once per configured cooldown', () => {
  const first = R.record({}, 'chatgpt', now);
  assert.equal(first.chatgpt.score, 1);
  assert.equal(R.record(first, 'chatgpt', now + 59999), null);
  assert.ok(R.record(first, 'chatgpt', now + 60000).chatgpt.score > 1.99);
  assert.ok(R.record(first, 'chatgpt', now + 10000, {cooldownSeconds: 10}));
  assert.equal(R.record({}, 'bad\napp', now), null);
  assert.equal(R.record({}, '', now), null);
});
test('scores decay and survive a JSON round trip', () => {
  assert.equal(R.score({score: 2, at: now - 14 * 86400000}, now), 1);
  assert.equal(R.score({score: 2, at: now - 86400000}, now, 1), 1);
  const state = R.record({}, 'chatgpt', now);
  assert.deepEqual(R.clean(JSON.parse(JSON.stringify(state)), now), state);
});
test('learned score outranks starter apps, then running apps and alphabetical fallback', () => {
  const entries = ['Zulu', 'Alpha', 'Beta', 'Gamma'].map(name => ({id: name, name}));
  const ranked = R.ranked(entries, {Zulu: {score: 4, at: now}}, now, ['Beta'], ['Gamma']);
  assert.deepEqual(ranked.map(x => x.id), ['Zulu', 'Beta', 'Gamma', 'Alpha']);
  assert.deepEqual(entries.map(x => x.id), ['Zulu', 'Alpha', 'Beta', 'Gamma']);
  assert.equal(R.ranked(entries, {}, now)[0].id, 'Alpha');
});
