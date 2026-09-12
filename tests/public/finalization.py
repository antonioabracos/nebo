"""Validate final publication metadata against reviewed, non-circular authorities."""
import csv
import io
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STATE = 'FINAL_RELEASE'
OLD_STATE = 'PULL' + '_REQUEST_CANDIDATE'
READY_STATE = 'FINAL_RELEASE' + '_READY'
RELEASE_DATE = '2026-09-12'
RELEASE_TIMESTAMP = '2026-09-12T07:14:22Z'
TAG = 'nebo-v1.1.0'
MAIN = 'ea0e407b82595577c48c70b7877499f7757d4010'
TREE = '5878240e6627106a466bf3fd88399eacde7492e1'
CI = 34645936056
INVENTORY = 'release/NEBO-1.1.0-RELEASE-GO-STATUS-INVENTORY.tsv'
MANIFEST = 'release/NEBO-1.1.0-RELEASE-GO-CHANGE-MANIFEST.tsv'
ENV = 'release/PUBLIC-RELEASE-CANDIDATE.env'
IDENTITY = 'release/NEBO-PUBLIC-RELEASE-IDENTITY.env'
PROVENANCE = 'SOURCE-PROVENANCE.json'
VALIDATION = 'release/PUBLIC-VALIDATION.json'
DOC_MARKERS = {
    'README.md': 'Publication status: ' + STATE,
    'README_SOURCE.md': 'Status: ' + STATE + '.',
    'CHANGELOG.md': 'Publication status: ' + STATE,
    'docs/releases/VERSION-DECISION.md': 'Publication status: **' + STATE + '**.',
    'docs/releases/NEBO-1.1.0-RELEASE-NOTES.md': 'Publication status: ' + STATE,
    'docs/public/v1.0/releases/NEBO-1.1.0-RELEASE-NOTES.md': 'Publication status: ' + STATE,
    'docs/public/v1.0/index.md': 'Language Edition: `1.0`. ' + STATE + '.',
    'docs/reference/nebo-1.0/g027-readiness.md': 'The public source is ' + STATE + '.',
}
EXPECTED_ENV = {
    'STATUS': STATE, 'VERSION': '1.1.0', 'EDITION': '1.0',
    'RELEASE_DATE': RELEASE_DATE, 'RELEASE_TIMESTAMP_UTC': RELEASE_TIMESTAMP,
    'TAG': TAG, 'PUBLICATION_CHANNEL': 'GITHUB_RELEASE',
    'PUBLICATION_AUTHORIZATION': 'RELEASE_GO', 'OPEN_FINDINGS': '0',
    'PREVIOUS_PUBLIC_VERSION': '1.0.1', 'TARGET': 'x86_64-systemv-elf-linux',
    'SEMVER_DECISION': 'BACKWARD_COMPATIBLE_PUBLIC_ADDITIONS',
    'SOURCE_MAIN_COMMIT': MAIN, 'SOURCE_MAIN_TREE': TREE,
    'SOURCE_MAIN_CI_RUN': str(CI), 'SOURCE_MAIN_CI': 'PASS',
}
CURRENT_CLASSES = {
    'CURRENT_FINAL_RELEASE_STATE_OWNER', 'CURRENT_PUBLIC_DOCUMENTATION',
    'CURRENT_CHANGELOG', 'CURRENT_RELEASE_NOTES', 'CURRENT_PROVENANCE',
    'CURRENT_VALIDATION_METADATA', 'CURRENT_DERIVED_OWNER_POLICY',
    'CURRENT_VALIDATOR_EXPECTATION',
}
HISTORY_CLASSES = {
    'HISTORICAL_FINALIZATION_PR_RECORD', 'HISTORICAL_PR_1_RECORD',
    'HISTORICAL_RELEASE_RECORD',
}
OTHER_CLASSES = {'COMPATIBILITY_BASELINE', 'EXAMPLE_OR_TEST_FIXTURE', 'NOT_A_RELEASE_STATE'}
MANIFEST_CLASSES = {
    'CURRENT_STATUS_OWNER', 'PUBLIC_DOCUMENTATION', 'PROVENANCE',
    'VALIDATION_METADATA', 'DERIVED_OWNER_POLICY', 'VALIDATOR',
    'CHECKSUM', 'RELEASE_GO_MANIFEST',
}
# Splitting the literals keeps the scanner specification distinct from claims
# in documents and metadata. Synthetic fixtures exercise each complete token.
SCAN_PATTERN = re.compile('|'.join([
    re.escape(READY_STATE), re.escape(OLD_STATE), 'pull request ' + 'candidate',
    'Un' + 'released', 'UN' + 'SET', 'NOT_' + 'CREATED',
    'NOT_PERFORMED_' + 'BY_THIS_SNAPSHOT', 'release date is ' + 'un' + 'set',
    r'latest published (?:release|github release).*' + r'1\.0\.1',
    'tag does not ' + 'exist', 'GitHub Release does not ' + 'exist',
    r'separate\s+' + 'RELEASE_GO', 'not exist ' + 'yet',
    'ainda não foi ' + 'publicada',
]), re.I)


def unique(items):
    result = {}
    for key, value in items:
        assert key not in result, ('duplicate key', key)
        result[key] = value
    return result


def parsed_json(text):
    return json.loads(text, object_pairs_hook=unique)


def table(text, fields):
    reader = csv.DictReader(io.StringIO(text), delimiter='\t')
    assert reader.fieldnames == fields, 'table schema'
    rows = list(reader)
    assert rows and all(set(row) == set(fields) and all(row.values()) for row in rows), 'empty table or field'
    return rows


def exact(document, expected):
    for key, value in expected.items():
        assert type(document.get(key)) is type(value) and document[key] == value, ('metadata field', key)


def validate(texts):
    """Pure validation; expectations never come from observed metadata values."""
    assert texts, 'empty release scan'
    for path, expected in [(IDENTITY, EXPECTED_ENV), (ENV, dict(EXPECTED_ENV, FILENAME_COMPATIBILITY='HISTORICAL_PATH_PRESERVED'))]:
        env = unique(line.split('=', 1) for line in texts[path].splitlines() if line and not line.startswith('#'))
        assert set(env) == set(expected), ('release identity fields', path)
        exact(env, expected)
    provenance = parsed_json(texts[PROVENANCE])
    exact(provenance, {
        'status': STATE, 'version': '1.1.0', 'edition': '1.0', 'target': EXPECTED_ENV['TARGET'],
        'source_integration_commit': MAIN, 'source_integration_tree': TREE,
        'source_integration_ci_run': CI, 'source_integration_ci': 'PASS',
        'public_base_commit': '753cc86c752a132779401384c99ed0f3eb580f20',
        'public_base_tree': '4ec315e223c0eb639bda1d2bd097286c2bd57dda',
        'release_date': RELEASE_DATE, 'release_timestamp_utc': RELEASE_TIMESTAMP,
        'tag': TAG, 'publication_channel': 'GITHUB_RELEASE',
        'publication_authorization': 'RELEASE_GO',
    })
    assert not {'remote_publication', 'expected_tag', 'tag_created', 'github_release_created', 'assets_uploaded'} & provenance.keys()
    validation = parsed_json(texts[VALIDATION])
    exact(validation, {
        'release_readiness': STATE, 'version': '1.1.0', 'edition': '1.0',
        'source_integration_commit': MAIN, 'source_integration_tree': TREE,
        'post_merge_ci_run': CI, 'post_merge_ci': 'PASS',
        'release_date': RELEASE_DATE, 'release_timestamp_utc': RELEASE_TIMESTAMP,
        'final_tag': TAG, 'publication_authorization': 'RELEASE_GO',
        'release_go_metadata_validation': 'PASS',
    })
    assert not {'tag_created', 'github_release_created', 'assets_uploaded'} & validation.keys()
    for path, marker in DOC_MARKERS.items():
        text = texts[path]
        assert text.count(marker) == 1, ('current status owner', path)
        if path == 'CHANGELOG.md':
            heading = '## [1.1.0] - ' + RELEASE_DATE
            assert re.findall(r'^## \[1\.1\.0\].*$', text, re.M) == [heading]
            text = text.split(heading, 1)[1].split('\n## ', 1)[0]
        plain = re.sub(r'[`*]', '', text)
        assert not SCAN_PATTERN.search(plain), ('stale current owner', path)
        assert 'RELEASE_GO' in plain, ('release authorization', path)
        tags = re.findall(r'\btag:\s*(nebo-v[\d.]+)', plain, re.I)
        assert [value.rstrip('.') for value in tags] == [TAG], ('current release tag', path)
        dates = re.findall(r'release date:\s*(\d{4}-\d{2}-\d{2})', plain, re.I)
        clocks = re.findall(r'release timestamp \(UTC\):\s*(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)', plain, re.I)
        assert dates == [RELEASE_DATE] and clocks == [RELEASE_TIMESTAMP], ('frozen release clock', path)
        latest = re.findall(r'latest published (?:github )?release\s*(?::|remains|is)\s*([\d.]+)', plain, re.I)
        assert latest and all(value.rstrip('.') == '1.1.0' for value in latest), ('latest publication claim', path)
    notes = 'docs/releases/NEBO-1.1.0-RELEASE-NOTES.md'
    assert texts[notes] == texts['docs/public/v1.0/releases/NEBO-1.1.0-RELEASE-NOTES.md'], 'release note copy'
    rows = table(texts[INVENTORY], ['path', 'line_or_field', 'observed', 'classification', 'action', 'expected_after', 'validation'])
    assert len({(row['path'], row['line_or_field']) for row in rows}) == len(rows), 'duplicate inventory row'
    preserved = {}
    for row in rows:
        cls = row['classification'];path = row['path']
        assert cls in CURRENT_CLASSES | HISTORY_CLASSES | OTHER_CLASSES
        assert path in texts, ('missing inventoried path', path)
        if cls in CURRENT_CLASSES:
            assert row['action'] == 'TRANSITION' and row['expected_after'] in texts[path], ('inventory expectation', path)
            assert row['expected_after'] in {STATE, '## [1.1.0] - ' + RELEASE_DATE, 'final-release-state-accepted'}
        else:
            assert path not in DOC_MARKERS and row['action'] == 'PRESERVE'
            assert row['expected_after'] == row['observed']
            index = int(row['line_or_field'].removeprefix('line:'))
            assert texts[path].splitlines()[index - 1].strip() == row['observed'], ('historical observation drift', path)
            preserved[(path, index)] = row['observed']
    manifests = table(texts[MANIFEST], ['path', 'action', 'owner_class', 'old_state', 'new_state', 'reason', 'validation'])
    assert len({row['path'] for row in manifests}) == len(manifests) and len(manifests) <= 60
    for row in manifests:
        assert row['owner_class'] in MANIFEST_CLASSES and row['action'] in {'ADD', 'MODIFY'}
        assert row['path'] in texts and row['new_state'] in {STATE, 'REGENERATED'}
        assert not any(SCAN_PATTERN.search(row[k]) for k in row if k != 'old_state'), 'old status outside manifest baseline'
    count = 0
    for path, text in texts.items():
        if path == INVENTORY:
            for row in rows:
                allowed = {'observed', 'expected_after'} if row['classification'] not in CURRENT_CLASSES else {'observed'}
                assert not any(SCAN_PATTERN.search(row[k]) for k in row if k not in allowed), 'old status outside inventory observation'
            continue
        if path == MANIFEST:
            continue
        for line, value in enumerate(text.splitlines(), 1):
            if SCAN_PATTERN.search(value):
                assert preserved.get((path, line)) == value.strip(), ('unclassified release state', path, line)
                count += 1
    return {'status': 'PASS', 'readiness': STATE, 'release_date': RELEASE_DATE,
            'release_timestamp_utc': RELEASE_TIMESTAMP, 'inventory_rows': len(rows),
            'unclassified_status_occurrences': 0, 'current_old_status_owners': 0,
            'classified_preserved_occurrences': count, 'manifest_paths': len(manifests)}


def read_texts(root, names):
    assert names and len(names) == len(set(names)), 'empty or duplicate scan inventory'
    texts = {}
    for name in names:
        raw = (root / name).read_bytes()
        if b'\0' in raw:
            continue
        try:
            texts[name] = raw.decode('utf-8')
        except UnicodeError:
            continue
    assert texts, 'empty text scan'
    return texts


if __name__ == '__main__':
    import subprocess
    names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=ROOT).decode().split('\0')
    print(json.dumps(validate(read_texts(ROOT, sorted({n for n in names if n}))), sort_keys=True))
