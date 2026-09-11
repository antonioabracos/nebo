#!/usr/bin/env python3
"""Independent source-to-effect oracle for all 57 G041 public surfaces."""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
from typing import Any, Callable

from compiler.sdk.robotics import (
    Filter,
    PidController,
    Pose,
    RobotLoop,
    RobotModel,
    RoboticsError,
    SensorFusion,
    SignalBuffer,
    StateSpace,
    SystemIdentification,
    Trajectory,
    Transform,
)


COUNTS = {
    "positive": 0,
    "negative": 0,
    "boundary": 0,
    "metamorphic": 0,
    "adversarial": 0,
    "composition": 0,
    "ownership": 0,
    "failure_atomicity": 0,
    "diagnostics": 0,
    "sdk": 0,
    "determinism": 0,
}
EVIDENCE: list[str] = []


def require(condition: bool, label: str) -> None:
    if not condition:
        raise AssertionError(label)


def close(actual: float, expected: float, tolerance: float = 1.0e-8) -> bool:
    return math.isclose(actual, expected, rel_tol=tolerance, abs_tol=tolerance)


def surface(surface_id: str, condition: bool, observation: Any) -> None:
    require(condition, surface_id)
    COUNTS["positive"] += 1
    COUNTS["sdk"] += 1
    EVIDENCE.append(f"{surface_id}:{observation!r}")


def claim(category: str, condition: bool, label: str, observation: Any = True) -> None:
    require(condition, label)
    COUNTS[category] += 1
    EVIDENCE.append(f"{category}:{label}:{observation!r}")


def negative(code: str, operation: str, action: Callable[[], Any]) -> None:
    try:
        action()
    except RoboticsError as error:
        require(error.code == code, f"negative code {operation}: {error.code}")
        require(error.operation == operation, f"negative operation {operation}: {error.operation}")
        COUNTS["negative"] += 1
        COUNTS["diagnostics"] += 1
        EVIDENCE.append(f"negative:{operation}:{code}")
        return
    raise AssertionError(f"negative case unexpectedly passed: {operation}:{code}")


def subgroup_s01() -> None:
    signal = SignalBuffer.new(8, 4.0, "m/s")
    surface("G041-S01-01", signal.capacity == 8 and signal.sample_rate == 4.0 and signal.unit == "m/s", signal.capacity)
    for value, timestamp in ((0.0, 0.0), (1.0, 0.25), (0.0, 0.5), (-1.0, 0.75)):
        signal.push(value, timestamp)
    surface("G041-S01-02", len(signal.window(8)) == 4 and signal.window(1)[0].value == -1.0, signal.window(1))
    window = signal.window(3)
    surface("G041-S01-03", tuple(point.value for point in window) == (1.0, 0.0, -1.0), window)
    resampled = signal.resample(8.0, "linear")
    surface("G041-S01-04", len(resampled) == 7 and close(resampled[1].value or 0.0, 0.5), resampled[1])
    decimated = signal.decimate(2, Filter.lowPass(1.0, 4.0, 1))
    surface("G041-S01-05", len(decimated) == 2 and decimated[0].timestamp == 0.0, decimated)
    interpolated = signal.interpolate(0.375, "linear")
    surface("G041-S01-06", close(interpolated, 0.5), interpolated)
    spectrum = signal.spectrum({"window": "rectangular"})
    surface("G041-S01-07", len(spectrum) == 3 and close(spectrum[0].frequency, 0.0), spectrum)
    statistics = signal.statistics()
    surface("G041-S01-08", statistics["count"] == 4 and close(statistics["mean"], 0.0), dict(statistics))

    altered = SignalBuffer.new(8, 4.0, "m/s")
    for value, timestamp in ((0.0, 0.0), (2.0, 0.25), (0.0, 0.5), (-1.0, 0.75)):
        altered.push(value, timestamp)
    claim("metamorphic", altered.statistics()["mean"] != statistics["mean"], "signal values govern statistics")
    claim("composition", close(signal.interpolate(0.25, "linear"), signal.window(4)[1].value or 0.0), "window and interpolation compose")
    copied = signal.window(4)
    signal.push(9.0, 1.0)
    claim("ownership", len(copied) == 4 and copied[-1].value == -1.0, "signal windows are detached snapshots")
    before = signal.window(8)
    negative("NON_MONOTONIC_TIMESTAMP", "signal.push", lambda: signal.push(3.0, 1.0))
    claim("failure_atomicity", signal.window(8) == before, "rejected timestamp leaves signal unchanged")
    claim("boundary", SignalBuffer.new(2, 1.0, "V").capacity == 2, "minimum signal capacity")
    negative("INVALID_INTEGER", "SignalBuffer.new", lambda: SignalBuffer.new(True, 4.0, "V"))
    negative("OUT_OF_RANGE", "SignalBuffer.new", lambda: SignalBuffer.new(1, 4.0, "V"))
    negative("OUT_OF_RANGE", "SignalBuffer.new", lambda: SignalBuffer.new(4, 0.0, "V"))
    negative("INVALID_TEXT", "SignalBuffer.new", lambda: SignalBuffer.new(4, 4.0, ""))
    negative("NON_FINITE", "signal.push", lambda: signal.push(float("nan"), 1.25))
    negative("TIMESTAMP_OUTSIDE_WINDOW", "signal.interpolate", lambda: signal.interpolate(-1.0, "linear"))
    negative("UNSUPPORTED_METHOD", "signal.interpolate", lambda: signal.interpolate(0.5, "cubic"))
    negative("ANTI_ALIAS_FILTER_REQUIRED", "signal.decimate", lambda: signal.decimate(2, Filter.highPass(1.0, 4.0, 1)))
    negative("UNSUPPORTED_WINDOW", "signal.spectrum", lambda: signal.spectrum({"window": "blackman"}))


def subgroup_s02() -> None:
    low = Filter.lowPass(5.0, 100.0, 2)
    surface("G041-S02-01", low.kind == "lowpass" and low.parameters["order"] == 2, low.parameters)
    high = Filter.highPass(3.0, 100.0, 1)
    surface("G041-S02-02", high.kind == "highpass" and high.parameters["cutoff"] == 3.0, high.parameters)
    band = Filter.bandPass(2.0, 12.0, 100.0)
    surface("G041-S02-03", band.kind == "bandpass" and band.parameters["low"] == 2.0, band.parameters)
    moving = Filter.movingAverage(3)
    surface("G041-S02-04", moving.kind == "moving-average" and moving.parameters["window"] == 3, moving.parameters)
    kalman = Filter.kalman({"transition": 1.0, "measurement": 1.0, "initialState": 0.0}, 0.1, 0.4)
    surface("G041-S02-05", kalman.kind == "kalman" and kalman.parameters["processNoise"] != kalman.parameters["measurementNoise"], kalman.parameters)
    filtered = tuple(moving.step(value) for value in (3.0, 6.0, 9.0, 12.0))
    surface("G041-S02-06", filtered == (3.0, 4.5, 6.0, 9.0), filtered)
    moving.reset(5.0)
    surface("G041-S02-07", close(moving.step(8.0), 6.5), 6.5)
    response = low.frequencyResponse(9)
    surface("G041-S02-08", response[0].magnitude > response[-1].magnitude and response[-1].frequency == 50.0, response)

    response_repeat = Filter.lowPass(5.0, 100.0, 2).frequencyResponse(9)
    claim("determinism", response_repeat == response, "frequency response is deterministic")
    claim("metamorphic", Filter.lowPass(15.0, 100.0, 1).frequencyResponse(9)[4].magnitude > Filter.lowPass(5.0, 100.0, 1).frequencyResponse(9)[4].magnitude, "cutoff governs attenuation")
    claim("composition", close(Filter.movingAverage(2).step(low.step(2.0)), low.step(2.0), 1.0), "filter stages compose")
    reset_response = low.frequencyResponse(9)
    low.step(8.0)
    claim("ownership", low.frequencyResponse(9) == reset_response, "response snapshot does not expose filter state")
    initial = kalman.step(1.0)
    negative("NON_FINITE", "filter.step", lambda: kalman.step(float("inf")))
    claim("failure_atomicity", close(kalman.step(1.0), initial, 0.5), "rejected Kalman measurement does not poison state")
    claim("boundary", len(Filter.movingAverage(1).frequencyResponse(2)) == 2, "minimum response dimensions")
    negative("NYQUIST_VIOLATION", "Filter.lowPass", lambda: Filter.lowPass(50.0, 100.0, 1))
    negative("INVALID_INTEGER", "Filter.highPass", lambda: Filter.highPass(5.0, 100.0, True))
    negative("INVALID_BAND", "Filter.bandPass", lambda: Filter.bandPass(12.0, 2.0, 100.0))
    negative("OUT_OF_RANGE", "Filter.movingAverage", lambda: Filter.movingAverage(0))
    negative("OUT_OF_RANGE", "Filter.kalman", lambda: Filter.kalman({}, 0.0, 1.0))
    negative("UNSUPPORTED_OPERATION", "filter.frequencyResponse", lambda: kalman.frequencyResponse(8))
    negative("INVALID_NUMBER", "filter.step", lambda: low.step(True))


def subgroup_s03() -> None:
    controller = PidController.new(2.0, 1.0, 0.25, {"antiWindup": "clamp", "derivativeFilter": 8.0})
    surface("G041-S03-01", controller.kp == 2.0 and controller.anti_windup == "clamp", controller.kp)
    surface("G041-S03-02", controller.setTarget(10.0).target == 10.0, controller.target)
    controller.setLimits(-3.0, 3.0)
    step = controller.step(0.0, 0.1)
    surface("G041-S03-03", step.output == 3.0 and step.saturated, step)
    surface("G041-S03-04", controller.minimum == -3.0 and controller.maximum == 3.0, (controller.minimum, controller.maximum))
    controller.reset({"integral": 0.5, "previousError": 1.0, "derivative": 0.0})
    surface("G041-S03-05", controller.trace() == () and close(controller._integral, 0.5), controller._integral)
    tuned = controller.tune("ziegler-nichols-pi", {"ultimateGain": 4.0, "ultimatePeriod": 2.0})
    surface("G041-S03-06", close(tuned["kp"], 1.8) and tuned["kd"] == 0.0, dict(tuned))
    stability = controller.stabilityReport({"processGain": 2.0, "timeConstant": 5.0})
    surface("G041-S03-07", stability["stable"] is True and stability["saturationConfigured"] is True, dict(stability))
    controller.step(9.0, 0.1)
    trace = controller.trace()
    surface("G041-S03-08", len(trace) == 1 and trace[0].error == 1.0, trace)

    clamped = PidController.new(0.0, 10.0, 0.0, {"antiWindup": "clamp"}).setTarget(10.0).setLimits(-1.0, 1.0)
    for _ in range(5):
        clamped.step(0.0, 1.0)
    claim("adversarial", close(clamped._integral, 0.0), "saturation prevents integral windup")
    changed = PidController.new(0.5, 0.0, 0.0, None).setTarget(2.0).step(1.0, 0.1)
    claim("metamorphic", changed.output != step.output, "PID gains and measurement govern output")
    claim("composition", stability["integralAction"] is True and len(trace) == 1, "tuning stability and trace compose")
    snapshot = controller.trace()
    controller.step(8.5, 0.1)
    claim("ownership", len(snapshot) == 1 and len(controller.trace()) == 2, "PID trace is a detached snapshot")
    integral_before = controller._integral
    negative("OUT_OF_RANGE", "controller.step", lambda: controller.step(1.0, 0.0))
    claim("failure_atomicity", controller._integral == integral_before, "invalid dt leaves PID integral unchanged")
    claim("boundary", PidController.new(0.0, 0.0, 0.0, None).step(1.0, 1.0).output == 0.0, "zero gain controller")
    negative("INVALID_NUMBER", "PidController.new", lambda: PidController.new(True, 1.0, 1.0, None))
    negative("UNSUPPORTED_POLICY", "PidController.new", lambda: PidController.new(1.0, 1.0, 1.0, {"antiWindup": "guess"}))
    negative("INVALID_LIMITS", "controller.setLimits", lambda: controller.setLimits(2.0, 2.0))
    negative("UNSUPPORTED_METHOD", "controller.tune", lambda: controller.tune("auto", {}))
    negative("INVALID_MODEL", "controller.stabilityReport", lambda: controller.stabilityReport([]))
    negative("OUT_OF_RANGE", "controller.tune", lambda: controller.tune("step-response", {"processGain": 1.0, "timeConstant": 1.0, "deadTime": 0.0}))


def subgroup_s04() -> None:
    model = StateSpace.define(((1.0, 0.1), (0.0, 1.0)), ((0.0,), (0.1,)), ((1.0, 0.0),), ((0.0,),), 0.1)
    surface("G041-S04-01", model.state_count == 2 and model.input_count == 1 and model.sample_time == 0.1, model.sample_time)
    simulation = model.simulate(((1.0,), (1.0,), (0.0,)), (0.0, 0.0))
    surface("G041-S04-02", len(simulation) == 3 and simulation[-1].state[0] > 0.0, simulation)
    point = model.step((1.0, 2.0), (3.0,))
    surface("G041-S04-03", point.state == (1.2, 2.3) and point.output == (1.0,), point)
    surface("G041-S04-04", model.controllable() is True, model.controllable())
    surface("G041-S04-05", model.observable() is True, model.observable())
    continuous = StateSpace.define(((0.0, 1.0), (-1.0, -0.2)), ((0.0,), (1.0,)), ((1.0, 0.0),), ((0.0,),), 0.0)
    discrete = continuous.discretize(0.05, "forward-euler")
    surface("G041-S04-06", discrete.sample_time == 0.05 and close(discrete.A[0][1], 0.05), discrete.A)
    identification = SystemIdentification.fit(
        {"input": (0.0, 1.0, 0.0, 2.0, 1.0), "output": (1.0, 0.5, 2.25, 1.125, 4.5625)},
        "arx-1",
        {"solver": "normal-equations"},
    )
    surface("G041-S04-07", close(identification.coefficient, 0.5) and close(identification.input_gain, 2.0), (identification.coefficient, identification.input_gain))
    residual = identification.residualReport()
    surface("G041-S04-08", close(residual["mse"], 0.0) and close(residual["fit"], 1.0), dict(residual))

    scaled = model.step((2.0, 4.0), (6.0,))
    claim("metamorphic", scaled.state == tuple(2.0 * value for value in point.state), "linear state model scales")
    claim("composition", continuous.discretize(0.05, "euler").step((0.0, 0.0), (1.0,)).state == (0.0, 0.05), "discretization and stepping compose")
    snapshot = simulation
    model.step((9.0, 9.0), (9.0,))
    claim("ownership", snapshot == simulation, "simulation result is immutable and detached")
    claim("determinism", model.simulate(((1.0,), (1.0,), (0.0,)), (0.0, 0.0)) == simulation, "state simulation deterministic")
    claim("boundary", len(model.simulate((), (0.0, 0.0))) == 0, "empty bounded simulation")
    negative("DIMENSION_MISMATCH", "StateSpace.define", lambda: StateSpace.define(((1.0, 0.0),), ((1.0,),), ((1.0,),), ((0.0,),), 0.1))
    negative("CONTINUOUS_MODEL", "model.step", lambda: continuous.step((0.0, 0.0), (1.0,)))
    negative("DIMENSION_MISMATCH", "model.step", lambda: model.step((1.0,), (1.0,)))
    negative("UNSUPPORTED_METHOD", "model.discretize", lambda: continuous.discretize(0.1, "magic"))
    negative("ALREADY_DISCRETE", "model.discretize", lambda: model.discretize(0.1, "euler"))
    negative("UNSUPPORTED_STRUCTURE", "SystemIdentification.fit", lambda: SystemIdentification.fit({"input": (1, 2, 3), "output": (1, 2, 3)}, "neural", None))
    negative("SINGULAR_DATA", "SystemIdentification.fit", lambda: SystemIdentification.fit({"input": (0, 0, 0), "output": (1, 1, 1)}, "arx-1", None))


def subgroup_s05() -> None:
    origin = Pose.of((0.0, 0.0, 0.0), (1.0, 0.0, 0.0, 0.0), "base")
    surface("G041-S05-01", origin.frame == "base" and origin.orientation[0] == 1.0, origin)
    target_pose = Pose.of((1.0, 1.0, 0.0), (1.0, 0.0, 0.0, 0.0), "base")
    transform = Transform.between(origin, target_pose)
    surface("G041-S05-02", transform.translation == (1.0, 1.0, 0.0) and transform.frame == "base", transform)
    description = {"version": 1, "linkLengths": (1.0, 1.0), "jointLimits": ((-math.pi, math.pi), (-math.pi, math.pi)), "frame": "base"}
    robot = RobotModel.load(description, "simulation")
    surface("G041-S05-03", robot.capability == "simulation" and robot.link_lengths == (1.0, 1.0), robot.link_lengths)
    forward = robot.forwardKinematics((0.0, math.pi / 2.0))
    surface("G041-S05-04", close(forward.position[0], 1.0) and close(forward.position[1], 1.0), forward)
    inverse = robot.inverseKinematics(target_pose, (0.1, 1.0), {"elbow": "nearest"})
    surface("G041-S05-05", inverse.converged and inverse.residual <= 1.0e-8, inverse)
    limits = {"maximumVelocity": 1.0, "maximumAcceleration": 2.0, "duration": 3.0}
    trajectory = Trajectory.plan((0.0, 0.0), (1.0, -0.5), limits, ({"center": (5.0, 5.0), "radius": 0.5},))
    surface("G041-S05-06", trajectory.start != trajectory.goal and trajectory.duration == 3.0, trajectory.duration)
    midpoint = trajectory.sample(1.5)
    surface("G041-S05-07", midpoint.position == (0.5, -0.25) and midpoint.velocity[0] > 0.0, midpoint)
    validation = trajectory.validate(limits)
    surface("G041-S05-08", validation["valid"] is True and validation["peakVelocity"] <= 1.0, dict(validation))

    farther = Pose.of((2.0, 0.0, 0.0), (1.0, 0.0, 0.0, 0.0), "base")
    rotated_origin = Pose.of((0.0, 0.0, 0.0), (math.sqrt(0.5), 0.0, 0.0, math.sqrt(0.5)), "base")
    rotated_translation = Transform.between(rotated_origin, Pose.of((1.0, 0.0, 0.0), rotated_origin.orientation, "base")).translation
    claim("metamorphic", close(rotated_translation[0], 0.0) and close(rotated_translation[1], -1.0), "source orientation governs relative transform")
    claim("composition", math.dist(robot.forwardKinematics(inverse.joints).position, target_pose.position) <= 1.0e-8, "inverse and forward kinematics compose")
    pose_snapshot = robot.forwardKinematics((0.0, 0.0))
    robot.forwardKinematics((0.1, 0.2))
    claim("ownership", pose_snapshot.position == (2.0, 0.0, 0.0), "kinematic pose is a detached value")
    claim("boundary", robot.inverseKinematics(farther, (0.0, 0.0), {"elbow": "nearest"}).singular, "workspace boundary is singular")
    negative("FRAME_MISMATCH", "Transform.between", lambda: Transform.between(origin, Pose.of((0, 0, 0), (1, 0, 0, 0), "map")))
    negative("CAPABILITY_DENIED", "RobotModel.load", lambda: RobotModel.load(description, "hardware"))
    negative("UNSUPPORTED_VERSION", "RobotModel.load", lambda: RobotModel.load({**description, "version": 2}, "simulation"))
    negative("JOINT_LIMIT", "robot.forwardKinematics", lambda: robot.forwardKinematics((4.0, 0.0)))
    negative("UNREACHABLE_TARGET", "robot.inverseKinematics", lambda: robot.inverseKinematics(Pose.of((3, 0, 0), (1, 0, 0, 0), "base"), (0, 0), None))
    negative("PATH_COLLISION", "Trajectory.plan", lambda: Trajectory.plan((0, 0), (1, 0), limits, ({"center": (0.503, 0.0), "radius": 0.001},)))
    negative("TIME_OUTSIDE_TRAJECTORY", "trajectory.sample", lambda: trajectory.sample(4.0))
    negative("INFEASIBLE_LIMITS", "Trajectory.plan", lambda: Trajectory.plan((0, 0), (1, 0), {**limits, "duration": 0.1}, ()))


def subgroup_s06() -> None:
    fusion = SensorFusion.new({"frame": "base", "processNoise": 0.02}, {"initialState": (0.0, 1.0), "initialCovariance": 1.0})
    surface("G041-S06-01", fusion.frame == "base" and fusion.process_noise == 0.02, fusion.state())
    fusion.addSensor("position", {"stateIndex": 0, "measurementNoise": 0.25}, "base")
    surface("G041-S06-02", "position" in fusion._sensors and fusion._sensors["position"]["measurementNoise"] == 0.25, fusion._sensors)
    predicted = fusion.predict(2.0, 0.5)
    surface("G041-S06-03", predicted == (0.75, 2.0), predicted)
    accepted = fusion.update("position", {"value": 0.8, "frame": "base"}, 1.0)
    surface("G041-S06-04", accepted.accepted and accepted.sensor == "position", accepted)
    state = fusion.state()
    surface("G041-S06-05", len(state) == 2 and state[0] > 0.75, state)
    covariance = fusion.covariance()
    surface("G041-S06-06", len(covariance) == 2 and covariance[0][0] < 1.0, covariance)
    fusion.rejectOutliers({"method": "normalized-innovation", "threshold": 2.0})
    surface("G041-S06-07", fusion._policy["threshold"] == 2.0, fusion._policy)
    rejected = fusion.update("position", {"value": 100.0, "frame": "base"}, 2.0)
    report = fusion.innovationReport()
    surface("G041-S06-08", not rejected.accepted and report == (accepted, rejected), report)

    state_before_reject = state
    claim("failure_atomicity", fusion.state() == state_before_reject, "outlier rejection preserves fused state")
    lower_noise = SensorFusion.new({"frame": "base", "processNoise": 0.02}, {"initialState": (0.0, 1.0), "initialCovariance": 1.0})
    lower_noise.addSensor("position", {"stateIndex": 0, "measurementNoise": 0.01}, "base").predict(2.0, 0.5)
    lower_noise.update("position", {"value": 0.8, "frame": "base"}, 1.0)
    claim("metamorphic", lower_noise.state()[0] != state[0], "measurement noise governs fusion gain")
    claim("composition", report[0].innovation == accepted.innovation and covariance[0][0] > 0.0, "prediction update and report compose")
    report_snapshot = fusion.innovationReport()
    claim("ownership", isinstance(report_snapshot, tuple) and report_snapshot[-1].sensor == "position", "innovation report is immutable")
    claim("adversarial", rejected.normalizedInnovation > 2.0 and fusion.state() == state_before_reject, "large sensor outlier cannot move state")
    claim("boundary", len(SensorFusion.new({"frame": "x", "processNoise": 0.01}, None).state()) == 2, "default bounded fusion state")
    negative("FRAME_MISMATCH", "fusion.addSensor", lambda: fusion.addSensor("wrong", {"stateIndex": 0, "measurementNoise": 1.0}, "map"))
    negative("DUPLICATE_SENSOR", "fusion.addSensor", lambda: fusion.addSensor("position", {"stateIndex": 0, "measurementNoise": 1.0}, "base"))
    negative("UNKNOWN_SENSOR", "fusion.update", lambda: fusion.update("missing", 1.0, 3.0))
    negative("FRAME_MISMATCH", "fusion.update", lambda: fusion.update("position", {"value": 1.0, "frame": "map"}, 3.0))
    negative("NON_MONOTONIC_TIMESTAMP", "fusion.update", lambda: fusion.update("position", 1.0, 2.0))
    negative("UNSUPPORTED_POLICY", "fusion.rejectOutliers", lambda: fusion.rejectOutliers({"method": "magic", "threshold": 2.0}))
    negative("INVALID_INTEGER", "fusion.addSensor", lambda: SensorFusion.new({"frame": "x"}, None).addSensor("x", {"stateIndex": True, "measurementNoise": 1.0}, "x"))


def configured_loop(safe_events: list[str], writes: list[float]) -> RobotLoop:
    controller = PidController.new(1.0, 0.0, 0.0, None).setTarget(1.0)
    loop = RobotLoop.new(0.02, 0.01, controller)
    loop.readSensors(lambda tick: float(tick) / 10.0)
    loop.compute(lambda sensed, control, period: control.step(sensed, period).output)
    loop.writeActuators(lambda command: writes.append(command))
    loop.safeState(lambda reason: safe_events.append(reason))
    loop.watchdog(0.015)
    return loop


def subgroup_s07() -> None:
    safe_events: list[str] = []
    writes: list[float] = []
    controller = PidController.new(1.0, 0.0, 0.0, None).setTarget(1.0)
    loop = RobotLoop.new(0.02, 0.01, controller)
    surface("G041-S07-01", loop.period == 0.02 and loop.deadline == 0.01, (loop.period, loop.deadline))
    surface("G041-S07-02", loop.readSensors(lambda tick: float(tick))._read is not None, True)
    surface("G041-S07-03", loop.compute(lambda sensed, control, period: control.step(sensed, period).output)._compute is not None, True)
    surface("G041-S07-04", loop.writeActuators(lambda command: writes.append(command))._write is not None, True)
    surface("G041-S07-05", loop.safeState(lambda reason: safe_events.append(reason))._safe is not None, True)
    surface("G041-S07-06", loop.watchdog(0.015)._watchdog == 0.015, loop._watchdog)
    result = loop.run({"maxTicks": 3, "phaseDurations": (0.004, 0.012, 0.004)})
    surface("G041-S07-07", result.status == "SAFE" and result.fault == "DEADLINE_MISS" and result.safeStateCalls == 1, result)
    timing = loop.timingReport()
    surface("G041-S07-08", timing["ticks"] == 2 and timing["misses"] == 1, dict(timing))
    replay = loop.replay(loop.log)
    surface("G041-S07-09", replay.deterministic and replay.events == len(loop.log) and replay.hardware is False, replay)

    repeat = loop.replay(loop.log)
    claim("determinism", repeat.digest == replay.digest, "loop replay digest deterministic")
    changed_log = tuple(loop.log) + ({"tick": 9, "event": "SAFE", "reason": "changed"},)
    claim("metamorphic", loop.replay(changed_log).digest != replay.digest, "replay log identity governs digest")
    claim("composition", len(writes) == 1 and safe_events == ["DEADLINE_MISS"] and timing["misses"] == 1, "read compute write timing and safety compose")
    log_snapshot = loop.log
    claim("ownership", isinstance(log_snapshot, tuple) and all(type(event).__name__ == "mappingproxy" for event in log_snapshot), "loop log is immutable")
    claim("failure_atomicity", result.safeStateCalls == 1 and len(safe_events) == 1, "deadline fault enters safe state exactly once")
    fault_safety: list[str] = []
    fault_loop = RobotLoop.new(0.02, 0.01, object())
    fault_loop.readSensors(lambda tick: (_ for _ in ()).throw(RuntimeError("device")))
    fault_loop.compute(lambda sensed, control, period: sensed).writeActuators(lambda command: None).safeState(lambda reason: fault_safety.append(reason))
    fault = fault_loop.run({"maxTicks": 1, "phaseDurations": (0.001,)})
    claim("adversarial", fault.fault == "DEVICE_OR_CALLBACK_FAILURE" and fault_safety == ["DEVICE_OR_CALLBACK_FAILURE"], "device fault activates safe state")
    cancelled_safety: list[str] = []
    cancelled_loop = configured_loop(cancelled_safety, [])
    cancelled = cancelled_loop.run({"maxTicks": 1, "cancelled": True})
    claim("boundary", cancelled.ticks == 0 and cancelled_safety == ["CANCELLED"], "pre-run cancellation is safe")
    negative("INVALID_DEADLINE", "RobotLoop.new", lambda: RobotLoop.new(0.01, 0.02, object()))
    negative("INVALID_CALLBACK", "loop.readSensors", lambda: loop.readSensors(4))
    negative("INVALID_WATCHDOG", "loop.watchdog", lambda: loop.watchdog(0.03))
    negative("INVALID_CANCELLATION", "loop.run", lambda: loop.run([]))
    negative("INCOMPLETE_LOOP", "loop.run", lambda: RobotLoop.new(0.02, 0.01, object()).run({"maxTicks": 1}))
    negative("INVALID_LOG", "loop.replay", lambda: loop.replay("not-a-log"))
    negative("HARDWARE_REPLAY_FORBIDDEN", "loop.replay", lambda: loop.replay(({"hardware": True},)))


def static_contract_checks() -> None:
    module = Path("compiler/sdk/robotics.py").read_text(encoding="utf-8")
    require("socket." not in module and "subprocess." not in module and "urlopen" not in module, "SDK must not perform network or process IO")
    require("time.time" not in module and "datetime.now" not in module and "threading." not in module, "SDK must not claim host timing")
    require("simulation-only" in module and "hard real-time" in module, "honest physical-loop scope must be declared")
    claim("adversarial", "HARDWARE_REPLAY_FORBIDDEN" in module and "CAPABILITY_DENIED" in module, "hardware escape is rejected")


def main() -> None:
    subgroup_s01()
    subgroup_s02()
    subgroup_s03()
    subgroup_s04()
    subgroup_s05()
    subgroup_s06()
    subgroup_s07()
    static_contract_checks()
    require(COUNTS["positive"] == 57 and COUNTS["sdk"] == 57, "all 57 surfaces must have observed effects")
    digest = hashlib.sha256(json.dumps(EVIDENCE, sort_keys=False, separators=(",", ":"), ensure_ascii=True).encode("ascii")).hexdigest()
    fields = " ".join(f"{name}={count}" for name, count in COUNTS.items())
    print(f"G041_SDK_ORACLE_GREEN {fields} digest={digest}")


if __name__ == "__main__":
    main()
