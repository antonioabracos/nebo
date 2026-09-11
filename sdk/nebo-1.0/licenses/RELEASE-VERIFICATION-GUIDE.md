# Offline verification and reconstruction

Run `bash tests/rf204/G198/validate.sh` in the canonical checkout. This creates
bounded temporary product archives, restores the admitted source closure twice,
and rebuilds the 14 native owners without reading the checkout or using the
network. It compares source, SDK, docs, tooling and real package-cache archive
bytes under different directories, locales, timezones, mtimes and umasks.
Temporary archives, objects and executables are deleted when the campaign exits.

The public local tool is `python3 -B scripts/rf204/nebo-supply-chain.py`:

- `snapshot --repo REPO --output SOURCE --example RELATIVE.no` (repeat example
  for each admitted source/module) captures a normalized source tree and its
  exact Git baseline, working-tree overlay and host-toolchain inventory.
- `archive ROOT OUTPUT.tar --profile source|sdk|docs|tooling|package
  --provenance SOURCE/SOURCE-PROVENANCE.json` creates an uncompressed USTAR
  transport containing canonical SBOM/provenance and the complete payload.
- `verify OUTPUT.tar --sha256 INDEPENDENT_PIN` verifies the same bounded bytes
  subsequently consumed, with no extraction and no network operation.
- `restore OUTPUT.tar --sha256 INDEPENDENT_PIN --output ABSENT_DIRECTORY`
  validates before publishing a complete directory, refusing collisions.

The Python API `attest(subjects, provenance)` joins all five independently
observed archive identities. `verify_attestation(raw, expected_pin, archives)`
checks every subject, SBOM and source identity. Retain the attestation SHA-256
outside the transport; a digest obtained from an untrusted archive is no trust
anchor. Production publisher authentication requires the separate signing gate.

Source means the explicit build/package input closure, not a repository backup.
Ninja intermediate outputs, Git metadata, hidden paths, credentials, caches and
release directories are excluded. NASM literal include/incbin dependencies are
followed. Generated tables/atlas are versioned source inputs; the atlas generator
is rerun in check mode using the inventoried Pillow/FreeType and vendored font.
The dependency inventory records host executables, Python/Pillow files and their
shared libraries. The Linux x86-64 kernel/CPU and installed toolchain remain
external prerequisites; this is not an independent compiler bootstrap or a
portable whole-OS reproducibility claim. No clean-room download is permitted.

Any changed hash, missing notice, malformed/duplicate metadata, link, special
file, unsafe path, wrong pin or incompatible profile prevents admission.
License inventory is factual; RELEASE-LEGAL remains pending external review.

For package reconstruction, pass `--package-workspace RELATIVE/workspace.json`
to snapshot; all declared package manifests and module sources join the admitted
input closure. After pinned source restore, run `/usr/bin/python3 -B -m
compiler.sdk.supply_chain_build SOURCE OUTPUT` with cwd SOURCE. This executes
the already trusted build recipe; all profile outputs publish together on success.
Host site customization outside /usr is denied in the clean room.
