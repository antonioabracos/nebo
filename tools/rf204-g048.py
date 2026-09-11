#!/usr/bin/env python3
"""Local CLI host for the bounded G048 analysis and source-change surfaces."""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
from pathlib import Path
import sys


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.static_analysis import (
    AnalysisError, ApiBaseline, CompilerSession, FixPlan, Refactor,
    SourceChange, SourceOptimizer, api_diff,
)
from compiler.sdk.text_tooling import (
    FixPlan as TextFixPlan, FormatTree, LintRuleRegistry, report_diagnostics,
)

MAX_JSON_BYTES = 1 << 20


def execute(script: str, arguments: list[str]) -> int:
    path = ROOT / "tools" / script
    os.environ["PYTHONDONTWRITEBYTECODE"] = "1"
    os.execv(sys.executable, [sys.executable, "-B", "-S", str(path), *arguments])
    return 127


def _emit(value: object) -> None:
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))


def _formatter():
    spec = importlib.util.spec_from_file_location("nebo_g048_formatter", ROOT / "tools/rf27-format.py")
    if spec is None or spec.loader is None:
        raise AnalysisError("NEBO-G048-FORMATTER-UNAVAILABLE")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _comment_tool():
    spec = importlib.util.spec_from_file_location("nebo_g164_comments", ROOT / "tools/rf204-g164.py")
    if spec is None or spec.loader is None:
        raise AnalysisError("NEBO-G164-COMMENT-TOOL-UNAVAILABLE")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _paths(values: list[str]) -> list[Path]:
    if not values:
        raise AnalysisError("NEBO-G048-PATH-REQUIRED")
    return [Path(value) for value in values]


def _json_object(value: str) -> dict[str, object]:
    selected = Path(value)
    if selected.is_symlink():
        raise AnalysisError("NEBO-G048-JSON-REGULAR-REQUIRED")
    path = selected.resolve()
    if not path.is_file() or path.stat().st_size > MAX_JSON_BYTES:
        raise AnalysisError("NEBO-G048-JSON-REGULAR-REQUIRED")
    result = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(result, dict):
        raise AnalysisError("NEBO-G048-JSON-OBJECT-REQUIRED")
    return result


def _format_plan(paths: list[Path]) -> FixPlan:
    formatter = _formatter()
    plan = FixPlan.new(paths)
    for path, original in plan.sources.items():
        replacement = formatter.canonicalize(original)
        if replacement != original:
            plan.add({"path": path, "start": 0, "end": len(original), "replacement": replacement})
    return plan.orderCanonical()


def _change_from_plan(path: str) -> SourceChange:
    raw = _json_object(path)
    if not isinstance(raw.get("before"), list) or not isinstance(raw.get("after"), list):
        raise AnalysisError("NEBO-G048-CHANGE-PLAN-SCHEMA")
    before = tuple(Path(str(item)).resolve() for item in raw["before"])
    after = tuple(Path(str(item)).resolve() for item in raw["after"])
    return SourceChange(before, after)


def _verify(change: SourceChange, level: str) -> dict[str, object]:
    levels = {"parse": 1, "check": 2, "tests": 3, "differential": 4}
    if level not in levels:
        raise AnalysisError("NEBO-G048-VERIFY-LEVEL")
    change.verifyParse()
    if levels[level] >= 2:
        change.verifySemantics()
        change.compareHir("equivalent")
        change.comparePublicApi()
    if levels[level] >= 3:
        change.runSelectedTests({"sources": change.after})
    if levels[level] >= 4:
        change.differentialRun([b""])
    return change.reviewReport()


def command_api_diff(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc api-diff")
    parser.add_argument("baseline")
    parser.add_argument("current")
    args = parser.parse_args(arguments)
    def load(value: str) -> dict[str, object]:
        path = Path(value).resolve()
        if path.suffix == ".json":
            return _json_object(str(path))
        return ApiBaseline.capture(path)
    result = api_diff(load(args.baseline), load(args.current))
    _emit(result)
    return 1 if result["classification"] == "breaking" else 0


def command_fix(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc fix")
    parser.add_argument("paths", nargs="*")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--verify", choices=("parse", "check", "tests", "differential"))
    args = parser.parse_args(arguments)
    modes = sum(bool(value) for value in (args.check, args.preview, args.apply, args.verify))
    if modes != 1:
        raise AnalysisError("NEBO-G048-FIX-MODE")
    if args.verify:
        if len(args.paths) != 1:
            raise AnalysisError("NEBO-G048-VERIFY-PLAN")
        report = _verify(_change_from_plan(args.paths[0]), args.verify)
        _emit(report)
        return 0 if report["decision"] != "REJECTED" else 2
    plan = _format_plan(_paths(args.paths))
    if args.check:
        _emit(plan.report())
        return 1 if plan.edits else 0
    if args.preview:
        sys.stdout.write(str(plan.preview("unified")))
        return 0
    report = plan.apply("source-write", "confirmed")
    checked = plan.recheck()
    _emit({"apply": report, "recheck": checked})
    return 0 if checked["status"] == "PASS" else 2


def command_refactor(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc refactor")
    parser.add_argument("operation", choices=("rename", "extract-function", "inline-function",
                                               "extract-binding", "move-item", "change-signature",
                                               "organize-imports", "copy-to-borrow", "if-to-match"))
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--symbol")
    parser.add_argument("--new-name")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args(arguments)
    session = CompilerSession.fromSources(_paths(args.paths))
    refactor = Refactor(session)
    if args.operation != "rename":
        _emit({"operation": args.operation, "decision": "MANUAL_REQUIRED",
               "reason": "typed operation-specific proof is required", "snapshot": session.snapshot})
        return 0
    if not args.symbol or not args.new_name:
        raise AnalysisError("NEBO-G048-RENAME-OPTIONS")
    plan = refactor.rename(args.symbol, args.new_name)
    if not args.apply:
        sys.stdout.write(str(plan.preview("unified")))
        return 0
    if refactor.publicApiImpact() == "breaking":
        raise AnalysisError("NEBO-G048-BREAKING-AUTO-APPLY-FORBIDDEN")
    report = plan.apply("source-write", "confirmed")
    checked = plan.recheck()
    _emit({"operation": "rename", "affectedFiles": refactor.affectedFiles(),
           "apiImpact": refactor.publicApiImpact(), "apply": report, "recheck": checked})
    return 0 if checked["status"] == "PASS" else 2


def _optimizer(paths: list[Path], edition: str | None = None) -> SourceOptimizer:
    optimizer = SourceOptimizer.new("v1", {"passes": 32}, paths)
    optimizer.simplifyConstants().simplifyControlFlow().removeDeadBindings()
    optimizer.canonicalizeLoops().mergeEquivalentBranches()
    optimizer.rewriteDeprecatedApis({})
    if edition is not None:
        optimizer.upgradeEdition("1", edition)
    optimizer.preserveComments("preserve")
    return optimizer


def command_source_optimize(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc source-optimize")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args(arguments)
    if sum((args.check, args.preview, args.apply)) != 1:
        raise AnalysisError("NEBO-G048-SOURCE-OPT-MODE")
    optimizer = _optimizer(_paths(args.paths))
    if args.check:
        _emit(optimizer.report())
        return 1 if optimizer.plan.edits else 0
    if args.preview:
        sys.stdout.write(str(optimizer.plan.preview("unified")))
        return 0
    report = optimizer.plan.apply("source-write", "confirmed")
    checked = optimizer.plan.recheck()
    _emit({"optimizer": optimizer.report(), "apply": report, "recheck": checked})
    return 0 if checked["status"] == "PASS" else 2


def command_modernize(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc modernize")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--edition", required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args(arguments)
    optimizer = _optimizer(_paths(args.paths), args.edition)
    report = optimizer.report()
    if args.apply and optimizer.plan.edits:
        applied = optimizer.plan.apply("source-write", "confirmed")
        checked = optimizer.plan.recheck()
        report = {**report, "apply": applied, "recheck": checked}
        _emit(report)
        return 0 if checked["status"] == "PASS" else 2
    _emit(report)
    return 0


def command_change_review(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc change-review")
    parser.add_argument("plan")
    args = parser.parse_args(arguments)
    report = _verify(_change_from_plan(args.plan), "differential")
    _emit(report)
    return 0 if report["decision"] != "REJECTED" else 2


def command_lint(arguments: list[str]) -> int:
    if "--group" in arguments:
        try:
            group_index = arguments.index("--group")
            group = arguments[group_index + 1]
        except (ValueError, IndexError) as error:
            raise AnalysisError("NEBO-G083-LINT-GROUP") from error
        if group == "docs":
            return execute("rf204-g157.py", ["lint", *arguments])
        return _comment_tool().lint(arguments)
    parser = argparse.ArgumentParser(prog="neboc lint")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--profile", default="recommended")
    parser.add_argument("--report", choices=("text", "json", "sarif"), default="text")
    parser.add_argument("--warnings-as-errors", action="store_true")
    parser.add_argument("--fix-preview", action="store_true")
    args = parser.parse_args(arguments)
    registry = LintRuleRegistry()
    diagnostics = []
    previews: list[str] = []
    for path in _paths(args.paths):
        if path.is_symlink():
            raise AnalysisError("NEBO-G083-LINT-REGULAR-REQUIRED")
        selected = path.resolve()
        if not selected.is_file():
            raise AnalysisError("NEBO-G083-LINT-REGULAR-REQUIRED")
        tree = FormatTree.parse(selected.read_bytes())
        diagnostics.extend(registry.lint(tree, args.profile))
        if args.fix_preview:
            preview = TextFixPlan.forFormatting(selected).preview()
            if preview:
                previews.append(preview)
    if args.fix_preview:
        sys.stdout.write("".join(previews))
    else:
        sys.stdout.write(report_diagnostics(diagnostics, args.report))
    return 1 if diagnostics and args.warnings_as_errors else 0


COMMANDS = {
    "api-diff": command_api_diff,
    "fix": command_fix,
    "refactor": command_refactor,
    "source-optimize": command_source_optimize,
    "modernize": command_modernize,
    "change-review": command_change_review,
    "lint": command_lint,
}


def main(arguments: list[str]) -> int:
    if not arguments or arguments[0] not in COMMANDS:
        raise AnalysisError("NEBO-G048-COMMAND")
    return COMMANDS[arguments[0]](arguments[1:])


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (AnalysisError, OSError, UnicodeError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"NEBO_G048_TOOL_ERROR:{error}", file=sys.stderr)
        raise SystemExit(2)
