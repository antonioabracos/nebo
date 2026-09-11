#!/usr/bin/env python3
"""Historical corpus decisions and real exact-alias differential execution."""
import sys,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[3];sys.path.insert(0,str(root));sys.path.insert(0,str(root/'tests/rf204/G170'))
from compiler.migration.semantic_migration import plan_files,apply_plan,rollback
from harness import pipeline
with tempfile.TemporaryDirectory() as raw:
    work=Path(raw);source=work/'source.no';source.write_text('start(){(73 ⊻ 19).return;}\n')
    a=work/'a';a.mkdir();before=pipeline(source,a,73^19)
    plan=plan_files([source]);apply_plan(plan,work/'journal')
    b=work/'b';b.mkdir();after=pipeline(source,b,73^19)
    assert before['elf_sha256']==after['elf_sha256'] and not plan_files([source])['files'][0]['edits']
    rollback(work/'journal')
print('RF204-G190-F07=PASS')
