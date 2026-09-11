"""Synthetic runtime fixtures exercise privacy failures without storing private roots."""
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from privacy import ScanError, scan_files


def main():
    rows = []
    with tempfile.TemporaryDirectory(prefix='public-scan-selftest-') as directory:
        root = Path(directory)
        def check(name, data, expected, *, filename='fixture.txt', extra=()):
            path = root / filename
            path.write_bytes(data)
            try:
                result = scan_files(root, [filename], extra)
            except (ScanError, OSError):
                observed = 'REJECT'
            else:
                assert result['files'] == 1
                observed = 'ACCEPT'
            assert observed == expected, (name, observed, expected)
            rows.append({'case': name, 'expected': expected, 'observed': observed})
        home = '/' + '/'.join(['home', 'example-user', 'private-project'])
        mac = '/' + '/'.join(['Users', 'example-user', 'private-project'])
        windows = 'C:' + chr(92) + chr(92).join(['Users', 'example-user', 'private-project'])
        dated = '/' + '/'.join(['tmp', 'example-run-' + '20260101' + 'T010203Z'])
        for name, text in [('linux-home', home), ('mac-home', mac), ('windows-home', windows), ('windows-json-escaped', json.dumps(windows)), ('dated-run-cache', dated)]:
            check(name, text.encode(), 'REJECT')
        for folder in ('home', 'Users'):
            for user in ('雪', 'example user'):
                text = '/' + '/'.join([folder, user, 'private-project'])
                check(folder + '-unicode-or-spaced-' + user, text.encode(), 'REJECT')
        for name, folder, user in [('windows-spaced-user', 'Users', 'example user'), ('windows-unicode-user', 'Users', 'utilisateur-é'), ('windows-case-insensitive', 'users', 'example-user')]:
            text = 'C:' + chr(92) + chr(92).join([folder, user, 'private-project'])
            check(name, text.encode(), 'REJECT')
        for name, text in [('control-marker', 'Nebo' + '_Control'), ('source-marker', 'Nebo' + '_src'), ('backup-marker', 'Nebolys' + '-Backups'), ('archive-ref', 'refs' + '/archive/example'), ('internal-branch', 'feat/nebo-' + 'g001-g204-example')]:
            check(name, text.encode(), 'REJECT')
        check('configured-private-root', b'custom-private-root/file', 'REJECT', extra=('custom-private-root',))
        check('public-local-option', b'--local-only', 'ACCEPT')
        check('loopback', b'localhost 127.0.0.1 ::1', 'ACCEPT')
        check('public-temporary-template', b'/' + b'/'.join([b'tmp', b'public-tool.XXXXXX']), 'ACCEPT')
        check('empty-content', b'', 'REJECT')
        for name, paths in [('empty-file-list', []), ('duplicate-file-list', ['fixture.txt', 'fixture.txt']), ('missing-file', ['absent']), ('path-traversal', ['../outside'])]:
            try: scan_files(root, paths)
            except (ScanError, OSError): pass
            else: raise AssertionError(name + ' accepted')
            rows.append({'case': name, 'expected': 'REJECT', 'observed': 'REJECT'})
        unreadable = root / 'unreadable.txt'; unreadable.write_text('ordinary text'); unreadable.chmod(0)
        try:
            try: scan_files(root, ['unreadable.txt'])
            except (ScanError, OSError): pass
            else: raise AssertionError('unreadable accepted')
        finally: unreadable.chmod(0o600)
        rows.append({'case': 'unreadable-file', 'expected': 'REJECT', 'observed': 'REJECT'})
        (root / 'link.txt').symlink_to(root / 'fixture.txt')
        try: scan_files(root, ['link.txt'])
        except (ScanError, OSError): pass
        else: raise AssertionError('symlink accepted')
        rows.append({'case': 'symlink', 'expected': 'REJECT', 'observed': 'REJECT'})
        for kind in ('tar', 'zip'):
            for name, payload, expected in [('private-member', home.encode(), 'REJECT'), ('public-member', b'--local-only localhost', 'ACCEPT')]:
                buf = io.BytesIO()
                if kind == 'tar':
                    with tarfile.open(fileobj=buf, mode='w:gz') as archive:
                        member = tarfile.TarInfo('member.txt'); member.size = len(payload); archive.addfile(member, io.BytesIO(payload))
                    suffix = '.tgz'
                else:
                    with zipfile.ZipFile(buf, 'w', compression=zipfile.ZIP_DEFLATED) as archive: archive.writestr('member.txt', payload)
                    suffix = '.zip'
                check(kind + '-' + name, buf.getvalue(), expected, filename='fixture' + suffix)
        # Exercise bounded recursive archives, including an empty nested member.
        import privacy
        def make_tar(name, payload):
            buffer = io.BytesIO()
            with tarfile.open(fileobj=buffer, mode='w') as archive:
                item = tarfile.TarInfo(name); item.size = len(payload)
                archive.addfile(item, io.BytesIO(payload))
            return buffer.getvalue()
        empty_zip = io.BytesIO()
        with zipfile.ZipFile(empty_zip, 'w'): pass
        check('empty-archive', empty_zip.getvalue(), 'REJECT', filename='empty.zip')
        check('nested-empty-archive', make_tar('empty.zip', empty_zip.getvalue()), 'REJECT', filename='nested.tar')
        check('nested-public-archive', make_tar('inner.tar', make_tar('public.txt', b'localhost')), 'ACCEPT', filename='nested.tar')
        check('nested-private-archive', make_tar('inner.tar', make_tar('private.txt', home.encode())), 'REJECT', filename='nested.tar')
        saved = (privacy.MAX_FILE, privacy.MAX_ARCHIVE_BYTES, privacy.MAX_MEMBERS, privacy.MAX_DEPTH)
        try:
            privacy.MAX_FILE = 64
            check('file-byte-limit', b'x' * 65, 'REJECT')
            privacy.MAX_FILE = saved[0]
            privacy.MAX_ARCHIVE_BYTES = 4
            check('archive-expanded-byte-limit', make_tar('public.txt', b'localhost'), 'REJECT', filename='bounded.tar')
            privacy.MAX_ARCHIVE_BYTES = saved[1]
            privacy.MAX_MEMBERS = 0
            check('archive-member-limit', make_tar('public.txt', b'localhost'), 'REJECT', filename='bounded.tar')
            privacy.MAX_MEMBERS = saved[2]
            privacy.MAX_DEPTH = 1
            check('archive-depth-limit', make_tar('inner.tar', make_tar('public.txt', b'localhost')), 'REJECT', filename='bounded.tar')
        finally:
            privacy.MAX_FILE, privacy.MAX_ARCHIVE_BYTES, privacy.MAX_MEMBERS, privacy.MAX_DEPTH = saved
        check('invalid-archive', b'not a valid archive', 'REJECT', filename='invalid.zip')
        check('fake-access-token', ('gh' + 'p_' + 'x'*36).encode(), 'REJECT')
        check('fake-private-key', ('-----BEGIN ' + 'PRIVATE KEY-----').encode(), 'REJECT')
        cli = Path(__file__).with_name('privacy.py')
        (root/'cli.txt').write_text(home)
        run = subprocess.run([sys.executable, '-B', str(cli), '--root', str(root), 'cli.txt'],capture_output=True,text=True)
        assert run.returncode != 0 and json.loads(run.stdout)['status']=='FAIL' and home not in run.stdout
        rows.append({'case':'cli-nonzero-redacted-finding','expected':'REJECT','observed':'REJECT'})
    print(json.dumps({'status': 'PASS', 'cases': rows, 'passed': len(rows), 'total': len(rows)}))


if __name__ == '__main__': main()
