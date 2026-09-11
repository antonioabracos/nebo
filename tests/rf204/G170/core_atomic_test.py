#!/usr/bin/env python3
"""Public scalar/operator probes with actual exit or retained-document oracles."""
import json
import tempfile
from pathlib import Path
from harness import pipeline

CASES = [{'id': 'int-literal', 'source': 'start(){37.return;}', 'exit': 37},
 {'id': 'char-codepoint', 'source': "start(){'Q'.codepoint().return;}", 'exit': 81},
 {'id': 'text-length', 'source': 'start(){"Nebo".byteLength().return;}', 'exit': 4},
 {'id': 'bytes-empty', 'source': 'start(){Bytes.empty().byteLength().return;}', 'exit': 0},
 {'id': 'multiply', 'source': 'start(){(7*9).return;}', 'exit': 63},
 {'id': 'divide', 'source': 'start(){(59/7).return;}', 'exit': 8},
 {'id': 'remainder', 'source': 'start(){(59%7).return;}', 'exit': 3},
 {'id': 'power', 'source': 'start(){(3^4).return;}', 'exit': 81},
 {'id': 'unicode-divide', 'source': 'start(){(59÷7).return;}', 'exit': 8},
 {'id': 'bool-literal',
  'source': 'start(){true.console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'negative',
  'source': 'start(){(-17).console();0.return;}',
  'exit': 0,
  'kinds': [4],
  'text': '-17'},
 {'id': 'bool-and',
  'source': 'start(){(true && false).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'false'},
 {'id': 'bool-or',
  'source': 'start(){(true || false).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'bool-not',
  'source': 'start(){(!false).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'less',
  'source': 'start(){(17<23).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'less-equal',
  'source': 'start(){(23<=23).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'greater',
  'source': 'start(){(37>23).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'greater-equal',
  'source': 'start(){(37>=37).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'equal',
  'source': 'start(){(37==37).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'not-equal',
  'source': 'start(){(37!=23).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'},
 {'id': 'unicode-less-equal',
  'source': 'start(){(23≤23).console();0.return;}',
  'exit': 0,
  'kinds': [5],
  'text': 'true'}]

def run():
    results=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-core-',dir='/tmp') as directory:
        root=Path(directory)
        for case in CASES:
            work=root/case['id'];work.mkdir()
            path=work/'source.no';path.write_text(case['source'])
            options={} if 'kinds' not in case else dict(kinds=case['kinds'],text=case['text'].encode())
            proof=pipeline(path,work,case['exit'],**options)
            results.append(dict(id=case['id'],result='PASS',**proof))
        # A deliberately wrong predicate must trap. Both programs use the same
        # source operands, and the reference result is computed in Python.
        import math
        for name,value,function in [('floor',3.75,math.floor),('ceil',3.25,math.ceil)]:
            expected=function(value)
            for wrong in (False,True):
                case_id=name+('-wrong-oracle' if wrong else '-assert')
                work=root/case_id;work.mkdir()
                path=work/'source.no'
                path.write_text(f'start(){{flow.assert({value}.{name}()=={expected+int(wrong)});23.return;}}')
                proof=pipeline(path,work,175 if wrong else 23)
                results.append(dict(id=case_id,result='PASS',**proof))
    return dict(cases=results,passed=len(results),total=len(CASES)+4)

if __name__=='__main__':
    print(json.dumps(run(),sort_keys=True))
