const {test} = require('node:test');
const assert = require('node:assert/strict');
const C = require('../Config.js');
const A = require('../AppModel.js');
test('configuration uses safe defaults and bounded numeric settings', () => {
  assert.deepEqual(C.normalize(null), C.normalize({version: 500, learning: false}));
  assert.deepEqual(C.normalize({starterApps: ['foo.desktop', 'foo', '', null]}).starterApps, ['foo']);
  assert.equal(C.normalize({focusDelayMs: -2}).focusDelayMs, 500);
  assert.equal(C.normalize({halfLifeDays: Infinity}).halfLifeDays, 14);
  assert.equal(C.normalize({cooldownSeconds: '1'}).cooldownSeconds, 60);
  const aliases = C.normalize({appAliases: {Foo: 'a', FOO: 'b', bad: 'bad\nvalue'}}).appAliases;
  assert.equal(aliases.foo, 'b');
  assert.equal(aliases.bad, undefined);
  assert.equal(C.normalize({learning: false}).learning, false);
});
test('equivalent launchers deduplicate without conflating web and native apps', () => {
  const entries = [{id: 'com.microsoft.Edge', name: 'Edge', execString: 'edge'}, {id: 'microsoft-edge', name: 'Edge', execString: 'edge'}, {id: 'web', name: 'ChatGPT Web', execString: 'webapp'}, {id: 'chatgpt', name: 'ChatGPT', execString: 'chatgpt'}];
  const unique = A.unique(entries);
  assert.equal(unique.length, 3);
  assert.equal(unique[0].id, 'microsoft-edge');
  assert.equal(A.unique(entries, ['com.microsoft.Edge'])[0].id, 'com.microsoft.Edge');
  assert.equal(A.canonical(entries[0], unique).id, 'microsoft-edge');
  assert.equal(A.canonical({id: 'missing', name: 'Missing'}, unique), null);
  assert.equal(A.visible(entries, ['microsoft-edge'], []).length, 2);
  assert.equal(A.visible(entries, ['com.microsoft.Edge'], []).length, 2);
});
test('class aliases and terminal app identifiers map without window-title guesses', () => {
  const entries = [{id: 'chatgpt', startupClass: 'Chatgpt'}, {id: 'WhatsApp'}, {id: 'nvim', runInTerminal: true, command: ['/usr/bin/nvim']}];
  assert.equal(A.match('Chatgpt', entries, {}).id, 'chatgpt');
  assert.equal(A.match('msedge-web.whatsapp.com__-Default', entries, {'msedge-web.whatsapp.com__-default': 'WhatsApp'}).id, 'WhatsApp');
  assert.equal(A.match('org.omarchy.nvim', entries, {}).id, 'nvim');
  assert.equal(A.match('random-app', entries, {}), null);
  assert.equal(A.match('chatgpt', entries, {chatgpt: 'not-installed'}), null);
});
test('focus commands validate addresses and restore minimized windows', () => {
  assert.equal(A.focusCommand('0x123"; os.execute("bad")', 1, '1', 1), '');
  assert.equal(A.focusCommand('0x' + 'f'.repeat(17), 1, '1', 1), '');
  assert.match(A.focusCommand('123abc', 5, '5', 1), /workspace = "5"/);
  assert.match(A.focusCommand('0x123', -99, 'special:minimized', 2), /window.move\(\{ workspace = "2"/);
  assert.equal(A.focusCommand('0x123', -99, 'special:minimized', -1), '');
  assert.equal(A.focusCommand('0x123', -99, 'special:minimized', Infinity), '');
  assert.equal(A.focusCommand('0x123', -99, 'special:minimized', 1.5), '');
  assert.equal(A.focusCommand('0x123', -99, 'special:minimized', 2147483648), '');
  assert.doesNotMatch(A.focusCommand('0x123', -1, 'special:chat', 1), /toggle_special|workspace =/);
  assert.doesNotMatch(A.focusCommand('0x123', '1;bad', 'whatever', 1), /bad/);
});
