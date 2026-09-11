"""Versioned, bounded public tooling IR for RF46-G46-F02."""

from __future__ import annotations

from dataclasses import asdict, dataclass, replace
import hashlib
import json
from typing import Callable, Iterable


class IrError(ValueError):
    def __init__(self, diagnostic: str, message: str):
        super().__init__(f"{diagnostic}: {message}")
        self.diagnostic = diagnostic


@dataclass(frozen=True)
class Node:
    id: int
    op: str
    args: tuple[int, ...] = ()
    value: int | None = None
    type: str = "I64"
    effect: str = "PURE"
    ownership: str = "VALUE"
    origin: str = "generated:0:0"


@dataclass(frozen=True)
class PassContract:
    pass_id: str
    version: int
    required: tuple[str, ...]
    preserved: tuple[str, ...]
    transform: Callable[[Node], Node]

    def required_analyses(self) -> tuple[str, ...]:
        return self.required

    def preserved_analyses(self) -> tuple[str, ...]:
        return self.preserved

    requiredAnalyses = required_analyses
    preservedAnalyses = preserved_analyses


class IrModule:
    FORMAT = "NEBO-IR-V1"
    MAX_NODES = 256
    OPS = {"const": 0, "param": 0, "add": 2, "sub": 2, "mul": 2, "return": 1}
    TYPES = {"I64"}
    EFFECTS = {"PURE"}
    OWNERSHIP = {"VALUE"}

    def __init__(self, nodes: Iterable[Node], *, layer: str = "LIR"):
        self.layer = layer
        self.nodes = tuple(nodes)
        self.validate()

    def validate(self) -> None:
        if self.layer not in {"AST", "HIR", "LIR"}:
            raise IrError("NG46_F0201", "unknown layer")
        if not self.nodes or len(self.nodes) > self.MAX_NODES:
            raise IrError("NG46_F0201", "node limit")
        seen: set[int] = set()
        for index, node in enumerate(self.nodes):
            if node.id in seen or node.id != index:
                raise IrError("NG46_F0201", "node IDs must be dense and unique")
            if node.op not in self.OPS:
                raise IrError("NG46_F0202", "unknown node")
            if len(node.args) != self.OPS[node.op] or any(arg not in seen for arg in node.args):
                raise IrError("NG46_F0201", "arity or topological order")
            if node.type not in self.TYPES or node.effect not in self.EFFECTS or node.ownership not in self.OWNERSHIP:
                raise IrError("NG46_F0203", "type/effect/ownership violation")
            if node.op == "const" and (not isinstance(node.value, int) or not -(1 << 63) <= node.value < (1 << 63)):
                raise IrError("NG46_F0201", "constant outside I64")
            if node.op != "const" and node.value is not None:
                raise IrError("NG46_F0201", "unexpected literal")
            seen.add(node.id)
        if self.nodes[-1].op != "return":
            raise IrError("NG46_F0201", "terminal return required")

    def visit(self, visitor: Callable[[Node], None]) -> None:
        for node in self.nodes:
            visitor(node)

    def rewrite(self, contract: PassContract) -> "IrModule":
        if not contract.pass_id or contract.version != 1:
            raise IrError("NG46_F0203", "invalid pass identity")
        rewritten: list[Node] = []
        for before in self.nodes:
            after = contract.transform(before)
            if (after.id, after.type, after.effect, after.ownership, after.origin) != (
                before.id, before.type, before.effect, before.ownership, before.origin
            ):
                raise IrError("NG46_F0203", "rewrite changed protected metadata")
            rewritten.append(after)
        return IrModule(rewritten, layer=self.layer)

    transform = rewrite

    def serialize(self) -> bytes:
        payload = {
            "format": self.FORMAT,
            "layer": self.layer,
            "nodes": [{**asdict(node), "args": list(node.args)} for node in self.nodes],
        }
        return (json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n").encode()

    @classmethod
    def deserialize(cls, data: bytes) -> "IrModule":
        if len(data) > 1_048_576:
            raise IrError("NG46_F0201", "serialized byte limit")
        try:
            payload = json.loads(data)
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise IrError("NG46_F0201", "invalid serialization") from error
        if set(payload) != {"format", "layer", "nodes"} or payload["format"] != cls.FORMAT:
            raise IrError("NG46_F0202", "unknown format")
        nodes = []
        for item in payload["nodes"]:
            if set(item) != {"id", "op", "args", "value", "type", "effect", "ownership", "origin"}:
                raise IrError("NG46_F0202", "unknown node field")
            nodes.append(Node(**(item | {"args": tuple(item["args"])})))
        return cls(nodes, layer=payload["layer"])

    def digest(self) -> str:
        return hashlib.sha256(self.serialize()).hexdigest()

    def diff(self, other: "IrModule") -> tuple[str, ...]:
        result = []
        for index in range(max(len(self.nodes), len(other.nodes))):
            left = self.nodes[index] if index < len(self.nodes) else None
            right = other.nodes[index] if index < len(other.nodes) else None
            if left != right:
                result.append(f"node[{index}]={left!r}->{right!r}")
        return tuple(result)


Ast = IrModule
Hir = IrModule
Lir = IrModule


def replace_node(node: Node, **changes: object) -> Node:
    return replace(node, **changes)
