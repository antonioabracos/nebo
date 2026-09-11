# Local SDK installation profiles

Use Python 3 to run `sdk/nebo-1.0/install/install-nebo-sdk.py` from an unpacked SDK.
The equivalent entrypoint is `scripts/rf204/nebo-sdk-lifecycle.py`.

```
python3 install-nebo-sdk.py install LOCAL_SDK PRIVATE_PARENT/nebo --profile prefix
python3 install-nebo-sdk.py install LOCAL.tar PRIVATE_PARENT/nebo --profile prefix --archive-sha256 EXPECTED_SHA256
python3 install-nebo-sdk.py verify PRIVATE_PARENT/nebo
python3 install-nebo-sdk.py env PRIVATE_PARENT/nebo --shell bash
```

| Profile | Destination | Permission and ownership policy |
|---|---|---|
| user (CLI default) | Explicit leaf prefix, or `$HOME/.local/opt/nebo` | No root; existing parent owned by invoking user, no group/world write. |
| prefix | Required explicit leaf prefix | Same private parent rule; no root. |
| system-local | Required explicit dedicated leaf prefix | Requires `--allow-system-local`; no implicit elevation or sudo. An administrator may invoke this profile explicitly. |

Create the parent yourself with mode 0700 before installation. The installer never
creates a parent hierarchy as an incidental side effect. `/`, `/usr`, `/usr/local`,
`/bin`, `/etc` and `/opt` themselves are forbidden destinations. A dedicated
administrator-owned leaf such as `/usr/local/nebo` is an explicit system-local
choice. Tests use only private sandboxes, never a real system installation.

Active prefix mode is 0700. Manifest files retain 0644/0755; privileged modes,
hardlinks, symlinks, devices and traversal are rejected. The install manifest
records the chosen profile and exact owned paths, sizes, hashes and modes.
Metadata is bounded to 16 MiB; up to 20,001 owned rows, 128 MiB per file and
512 MiB payload plus manifest allowance. Owned paths have at most 64 components;
the complete owned file/directory tree has at most 80,128 entries, compatible
with the uninstall inventory bound. Linux x86_64 is the executable SDK target.
Other hosts receive factual unsupported diagnostics from doctor.

Install phases are validate, private stage, byte/mode verification and atomic
no-replace activation on the same filesystem. A parent-directory flock serializes
cooperating lifecycle operations, including distinct prefixes under that parent.
An occupied destination is preserved. Ordinary failures and handled SIGTERM clean
staging; SIGKILL/power loss can leave an **inactive** private staging directory.
The kernel releases the lock. Retry is safe; abandoned staging is not automatically
deleted because it may contain user additions. It never becomes an active prefix.
The old `.PREFIX.nebo-lock` marker is rejected and never silently removed.

`env` prints a POSIX sh or bash snippet only after verifying the installation.
Evaluate it explicitly to export NEBO_SDK_ROOT, add bin to PATH once, and choose
NEBO_PACKAGE_STORE only if unset. Bash output also registers command completion.
Prefixes are shell quoted. No dotfile, login script or global PATH is edited.

An installation is trusted local content with unsigned integrity, not an
independently signed distribution. No download, registry lookup or remote action
is performed. Keep the prefix quiescent except for cooperating lifecycle commands;
a hostile process with the same UID can rewrite the ownership authority itself.
