#!/usr/bin/env python3
from __future__ import annotations

from compiler.ir.ir import IrError, IrModule, Node
from compiler.verification.verify import OptimizationPass, Pipeline, VerificationStatus, verify_equivalence


def baseline() -> IrModule:
    return IrModule([Node(0, "param"), Node(1, "return", (0,))])


def add_zero() -> IrModule:
    return IrModule([Node(0, "param"), Node(1, "const", value=0), Node(2, "add", (0, 1)), Node(3, "return", (2,))])


def add_one() -> IrModule:
    return IrModule([Node(0, "param"), Node(1, "const", value=1), Node(2, "add", (0, 1)), Node(3, "return", (2,))])


def main() -> None:
    same = verify_equivalence(baseline(), baseline())
    equivalent = verify_equivalence(baseline(), add_zero())
    divergent = verify_equivalence(baseline(), add_one())
    assert same.status == VerificationStatus.VERIFIED_WITHIN_BOUNDS
    assert equivalent.status == VerificationStatus.DIFFERENTIAL_PASS and equivalent.cases == 8
    assert divergent.status == VerificationStatus.DIVERGED and divergent.counterexample
    identity = OptimizationPass.new("identity", lambda module: module)
    assert identity.fuzz([baseline(), baseline()], lambda _module: add_zero())[1].status == VerificationStatus.DIFFERENTIAL_PASS
    pipeline = Pipeline()
    pipeline.add(identity)
    assert pipeline.run(baseline()).serialize() == baseline().serialize()
    assert pipeline.determinismReport().startswith("pipeline-determinism=PASS\n")
    bad = Pipeline()
    bad.add(OptimizationPass("wrong", 1, lambda _module: add_one()))
    assert bad.bisectFailure(baseline()).startswith("wrong@1:DIVERGED:")
    try:
        bad.run(baseline())
    except IrError as error:
        assert error.diagnostic == "NG46_F0603"
    else:
        raise AssertionError("divergent pass accepted")
    print("RF46_G46_F06_ORACLE_GREEN statuses=VERIFIED_WITHIN_BOUNDS,DIFFERENTIAL_PASS,DIVERGED unknown_is_not_pass=yes cases=8")


if __name__ == "__main__":
    main()
