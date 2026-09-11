#!/usr/bin/env python3
import runpy,sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
modules=root/'libexec/nebo/modules'
sys.path.insert(0,str(modules if modules.is_dir() else root))
runpy.run_module('compiler.sdk.sdk_builder',run_name='__main__')
