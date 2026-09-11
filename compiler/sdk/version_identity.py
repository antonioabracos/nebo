"""Product identity shared by source, installed SDK and metadata producers."""
from pathlib import Path
import json
import re


def identity(root=None):
    root=Path(root) if root is not None else Path(__file__).resolve().parents[2]
    paths=[root/'version/NEBO-VERSION.json',root/'share/nebo/version/NEBO-VERSION.json']
    found=[p for p in paths if p.is_file()]
    if not found:raise ValueError('NEBO_VERSION_AUTHORITY_MISSING')
    records=[json.loads(p.read_bytes()) for p in found]
    if any(r!=records[0] for r in records):raise ValueError('NEBO_VERSION_AUTHORITY_CONFLICT')
    value=records[0]
    if (value.get('schema')!='NEBO-VERSION-v1' or not re.fullmatch(r'[1-9][0-9]*\.[0-9]+\.[0-9]+',str(value.get('version')))
        or value.get('compiler')!='neboc' or value.get('cli')!='neboc '+value['version']
        or value.get('edition')!='1.0' or value.get('target')!='x86_64-systemv-elf-linux'):
        raise ValueError('NEBO_VERSION_AUTHORITY_INVALID')
    return value


CURRENT=identity()
VERSION=CURRENT['version']
EDITION=CURRENT['edition']
CLI=CURRENT['cli']
