"""Read pinned, relocatable domain maturity manifests and select descriptors.

Selection never imports code, resolves packages, contacts services or grants
capabilities. The caller pins the index digest from its trusted distribution.
Digests identify content; they are not signatures or external review evidence.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import re
from dataclasses import dataclass
from types import MappingProxyType
from typing import Mapping

TIERS = ('STABLE_1_0', 'EXPERIMENTAL', 'TARGET_GATED', 'EXTERNAL_REVIEW_ONLY', 'EXCLUDED_1_0', 'POST_1_0')
INDEX = 'DOMAIN-PACK-INDEX.json'
FILES = {tier: tier.lower() + '.json' for tier in TIERS}
NATIVE_TARGET = 'x86_64-systemv-elf-linux'
TARGETS = {NATIVE_TARGET, 'PYTHON_CPU_REFERENCE', 'UNDECLARED'}
MAX_BYTES = 16 * 1024 * 1024
MAX_ROWS = 8192
FIELDS = {'identity', 'surface', 'pack', 'subgroup', 'tier', 'evidence_level', 'target',
          'capability', 'external_gate', 'legal', 'limits', 'owner', 'evidence', 'authority',
          'authority_row_sha256', 'core', 'import_grants_capability', 'hardware_claim', 'security_assurance'}
PROOFS = {'FROZEN_PUBLIC_SOURCE', 'FROZEN_PROFILE_BOUNDARY', 'SDK_REFERENCE_MODEL',
          'NATIVE_OWNER_RECORD', 'FAIL_CLOSED_EXTERNAL_GATE'}

class DomainPackError(ValueError):
    """Stable fail-closed domain manifest or selection diagnostic."""

@dataclass(frozen=True)
class Snapshot:
    """Validated immutable descriptors; selected copies cannot alter the pin."""
    rows: tuple[Mapping[str, str], ...]
    manifest_sha256: str
    core_dependencies: tuple = ()
    release_readiness: str = 'NOT_DECLARED'

def require(test, code):
    if not test:
        raise DomainPackError(code)

def digest(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()

def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, 'DUPLICATE_JSON_FIELD')
        result[key] = value
    return result

def decode(raw):
    try:
        return json.loads(raw, object_pairs_hook=unique,
                          parse_constant=lambda _: require(False, 'NONFINITE_JSON'))
    except (UnicodeError, json.JSONDecodeError, RecursionError) as error:
        raise DomainPackError('MALFORMED_JSON') from error

def read(directory, name):
    path = directory / name
    require(path.is_file() and not path.is_symlink(), 'NON_REGULAR_MANIFEST')
    require(path.stat().st_size <= MAX_BYTES, 'MANIFEST_BYTE_BUDGET')
    with path.open('rb') as stream:
        raw = stream.read(MAX_BYTES + 1)
    require(len(raw) <= MAX_BYTES, 'MANIFEST_BYTE_BUDGET')
    return raw

def validate_rows(rows):
    require(type(rows) is list and 0 < len(rows) <= MAX_ROWS, 'DOMAIN_ROW_BUDGET')
    ids = set()
    for row in rows:
        require(type(row) is dict and set(row) == FIELDS and
                all(type(v) is str and 0 < len(v) <= 32768 for v in row.values()), 'DOMAIN_ROW_SCHEMA')
        require(row['identity'] not in ids, 'DUPLICATE_DOMAIN_IDENTITY')
        ids.add(row['identity'])
        require(row['tier'] in TIERS and row['target'] in TARGETS and row['evidence_level'] in PROOFS, 'DOMAIN_CLASSIFICATION')
        require(re.fullmatch(r'S0[1-7]', row['subgroup']), 'DOMAIN_FRONT')
        require(re.fullmatch(r'[0-9a-f]{64}', row['authority_row_sha256']), 'AUTHORITY_FINGERPRINT')
        require(not Path(row['authority']).is_absolute() and '..' not in Path(row['authority']).parts, 'AUTHORITY_PATH')
        require(row['import_grants_capability'] == row['hardware_claim'] == row['security_assurance'] == 'NO', 'UNPROVEN_CLAIM')
        require(row['core'] == ('YES' if row['tier'] == 'STABLE_1_0' else 'NO'), 'CORE_EXCLUDED_DEPENDENCY')
        if row['tier'] == 'STABLE_1_0':
            require(row['identity'].startswith('public:') and row['evidence_level'] == 'FROZEN_PUBLIC_SOURCE'
                    and row['target'] == NATIVE_TARGET and row['external_gate'] == 'NONE'
                    and re.fullmatch(r'G178:[0-9a-f]{64}:.+', row['evidence']), 'STABLE_PROMOTION_WITHOUT_SOURCE')
        if row['evidence_level'] == 'SDK_REFERENCE_MODEL':
            require(row['tier'] == 'EXPERIMENTAL' and row['target'] == 'PYTHON_CPU_REFERENCE'
                    and row['capability'] == 'SYNTHETIC_LOCAL_DATA', 'SDK_OR_TARGET_PROMOTION')
        if row['evidence_level'] == 'NATIVE_OWNER_RECORD':
            require(row['tier'] == 'EXCLUDED_1_0', 'INTERNAL_OWNER_PROMOTION')
        if row['evidence_level'] == 'FROZEN_PUBLIC_SOURCE':
            require(row['identity'].startswith('public:') and row['tier'] in ('STABLE_1_0', 'EXPERIMENTAL')
                    and row['target'] == NATIVE_TARGET, 'PUBLIC_SOURCE_TARGET_OR_TIER')
        if row['tier'] == 'TARGET_GATED':
            gates = {'NETWORK_NOT_AUTHORIZED': 'NETWORK', 'GPU_BACKEND_UNAVAILABLE': 'AUTHENTICATED_GPU',
                     'PRIVATE_X11_EVIDENCE_ONLY': 'X11_SESSION'}
            require(row['evidence_level'] == 'FROZEN_PROFILE_BOUNDARY' and
                    gates.get(row['external_gate']) == row['capability'], 'TARGET_GATE_REMOVED_OR_CONFUSED')
        if row['tier'] == 'EXTERNAL_REVIEW_ONLY' or row['evidence_level'] == 'FAIL_CLOSED_EXTERNAL_GATE':
            require(row['tier'] == 'EXTERNAL_REVIEW_ONLY' and row['external_gate'] == 'CRYPTO_IMPLEMENTATION_REVIEW'
                    and row['evidence_level'] == 'FAIL_CLOSED_EXTERNAL_GATE', 'EXTERNAL_REVIEW_PROMOTION')
        if row['target'] == 'UNDECLARED':
            require(row['tier'] in ('EXCLUDED_1_0', 'POST_1_0'), 'UNDECLARED_TARGET_PROMOTION')
    return rows

def load(directory: Path, *, expected_sha256: str) -> Snapshot:
    """Authenticate the caller's pinned manifest set and validate all tiers."""
    require(type(expected_sha256) is str and re.fullmatch(r'[0-9a-f]{64}', expected_sha256), 'INDEX_PIN_REQUIRED')
    directory = Path(directory)
    require(directory.is_dir() and not directory.is_symlink(), 'NON_REGULAR_MANIFEST_ROOT')
    raw = read(directory, INDEX)
    require(digest(raw) == expected_sha256, 'INDEX_PIN_MISMATCH')
    index = decode(raw)
    try:
        require(type(index) is dict and set(index) == {'schema', 'group', 'files', 'identities', 'authority_fingerprints',
                    'core_dependencies', 'release_readiness', 'release_gates'}, 'INDEX_SCHEMA')
        require(type(index['schema']) is int and index['schema'] == 1 and index['group'] == 'G179', 'INDEX_VERSION')
        require(index['core_dependencies'] == [] and index['release_readiness'] == 'NOT_DECLARED', 'RELEASE_OR_CORE_PROMOTION')
        require(index['release_gates'] == ['RELEASE-SECURITY', 'RELEASE-LEGAL', 'RELEASE-SIGNING', 'RELEASE-CANDIDATE'], 'RELEASE_GATE_REMOVED')
        require(type(index['files']) is dict and set(index['files']) == set(FILES.values()), 'TIER_FILE_SET')
        require(type(index['authority_fingerprints']) is dict and index['authority_fingerprints'] and
                all(type(k) is str and type(v) is str and re.fullmatch(r'[0-9a-f]{64}', v)
                    for k, v in index['authority_fingerprints'].items()), 'AUTHORITY_SET')
        rows = []
        for tier, name in FILES.items():
            payload = read(directory, name)
            require(digest(payload) == index['files'][name], 'TIER_CONTENT_DRIFT')
            data = decode(payload)
            require(type(data) is dict and set(data) == {'tier', 'rows'} and data['tier'] == tier
                    and type(data['rows']) is list and data['rows'] and
                    all(type(r) is dict and r.get('tier') == tier for r in data['rows']), 'TIER_PARTITION')
            rows += data['rows']
        validate_rows(rows)
        require(index['identities'] == sorted(r['identity'] for r in rows), 'DOMAIN_IDENTITY_SET')
        require(read(directory, INDEX) == raw, 'MANIFEST_CHANGED_DURING_READ')
        return Snapshot(tuple(MappingProxyType(dict(r)) for r in rows), expected_sha256)
    except (KeyError, TypeError, AttributeError) as error:
        raise DomainPackError('MALFORMED_MANIFEST') from error

def select(snapshot: Snapshot, *, optional=(), experimental=False, target=NATIVE_TARGET, capabilities=()) -> list[dict]:
    """Select copies of metadata descriptors; this grants no runtime authority.

    Core is always the frozen native profile. Optional SDK models can be
    inspected with their explicit reference target and experimental opt-in.
    Excluded, post-1.0 and pending-review descriptors cannot be activated.
    """
    require(type(snapshot) is Snapshot, 'SNAPSHOT_SCHEMA')
    rows = validate_rows([dict(r) for r in snapshot.rows])
    require(snapshot.core_dependencies == () and snapshot.release_readiness == 'NOT_DECLARED', 'SNAPSHOT_POLICY')
    require(type(experimental) is bool and type(target) is str and target in TARGETS and target != 'UNDECLARED', 'SELECTION_PROFILE')
    require(type(optional) in (tuple, list) and all(type(x) is str for x in optional)
            and len(optional) == len(set(optional)) and len(optional) <= MAX_ROWS, 'OPTIONAL_SELECTION')
    require(type(capabilities) in (tuple, list) and all(type(x) is str for x in capabilities)
            and set(capabilities) <= {'SYNTHETIC_LOCAL_DATA', 'X11_SESSION'}, 'CAPABILITY_PROFILE')
    by_id = {r['identity']: r for r in rows}
    chosen = [r for r in rows if r['core'] == 'YES'] if target == NATIVE_TARGET else []
    for identity in optional:
        require(identity in by_id, 'UNKNOWN_DOMAIN_SURFACE')
        row = by_id[identity]
        require(row['tier'] in ('STABLE_1_0', 'EXPERIMENTAL', 'TARGET_GATED'), 'DOMAIN_EXCLUDED_OR_REVIEW_PENDING')
        require(row['tier'] == 'STABLE_1_0' or experimental, 'EXPERIMENTAL_OPT_IN_REQUIRED')
        require(row['target'] == target, 'DOMAIN_TARGET_UNAVAILABLE')
        require(row['external_gate'] == 'NONE', 'EXTERNAL_GATE_PENDING')
        require(row['capability'] == 'NONE' or row['capability'] in capabilities, 'CAPABILITY_REQUIRED')
        if row not in chosen: chosen.append(row)
    return [dict(r) for r in sorted(chosen, key=lambda r: r['identity'])]
