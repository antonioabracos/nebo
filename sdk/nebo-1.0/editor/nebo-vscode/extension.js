'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
let client;
function verify(directory) {
  const manifest = JSON.parse(fs.readFileSync(path.join(directory, 'INTEGRITY.json'), 'utf8'));
  if (manifest.format !== 'NEBO-EDITOR-INTEGRITY-v1' || !Array.isArray(manifest.files) || manifest.files.length > 16) throw new Error('Invalid Nebo editor inventory');
  const expected = new Set(['INTEGRITY.json']);
  for (const row of manifest.files) {
    if (!/^[a-zA-Z0-9._-]+$/.test(row.path) || expected.has(row.path)) throw new Error('Invalid Nebo editor path');
    expected.add(row.path);
    const file = path.join(directory, row.path);
    if (!fs.lstatSync(file).isFile() || crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') !== row.sha256) throw new Error('Nebo editor integrity mismatch');
  }
  if (JSON.stringify([...expected].sort()) !== JSON.stringify(fs.readdirSync(directory).sort())) throw new Error('Nebo editor inventory mismatch');
}
async function activate(context) {
  const vscode = require('vscode');
  verify(context.extensionPath);
  const {Client} = require('./client');
  if (!vscode.workspace.isTrusted) return;
  const folder = vscode.workspace.workspaceFolders?.[0];
  if (!folder || folder.uri.scheme !== 'file') return;
  const sdk = vscode.workspace.getConfiguration('nebo').get('sdkPath', '');
  if (!path.isAbsolute(sdk)) { vscode.window.showErrorMessage('Set nebo.sdkPath to the absolute path of the offline SDK.'); return; }
  const range = r => new vscode.Range(r.start.line, r.start.character, r.end.line, r.end.character);
  const position = p => ({line: p.line, character: p.character});
  const document = d => ({uri: d.uri.toString()});
  const diagnostics = vscode.languages.createDiagnosticCollection('nebo');
  context.subscriptions.push(diagnostics);
  client = new Client(path.join(sdk, 'bin/neboc'), folder.uri.fsPath, value => {
    if (value.method !== 'textDocument/publishDiagnostics') return;
    const p = value.params;
    const open = vscode.workspace.textDocuments.find(d => d.uri.toString() === p.uri);
    if (!open || open.version !== p.version) return;
    diagnostics.set(open.uri, p.diagnostics.map(d => {
      const result = new vscode.Diagnostic(range(d.range), d.message, (d.severity || 1) - 1);
      result.code = d.code; result.source = d.source; return result;
    }));
  });
  try {await client.request('initialize', {rootUri: folder.uri.toString(), capabilities: {general: {positionEncodings: ['utf-16']}}});}
  catch (error) {client.close(error); throw error;}
  client.notify('initialized', {});
  const selected = d => d.languageId === 'nebo' && d.uri.scheme === 'file';
  const opened = d => { if (selected(d)) client.notify('textDocument/didOpen', {textDocument: {...document(d), languageId: 'nebo', version: d.version, text: d.getText()}}); };
  context.subscriptions.push(vscode.workspace.onDidOpenTextDocument(opened),
    vscode.workspace.onDidChangeTextDocument(e => { if (selected(e.document)) client.notify('textDocument/didChange', {textDocument: {...document(e.document), version: e.document.version}, contentChanges: [{text: e.document.getText()}]}); }),
    vscode.workspace.onDidCloseTextDocument(d => { if (selected(d)) {client.notify('textDocument/didClose', {textDocument: document(d)}); diagnostics.delete(d.uri);} }));
  vscode.workspace.textDocuments.forEach(opened);
  const selector = {language: 'nebo', scheme: 'file'};
  const ask = async (method, d, params = {}) => {
    const version = d.version;
    const result = await client.request(method, {textDocument: document(d), ...params});
    if (d.version !== version) throw new Error('Nebo document changed during request');
    return result;
  };
  context.subscriptions.push(vscode.languages.registerDocumentFormattingEditProvider(selector, {
    provideDocumentFormattingEdits: async d => (await ask('textDocument/formatting', d)).map(e => vscode.TextEdit.replace(range(e.range), e.newText))
  }), vscode.languages.registerHoverProvider(selector, {
    provideHover: async (d, p) => {const r = await ask('textDocument/hover', d, {position: position(p)}); return new vscode.Hover(new vscode.MarkdownString(r.contents.value), range(r.range));}
  }), vscode.languages.registerDefinitionProvider(selector, {
    provideDefinition: async (d, p) => (await ask('textDocument/definition', d, {position: position(p)})).map(r => new vscode.Location(vscode.Uri.parse(r.uri), range(r.range)))
  }), vscode.languages.registerReferenceProvider(selector, {
    provideReferences: async (d, p, c) => (await ask('textDocument/references', d, {position: position(p), context: c})).map(r => new vscode.Location(vscode.Uri.parse(r.uri), range(r.range)))
  }), vscode.languages.registerCompletionItemProvider(selector, {
    provideCompletionItems: async (d, p) => {const r = await ask('textDocument/completion', d, {position: position(p)}); return new vscode.CompletionList(r.items.map(item => {const c = new vscode.CompletionItem(item.label, (item.kind || 1) - 1); c.sortText = item.sortText; c.insertText = item.insertText; c.nebo = item; return c;}), r.isIncomplete);},
    resolveCompletionItem: async c => {const r = await client.request('completionItem/resolve', c.nebo); c.detail = r.detail; c.documentation = new vscode.MarkdownString(r.documentation.value); c.additionalTextEdits = (r.additionalTextEdits || []).map(e => vscode.TextEdit.replace(range(e.range), e.newText)); return c;}
  }, '.'), vscode.languages.registerRenameProvider(selector, {
    provideRenameEdits: async (d, p, newName) => {
      const r = await ask('textDocument/rename', d, {position: position(p), newName});
      const edit = new vscode.WorkspaceEdit();
      for (const [uri, rows] of Object.entries(r.changes)) for (const e of rows) {
        const annotation = e.annotationId && r.changeAnnotations?.[e.annotationId];
        edit.replace(vscode.Uri.parse(uri), range(e.range), e.newText, annotation || undefined);
      }
      return edit;
    }
  }), {dispose: () => {if (client) client.close(new Error('Extension disposed'));}});
}
async function deactivate() {if (client) await client.stop(); client = undefined;}
module.exports = {activate, deactivate, verify};
