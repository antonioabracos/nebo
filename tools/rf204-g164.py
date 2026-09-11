#!/usr/bin/env python3
"""G164 public comment-trivia dump and security lint surfaces."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.comment_tooling import CommentModel, CommentToolError, MAX_SOURCE


def bounded_source(raw: str) -> tuple[Path, bytes]:
    path = Path(raw).absolute()
    info = path.lstat()
    if path.is_symlink() or not path.is_file() or info.st_size > MAX_SOURCE:
        raise CommentToolError(2, 0, "source must be a regular non-symlink file within 1 MiB")
    return path, path.read_bytes()


def dump_trivia(raw: str) -> int:
    path, source = bounded_source(raw)
    value = CommentModel.scan(source).public()
    value["path"] = str(path)
    print(json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    return 0


def lint(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc lint")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--group", required=True, choices=("comments",))
    parser.add_argument("--report", choices=("text", "json", "sarif"), default="text")
    args = parser.parse_args(arguments)
    findings: list[dict[str, object]] = []
    codes = ((4, "NEBO_COMMENT_BIDI_CONTROL"),
             (8, "NEBO_COMMENT_INVISIBLE"),
             (16, "NEBO_COMMENT_CONFUSABLE_SCRIPT"))
    for raw in args.paths:
        path, source = bounded_source(raw)
        model = CommentModel.scan(source)
        for item in model.comments:
            for flag, code in codes:
                if item.flags & flag:
                    findings.append({
                        "code": code, "severity": "warning", "path": str(path),
                        "start": item.start, "end": item.end,
                        "message": f"suspicious Unicode control or confusable bytes in {item.kind} comment",
                    })
    if args.report == "json":
        print(json.dumps({"schema": 1, "group": "comments", "findings": findings},
                         sort_keys=True, separators=(",", ":")))
    elif args.report == "sarif":
        results = [{"ruleId": item["code"], "level": "warning", "message": {"text": item["message"]},
                    "locations": [{"physicalLocation": {"artifactLocation": {"uri": item["path"]},
                    "region": {"byteOffset": item["start"], "byteLength": item["end"] - item["start"]}}}]}
                   for item in findings]
        print(json.dumps({"version": "2.1.0", "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
                          "runs": [{"tool": {"driver": {"name": "neboc-comments"}}, "results": results}]},
                         sort_keys=True, separators=(",", ":")))
    else:
        for item in findings:
            print(f"{item['path']}:{item['start']}:{item['end']}: warning {item['code']}: {item['message']}")
    return 1 if findings else 0


def main(arguments: list[str]) -> int:
    if len(arguments) == 3 and arguments[:2] == ["dump", "comment-trivia"]:
        return dump_trivia(arguments[2])
    if arguments and arguments[0] == "lint":
        return lint(arguments[1:])
    raise CommentToolError(1, 0, "invalid G164 arguments")


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (CommentToolError, OSError, UnicodeError) as error:
        print(f"NEBO_G164_COMMENT_ERROR:{error}", file=sys.stderr)
        raise SystemExit(2)
