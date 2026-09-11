#!/usr/bin/env python3
"""G170 atomic source-to-effect validation, with fail-closed coverage gates."""
import argparse
import csv
import hashlib
import json
import re
import sys
import tempfile
import time
from pathlib import Path

from harness import ROOT, Failure, pipeline, reject, campaign_stats
from inventory import inventory

HERE = Path(__file__).resolve().parent

def relative(value):
    if not isinstance(value, str) or not re.fullmatch(r'[A-Za-z0-9_./-]+', value):
        raise Failure('CASE_PATH')
    path = ROOT / value
    if '..' in Path(value).parts or not path.resolve().is_relative_to(ROOT):
        raise Failure('CASE_PATH_ESCAPE')
    if not path.is_file() or path.is_symlink():
        raise Failure('CASE_FILE')
    return path

def load_cases():
    data = json.loads((HERE / 'cases.json').read_text())
    if data.get('schema') != 1 or data.get('target') != 'x86_64-systemv-elf-linux':
        raise Failure('CASE_SCHEMA_OR_TARGET')
    cases = data['cases'] + data['negative']
    if not 1 <= len(cases) <= 512:
        raise Failure('CASE_BUDGET')
    ids = set()
    for case in cases:
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]{0,63}', case['id']) or case['id'] in ids:
            raise Failure('CASE_ID_OR_DUPLICATE')
        ids.add(case['id'])
        if not re.fullmatch(r'F(0[1-9]|1[0-2])', case['front']):
            raise Failure('CASE_FRONT')
        relative(case['source'])
        for unit in case.get('units', []):
            relative(unit)
    return data

def mathematical_oracle(case):
    if case['surface']=='std.math.public-body-return':
        match = re.search(r'\b([0-9]+)\.return;\s*}\s*$', relative(case['source']).read_text())
        if not match or int(match[1]) != case['exit']:
            raise Failure('EXPLICIT_RETURN_ORACLE')
        return
    if not case['surface'].startswith('std.math.'):
        return
    source = relative(case['source']).read_text()
    source = re.sub(r'/\*.*?\*/|//[^\n]*', '', source, flags=re.S)
    match = re.search(r'std\s*\.\s*math\s*\.\s*(max|min|abs|clamp)\s*\(([^)]*)\)', source)
    if not match:
        raise Failure('MATH_ORACLE_SYNTAX')
    values = [int(value.strip()) for value in match[2].split(',')]
    name = match[1]
    if name == 'max': value = max(values)
    elif name == 'min': value = min(values)
    elif name == 'abs': value = abs(values[0])
    else: value = min(max(values[0], values[1]), values[2])
    if value % 256 != case['exit']:
        raise Failure('MATH_ORACLE_MANIFEST_MISMATCH')

def run_suite(name, action):
    started=time.monotonic()
    print('G170_SUITE_BEGIN '+name, file=sys.stderr, flush=True)
    try:
        result=action()
    except Failure as error:
        raise Failure(name+':'+str(error)) from error
    print(f"G170_SUITE_END {name} {result['passed']}/{result['total']} {time.monotonic()-started:.3f}s",
          file=sys.stderr, flush=True)
    return result


def validate(front=None):
    if front is not None and not re.fullmatch(r'RF172-G170-F(0[1-9]|1[0-2])', front):
        raise Failure('FRONT_SELECTOR')
    selected = front[-3:] if front else None
    # F12 is the whole-group audit, so it must replay every original case as
    # well as all supplemental suites. Other selectors report only their front.
    if selected == 'F12':
        selected = None
    data = load_cases()
    result = dict(schema=1, group='G170', target=data['target'], result='FAIL', cases=[],
                  network='DENIED_BY_SECCOMP', live_window='NOT_REQUESTED',
                  inventory_claims=len(inventory()),
                  coverage_scope='SELECTED_FRONT' if selected else 'WHOLE_GROUP')
    with tempfile.TemporaryDirectory(prefix='nebo-G170-', dir='/tmp') as directory:
        root = Path(directory)
        for negative, cases in ((False, data['cases']), (True, data['negative'])):
            for case in cases:
                if selected and case['front'] != selected:
                    continue
                work = root / case['id']
                work.mkdir()
                observed = dict(id=case['id'], front=case['front'], result='FAIL',
                                category='negative' if negative else case['category'])
                try:
                    if negative:
                        observed.update(reject(relative(case['source']), work, case['code']))
                    else:
                        mathematical_oracle(case)
                        args = {k: case[k].encode('utf-8') for k in ('stdin','text','prompt','stdout') if k in case}
                        if 'kinds' in case: args['kinds'] = case['kinds']
                        args['units'] = [relative(unit) for unit in case.get('units', [])]
                        observed.update(pipeline(relative(case['source']), work, case['exit'], **args))
                    observed['result'] = 'PASS'
                except Failure as error:
                    observed['failure'] = str(error).replace(str(root), '<scratch>')
                result['cases'].append(observed)
    result['temporary_artifacts_removed'] = not root.exists()
    passed = {case['id'] for case in result['cases'] if case['result'] == 'PASS'}
    with (HERE / 'SURFACE-MAP.tsv').open() as stream:
        surfaces = list(csv.DictReader(stream, delimiter='\t'))
    if {row['front'] for row in surfaces} != {f'F{i:02d}' for i in range(1,13)}:
        raise Failure('MISSING_FRONT_COVERAGE')
    gates = []
    for row in surfaces:
        if selected and row['front'] != selected: continue
        dependencies = set(row['cases'].split(','))
        complete = row['status'] == 'PASS' and dependencies <= passed
        gates.append(dict(front=row['front'], result='PASS' if complete else 'FAIL',
                          reason=row['remaining_obligation']))
    result['gates'] = gates
    result['passed'] = len(passed)
    result['total'] = len(result['cases'])
    result['fronts_passed'] = sum(gate['result'] == 'PASS' for gate in gates)
    result['fronts_total'] = len(gates)
    result['manifest_sha256'] = hashlib.sha256((HERE / 'cases.json').read_bytes()).hexdigest()
    from coverage import reconcile
    result['public_coverage'] = reconcile()
    if selected in (None, 'F01', 'F12'):
        from metadata_test import run as metadata_regressions
        result['metadata_regressions'] = run_suite('metadata_regressions', metadata_regressions)
    if selected in (None, 'F02', 'F12'):
        from self_test import main as oracle_self_tests
        result['runner_self_tests'] = run_suite('runner_self_tests', lambda: oracle_self_tests(report=False))
    if selected in (None, 'F09', 'F12'):
        from math_return_test import run as math_return_regressions
        result['math_return_regressions'] = run_suite('math_return_regressions', math_return_regressions)
        from precision_test import run as precision_regressions
        result['precision_regressions'] = run_suite('precision_regressions', precision_regressions)
        from float_literal_test import run as float_literal_regressions
        result['float_literal_regressions'] = run_suite('float_literal_regressions', float_literal_regressions)
        from vector_test import run as vector_regressions
        result['vector_regressions'] = run_suite('vector_regressions', vector_regressions)
        from statistics_test import run as statistics_regressions
        result['statistics_regressions'] = run_suite('statistics_regressions', statistics_regressions)
        from random_test import run as random_regressions
        result['random_regressions'] = run_suite('random_regressions', random_regressions)
        from matrix_test import run as matrix_regressions
        result['matrix_regressions'] = run_suite('matrix_regressions', matrix_regressions)
        from tensor_test import run as tensor_regressions
        result['tensor_regressions'] = run_suite('tensor_regressions', tensor_regressions)
    if selected in (None, 'F11', 'F12'):
        from scan_public_test import run as scan_public_regressions
        result['scan_public_regressions'] = run_suite('scan_public_regressions', scan_public_regressions)
    if selected in (None, 'F10', 'F12'):
        from console_public_test import run as console_public_regressions
        result['console_public_regressions'] = run_suite('console_public_regressions', console_public_regressions)
    if selected in (None, 'F03', 'F08', 'F12'):
        from core_atomic_test import run as core_atomic_regressions
        result['core_atomic_regressions'] = run_suite('core_atomic_regressions', core_atomic_regressions)
    if selected in (None, 'F08', 'F12'):
        from regex_test import run as regex_regressions
        result['regex_regressions'] = run_suite('regex_regressions', regex_regressions)
        from slash_test import run as slash_regressions
        result['slash_regressions'] = run_suite('slash_regressions', slash_regressions)
        from operator_test import run as operator_regressions
        result['operator_regressions'] = run_suite('operator_regressions', operator_regressions)
        from linear_test import run as linear_regressions
        result['linear_regressions'] = run_suite('linear_regressions', linear_regressions)
        from bounded_operator_test import run as bounded_operator_regressions
        result['bounded_operator_regressions'] = run_suite('bounded_operator_regressions', bounded_operator_regressions)
        from text_test import run as text_regressions
        result['text_regressions'] = run_suite('text_regressions', text_regressions)
        from text_parse_test import run as text_parse_regressions
        result['text_parse_regressions'] = run_suite('text_parse_regressions', text_parse_regressions)
        from format_test import run as format_regressions
        result['format_regressions'] = run_suite('format_regressions', format_regressions)
        from interpolation_test import run as interpolation_regressions
        result['interpolation_regressions'] = run_suite('interpolation_regressions', interpolation_regressions)
    if selected in (None, 'F03', 'F12'):
        from binding_test import run as binding_regressions
        result['binding_regressions'] = run_suite('binding_regressions', binding_regressions)
    if selected in (None, 'F04', 'F12'):
        from control_test import run as control_regressions
        result['control_regressions'] = run_suite('control_regressions', control_regressions)
    if selected in (None, 'F05', 'F12'):
        from filesystem_test import run as filesystem_regressions
        result['filesystem_regressions'] = run_suite('filesystem_regressions', filesystem_regressions)
        from module_test import run as module_regressions
        result['module_regressions'] = run_suite('module_regressions', module_regressions)
    if selected in (None, 'F06', 'F12'):
        from composite_test import run as composite_regressions
        result['composite_regressions'] = run_suite('composite_regressions', composite_regressions)
        from ownership_test import run as ownership_regressions
        result['ownership_regressions'] = run_suite('ownership_regressions', ownership_regressions)
        from option_result_test import run as option_result_regressions
        result['option_result_regressions'] = run_suite('option_result_regressions', option_result_regressions)
    if selected in (None, 'F07', 'F12'):
        from dict_test import run as dict_regressions
        result['dict_regressions'] = run_suite('dict_regressions', dict_regressions)
        from sequential_test import run as sequential_regressions
        result['sequential_regressions'] = run_suite('sequential_regressions', sequential_regressions)
        from relational_test import run as relational_regressions
        result['relational_regressions'] = run_suite('relational_regressions', relational_regressions)
        from data_test import run as data_regressions
        result['data_regressions'] = run_suite('data_regressions', data_regressions)
        from hash_policy_test import run as hash_policy_regressions
        result['hash_policy_regressions'] = run_suite('hash_policy_regressions', hash_policy_regressions)
        required = dict(id='required-dict-empty', front='F07', result='FAIL', expected_exit=0)
        with tempfile.TemporaryDirectory(prefix='nebo-G170-required-', dir='/tmp') as directory:
            try:
                required.update(pipeline(HERE/'reproducers/dict-empty.no', Path(directory), 0))
                required['result'] = 'PASS'
            except Failure as error:
                required['failure'] = str(error).replace(directory, '<scratch>')
        result['required_surface_probes'] = [required]
    # Supplemental cases are actual executions, and must participate in both
    # dependency resolution and the terminal decision. Keep the original
    # atomic case count separate so its 39-case baseline remains observable.
    all_passed = set(passed)
    suites = []
    for key, prefix in (('runner_self_tests','self'),
                        ('math_return_regressions','math'),
                        ('precision_regressions','precision'),
                        ('float_literal_regressions','literal'),
                        ('vector_regressions','vector'),
                        ('statistics_regressions','statistics'),
                        ('random_regressions','random'),
                        ('matrix_regressions','matrix'),
                        ('tensor_regressions','tensor'),
                        ('core_atomic_regressions','core'),
                        ('operator_regressions','operator'),
                        ('linear_regressions','linear'),
                        ('bounded_operator_regressions','boundedoperator'),
                        ('text_regressions','text'),
                        ('text_parse_regressions','textparse'),
                        ('format_regressions','format'),
                        ('interpolation_regressions','interpolation'),
                        ('binding_regressions','binding'),
                        ('control_regressions','control'),
                        ('module_regressions','module'),
                        ('composite_regressions','composite'),
                        ('ownership_regressions','ownership'),
                        ('option_result_regressions','optionresult'),
                        ('dict_regressions','dict'),
                        ('sequential_regressions','sequence'),
                        ('relational_regressions','relation'),
                        ('data_regressions','data'),
                        ('hash_policy_regressions','hashpolicy'),
                        ('console_public_regressions','console'),
                        ('scan_public_regressions','scan'),
                        ('metadata_regressions','metadata'),
                        ('filesystem_regressions','filesystem'),
                        ('regex_regressions','regex'),
                        ('slash_regressions','slash')):
        if key in result:
            suite = result[key]
            suites.append(suite)
            all_passed.update(prefix+':'+case['id'] for case in suite['cases']
                              if case['result']=='PASS')
    all_passed.update(case['id'] for case in result.get('required_surface_probes',[])
                      if case['result']=='PASS')
    result['public_coverage'] = reconcile(proven_ids=all_passed)
    for gate in gates:
        row = next(row for row in surfaces if row['front']==gate['front'])
        gate['result'] = ('PASS' if row['status']=='PASS' and
                          set(row['cases'].split(',')) <= all_passed else 'FAIL')
    result['fronts_passed'] = sum(gate['result']=='PASS' for gate in gates)
    if (result['passed'] == result['total'] and all(gate['result'] == 'PASS' for gate in gates)
            and (selected is not None or result['public_coverage']['result'] == 'PASS')
            and all(suite['passed']==suite['total'] for suite in suites)
            and all(x['result']=='PASS' for x in result.get('required_surface_probes', []))):
        result['result'] = 'PASS'
    return result

def run(front=None, output=None):
    try:
        result = validate(front)
    except (Failure, OSError, ValueError, KeyError, TypeError) as error:
        result = dict(schema=1, group='G170', result='FAIL', first_failure=str(error))
    result['campaign_budget'] = campaign_stats()
    if output is not None:
        output = Path(output)
        if output.is_symlink() or not output.parent.is_dir():
            raise Failure('RESULT_PATH')
        if not (output.resolve().is_relative_to(ROOT) or output.resolve().is_relative_to('/tmp')):
            raise Failure('RESULT_PATH_ESCAPE')
        output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0 if result['result'] == 'PASS' else 1

def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('--front')
    parser.add_argument('--result-json')
    args = parser.parse_args(argv)
    return run(args.front, args.result_json)

if __name__ == '__main__':
    sys.exit(main())
