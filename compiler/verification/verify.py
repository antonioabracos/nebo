"""Bounded differential verification substrate for NEBO-IR-V1."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
import hashlib
from typing import Callable, Iterable

from compiler.ir.ir import IrError, IrModule


class VerificationStatus(str, Enum):
    VERIFIED_WITHIN_BOUNDS = "VERIFIED_WITHIN_BOUNDS"
    DIFFERENTIAL_PASS = "DIFFERENTIAL_PASS"
    UNKNOWN = "UNKNOWN"
    TIMEOUT = "TIMEOUT"
    DIVERGED = "DIVERGED"
    INVALID_IR = "INVALID_IR"
    UNSUPPORTED = "UNSUPPORTED"


@dataclass(frozen=True)
class VerificationResult:
    status: VerificationStatus
    cases: int
    counterexample: str | None
    before_hash: str
    after_hash: str


@dataclass(frozen=True)
class OptimizationPass:
    name: str
    version: int
    transform: Callable[[IrModule], IrModule]
    required: tuple[str, ...] = ("validated-ir",)
    preserved: tuple[str, ...] = ("types", "effects", "ownership", "origins")

    def verify(self, before: IrModule, after: IrModule) -> VerificationResult:
        return verify_equivalence(before, after)

    def fuzz(self, corpus: Iterable[tuple[IrModule, IrModule]]) -> tuple[VerificationResult, ...]:
        return tuple(verify_equivalence(before, after) for before, after in corpus)


def _evaluate(module: IrModule, arguments: dict[int, int], max_steps: int = 1_000_000) -> int:
    values: dict[int, int] = {}
    for steps, node in enumerate(module.nodes, start=1):
        if steps > max_steps:
            raise TimeoutError
        if node.op == "const":
            assert node.value is not None
            value = node.value
        elif node.op == "param":
            if node.id not in arguments:
                raise KeyError(node.id)
            value = arguments[node.id]
        elif node.op in {"add", "sub", "mul"}:
            left, right = (values[index] for index in node.args)
            value = left + right if node.op == "add" else left - right if node.op == "sub" else left * right
        elif node.op == "return":
            return values[node.args[0]]
        else:
            raise NotImplementedError(node.op)
        if not -(1 << 63) <= value < (1 << 63):
            raise OverflowError
        values[node.id] = value
    raise IrError("NG46_F0601", "return not reached")


def verify_equivalence(before: IrModule, after: IrModule) -> VerificationResult:
    try:
        before.validate()
        after.validate()
    except IrError:
        return VerificationResult(VerificationStatus.INVALID_IR, 0, None, "INVALID", "INVALID")
    if before.serialize() == after.serialize():
        return VerificationResult(VerificationStatus.VERIFIED_WITHIN_BOUNDS, 0, None, before.digest(), after.digest())
    before_params = tuple(node.id for node in before.nodes if node.op == "param")
    after_params = tuple(node.id for node in after.nodes if node.op == "param")
    if before_params != after_params or len(before_params) > 4:
        return VerificationResult(VerificationStatus.UNSUPPORTED, 0, None, before.digest(), after.digest())
    samples = (-17, -3, -1, 0, 1, 2, 7, 31)
    cases = 0
    for sample in samples:
        arguments = {node_id: sample for node_id in before_params}
        try:
            left = _evaluate(before, arguments)
            right = _evaluate(after, arguments)
        except TimeoutError:
            return VerificationResult(VerificationStatus.TIMEOUT, cases, None, before.digest(), after.digest())
        except (KeyError, NotImplementedError, OverflowError):
            return VerificationResult(VerificationStatus.UNKNOWN, cases, None, before.digest(), after.digest())
        cases += 1
        if left != right:
            counterexample = f"arguments={arguments};before={left};after={right}"
            return VerificationResult(VerificationStatus.DIVERGED, cases, counterexample, before.digest(), after.digest())
    return VerificationResult(VerificationStatus.DIFFERENTIAL_PASS, cases, None, before.digest(), after.digest())


class Pipeline:
    def __init__(self) -> None:
        self._passes: list[OptimizationPass] = []
        self._last_results: tuple[VerificationResult, ...] = ()

    def add(self, optimization_pass: OptimizationPass) -> None:
        if not optimization_pass.name or optimization_pass.version != 1 or any(item.name == optimization_pass.name for item in self._passes):
            raise IrError("NG46_F0601", "invalid pass DAG")
        self._passes.append(optimization_pass)

    def run(self, module: IrModule) -> IrModule:
        current = module
        results = []
        for optimization_pass in self._passes:
            candidate = optimization_pass.transform(current)
            candidate.validate()
            result = optimization_pass.verify(current, candidate)
            results.append(result)
            if result.status not in {VerificationStatus.VERIFIED_WITHIN_BOUNDS, VerificationStatus.DIFFERENTIAL_PASS}:
                self._last_results = tuple(results)
                raise IrError("NG46_F0603", f"pass {optimization_pass.name}: {result.status.value}")
            current = candidate
        self._last_results = tuple(results)
        return current

    def bisect_failure(self, module: IrModule) -> str | None:
        current = module
        for optimization_pass in self._passes:
            candidate = optimization_pass.transform(current)
            result = verify_equivalence(current, candidate)
            if result.status not in {VerificationStatus.VERIFIED_WITHIN_BOUNDS, VerificationStatus.DIFFERENTIAL_PASS}:
                return f"{optimization_pass.name}@{optimization_pass.version}:{result.status.value}:{result.counterexample}"
            current = candidate
        return None

    def determinism_report(self, module: IrModule) -> str:
        first = self.run(module).serialize()
        second = self.run(module).serialize()
        status = "PASS" if first == second else "DIVERGED"
        return f"pipeline-determinism={status}\nresult-sha256={hashlib.sha256(first).hexdigest()}\n"
