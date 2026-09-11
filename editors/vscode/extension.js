'use strict';

const path = require('path');
const childProcess = require('child_process');

const MAX_FRAME = 1_048_576;
const COMMANDS = Object.freeze({
  'nebo.check': ['check'],
  'nebo.build': ['build'],
  'nebo.emitAsm': ['emit-asm']
});

function localPath(root, configured) {
  if (typeof configured !== 'string' || configured.length === 0 || configured.includes('\0')) {
    throw new Error('invalid local tool path');
  }
  return path.isAbsolute(configured) ? path.normalize(configured) : path.resolve(root, configured);
}

function redact(text) {
  return String(text).split(/\r?\n/).map((line) =>
    /(?:secret|token|api[-_]?key|password)/i.test(line) ? '[REDACTED]' : line
  ).join('\n');
}

function boundedAppend(current, chunk, limit) {
  const next = current + chunk.toString('utf8');
  if (Buffer.byteLength(next) > limit) throw new Error('tool output budget exceeded');
  return next;
}

function runLocal(spawn, executable, args, cwd, limit) {
  return new Promise((resolve, reject) => {
    const processHandle = spawn(executable, args, {
      cwd,
      shell: false,
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
      env: { PATH: process.env.PATH || '', LANG: 'C.UTF-8', LC_ALL: 'C.UTF-8' }
    });
    let stdout = '', stderr = '', settled = false;
    const consume = (kind) => (chunk) => {
      try {
        if (kind === 'stdout') stdout = boundedAppend(stdout, chunk, limit);
        else stderr = boundedAppend(stderr, chunk, limit);
      } catch (error) {
        processHandle.kill();
        if (!settled) { settled = true; reject(error); }
      }
    };
    processHandle.stdout.on('data', consume('stdout'));
    processHandle.stderr.on('data', consume('stderr'));
    processHandle.on('error', (error) => { if (!settled) { settled = true; reject(error); } });
    processHandle.on('close', (code, signal) => {
      if (!settled) { settled = true; resolve({ code, signal, stdout: redact(stdout), stderr: redact(stderr) }); }
    });
  });
}

function encodeFrame(value) {
  const body = Buffer.from(JSON.stringify(value), 'utf8');
  if (body.length > MAX_FRAME) throw new Error('LSP frame budget exceeded');
  return Buffer.concat([Buffer.from(`Content-Length: ${body.length}\r\n\r\n`, 'ascii'), body]);
}

function decodeFrames(buffer) {
  const frames = [];
  let offset = 0;
  while (true) {
    const end = buffer.indexOf('\r\n\r\n', offset, 'ascii');
    if (end < 0) break;
    const header = buffer.subarray(offset, end).toString('ascii');
    const match = /^Content-Length: ([0-9]+)$/im.exec(header);
    if (!match) throw new Error('invalid LSP header');
    const length = Number(match[1]);
    if (!Number.isSafeInteger(length) || length > MAX_FRAME) throw new Error('LSP frame budget exceeded');
    const start = end + 4;
    if (buffer.length - start < length) break;
    frames.push(JSON.parse(buffer.subarray(start, start + length).toString('utf8')));
    offset = start + length;
  }
  return { frames, rest: buffer.subarray(offset) };
}

function workspaceContext(vscode) {
  if (!vscode.workspace.isTrusted) throw new Error('Nebo tools require a trusted workspace');
  const editor = vscode.window.activeTextEditor;
  if (!editor || editor.document.languageId !== 'nebo' || editor.document.uri.scheme !== 'file') {
    throw new Error('open a local Nebo document');
  }
  const folder = vscode.workspace.getWorkspaceFolder(editor.document.uri);
  if (!folder) throw new Error('document is outside the workspace');
  return { editor, root: folder.uri.fsPath };
}

async function executeCommand(vscode, spawn, command) {
  const { editor, root } = workspaceContext(vscode);
  await editor.document.save();
  const config = vscode.workspace.getConfiguration('nebo');
  const compiler = localPath(root, config.get('compilerPath', 'build/bin/neboc'));
  const limit = config.get('maxOutputBytes', MAX_FRAME);
  const args = [...COMMANDS[command], editor.document.uri.fsPath];
  const result = await runLocal(spawn, compiler, args, root, limit);
  const output = vscode.window.createOutputChannel('Nebo');
  output.appendLine(`[${command}] exit=${result.code} signal=${result.signal || 'none'}`);
  if (result.stdout) output.appendLine(result.stdout);
  if (result.stderr) output.appendLine(result.stderr);
  output.show(true);
  if (result.code !== 0) throw new Error(`neboc ${COMMANDS[command][0]} failed`);
  return result;
}

function activate(context) {
  const vscode = require('vscode');
  for (const command of Object.keys(COMMANDS)) {
    context.subscriptions.push(vscode.commands.registerCommand(command, () =>
      executeCommand(vscode, childProcess.spawn, command).catch((error) => vscode.window.showErrorMessage(redact(error.message)))
    ));
  }
  context.subscriptions.push(vscode.commands.registerCommand('nebo.format', async () => {
    const { editor, root } = workspaceContext(vscode);
    const config = vscode.workspace.getConfiguration('nebo');
    const formatter = localPath(root, 'tools/rf27-format.py');
    const compiler = localPath(root, config.get('compilerPath', 'build/bin/neboc'));
    await editor.document.save();
    const result = await runLocal(childProcess.spawn, config.get('pythonPath', 'python3'),
      [formatter, '--compiler', compiler, editor.document.uri.fsPath], root, config.get('maxOutputBytes', MAX_FRAME));
    if (result.code !== 0) vscode.window.showErrorMessage(redact(result.stderr || 'Nebo formatter failed'));
  }));
  return { transport: 'stdio', telemetry: false, network: false, lsp: 'tools/rf27-lsp.py' };
}

function deactivate() {}

module.exports = { activate, deactivate, _test: { localPath, redact, boundedAppend, runLocal, encodeFrame, decodeFrames, workspaceContext, executeCommand, COMMANDS, MAX_FRAME } };
