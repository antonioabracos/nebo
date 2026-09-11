"""Reuse current source-to-effect owners without duplicating their oracles."""
import argparse
import importlib
import json
from pathlib import Path
import sys
import time

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/rf204/G170'))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('suite', choices=['sequential', 'data', 'matrix', 'tensor',
                                        'control', 'binding', 'self', 'console_public', 'scan_public', 'relational', 'filesystem'])
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    start = time.monotonic()
    owner = importlib.import_module(args.suite + '_test')
    result = owner.main(report=False) if args.suite == 'self' else owner.run()
    result['elapsed_seconds'] = round(time.monotonic() - start, 6)
    result['suite'] = args.suite
    result['status'] = 'PASS' if result['passed'] == result['total'] and result['total'] > 0 else 'FAIL'
    args.report.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({k: result[k] for k in ('suite', 'passed', 'total', 'status', 'elapsed_seconds')}))
    raise SystemExit(result['status'] != 'PASS')
