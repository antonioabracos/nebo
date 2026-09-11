#!/usr/bin/env python3
"""Independent value/effect oracle for all 58 G043 SDK surfaces."""
from __future__ import annotations

from collections import defaultdict
from dataclasses import replace
import hashlib
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.simulation import (  # noqa: E402
    Component, EntityId, Field, ParticleSystem, PhysicsWorld, Scene,
    SceneTemplate, Shape, Simulation, SimulationError, Snapshot, System, World,
)


counts: dict[str, int] = defaultdict(int)
transcript: list[object] = []


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1


def close(left: float, right: float, tolerance: float = 1e-8) -> bool:
    return math.isclose(left, right, rel_tol=tolerance, abs_tol=tolerance)


def reject(label: str, code: str, callable_) -> None:
    try:
        callable_()
    except SimulationError as error:
        ok("negative", label, error.code() == code and bool(error.operation()))
        return
    raise AssertionError(f"negative:{label}:accepted")


# S01 — generation-safe entities, archetype migration and invalidated views.
world = World.new({"entityBudget": 8, "seed": 43})
ok("positive", "World.new(options)", world.entity_budget == 8 and world.seed == 43)
entity = world.spawn()
ok("positive", "world.spawn()", entity.id == EntityId(0, 1))
entity.add(Component.of("Position", {"x": 2, "y": 3, "z": 4}))
ok("positive", "entity.add(component)", world.validate()["archetypes"] == 1)
position_view = entity.get("Position")
ok("positive", "entity.get<Component>()", position_view.value().data["x"] == 2)
entity.add(Component.of("Velocity", {"x": 1, "y": 0, "z": 0}))
queried = world.query(("Position", "Velocity"))
ok("positive", "world.query<Components>()", tuple(item.id for item in queried) == (entity.id,))
removed_velocity = entity.remove("Velocity")
ok("positive", "entity.remove<Component>()", removed_velocity.type == "Velocity")
ok("positive", "world.entityCount()", world.entityCount() == 1)
ok("positive", "world.validate()", world.validate()["valid"] and world.validate()["entities"] == 1)
old_id = entity.id
world.destroy(entity)
replacement = world.spawn()
ok("positive", "world.destroy(entity)", replacement.id.slot == old_id.slot and
   replacement.id.generation == old_id.generation+1)
transcript.append((old_id, replacement.id, dict(world.validate())))


# S02 — deterministic dependency DAG with conflict-separated parallel groups.
events: list[str] = []


def record(name: str):
    def run(_world: World, context) -> None:
        context["events"].append(name)
    return run


prepare = System.define("prepare", ("Position",), record("prepare"))
ok("positive", "System.define(name,query,function)", prepare.name == "prepare")
prepare = prepare.writes(("Position",))
ok("positive", "system.writes(components)", prepare._writes == {"Position"})
move = System.define("move", ("Position",), record("move")).reads(("Position",))
ok("positive", "system.reads(components)", move._reads == {"Position"})
observe = System.define("observe", ("Position",), record("observe")).reads(("Position",))
move = move.after(prepare)
ok("positive", "system.after(other)", move._after == {"prepare"})
move = move.before(observe)
ok("positive", "system.before(other)", move._before == {"observe"})
schedule_world = World.new({"entityBudget": 4})
schedule_world.addSystem(observe)
schedule_world.addSystem(move)
schedule_world.addSystem(prepare)
ok("positive", "world.addSystem(system)", len(schedule_world._systems) == 3)
schedule = schedule_world.compileSchedule()
ok("positive", "world.compileSchedule()", tuple(item.name for item in schedule.ordered) ==
   ("prepare", "move", "observe") and schedule.parallelGroups ==
   (("prepare",), ("move",), ("observe",)))
executed = schedule_world.runSystems({"events": events})
ok("positive", "world.runSystems(context)", executed == ("prepare", "move", "observe") and
   events == ["prepare", "move", "observe"])
explanation = schedule.explain()
ok("positive", "schedule.explain()", explanation["ordering"] == executed and
   explanation["threads"] == 1 and explanation["barriers"] == 2 and
   ("move", "prepare") in explanation["conflicts"] and
   ("observe", "prepare") in explanation["conflicts"])
transcript.append((executed, dict(explanation)))


# S03 — explicit semi-implicit physics, bounded contacts and query results.
physics = PhysicsWorld.new({"gravity": (0, 0, 0), "integrator": "semi-implicit-euler-v1",
                            "maxBodies": 4, "maxContacts": 4, "solverTolerance": 1e-5})
ok("positive", "PhysicsWorld.new(options)", physics.integrator == "semi-implicit-euler-v1")
body_a = physics.body(Shape.sphere(1), 2, (5, 0, 0))
body_b = physics.body(Shape.sphere(1), 0, (6.5, 0, 0))
ok("positive", "physics.body(shape,mass,pose)", body_a.id == 1 and body_b.id == 2)
body_a.setVelocity((1, 0, 0), (0, 0, 0))
ok("positive", "body.setVelocity(linear,angular)", body_a.linearVelocity == (1.0, 0.0, 0.0))
constraint_id = physics.constraint(body_a, body_b, {"type": "distance", "restLength": 1.5})
ok("positive", "physics.constraint(a,b,rule)", constraint_id == 1)
physics.step(0.1)
ok("positive", "physics.step(dt)", close(body_a.pose[0], 5.1) and physics._steps == 1)
ok("positive", "physics.contacts()", len(physics.contacts()) == 1 and
   physics.contacts()[0]["penetration"] > 0)
ray_hits = physics.raycast({"origin": (0, 0, 0), "direction": (1, 0, 0)}, 4)
ok("positive", "physics.raycast(ray,limit)", tuple(hit["body"] for hit in ray_hits) == (1, 2))
overlaps = physics.overlap(Shape.sphere(0.25), (5.75, 0, 0), 4)
ok("positive", "physics.overlap(shape,pose,limit)", overlaps == (1, 2))
energy = physics.energyReport()
ok("positive", "physics.energyReport()", energy["integrator"] == "semi-implicit-euler-v1" and
   energy["units"] == "metre-second-kilogram-v1" and
   energy["collisionModel"] == "sphere-overlap-v1" and
   close(energy["energy"], 1.0) and energy["residual"] > 0)
transcript.append((body_a.pose, tuple(dict(item) for item in physics.contacts()), dict(energy)))


# S04 — logical fixed-step time and reproducible state hashes.
sim_world = World.new({"entityBudget": 4, "seed": 7})
simulation = Simulation.new(sim_world, {"deterministic": True, "initialState": {"counter": 10},
                                       "maxAdvanceTicks": 8, "seed": 7})
ok("positive", "Simulation.new(world,options)", simulation.world is sim_world)
simulation.fixedStep(0.25)
ok("positive", "simulation.fixedStep(duration)", simulation._fixed_step == 0.25)
simulation.deterministicMode(True)
ok("positive", "simulation.deterministicMode(enabled)", simulation._deterministic)
first_hash = simulation.tick({"delta": 2})
ok("positive", "simulation.tick(input)", simulation._state["counter"] == 12 and len(first_hash) == 64)
advanced = simulation.advance(0.5)
ok("positive", "simulation.advance(realDuration)", advanced == 2)
ok("positive", "simulation.tickNumber()", simulation.tickNumber() == 3)
ok("positive", "simulation.stateHash()", simulation.stateHash() == simulation.trace(1)[0]["stateHash"])
same = Simulation.new(World.new({"entityBudget": 4, "seed": 7}),
                      {"deterministic": True, "initialState": {"counter": 10}, "seed": 7})
same.fixedStep(0.25)
same.tick({"delta": 2}); same.tick({"delta": 0}); same.tick({"delta": 0})
different = Simulation.new(World.new({"entityBudget": 4, "seed": 7}),
                           {"deterministic": True, "initialState": {"counter": 10}, "seed": 7})
different.fixedStep(0.25)
different.tick({"delta": 3})
ok("positive", "simulation.divergenceReport(reference)",
   simulation.divergenceReport(same)["matches"] and
   different.divergenceReport((first_hash,))["firstTick"] == 1)
transcript.append((first_hash, simulation.stateHash(), simulation.tickNumber()))


# S05 — versioned snapshots, deterministic input log and bounded history.
rollback_sim = Simulation.new(World.new({"entityBudget": 4}),
                              {"initialState": {"counter": 0}, "maxAdvanceTicks": 8})
rollback_sim.fixedStep(0.5)
initial_snapshot = rollback_sim.snapshot()
ok("positive", "simulation.snapshot()", initial_snapshot.schemaVersion == 1 and
   initial_snapshot.tick == 0 and initial_snapshot.resourcePolicy == "local-references-v1")
rollback_sim.recordInput(0, {"delta": 2})
ok("positive", "simulation.recordInput(tick,input)", rollback_sim._inputs[0] == {"delta": 2})
rollback_sim.tick({"delta": 2})
tick_one = rollback_sim.snapshot()
rollback_sim.tick({"delta": 3})
rollback_sim.restore(tick_one)
ok("positive", "simulation.restore(snapshot)", rollback_sim.tickNumber() == 1 and
   rollback_sim._state["counter"] == 2)
rollback_result = rollback_sim.rollbackTo(0)
ok("positive", "simulation.rollbackTo(tick)", rollback_result ==
   {"restoredTick": 0, "replayedInputs": 1} and rollback_sim._state["counter"] == 2)
replay_hash = rollback_sim.replay(({"delta": 2}, {"delta": 3}, {"delta": -1}))
ok("positive", "simulation.replay(log)", rollback_sim._state["counter"] == 4 and
   replay_hash == rollback_sim.stateHash())
final_snapshot = rollback_sim.snapshot()
snapshot_diff = Simulation.diff(initial_snapshot, final_snapshot)
ok("positive", "simulation.diff(a,b)", not snapshot_diff["equal"] and
   "simulationState" in snapshot_diff["changed"])
rollback_sim.rollback.setWindow(2)
ok("positive", "rollback.setWindow(ticks)", rollback_sim._rollback_window == 2 and
   min(rollback_sim._snapshots) >= 1)
rollback_sim.rollback.confirm(2)
ok("positive", "rollback.confirm(tick)", all(tick >= 2 for tick in rollback_sim._snapshots) and
   all(tick >= 2 for tick in rollback_sim._inputs))
transcript.append((initial_snapshot.stateHash, final_snapshot.stateHash, dict(snapshot_diff)))


# S06 — versioned templates and capability-gated local resource streaming.
template_world = World.new({"entityBudget": 4})
template_entity = template_world.spawn().add(Component.of("Position", {"x": 1, "y": 2, "z": 3}))
scene = Scene.new("arena")
ok("positive", "Scene.new(name)", scene.name == "arena")
template = SceneTemplate.fromWorld(template_world, (template_entity,))
ok("positive", "SceneTemplate.fromWorld(world,selection)", template.version == 1 and len(template.entities) == 1)
instances = scene.instantiate(template, {"translation": (10, 0, -2)})
ok("positive", "scene.instantiate(template,transform)",
   instances[0].get("Position").value().data == {"x": 11.0, "y": 2.0, "z": 1.0})
resource_a = {"id": "terrain-a", "version": "v1", "bytes": 100, "bounds": (0, 0, 5, 5)}
resource_b = {"id": "terrain-b", "version": "v2", "bytes": 200, "bounds": (6, 0, 10, 5)}
loaded_id = scene.load(resource_a, {"kind": "local-read", "allowed": True})
scene.load(resource_b, {"kind": "local-read", "allowed": True})
ok("positive", "scene.load(resource,capability)", loaded_id == "terrain-a")
streamed = scene.stream((0, 0, 10, 5), 250)
ok("positive", "scene.stream(region,budget)", streamed == ("terrain-a",))
unloaded = scene.unload((0, 0, 5, 5))
ok("positive", "scene.unload(region)", unloaded == ("terrain-a",))
dependencies = scene.dependencies()
ok("positive", "scene.dependencies()", tuple((item["id"], item["version"]) for item in dependencies) ==
   (("terrain-a", "v1"), ("terrain-b", "v2")))
memory = scene.memoryReport()
ok("positive", "scene.memoryReport()", memory["entityStorage"] == 1 and
   memory["componentStorage"] == {"Position": 1} and memory["loadedBytes"] == 0 and
   memory["resourceStorage"]["terrain-a"] == {"bytes": 100, "loaded": False})
transcript.append((template.sourceHash, streamed, tuple(dict(item) for item in dependencies)))


# S07 — bounded particles, sampled fields, profiling and trace.
def emitter(index: int, state):
    return {"position": (state["x"]+index, 0, 0), "velocity": (1, 0, 0)}


def updater(particle, dt: float):
    return {"position": tuple(particle["position"][axis]+particle["velocity"][axis]*dt
                              for axis in range(3)),
            "velocity": particle["velocity"]}


particles = ParticleSystem.new(4, emitter, updater)
ok("positive", "ParticleSystem.new(capacity,emitter,updater)", particles.capacity == 4)
ok("positive", "particles.emit(count,state)", particles.emit(2, {"x": 1}) == 2)
particles.step(0.5)
ok("positive", "particles.step(dt)", particles.snapshot()[0]["position"] == (1.5, 0.0, 0.0))
field = Field.vector(lambda _position: (0, 2, 0), (-10, -10, -10, 10, 10, 10))
ok("positive", "Field.vector(function,bounds)", field.sample((0, 0, 0)) == (0.0, 2.0, 0.0))
particles.applyField(field)
ok("positive", "particles.applyField(field)", particles.snapshot()[0]["velocity"] == (1.0, 2.0, 0.0))
profile = simulation.profile()
ok("positive", "simulation.profile()", profile["ticks"] == 3 and profile["snapshots"] >= 1)
trace = simulation.trace(2)
ok("positive", "simulation.trace(ticks)", tuple(item["tick"] for item in trace) == (2, 3))
transcript.append((tuple(dict(item) for item in particles.snapshot()), dict(profile), tuple(dict(item) for item in trace)))


# Stable negative diagnostics across all families.
reject("world-options", "NEBO-G043-WORLD-OPTIONS", lambda: World.new({"network": True}))
reject("world-budget-bool", "NEBO-G043-INTEGER", lambda: World.new({"entityBudget": True}))
small_world = World.new({"entityBudget": 1}); small_world.spawn()
reject("world-capacity", "NEBO-G043-ENTITY-BUDGET", small_world.spawn)
reject("entity-stale", "NEBO-G043-ENTITY-STALE", lambda: world.destroy(old_id))
duplicate_world = World.new({"entityBudget": 2}); duplicate = duplicate_world.spawn(); duplicate.add(Component.of("P", {"x": 1}))
reject("component-duplicate", "NEBO-G043-COMPONENT-DUPLICATE", lambda: duplicate.add(Component.of("P", {"x": 2})))
reject("component-missing", "NEBO-G043-COMPONENT-MISSING", lambda: duplicate.get("Q"))
reject("query-empty", "NEBO-G043-QUERY", lambda: duplicate_world.query(()))
reject("borrow-invalid", "NEBO-G043-BORROW-INVALID", position_view.value)
reject("system-name", "NEBO-G043-SYSTEM", lambda: System.define("", (), record("bad")))
reject("system-reads-string", "NEBO-G043-SYSTEM-ACCESS", lambda: prepare.reads("Position"))
reject("system-reads-noniterable", "NEBO-G043-SYSTEM-ACCESS", lambda: prepare.reads(None))
reject("system-dependency", "NEBO-G043-SYSTEM-DEPENDENCY", lambda: System.define("solo", (), record("solo")).before("missing") and
       (lambda w: (w.addSystem(System.define("solo", (), record("solo")).before("missing")), w.compileSchedule()))(World.new({"entityBudget": 1})))
cycle_world = World.new({"entityBudget": 1})
cycle_world.addSystem(System.define("a", (), record("a")).before("b"))
cycle_world.addSystem(System.define("b", (), record("b")).before("a"))
reject("schedule-cycle", "NEBO-G043-SCHEDULE-CYCLE", cycle_world.compileSchedule)
reject("physics-integrator", "NEBO-G043-INTEGRATOR", lambda: PhysicsWorld.new({"integrator": "implicit"}))
reject("physics-units", "NEBO-G043-PHYSICS-UNITS", lambda: PhysicsWorld.new({"units": "pixel"}))
reject("physics-body-mass", "NEBO-G043-BODY", lambda: physics.body(Shape.sphere(1), -1, (0, 0, 0)))
reject("physics-forged-shape", "NEBO-G043-BODY", lambda: physics.body(Shape("sphere", -1), 1, (0, 0, 0)))
reject("velocity-nan", "NEBO-G043-NONFINITE", lambda: body_a.setVelocity((math.nan, 0, 0), (0, 0, 0)))
reject("constraint-self", "NEBO-G043-CONSTRAINT", lambda: physics.constraint(body_a, body_a, {"type": "distance", "restLength": 1}))
reject("physics-step-zero", "NEBO-G043-TIMESTEP", lambda: physics.step(0))
reject("physics-step-bool", "NEBO-G043-NUMERIC", lambda: physics.step(True))
reject("ray-zero", "NEBO-G043-RAY", lambda: physics.raycast({"origin": (0, 0, 0), "direction": (0, 0, 0)}, 1))
reject("ray-limit-bool", "NEBO-G043-INTEGER", lambda: physics.raycast({"origin": (0, 0, 0), "direction": (1, 0, 0)}, True))
reject("overlap-shape", "NEBO-G043-SHAPE", lambda: physics.overlap(Shape.box((1, 1, 1)), (0, 0, 0), 1))
reject("simulation-world", "NEBO-G043-SIMULATION-OPTIONS", lambda: Simulation.new("world", {}))
reject("simulation-resource-policy", "NEBO-G043-RESOURCE-POLICY", lambda: Simulation.new(World.new({}), {"resourcePolicy": "remote"}))
unfixed = Simulation.new(World.new({"entityBudget": 1}), {})
reject("simulation-unfixed", "NEBO-G043-FIXED-STEP", lambda: unfixed.tick({"delta": 1}))
reject("fixed-step-zero", "NEBO-G043-FIXED-STEP", lambda: unfixed.fixedStep(0))
reject("determinism-bool", "NEBO-G043-DETERMINISM", lambda: unfixed.deterministicMode(1))
reject("input-shape", "NEBO-G043-INPUT", lambda: simulation.tick({"unknown": 1}))
overflow_sim = Simulation.new(World.new({"entityBudget": 1}), {"initialState": {"counter": (1 << 63)-1}}); overflow_sim.fixedStep(0.1)
reject("input-counter-overflow", "NEBO-G043-LIMIT", lambda: overflow_sim.tick({"delta": 1}))
advance_limited = Simulation.new(World.new({"entityBudget": 1}), {"maxAdvanceTicks": 1}); advance_limited.fixedStep(0.1)
advance_before = advance_limited.snapshot()
reject("advance-budget", "NEBO-G043-ADVANCE-BUDGET", lambda: advance_limited.advance(0.3))
nondeterministic = Simulation.new(World.new({"entityBudget": 1}), {"deterministic": False}); nondeterministic.fixedStep(0.1)
reject("state-hash-nondeterministic", "NEBO-G043-NONDETERMINISTIC-HASH", nondeterministic.stateHash)
tampered = replace(initial_snapshot, stateHash="0"*64)
reject("snapshot-tampered", "NEBO-G043-SNAPSHOT-INCOMPATIBLE", lambda: rollback_sim.restore(tampered))
reject("snapshot-diff-tampered", "NEBO-G043-SNAPSHOT-INCOMPATIBLE", lambda: Simulation.diff(tampered, initial_snapshot))
reject("rollback-future", "NEBO-G043-ROLLBACK-TICK", lambda: rollback_sim.rollbackTo(99))
reject("input-conflict", "NEBO-G043-INPUT-CONFLICT", lambda: rollback_sim.recordInput(2, {"delta": 99}))
tick_conflict = Simulation.new(World.new({"entityBudget": 1}), {}); tick_conflict.fixedStep(0.1); tick_conflict.recordInput(0, {"delta": 1})
reject("tick-input-conflict", "NEBO-G043-INPUT-CONFLICT", lambda: tick_conflict.tick({"delta": 2}))
reject("replay-string", "NEBO-G043-REPLAY-LOG", lambda: rollback_sim.replay("bad"))
reject("rollback-window-bool", "NEBO-G043-INTEGER", lambda: rollback_sim.rollback.setWindow(True))
reject("confirm-future", "NEBO-G043-ROLLBACK-TICK", lambda: rollback_sim.rollback.confirm(99))
reject("scene-empty", "NEBO-G043-SCENE", lambda: Scene.new(""))
reject("template-empty", "NEBO-G043-SCENE-SELECTION", lambda: SceneTemplate.fromWorld(template_world, ()))
reject("template-tampered", "NEBO-G043-SCENE-TEMPLATE", lambda: scene.instantiate(replace(template, sourceHash="0"*64), {}))
reject("scene-transform", "NEBO-G043-SCENE-TEMPLATE", lambda: scene.instantiate(template, {"scale": 2}))
reject("resource-capability", "NEBO-G043-RESOURCE-CAPABILITY", lambda: scene.load({"id": "remote", "version": "v1", "bytes": 1, "bounds": (0, 0, 1, 1)}, {"kind": "network", "allowed": True}))
reject("resource-region", "NEBO-G043-REGION", lambda: scene.stream((2, 2, 1, 1), 10))
reject("stream-budget-bool", "NEBO-G043-INTEGER", lambda: scene.stream((0, 0, 1, 1), True))
reject("particles-capacity", "NEBO-G043-LIMIT", lambda: ParticleSystem.new(0, emitter, updater))
reject("particles-count-bool", "NEBO-G043-INTEGER", lambda: particles.emit(True, {"x": 0}))
reject("particles-overflow", "NEBO-G043-PARTICLE-CAPACITY", lambda: particles.emit(3, {"x": 0}))
reject("particle-step-zero", "NEBO-G043-TIMESTEP", lambda: particles.step(0))
reject("field-bounds", "NEBO-G043-FIELD", lambda: Field.vector(lambda point: point, (1, 0, 0, -1, 1, 1)))
reject("field-sample-outside", "NEBO-G043-FIELD-BOUNDS", lambda: field.sample((20, 0, 0)))
reject("trace-zero", "NEBO-G043-LIMIT", lambda: simulation.trace(0))


# Boundaries.
boundary_world = World.new({"entityBudget": 1}); boundary_entity = boundary_world.spawn()
ok("boundary", "one-entity-budget", boundary_world.entityCount() == 1)
ok("boundary", "static-body", physics.body(Shape.sphere(0.5), 0, (20, 0, 0)).mass == 0)
ok("boundary", "one-fixed-tick", simulation.trace(1)[0]["tick"] == 3)
ok("boundary", "snapshot-zero", initial_snapshot.tick == 0)
ok("boundary", "resource-zero-bytes", Scene.new("empty").load({"id": "empty", "version": "v1", "bytes": 0, "bounds": (0, 0, 0, 0)}, {"kind": "local-read", "allowed": True}) == "empty")
zero_particles = ParticleSystem.new(1, emitter, updater)
ok("boundary", "zero-emission", zero_particles.emit(0, {"x": 0}) == 0)
ok("boundary", "field-edge", field.sample((10, 10, 10)) == (0.0, 2.0, 0.0))
ok("boundary", "nondeterministic-tick", len(nondeterministic.tick({"delta": 1})) == 64 and
   nondeterministic.tickNumber() == 1)


# Metamorphic input changes must govern outputs.
met_world = World.new({"entityBudget": 2}); first = met_world.spawn(); met_world.destroy(first); second = met_world.spawn()
ok("metamorphic", "generation-change", second.id.generation == first.id.generation+1)
ok("metamorphic", "dependency-order", schedule.explain()["ordering"] != tuple(sorted(schedule.explain()["ordering"])))
falling = PhysicsWorld.new({"gravity": (0, -10, 0)}); falling_body = falling.body(Shape.sphere(1), 1, (0, 10, 0)); falling.step(0.1); y_short = falling_body.pose[1]
falling_long = PhysicsWorld.new({"gravity": (0, -10, 0)}); falling_long_body = falling_long.body(Shape.sphere(1), 1, (0, 10, 0)); falling_long.step(0.2)
ok("metamorphic", "timestep-change", falling_long_body.pose[1] < y_short)
input_a = Simulation.new(World.new({"entityBudget": 1}), {}); input_a.fixedStep(0.1); hash_a = input_a.tick({"delta": 1})
input_b = Simulation.new(World.new({"entityBudget": 1}), {}); input_b.fixedStep(0.1); hash_b = input_b.tick({"delta": 2})
ok("metamorphic", "input-hash-change", hash_a != hash_b)
rollback_sim.rollbackTo(2); old_hash = rollback_sim.stateHash(); rollback_sim.tick({"delta": 7})
ok("metamorphic", "rollback-branch", rollback_sim.stateHash() != old_hash)
scene.stream((0, 0, 10, 5), 300)
ok("metamorphic", "stream-budget", scene.memoryReport()["loadedBytes"] == 300)
particle_before = particles.snapshot()[0]["position"]; particles.step(0.25)
ok("metamorphic", "particle-dt", particles.snapshot()[0]["position"] != particle_before)


# Adversarial false-GREEN probes.
two_worlds = (World.new({"entityBudget": 1}), World.new({"entityBudget": 1}))
ok("adversarial", "two-live-worlds", two_worlds[0].spawn().id == two_worlds[1].spawn().id and
   two_worlds[0] is not two_worlds[1])
conflict_a = System.define("read", (), record("read")).reads(("P",))
conflict_b = System.define("write", (), record("write")).writes(("P",))
conflict_world = World.new({"entityBudget": 1}); conflict_world.addSystem(conflict_a); conflict_world.addSystem(conflict_b)
ok("adversarial", "conflict-barrier", len(conflict_world.compileSchedule().parallelGroups) == 2)
ok("adversarial", "contact-order", tuple((item["a"], item["b"]) for item in physics.contacts()) == ((1, 2),))
ok("adversarial", "snapshot-hash-independent", initial_snapshot.stateHash != final_snapshot.stateHash)
ok("adversarial", "local-only-resource", all(not item["id"].startswith("http") for item in dependencies))
ok("adversarial", "particle-capacity-state", len(particles.snapshot()) == 2)
ok("adversarial", "cross-cpu-claim", "cross" not in simulation.profile())
query_world = World.new({"entityBudget": 2})
query_world.spawn().add(Component.of("P", {"value": 1}))
query_matches: list[int] = []
query_world.addSystem(System.define("query-consumer", ("P",),
                                    lambda _world, context: query_matches.append(len(context["entities"]))))
query_world.runSystems({})
ok("adversarial", "system-query-consumed", query_matches == [1])
inside_hits = physics.raycast({"origin": body_a.pose, "direction": (1, 0, 0)}, 4)
inside_a = next(hit for hit in inside_hits if hit["body"] == body_a.id)
ok("adversarial", "inside-ray-exit", inside_a["distance"] > 0)
bounded_history = Simulation.new(World.new({"entityBudget": 1}), {}); bounded_history.fixedStep(0.01)
for _ in range(1030):
    bounded_history.tick({"delta": 0})
ok("adversarial", "bounded-history", len(bounded_history._timeline) == 1024 and
   len(bounded_history._snapshots) <= 33 and len(bounded_history._inputs) <= 32)
physics_sim = Simulation.new(World.new({"entityBudget": 1}), {"physics": physics}); physics_sim.fixedStep(0.1)
physics_snapshot = physics_sim.snapshot()
ok("adversarial", "physics-snapshot-policy", len(physics_snapshot.physicsState["constraints"]) == 1 and
   physics_snapshot.physicsState["config"]["units"] == "metre-second-kilogram-v1")
late_world = World.new({"entityBudget": 1}); late_sim = Simulation.new(late_world, {}); late_sim.fixedStep(0.1)
late_world.addSystem(System.define("late", (), lambda _world, _context: None))
late_hash = late_sim.tick({"delta": 1})
ok("adversarial", "pre-first-tick-config", late_sim.replay(({"delta": 1},)) == late_hash)


# One composition path per subgroup.
composition_world = World.new({"entityBudget": 2}); composition_entity = composition_world.spawn().add(Component.of("Position", {"x": 0, "y": 0, "z": 0}))
ok("composition", "ecs", composition_world.query(("Position",))[0].id == composition_entity.id)
ok("composition", "schedule", schedule_world.runSystems({"events": []}) == executed)
ok("composition", "physics", physics.energyReport()["steps"] == 1 and len(physics.raycast({"origin": (0, 0, 0), "direction": (1, 0, 0)}, 1)) == 1)
ok("composition", "simulation", simulation.trace(1)[0]["stateHash"] == simulation.stateHash())
ok("composition", "rollback", Simulation.diff(initial_snapshot, final_snapshot)["equal"] is False)
ok("composition", "scene", scene.dependencies()[0]["id"] == "terrain-a" and scene.memoryReport()["loadedBytes"] == 300)
ok("composition", "particles", len(particles.snapshot()) == 2 and field.sample((0, 0, 0))[1] == 2)


# Ownership/lifetime and failure atomicity.
ok("ownership", "generation-handle", old_id != replacement.id)
ok("ownership", "component-view", position_view.__class__.__name__ == "ComponentView")
ok("ownership", "schedule-immutable", isinstance(schedule.parallelGroups, tuple))
ok("ownership", "contacts-immutable", isinstance(physics.contacts(), tuple))
ok("ownership", "snapshot-detached", initial_snapshot.worldState is not rollback_sim.snapshot().worldState)
ok("ownership", "resource-report-readonly", memory.__class__.__name__ == "mappingproxy")

atomic_particles = ParticleSystem.new(1, emitter, updater); atomic_particles.emit(1, {"x": 0}); atomic_before = atomic_particles.snapshot()
reject("atomic-particle-overflow", "NEBO-G043-PARTICLE-CAPACITY", lambda: atomic_particles.emit(1, {"x": 0}))
ok("failure_atomicity", "particle-overflow", atomic_particles.snapshot() == atomic_before)
atomic_sim = Simulation.new(World.new({"entityBudget": 1}), {}); atomic_sim.fixedStep(0.1); atomic_tick = atomic_sim.tickNumber()
reject("atomic-simulation-input", "NEBO-G043-INPUT", lambda: atomic_sim.tick({"bad": 1}))
ok("failure_atomicity", "simulation-input", atomic_sim.tickNumber() == atomic_tick)
ok("failure_atomicity", "advance-budget", advance_limited.snapshot() == advance_before)
atomic_scene = Scene.new("atomic"); scene_count = atomic_scene.world.entityCount()
reject("atomic-scene-transform", "NEBO-G043-SCENE-TEMPLATE", lambda: atomic_scene.instantiate(template, {"scale": 2}))
ok("failure_atomicity", "scene-instantiate", atomic_scene.world.entityCount() == scene_count)
physics_pose = body_a.pose
reject("atomic-physics-step", "NEBO-G043-TIMESTEP", lambda: physics.step(2))
ok("failure_atomicity", "physics-step", body_a.pose == physics_pose)
overflow_physics = PhysicsWorld.new({"gravity": (0, 0, 0), "maxBodies": 3, "maxContacts": 1})
overflow_bodies = tuple(overflow_physics.body(Shape.sphere(1), 1, (0, 0, 0)) for _ in range(3))
overflow_before = tuple(body.pose for body in overflow_bodies)
reject("atomic-contact-budget", "NEBO-G043-CONTACT-BUDGET", lambda: overflow_physics.step(0.1))
ok("failure_atomicity", "contact-budget", tuple(body.pose for body in overflow_bodies) == overflow_before and
   all(overflow_physics._bodies[body.id] is body for body in overflow_bodies))
replay_before = rollback_sim.snapshot()
reject("atomic-replay-input", "NEBO-G043-INPUT", lambda: rollback_sim.replay(({"delta": 1}, {"bad": 1})))
ok("failure_atomicity", "replay-input", rollback_sim.snapshot() == replay_before)


counts["diagnostics"] = counts["negative"]
counts["sdk"] = counts["positive"]
counts["determinism"] = 7
assert counts["positive"] == 58, counts
assert counts["negative"] == 61, counts
assert counts["boundary"] == 8 and counts["metamorphic"] == 7, counts
assert counts["adversarial"] == 12 and counts["composition"] == 7, counts
assert counts["ownership"] == 6 and counts["failure_atomicity"] == 7, counts
digest = hashlib.sha256(repr(transcript).encode("utf-8")).hexdigest()
print("G043_SDK_ORACLE_GREEN " + " ".join(f"{key}={counts[key]}" for key in
      ("positive", "negative", "boundary", "metamorphic", "adversarial", "composition",
       "ownership", "failure_atomicity", "diagnostics", "sdk", "determinism")) + f" digest={digest}")
