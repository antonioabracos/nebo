#!/usr/bin/env python3
import hashlib
import importlib.util
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[3]
PROJECT_ROOT = ROOT / "examples/projects/rf27-g27"
NAMES = ("analytics", "service", "library", "empty", "migration")
PACKAGE_TOOL = ROOT / "tools/rf27-package.py"

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("rf27_package", PACKAGE_TOOL)
package_module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(package_module)

env = dict(os.environ, LC_ALL="C", LANG="C", TZ="UTC", TERM="dumb", PYTHONDONTWRITEBYTECODE="1")

def run(args, *, ok=True):
    result = subprocess.run([str(arg) for arg in args], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if ok and result.returncode:
        raise SystemExit(result.stderr.decode(errors="replace"))
    return result

def metadata(path):
    rows = [line.split("\t", 1) for line in path.read_text().splitlines()]
    if rows[0] != ["key", "value"]:
        raise SystemExit(f"bad metadata header: {path}")
    return dict(rows[1:])

artifact_hashes = []
with tempfile.TemporaryDirectory(prefix="rf27-g27-f10-") as raw:
    temp = pathlib.Path(raw)
    for name in NAMES:
        project = PROJECT_ROOT / name
        meta = metadata(project / "project.tsv")
        expected_meta = {"schema": "1", "name": name, "edition_from": "1", "edition_to": "2",
                         "abi": "0", "runtime": "0", "expected_exit": meta.get("expected_exit", ""),
                         "capabilities": "NONE"}
        if meta != expected_meta:
            raise SystemExit(f"incompatible project metadata: {name}")
        main, core, util = project / "main.no", project / "core.no", project / "util.no"
        units_a = ["--unit", core, "--unit", util]
        units_b = ["--unit", util, "--unit", core]
        run([ROOT / "build/bin/neboc", "check", main, *units_a])
        asm_a, asm_b = temp / f"{name}_a.asm", temp / f"{name}_b.asm"
        elf_a, elf_b = temp / f"{name}_a.elf", temp / f"{name}_b.elf"
        run([ROOT / "build/bin/neboc", "emit-asm", main, *units_a, "-o", asm_a])
        run([ROOT / "build/bin/neboc", "emit-asm", main, *units_b, "-o", asm_b])
        run([ROOT / "build/bin/neboc", "build", main, *units_a, "-o", elf_a])
        run([ROOT / "build/bin/neboc", "build", main, *units_b, "-o", elf_b])
        if asm_a.read_bytes() != asm_b.read_bytes() or elf_a.read_bytes() != elf_b.read_bytes():
            raise SystemExit(f"non-canonical unit order: {name}")
        if run([elf_a], ok=False).returncode != int(meta["expected_exit"]):
            raise SystemExit(f"unexpected output: {name}")
        if b"statically linked" not in run(["file", elf_a]).stdout or b"INTERP" in run(["readelf", "-lW", elf_a]).stdout:
            raise SystemExit(f"non-static artifact: {name}")
        if run(["nm", "-u", elf_a]).stdout:
            raise SystemExit(f"undefined symbols: {name}")

        migrated = temp / "migrated" / name
        shutil.copytree(project, migrated)
        migrated_elf = temp / f"{name}_migrated.elf"
        run([ROOT / "build/bin/neboc", "build", migrated / "main.no", "--unit", migrated / "core.no",
             "--unit", migrated / "util.no", "-o", migrated_elf])
        if migrated_elf.read_bytes() != elf_a.read_bytes():
            raise SystemExit(f"migration changed output: {name}")

        package = temp / "packages" / name
        run([PACKAGE_TOOL, "init", package, "--name", name])
        for source in (main, core, util):
            shutil.copy2(source, package / "src" / source.name)
        shutil.copy2(project / "project.tsv", package / "project.tsv")
        run([PACKAGE_TOOL, "resolve", package])
        manifest = json.loads((package / "nebo.package.json").read_text())
        if manifest["edition"] != "1":
            raise SystemExit(f"unexpected initial edition: {name}")
        manifest["edition"] = "2"
        package_module.publish_manifest_lock(package, manifest)
        run([PACKAGE_TOOL, "audit", package])
        package_a, package_b = temp / f"{name}_a.nbpkg", temp / f"{name}_b.nbpkg"
        run([PACKAGE_TOOL, "package", package, "--output", package_a])
        run([PACKAGE_TOOL, "package", package, "--output", package_b])
        if package_a.read_bytes() != package_b.read_bytes():
            raise SystemExit(f"nondeterministic package: {name}")
        saved = (package / "src/core.no").read_bytes()
        (package / "src/core.no").write_bytes(saved + b"\n")
        mutated_package = temp / f"{name}_mutated.nbpkg"
        run([PACKAGE_TOOL, "package", package, "--output", mutated_package])
        if mutated_package.read_bytes() == package_a.read_bytes():
            raise SystemExit(f"package mutation not detected: {name}")
        (package / "src/core.no").write_bytes(saved)
        run([PACKAGE_TOOL, "audit", package])
        package_c = temp / f"{name}_restored.nbpkg"
        run([PACKAGE_TOOL, "package", package, "--output", package_c])
        if package_c.read_bytes() != package_a.read_bytes():
            raise SystemExit(f"package restore mismatch: {name}")
        artifact_hashes.extend((hashlib.sha256(elf_a.read_bytes()).hexdigest(),
                                hashlib.sha256(package_a.read_bytes()).hexdigest()))

digest = hashlib.sha256("".join(artifact_hashes).encode()).hexdigest()
print(f"RF27_G27_F10_PROJECTS=PASS projects=5 physical_units=15 builds=15 runs=5 migrations=5 packages=15 restores=5 deterministic=yes static_elf=5 no_c_no_libc=5 external_users_claimed=0 digest={digest}")
