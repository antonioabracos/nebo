#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from compiler.ir.ir import IrError, IrModule, PassContract, replace_node


ROOT = Path(__file__).resolve().parents[2]


def rejected(data: bytes, diagnostic: str) -> None:
    try:
        IrModule.deserialize(data)
    except IrError as error:
        assert error.diagnostic == diagnostic
    else:
        raise AssertionError("invalid IR accepted")


def main() -> None:
    data = (ROOT / "examples/evolution/rf46-g46/ir-v1.json").read_bytes()
    module = IrModule.deserialize(data)
    assert module.serialize() == data
    visited: list[int] = []
    module.visit(lambda node: visited.append(node.id))
    assert visited == [0, 1, 2, 3]
    identity = PassContract("identity", 1, ("types",), ("types", "effects", "ownership"), lambda node: node)
    after = module.transform(identity)
    assert after.digest() == module.digest() and module.diff(after) == ()
    changed = module.rewrite(PassContract(
        "constant-edit", 1, ("types",), ("types", "effects", "ownership"),
        lambda node: replace_node(node, value=21) if node.id == 0 else node,
    ))
    assert len(module.diff(changed)) == 1
    assert identity.required_analyses() == ("types",)
    assert identity.preserved_analyses() == ("types", "effects", "ownership")
    rejected(data.replace(b'"add"', b'"unknown"'), "NG46_F0202")
    rejected(data.replace(b'"args":[0,1]', b'"args":[0,9]'), "NG46_F0201")
    try:
        module.rewrite(PassContract("bad", 1, (), (), lambda node: replace_node(node, effect="IO") if node.id == 0 else node))
    except IrError as error:
        assert error.diagnostic == "NG46_F0203"
    else:
        raise AssertionError("effect-changing rewrite accepted")
    print(f"RF46_G46_F02_ORACLE_GREEN format={module.FORMAT} nodes={len(module.nodes)} digest={module.digest()}")


if __name__ == "__main__":
    main()
