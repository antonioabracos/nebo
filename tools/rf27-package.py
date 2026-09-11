#!/usr/bin/env python3
"""Deterministic offline-only Nebo path package manager."""
from __future__ import annotations

import argparse
from hashlib import sha256
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
import zipfile

MANIFEST = "nebo.package.json"
LOCK = "nebo.lock.json"
STATE = ".nebo-state"
MAX_NODES = 64
MAX_EDGES = 256
MAX_FILE = 16_777_216


class PackageError(Exception):
    pass


def canonical(value: object) -> bytes:
    return (json.dumps(value, sort_keys=True, indent=2, separators=(",", ": ")) + "\n").encode()


def atomic_write(path: Path, content: bytes) -> None:
    handle, raw = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temp = Path(raw)
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp, path)
    finally:
        temp.unlink(missing_ok=True)


def publish_state(project: Path, manifest_bytes: bytes, lock_bytes: bytes) -> None:
    """Publish the manifest/lock pair through one atomic generation pointer."""
    state = project / STATE
    state.mkdir(mode=0o755, exist_ok=True)
    identity = sha256(manifest_bytes + b"\0" + lock_bytes).hexdigest()
    generation = state / f"gen-{identity}"
    if not generation.exists():
        temporary = Path(tempfile.mkdtemp(prefix=".generation.", dir=state))
        try:
            atomic_write(temporary / MANIFEST, manifest_bytes)
            atomic_write(temporary / LOCK, lock_bytes)
            os.replace(temporary, generation)
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)
    current = state / "current"
    handle, raw = tempfile.mkstemp(prefix=".current.", dir=state)
    os.close(handle)
    temporary_link = Path(raw)
    temporary_link.unlink()
    try:
        os.symlink(generation.name, temporary_link)
        os.replace(temporary_link, current)
    finally:
        temporary_link.unlink(missing_ok=True)
    for name in (MANIFEST, LOCK):
        public = project / name
        expected = f"{STATE}/current/{name}"
        if public.exists() or public.is_symlink():
            if not public.is_symlink() or os.readlink(public) != expected:
                raise PackageError(f"non-canonical package state link: {public}")
        else:
            os.symlink(expected, public)


def load_json(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise PackageError(f"invalid JSON: {path}") from exc
    if not isinstance(value, dict):
        raise PackageError(f"object required: {path}")
    return value


def version_tuple(text: str) -> tuple[int, int, int]:
    try:
        parts = tuple(int(part) for part in text.split("."))
    except ValueError as exc:
        raise PackageError(f"invalid semantic version: {text}") from exc
    if len(parts) != 3 or any(part < 0 or part > 65535 for part in parts):
        raise PackageError(f"invalid semantic version: {text}")
    return parts


def validate_manifest(value: dict, path: Path) -> None:
    if value.get("schema") != 1 or not isinstance(value.get("name"), str):
        raise PackageError(f"invalid manifest identity: {path}")
    if not value["name"] or not value["name"].replace("-", "").replace("_", "").isalnum():
        raise PackageError(f"invalid package name: {value.get('name')}")
    version_tuple(value.get("version", ""))
    deps = value.get("dependencies")
    if not isinstance(deps, dict):
        raise PackageError(f"dependencies object required: {path}")


def package_files(root: Path) -> list[Path]:
    result: list[Path] = []
    for path in sorted(root.rglob("*"), key=lambda item: item.relative_to(root).as_posix()):
        relative = path.relative_to(root)
        if relative.parts[0] in {".git", "vendor", STATE} or relative.name == LOCK or relative.suffix == ".nbpkg":
            continue
        if path.is_symlink():
            if relative.as_posix() != MANIFEST:
                raise PackageError(f"symlink forbidden in package: {relative}")
        if path.is_file():
            if path.stat().st_size > MAX_FILE:
                raise PackageError(f"file exceeds 16 MiB: {relative}")
            result.append(path)
    return result


def content_digest(root: Path) -> str:
    digest = sha256()
    for path in package_files(root):
        relative = path.relative_to(root).as_posix().encode()
        content = path.read_bytes()
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest()


def resolve_graph(project: Path, root_manifest: dict | None = None) -> dict:
    root_manifest = root_manifest or load_json(project / MANIFEST)
    validate_manifest(root_manifest, project / MANIFEST)
    nodes: dict[str, dict] = {}
    visiting: set[Path] = set()
    seen_paths: dict[str, Path] = {}
    edges = 0

    def visit(base: Path, manifest: dict) -> None:
        nonlocal edges
        real = base.resolve()
        if real in visiting:
            raise PackageError(f"dependency cycle at {real}")
        name = manifest["name"]
        previous = seen_paths.get(name)
        if previous is not None and previous != real:
            raise PackageError(f"package name conflict: {name}")
        if name in nodes:
            return
        if len(nodes) >= MAX_NODES:
            raise PackageError("package node budget exceeded")
        visiting.add(real)
        seen_paths[name] = real
        dependencies: list[str] = []
        for dep_name, raw in sorted(manifest["dependencies"].items()):
            edges += 1
            if edges > MAX_EDGES:
                raise PackageError("package edge budget exceeded")
            if not isinstance(raw, dict) or set(raw) != {"path", "min_version"}:
                raise PackageError(f"local path and min_version required for {dep_name}")
            dep_path_text = raw["path"]
            if not isinstance(dep_path_text, str) or "://" in dep_path_text:
                raise PackageError(f"network dependency forbidden: {dep_name}")
            dep_path = (real / dep_path_text).resolve()
            dep_manifest = load_json(dep_path / MANIFEST)
            validate_manifest(dep_manifest, dep_path / MANIFEST)
            if dep_manifest["name"] != dep_name:
                raise PackageError(f"dependency name mismatch: {dep_name}")
            if version_tuple(dep_manifest["version"]) < version_tuple(raw["min_version"]):
                raise PackageError(f"minimum version not satisfied: {dep_name}")
            visit(dep_path, dep_manifest)
            dependencies.append(dep_name)
        visiting.remove(real)
        relative = os.path.relpath(real, project.resolve()).replace(os.sep, "/")
        nodes[name] = {
            "version": manifest["version"], "path": relative,
            "sha256": content_digest(real), "dependencies": dependencies,
        }

    visit(project, root_manifest)
    root_name = root_manifest["name"]
    entries = {name: nodes[name] for name in sorted(nodes) if name != root_name}
    return {"schema": 1, "root": root_name, "root_version": root_manifest["version"],
            "nodes": entries, "node_count": len(nodes), "edge_count": edges}


def init(project: Path, name: str) -> None:
    project.mkdir(parents=True, exist_ok=True)
    if (project / MANIFEST).exists() or (project / LOCK).exists():
        raise PackageError("project already initialized")
    manifest = {"schema": 1, "name": name, "version": "0.1.0", "edition": "1",
                "dependencies": {}}
    validate_manifest(manifest, project / MANIFEST)
    (project / "src").mkdir()
    atomic_write(project / "src/main.no", b"start() {\n}\n")
    manifest_bytes = canonical(manifest)
    lock_bytes = canonical(resolve_graph(project, manifest))
    publish_state(project, manifest_bytes, lock_bytes)


def publish_manifest_lock(project: Path, manifest: dict) -> None:
    validate_manifest(manifest, project / MANIFEST)
    lock = resolve_graph(project, manifest)
    manifest_bytes, lock_bytes = canonical(manifest), canonical(lock)
    publish_state(project, manifest_bytes, lock_bytes)


def add(project: Path, dependency: Path, min_version: str | None) -> None:
    manifest = load_json(project / MANIFEST)
    dep_manifest = load_json(dependency.resolve() / MANIFEST)
    validate_manifest(manifest, project / MANIFEST)
    validate_manifest(dep_manifest, dependency / MANIFEST)
    name = dep_manifest["name"]
    if name in manifest["dependencies"]:
        raise PackageError(f"dependency already exists: {name}")
    minimum = min_version or dep_manifest["version"]
    version_tuple(minimum)
    relative = os.path.relpath(dependency.resolve(), project.resolve()).replace(os.sep, "/")
    manifest["dependencies"][name] = {"path": relative, "min_version": minimum}
    publish_manifest_lock(project, manifest)


def remove(project: Path, name: str) -> None:
    manifest = load_json(project / MANIFEST)
    validate_manifest(manifest, project / MANIFEST)
    if name not in manifest["dependencies"]:
        raise PackageError(f"dependency not found: {name}")
    del manifest["dependencies"][name]
    publish_manifest_lock(project, manifest)


def resolve(project: Path) -> None:
    manifest = load_json(project / MANIFEST)
    publish_state(project, canonical(manifest), canonical(resolve_graph(project, manifest)))


def audit(project: Path) -> None:
    expected = canonical(resolve_graph(project))
    if not (project / LOCK).is_file() or (project / LOCK).read_bytes() != expected:
        raise PackageError("lockfile integrity mismatch")


def vendor(project: Path) -> None:
    audit(project)
    lock = load_json(project / LOCK)
    destination = project / "vendor"
    if destination.exists():
        raise PackageError("vendor directory already exists")
    temporary = Path(tempfile.mkdtemp(prefix=".vendor.", dir=project))
    try:
        for name, node in lock["nodes"].items():
            source = (project / node["path"]).resolve()
            shutil.copytree(source, temporary / name, symlinks=False,
                            ignore=shutil.ignore_patterns(".git", "vendor", STATE, "*.nbpkg", LOCK))
        os.replace(temporary, destination)
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)


def package(project: Path, output: Path) -> None:
    audit(project)
    files = package_files(project)
    handle, raw = tempfile.mkstemp(prefix=f".{output.name}.", suffix=".tmp", dir=output.parent)
    os.close(handle)
    temporary = Path(raw)
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_STORED) as archive:
            for path in files + [project / LOCK]:
                relative = path.relative_to(project).as_posix()
                info = zipfile.ZipInfo(relative, (1980, 1, 1, 0, 0, 0))
                info.external_attr = (0o100644 & 0xFFFF) << 16
                archive.writestr(info, path.read_bytes())
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)


def main(argv: list[str] | None = None) -> int:
    supplied = list(sys.argv[1:] if argv is None else argv)
    if len(supplied) >= 2 and supplied[0] == 'package' and supplied[1] in {'freeze', 'verify', 'restore', 'build'}:
        sys.dont_write_bytecode = True
        sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
        from compiler.sdk.package_manager import main as exact_package
        return exact_package(supplied[1:])
    parser = argparse.ArgumentParser(prog="neboc package")
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("init"); p.add_argument("project", type=Path); p.add_argument("--name", required=True)
    p = sub.add_parser("add"); p.add_argument("project", type=Path); p.add_argument("dependency", type=Path); p.add_argument("--min-version")
    p = sub.add_parser("remove"); p.add_argument("project", type=Path); p.add_argument("name")
    for command in ("resolve", "audit", "vendor"):
        p = sub.add_parser(command); p.add_argument("project", type=Path)
    p = sub.add_parser("package"); p.add_argument("project", type=Path); p.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        if args.command == "init": init(args.project.resolve(), args.name)
        elif args.command == "add": add(args.project.resolve(), args.dependency, args.min_version)
        elif args.command == "remove": remove(args.project.resolve(), args.name)
        elif args.command == "resolve": resolve(args.project.resolve())
        elif args.command == "audit": audit(args.project.resolve())
        elif args.command == "vendor": vendor(args.project.resolve())
        elif args.command == "package": package(args.project.resolve(), args.output.resolve())
    except (OSError, PackageError) as exc:
        print(f"neboc package: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
