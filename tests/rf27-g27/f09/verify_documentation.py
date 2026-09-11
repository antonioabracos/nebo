#!/usr/bin/env python3
import hashlib
import pathlib
import re
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[3]
DOCS = [
    "LANGUAGE-GUIDE.md", "REFERENCE.md", "COOKBOOK.md", "COMPATIBILITY.md",
    "SECURITY-GUIDE.md", "INSTALLATION-TARGETS.md", "PACKAGES-TOOLING.md", "MIGRATION.md",
]
allowed = {"nebo", "bash", "text"}
examples = []
for name in DOCS:
    text = (ROOT / "docs/public" / name).read_text()
    fences = re.findall(r"^```([^\n]*)$", text, re.M)
    if (fences and (len(fences) % 2 or
            any(label not in allowed for label in fences[::2]) or
            any(label for label in fences[1::2]))):
        raise SystemExit(f"invalid fence label: {name}")
    blocks = re.findall(r"```nebo\n(.*?)\n```", text, re.S)
    marked = re.findall(r"<!-- expect-exit: (\d+) -->\s*```nebo\n(.*?)\n```", text, re.S)
    if len(blocks) != len(marked):
        raise SystemExit(f"unverified Nebo block: {name}")
    examples.extend((name, int(code), source) for code, source in marked)

joined = "\n".join((ROOT / "docs/public" / name).read_text() for name in DOCS)
for forbidden in ("print(", "AArch64 is certified", "real external users validated"):
    if forbidden in joined:
        raise SystemExit(f"unsafe documentation claim: {forbidden}")

with tempfile.TemporaryDirectory(prefix="rf27-g27-f09-") as raw:
    temp = pathlib.Path(raw)
    hashes = []
    for index, (name, expected, source) in enumerate(examples):
        src = temp / f"example_{index}.no"
        asm_a = temp / f"example_{index}_a.asm"
        asm_b = temp / f"example_{index}_b.asm"
        elf_a = temp / f"example_{index}_a"
        elf_b = temp / f"example_{index}_b"
        src.write_text(source + "\n")
        subprocess.run([ROOT / "build/bin/neboc", "check", src], check=True, stdout=subprocess.DEVNULL)
        subprocess.run([ROOT / "build/bin/neboc", "emit-asm", src, "-o", asm_a], check=True)
        subprocess.run([ROOT / "build/bin/neboc", "emit-asm", src, "-o", asm_b], check=True)
        subprocess.run([ROOT / "build/bin/neboc", "build", src, "-o", elf_a], check=True)
        subprocess.run([ROOT / "build/bin/neboc", "build", src, "-o", elf_b], check=True)
        if asm_a.read_bytes() != asm_b.read_bytes() or elf_a.read_bytes() != elf_b.read_bytes():
            raise SystemExit(f"nondeterministic example: {name}")
        result = subprocess.run([elf_a], check=False)
        if result.returncode != expected:
            raise SystemExit(f"unexpected example result: {name}: {result.returncode}")
        hashes.append(hashlib.sha256(elf_a.read_bytes()).hexdigest())

print(f"RF27_G27_F09_DOCS=PASS documents={len(DOCS)} verified_nebo_blocks={len(examples)} deterministic_builds={len(examples) * 2} digest={hashlib.sha256(''.join(hashes).encode()).hexdigest()}")
