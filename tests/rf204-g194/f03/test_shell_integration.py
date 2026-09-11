#!/usr/bin/env python3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; env=(ROOT/"sdk/nebo-1.0/shell/nebo-env.sh").read_text(); comp=(ROOT/"sdk/nebo-1.0/shell/neboc.bash").read_text()
assert "NEBO_SDK_ROOT" in env and "PATH" in env and ".bashrc" not in env and ".profile" not in env
assert "check emit-asm build --help --version" in comp
print("RF204-G194-F03=PASS")
