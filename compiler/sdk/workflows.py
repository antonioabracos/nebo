"""Deterministic, bounded reference SDK for Nebo G045 workflow surfaces.

The module deliberately has no host clock, filesystem, process, thread, or
network dependency.  Time is a caller-supplied logical integer, persistence is
represented by checksummed snapshots, and every effect requires an explicit
capability.  The native G045 owners remain the ABI/runtime implementation; this
module makes the current source-facing contract executable and independently
testable.
"""
from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass, field
import hashlib
import json
from typing import Any, Callable, Iterable, Mapping, Sequence


MAX_STATES = 128
MAX_TRANSITIONS = 1024
MAX_HISTORY = 256
MAX_STEPS = 64
MAX_ATTEMPTS = 8
MAX_SAGA_STEPS = 16
MAX_RULES = 64
MAX_ROWS = 64
MAX_DOMAIN_CASES = 256
REDACTED_KEYS = ("secret", "token", "password", "credential")


class WorkflowError(ValueError):
    """Stable public failure with a machine-readable diagnostic code."""

    def __init__(self, suffix: str, operation: str, detail: str):
        self.suffix = suffix
        self.operation_name = operation
        self.detail = detail
        super().__init__(f"NEBO-G045-{suffix}: {operation}: {detail}")

    def code(self) -> str:
        return f"NEBO-G045-{self.suffix}"

    def operation(self) -> str:
        return self.operation_name


def _require(condition: bool, suffix: str, operation: str, detail: str) -> None:
    if not condition:
        raise WorkflowError(suffix, operation, detail)


def _name(value: Any, operation: str) -> str:
    _require(isinstance(value, str) and 0 < len(value) <= 96,
             "NAME-001", operation, "name must contain 1..96 characters")
    return value


def _logical_time(value: Any, operation: str) -> int:
    _require(isinstance(value, int) and not isinstance(value, bool) and value >= 0,
             "TIME-002", operation, "logical time must be a non-negative integer")
    return value


def _canonical(value: Any) -> bytes:
    try:
        return json.dumps(value, sort_keys=True, separators=(",", ":"),
                          ensure_ascii=True).encode("ascii")
    except (TypeError, ValueError) as error:
        raise WorkflowError("VALUE-003", "canonicalize", "value is not deterministic JSON") from error


def _digest(value: Any) -> str:
    return hashlib.sha256(_canonical(value)).hexdigest()


def _snapshot(value: Any) -> Any:
    return deepcopy(value)


def _redact(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {
            str(key): ("<redacted>" if any(term in str(key).lower() for term in REDACTED_KEYS)
                       else _redact(item))
            for key, item in value.items()
        }
    if isinstance(value, (list, tuple)):
        return [_redact(item) for item in value]
    return value


@dataclass(frozen=True)
class Capability:
    name: str
    permissions: frozenset[str]

    @classmethod
    def issue(cls, name: str, permissions: Iterable[str]) -> "Capability":
        return cls(_name(name, "Capability.issue"), frozenset(permissions))

    def allows(self, permission: str) -> bool:
        return permission in self.permissions


@dataclass
class Transition:
    event: str
    target: str
    guard: Callable[[Mapping[str, Any]], bool] | None
    action: Callable[[dict[str, Any]], Any] | None


class State:
    def __init__(self, machine: "StateMachine", name: str, parent: "State | None" = None):
        self.machine = machine
        self.name = _name(name, "machine.state")
        self.parent = parent
        self.transitions: dict[str, Transition] = {}
        self.children: dict[str, State] = {}
        self.initial_child: str | None = None
        self.parallel_regions: tuple[str, ...] = ()
        self.enter_action: Callable[[dict[str, Any]], Any] | None = None
        self.exit_action: Callable[[dict[str, Any]], Any] | None = None
        self.history_mode: str | None = None

    def on(self, event: str, target: str,
           guard: Callable[[Mapping[str, Any]], bool] | None = None,
           action: Callable[[dict[str, Any]], Any] | None = None) -> "State":
        event = _name(event, "state.on")
        target = _name(target, "state.on")
        _require(event not in self.transitions, "FSM-004", "state.on",
                 "an event has at most one transition per state")
        _require(guard is None or callable(guard), "FSM-005", "state.on", "guard must be callable")
        _require(action is None or callable(action), "FSM-006", "state.on", "action must be callable")
        count = sum(len(item.transitions) for item in self.machine._all_states())
        _require(count < MAX_TRANSITIONS, "LIMIT-007", "state.on", "transition capacity exceeded")
        self.transitions[event] = Transition(event, target, guard, action)
        return self

    def child(self, name: str) -> "State":
        name = _name(name, "state.child")
        _require(self.machine._find(name) is None, "STATECHART-008", "state.child",
                 "state names must be globally unique within a machine")
        _require(len(self.machine._all_states()) < MAX_STATES,
                 "LIMIT-009", "state.child", "state capacity exceeded")
        child = State(self.machine, name, self)
        self.children[name] = child
        return child

    def initial(self, child: str | "State") -> "State":
        name = child.name if isinstance(child, State) else child
        _require(name in self.children, "STATECHART-010", "state.initial", "unknown child")
        self.initial_child = name
        return self

    def parallel(self, regions: Sequence[str | "State"]) -> "State":
        names = tuple(item.name if isinstance(item, State) else item for item in regions)
        _require(1 < len(names) <= 8 and len(set(names)) == len(names),
                 "STATECHART-011", "state.parallel", "parallel regions must be 2..8 unique children")
        _require(all(name in self.children for name in names),
                 "STATECHART-012", "state.parallel", "unknown parallel region")
        self.parallel_regions = names
        return self

    def onEnter(self, action: Callable[[dict[str, Any]], Any]) -> "State":
        _require(callable(action), "STATECHART-013", "state.onEnter", "action must be callable")
        self.enter_action = action
        return self

    def onExit(self, action: Callable[[dict[str, Any]], Any]) -> "State":
        _require(callable(action), "STATECHART-014", "state.onExit", "action must be callable")
        self.exit_action = action
        return self

    def history(self, mode: str) -> "State":
        _require(mode in ("shallow", "deep"), "STATECHART-015", "state.history",
                 "history mode must be shallow or deep")
        self.history_mode = mode
        return self


class StateMachine:
    @classmethod
    def new(cls, name: str, initialState: str) -> "StateMachine":
        return cls(name, initialState)

    def __init__(self, name: str, initial_state: str):
        self.name = _name(name, "StateMachine.new")
        self.initial_state = _name(initial_state, "StateMachine.new")
        self.states: dict[str, State] = {}
        self.current: str = initial_state
        self.context: dict[str, Any] = {}
        self._history: list[dict[str, Any]] = []
        self._active: tuple[str, ...] = (initial_state,)

    def _all_states(self) -> list[State]:
        found: list[State] = []
        pending = list(self.states.values())
        while pending:
            state = pending.pop(0)
            found.append(state)
            pending.extend(state.children.values())
        return found

    def _find(self, name: str) -> State | None:
        return next((state for state in self._all_states() if state.name == name), None)

    def state(self, name: str) -> State:
        name = _name(name, "machine.state")
        _require(name not in self.states, "FSM-016", "machine.state", "duplicate state")
        _require(len(self._all_states()) < MAX_STATES, "LIMIT-017", "machine.state",
                 "state capacity exceeded")
        state = State(self, name)
        self.states[name] = state
        return state

    def send(self, event: str, context: Mapping[str, Any] | None = None) -> dict[str, Any]:
        event = _name(event, "machine.send")
        state = self._find(self.current)
        _require(state is not None, "FSM-018", "machine.send", "current state is undeclared")
        transition = state.transitions.get(event)
        _require(transition is not None, "FSM-019", "machine.send", "event is not allowed")
        target = self._find(transition.target)
        _require(target is not None, "FSM-020", "machine.send", "transition target is undeclared")
        proposed = _snapshot(dict(context if context is not None else self.context))
        before = (self.current, _snapshot(self.context), _snapshot(self._history), self._active)
        try:
            if transition.guard is not None:
                _require(bool(transition.guard(_snapshot(proposed))), "FSM-021", "machine.send",
                         "transition guard rejected the event")
            if state.exit_action is not None:
                state.exit_action(proposed)
            if transition.action is not None:
                result = transition.action(proposed)
                if isinstance(result, Mapping):
                    proposed = _snapshot(dict(result))
            if target.enter_action is not None:
                target.enter_action(proposed)
        except WorkflowError:
            self.current, self.context, self._history, self._active = before
            raise
        except Exception as error:
            self.current, self.context, self._history, self._active = before
            raise WorkflowError("ACTION-022", "machine.send", "guard or action failed atomically") from error
        self.current = target.name
        self.context = proposed
        self._active = self._configuration(target)
        record = {"sequence": len(self._history) + 1, "from": state.name,
                  "event": event, "to": target.name, "context": _snapshot(proposed)}
        self._history.append(record)
        if len(self._history) > MAX_HISTORY:
            del self._history[0]
        return _snapshot(record)

    def currentState(self) -> str:
        return self.current

    def allowedEvents(self) -> tuple[str, ...]:
        state = self._find(self.current)
        return tuple(sorted(state.transitions)) if state else ()

    def transitionHistory(self, limit: int) -> tuple[dict[str, Any], ...]:
        _require(isinstance(limit, int) and 0 <= limit <= MAX_HISTORY,
                 "LIMIT-023", "machine.transitionHistory", "limit must be 0..256")
        return tuple(_snapshot(self._history[-limit:])) if limit else ()

    def validate(self) -> dict[str, Any]:
        _require(self.initial_state in self.states, "FSM-024", "machine.validate",
                 "initial state is undeclared")
        _require(all(transition.target in {state.name for state in self._all_states()}
                     for state in self._all_states() for transition in state.transitions.values()),
                 "FSM-025", "machine.validate", "transition has an undeclared target")
        reachable = {self.initial_state}
        pending = [self.initial_state]
        while pending:
            current = pending.pop(0)
            state = self._find(current)
            if state is None:
                continue
            for transition in state.transitions.values():
                if transition.target not in reachable:
                    reachable.add(transition.target)
                    pending.append(transition.target)
        roots = set(self.states)
        _require(roots <= reachable, "FSM-026", "machine.validate", "unreachable root state")
        return {"valid": True, "states": len(self._all_states()),
                "transitions": sum(len(state.transitions) for state in self._all_states()),
                "reachable": tuple(sorted(reachable))}

    def _configuration(self, state: State) -> tuple[str, ...]:
        names = [state.name]
        if state.parallel_regions:
            names.extend(state.parallel_regions)
        elif state.initial_child:
            names.append(state.initial_child)
        return tuple(names)

    def activeConfiguration(self) -> tuple[str, ...]:
        return tuple(self._active)

    def step(self, event: str) -> dict[str, Any]:
        record = self.send(event, self.context)
        record["configuration"] = self.activeConfiguration()
        return record


@dataclass
class WorkflowStep:
    name: str
    action: Callable[[dict[str, Any]], Any]
    retry_policy: dict[str, Any] = field(default_factory=lambda: {"attempts": 1, "backoff": 0})
    timeout_duration: int | None = None
    key_function: Callable[[Mapping[str, Any]], str] | None = None
    compensation: Callable[[dict[str, Any]], Any] | None = None

    def retry(self, policy: Mapping[str, Any]) -> "WorkflowStep":
        attempts = policy.get("attempts", 1)
        backoff = policy.get("backoff", 0)
        _require(isinstance(attempts, int) and 1 <= attempts <= MAX_ATTEMPTS,
                 "RETRY-027", "step.retry", "attempts must be 1..8")
        _logical_time(backoff, "step.retry")
        self.retry_policy = {"attempts": attempts, "backoff": backoff,
                             "retryOn": tuple(policy.get("retryOn", ("transient",)))}
        return self

    def timeout(self, duration: int) -> "WorkflowStep":
        self.timeout_duration = _logical_time(duration, "step.timeout")
        _require(duration > 0, "TIMEOUT-028", "step.timeout", "timeout must be positive")
        return self

    def idempotencyKey(self, function: Callable[[Mapping[str, Any]], str]) -> "WorkflowStep":
        _require(callable(function), "IDEMPOTENCY-029", "step.idempotencyKey",
                 "key function must be callable")
        self.key_function = function
        return self

    def compensate(self, action: Callable[[dict[str, Any]], Any]) -> "WorkflowStep":
        _require(callable(action), "SAGA-030", "step.compensate", "compensation must be callable")
        self.compensation = action
        return self


class Workflow:
    _registry: dict[str, "Workflow"] = {}
    _instances: dict[str, dict[str, Any]] = {}
    _counter = 0

    @classmethod
    def define(cls, name: str, version: int, body: Callable[["Workflow"], Any] | None) -> "Workflow":
        _require(isinstance(version, int) and version > 0, "VERSION-031", "Workflow.define",
                 "version must be a positive integer")
        _require(body is None or callable(body), "WORKFLOW-032", "Workflow.define",
                 "body must be callable or none")
        workflow = cls(_name(name, "Workflow.define"), version, body)
        key = f"{workflow.name}@{version}"
        prior = cls._registry.get(key)
        _require(prior is None, "VERSION-033", "Workflow.define",
                 "versioned definitions cannot be redefined")
        if body is not None:
            body(workflow)
        cls._registry[key] = workflow
        return workflow

    def __init__(self, name: str, version: int, body: Callable[["Workflow"], Any] | None):
        self.name, self.version, self.body = name, version, body
        self.steps: list[WorkflowStep] = []
        self.instance_id: str | None = None
        self._frozen = False

    def signature(self) -> dict[str, Any]:
        return {"name": self.name, "version": self.version,
                "steps": tuple(step.name for step in self.steps)}

    def step(self, name: str, action: Callable[[dict[str, Any]], Any]) -> WorkflowStep:
        _require(not self._frozen, "DEFINITION-089", "workflow.step",
                 "started workflow versions are immutable")
        name = _name(name, "workflow.step")
        _require(callable(action), "WORKFLOW-034", "workflow.step", "action must be callable")
        _require(len(self.steps) < MAX_STEPS, "LIMIT-035", "workflow.step", "step capacity exceeded")
        _require(all(step.name != name for step in self.steps), "WORKFLOW-036", "workflow.step",
                 "duplicate step")
        step = WorkflowStep(name, action)
        self.steps.append(step)
        return step

    @staticmethod
    def _policy(policy: Mapping[str, Any]) -> tuple[Capability, int]:
        capability = policy.get("capability")
        _require(isinstance(capability, Capability) and capability.allows("workflow.run"),
                 "CAPABILITY-037", "workflow.run", "workflow.run capability required")
        now = _logical_time(policy.get("logicalTime", 0), "workflow.run")
        return capability, now

    def _seal(self, instance: dict[str, Any]) -> None:
        payload = {key: value for key, value in instance.items() if key != "checksum"}
        instance["checksum"] = _digest(payload)

    def _record(self, instance: dict[str, Any], kind: str, data: Mapping[str, Any]) -> None:
        instance["timeline"].append({"sequence": len(instance["timeline"]) + 1,
                                     "kind": kind, "data": _snapshot(dict(data))})

    def run(self, input: Mapping[str, Any], policy: Mapping[str, Any]) -> dict[str, Any]:
        _, now = self._policy(policy)
        _require(len(self.steps) > 0, "WORKFLOW-038", "workflow.run", "workflow has no steps")
        self._frozen = True
        Workflow._counter += 1
        identity = f"{self.name}:{self.version}:{Workflow._counter}"
        context = _snapshot(dict(input))
        instance = {"id": identity, "workflow": self.name, "version": self.version,
                    "status": "running", "logicalTime": now, "position": 0,
                    "context": context, "completed": [], "keys": {}, "attempts": {},
                    "timeline": [], "checkpoint": 0}
        self._record(instance, "started", {"version": self.version, "input": _redact(context)})
        Workflow._instances[identity] = instance
        self.instance_id = identity
        try:
            for index, step in enumerate(self.steps):
                key = step.key_function(context) if step.key_function else f"{identity}:{step.name}"
                _require(isinstance(key, str) and key, "IDEMPOTENCY-039", "workflow.run",
                         "idempotency key must be non-empty text")
                if key in instance["keys"]:
                    continue
                last_error: Exception | None = None
                attempts = step.retry_policy["attempts"]
                for attempt in range(1, attempts + 1):
                    instance["attempts"][step.name] = attempt
                    try:
                        value = step.action(_snapshot(context))
                        if isinstance(value, Mapping):
                            context.update(_snapshot(dict(value)))
                        instance["keys"][key] = _snapshot(value)
                        instance["completed"].append(step.name)
                        instance["position"] = index + 1
                        self._record(instance, "step-completed", {"step": step.name,
                                                                   "attempt": attempt, "key": key})
                        last_error = None
                        break
                    except Exception as error:  # application failure is converted at the boundary
                        last_error = error
                        self._record(instance, "step-failed", {"step": step.name, "attempt": attempt})
                if last_error is not None:
                    raise last_error
            instance["context"] = context
            instance["status"] = "completed"
            self._record(instance, "completed", {"steps": len(instance["completed"])})
        except Exception as error:
            instance["status"] = "failed"
            instance["context"] = context
            self._record(instance, "failed", {"position": instance["position"]})
            self._seal(instance)
            raise WorkflowError("EXECUTION-040", "workflow.run", "step failed after bounded retries") from error
        self._seal(instance)
        return self.checkpoint()

    def _instance(self) -> dict[str, Any]:
        _require(self.instance_id in Workflow._instances, "INSTANCE-041", "workflow.instance",
                 "no active instance")
        return Workflow._instances[self.instance_id]  # type: ignore[index]

    def waitFor(self, event: str, deadline: int) -> dict[str, Any]:
        event = _name(event, "workflow.waitFor")
        deadline = _logical_time(deadline, "workflow.waitFor")
        instance = self._instance()
        _require(deadline >= instance["logicalTime"], "TIME-042", "workflow.waitFor",
                 "deadline precedes logical time")
        instance["status"] = "waiting"
        instance["waiting"] = {"event": event, "deadline": deadline}
        self._record(instance, "waiting", instance["waiting"])
        self._seal(instance)
        return _snapshot(instance["waiting"])

    def sleepUntil(self, time: int) -> int:
        time = _logical_time(time, "workflow.sleepUntil")
        instance = self._instance()
        _require(time >= instance["logicalTime"], "TIME-043", "workflow.sleepUntil",
                 "sleep cannot move logical time backwards")
        instance["logicalTime"] = time
        instance["status"] = "sleeping"
        self._record(instance, "sleeping", {"until": time})
        self._seal(instance)
        return time

    def checkpoint(self) -> dict[str, Any]:
        instance = self._instance()
        instance["checkpoint"] += 1
        self._seal(instance)
        return _snapshot(instance)

    def resume(self, instanceId: str) -> dict[str, Any]:
        _require(instanceId in Workflow._instances, "INSTANCE-044", "workflow.resume",
                 "unknown instance")
        instance = Workflow._instances[instanceId]
        supplied = instance.get("checksum")
        payload = {key: value for key, value in instance.items() if key != "checksum"}
        _require(supplied == _digest(payload), "CHECKSUM-045", "workflow.resume",
                 "instance checksum mismatch")
        _require(instance["workflow"] == self.name and instance["version"] == self.version,
                 "VERSION-046", "workflow.resume", "definition version mismatch")
        self.instance_id = instanceId
        if instance["status"] in ("waiting", "sleeping"):
            instance["status"] = "running"
            self._record(instance, "resumed", {"version": self.version})
            self._seal(instance)
        return _snapshot(instance)

    def cancel(self, reason: str) -> dict[str, Any]:
        reason = _name(reason, "workflow.cancel")
        instance = self._instance()
        _require(instance["status"] not in ("cancelled", "compensated"),
                 "INSTANCE-047", "workflow.cancel", "instance already terminal")
        context = _snapshot(instance["context"])
        for name in reversed(instance["completed"]):
            step = next(item for item in self.steps if item.name == name)
            if step.compensation is not None:
                step.compensation(context)
        instance["status"] = "cancelled"
        self._record(instance, "cancelled", {"reason": reason})
        self._seal(instance)
        return {"id": instance["id"], "status": "cancelled", "reason": reason}

    def migrate(self, instance: str | Mapping[str, Any], targetVersion: int,
                plan: Callable[[dict[str, Any]], Mapping[str, Any]]) -> dict[str, Any]:
        identity = instance if isinstance(instance, str) else instance.get("id")
        _require(identity in Workflow._instances, "INSTANCE-048", "workflow.migrate", "unknown instance")
        current = Workflow._instances[identity]  # type: ignore[index]
        _require(isinstance(targetVersion, int) and targetVersion > current["version"],
                 "VERSION-049", "workflow.migrate", "target must be a newer version")
        _require(callable(plan), "MIGRATION-050", "workflow.migrate", "migration plan required")
        before = _snapshot(current)
        try:
            migrated = dict(plan(_snapshot(current["context"])))
        except Exception as error:
            Workflow._instances[identity] = before  # type: ignore[index]
            raise WorkflowError("MIGRATION-051", "workflow.migrate", "plan failed atomically") from error
        current["context"] = migrated
        current["version"] = targetVersion
        self._record(current, "migrated", {"from": before["version"], "to": targetVersion})
        self._seal(current)
        return _snapshot(current)

    def compatibility(self, previous: "Workflow") -> dict[str, Any]:
        _require(isinstance(previous, Workflow) and previous.name == self.name,
                 "VERSION-052", "workflow.compatibility", "workflow identity mismatch")
        old = tuple(step.name for step in previous.steps)
        new = tuple(step.name for step in self.steps)
        if self.version <= previous.version:
            level = "breaking"
        elif new[:len(old)] == old:
            level = "additive" if len(new) > len(old) else "compatible"
        else:
            level = "migration_required"
        return {"from": previous.version, "to": self.version, "classification": level,
                "preservedPrefix": new[:len(old)] == old}

    def instances(self, filter: Mapping[str, Any], limit: int) -> tuple[dict[str, Any], ...]:
        capability = filter.get("capability")
        _require(isinstance(capability, Capability) and capability.allows("workflow.inspect"),
                 "CAPABILITY-053", "workflow.instances", "workflow.inspect capability required")
        _require(isinstance(limit, int) and 1 <= limit <= 256,
                 "LIMIT-054", "workflow.instances", "limit must be 1..256")
        status = filter.get("status")
        items = [item for item in Workflow._instances.values()
                 if item["workflow"] == self.name and (status is None or item["status"] == status)]
        return tuple(_redact(_snapshot(item)) for item in sorted(items, key=lambda item: item["id"])[:limit])

    def timeline(self, instance: str | None = None) -> tuple[dict[str, Any], ...]:
        identity = instance or self.instance_id
        _require(identity in Workflow._instances, "INSTANCE-055", "workflow.timeline", "unknown instance")
        return tuple(_redact(_snapshot(Workflow._instances[identity]["timeline"])))  # type: ignore[index]

    def metrics(self) -> dict[str, int]:
        items = [item for item in Workflow._instances.values() if item["workflow"] == self.name]
        return {"instances": len(items), "completed": sum(item["status"] == "completed" for item in items),
                "waiting": sum(item["status"] in ("waiting", "sleeping") for item in items),
                "failed": sum(item["status"] == "failed" for item in items),
                "retries": sum(max(0, attempt - 1) for item in items for attempt in item["attempts"].values())}

    def replay(self, instance: str, mode: str) -> dict[str, Any]:
        _require(mode in ("verify", "simulate"), "REPLAY-056", "workflow.replay",
                 "mode must be verify or simulate")
        _require(instance in Workflow._instances, "INSTANCE-057", "workflow.replay", "unknown instance")
        item = Workflow._instances[instance]
        supplied = item["checksum"]
        payload = {key: value for key, value in item.items() if key != "checksum"}
        _require(supplied == _digest(payload), "CHECKSUM-058", "workflow.replay", "checksum mismatch")
        return {"id": instance, "mode": mode, "verified": True,
                "events": len(item["timeline"]), "stateHash": _digest(item["context"]),
                "mutated": False}

    def repair(self, instance: str, action: Mapping[str, Any]) -> dict[str, Any]:
        _require(instance in Workflow._instances, "INSTANCE-059", "workflow.repair", "unknown instance")
        capability = action.get("capability")
        _require(isinstance(capability, Capability) and capability.allows("workflow.repair"),
                 "CAPABILITY-060", "workflow.repair", "workflow.repair capability required")
        reason = _name(action.get("reason"), "workflow.repair")
        operation = action.get("operation")
        _require(operation in ("retry", "cancel", "mark-stuck"),
                 "REPAIR-061", "workflow.repair", "unsupported explicit repair")
        item = Workflow._instances[instance]
        if operation == "retry":
            item["status"] = "running"
        elif operation == "cancel":
            item["status"] = "cancelled"
        else:
            item["status"] = "stuck"
        self._record(item, "repair", {"operation": operation, "reason": reason})
        self._seal(item)
        return {"id": instance, "status": item["status"], "operation": operation, "reason": reason}


class Saga:
    @classmethod
    def new(cls, steps: Sequence[WorkflowStep]) -> "Saga":
        return cls(steps)

    def __init__(self, steps: Sequence[WorkflowStep]):
        _require(0 < len(steps) <= MAX_SAGA_STEPS and all(isinstance(step, WorkflowStep) for step in steps),
                 "SAGA-062", "Saga.new", "saga requires 1..16 workflow steps")
        self.steps = tuple(steps)
        self._status = "ready"
        self.audit: list[dict[str, Any]] = []

    def execute(self, context: Mapping[str, Any]) -> dict[str, Any]:
        state = _snapshot(dict(context))
        completed: list[WorkflowStep] = []
        self._status = "running"
        try:
            for step in self.steps:
                value = step.action(_snapshot(state))
                if isinstance(value, Mapping):
                    state.update(_snapshot(dict(value)))
                completed.append(step)
                self.audit.append({"kind": "step", "name": step.name})
        except Exception as error:
            stuck = False
            for step in reversed(completed):
                if step.compensation is None:
                    stuck = True
                    continue
                try:
                    step.compensation(state)
                    self.audit.append({"kind": "compensation", "name": step.name})
                except Exception:
                    stuck = True
            self._status = "stuck" if stuck else "compensated"
            return {"status": self._status, "completed": len(completed), "context": _snapshot(state),
                    "cause": type(error).__name__}
        self._status = "completed"
        return {"status": self._status, "completed": len(completed), "context": _snapshot(state)}

    def status(self) -> str:
        return self._status

    def manualIntervention(self, reason: str) -> dict[str, Any]:
        reason = _name(reason, "saga.manualIntervention")
        _require(self._status == "stuck", "SAGA-063", "saga.manualIntervention",
                 "manual intervention is only valid for a stuck saga")
        self.audit.append({"kind": "manual-intervention", "reason": reason})
        self._status = "manual"
        return {"status": self._status, "reason": reason}


@dataclass
class Decision:
    matched: tuple[str, ...]
    values: tuple[Any, ...]
    context: dict[str, Any]
    fired: bool = False


class Rule:
    def __init__(self, owner: "RuleSet", condition: Callable[[Mapping[str, Any]], bool], label: str):
        self.owner, self.condition, self.label = owner, condition, label
        self.action: Callable[[dict[str, Any]], Any] | None = None
        self.priority_value = 0

    def then(self, action: Callable[[dict[str, Any]], Any]) -> "Rule":
        _require(not self.owner._frozen, "DEFINITION-090", "rule.then",
                 "evaluated rule-set versions are immutable")
        _require(callable(action), "RULE-064", "rule.then", "action must be callable")
        self.action = action
        return self

    def priority(self, value: int) -> "Rule":
        _require(not self.owner._frozen, "DEFINITION-090", "rule.priority",
                 "evaluated rule-set versions are immutable")
        _require(isinstance(value, int) and -1000 <= value <= 1000,
                 "RULE-065", "rule.priority", "priority must be -1000..1000")
        self.priority_value = value
        return self


class RuleSet:
    @classmethod
    def new(cls, name: str, version: int) -> "RuleSet":
        return cls(name, version)

    def __init__(self, name: str, version: int):
        self.name = _name(name, "RuleSet.new")
        _require(isinstance(version, int) and version > 0,
                 "VERSION-066", "RuleSet.new", "version must be positive")
        self.version = version
        self.rules: list[Rule] = []
        self._frozen = False

    def when(self, condition: Callable[[Mapping[str, Any]], bool], label: str | None = None) -> Rule:
        _require(not self._frozen, "DEFINITION-090", "rules.when",
                 "evaluated rule-set versions are immutable")
        _require(callable(condition), "RULE-067", "rules.when", "condition must be callable")
        _require(len(self.rules) < MAX_RULES, "LIMIT-068", "rules.when", "rule capacity exceeded")
        rule = Rule(self, condition, label or f"rule-{len(self.rules) + 1}")
        _name(rule.label, "rules.when")
        _require(all(item.label != rule.label for item in self.rules),
                 "RULE-069", "rules.when", "duplicate rule label")
        self.rules.append(rule)
        return rule

    def evaluate(self, context: Mapping[str, Any]) -> Decision:
        self._frozen = True
        snapshot = _snapshot(dict(context))
        matched = [rule for rule in self.rules if bool(rule.condition(_snapshot(snapshot)))]
        matched.sort(key=lambda rule: (-rule.priority_value, rule.label))
        return Decision(tuple(rule.label for rule in matched), (), snapshot)

    def fire(self, context: Mapping[str, Any], policy: Mapping[str, Any]) -> Decision:
        capability = policy.get("capability")
        _require(isinstance(capability, Capability) and capability.allows("rules.fire"),
                 "CAPABILITY-070", "rules.fire", "rules.fire capability required")
        decision = self.evaluate(context)
        values: list[Any] = []
        staged = _snapshot(decision.context)
        matched = {label for label in decision.matched}
        for rule in sorted((item for item in self.rules if item.label in matched),
                           key=lambda item: (-item.priority_value, item.label)):
            _require(rule.action is not None, "RULE-071", "rules.fire", "matched rule has no action")
            try:
                value = rule.action(_snapshot(staged))
            except Exception as error:
                raise WorkflowError("ACTION-072", "rules.fire", "rule action failed atomically") from error
            values.append(_snapshot(value))
        return Decision(decision.matched, tuple(values), staged, True)

    def explain(self, decision: Decision) -> dict[str, Any]:
        _require(isinstance(decision, Decision), "RULE-073", "rules.explain", "decision required")
        return {"ruleset": self.name, "version": self.version, "matched": decision.matched,
                "facts": _redact(decision.context), "fired": decision.fired}

    def validate(self) -> dict[str, Any]:
        _require(len(self.rules) > 0, "RULE-074", "rules.validate", "empty rule set")
        _require(all(rule.action is not None for rule in self.rules),
                 "RULE-075", "rules.validate", "every rule needs an action")
        return {"valid": True, "rules": len(self.rules),
                "order": tuple(rule.label for rule in sorted(self.rules,
                                                               key=lambda item: (-item.priority_value,
                                                                                 item.label)))}


@dataclass
class TableRow:
    identity: str
    conditions: Mapping[str, Any]
    result: Mapping[str, Any]


class DecisionTable:
    @classmethod
    def define(cls, inputs: Sequence[str], outputs: Sequence[str], hitPolicy: str) -> "DecisionTable":
        return cls(inputs, outputs, hitPolicy)

    def __init__(self, inputs: Sequence[str], outputs: Sequence[str], hit_policy: str):
        _require(0 < len(inputs) <= 16 and len(set(inputs)) == len(inputs),
                 "TABLE-076", "DecisionTable.define", "inputs must be 1..16 unique names")
        _require(0 < len(outputs) <= 16 and len(set(outputs)) == len(outputs),
                 "TABLE-077", "DecisionTable.define", "outputs must be 1..16 unique names")
        _require(hit_policy in ("unique", "first", "collect"),
                 "TABLE-078", "DecisionTable.define", "unsupported hit policy")
        self.inputs = tuple(_name(item, "DecisionTable.define") for item in inputs)
        self.outputs = tuple(_name(item, "DecisionTable.define") for item in outputs)
        self.hit_policy = hit_policy
        self.rows: list[TableRow] = []

    def row(self, conditions: Mapping[str, Any], result: Mapping[str, Any]) -> "DecisionTable":
        _require(len(self.rows) < MAX_ROWS, "LIMIT-079", "table.row", "row capacity exceeded")
        _require(set(conditions) == set(self.inputs), "TABLE-080", "table.row",
                 "conditions must cover every input")
        _require(set(result) == set(self.outputs), "TABLE-081", "table.row",
                 "result must cover every output")
        for condition in conditions.values():
            _require(callable(condition) or isinstance(condition, (str, int, bool, tuple, list, set, frozenset)),
                     "TABLE-082", "table.row", "unsupported condition")
        self.rows.append(TableRow(f"row-{len(self.rows) + 1}", _snapshot(dict(conditions)),
                                  _snapshot(dict(result))))
        return self

    @staticmethod
    def _matches(condition: Any, value: Any) -> bool:
        if callable(condition):
            return bool(condition(value))
        if isinstance(condition, (set, frozenset, list)):
            return value in condition
        if isinstance(condition, tuple) and len(condition) == 2:
            return condition[0] <= value <= condition[1]
        return value == condition

    @staticmethod
    def _condition_descriptor(condition: Any) -> Any:
        if callable(condition):
            return {"predicate": f"{condition.__module__}.{condition.__qualname__}"}
        if isinstance(condition, (set, frozenset)):
            return {"members": sorted(condition, key=repr)}
        if isinstance(condition, list):
            return {"members": list(condition)}
        if isinstance(condition, tuple) and len(condition) == 2:
            return {"interval": list(condition)}
        return {"equals": condition}

    @staticmethod
    def _overlaps(left: Any, right: Any) -> bool:
        if callable(left) or callable(right):
            return left is right
        if isinstance(left, tuple) and len(left) == 2 and isinstance(right, tuple) and len(right) == 2:
            return max(left[0], right[0]) <= min(left[1], right[1])
        left_values = set(left) if isinstance(left, (set, frozenset, list)) else {left}
        right_values = set(right) if isinstance(right, (set, frozenset, list)) else {right}
        if isinstance(left, tuple) and len(left) == 2:
            return any(left[0] <= value <= left[1] for value in right_values)
        if isinstance(right, tuple) and len(right) == 2:
            return any(right[0] <= value <= right[1] for value in left_values)
        return bool(left_values & right_values)

    def _matching(self, input: Mapping[str, Any]) -> list[TableRow]:
        _require(set(input) == set(self.inputs), "TABLE-083", "table.decide",
                 "input must contain exactly the declared fields")
        return [row for row in self.rows
                if all(self._matches(row.conditions[name], input[name]) for name in self.inputs)]

    def decide(self, input: Mapping[str, Any]) -> Any:
        matched = self._matching(input)
        _require(matched, "TABLE-084", "table.decide", "coverage gap")
        if self.hit_policy == "unique":
            _require(len(matched) == 1, "TABLE-085", "table.decide", "unique hit conflict")
            return _snapshot(dict(matched[0].result))
        if self.hit_policy == "first":
            return _snapshot(dict(matched[0].result))
        return tuple(_snapshot(dict(row.result)) for row in matched)

    def validateCoverage(self, domain: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
        _require(len(domain) <= MAX_DOMAIN_CASES, "LIMIT-086", "table.validateCoverage",
                 "domain exceeds 256 cases")
        gaps = tuple(index for index, item in enumerate(domain) if not self._matching(item))
        return {"covered": not gaps, "cases": len(domain), "gaps": gaps}

    def validateConflicts(self) -> dict[str, Any]:
        conflicts: list[tuple[str, str]] = []
        for left_index, left in enumerate(self.rows):
            for right in self.rows[left_index + 1:]:
                if (all(self._overlaps(left.conditions[name], right.conditions[name]) for name in self.inputs)
                        and left.result != right.result):
                    conflicts.append((left.identity, right.identity))
        return {"valid": not conflicts or self.hit_policy != "unique", "conflicts": tuple(conflicts)}

    def generateTests(self) -> tuple[dict[str, Any], ...]:
        generated = []
        for row in self.rows:
            inputs: dict[str, Any] = {}
            for name, condition in row.conditions.items():
                if callable(condition):
                    inputs[name] = "predicate-sample-required"
                elif isinstance(condition, tuple) and len(condition) == 2:
                    inputs[name] = condition[0]
                elif isinstance(condition, (set, frozenset, list)):
                    inputs[name] = sorted(condition, key=repr)[0]
                else:
                    inputs[name] = condition
            generated.append({"row": row.identity, "input": inputs, "expected": _snapshot(dict(row.result))})
        return tuple(generated)

    def explain(self, input: Mapping[str, Any]) -> dict[str, Any]:
        matched = self._matching(input)
        return {"hitPolicy": self.hit_policy, "input": _redact(dict(input)),
                "matched": tuple(row.identity for row in matched),
                "result": self.decide(input) if matched else None}

    def diff(self, previous: "DecisionTable") -> dict[str, Any]:
        _require(isinstance(previous, DecisionTable), "TABLE-087", "table.diff", "table required")
        def identity(row: TableRow) -> str:
            return _digest({"conditions": {name: self._condition_descriptor(row.conditions[name])
                                            for name in sorted(row.conditions)},
                            "result": row.result})

        old_rows = {identity(row) for row in previous.rows}
        new_rows = {identity(row) for row in self.rows}
        classification = "compatible" if old_rows <= new_rows else "behavioral-change"
        return {"classification": classification, "added": len(new_rows - old_rows),
                "removed": len(old_rows - new_rows), "hitPolicyChanged": self.hit_policy != previous.hit_policy}


__all__ = ["Capability", "Decision", "DecisionTable", "Rule", "RuleSet", "Saga",
           "State", "StateMachine", "Workflow", "WorkflowError", "WorkflowStep"]
