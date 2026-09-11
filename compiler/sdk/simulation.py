"""Bounded deterministic ECS, physics, scene and replay profile for G043.

The module is a dependency-free executable reference for the current public
surface.  It deliberately uses one deterministic thread, synthetic/local
resources, explicit fixed-step time and bounded containers.  It does not claim
cross-CPU floating-point bit identity or access hardware, a wall clock, the
network, or an external game engine.
"""
from __future__ import annotations

from dataclasses import dataclass, field, replace
import copy
import hashlib
import heapq
import json
import math
from types import MappingProxyType
from typing import Any, Callable, Iterable, Mapping, Sequence


MAX_ENTITIES = 4096
MAX_SYSTEMS = 128
MAX_BODIES = 1024
MAX_CONTACTS = 4096
MAX_CONSTRAINTS = 4096
MAX_ADVANCE_TICKS = 256
MAX_ROLLBACK_TICKS = 1024
MAX_RESOURCES = 1024
MAX_RESOURCE_BYTES = 64 * 1024 * 1024
MAX_PARTICLES = 65536
MAX_TRACE_TICKS = 1024


class SimulationError(RuntimeError):
    """Stable fail-closed diagnostic for the bounded profile."""

    def __init__(self, code: str, operation: str) -> None:
        super().__init__(f"{code}:{operation}")
        self._code = code
        self._operation = operation

    def code(self) -> str:
        return self._code

    def operation(self) -> str:
        return self._operation


def _require(condition: bool, code: str, operation: str) -> None:
    if not condition:
        raise SimulationError(code, operation)


def _integer(value: Any, operation: str, minimum: int = 0,
             maximum: int | None = None) -> int:
    _require(isinstance(value, int) and not isinstance(value, bool),
             "NEBO-G043-INTEGER", operation)
    _require(value >= minimum and (maximum is None or value <= maximum),
             "NEBO-G043-LIMIT", operation)
    return value


def _number(value: Any, operation: str) -> float:
    _require(isinstance(value, (int, float)) and not isinstance(value, bool),
             "NEBO-G043-NUMERIC", operation)
    result = float(value)
    _require(math.isfinite(result), "NEBO-G043-NONFINITE", operation)
    return result


def _vector3(value: Sequence[Any], operation: str) -> tuple[float, float, float]:
    _require(isinstance(value, Sequence) and not isinstance(value, (str, bytes)) and
             len(value) == 3, "NEBO-G043-VECTOR3", operation)
    return tuple(_number(item, operation) for item in value)  # type: ignore[return-value]


def _plain(value: Any) -> Any:
    if isinstance(value, Mapping):
        _require(all(isinstance(key, str) for key in value),
                 "NEBO-G043-SERIALIZATION", "canonical-state")
        return {key: _plain(value[key]) for key in sorted(value)}
    if isinstance(value, (tuple, list)):
        return [_plain(item) for item in value]
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    if isinstance(value, EntityId):
        return {"generation": value.generation, "slot": value.slot}
    if isinstance(value, Component):
        return {"data": _plain(value.data), "type": value.type}
    raise SimulationError("NEBO-G043-SERIALIZATION", "canonical-state")


def _freeze(value: Any) -> Any:
    if isinstance(value, Mapping):
        return MappingProxyType({key: _freeze(item) for key, item in value.items()})
    if isinstance(value, (tuple, list)):
        return tuple(_freeze(item) for item in value)
    return value


def _frozen_mapping(value: Mapping[str, Any]) -> Mapping[str, Any]:
    plain = _plain(value)
    _require(isinstance(plain, dict), "NEBO-G043-SERIALIZATION", "canonical-state")
    return _freeze(plain)


def _digest(value: Any) -> str:
    encoded = json.dumps(_plain(value), sort_keys=True, separators=(",", ":"),
                         ensure_ascii=True, allow_nan=False).encode("ascii")
    return hashlib.sha256(encoded).hexdigest()


@dataclass(frozen=True, order=True)
class EntityId:
    slot: int
    generation: int


@dataclass(frozen=True)
class Component:
    type: str
    data: Mapping[str, Any]

    @staticmethod
    def of(type_: str, data: Mapping[str, Any]) -> "Component":
        _require(isinstance(type_, str) and bool(type_) and isinstance(data, Mapping),
                 "NEBO-G043-COMPONENT", "Component.of")
        return Component(type_, _frozen_mapping(data))


class ComponentView:
    """A view invalidated by destruction or any archetype migration."""

    def __init__(self, world: "World", entity_id: EntityId, component_type: str,
                 epoch: int) -> None:
        self._world = world
        self._entity_id = entity_id
        self._component_type = component_type
        self._epoch = epoch

    def value(self) -> Component:
        _require(self._epoch == self._world._structural_epoch,
                 "NEBO-G043-BORROW-INVALID", "entity.get<Component>")
        return self._world._get_component(self._entity_id, self._component_type)


class EntityRef:
    def __init__(self, world: "World", entity_id: EntityId) -> None:
        self._world = world
        self.id = entity_id

    def add(self, component: Component) -> "EntityRef":
        self._world._add_component(self.id, component)
        return self

    def remove(self, component_type: str) -> Component:
        return self._world._remove_component(self.id, component_type)

    def get(self, component_type: str) -> ComponentView:
        self._world._get_component(self.id, component_type)
        return ComponentView(self._world, self.id, component_type,
                             self._world._structural_epoch)


class World:
    """Generation-safe bounded archetype reference world."""

    def __init__(self, options: Mapping[str, Any]) -> None:
        operation = "World.new"
        _require(isinstance(options, Mapping) and set(options) <= {"entityBudget", "seed"},
                 "NEBO-G043-WORLD-OPTIONS", operation)
        self.entity_budget = _integer(options.get("entityBudget", MAX_ENTITIES), operation,
                                      1, MAX_ENTITIES)
        self.seed = _integer(options.get("seed", 0), operation, 0, (1 << 63)-1)
        self._generations: list[int] = []
        self._alive: set[int] = set()
        self._free: list[int] = []
        self._components: dict[int, dict[str, Component]] = {}
        self._structural_epoch = 0
        self._systems: dict[str, System] = {}
        self._schedule: Schedule | None = None

    @staticmethod
    def new(options: Mapping[str, Any]) -> "World":
        return World(options)

    def _check_id(self, entity: EntityId | EntityRef, operation: str) -> EntityId:
        entity_id = entity.id if isinstance(entity, EntityRef) else entity
        _require(isinstance(entity_id, EntityId) and
                 0 <= entity_id.slot < len(self._generations) and
                 entity_id.slot in self._alive and
                 self._generations[entity_id.slot] == entity_id.generation,
                 "NEBO-G043-ENTITY-STALE", operation)
        return entity_id

    def spawn(self) -> EntityRef:
        operation = "world.spawn"
        _require(len(self._alive) < self.entity_budget,
                 "NEBO-G043-ENTITY-BUDGET", operation)
        if self._free:
            slot = heapq.heappop(self._free)
        else:
            slot = len(self._generations)
            self._generations.append(1)
        self._alive.add(slot)
        self._components[slot] = {}
        self._structural_epoch += 1
        return EntityRef(self, EntityId(slot, self._generations[slot]))

    def destroy(self, entity: EntityId | EntityRef) -> None:
        entity_id = self._check_id(entity, "world.destroy")
        self._alive.remove(entity_id.slot)
        self._components.pop(entity_id.slot)
        self._generations[entity_id.slot] += 1
        heapq.heappush(self._free, entity_id.slot)
        self._structural_epoch += 1

    def _add_component(self, entity: EntityId, component: Component) -> None:
        entity_id = self._check_id(entity, "entity.add")
        _require(isinstance(component, Component) and component.type not in self._components[entity_id.slot],
                 "NEBO-G043-COMPONENT-DUPLICATE", "entity.add")
        self._components[entity_id.slot][component.type] = component
        self._structural_epoch += 1

    def _remove_component(self, entity: EntityId, component_type: str) -> Component:
        entity_id = self._check_id(entity, "entity.remove<Component>")
        _require(isinstance(component_type, str) and
                 component_type in self._components[entity_id.slot],
                 "NEBO-G043-COMPONENT-MISSING", "entity.remove<Component>")
        value = self._components[entity_id.slot].pop(component_type)
        self._structural_epoch += 1
        return value

    def _get_component(self, entity: EntityId, component_type: str) -> Component:
        entity_id = self._check_id(entity, "entity.get<Component>")
        _require(isinstance(component_type, str) and
                 component_type in self._components[entity_id.slot],
                 "NEBO-G043-COMPONENT-MISSING", "entity.get<Component>")
        return self._components[entity_id.slot][component_type]

    def query(self, components: Sequence[str]) -> tuple[EntityRef, ...]:
        operation = "world.query<Components>"
        _require(isinstance(components, Sequence) and not isinstance(components, (str, bytes)) and
                 len(components) > 0 and all(isinstance(item, str) and item for item in components),
                 "NEBO-G043-QUERY", operation)
        required = frozenset(components)
        return tuple(EntityRef(self, EntityId(slot, self._generations[slot]))
                     for slot in sorted(self._alive)
                     if required <= self._components[slot].keys())

    def entityCount(self) -> int:
        return len(self._alive)

    def validate(self) -> Mapping[str, Any]:
        free = set(self._free)
        valid = (self._alive == set(self._components) and
                 len(free) == len(self._free) and
                 all(0 <= slot < len(self._generations) for slot in self._alive | free) and
                 not (self._alive & free) and
                 len(self._alive)+len(free) == len(self._generations) and
                 all(component.type == name and bool(name)
                     for components in self._components.values()
                     for name, component in components.items()))
        return MappingProxyType({"archetypes": len({tuple(sorted(self._components[slot]))
                                                    for slot in self._alive}),
                                 "entities": len(self._alive), "valid": valid})

    def addSystem(self, system: "System") -> None:
        _require(isinstance(system, System) and system.name not in self._systems and
                 len(self._systems) < MAX_SYSTEMS,
                 "NEBO-G043-SYSTEM-REGISTRATION", "world.addSystem")
        self._systems[system.name] = system
        self._schedule = None

    def compileSchedule(self) -> "Schedule":
        operation = "world.compileSchedule"
        _require(bool(self._systems), "NEBO-G043-SCHEDULE-EMPTY", operation)
        names = set(self._systems)
        edges: set[tuple[str, str]] = set()
        for system in self._systems.values():
            _require(system._before <= names and system._after <= names and
                     system.name not in system._before and system.name not in system._after,
                     "NEBO-G043-SYSTEM-DEPENDENCY", operation)
            edges.update((system.name, other) for other in system._before)
            edges.update((other, system.name) for other in system._after)
        incoming = {name: 0 for name in names}
        outgoing: dict[str, set[str]] = {name: set() for name in names}
        for source, target in edges:
            if target not in outgoing[source]:
                outgoing[source].add(target)
                incoming[target] += 1
        systems = tuple(self._systems[name] for name in sorted(names))
        conflicts = {
            tuple(sorted((left.name, right.name)))
            for index, left in enumerate(systems)
            for right in systems[index+1:]
            if left.conflicts(right)
        }
        groups: list[list[System]] = []
        ordered: list[System] = []
        completed = 0
        while completed < len(names):
            level_names = sorted(name for name, count in incoming.items() if count == 0)
            _require(bool(level_names), "NEBO-G043-SCHEDULE-CYCLE", operation)
            level_groups: list[list[System]] = []
            for name in level_names:
                system = self._systems[name]
                ordered.append(system)
                placed = False
                for group in level_groups:
                    if all(not system.conflicts(other) for other in group):
                        group.append(system)
                        placed = True
                        break
                if not placed:
                    level_groups.append([system])
            groups.extend(level_groups)
            for name in level_names:
                incoming[name] = -1
                completed += 1
                for target in outgoing[name]:
                    incoming[target] -= 1
        schedule = Schedule(tuple(ordered), tuple(tuple(item.name for item in group) for group in groups),
                            tuple(sorted(conflicts)), tuple(sorted(edges)))
        self._schedule = schedule
        return schedule

    def runSystems(self, context: Mapping[str, Any]) -> tuple[str, ...]:
        _require(isinstance(context, Mapping), "NEBO-G043-SYSTEM-CONTEXT", "world.runSystems")
        schedule = self._schedule or self.compileSchedule()
        before = self._export_state()
        executed: list[str] = []
        try:
            for system in schedule.ordered:
                system_context = dict(context)
                system_context["entities"] = self.query(system.query) if system.query else ()
                system.function(self, MappingProxyType(system_context))
                executed.append(system.name)
        except Exception as error:
            self._import_state(before)
            if isinstance(error, SimulationError):
                raise
            raise SimulationError("NEBO-G043-SYSTEM-EXECUTION", "world.runSystems") from error
        return tuple(executed)

    def _export_state(self) -> Mapping[str, Any]:
        return copy.deepcopy({
            "alive": sorted(self._alive),
            "components": {str(slot): {name: _plain(component)
                                        for name, component in sorted(self._components[slot].items())}
                           for slot in sorted(self._alive)},
            "entityBudget": self.entity_budget,
            "free": sorted(self._free),
            "generations": list(self._generations),
            "seed": self.seed,
            "systems": {
                name: {"after": sorted(system._after), "before": sorted(system._before),
                       "query": list(system.query), "reads": sorted(system._reads),
                       "writes": sorted(system._writes)}
                for name, system in sorted(self._systems.items())
            },
        })

    def _import_state(self, state: Mapping[str, Any]) -> None:
        self._generations = [int(value) for value in state["generations"]]
        self._alive = {int(value) for value in state["alive"]}
        self._free = [int(value) for value in state["free"]]
        heapq.heapify(self._free)
        self._components = {}
        for slot_text, components in state["components"].items():
            self._components[int(slot_text)] = {
                name: Component.of(value["type"], value["data"])
                for name, value in components.items()
            }
        self._structural_epoch += 1


@dataclass(frozen=True)
class System:
    name: str
    query: tuple[str, ...]
    function: Callable[[World, Mapping[str, Any]], None] = field(compare=False, repr=False)
    _reads: frozenset[str] = frozenset()
    _writes: frozenset[str] = frozenset()
    _before: frozenset[str] = frozenset()
    _after: frozenset[str] = frozenset()

    @staticmethod
    def define(name: str, query: Sequence[str], function: Callable[[World, Mapping[str, Any]], None]) -> "System":
        operation = "System.define"
        _require(isinstance(name, str) and bool(name) and isinstance(query, Sequence) and
                 not isinstance(query, (str, bytes)) and callable(function),
                 "NEBO-G043-SYSTEM", operation)
        values = tuple(query)
        _require(all(isinstance(item, str) and item for item in values),
                 "NEBO-G043-SYSTEM", operation)
        return System(name, values, function)

    def reads(self, components: Iterable[str]) -> "System":
        _require(not isinstance(components, (str, bytes)),
                 "NEBO-G043-SYSTEM-ACCESS", "system.reads")
        try:
            values = frozenset(components)
        except TypeError as error:
            raise SimulationError("NEBO-G043-SYSTEM-ACCESS", "system.reads") from error
        _require(all(isinstance(item, str) and item for item in values),
                 "NEBO-G043-SYSTEM-ACCESS", "system.reads")
        return replace(self, _reads=self._reads | values)

    def writes(self, components: Iterable[str]) -> "System":
        _require(not isinstance(components, (str, bytes)),
                 "NEBO-G043-SYSTEM-ACCESS", "system.writes")
        try:
            values = frozenset(components)
        except TypeError as error:
            raise SimulationError("NEBO-G043-SYSTEM-ACCESS", "system.writes") from error
        _require(all(isinstance(item, str) and item for item in values),
                 "NEBO-G043-SYSTEM-ACCESS", "system.writes")
        return replace(self, _writes=self._writes | values)

    def before(self, other: "System | str") -> "System":
        name = other.name if isinstance(other, System) else other
        _require(isinstance(name, str) and bool(name),
                 "NEBO-G043-SYSTEM-DEPENDENCY", "system.before")
        return replace(self, _before=self._before | {name})

    def after(self, other: "System | str") -> "System":
        name = other.name if isinstance(other, System) else other
        _require(isinstance(name, str) and bool(name),
                 "NEBO-G043-SYSTEM-DEPENDENCY", "system.after")
        return replace(self, _after=self._after | {name})

    def conflicts(self, other: "System") -> bool:
        return bool((self._writes & (other._reads | other._writes)) or
                    (other._writes & (self._reads | self._writes)))


@dataclass(frozen=True)
class Schedule:
    ordered: tuple[System, ...]
    parallelGroups: tuple[tuple[str, ...], ...]
    conflicts: tuple[tuple[str, str], ...]
    dependencies: tuple[tuple[str, str], ...]

    def explain(self) -> Mapping[str, Any]:
        return MappingProxyType({"barriers": max(0, len(self.parallelGroups)-1),
                                 "conflicts": self.conflicts,
                                 "dependencies": self.dependencies,
                                 "ordering": tuple(system.name for system in self.ordered),
                                 "parallelGroups": self.parallelGroups,
                                 "threads": 1})


@dataclass(frozen=True)
class Shape:
    kind: str
    radius: float = 0.0
    halfExtents: tuple[float, float, float] = (0.0, 0.0, 0.0)

    @staticmethod
    def sphere(radius: Any) -> "Shape":
        value = _number(radius, "Shape.sphere")
        _require(value > 0, "NEBO-G043-SHAPE", "Shape.sphere")
        return Shape("sphere", value)

    @staticmethod
    def box(half_extents: Sequence[Any]) -> "Shape":
        values = _vector3(half_extents, "Shape.box")
        _require(all(value > 0 for value in values), "NEBO-G043-SHAPE", "Shape.box")
        return Shape("box", 0.0, values)


class RigidBody:
    def __init__(self, owner: "PhysicsWorld", identity: int, shape: Shape,
                 mass: float, pose: Sequence[Any]) -> None:
        self._owner = owner
        self.id = identity
        self.shape = shape
        self.mass = mass
        self.pose = _vector3(pose, "physics.body")
        self.linearVelocity = (0.0, 0.0, 0.0)
        self.angularVelocity = (0.0, 0.0, 0.0)

    def setVelocity(self, linear: Sequence[Any], angular: Sequence[Any]) -> None:
        self._owner._require_body(self, "body.setVelocity")
        self.linearVelocity = _vector3(linear, "body.setVelocity")
        self.angularVelocity = _vector3(angular, "body.setVelocity")


class PhysicsWorld:
    def __init__(self, options: Mapping[str, Any]) -> None:
        operation = "PhysicsWorld.new"
        _require(isinstance(options, Mapping) and set(options) <= {
            "gravity", "integrator", "maxBodies", "maxContacts", "solverTolerance", "units"
        }, "NEBO-G043-PHYSICS-OPTIONS", operation)
        self.gravity = _vector3(options.get("gravity", (0, -9.81, 0)), operation)
        self.integrator = options.get("integrator", "semi-implicit-euler-v1")
        _require(self.integrator == "semi-implicit-euler-v1",
                 "NEBO-G043-INTEGRATOR", operation)
        self.max_bodies = _integer(options.get("maxBodies", MAX_BODIES), operation, 1, MAX_BODIES)
        self.max_contacts = _integer(options.get("maxContacts", MAX_CONTACTS), operation, 1, MAX_CONTACTS)
        self.tolerance = _number(options.get("solverTolerance", 1e-6), operation)
        _require(self.tolerance > 0, "NEBO-G043-SOLVER", operation)
        self.units = options.get("units", "metre-second-kilogram-v1")
        _require(self.units == "metre-second-kilogram-v1", "NEBO-G043-PHYSICS-UNITS", operation)
        self._bodies: dict[int, RigidBody] = {}
        self._constraints: list[Mapping[str, Any]] = []
        self._contacts: tuple[Mapping[str, Any], ...] = ()
        self._next_body = 1
        self._steps = 0
        self._last_dt = 0.0
        self._baseline_energy: float | None = None
        self._residual = 0.0

    @staticmethod
    def new(options: Mapping[str, Any]) -> "PhysicsWorld":
        return PhysicsWorld(options)

    def body(self, shape: Shape, mass: Any, pose: Sequence[Any]) -> RigidBody:
        operation = "physics.body"
        value = _number(mass, operation)
        valid_shape = isinstance(shape, Shape) and (
            (shape.kind == "sphere" and shape.radius > 0) or
            (shape.kind == "box" and all(value > 0 for value in shape.halfExtents))
        )
        _require(valid_shape and value >= 0 and len(self._bodies) < self.max_bodies,
                 "NEBO-G043-BODY", operation)
        body = RigidBody(self, self._next_body, shape, value, pose)
        self._bodies[body.id] = body
        self._next_body += 1
        return body

    def _require_body(self, body: RigidBody, operation: str) -> None:
        _require(isinstance(body, RigidBody) and self._bodies.get(body.id) is body,
                 "NEBO-G043-BODY-HANDLE", operation)

    def constraint(self, a: RigidBody, b: RigidBody, rule: Mapping[str, Any]) -> int:
        operation = "physics.constraint"
        self._require_body(a, operation)
        self._require_body(b, operation)
        _require(a is not b and isinstance(rule, Mapping) and rule.get("type") == "distance" and
                 len(self._constraints) < MAX_CONSTRAINTS,
                 "NEBO-G043-CONSTRAINT", operation)
        rest = _number(rule.get("restLength"), operation)
        _require(rest > 0, "NEBO-G043-CONSTRAINT", operation)
        self._constraints.append(MappingProxyType({"a": a.id, "b": b.id,
                                                   "restLength": rest, "type": "distance"}))
        return len(self._constraints)

    @staticmethod
    def _sphere_overlap(left: RigidBody, right: RigidBody) -> tuple[bool, float]:
        if left.shape.kind != "sphere" or right.shape.kind != "sphere":
            return False, 0.0
        distance = math.sqrt(sum((a-b)**2 for a, b in zip(left.pose, right.pose)))
        penetration = left.shape.radius + right.shape.radius - distance
        return penetration >= 0, max(0.0, penetration)

    def step(self, dt: Any) -> None:
        operation = "physics.step"
        duration = _number(dt, operation)
        _require(0 < duration <= 1, "NEBO-G043-TIMESTEP", operation)
        before_bodies = {
            identity: (body.pose, body.linearVelocity, body.angularVelocity)
            for identity, body in self._bodies.items()
        }
        before_metadata = (self._baseline_energy, self._contacts, self._last_dt,
                           self._residual, self._steps)
        try:
            if self._baseline_energy is None:
                self._baseline_energy = self._energy()
            for body in self._bodies.values():
                if body.mass == 0:
                    continue
                body.linearVelocity = tuple(body.linearVelocity[index] + self.gravity[index]*duration
                                            for index in range(3))
                body.pose = tuple(body.pose[index] + body.linearVelocity[index]*duration
                                  for index in range(3))
            contacts: list[Mapping[str, Any]] = []
            values = [self._bodies[key] for key in sorted(self._bodies)]
            for index, left in enumerate(values):
                for right in values[index+1:]:
                    overlap, penetration = self._sphere_overlap(left, right)
                    if overlap:
                        contacts.append(MappingProxyType({"a": left.id, "b": right.id,
                                                          "penetration": penetration}))
            _require(len(contacts) <= self.max_contacts,
                     "NEBO-G043-CONTACT-BUDGET", operation)
            residual = 0.0
            for constraint in self._constraints:
                a = self._bodies[constraint["a"]]
                b = self._bodies[constraint["b"]]
                distance = math.sqrt(sum((left-right)**2 for left, right in zip(a.pose, b.pose)))
                residual = max(residual, abs(distance-constraint["restLength"]))
            self._contacts = tuple(contacts)
            self._residual = residual
            self._steps += 1
            self._last_dt = duration
        except Exception:
            for identity, (pose, linear, angular) in before_bodies.items():
                body = self._bodies[identity]
                body.pose = pose
                body.linearVelocity = linear
                body.angularVelocity = angular
            (self._baseline_energy, self._contacts, self._last_dt,
             self._residual, self._steps) = before_metadata
            raise

    def contacts(self) -> tuple[Mapping[str, Any], ...]:
        return self._contacts

    def raycast(self, ray: Mapping[str, Any], limit: int) -> tuple[Mapping[str, Any], ...]:
        operation = "physics.raycast"
        _require(isinstance(ray, Mapping), "NEBO-G043-RAY", operation)
        origin = _vector3(ray.get("origin"), operation)
        direction = _vector3(ray.get("direction"), operation)
        length = math.sqrt(sum(value*value for value in direction))
        _require(length > 0, "NEBO-G043-RAY", operation)
        direction = tuple(value/length for value in direction)
        maximum = _integer(limit, operation, 1, 256)
        hits: list[tuple[float, int]] = []
        for body in self._bodies.values():
            if body.shape.kind != "sphere":
                continue
            offset = tuple(origin[index]-body.pose[index] for index in range(3))
            projection = sum(offset[index]*direction[index] for index in range(3))
            constant = sum(value*value for value in offset)-body.shape.radius**2
            discriminant = projection*projection-constant
            if discriminant >= 0:
                root = math.sqrt(discriminant)
                near = -projection-root
                distance = near if near >= 0 else -projection+root
                if distance >= 0:
                    hits.append((distance, body.id))
        return tuple(MappingProxyType({"body": identity, "distance": distance})
                     for distance, identity in sorted(hits)[:maximum])

    def overlap(self, shape: Shape, pose: Sequence[Any], limit: int) -> tuple[int, ...]:
        operation = "physics.overlap"
        _require(isinstance(shape, Shape) and shape.kind == "sphere",
                 "NEBO-G043-SHAPE", operation)
        centre = _vector3(pose, operation)
        maximum = _integer(limit, operation, 1, 256)
        matches = []
        for body in self._bodies.values():
            if body.shape.kind == "sphere":
                distance = math.sqrt(sum((left-right)**2 for left, right in zip(centre, body.pose)))
                if distance <= shape.radius+body.shape.radius:
                    matches.append(body.id)
        return tuple(sorted(matches)[:maximum])

    def _energy(self) -> float:
        return sum(0.5*body.mass*sum(value*value for value in body.linearVelocity)
                   - body.mass*sum(self.gravity[index]*body.pose[index] for index in range(3))
                   for body in self._bodies.values() if body.mass > 0)

    def energyReport(self) -> Mapping[str, Any]:
        energy = self._energy()
        baseline = energy if self._baseline_energy is None else self._baseline_energy
        return MappingProxyType({"drift": energy-baseline, "energy": energy,
                                 "collisionModel": "sphere-overlap-v1",
                                 "integrator": self.integrator, "residual": self._residual,
                                 "solverTolerance": self.tolerance, "steps": self._steps,
                                 "timestep": self._last_dt, "units": self.units})

    def _export_state(self) -> Mapping[str, Any]:
        return copy.deepcopy({"baseline": self._baseline_energy, "contacts": [_plain(item) for item in self._contacts],
                              "config": {"gravity": self.gravity, "integrator": self.integrator,
                                         "maxBodies": self.max_bodies, "maxContacts": self.max_contacts,
                                         "solverTolerance": self.tolerance, "units": self.units},
                              "constraints": [_plain(item) for item in self._constraints],
                              "lastDt": self._last_dt, "nextBody": self._next_body,
                              "residual": self._residual, "steps": self._steps,
                              "bodies": {str(identity): {"angular": body.angularVelocity,
                                                         "linear": body.linearVelocity,
                                                         "mass": body.mass, "pose": body.pose,
                                                         "shape": _plain(body.shape.__dict__)}
                                         for identity, body in sorted(self._bodies.items())}})

    def _import_state(self, state: Mapping[str, Any]) -> None:
        config = state["config"]
        _require(config == {"gravity": self.gravity, "integrator": self.integrator,
                            "maxBodies": self.max_bodies, "maxContacts": self.max_contacts,
                            "solverTolerance": self.tolerance, "units": self.units},
                 "NEBO-G043-SNAPSHOT-RESOURCE", "simulation.restore")
        previous = self._bodies
        restored: dict[int, RigidBody] = {}
        for identity_text, value in state["bodies"].items():
            identity = int(identity_text)
            shape_data = value["shape"]
            shape = Shape(shape_data["kind"], shape_data["radius"], tuple(shape_data["halfExtents"]))
            body = previous.get(identity)
            if body is None:
                body = RigidBody(self, identity, shape, value["mass"], value["pose"])
            else:
                body.shape = shape
                body.mass = value["mass"]
                body.pose = tuple(value["pose"])
            body.linearVelocity = tuple(value["linear"])
            body.angularVelocity = tuple(value["angular"])
            restored[body.id] = body
        self._bodies = restored
        self._baseline_energy = state["baseline"]
        self._contacts = tuple(MappingProxyType(dict(item)) for item in state["contacts"])
        self._constraints = [MappingProxyType(dict(item)) for item in state["constraints"]]
        self._last_dt = state["lastDt"]
        self._next_body = state["nextBody"]
        self._residual = state["residual"]
        self._steps = state["steps"]


@dataclass(frozen=True)
class Snapshot:
    schemaVersion: int
    profile: str
    tick: int
    fixedStep: float
    accumulator: float
    deterministic: bool
    seed: int
    resourcePolicy: str
    worldState: Mapping[str, Any]
    simulationState: Mapping[str, Any]
    physicsState: Mapping[str, Any] | None
    stateHash: str


class RollbackController:
    def __init__(self, simulation: "Simulation") -> None:
        self._simulation = simulation

    def setWindow(self, ticks: int) -> None:
        value = _integer(ticks, "rollback.setWindow", 1, MAX_ROLLBACK_TICKS)
        self._simulation._rollback_window = value
        self._simulation._trim_history()

    def confirm(self, tick: int) -> None:
        value = _integer(tick, "rollback.confirm", 0)
        _require(value <= self._simulation._tick,
                 "NEBO-G043-ROLLBACK-TICK", "rollback.confirm")
        for item in tuple(self._simulation._snapshots):
            if item < value:
                del self._simulation._snapshots[item]
        for item in tuple(self._simulation._inputs):
            if item < value:
                del self._simulation._inputs[item]


class Simulation:
    def __init__(self, world: World, options: Mapping[str, Any]) -> None:
        operation = "Simulation.new"
        _require(isinstance(world, World) and isinstance(options, Mapping) and set(options) <= {
            "deterministic", "initialState", "maxAdvanceTicks", "physics", "resourcePolicy",
            "seed", "update"
        }, "NEBO-G043-SIMULATION-OPTIONS", operation)
        self.world = world
        self.physics = options.get("physics")
        _require(self.physics is None or isinstance(self.physics, PhysicsWorld),
                 "NEBO-G043-PHYSICS", operation)
        initial_state = options.get("initialState", {"counter": 0})
        _require(isinstance(initial_state, Mapping), "NEBO-G043-SIMULATION-OPTIONS", operation)
        plain_state = _plain(initial_state)
        self._state: dict[str, Any] = copy.deepcopy(plain_state)
        self._update = options.get("update")
        _require(self._update is None or callable(self._update), "NEBO-G043-UPDATE", operation)
        self._max_advance_ticks = _integer(options.get("maxAdvanceTicks", MAX_ADVANCE_TICKS),
                                           operation, 1, MAX_ADVANCE_TICKS)
        self._seed = _integer(options.get("seed", world.seed), operation, 0, (1 << 63)-1)
        self._resource_policy = options.get("resourcePolicy", "local-references-v1")
        _require(self._resource_policy == "local-references-v1",
                 "NEBO-G043-RESOURCE-POLICY", operation)
        deterministic = options.get("deterministic", True)
        _require(isinstance(deterministic, bool), "NEBO-G043-DETERMINISM", operation)
        self._deterministic = deterministic
        self._fixed_step: float | None = None
        self._accumulator = 0.0
        self._tick = 0
        self._inputs: dict[int, Any] = {}
        self._snapshots: dict[int, Snapshot] = {}
        self._timeline: list[Mapping[str, Any]] = []
        self._rollback_window = 32
        self.rollback = RollbackController(self)
        self._initial: Snapshot | None = None

    @staticmethod
    def new(world: World, options: Mapping[str, Any]) -> "Simulation":
        return Simulation(world, options)

    def fixedStep(self, duration: Any) -> None:
        value = _number(duration, "simulation.fixedStep")
        _require(0 < value <= 1 and self._tick == 0,
                 "NEBO-G043-FIXED-STEP", "simulation.fixedStep")
        self._fixed_step = value
        self._initial = self.snapshot()
        self._snapshots[0] = self._initial

    def deterministicMode(self, enabled: bool) -> None:
        _require(isinstance(enabled, bool) and self._tick == 0,
                 "NEBO-G043-DETERMINISM", "simulation.deterministicMode")
        self._deterministic = enabled
        if self._fixed_step is not None:
            self._initial = self.snapshot()
            self._snapshots[0] = self._initial

    def _apply_input(self, input_: Any) -> None:
        if self._update is not None:
            try:
                updated = self._update(copy.deepcopy(self._state), copy.deepcopy(_plain(input_)), self._tick)
            except SimulationError:
                raise
            except Exception as error:
                raise SimulationError("NEBO-G043-UPDATE", "simulation.tick") from error
            _require(isinstance(updated, Mapping), "NEBO-G043-UPDATE", "simulation.tick")
            self._state = copy.deepcopy(dict(updated))
        else:
            _require(isinstance(input_, Mapping) and set(input_) <= {"delta"},
                     "NEBO-G043-INPUT", "simulation.tick")
            delta = _integer(input_.get("delta", 0), "simulation.tick", -(1 << 31), (1 << 31)-1)
            counter = _integer(self._state.get("counter", 0), "simulation.tick", -(1 << 63), (1 << 63)-1)
            self._state["counter"] = _integer(counter+delta, "simulation.tick",
                                               -(1 << 63), (1 << 63)-1)

    def tick(self, input_: Any) -> str:
        _require(self._fixed_step is not None, "NEBO-G043-FIXED-STEP", "simulation.tick")
        canonical_input = _plain(input_)
        prior = self._inputs.get(self._tick)
        _require(prior is None or prior == canonical_input,
                 "NEBO-G043-INPUT-CONFLICT", "simulation.tick")
        if self._tick == 0 and not self._timeline:
            self._initial = self.snapshot()
            self._snapshots[0] = self._initial
        before = self.snapshot()
        before_inputs = dict(self._inputs)
        before_snapshots = dict(self._snapshots)
        before_timeline = list(self._timeline)
        try:
            self._inputs[self._tick] = copy.deepcopy(canonical_input)
            self._apply_input(canonical_input)
            if self.world._systems:
                self.world.runSystems(MappingProxyType({"input": canonical_input,
                                                        "state": self._state,
                                                        "tick": self._tick}))
            if self.physics is not None:
                self.physics.step(self._fixed_step)
            self._tick += 1
            state_hash = _digest(self._state_payload())
            self._timeline.append(MappingProxyType({"stateHash": state_hash, "tick": self._tick}))
            if len(self._timeline) > MAX_TRACE_TICKS:
                self._timeline = self._timeline[-MAX_TRACE_TICKS:]
            self._snapshots[self._tick] = self.snapshot()
            self._trim_history()
            return state_hash
        except Exception:
            self.restore(before)
            self._inputs = before_inputs
            self._snapshots = before_snapshots
            self._timeline = before_timeline
            raise

    def advance(self, realDuration: Any) -> int:
        _require(self._fixed_step is not None, "NEBO-G043-FIXED-STEP", "simulation.advance")
        duration = _number(realDuration, "simulation.advance")
        _require(duration >= 0, "NEBO-G043-DURATION", "simulation.advance")
        candidate = self._accumulator+duration
        ticks = int((candidate+1e-15)//self._fixed_step)
        _require(ticks <= self._max_advance_ticks,
                 "NEBO-G043-ADVANCE-BUDGET", "simulation.advance")
        before = self.snapshot()
        before_inputs = dict(self._inputs)
        before_snapshots = dict(self._snapshots)
        before_timeline = list(self._timeline)
        try:
            self._accumulator = candidate-ticks*self._fixed_step
            for _ in range(ticks):
                input_ = self._inputs.get(self._tick, {"delta": 0})
                self.tick(input_)
        except Exception:
            self.restore(before)
            self._inputs = before_inputs
            self._snapshots = before_snapshots
            self._timeline = before_timeline
            raise
        return ticks

    def tickNumber(self) -> int:
        return self._tick

    def _state_payload(self) -> Mapping[str, Any]:
        return {"accumulator": self._accumulator, "deterministic": self._deterministic,
                "fixedStep": self._fixed_step,
                "physics": None if self.physics is None else self.physics._export_state(),
                "resourcePolicy": self._resource_policy, "seed": self._seed,
                "simulation": self._state,
                "tick": self._tick, "world": self.world._export_state()}

    def stateHash(self) -> str:
        _require(self._deterministic, "NEBO-G043-NONDETERMINISTIC-HASH", "simulation.stateHash")
        return _digest(self._state_payload())

    def divergenceReport(self, reference: "Simulation | Sequence[str]") -> Mapping[str, Any]:
        if isinstance(reference, Simulation):
            expected = tuple(item["stateHash"] for item in reference._timeline)
        else:
            _require(isinstance(reference, Sequence) and not isinstance(reference, (str, bytes)),
                     "NEBO-G043-DIVERGENCE-REFERENCE", "simulation.divergenceReport")
            expected = tuple(reference)
        observed = tuple(item["stateHash"] for item in self._timeline)
        first = next((index+1 for index, pair in enumerate(zip(observed, expected))
                      if pair[0] != pair[1]), None)
        if first is None and len(observed) != len(expected):
            first = min(len(observed), len(expected))+1
        return MappingProxyType({"component": "canonical-state" if first is not None else None,
                                 "entity": None, "firstTick": first,
                                 "matches": first is None})

    def snapshot(self) -> Snapshot:
        _require(self._fixed_step is not None, "NEBO-G043-FIXED-STEP", "simulation.snapshot")
        world_state = self.world._export_state()
        physics_state = None if self.physics is None else self.physics._export_state()
        state = copy.deepcopy(self._state)
        payload = {"accumulator": self._accumulator, "deterministic": self._deterministic,
                   "fixedStep": self._fixed_step,
                   "physics": physics_state,
                   "profile": "DETERMINISTIC_SIMULATION_V1", "simulation": state,
                   "resourcePolicy": self._resource_policy, "seed": self._seed,
                   "schemaVersion": 1, "tick": self._tick, "world": world_state}
        return Snapshot(1, "DETERMINISTIC_SIMULATION_V1", self._tick, self._fixed_step,
                        self._accumulator, self._deterministic, self._seed, self._resource_policy,
                        world_state, state, physics_state, _digest(payload))

    @staticmethod
    def _snapshot_hash(snapshot: Snapshot) -> str:
        return _digest({"accumulator": snapshot.accumulator,
                        "deterministic": snapshot.deterministic, "fixedStep": snapshot.fixedStep,
                        "physics": snapshot.physicsState,
                        "profile": snapshot.profile, "simulation": snapshot.simulationState,
                        "resourcePolicy": snapshot.resourcePolicy, "seed": snapshot.seed,
                        "schemaVersion": snapshot.schemaVersion,
                        "tick": snapshot.tick, "world": snapshot.worldState})

    def restore(self, snapshot: Snapshot) -> None:
        operation = "simulation.restore"
        _require(isinstance(snapshot, Snapshot) and snapshot.schemaVersion == 1 and
                 snapshot.profile == "DETERMINISTIC_SIMULATION_V1" and
                 self._snapshot_hash(snapshot) == snapshot.stateHash,
                 "NEBO-G043-SNAPSHOT-INCOMPATIBLE", operation)
        _require(self._fixed_step is None or snapshot.fixedStep == self._fixed_step,
                 "NEBO-G043-SNAPSHOT-INCOMPATIBLE", operation)
        _require(snapshot.deterministic == self._deterministic and snapshot.seed == self._seed and
                 snapshot.resourcePolicy == self._resource_policy,
                 "NEBO-G043-SNAPSHOT-INCOMPATIBLE", operation)
        _require((snapshot.physicsState is None) == (self.physics is None),
                 "NEBO-G043-SNAPSHOT-RESOURCE", operation)
        _require(snapshot.worldState.get("entityBudget") == self.world.entity_budget and
                 snapshot.worldState.get("seed") == self.world.seed and
                 snapshot.worldState.get("systems") == self.world._export_state().get("systems"),
                 "NEBO-G043-SNAPSHOT-RESOURCE", operation)
        if snapshot.physicsState is not None:
            _require(snapshot.physicsState.get("config") == {
                "gravity": self.physics.gravity, "integrator": self.physics.integrator,
                "maxBodies": self.physics.max_bodies, "maxContacts": self.physics.max_contacts,
                "solverTolerance": self.physics.tolerance, "units": self.physics.units,
            }, "NEBO-G043-SNAPSHOT-RESOURCE", operation)
        self._fixed_step = snapshot.fixedStep
        self._accumulator = snapshot.accumulator
        self.world._import_state(snapshot.worldState)
        if snapshot.physicsState is not None:
            _require(self.physics is not None, "NEBO-G043-SNAPSHOT-RESOURCE", operation)
            self.physics._import_state(snapshot.physicsState)
        self._state = copy.deepcopy(dict(snapshot.simulationState))
        self._tick = snapshot.tick
        self._timeline = [item for item in self._timeline if item["tick"] <= self._tick]

    def rollbackTo(self, tick: int) -> Mapping[str, Any]:
        value = _integer(tick, "simulation.rollbackTo", 0)
        _require(value <= self._tick and value in self._snapshots,
                 "NEBO-G043-ROLLBACK-TICK", "simulation.rollbackTo")
        present = self._tick
        before = self.snapshot()
        before_inputs = dict(self._inputs)
        before_snapshots = dict(self._snapshots)
        before_timeline = list(self._timeline)
        try:
            self.restore(self._snapshots[value])
            replayed = 0
            while self._tick < present:
                _require(self._tick in before_inputs,
                         "NEBO-G043-REPLAY-INPUT", "simulation.rollbackTo")
                self.tick(before_inputs[self._tick])
                replayed += 1
        except Exception:
            self.restore(before)
            self._inputs = before_inputs
            self._snapshots = before_snapshots
            self._timeline = before_timeline
            raise
        return MappingProxyType({"replayedInputs": replayed, "restoredTick": value})

    def recordInput(self, tick: int, input_: Any) -> None:
        value = _integer(tick, "simulation.recordInput", 0)
        _require(value <= self._tick+MAX_ROLLBACK_TICKS,
                 "NEBO-G043-INPUT-WINDOW", "simulation.recordInput")
        canonical = _plain(input_)
        prior = self._inputs.get(value)
        _require(prior is None or prior == canonical,
                 "NEBO-G043-INPUT-CONFLICT", "simulation.recordInput")
        self._inputs[value] = copy.deepcopy(canonical)

    def replay(self, log: Sequence[Any]) -> str:
        _require(self._initial is not None and isinstance(log, Sequence) and
                 not isinstance(log, (str, bytes)) and len(log) <= MAX_ROLLBACK_TICKS,
                 "NEBO-G043-REPLAY-LOG", "simulation.replay")
        before = self.snapshot()
        before_inputs = dict(self._inputs)
        before_snapshots = dict(self._snapshots)
        before_timeline = list(self._timeline)
        try:
            self.restore(self._initial)
            self._timeline = []
            self._inputs = {}
            self._snapshots = {0: self._initial}
            for tick, input_ in enumerate(log):
                self.recordInput(tick, input_)
                self.tick(input_)
            return self.stateHash()
        except Exception:
            self.restore(before)
            self._inputs = before_inputs
            self._snapshots = before_snapshots
            self._timeline = before_timeline
            raise

    @staticmethod
    def diff(a: Snapshot, b: Snapshot) -> Mapping[str, Any]:
        _require(isinstance(a, Snapshot) and isinstance(b, Snapshot),
                 "NEBO-G043-SNAPSHOT", "simulation.diff")
        _require(Simulation._snapshot_hash(a) == a.stateHash and
                 Simulation._snapshot_hash(b) == b.stateHash,
                 "NEBO-G043-SNAPSHOT-INCOMPATIBLE", "simulation.diff")
        fields = ("schemaVersion", "profile", "tick", "fixedStep", "accumulator", "deterministic", "seed",
                  "resourcePolicy", "worldState", "simulationState", "physicsState")
        changed = tuple(field for field in fields if _plain(getattr(a, field)) != _plain(getattr(b, field)))
        return MappingProxyType({"changed": changed, "equal": not changed,
                                 "leftHash": a.stateHash, "rightHash": b.stateHash})

    def _trim_history(self) -> None:
        minimum = max(0, self._tick-self._rollback_window)
        for tick in tuple(self._snapshots):
            if tick < minimum:
                del self._snapshots[tick]
        for tick in tuple(self._inputs):
            if tick < minimum:
                del self._inputs[tick]

    def profile(self) -> Mapping[str, Any]:
        return MappingProxyType({"allocations": self.world.entityCount()+
                                                (0 if self.physics is None else len(self.physics._bodies)),
                                 "physicsSteps": 0 if self.physics is None else self.physics._steps,
                                 "snapshots": len(self._snapshots),
                                 "systems": len(self.world._systems), "ticks": self._tick})

    def trace(self, ticks: int) -> tuple[Mapping[str, Any], ...]:
        count = _integer(ticks, "simulation.trace", 1, MAX_TRACE_TICKS)
        return tuple(self._timeline[-count:])


@dataclass(frozen=True)
class SceneTemplate:
    version: int
    entities: tuple[tuple[Component, ...], ...]
    sourceHash: str

    @staticmethod
    def fromWorld(world: World, selection: Sequence[EntityRef]) -> "SceneTemplate":
        operation = "SceneTemplate.fromWorld"
        _require(isinstance(world, World) and isinstance(selection, Sequence) and
                 not isinstance(selection, (str, bytes)) and len(selection) > 0,
                 "NEBO-G043-SCENE-SELECTION", operation)
        entities = []
        for entity in selection:
            entity_id = world._check_id(entity, operation)
            entities.append(tuple(Component.of(world._components[entity_id.slot][name].type,
                                                 world._components[entity_id.slot][name].data)
                                  for name in sorted(world._components[entity_id.slot])))
        result = tuple(entities)
        return SceneTemplate(1, result, _digest(result))


def _region(value: Sequence[Any], operation: str) -> tuple[float, float, float, float]:
    _require(isinstance(value, Sequence) and not isinstance(value, (str, bytes)) and len(value) == 4,
             "NEBO-G043-REGION", operation)
    result = tuple(_number(item, operation) for item in value)
    _require(result[0] <= result[2] and result[1] <= result[3],
             "NEBO-G043-REGION", operation)
    return result  # type: ignore[return-value]


def _intersects(left: Sequence[float], right: Sequence[float]) -> bool:
    return not (left[2] < right[0] or right[2] < left[0] or
                left[3] < right[1] or right[3] < left[1])


class Scene:
    def __init__(self, name: str) -> None:
        _require(isinstance(name, str) and bool(name), "NEBO-G043-SCENE", "Scene.new")
        self.name = name
        self.world = World.new({"entityBudget": MAX_ENTITIES})
        self._resources: dict[str, Mapping[str, Any]] = {}
        self._loaded: set[str] = set()

    @staticmethod
    def new(name: str) -> "Scene":
        return Scene(name)

    def instantiate(self, template: SceneTemplate, transform: Mapping[str, Any]) -> tuple[EntityRef, ...]:
        operation = "scene.instantiate"
        _require(isinstance(template, SceneTemplate) and template.version == 1 and
                 template.sourceHash == _digest(template.entities) and
                 isinstance(transform, Mapping) and set(transform) <= {"translation"},
                 "NEBO-G043-SCENE-TEMPLATE", operation)
        translation = _vector3(transform.get("translation", (0, 0, 0)), operation)
        before = self.world._export_state()
        created = []
        try:
            for components in template.entities:
                entity = self.world.spawn()
                for component in components:
                    value = component
                    if component.type == "Position" and {"x", "y", "z"} <= component.data.keys():
                        data = dict(component.data)
                        data.update({axis: _number(data[axis], operation)+translation[index]
                                     for index, axis in enumerate(("x", "y", "z"))})
                        value = Component.of("Position", data)
                    entity.add(value)
                created.append(entity)
        except Exception:
            self.world._import_state(before)
            raise
        return tuple(created)

    def load(self, resource: Mapping[str, Any], capability: Mapping[str, Any]) -> str:
        operation = "scene.load"
        _require(isinstance(resource, Mapping) and isinstance(capability, Mapping) and
                 capability.get("kind") == "local-read" and capability.get("allowed") is True,
                 "NEBO-G043-RESOURCE-CAPABILITY", operation)
        identity = resource.get("id")
        version = resource.get("version")
        size = _integer(resource.get("bytes"), operation, 0, MAX_RESOURCE_BYTES)
        bounds = _region(resource.get("bounds"), operation)
        _require(isinstance(identity, str) and bool(identity) and isinstance(version, str) and
                 bool(version) and identity not in self._resources and
                 len(self._resources) < MAX_RESOURCES,
                 "NEBO-G043-RESOURCE", operation)
        self._resources[identity] = MappingProxyType({"bounds": bounds, "bytes": size,
                                                      "id": identity, "version": version})
        return identity

    def stream(self, region: Sequence[Any], budget: int) -> tuple[str, ...]:
        operation = "scene.stream"
        area = _region(region, operation)
        remaining = _integer(budget, operation, 0, MAX_RESOURCE_BYTES)
        selected = []
        for identity, resource in sorted(self._resources.items()):
            if identity not in self._loaded and _intersects(area, resource["bounds"]) and resource["bytes"] <= remaining:
                self._loaded.add(identity)
                selected.append(identity)
                remaining -= resource["bytes"]
        return tuple(selected)

    def unload(self, region: Sequence[Any]) -> tuple[str, ...]:
        area = _region(region, "scene.unload")
        removed = tuple(identity for identity in sorted(self._loaded)
                        if _intersects(area, self._resources[identity]["bounds"]))
        self._loaded.difference_update(removed)
        return removed

    def dependencies(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(MappingProxyType({"id": identity, "version": resource["version"]})
                     for identity, resource in sorted(self._resources.items()))

    def memoryReport(self) -> Mapping[str, Any]:
        component_storage: dict[str, int] = {}
        for components in self.world._components.values():
            for name in components:
                component_storage[name] = component_storage.get(name, 0)+1
        return _frozen_mapping({"componentStorage": component_storage,
                                "entityStorage": self.world.entityCount(),
                                "loadedBytes": sum(self._resources[item]["bytes"] for item in self._loaded),
                                "loadedResources": len(self._loaded),
                                "resourceBudget": MAX_RESOURCE_BYTES,
                                "resourceStorage": {
                                    identity: {"bytes": resource["bytes"],
                                               "loaded": identity in self._loaded}
                                    for identity, resource in sorted(self._resources.items())}})


@dataclass(frozen=True)
class Field:
    function: Callable[[tuple[float, float, float]], Sequence[Any]] = field(compare=False, repr=False)
    bounds: tuple[float, float, float, float, float, float]

    @staticmethod
    def vector(function: Callable[[tuple[float, float, float]], Sequence[Any]],
               bounds: Sequence[Any]) -> "Field":
        operation = "Field.vector"
        _require(callable(function) and isinstance(bounds, Sequence) and
                 not isinstance(bounds, (str, bytes)) and len(bounds) == 6,
                 "NEBO-G043-FIELD", operation)
        values = tuple(_number(item, operation) for item in bounds)
        _require(all(values[index] <= values[index+3] for index in range(3)),
                 "NEBO-G043-FIELD", operation)
        return Field(function, values)  # type: ignore[arg-type]

    def sample(self, position: Sequence[Any]) -> tuple[float, float, float]:
        point = _vector3(position, "Field.vector")
        _require(all(self.bounds[index] <= point[index] <= self.bounds[index+3]
                     for index in range(3)), "NEBO-G043-FIELD-BOUNDS", "Field.vector")
        try:
            sampled = self.function(point)
        except SimulationError:
            raise
        except Exception as error:
            raise SimulationError("NEBO-G043-FIELD-CALLBACK", "Field.vector") from error
        return _vector3(sampled, "Field.vector")


class ParticleSystem:
    def __init__(self, capacity: int,
                 emitter: Callable[[int, Mapping[str, Any]], Mapping[str, Any]],
                 updater: Callable[[Mapping[str, Any], float], Mapping[str, Any]]) -> None:
        self.capacity = _integer(capacity, "ParticleSystem.new", 1, MAX_PARTICLES)
        _require(callable(emitter) and callable(updater),
                 "NEBO-G043-PARTICLE-CALLBACK", "ParticleSystem.new")
        self._emitter = emitter
        self._updater = updater
        self._particles: list[dict[str, Any]] = []

    @staticmethod
    def new(capacity: int,
            emitter: Callable[[int, Mapping[str, Any]], Mapping[str, Any]],
            updater: Callable[[Mapping[str, Any], float], Mapping[str, Any]]) -> "ParticleSystem":
        return ParticleSystem(capacity, emitter, updater)

    def emit(self, count: int, state: Mapping[str, Any]) -> int:
        operation = "particles.emit"
        value = _integer(count, operation, 0, self.capacity)
        _require(isinstance(state, Mapping) and len(self._particles)+value <= self.capacity,
                 "NEBO-G043-PARTICLE-CAPACITY", operation)
        generated = []
        for index in range(value):
            try:
                particle = self._emitter(index, _frozen_mapping(state))
            except SimulationError:
                raise
            except Exception as error:
                raise SimulationError("NEBO-G043-PARTICLE-CALLBACK", operation) from error
            _require(isinstance(particle, Mapping) and {"position", "velocity"} <= particle.keys(),
                     "NEBO-G043-PARTICLE-STATE", operation)
            generated.append({"position": _vector3(particle["position"], operation),
                              "velocity": _vector3(particle["velocity"], operation)})
        self._particles.extend(generated)
        return value

    def step(self, dt: Any) -> None:
        duration = _number(dt, "particles.step")
        _require(0 < duration <= 1, "NEBO-G043-TIMESTEP", "particles.step")
        updated = []
        for particle in self._particles:
            try:
                value = self._updater(_frozen_mapping(particle), duration)
            except SimulationError:
                raise
            except Exception as error:
                raise SimulationError("NEBO-G043-PARTICLE-CALLBACK", "particles.step") from error
            _require(isinstance(value, Mapping) and {"position", "velocity"} <= value.keys(),
                     "NEBO-G043-PARTICLE-STATE", "particles.step")
            updated.append({"position": _vector3(value["position"], "particles.step"),
                            "velocity": _vector3(value["velocity"], "particles.step")})
        self._particles = updated

    def applyField(self, field_: Field) -> None:
        _require(isinstance(field_, Field), "NEBO-G043-FIELD", "particles.applyField")
        before = copy.deepcopy(self._particles)
        try:
            updated = []
            for particle in self._particles:
                force = field_.sample(particle["position"])
                value = copy.deepcopy(particle)
                value["velocity"] = tuple(value["velocity"][index]+force[index] for index in range(3))
                updated.append(value)
            self._particles = updated
        except Exception:
            self._particles = before
            raise

    def snapshot(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(MappingProxyType(copy.deepcopy(value)) for value in self._particles)
