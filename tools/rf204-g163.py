#!/usr/bin/python3
"""Public offline host for the edition-owned Nebo prelude contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from compiler.sdk.prelude import (  # noqa: E402
    PRELUDE_PATH,
    REGISTRY_PATH,
    TARGET,
    Prelude,
    PreludeError,
    PreludeInterface,
    PreludeMigration,
    PreludeProfile,
    StdlibModuleRegistry,
    _code_without_comments_strings,
    _source_text,
    apply_migration,
    reachableComponents,
    verify_visibility,
    without_std_imports,
)


NEBOC = ROOT / "build/bin/neboc"
if not NEBOC.is_file():
    NEBOC = ROOT / "bin/neboc"


def emit(value: object) -> None:
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))


def source_line_for(text: str, needle: str) -> tuple[int, int]:
    offset = _code_without_comments_strings(without_std_imports(text)).find(needle)
    if offset < 0:
        return 1, 1
    line = text.count("\n", 0, offset) + 1
    start = text.rfind("\n", 0, offset) + 1
    return line, offset - start + 1


def native_check(path: Path, text: str, mode: str = "check", output: str | None = None,
                 message_format: str | None = None, color: str | None = None, units=(),
                 diagnostic_options=()) -> int:
    # The visibility layer consumes only authenticated std.* import records.
    # The remaining source is admitted by the existing parser/semantic/lowering
    # owner through a private non-recursive command alias.
    admitted = without_std_imports(text).encode()
    if units:
        from compiler.sdk.module_program import project_typed_program
        projected_program=project_typed_program(path,admitted,units,NEBOC)
        if projected_program is not None:admitted=projected_program;units=()
    with tempfile.TemporaryDirectory(prefix="nebo-g163-check-") as temporary:
        projected = Path(temporary) / path.name
        projected.write_bytes(admitted)
        arguments=[str(NEBOC), "g163-native-"+mode, str(projected)]
        for unit in units:arguments.extend(('--unit',str(Path(unit).absolute())))
        if output is not None:arguments.extend(("-o",str(Path(output).absolute())))
        if message_format is not None:arguments.extend(("--message-format",message_format))
        if color is not None:arguments.extend(("--color",color))
        arguments.extend(diagnostic_options)
        result = subprocess.run(
            arguments,
            cwd=ROOT,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
            check=False,
        )
    sys.stdout.buffer.write(result.stdout.replace(str(projected).encode(),str(path).encode()))
    sys.stderr.buffer.write(result.stderr.replace(str(projected).encode(),str(path).encode()))
    return result.returncode


def command_check(arguments: list[str], mode: str = "check") -> int:
    parser = argparse.ArgumentParser(prog="neboc "+mode)
    parser.add_argument("source")
    parser.add_argument("--no-prelude", action="store_true")
    parser.add_argument("--edition", default="1")
    parser.add_argument("--target", default=TARGET)
    parser.add_argument("-o","--output",required=mode!="check")
    parser.add_argument("--message-format",choices=("human","short","json-lines","json","sarif"))
    parser.add_argument("--color",choices=("auto","never","always"))
    parser.add_argument("--unit",action='append',default=[])
    if mode == "build":
        parser.add_argument("--quiet", action="count", default=0)
    # Preserve repetitions for the native owner to reject; argparse must not
    # silently collapse duplicate options or implement a second recovery policy.
    if mode == "check":
        parser.add_argument("--max-errors", action="append", default=[])
        parser.add_argument("--path-style", action="append", default=[])
        for option in ("--fail-fast", "--keep-going", "--show-fixes"):
            parser.add_argument(option, action="count", default=0)
    args = parser.parse_args(arguments)
    path = Path(os.path.abspath(args.source))
    _, text, _ = _source_text(path)
    interface = PreludeInterface.load(PreludeProfile.forEdition(args.edition), args.target)
    try:
        visibility = verify_visibility(text, interface, args.no_prelude)
    except PreludeError as error:
        candidate = ""
        if error.code == "NEBO-RF166-G163-002":
            candidate = error.message.split()[2].rstrip(";")
        elif error.code == "NEBO-RF166-G163-004":
            candidate = error.message.rsplit(" ", 1)[-1]
        line, column = source_line_for(text, candidate)
        registry = StdlibModuleRegistry.load()
        owner = registry.owner_of(candidate)
        quick_fix = "NONE"
        if owner is not None:
            alias = owner.rsplit(".", 1)[-1]
            quick_fix = f'import "{owner}" {{ {candidate}; }}.{alias};'
        related = PRELUDE_PATH if error.code == "NEBO-RF166-G163-002" else REGISTRY_PATH
        raise PreludeError(
            error.code,
            f"{error.message}; primary={path}:{line}:{column}; "
            f"related={related.relative_to(ROOT)}; quick-fix={quick_fix}; "
            "note=no resolver, interface, lowering, or artifact state was published",
        ) from error
    if mode=="check" and args.output is not None:parser.error("check has no output artifact")
    diagnostic_options = []
    if mode == "build":
        diagnostic_options.extend(["--quiet"] * args.quiet)
    if mode == "check":
        for option, values in (("--max-errors", args.max_errors), ("--path-style", args.path_style)):
            for value in values:diagnostic_options.extend((option, value))
        for option in ("--fail-fast", "--keep-going", "--show-fixes"):
            diagnostic_options.extend([option] * getattr(args, option[2:].replace("-", "_")))
    status = native_check(path, text, mode, args.output, args.message_format, args.color,args.unit,
                          diagnostic_options)
    if status:
        return status
    if visibility["missing"]:
        raise PreludeError("NEBO-RF166-G163-009", "native admission diverged from no-prelude visibility")
    return 0


def command_prelude_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc prelude-report")
    parser.add_argument("--edition", default="1")
    parser.add_argument("--target", default=TARGET)
    parser.add_argument("--source")
    parser.add_argument("--no-prelude", action="store_true")
    args = parser.parse_args(arguments)
    profile = PreludeProfile.forEdition(args.edition)
    if args.no_prelude:
        profile = Prelude.disable(profile)
    interface = PreludeInterface.load(profile, args.target)
    resolver: dict[str, dict[str, str]] = {}
    injected = Prelude.inject(resolver, interface, profile)
    payload: dict[str, object] = {
        "schema": 1,
        "command": "prelude-report",
        "edition": interface.edition,
        "enabled": profile.enabled,
        "freestanding": profile.freestanding,
        "target": interface.target,
        "module": "std.prelude",
        "interfaceVersion": interface.interface_version,
        "interfaceHash": interface.interface_hash,
        "manifest": str(PRELUDE_PATH.relative_to(ROOT)),
        "dependencies": list(interface.dependencies),
        "metadata": {"since": interface.since, "stability": interface.stability,
                     "edition": interface.edition, "target": interface.target,
                     "layer": "PRELUDE"},
        "symbols": Prelude.symbols(interface),
        "injected": len(injected),
        "capabilitiesGranted": [],
        "network": False,
    }
    if args.source:
        path = Path(os.path.abspath(args.source))
        data, text, _ = _source_text(path)
        visibility = verify_visibility(text, interface, not profile.enabled)
        payload["source"] = {
            "path": str(path),
            "sha256": hashlib.sha256(data).hexdigest(),
            "visibility": visibility,
            "reachableComponents": reachableComponents(text, interface, not profile.enabled),
        }
    emit(payload)
    return 0


def migration_payload(edits: list, profile: str, edition: str, applied: int) -> dict[str, object]:
    impact = PreludeMigration.publicApiImpact(edits)
    return {
        "schema": 1,
        "command": "migrate-imports",
        "edition": edition,
        "profile": profile,
        "files": len(edits),
        "changed": sum(row.before != row.after for row in edits),
        "applied": applied,
        "transactional": True,
        "semanticVerified": impact["safe"],
        "publicApiImpact": impact,
        "edits": [
            {
                "path": str(row.path),
                "beforeSha256": row.before_hash,
                "afterSha256": hashlib.sha256(row.after).hexdigest(),
                "insertions": list(row.insertions),
                "removals": list(row.removals),
                "collisions": list(row.collisions),
            }
            for row in edits
        ],
    }


def command_migrate_imports(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc migrate-imports")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--edition", required=True)
    parser.add_argument("--from-edition", default="1")
    parser.add_argument("--profile", choices=("default", "no-prelude"), required=True)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--preview", action="store_true")
    mode.add_argument("--apply", action="store_true")
    parser.add_argument("--target", default=TARGET)
    args = parser.parse_args(arguments)
    edits = PreludeMigration.plan(
        args.from_edition,
        args.edition,
        [Path(value) for value in args.paths],
        profile=args.profile,
        target=args.target,
    )
    impact = PreludeMigration.publicApiImpact(edits)
    if not impact["safe"]:
        emit(migration_payload(edits, args.profile, args.edition, 0))
        return 1
    applied = apply_migration(edits) if args.apply else 0
    emit(migration_payload(edits, args.profile, args.edition, applied))
    return 0


def command_stdlib(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc stdlib modules")
    parser.add_argument("operation", choices=("modules",))
    parser.add_argument("--edition", default="1")
    parser.add_argument("--target", default=TARGET)
    args = parser.parse_args(arguments)
    registry = StdlibModuleRegistry.load()
    registry.require_target(args.target)
    rows = [registry.resolve(str(row["name"]), args.edition, args.target) for row in registry.records]
    emit({
        "schema": 1,
        "command": "stdlib modules",
        "edition": PreludeProfile.forEdition(args.edition).edition,
        "target": args.target,
        "registry": str(REGISTRY_PATH.relative_to(ROOT)),
        "registryHash": registry.registry_hash,
        "modules": rows,
        "network": False,
    })
    return 0


def command_model_corpus(arguments: list[str]) -> int:
    if arguments != ["--verify"]:
        raise PreludeError("USAGE", "_prelude-corpus requires --verify")
    profile = PreludeProfile.forEdition("1")
    interface = PreludeInterface.load(profile, TARGET)
    resolver: dict[str, dict[str, str]] = {}
    injected = Prelude.inject(resolver, interface, profile)
    disabled = Prelude.disable(profile)
    registry = StdlibModuleRegistry.load()
    core = registry.resolve("std.core", "1", TARGET)
    source = "module corpus;\nstart() { Option<Int>(Some(17)).value; value.unwrapOr(0).return; }\n"
    components = reachableComponents(source, interface)
    emit({
        "schema": 1,
        "command": "_prelude-corpus",
        "profile": profile.__dict__,
        "interfaceHash": interface.interface_hash,
        "symbols": len(Prelude.symbols(interface)),
        "injected": len(injected),
        "disabled": disabled.__dict__,
        "core": core,
        "reachable": components,
        "owners": ["PreludeProfile.forEdition", "PreludeInterface.load", "Prelude.inject",
                   "Prelude.symbols", "Prelude.disable", "StdlibModuleRegistry.resolve",
                   "stdlib.reachableComponents", "PreludeMigration.plan",
                   "PreludeMigration.publicApiImpact"],
    })
    return 0


COMMANDS = {
    "check": command_check,
    "emit-asm": lambda arguments: command_check(arguments,"emit-asm"),
    "build": lambda arguments: command_check(arguments,"build"),
    "prelude-report": command_prelude_report,
    "migrate-imports": command_migrate_imports,
    "stdlib": command_stdlib,
    "_prelude-corpus": command_model_corpus,
}


def main(arguments: list[str]) -> int:
    if not arguments or arguments[0] not in COMMANDS:
        raise PreludeError("USAGE", "prelude command is required")
    return COMMANDS[arguments[0]](arguments[1:])


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except PreludeError as error:
        if error.code == "USAGE":
            print(f"neboc: usage: {error.message}", file=sys.stderr)
            raise SystemExit(2)
        print(f"{error.code}: {error.message}", file=sys.stderr)
        raise SystemExit(1)
    except (OSError, UnicodeError, ValueError, TypeError, KeyError, subprocess.TimeoutExpired) as error:
        print(f"NEBO-RF166-G163-009: {error}; note=no partial state was published", file=sys.stderr)
        raise SystemExit(1)
