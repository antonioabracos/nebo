"""Validate the pre-publication boundary against explicit, reviewed authorities."""
import csv
import io
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STATE = 'FINAL_RELEASE_READY'
OLD_STATE = 'PULL' + '_REQUEST_CANDIDATE'
MAIN = 'ea0e407b82595577c48c70b7877499f7757d4010'
TREE = '5878240e6627106a466bf3fd88399eacde7492e1'
CI = 34645936056
INVENTORY = 'release/NEBO-1.1.0-FINALIZATION-STATUS-INVENTORY.tsv'
MANIFEST = 'release/NEBO-1.1.0-FINALIZATION-CHANGE-MANIFEST.tsv'
ENV = 'release/PUBLIC-RELEASE-CANDIDATE.env'
PROVENANCE = 'SOURCE-PROVENANCE.json'
VALIDATION = 'release/PUBLIC-VALIDATION.json'
DOC_MARKERS = {
    'README.md': 'Publication status: ' + STATE,
    'README_SOURCE.md': 'Status: ' + STATE + '.',
    'CHANGELOG.md': 'release metadata is ' + STATE,
    'docs/releases/VERSION-DECISION.md': 'Publication status: **' + STATE + '**.',
    'docs/releases/NEBO-1.1.0-RELEASE-NOTES.md': 'Publication status: ' + STATE,
    'docs/public/v1.0/releases/NEBO-1.1.0-RELEASE-NOTES.md': 'Publication status: ' + STATE,
    'docs/public/v1.0/index.md': 'Language Edition: `1.0`. ' + STATE + '.',
    'docs/reference/nebo-1.0/g027-readiness.md': 'The public source is ' + STATE,
}
EXPECTED_ENV = {
    'STATUS': STATE, 'VERSION': '1.1.0', 'EDITION': '1.0',
    'PREVIOUS_PUBLIC_VERSION': '1.0.1', 'TARGET': 'x86_64-systemv-elf-linux',
    'SEMVER_DECISION': 'BACKWARD_COMPATIBLE_PUBLIC_ADDITIONS',
    'SOURCE_MAIN_COMMIT': MAIN, 'SOURCE_MAIN_TREE': TREE,
    'SOURCE_MAIN_CI_RUN': str(CI), 'SOURCE_MAIN_CI': 'PASS',
    'RELEASE_DATE': 'UNSET', 'EXPECTED_TAG': 'nebo-v1.1.0',
    'TAG_CREATED': 'NO', 'GITHUB_RELEASE_CREATED': 'NO',
    'ASSETS_UPLOADED': '0', 'OPEN_FINDINGS': '0', 'NEXT_ACTION': 'SEPARATE_RELEASE_GO',
}
CURRENT_CLASSES = {
    'CURRENT_PUBLICATION_STATE_OWNER', 'CURRENT_RELEASE_READINESS_OWNER',
    'CURRENT_PUBLIC_DOCUMENTATION', 'CURRENT_VALIDATOR_EXPECTATION',
    'CURRENT_DERIVED_OWNER_POLICY', 'CURRENT_PROVENANCE', 'CURRENT_CHANGELOG',
}
HISTORY_CLASSES = {'HISTORICAL_PR_1_RECORD', 'HISTORICAL_RELEASE_RECORD', 'HISTORICAL_CHANGELOG_ENTRY'}
OTHER_CLASSES = {'COMPATIBILITY_BASELINE', 'TEST_FIXTURE', 'EXAMPLE_TEXT', 'NOT_A_PUBLICATION_STATE'}
MANIFEST_CLASSES = {
    'CURRENT_STATUS_OWNER', 'PUBLIC_DOCUMENTATION', 'PROVENANCE',
    'VALIDATION_METADATA', 'DERIVED_OWNER_POLICY', 'VALIDATOR',
    'CHECKSUM', 'FINALIZATION_MANIFEST',
}
OLD_PATTERN = re.compile(re.escape(OLD_STATE) + r'|pull request ' + 'candidate', re.I)


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
    """Pure checks permit mutation tests without editing a checkout or needing Git."""
    env = unique(line.split('=', 1) for line in texts[ENV].splitlines() if line and not line.startswith('#'))
    exact(env, EXPECTED_ENV)
    provenance = parsed_json(texts[PROVENANCE])
    exact(provenance, {
        'status': STATE, 'version': '1.1.0', 'edition': '1.0', 'target': EXPECTED_ENV['TARGET'],
        'source_integration_commit': MAIN, 'source_integration_tree': TREE,
        'source_integration_ci_run': CI, 'source_integration_ci': 'PASS',
        'public_base_commit': '753cc86c752a132779401384c99ed0f3eb580f20',
        'public_base_tree': '4ec315e223c0eb639bda1d2bd097286c2bd57dda',
        'expected_tag': 'nebo-v1.1.0', 'remote_publication': 'NOT_PERFORMED_BY_THIS_SNAPSHOT',
        'release_date': None,
    })
    validation = parsed_json(texts[VALIDATION])
    exact(validation, {
        'release_readiness': STATE, 'version': '1.1.0', 'edition': '1.0',
        'source_integration_commit': MAIN, 'source_integration_tree': TREE,
        'post_merge_ci_run': CI, 'post_merge_ci': 'PASS',
        'tag_created': False, 'github_release_created': False, 'assets_uploaded': 0,
        'release_date': None,
    })
    for path, marker in DOC_MARKERS.items():
        text = texts[path]
        assert text.count(marker) == 1, ('current status owner', path)
        assert 'RELEASE_GO' in text and '1.0.1' in text, ('publication boundary', path)
        if path == 'CHANGELOG.md':
            assert re.findall(r'^## \[1\.1\.0\].*$', text, re.M) == ['## [1.1.0] - Unreleased']
            text = text.split('## [1.1.0] - Unreleased', 1)[1].split('\n## ', 1)[0]
        plain = re.sub(r'[`*]', '', text)
        assert not OLD_PATTERN.search(plain), ('stale current owner', path)
        latest = re.findall(r'latest published (?:github )?release\s*(?::|remains|is)\s*([\d.]+)', plain, re.I)
        assert latest and all(value.rstrip('.') == '1.0.1' for value in latest), ('latest publication claim', path)
        assert not re.search(r'\b(?:nebo|version|release|source(?: version)?)\s+1\.1\.0\s+(?:is|has been)\s+(?:now\s+)?(?:published|released)', plain, re.I), ('false publication claim', path)
        assert not re.search(r'download\s+(?:the\s+)?1\.1\.0\s+release assets|nebo-v1\.1\.0\s+(?:exists|is created)', plain, re.I), ('false asset or tag claim', path)
    notes = 'docs/releases/NEBO-1.1.0-RELEASE-NOTES.md'
    assert texts[notes] == texts['docs/public/v1.0/releases/NEBO-1.1.0-RELEASE-NOTES.md'], 'release note copy'
    rows = table(texts[INVENTORY], ['path', 'line_or_field', 'observed', 'classification', 'owner_kind', 'action', 'expected_after', 'validation'])
    assert len({(row['path'], row['line_or_field']) for row in rows}) == len(rows), 'duplicate inventory row'
    history = {}
    for row in rows:
        assert row['classification'] in CURRENT_CLASSES | HISTORY_CLASSES | OTHER_CLASSES
        assert row['action'] in {'TRANSITION', 'PRESERVE'}
        if row['classification'] in CURRENT_CLASSES:
            assert row['path'] in texts, ('missing status owner', row['path'])
            assert row['expected_after'] in texts[row['path']], ('inventory expectation', row['path'])
            if OLD_PATTERN.search(row['observed']):
                assert row['action'] == 'TRANSITION' and row['expected_after'] == STATE
        elif row['classification'] in HISTORY_CLASSES:
            assert row['path'] not in DOC_MARKERS and row['action'] == 'PRESERVE'
            assert row['expected_after'] == row['observed']
            history[(row['path'], row['line_or_field'])] = row['observed']
    manifests = table(texts[MANIFEST], ['path', 'action', 'owner_class', 'old_state', 'new_state', 'reason', 'validation'])
    assert len({row['path'] for row in manifests}) == len(manifests) and len(manifests) <= 60
    assert all(row['owner_class'] in MANIFEST_CLASSES and row['action'] in {'ADD', 'MODIFY'} for row in manifests)
    assert all(row['path'] in texts for row in manifests), 'manifest path missing'
    historical_count = 0
    for path, text in texts.items():
        if path == INVENTORY:
            # Old observed values are an explicit record of the integrated main.
            for row in rows:
                allowed = {'observed', 'expected_after'} if row['classification'] in HISTORY_CLASSES else {'observed'}
                assert not any(OLD_PATTERN.search(row[k]) for k in row if k not in allowed), 'old status outside inventory observation'
            continue
        if path == MANIFEST:
            # The old_state column records the transition, never the current state.
            for row in manifests:
                assert not any(OLD_PATTERN.search(row[k]) for k in row if k != 'old_state'), 'old status outside change baseline'
            continue
        for line, value in enumerate(text.splitlines(), 1):
            if OLD_PATTERN.search(value):
                assert history.get((path, 'line:' + str(line))) == value.strip(), ('unclassified old status', path, line)
                historical_count += 1
    return {'status': 'PASS', 'readiness': STATE, 'inventory_rows': len(rows),
            'unclassified_status_occurrences': 0, 'current_old_status_owners': 0,
            'classified_historical_occurrences': historical_count, 'manifest_paths': len(manifests)}


def read_texts(root, names):
    texts = {}
    for name in names:
        raw = (root / name).read_bytes()
        if b'\0' in raw:
            continue
        try:
            texts[name] = raw.decode('utf-8')
        except UnicodeError:
            continue
    return texts


if __name__ == '__main__':
    import subprocess
    names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=ROOT).decode().split('\0')
    print(json.dumps(validate(read_texts(ROOT, sorted({n for n in names if n}))), sort_keys=True))
