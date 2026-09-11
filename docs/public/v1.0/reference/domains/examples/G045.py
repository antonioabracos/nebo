#!/usr/bin/env python3
"""Independent value, state, law, and failure oracle for G045 public surfaces."""
from __future__ import annotations

from collections import defaultdict
import hashlib
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.workflows import (  # noqa: E402
    Capability, DecisionTable, RuleSet, Saga, StateMachine, Workflow,
    WorkflowError, WorkflowStep,
)


counts: dict[str, int] = defaultdict(int)
transcript: list[object] = []


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1
    if category == "positive":
        counts["sdk"] += 1


def reject(label: str, suffix: str, callable_) -> None:
    try:
        callable_()
    except WorkflowError as error:
        ok("negative", label, error.code() == f"NEBO-G045-{suffix}" and bool(error.operation()))
        counts["diagnostics"] += 1
        return
    raise AssertionError(f"negative:{label}:accepted")


def canonical(value) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), default=list)


Workflow._registry.clear()
Workflow._instances.clear()
Workflow._counter = 0
run_cap = Capability.issue("workflow-oracle", ("workflow.run", "workflow.inspect", "workflow.repair"))
rule_cap = Capability.issue("rule-oracle", ("rules.fire",))


# S01 — deterministic finite state machine declarations and observations.
machine = StateMachine.new("order-machine", "pending")
ok("positive", "StateMachine.new", machine.name == "order-machine" and machine.current == "pending")
pending = machine.state("pending")
approved = machine.state("approved")
ok("positive", "machine.state", pending.name == "pending" and approved.name == "approved")
pending.on("approve", "approved", lambda ctx: ctx["amount"] <= 500,
           lambda ctx: {**ctx, "approvedBy": "policy-45"})
ok("positive", "state.on", tuple(pending.transitions) == ("approve",))
transition = machine.send("approve", {"amount": 145})
ok("positive", "machine.send", transition["to"] == "approved" and machine.context["approvedBy"] == "policy-45")
ok("positive", "machine.currentState", machine.currentState() == "approved")
ok("positive", "machine.allowedEvents", machine.allowedEvents() == ())
history = machine.transitionHistory(1)
ok("positive", "machine.transitionHistory", history[0]["from"] == "pending" and history[0]["event"] == "approve")
validation = machine.validate()
ok("positive", "machine.validate", validation == {"valid": True, "states": 2, "transitions": 1,
                                                     "reachable": ("approved", "pending")})
transcript.append((transition, history, validation))


# S02 — hierarchy, parallel configuration, lifecycle order, and atomic stepping.
lifecycle: list[str] = []
chart = StateMachine.new("shipment-chart", "idle")
idle = chart.state("idle")
working = chart.state("working")
region_a = working.child("payment")
ok("positive", "state.child", region_a.parent is working)
working.child("inventory")
working.initial(region_a)
ok("positive", "state.initial", working.initial_child == "payment")
working.parallel(("payment", "inventory"))
ok("positive", "state.parallel", working.parallel_regions == ("payment", "inventory"))
working.onEnter(lambda ctx: lifecycle.append("enter-working"))
ok("positive", "state.onEnter", callable(working.enter_action))
idle.onExit(lambda ctx: lifecycle.append("exit-idle"))
ok("positive", "state.onExit", callable(idle.exit_action))
working.history("deep")
ok("positive", "state.history", working.history_mode == "deep")
idle.on("begin", "working")
ok("positive", "machine.activeConfiguration", chart.activeConfiguration() == ("idle",))
chart_step = chart.step("begin")
ok("positive", "machine.step", chart_step["configuration"] == ("working", "payment", "inventory")
   and lifecycle == ["exit-idle", "enter-working"])
transcript.append((chart.activeConfiguration(), lifecycle, chart_step))


# S03 — durable versioned workflow state with logical time and checksums.
workflow = Workflow.define("fulfil-order", 1, None)
ok("positive", "Workflow.define", workflow.name == "fulfil-order" and workflow.version == 1)
reserve = workflow.step("reserve", lambda ctx: {"reserved": ctx["units"] + 4})
ok("positive", "workflow.step", reserve.name == "reserve" and len(workflow.steps) == 1)
run_snapshot = workflow.run({"units": 41, "password": "do-not-report"},
                            {"capability": run_cap, "logicalTime": 100})
ok("positive", "workflow.run", run_snapshot["status"] == "completed"
   and run_snapshot["context"]["reserved"] == 45 and len(run_snapshot["checksum"]) == 64)
wait = workflow.waitFor("warehouse-confirmed", 120)
ok("positive", "workflow.waitFor", wait == {"event": "warehouse-confirmed", "deadline": 120})
ok("positive", "workflow.sleepUntil", workflow.sleepUntil(135) == 135)
checkpoint = workflow.checkpoint()
ok("positive", "workflow.checkpoint", checkpoint["checkpoint"] == 2 and len(checkpoint["checksum"]) == 64)
resumed = workflow.resume(run_snapshot["id"])
ok("positive", "workflow.resume", resumed["status"] == "running" and resumed["version"] == 1)
cancelled = workflow.cancel("customer-request")
ok("positive", "workflow.cancel", cancelled["status"] == "cancelled" and cancelled["reason"] == "customer-request")
transcript.append((run_snapshot["id"], wait, checkpoint["checksum"], resumed["status"], cancelled))


# S04 — bounded retry policy, timeout, idempotency, compensation, and saga state.
compensations: list[str] = []
saga_first = WorkflowStep("charge", lambda ctx: {"charged": 45})
saga_first.retry({"attempts": 3, "backoff": 2, "retryOn": ("transient",)})
ok("positive", "step.retry", saga_first.retry_policy["attempts"] == 3)
saga_first.timeout(25)
ok("positive", "step.timeout", saga_first.timeout_duration == 25)
saga_first.idempotencyKey(lambda ctx: f"charge:{ctx['order']}")
ok("positive", "step.idempotencyKey", saga_first.key_function({"order": 17}) == "charge:17")
saga_first.compensate(lambda ctx: compensations.append("refund"))
ok("positive", "step.compensate", callable(saga_first.compensation))
saga_second = WorkflowStep("prepare", lambda ctx: {"prepared": True})
saga_third = WorkflowStep("ship", lambda ctx: (_ for _ in ()).throw(RuntimeError("carrier")))
saga = Saga.new((saga_first, saga_second, saga_third))
ok("positive", "Saga.new", len(saga.steps) == 3)
saga_result = saga.execute({"order": 17})
ok("positive", "saga.execute", saga_result["status"] == "stuck" and compensations == ["refund"])
ok("positive", "saga.status", saga.status() == "stuck")
manual = saga.manualIntervention("carrier-unavailable")
ok("positive", "saga.manualIntervention", manual["status"] == "manual")
transcript.append((saga_first.retry_policy, saga_result, saga.audit, manual))


# S05 — pure rule decisions and separately authorized effects.
rules = RuleSet.new("shipping-rules", 3)
ok("positive", "RuleSet.new", rules.name == "shipping-rules" and rules.version == 3)
priority_rule = rules.when(lambda ctx: ctx["total"] >= 100, "priority")
ok("positive", "rules.when", priority_rule.label == "priority")
priority_rule.then(lambda ctx: {"lane": "express"})
ok("positive", "rule.then", callable(priority_rule.action))
priority_rule.priority(45)
ok("positive", "rule.priority", priority_rule.priority_value == 45)
rules.when(lambda ctx: ctx["region"] == "EU", "regional").then(lambda ctx: {"tax": "vat"}).priority(20)
decision = rules.evaluate({"total": 145, "region": "EU", "token": "hidden"})
ok("positive", "rules.evaluate", decision.matched == ("priority", "regional") and not decision.fired)
fired = rules.fire({"total": 145, "region": "EU"}, {"capability": rule_cap})
ok("positive", "rules.fire", fired.fired and fired.values == ({"lane": "express"}, {"tax": "vat"}))
explanation = rules.explain(decision)
ok("positive", "rules.explain", explanation["facts"]["token"] == "<redacted>"
   and explanation["matched"] == decision.matched)
rules_valid = rules.validate()
ok("positive", "rules.validate", rules_valid["valid"] and rules_valid["order"] == ("priority", "regional"))
transcript.append((decision.matched, fired.values, explanation, rules_valid))


# S06 — bounded decision tables with independent coverage and conflict reports.
table = DecisionTable.define(("tier", "region"), ("queue",), "unique")
ok("positive", "DecisionTable.define", table.hit_policy == "unique" and table.inputs == ("tier", "region"))
table.row({"tier": (0, 49), "region": "EU"}, {"queue": "standard"})
table.row({"tier": (50, 99), "region": "EU"}, {"queue": "priority"})
ok("positive", "table.row", len(table.rows) == 2)
table_decision = table.decide({"tier": 75, "region": "EU"})
ok("positive", "table.decide", table_decision == {"queue": "priority"})
coverage = table.validateCoverage(({"tier": 5, "region": "EU"}, {"tier": 75, "region": "EU"}))
ok("positive", "table.validateCoverage", coverage == {"covered": True, "cases": 2, "gaps": ()})
conflicts = table.validateConflicts()
ok("positive", "table.validateConflicts", conflicts == {"valid": True, "conflicts": ()})
generated = table.generateTests()
ok("positive", "table.generateTests", generated[0]["input"] == {"tier": 0, "region": "EU"}
   and generated[1]["expected"] == {"queue": "priority"})
table_explanation = table.explain({"tier": 75, "region": "EU"})
ok("positive", "table.explain", table_explanation["matched"] == ("row-2",)
   and table_explanation["result"] == {"queue": "priority"})
table_v2 = DecisionTable.define(("tier", "region"), ("queue",), "unique")
table_v2.row({"tier": (0, 49), "region": "EU"}, {"queue": "standard"})
table_v2.row({"tier": (50, 99), "region": "EU"}, {"queue": "priority"})
table_v2.row({"tier": (100, 149), "region": "EU"}, {"queue": "urgent"})
table_diff = table_v2.diff(table)
ok("positive", "table.diff", table_diff["classification"] == "compatible" and table_diff["added"] == 1)
transcript.append((table_decision, coverage, conflicts, generated, table_explanation, table_diff))


# S07 — upgrades, inspection, replay, repair; CLI verification is tested by validate.sh.
ops_v1 = Workflow.define("ops-flow", 1, None)
ops_v1.step("capture", lambda ctx: {"captured": ctx["amount"]})
ops_instance = ops_v1.run({"amount": 245, "secretNote": "redact-me"},
                          {"capability": run_cap, "logicalTime": 500})
ops_v2 = Workflow.define("ops-flow", 2, None)
ops_v2.step("capture", lambda ctx: {"captured": ctx["amount"]})
ops_v2.step("notify", lambda ctx: {"notified": True})
migrated = ops_v2.migrate(ops_instance["id"], 2, lambda ctx: {**ctx, "schema": "v2"})
ok("positive", "workflow.migrate", migrated["version"] == 2 and migrated["context"]["schema"] == "v2")
compatibility = ops_v2.compatibility(ops_v1)
ok("positive", "workflow.compatibility", compatibility["classification"] == "additive"
   and compatibility["preservedPrefix"])
instances = ops_v2.instances({"capability": run_cap}, 4)
ok("positive", "workflow.instances", len(instances) == 1
   and instances[0]["context"]["secretNote"] == "<redacted>")
timeline = ops_v2.timeline(ops_instance["id"])
ok("positive", "workflow.timeline", timeline[-1]["kind"] == "migrated"
   and timeline[0]["data"]["input"]["secretNote"] == "<redacted>")
metrics = ops_v2.metrics()
ok("positive", "workflow.metrics", metrics["instances"] == 1 and metrics["completed"] == 1)
replay = ops_v2.replay(ops_instance["id"], "verify")
ok("positive", "workflow.replay", replay["verified"] and not replay["mutated"] and replay["events"] == 4)
repair = ops_v2.repair(ops_instance["id"], {"capability": run_cap, "operation": "mark-stuck",
                                                   "reason": "operator-confirmed-divergence"})
ok("positive", "workflow.repair", repair["status"] == "stuck" and repair["operation"] == "mark-stuck")
transcript.append((migrated["checksum"], compatibility, instances, timeline, metrics, replay, repair))


# Stable diagnostics and failure atomicity across all domains.
reject("empty-machine", "NAME-001", lambda: StateMachine.new("", "idle"))
reject("duplicate-state", "FSM-016", lambda: machine.state("pending"))
reject("duplicate-transition", "FSM-004", lambda: pending.on("approve", "approved"))
reject("disallowed-event", "FSM-019", lambda: machine.send("reject", {}))
reject("bad-history-limit", "LIMIT-023", lambda: machine.transitionHistory(257))
reject("bad-parallel", "STATECHART-011", lambda: working.parallel(("payment",)))
reject("unknown-initial-child", "STATECHART-010", lambda: working.initial("missing"))
reject("bad-history-mode", "STATECHART-015", lambda: working.history("implicit"))
chart.state("global-name")
reject("global-child-collision", "STATECHART-008", lambda: working.child("global-name"))
reject("unversioned-workflow", "VERSION-031", lambda: Workflow.define("bad", 0, None))
reject("missing-run-capability", "CAPABILITY-037",
       lambda: workflow.run({"units": 1}, {"logicalTime": 0}))
reject("mutate-started-definition", "DEFINITION-089", lambda: workflow.step("late", lambda ctx: ctx))
reject("backwards-wait", "TIME-042", lambda: workflow.waitFor("late", 2))
reject("bad-retry", "RETRY-027", lambda: WorkflowStep("x", lambda ctx: None).retry({"attempts": 9}))
reject("zero-timeout", "TIMEOUT-028", lambda: WorkflowStep("x", lambda ctx: None).timeout(0))
reject("empty-saga", "SAGA-062", lambda: Saga.new(()))
reject("manual-before-stuck", "SAGA-063", lambda: Saga.new((saga_first,)).manualIntervention("no"))
reject("empty-rules", "RULE-074", lambda: RuleSet.new("empty", 1).validate())
reject("unauthorized-fire", "CAPABILITY-070", lambda: rules.fire({"total": 1, "region": "US"}, {}))
reject("mutate-evaluated-rules", "DEFINITION-090", lambda: rules.when(lambda ctx: True, "late"))
reject("table-no-inputs", "TABLE-076", lambda: DecisionTable.define((), ("x",), "unique"))
reject("table-bad-policy", "TABLE-078", lambda: DecisionTable.define(("x",), ("y",), "magic"))
reject("table-gap", "TABLE-084", lambda: table.decide({"tier": 200, "region": "EU"}))
conflict_table = DecisionTable.define(("x",), ("y",), "unique")
conflict_table.row({"x": 1}, {"y": "a"}).row({"x": 1}, {"y": "b"})
reject("table-conflict", "TABLE-085", lambda: conflict_table.decide({"x": 1}))
reject("table-domain-bound", "LIMIT-086",
       lambda: table.validateCoverage(tuple({"tier": 1, "region": "EU"} for _ in range(257))))
reject("migration-backwards", "VERSION-049",
       lambda: ops_v2.migrate(ops_instance["id"], 1, lambda ctx: ctx))
reject("inspect-without-capability", "CAPABILITY-053", lambda: ops_v2.instances({}, 1))
reject("bad-replay-mode", "REPLAY-056", lambda: ops_v2.replay(ops_instance["id"], "execute"))
reject("repair-without-capability", "CAPABILITY-060",
       lambda: ops_v2.repair(ops_instance["id"], {"operation": "retry", "reason": "x"}))

atomic_machine = StateMachine.new("atomic", "before")
before = atomic_machine.state("before")
atomic_machine.state("after")
before.on("fail", "after", None, lambda ctx: (_ for _ in ()).throw(RuntimeError("fault")))
atomic_checkpoint = (atomic_machine.currentState(), atomic_machine.transitionHistory(8))
reject("fsm-action-fault", "ACTION-022", lambda: atomic_machine.send("fail", {"value": 45}))
ok("failure_atomicity", "fsm-action", atomic_checkpoint ==
   (atomic_machine.currentState(), atomic_machine.transitionHistory(8)))

failing_workflow = Workflow.define("failing-flow", 1, None)
failing_workflow.step("fail", lambda ctx: (_ for _ in ()).throw(RuntimeError("fault"))).retry({"attempts": 2})
reject("workflow-step-fault", "EXECUTION-040",
       lambda: failing_workflow.run({"value": 1}, {"capability": run_cap, "logicalTime": 0}))
failed_item = next(item for item in Workflow._instances.values() if item["workflow"] == "failing-flow")
ok("failure_atomicity", "workflow-bounded-failure", failed_item["status"] == "failed"
   and failed_item["position"] == 0 and failed_item["attempts"]["fail"] == 2)

bad_migration_before = canonical(Workflow._instances[ops_instance["id"]])
reject("migration-fault", "MIGRATION-051",
       lambda: ops_v2.migrate(ops_instance["id"], 3,
                              lambda ctx: (_ for _ in ()).throw(RuntimeError("fault"))))
ok("failure_atomicity", "migration-plan", canonical(Workflow._instances[ops_instance["id"]]) == bad_migration_before)

atomic_rules = RuleSet.new("atomic-rules", 1)
atomic_rules.when(lambda ctx: True, "explode").then(
    lambda ctx: (_ for _ in ()).throw(RuntimeError("fault")))
rule_input = {"value": 45}
reject("rule-action-fault", "ACTION-072", lambda: atomic_rules.fire(rule_input, {"capability": rule_cap}))
ok("failure_atomicity", "rule-action", rule_input == {"value": 45})


# Boundary, metamorphic, adversarial, ownership, and composition properties.
ok("boundary", "history-zero", machine.transitionHistory(0) == ())
ok("boundary", "retry-max", WorkflowStep("max", lambda ctx: None).retry({"attempts": 8}).retry_policy["attempts"] == 8)
ok("boundary", "priority-low", RuleSet.new("boundary", 1).when(lambda ctx: True).priority(-1000).priority_value == -1000)
ok("boundary", "table-range-edge", table.decide({"tier": 49, "region": "EU"})["queue"] == "standard")
ok("boundary", "domain-empty", table.validateCoverage(())["covered"])
ok("boundary", "inspect-one", len(ops_v2.instances({"capability": run_cap}, 1)) == 1)
ok("boundary", "logical-zero", Workflow.define("zero-clock", 1, None).step("x", lambda ctx: ctx).name == "x")

machine_copy = StateMachine.new("machine-copy", "pending")
machine_copy.state("approved")
machine_copy.state("pending").on("approve", "approved", lambda ctx: ctx["amount"] <= 500,
                                  lambda ctx: {**ctx, "approvedBy": "policy-45"})
copy_transition = machine_copy.send("approve", {"amount": 145})
ok("metamorphic", "fsm-renaming-independent", copy_transition["to"] == transition["to"])
ok("metamorphic", "table-repeat", table.decide({"tier": 75, "region": "EU"}) == table_decision)
permuted = DecisionTable.define(("tier", "region"), ("queue",), "unique")
permuted.row({"tier": (50, 99), "region": "EU"}, {"queue": "priority"})
permuted.row({"tier": (0, 49), "region": "EU"}, {"queue": "standard"})
ok("metamorphic", "unique-row-permutation", permuted.decide({"tier": 75, "region": "EU"}) == table_decision)
replay_again = ops_v2.replay(ops_instance["id"], "verify")
ok("metamorphic", "replay-repeat", replay_again["stateHash"] == replay["stateHash"]
   and replay_again["verified"])
ok("metamorphic", "rule-evaluate-repeat", rules.evaluate({"total": 145, "region": "EU"}).matched == decision.matched)
ok("metamorphic", "coverage-order", table.validateCoverage(({"tier": 75, "region": "EU"},
                                                               {"tier": 5, "region": "EU"}))["covered"])
ok("metamorphic", "compatibility-repeat", ops_v2.compatibility(ops_v1) == compatibility)

history[0]["context"]["amount"] = -1
ok("ownership", "history-detached", machine.transitionHistory(1)[0]["context"]["amount"] == 145)
run_snapshot["context"]["reserved"] = -1
ok("ownership", "checkpoint-detached", workflow.checkpoint()["context"]["reserved"] == 45)
instances[0]["context"]["amount"] = -1
ok("ownership", "instances-detached", ops_v2.instances({"capability": run_cap}, 1)[0]["context"]["amount"] == 245)
timeline[0]["data"]["input"]["amount"] = -1
ok("ownership", "timeline-detached", ops_v2.timeline(ops_instance["id"])[0]["data"]["input"]["amount"] == 245)
generated[0]["expected"]["queue"] = "tampered"
ok("ownership", "generated-tests-detached", table.generateTests()[0]["expected"]["queue"] == "standard")
ok("ownership", "rule-input-unchanged", decision.context["total"] == 145)

ok("adversarial", "secret-redaction", "do-not-report" not in canonical(workflow.timeline()))
ok("adversarial", "token-redaction", "hidden" not in canonical(explanation))
ok("adversarial", "bounded-history", len(machine.transitionHistory(256)) <= 256)
ok("adversarial", "no-replay-mutation", ops_v2.replay(ops_instance["id"], "simulate")["mutated"] is False)
ok("adversarial", "conflict-visible", conflict_table.validateConflicts()["conflicts"] == (("row-1", "row-2"),))
ok("adversarial", "logical-time-only", checkpoint["logicalTime"] == 135)
overlap_table = DecisionTable.define(("x",), ("y",), "unique")
overlap_table.row({"x": (1, 5)}, {"y": "left"}).row({"x": (5, 9)}, {"y": "right"})
ok("adversarial", "interval-conflict-visible",
   overlap_table.validateConflicts()["conflicts"] == (("row-1", "row-2"),))

ok("composition", "fsm-statechart", chart.currentState() == "working" and chart.activeConfiguration()[1:] ==
   ("payment", "inventory"))
ok("composition", "workflow-retry-checkpoint", failed_item["attempts"]["fail"] == 2 and len(failed_item["checksum"]) == 64)
ok("composition", "workflow-migration-replay", migrated["version"] == 2 and replay["verified"])
ok("composition", "rules-table", fired.values[0]["lane"] == "express" and table_decision["queue"] == "priority")
ok("composition", "saga-compensation-audit", saga.audit[2] == {"kind": "compensation", "name": "charge"})
ok("composition", "repair-audit", ops_v2.timeline(ops_instance["id"])[-1]["kind"] == "repair")
ok("composition", "native-public-model", validation["states"] == 2 and metrics["instances"] == 1)

for category, expected in {
    "positive": 55, "negative": 33, "boundary": 7, "metamorphic": 7,
    "adversarial": 7, "composition": 7, "ownership": 6,
    "failure_atomicity": 4, "diagnostics": 33, "sdk": 55,
}.items():
    if counts[category] != expected:
        raise AssertionError(f"count:{category}:{counts[category]}!={expected}")

digest = hashlib.sha256(canonical(transcript).encode("utf-8")).hexdigest()
print("G045_SDK_ORACLE_GREEN " + " ".join(
    f"{name}={counts[name]}" for name in (
        "positive", "negative", "boundary", "metamorphic", "adversarial", "composition",
        "ownership", "failure_atomicity", "diagnostics", "sdk"
    )) + f" determinism=7 digest={digest}")
