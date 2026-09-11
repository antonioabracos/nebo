'use strict';
// Dependency-free stdio transport. No sockets, shell, telemetry or downloads.
const {spawn} = require('child_process');
class Client {
  constructor(compiler, root, notify = () => {}) {
    this.pending = new Map(); this.sequence = 0; this.buffer = Buffer.alloc(0); this.closed = false;
    this.process = spawn(compiler, ['lsp'], {cwd: root, shell: false,
      env: {PATH: '/usr/bin:/bin', HOME: root, TMPDIR: root, LC_ALL: 'C', PYTHONDONTWRITEBYTECODE: '1'}});
    this.process.stdin.on('error', error => this.close(error));
    this.process.on('error', error => this.close(error));
    this.exited = new Promise(resolve => this.process.on('exit', (code, signal) => {this.exitStatus = {code, signal}; this.close(new Error('Nebo language server exited')); resolve(this.exitStatus);}));
    this.process.stderr.on('data', () => {});
    this.process.stdout.on('data', chunk => {
      try {
        this.buffer = Buffer.concat([this.buffer, chunk]);
        if (this.buffer.length > 2097152) throw new Error('LSP receive budget');
        for (;;) {
          const end = this.buffer.indexOf('\r\n\r\n');
          if (end < 0) { if (this.buffer.length > 8192) throw new Error('LSP header budget'); break; }
          if (end > 8192) throw new Error('LSP header budget');
          const match = /^Content-Length: ([0-9]+)$/i.exec(this.buffer.subarray(0, end).toString('ascii'));
          if (!match) throw new Error('Invalid LSP framing');
          const length = Number(match[1]);
          if (length > 1048576) throw new Error('LSP message budget');
          if (this.buffer.length < end + 4 + length) break;
          const value = JSON.parse(this.buffer.subarray(end + 4, end + 4 + length).toString('utf8'));
          this.buffer = this.buffer.subarray(end + 4 + length);
          if (value.jsonrpc !== '2.0') throw new Error('Invalid JSON-RPC version');
          if (Object.hasOwn(value, 'id')) {
            const request = this.pending.get(value.id);
            if (!request) throw new Error('Unknown LSP response id');
            this.pending.delete(value.id); clearTimeout(request.timer);
            if (value.error) request.reject(new Error(value.error.message)); else request.resolve(value.result);
          } else { notify(value); }
        }
      } catch (error) { this.close(error); }
    });
  }
  send(value) {
    if (this.closed) throw new Error('LSP client closed');
    const body = Buffer.from(JSON.stringify({jsonrpc: '2.0', ...value}), 'utf8');
    if (body.length > 1048576) throw new Error('LSP send budget');
    this.process.stdin.write(Buffer.concat([Buffer.from(`Content-Length: ${body.length}\r\n\r\n`), body]));
  }
  notify(method, params) { this.send({method, params}); }
  request(method, params) {
    if (this.closed) return Promise.reject(new Error('LSP client closed'));
    if (this.pending.size >= 32) return Promise.reject(new Error('LSP pending budget'));
    return new Promise((resolve, reject) => {
      const id = ++this.sequence;
      const timer = setTimeout(() => this.close(new Error('LSP request timed out')), 45000);
      this.pending.set(id, {resolve, reject, timer});
      try { this.send({id, method, params}); } catch (error) { this.close(error); }
    });
  }
  async stop() {
    if (this.closed) return;
    let timer;
    try {
      await this.request('shutdown', null); this.notify('exit', null); this.process.stdin.end();
      await Promise.race([this.exited, new Promise((_, reject) => {timer = setTimeout(() => reject(new Error('LSP exit timed out')), 3000);})]);
    }
    finally {clearTimeout(timer); this.close(new Error('LSP client disposed'));}
  }
  close(error) {
    if (this.closed) return;
    this.closed = true;
    for (const item of this.pending.values()) { clearTimeout(item.timer); item.reject(error); }
    this.pending.clear(); this.process.kill();
  }
}
module.exports = {Client};
