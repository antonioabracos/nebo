#!/usr/bin/env python3
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.compat.compatibility_diff import compare
base={'api':{'nebo://a':{'signature':'fn()'}}}; same=compare(base,base); assert same['required_bump']=='NONE' and not same['changes']
add=compare(base,{'api':{**base['api'],'nebo://b':{'signature':'fn()'}}}); assert add['required_bump']=='MINOR' and not add['blockers']
remove=compare(base,{'api':{}}); assert remove['required_bump']=='MAJOR' and remove['blockers']
security=compare({'security':{'nebo://x':{'revoked':False}}},{'security':{'nebo://x':{'revoked':True}}}); assert security['required_bump']=='SECURITY'
assert compare(base,{'api':{}})==remove
print('RF204-G191-F07=PASS')
