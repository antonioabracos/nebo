"""Adversarial release identity checks use mutations of authenticated inputs."""
import csv
import io
import json
from finalization import (ENV, IDENTITY, INVENTORY, PROVENANCE, VALIDATION,
                          MANIFEST, OLD_STATE, READY_STATE, STATE, RELEASE_DATE,
                          RELEASE_TIMESTAMP, TAG, validate, read_texts)


def run(texts):
    paths = {row['path'] for name in (INVENTORY, MANIFEST)
             for row in csv.DictReader(io.StringIO(texts[name]), delimiter='\t')}
    texts = {path: texts[path] for path in paths}
    cases = []

    def test(name, change, accepted=False):
        fixture = dict(texts)
        change(fixture)
        try:
            validate(fixture)
            result = True
        except (AssertionError, ValueError, KeyError, TypeError, IndexError):
            result = False
        assert result == accepted, ('release state adversary', name)
        cases.append({'id': name, 'status': 'PASS', 'accepted': accepted})

    def replace(path, before, after):
        def change(fixture):
            assert before in fixture[path]
            fixture[path] = fixture[path].replace(before, after)
        return change

    def field(path, name, value):
        def change(fixture):
            data = json.loads(fixture[path]); data[name] = value
            fixture[path] = json.dumps(data)
        return change

    test('final-release-state-accepted', lambda f: None, True)
    for bad in (READY_STATE, OLD_STATE, 'PUBLISHED'):
        test('wrong-current-state-' + bad, replace(ENV, 'STATUS=' + STATE, 'STATUS=' + bad))
    test('undated-changelog-rejected', replace('CHANGELOG.md', '## [1.1.0] - ' + RELEASE_DATE, '## [1.1.0] - Un' + 'released'))
    for key, before, after in [
        ('date', RELEASE_DATE, '2026-01-01'),
        ('timestamp', RELEASE_TIMESTAMP, '2026-01-01T00:00:00Z'),
        ('tag', TAG, 'nebo-v1.0.1'),
        ('version', 'VERSION=1.1.0', 'VERSION=1.0.1'),
        ('edition', 'EDITION=1.0', 'EDITION=2.0'),
        ('authorization', 'PUBLICATION_AUTHORIZATION=RELEASE_GO\n', ''),
        ('findings', 'OPEN_FINDINGS=0', 'OPEN_FINDINGS=1'),
    ]:
        test('wrong-' + key + '-rejected', replace(IDENTITY, before, after))
    previous_version = '1.0.1'
    test('stale-latest-release-rejected', replace('README.md', 'Latest published release: `1.1.0`', 'Latest published release: `' + previous_version + '`'))
    test('document-date-drift-rejected', replace('README.md', RELEASE_DATE, '2026-01-01'))
    test('document-timestamp-drift-rejected', replace('README.md', RELEASE_TIMESTAMP, '2026-01-01T00:00:00Z'))
    test('document-tag-drift-rejected', replace('README.md', TAG, 'nebo-v1.0.1'))
    test('document-tag-header-drift-with-valid-link-rejected', replace('README.md', 'Tag: `' + TAG + '`', 'Tag: `nebo-v1.0.1`'))
    test('published-without-date-rejected', lambda f: f.__setitem__(IDENTITY, f[IDENTITY].replace('STATUS=' + STATE, 'STATUS=PUBLISHED').replace('RELEASE_DATE=' + RELEASE_DATE + '\n', '')))
    test('wrong-main-commit-rejected', field(PROVENANCE, 'source_integration_commit', '0' * 40))
    test('wrong-main-tree-rejected', field(PROVENANCE, 'source_integration_tree', '0' * 40))
    test('wrong-ci-run-rejected', field(VALIDATION, 'post_merge_ci_run', 1))
    test('failed-ci-rejected', field(VALIDATION, 'post_merge_ci', 'FAIL'))
    test('wrong-provenance-clock-rejected', field(PROVENANCE, 'release_timestamp_utc', '2026-01-01T00:00:00Z'))
    test('stale-operational-field-rejected', lambda f: f.__setitem__(ENV, f[ENV] + 'TAG_CREATED=NO\n'))
    test('stale-validation-operational-field-rejected', field(VALIDATION, 'assets_uploaded', 0))
    test('duplicate-env-key-rejected', lambda f: f.__setitem__(ENV, f[ENV] + 'STATUS=' + STATE + '\n'))
    test('duplicate-inventory-row-rejected', lambda f: f.__setitem__(INVENTORY, f[INVENTORY] + f[INVENTORY].splitlines()[1] + '\n'))
    test('release-copy-drift-rejected', lambda f: f.__setitem__('docs/public/v1.0/releases/NEBO-1.1.0-RELEASE-NOTES.md', f['docs/public/v1.0/releases/NEBO-1.1.0-RELEASE-NOTES.md'] + '\n'))
    test('unclassified-current-owner-rejected', lambda f: f.__setitem__('release/new-owner.txt', 'Status: ' + READY_STATE))

    def observed_expectation(fixture):
        for path in fixture:
            # Consistently changing observed documents and declared derived
            # owners cannot redefine the independently reviewed expected clock.
            if path not in (INVENTORY, MANIFEST):
                fixture[path] = fixture[path].replace(RELEASE_DATE, '2026-01-01')
    test('expected-derived-from-observed-rejected', observed_expectation)
    test('empty-scan-rejected', lambda f: f.clear())

    def historical(fixture, classified):
        path = 'docs/releases/history/pr-2-state.txt'
        value = 'Historical PR #2 state: ' + READY_STATE + '.'
        fixture[path] = value + '\n'
        if classified:
            reader = csv.DictReader(io.StringIO(fixture[INVENTORY]), delimiter='\t')
            fields = reader.fieldnames; rows = list(reader)
            rows.append(dict(path=path, line_or_field='line:1', observed=value,
                             classification='HISTORICAL_FINALIZATION_PR_RECORD',
                             action='PRESERVE', expected_after=value,
                             validation='Exact explicitly classified historical observation'))
            out = io.StringIO(); writer = csv.DictWriter(out, fieldnames=fields, delimiter='\t', lineterminator='\n')
            writer.writeheader(); writer.writerows(rows); fixture[INVENTORY] = out.getvalue()
    test('unclassified-historical-state-rejected', lambda f: historical(f, False))
    test('classified-historical-state-accepted', lambda f: historical(f, True), True)

    class Unreadable:
        def __truediv__(self, name):
            return self
        def read_bytes(self):
            raise OSError('synthetic unreadable input')
    try:
        read_texts(Unreadable(), ['README.md'])
    except OSError:
        cases.append({'id': 'scan-exception-fails-closed', 'status': 'PASS', 'accepted': False})
    else:
        raise AssertionError('scan failure was swallowed')
    try:
        read_texts(Unreadable(), [])
    except AssertionError:
        cases.append({'id': 'empty-file-inventory-rejected', 'status': 'PASS', 'accepted': False})
    else:
        raise AssertionError('empty file inventory accepted')
    return {'status': 'PASS', 'cases': cases, 'passed': len(cases), 'total': len(cases)}


if __name__ == '__main__':
    import subprocess
    from finalization import ROOT
    names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=ROOT).decode().split('\0')
    print(json.dumps(run(read_texts(ROOT, sorted({n for n in names if n}))), sort_keys=True))
