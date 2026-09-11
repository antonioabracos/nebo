#!/usr/bin/env python3
"""Regression for source-verified migration and exact journal rollback."""
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];sys.path.insert(0,str(ROOT))
from compiler.migration.semantic_migration import plan_files,apply_plan,rollback,MigrationError
with tempfile.TemporaryDirectory(prefix='nebo-G192-legacy-regression-') as raw:
 root=Path(raw);source=root/'x.no';source.write_text('start(){(41 ⊻ 7).return;}\n');before=source.read_bytes();journal=root/'journal'
 plan=plan_files([source],root=root);assert len(plan['files'][0]['edits'])==1
 assert apply_plan(plan,journal)==1 and 'xor' in source.read_text()
 rollback(journal);assert source.read_bytes()==before and not journal.exists()
 source.write_text('print(1)\n');before=source.read_bytes()
 try:plan_files([source],root=root)
 except MigrationError:pass
 else:raise AssertionError('invalid source admitted')
 assert source.read_bytes()==before and not journal.exists()
print('RF204-G192-F02=PASS')
