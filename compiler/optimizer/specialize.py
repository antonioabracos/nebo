"""Bounded pure-I64 partial evaluation for NEBO-IR-V1."""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json

from compiler.ir.ir import IrError, IrModule, Node


class SpecializationError(IrError):
    pass


@dataclass(frozen=True)
class SpecializationReport:
    status: str
    assumptions: tuple[str, ...]
    before: str
    after: str
    size_delta: int
    evaluation_steps: int
    cache_key: str

    def serialize(self) -> str:
        return json.dumps({
            "after": self.after,
            "assumptions": list(self.assumptions),
            "before": self.before,
            "cache_key": self.cache_key,
            "evaluation_steps": self.evaluation_steps,
            "size_delta": self.size_delta,
            "status": self.status,
        }, sort_keys=True, separators=(",", ":")) + "\n"


class Specializer:
    VERSION = "NEBO-SPECIALIZATION-V1"
    MAX_SPECIALIZATIONS_PER_FUNCTION = 32
    MAX_SPECIALIZED_FUNCTIONS_PER_SESSION = 256
    MAX_CODE_GROWTH_RATIO = 4
    MAX_PARTIAL_EVAL_STEPS = 1_000_000

    def __init__(self) -> None:
        self._function_counts: dict[str, int] = {}
        self._session_functions: set[str] = set()

    @staticmethod
    def _i64(value: int) -> int:
        if not -(1 << 63) <= value < (1 << 63):
            raise SpecializationError("NG46_F0303", "I64 overflow is not foldable")
        return value

    @classmethod
    def constant_fold(cls, op: str, left: int, right: int) -> int:
        if op == "add":
            return cls._i64(left + right)
        if op == "sub":
            return cls._i64(left - right)
        if op == "mul":
            return cls._i64(left * right)
        raise SpecializationError("NG46_F0302", "operation is not pure-foldable")

    def specialize(self, function: str, module: IrModule, known_arguments: dict[int, int]) -> tuple[IrModule, SpecializationReport]:
        if not function or len(known_arguments) > 32:
            raise SpecializationError("NG46_F0301", "specialization argument limit")
        count = self._function_counts.get(function, 0)
        if count >= self.MAX_SPECIALIZATIONS_PER_FUNCTION:
            raise SpecializationError("NG46_F0301", "per-function specialization limit")
        if function not in self._session_functions and len(self._session_functions) >= self.MAX_SPECIALIZED_FUNCTIONS_PER_SESSION:
            raise SpecializationError("NG46_F0301", "session specialization limit")
        values: dict[int, int] = {}
        rewritten: list[Node] = []
        steps = 0
        assumptions = []
        for node in module.nodes:
            steps += 1
            if steps > self.MAX_PARTIAL_EVAL_STEPS:
                raise SpecializationError("NG46_F0301", "evaluation step limit")
            if node.effect != "PURE":
                raise SpecializationError("NG46_F0302", "effectful node")
            after = node
            if node.op == "param" and node.id in known_arguments:
                value = self._i64(known_arguments[node.id])
                after = Node(node.id, "const", (), value, node.type, node.effect, node.ownership, node.origin)
                assumptions.append(f"param[{node.id}]={value}")
            elif node.op in {"add", "sub", "mul"} and all(arg in values for arg in node.args):
                value = self.constant_fold(node.op, values[node.args[0]], values[node.args[1]])
                after = Node(node.id, "const", (), value, node.type, node.effect, node.ownership, node.origin)
            if after.op == "const":
                assert after.value is not None
                values[after.id] = after.value
            rewritten.append(after)
        result = IrModule(rewritten, layer=module.layer)
        if len(result.nodes) > len(module.nodes) * self.MAX_CODE_GROWTH_RATIO:
            raise SpecializationError("NG46_F0301", "code growth limit")
        key_payload = self.VERSION + "\0" + function + "\0" + module.digest() + "\0" + json.dumps(known_arguments, sort_keys=True)
        key = hashlib.sha256(key_payload.encode()).hexdigest()
        report = SpecializationReport(
            "SPECIALIZED_PURE_I64", tuple(assumptions), module.digest(), result.digest(),
            len(result.serialize()) - len(module.serialize()), steps, key,
        )
        self._function_counts[function] = count + 1
        self._session_functions.add(function)
        return result, report

    @staticmethod
    def propagate_constants(_module: IrModule) -> None:
        raise SpecializationError("NG46_F0302", "whole-module propagation is contract-only")

    inline = propagate_constants
    eliminate_dead_branches = propagate_constants
    unroll = propagate_constants
