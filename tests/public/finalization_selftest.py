"""Known-bad publication metadata must fail without changing source files."""
import csv
import io
import json
from finalization import ENV, INVENTORY, PROVENANCE, VALIDATION, MANIFEST, OLD_STATE, STATE, validate


def run(texts):
    # Mutation fixtures include every declared owner and changed path; the caller
    # separately scans the complete source tree using the same validation function.
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
        except (AssertionError, ValueError, KeyError, TypeError):
            result = False
        assert result == accepted, ('finalization adversary', name)
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

    test('unchanged-unreleased-phase-accepted', lambda f: None, True)
    test('old-current-state-rejected', replace(ENV, 'STATUS=' + STATE, 'STATUS=' + OLD_STATE))
    test('published-state-rejected', replace(ENV, 'STATUS=' + STATE, 'STATUS=PUBLISHED'))
    test('latest-release-claim-rejected', replace('README.md', 'Latest published release: `1.0.1`', 'Latest published release: `1.1.0`'))
    test('tag-created-rejected', replace(ENV, 'TAG_CREATED=NO', 'TAG_CREATED=YES'))
    test('release-created-rejected', replace(ENV, 'GITHUB_RELEASE_CREATED=NO', 'GITHUB_RELEASE_CREATED=YES'))
    test('assets-uploaded-rejected', replace(ENV, 'ASSETS_UPLOADED=0', 'ASSETS_UPLOADED=1'))
    test('wrong-main-commit-rejected', field(PROVENANCE, 'source_integration_commit', '0' * 40))
    test('wrong-main-tree-rejected', field(PROVENANCE, 'source_integration_tree', '0' * 40))
    test('wrong-ci-run-rejected', field(VALIDATION, 'post_merge_ci_run', 1))
    test('failed-ci-rejected', field(VALIDATION, 'post_merge_ci', 'FAIL'))
    test('date-set-rejected', replace(ENV, 'RELEASE_DATE=UNSET', 'RELEASE_DATE=2026-01-01'))
    test('dated-changelog-rejected', replace('CHANGELOG.md', '## [1.1.0] - Unreleased', '## [1.1.0] - 2026-01-01'))
    test('false-published-prose-rejected', lambda f: f.__setitem__('README.md', f['README.md'] + '\nNebo 1.1.0 is published.\n'))
    test('false-download-prose-rejected', lambda f: f.__setitem__('README.md', f['README.md'] + '\nDownload the 1.1.0 release assets.\n'))
    test('boolean-asset-count-rejected', field(VALIDATION, 'assets_uploaded', False))
    test('duplicate-env-key-rejected', lambda f: f.__setitem__(ENV, f[ENV] + 'STATUS=' + STATE + '\n'))
    test('unclassified-new-current-owner-rejected', lambda f: f.__setitem__('release/new-owner.txt', 'Status: ' + OLD_STATE))
    test('duplicate-inventory-row-rejected', lambda f: f.__setitem__(INVENTORY, f[INVENTORY] + f[INVENTORY].splitlines()[1] + '\n'))
    test('release-copy-drift-rejected', lambda f: f.__setitem__('docs/public/v1.0/releases/NEBO-1.1.0-RELEASE-NOTES.md', f['docs/public/v1.0/releases/NEBO-1.1.0-RELEASE-NOTES.md'] + '\n'))

    def historical(fixture, classified):
        path = 'docs/releases/history/pr-1-state.txt'
        value = 'Historical PR #1 state: ' + OLD_STATE + '.'
        fixture[path] = value + '\n'
        if classified:
            reader = csv.DictReader(io.StringIO(fixture[INVENTORY]), delimiter='\t')
            fields = reader.fieldnames; rows = list(reader)
            rows.append(dict(path=path, line_or_field='line:1', observed=value,
                             classification='HISTORICAL_PR_1_RECORD', owner_kind='historical_record',
                             action='PRESERVE', expected_after='Historical PR #1 state: ' + OLD_STATE + '.',
                             validation='Exact explicitly classified historical occurrence'))
            out = io.StringIO(); writer = csv.DictWriter(out, fieldnames=fields, delimiter='\t', lineterminator='\n')
            writer.writeheader(); writer.writerows(rows); fixture[INVENTORY] = out.getvalue()
    test('unclassified-historical-state-rejected', lambda f: historical(f, False))
    test('classified-historical-state-accepted', lambda f: historical(f, True), True)
    return {'status': 'PASS', 'cases': cases, 'passed': len(cases), 'total': len(cases)}


if __name__ == '__main__':
    import subprocess
    from finalization import ROOT, read_texts
    names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=ROOT).decode().split('\0')
    print(json.dumps(run(read_texts(ROOT, sorted({n for n in names if n}))), sort_keys=True))
