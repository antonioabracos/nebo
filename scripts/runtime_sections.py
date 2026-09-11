#!/usr/bin/env python3
"""Preserve native runtime component sections until the final ELF reachability pass.

NASM remains the assembler and GNU ld owns relocation reachability. No source
program, fixture identity, call graph guess, or expected result is inspected.
"""
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

def run(args, cwd=None):
    return subprocess.run(args, check=True, stdin=subprocess.DEVNULL,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=90, cwd=cwd).stdout

def assemble(args):
    output = Path(args[args.index('-o') + 1])
    output.parent.mkdir(parents=True, exist_ok=True)
    # Preprocessing exposes the canonical include owner of each section.
    preprocess = [a for i, a in enumerate(args) if i not in (args.index('-o'), args.index('-o')+1)]
    raw = run([preprocess[0], '-E', *preprocess[1:]]).decode()
    owner = 'runtime'; lines = []
    for line in raw.splitlines():
        marker = re.match(r'%line \d+\+\d+ (.+)$', line)
        if marker:
            owner = marker[1].strip('"')
            continue
        section = re.match(r'(\s*\[section\s+)(\.(?:text|data|rodata|bss))(?=[\s\]])', line, re.I)
        if section:
            key = hashlib.sha256(owner.encode()).hexdigest()[:16]
            name = section[2] + '.component_' + key
            # ELF-specific attributes must remain explicit for custom names.
            attrs = {'text':'progbits alloc exec nowrite','rodata':'progbits alloc noexec nowrite',
                     'data':'progbits alloc noexec write','bss':'nobits alloc noexec write'}[section[2][1:]]
            line = line[:section.start(2)] + name + ' ' + attrs + line[section.end(2):]
        lines.append(line)
    with tempfile.TemporaryDirectory(prefix='.runtime-sections-',dir=output.parent) as t:
        source = Path(t)/'runtime.asm'; source.write_text('\n'.join(lines)+'\n')
        # Already preprocessed; -a avoids a second interpretation of directives.
        run([args[0], '-a', '-f', 'elf64', '-Wall', '-Werror', '-o', str(output.absolute()), 'runtime.asm'], cwd=t)

def link(args):
    output=Path(args[0]); inputs=[Path(p) for p in args[1:]]
    output.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.runtime-link-',dir=output.parent) as t:
        objects=[]
        for index,path in enumerate(inputs):
            target=Path(t)/f'{index:04}.o'
            key=hashlib.sha256(path.as_posix().encode()).hexdigest()[:16]
            flags=[]
            for section in ('.text','.rodata','.data','.bss'):
                flags+=['--rename-section',f'{section}={section}.component_{key}']
            run(['/usr/bin/objcopy',*flags,str(path),str(target)])
            objects.append(str(target))
        run(['/usr/bin/ld','-m','elf_x86_64','-r','-z','noexecstack','--build-id=none','-o',str(output),*objects])

if __name__=='__main__':
    try:
        {'assemble':assemble,'link':link}[sys.argv[1]](sys.argv[2:])
    except subprocess.CalledProcessError as error:
        sys.stderr.buffer.write(error.stderr); raise SystemExit(error.returncode)
