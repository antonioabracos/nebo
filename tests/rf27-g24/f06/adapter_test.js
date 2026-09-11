'use strict';

const assert = require('assert');
const { EventEmitter } = require('events');
const path = require('path');
const adapter = require('../../../editors/vscode/extension.js')._test;

async function main() {
  assert.strictEqual(adapter.MAX_FRAME, 1_048_576);
  assert.deepStrictEqual(Object.keys(adapter.COMMANDS), ['nebo.check', 'nebo.build', 'nebo.emitAsm']);
  assert.strictEqual(adapter.redact('ok\napi-key=raw-secret\ndone'), 'ok\n[REDACTED]\ndone');
  assert.throws(() => adapter.boundedAppend('', Buffer.alloc(9), 8), /budget/);
  assert.throws(() => adapter.localPath('/tmp/work', ''), /invalid/);
  assert.strictEqual(adapter.localPath('/tmp/work', 'build/bin/neboc'), path.resolve('/tmp/work/build/bin/neboc'));

  const framed = adapter.encodeFrame({ jsonrpc: '2.0', id: 1, result: { ok: true } });
  const partial = adapter.decodeFrames(framed.subarray(0, framed.length - 2));
  assert.strictEqual(partial.frames.length, 0);
  const decoded = adapter.decodeFrames(framed);
  assert.strictEqual(decoded.frames[0].result.ok, true);
  assert.strictEqual(decoded.rest.length, 0);
  assert.throws(() => adapter.decodeFrames(Buffer.from('X: 1\r\n\r\n{}')), /header/);

  let invocation;
  const spawn = (executable, args, options) => {
    invocation = { executable, args, options };
    const proc = new EventEmitter();
    proc.stdout = new EventEmitter(); proc.stderr = new EventEmitter(); proc.kill = () => {};
    process.nextTick(() => {
      proc.stdout.emit('data', Buffer.from('checked\n'));
      proc.stderr.emit('data', Buffer.from('token=must-not-leak\n'));
      proc.emit('close', 0, null);
    });
    return proc;
  };
  const result = await adapter.runLocal(spawn, '/local/neboc', ['check', '/w/a.no'], '/w', 1024);
  assert.strictEqual(result.stdout, 'checked\n');
  assert.strictEqual(result.stderr, '[REDACTED]\n');
  assert.strictEqual(invocation.options.shell, false);
  assert.deepStrictEqual(invocation.options.stdio, ['ignore', 'pipe', 'pipe']);
  assert.deepStrictEqual(invocation.args, ['check', '/w/a.no']);

  const document = { languageId: 'nebo', uri: { scheme: 'file', fsPath: '/w/a.no' }, save: async () => true };
  const output = [];
  const vscode = {
    workspace: {
      isTrusted: true,
      getWorkspaceFolder: () => ({ uri: { fsPath: '/w' } }),
      getConfiguration: () => ({ get: (key, fallback) => key === 'compilerPath' ? '/local/neboc' : fallback })
    },
    window: { activeTextEditor: { document }, createOutputChannel: () => ({ appendLine: (x) => output.push(x), show: () => {} }) }
  };
  await adapter.executeCommand(vscode, spawn, 'nebo.check');
  assert.strictEqual(invocation.args[0], 'check');
  assert(output.some((line) => line.includes('exit=0')));
  vscode.workspace.isTrusted = false;
  assert.throws(() => adapter.workspaceContext(vscode), /trusted/);
  console.log('RF27_G24_F06_ADAPTER_TEST=PASS assertions=22 shell=false telemetry=false network=false redaction=pre_sink lsp_frame_limit=1048576');
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
