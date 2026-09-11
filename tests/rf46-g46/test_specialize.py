#!/usr/bin/env python3
from __future__ import annotations

from compiler.ir.ir import IrModule, Node
from compiler.optimizer.specialize import Code, SpecializationError, Specializer


def source() -> IrModule:
    return IrModule([
        Node(0, "param", origin="specialize.no:1:1"),
        Node(1, "const", value=2, origin="specialize.no:1:5"),
        Node(2, "mul", (0, 1), origin="specialize.no:1:3"),
        Node(3, "return", (2,), origin="specialize.no:1:1"),
    ])


def main() -> None:
    optimizer = Specializer()
    after, report = optimizer.specialize("twice", source(), {0: 21})
    assert after.nodes[0].value == 21 and after.nodes[2].value == 42
    assert report.assumptions == ("param[0]=21",)
    assert report.evaluation_steps == 4
    again, second = Specializer().specialize("twice", source(), {0: 21})
    assert after.serialize() == again.serialize()
    assert report.serialize() == second.serialize()
    try:
        Specializer.constant_fold("add", (1 << 63) - 1, 1)
    except SpecializationError as error:
        assert error.diagnostic == "NG46_F0303"
    else:
        raise AssertionError("overflow folded")
    propagated, propagated_report = Code.propagateConstants(source())
    assert propagated.nodes[1].value == 2 and propagated_report.operation == "propagate-constants"
    inlined, inline_report = Code.inline(source(), {"max_nodes": 4})
    branchless, branch_report = Code.eliminateDeadBranches(source())
    unrolled, unroll_report = Code.unroll(source(), 2, {"max_factor": 4})
    expected = source().serialize()
    assert inlined.serialize() == branchless.serialize() == unrolled.serialize() == expected
    assert inline_report.status == "NO_CALL_NODES"
    assert branch_report.status == "NO_BRANCH_NODES"
    assert unroll_report.status == "NO_LOOP_NODES"
    via_facade, facade_report = Code.specialize(("twice", source()), {0: 21})
    assert via_facade.serialize() == after.serialize() and facade_report.cacheKey() == report.cache_key
    assert facade_report.report() == report.serialize()
    print(f"RF46_G46_F03_ORACLE_GREEN result={after.nodes[2].value} cache={report.cache_key} steps={report.evaluation_steps}")


if __name__ == "__main__":
    main()
