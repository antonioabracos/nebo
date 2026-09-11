"""Bounded deterministic geometry, GIS, mesh and routing profile for G042.

The existing assembly owners remain the compact native ABI implementation.
This dependency-free module materializes the current public source contract as
an executable reference profile.  It uses exact rational local coordinates,
explicit WGS84/Web-Mercator metadata, immutable snapshots and bounded scans.
"""
from __future__ import annotations

from dataclasses import dataclass, replace
from fractions import Fraction
import heapq
import io
import math
import re
from types import MappingProxyType
from typing import Any, Iterable, Mapping, Sequence


MAX_POINTS = 4096
MAX_FACES = 8192
MAX_INDEX_ITEMS = 4096
MAX_ROUTE_NODES = 2048
MAX_ROUTE_EDGES = 8192
MAX_CODEC_BYTES = 65536
EARTH_RADIUS_METRES = 6_371_008.8
WEB_MERCATOR_RADIUS_METRES = 6_378_137.0


class SpatialError(RuntimeError):
    """Stable fail-closed diagnostic."""

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
        raise SpatialError(code, operation)


def _exact(value: Any, operation: str) -> Fraction:
    _require(isinstance(value, (int, Fraction)) and not isinstance(value, bool),
             "NEBO-G042-COORDINATE", operation)
    return Fraction(value)


def _finite(value: Any, operation: str) -> float:
    _require(isinstance(value, (int, float, Fraction)) and not isinstance(value, bool),
             "NEBO-G042-NUMERIC", operation)
    result = float(value)
    _require(math.isfinite(result), "NEBO-G042-NONFINITE", operation)
    return result


def _limit(sequence: Sequence[Any], maximum: int, operation: str) -> tuple[Any, ...]:
    result = tuple(sequence)
    _require(0 < len(result) <= maximum, "NEBO-G042-LIMIT", operation)
    return result


@dataclass(frozen=True)
class PrecisionModel:
    mode: str
    tolerance: float = 0.0

    @staticmethod
    def exact() -> "PrecisionModel":
        return PrecisionModel("exact", 0.0)

    @staticmethod
    def filtered(tolerance: Any) -> "PrecisionModel":
        value = _finite(tolerance, "PrecisionModel.filtered")
        _require(value > 0.0, "NEBO-G042-PRECISION", "PrecisionModel.filtered")
        return PrecisionModel("filtered", value)

    @staticmethod
    def approximate(tolerance: Any) -> "PrecisionModel":
        value = _finite(tolerance, "PrecisionModel.approximate")
        _require(value > 0.0, "NEBO-G042-PRECISION", "PrecisionModel.approximate")
        return PrecisionModel("approximate", value)


@dataclass(frozen=True)
class ValidationReport:
    valid: bool
    issues: tuple[str, ...]
    topology: str


class _GeometryEvidence:
    precision: PrecisionModel
    crs: str
    units: str

    def validate(self) -> ValidationReport:
        return ValidationReport(True, (), "valid")

    def repair(self, plan: Mapping[str, Any]) -> "_GeometryEvidence":
        _require(isinstance(plan, Mapping) and plan.get("action") == "none",
                 "NEBO-G042-REPAIR-PLAN", "geometry.repair")
        return self

    def precisionReport(self) -> Mapping[str, Any]:
        return MappingProxyType({
            "crs": self.crs,
            "mode": self.precision.mode,
            "tolerance": self.precision.tolerance,
            "units": self.units,
        })


@dataclass(frozen=True)
class Point2(_GeometryEvidence):
    x: Fraction
    y: Fraction
    precision: PrecisionModel = PrecisionModel("exact", 0.0)
    crs: str = "LOCAL-CARTESIAN-V1"
    units: str = "millimetre"

    @staticmethod
    def of(x: Any, y: Any) -> "Point2":
        return Point2(_exact(x, "Point2.of"), _exact(y, "Point2.of"))


@dataclass(frozen=True)
class Vector2(_GeometryEvidence):
    x: Fraction
    y: Fraction
    precision: PrecisionModel = PrecisionModel("exact", 0.0)
    crs: str = "LOCAL-CARTESIAN-V1"
    units: str = "millimetre"

    @staticmethod
    def of(x: Any, y: Any) -> "Vector2":
        return Vector2(_exact(x, "Vector2.of"), _exact(y, "Vector2.of"))


@dataclass(frozen=True)
class Segment(_GeometryEvidence):
    a: Point2
    b: Point2
    precision: PrecisionModel = PrecisionModel("exact", 0.0)
    crs: str = "LOCAL-CARTESIAN-V1"
    units: str = "millimetre"

    @staticmethod
    def between(a: Point2, b: Point2) -> "Segment":
        _require(isinstance(a, Point2) and isinstance(b, Point2) and a != b,
                 "NEBO-G042-DEGENERATE", "Segment.between")
        _require((a.crs, a.units) == (b.crs, b.units),
                 "NEBO-G042-FRAME", "Segment.between")
        return Segment(a, b, a.precision, a.crs, a.units)


@dataclass(frozen=True)
class Polyline(_GeometryEvidence):
    points: tuple[Point2, ...]
    precision: PrecisionModel
    crs: str
    units: str

    @staticmethod
    def from_(points: Sequence[Point2]) -> "Polyline":
        values = _limit(points, MAX_POINTS, "Polyline.from")
        _require(len(values) >= 2 and all(isinstance(point, Point2) for point in values),
                 "NEBO-G042-POLYLINE", "Polyline.from")
        _require(all((point.crs, point.units) == (values[0].crs, values[0].units)
                     for point in values), "NEBO-G042-FRAME", "Polyline.from")
        _require(all(left != right for left, right in zip(values, values[1:])),
                 "NEBO-G042-DEGENERATE", "Polyline.from")
        return Polyline(values, values[0].precision, values[0].crs, values[0].units)


def _orientation(a: Point2, b: Point2, c: Point2) -> Fraction:
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x)


def _on_segment(point: Point2, segment: Segment) -> bool:
    return (_orientation(segment.a, segment.b, point) == 0 and
            min(segment.a.x, segment.b.x) <= point.x <= max(segment.a.x, segment.b.x) and
            min(segment.a.y, segment.b.y) <= point.y <= max(segment.a.y, segment.b.y))


def _segments_intersect(left: Segment, right: Segment) -> bool:
    o1 = _orientation(left.a, left.b, right.a)
    o2 = _orientation(left.a, left.b, right.b)
    o3 = _orientation(right.a, right.b, left.a)
    o4 = _orientation(right.a, right.b, left.b)
    if ((o1 > 0 > o2 or o1 < 0 < o2) and (o3 > 0 > o4 or o3 < 0 < o4)):
        return True
    return ((o1 == 0 and _on_segment(right.a, left)) or
            (o2 == 0 and _on_segment(right.b, left)) or
            (o3 == 0 and _on_segment(left.a, right)) or
            (o4 == 0 and _on_segment(left.b, right)))


def _ring_signed_area(ring: Sequence[Point2]) -> Fraction:
    return sum(a.x*b.y-b.x*a.y for a, b in zip(ring, ring[1:])) / 2


def _point_in_ring(point: Point2, ring: Sequence[Point2]) -> bool:
    result = False
    for a, b in zip(ring, ring[1:]):
        if (a.y > point.y) != (b.y > point.y):
            crossing = a.x + (point.y-a.y)*(b.x-a.x)/(b.y-a.y)
            if crossing > point.x:
                result = not result
    return result


@dataclass(frozen=True)
class Polygon(_GeometryEvidence):
    rings: tuple[tuple[Point2, ...], ...]
    boundary: str
    precision: PrecisionModel
    crs: str
    units: str

    @staticmethod
    def from_(rings: Sequence[Sequence[Point2]], policy: Mapping[str, Any]) -> "Polygon":
        operation = "Polygon.from"
        _require(isinstance(policy, Mapping) and policy.get("boundary") in {"include", "exclude"},
                 "NEBO-G042-POLYGON-POLICY", operation)
        _require(policy.get("precision") == "exact", "NEBO-G042-PRECISION", operation)
        values = _limit(rings, 32, operation)
        converted: list[tuple[Point2, ...]] = []
        for ring in values:
            points = _limit(ring, MAX_POINTS, operation)
            _require(len(points) >= 4 and points[0] == points[-1],
                     "NEBO-G042-RING", operation)
            _require(all(isinstance(point, Point2) for point in points),
                     "NEBO-G042-RING", operation)
            _require(all((point.crs, point.units) == (points[0].crs, points[0].units)
                         for point in points), "NEBO-G042-FRAME", operation)
            converted.append(points)
        polygon = Polygon(tuple(converted), str(policy["boundary"]),
                          values[0][0].precision, values[0][0].crs, values[0][0].units)
        report = polygon.validate()
        _require(report.valid, "NEBO-G042-POLYGON-INVALID", operation)
        return polygon

    def _edges(self) -> tuple[Segment, ...]:
        return tuple(Segment.between(a, b) for ring in self.rings
                     for a, b in zip(ring, ring[1:]))

    def validate(self) -> ValidationReport:
        issues: list[str] = []
        all_edges: list[tuple[Segment, ...]] = []
        for ring_index, ring in enumerate(self.rings):
            signed_area = _ring_signed_area(ring)
            if (ring_index == 0 and signed_area <= 0) or (ring_index > 0 and signed_area >= 0):
                issues.append("RING_ORIENTATION")
            edges = tuple(Segment.between(a, b) for a, b in zip(ring, ring[1:]))
            all_edges.append(edges)
            for i, left in enumerate(edges):
                for j, right in enumerate(edges):
                    if j <= i or j in {i-1, i+1} or {i, j} == {0, len(edges)-1}:
                        continue
                    if _segments_intersect(left, right):
                        issues.append("SELF_INTERSECTION")
        for index, edges in enumerate(all_edges):
            for other_edges in all_edges[index+1:]:
                if any(_segments_intersect(left, right) for left in edges for right in other_edges):
                    issues.append("RING_INTERSECTION")
        for hole in self.rings[1:]:
            if not _point_in_ring(hole[0], self.rings[0]):
                issues.append("HOLE_OUTSIDE_EXTERIOR")
        for index, hole in enumerate(self.rings[1:]):
            for other in self.rings[index+2:]:
                if _point_in_ring(hole[0], other) or _point_in_ring(other[0], hole):
                    issues.append("HOLE_OVERLAP")
        if self.area() == 0:
            issues.append("ZERO_AREA")
        return ValidationReport(not issues, tuple(sorted(set(issues))),
                                "simple" if not issues else "invalid")

    def area(self) -> Fraction:
        def ring_area(ring: Sequence[Point2]) -> Fraction:
            return abs(sum(a.x*b.y-b.x*a.y for a, b in zip(ring, ring[1:]))) / 2
        exterior = ring_area(self.rings[0])
        return exterior - sum((ring_area(ring) for ring in self.rings[1:]), Fraction(0))

    def contains(self, point: Point2) -> bool:
        _require(isinstance(point, Point2) and (point.crs, point.units) == (self.crs, self.units),
                 "NEBO-G042-FRAME", "polygon.contains")
        if any(_on_segment(point, edge) for edge in self._edges()):
            return self.boundary == "include"

        return _point_in_ring(point, self.rings[0]) and not any(
            _point_in_ring(point, ring) for ring in self.rings[1:])


class geometry:
    @staticmethod
    def intersects(a: Any, b: Any) -> bool:
        if isinstance(a, Segment) and isinstance(b, Segment):
            return _segments_intersect(a, b)
        if isinstance(a, Polygon) and isinstance(b, Point2):
            return a.contains(b)
        if isinstance(b, Polygon) and isinstance(a, Point2):
            return b.contains(a)
        raise SpatialError("NEBO-G042-GEOMETRY-KIND", "geometry.intersects")

    @staticmethod
    def distance(a: Any, b: Any) -> float:
        if isinstance(a, (Point2, Point3)) and isinstance(b, type(a)):
            coordinates_a = (a.x, a.y) if isinstance(a, Point2) else (a.x, a.y, a.z)
            coordinates_b = (b.x, b.y) if isinstance(b, Point2) else (b.x, b.y, b.z)
            return math.sqrt(sum(float(left-right)**2 for left, right in zip(coordinates_a, coordinates_b)))
        raise SpatialError("NEBO-G042-GEOMETRY-KIND", "geometry.distance")

    @staticmethod
    def raycast(ray: "Ray", objects: Sequence[Any], limit: int) -> tuple[Mapping[str, Any], ...]:
        _require(isinstance(ray, Ray) and isinstance(limit, int) and not isinstance(limit, bool) and
                 0 < limit <= 256,
                 "NEBO-G042-RAYCAST-LIMIT", "geometry.raycast")
        hits: list[tuple[float, int]] = []
        for index, obj in enumerate(objects):
            if isinstance(obj, Sphere):
                oc = (ray.origin.x-obj.center.x, ray.origin.y-obj.center.y, ray.origin.z-obj.center.z)
                b = sum(float(value)*direction for value, direction in zip(oc, ray.direction))
                c = sum(float(value)**2 for value in oc)-obj.radius**2
                discriminant = b*b-c
                if discriminant >= 0:
                    distance = -b-math.sqrt(discriminant)
                    if distance >= 0:
                        hits.append((distance, index))
        hits.sort()
        return tuple(MappingProxyType({"distance": distance, "objectIndex": index})
                     for distance, index in hits[:limit])

    @staticmethod
    def boundingBox(shape: Any) -> "Box3":
        if isinstance(shape, Sphere):
            r = Fraction(shape.radius).limit_denominator(1_000_000)
            return Box3(Point3.of(shape.center.x-r, shape.center.y-r, shape.center.z-r),
                        Point3.of(shape.center.x+r, shape.center.y+r, shape.center.z+r))
        if isinstance(shape, Mesh):
            return Box3(Point3.of(min(point.x for point in shape.vertices),
                                 min(point.y for point in shape.vertices),
                                 min(point.z for point in shape.vertices)),
                        Point3.of(max(point.x for point in shape.vertices),
                                 max(point.y for point in shape.vertices),
                                 max(point.z for point in shape.vertices)))
        raise SpatialError("NEBO-G042-GEOMETRY-KIND", "geometry.boundingBox")

    @staticmethod
    def volume(shape: Any) -> float:
        if isinstance(shape, Sphere):
            return 4.0*math.pi*shape.radius**3/3.0
        if isinstance(shape, Box3):
            return float((shape.maximum.x-shape.minimum.x) *
                         (shape.maximum.y-shape.minimum.y) *
                         (shape.maximum.z-shape.minimum.z))
        raise SpatialError("NEBO-G042-GEOMETRY-KIND", "geometry.volume")


@dataclass(frozen=True)
class Point3(_GeometryEvidence):
    x: Fraction
    y: Fraction
    z: Fraction
    precision: PrecisionModel = PrecisionModel("exact", 0.0)
    crs: str = "LOCAL-CARTESIAN-3D-V1"
    units: str = "millimetre"

    @staticmethod
    def of(x: Any, y: Any, z: Any) -> "Point3":
        return Point3(_exact(x, "Point3.of"), _exact(y, "Point3.of"), _exact(z, "Point3.of"))


@dataclass(frozen=True)
class Ray:
    origin: Point3
    direction: tuple[float, float, float]

    @staticmethod
    def from_(origin: Point3, direction: Sequence[Any]) -> "Ray":
        operation = "Ray.from"
        _require(isinstance(origin, Point3) and len(direction) == 3,
                 "NEBO-G042-RAY", operation)
        values = tuple(_finite(value, operation) for value in direction)
        norm = math.sqrt(sum(value*value for value in values))
        _require(norm > 0.0, "NEBO-G042-DEGENERATE", operation)
        return Ray(origin, tuple(value/norm for value in values))


@dataclass(frozen=True)
class Plane:
    point: Point3
    normal: tuple[float, float, float]

    @staticmethod
    def from_(point: Point3, normal: Sequence[Any]) -> "Plane":
        ray = Ray.from_(point, normal)
        return Plane(point, ray.direction)


@dataclass(frozen=True)
class Transform3:
    matrix: tuple[tuple[float, float, float, float], ...]

    @staticmethod
    def translation(vector: Sequence[Any]) -> "Transform3":
        _require(len(vector) == 3, "NEBO-G042-TRANSFORM", "Transform3.translation")
        x, y, z = (_finite(value, "Transform3.translation") for value in vector)
        return Transform3(((1, 0, 0, x), (0, 1, 0, y), (0, 0, 1, z), (0, 0, 0, 1)))

    @staticmethod
    def rotation(quaternion: Sequence[Any]) -> "Transform3":
        operation = "Transform3.rotation"
        _require(len(quaternion) == 4, "NEBO-G042-QUATERNION", operation)
        w, x, y, z = (_finite(value, operation) for value in quaternion)
        norm = math.sqrt(w*w+x*x+y*y+z*z)
        _require(norm > 0.0, "NEBO-G042-DEGENERATE", operation)
        w, x, y, z = (value/norm for value in (w, x, y, z))
        return Transform3(((1-2*y*y-2*z*z, 2*x*y-2*z*w, 2*x*z+2*y*w, 0),
                           (2*x*y+2*z*w, 1-2*x*x-2*z*z, 2*y*z-2*x*w, 0),
                           (2*x*z-2*y*w, 2*y*z+2*x*w, 1-2*x*x-2*y*y, 0),
                           (0, 0, 0, 1)))

    def compose(self, other: "Transform3") -> "Transform3":
        _require(isinstance(other, Transform3), "NEBO-G042-TRANSFORM", "transform.compose")
        result = tuple(tuple(sum(self.matrix[row][k]*other.matrix[k][column] for k in range(4))
                             for column in range(4)) for row in range(4))
        return Transform3(result)

    def apply(self, point: Point3) -> Point3:
        values = tuple(sum(self.matrix[row][column]*float((point.x, point.y, point.z, 1)[column])
                           for column in range(4)) for row in range(3))
        rounded = tuple(Fraction(value).limit_denominator(1_000_000) for value in values)
        return Point3(*rounded, point.precision, point.crs, point.units)


@dataclass(frozen=True)
class Sphere:
    center: Point3
    radius: float

    @staticmethod
    def of(center: Point3, radius: Any) -> "Sphere":
        value = _finite(radius, "Sphere.of")
        _require(isinstance(center, Point3) and value > 0, "NEBO-G042-SPHERE", "Sphere.of")
        return Sphere(center, value)


@dataclass(frozen=True)
class Box3:
    minimum: Point3
    maximum: Point3


@dataclass(frozen=True)
class Mesh(_GeometryEvidence):
    vertices: tuple[Point3, ...]
    indices: tuple[tuple[int, ...], ...]
    normals: tuple[tuple[float, float, float], ...] = ()
    simplificationError: float = 0.0
    precision: PrecisionModel = PrecisionModel("exact", 0.0)
    crs: str = "LOCAL-CARTESIAN-3D-V1"
    units: str = "millimetre"

    @staticmethod
    def from_(vertices: Sequence[Point3], indices: Sequence[Sequence[int]]) -> "Mesh":
        operation = "Mesh.from"
        points = _limit(vertices, MAX_POINTS, operation)
        faces = _limit(indices, MAX_FACES, operation)
        _require(all(isinstance(point, Point3) for point in points),
                 "NEBO-G042-MESH-VERTEX", operation)
        converted = tuple(tuple(face) for face in faces)
        _require(all(3 <= len(face) <= 64 and all(isinstance(index, int) and
                 not isinstance(index, bool) and 0 <= index < len(points) for index in face)
                 for face in converted), "NEBO-G042-MESH-INDEX", operation)
        mesh = Mesh(points, converted)
        _require(mesh.validate().valid, "NEBO-G042-MESH-INVALID", operation)
        return mesh

    def vertexCount(self) -> int:
        return len(self.vertices)

    def faceCount(self) -> int:
        return len(self.indices)

    def computeNormals(self, policy: Mapping[str, Any]) -> "Mesh":
        _require(isinstance(policy, Mapping) and policy.get("mode") in {"flat", "area-weighted"},
                 "NEBO-G042-NORMAL-POLICY", "mesh.computeNormals")
        normals = []
        for face in self.indices:
            a, b, c = (self.vertices[index] for index in face[:3])
            u = (float(b.x-a.x), float(b.y-a.y), float(b.z-a.z))
            v = (float(c.x-a.x), float(c.y-a.y), float(c.z-a.z))
            normal = (u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0])
            length = math.sqrt(sum(value*value for value in normal))
            _require(length > 0.0, "NEBO-G042-DEGENERATE", "mesh.computeNormals")
            normals.append(tuple(value/length for value in normal))
        return replace(self, normals=tuple(normals))

    def triangulate(self) -> "Mesh":
        faces = tuple((face[0], face[index], face[index+1])
                      for face in self.indices for index in range(1, len(face)-1))
        return replace(self, indices=faces, normals=(), simplificationError=0.0)

    def weld(self, tolerance: Any) -> "Mesh":
        value = _finite(tolerance, "mesh.weld")
        _require(value >= 0.0, "NEBO-G042-TOLERANCE", "mesh.weld")
        vertices: list[Point3] = []
        remap: list[int] = []
        for point in self.vertices:
            match = next((index for index, prior in enumerate(vertices)
                          if geometry.distance(point, prior) <= value), None)
            if match is None:
                match = len(vertices)
                vertices.append(point)
            remap.append(match)
        faces = tuple(tuple(remap[index] for index in face) for face in self.indices)
        _require(all(len(set(face)) >= 3 for face in faces),
                 "NEBO-G042-WELD-DEGENERATE", "mesh.weld")
        return Mesh(tuple(vertices), faces)

    def simplify(self, targetCount: int, error: Any) -> "Mesh":
        operation = "mesh.simplify"
        bound = _finite(error, operation)
        _require(isinstance(targetCount, int) and not isinstance(targetCount, bool) and
                 0 < targetCount <= self.faceCount() and bound >= 0,
                 "NEBO-G042-SIMPLIFY", operation)
        dropped = self.faceCount()-targetCount
        _require(dropped <= bound, "NEBO-G042-SIMPLIFY-ERROR", operation)
        return replace(self, indices=self.indices[:targetCount], normals=(),
                       simplificationError=float(dropped))

    def validate(self) -> ValidationReport:
        issues: list[str] = []
        edge_uses: dict[tuple[int, int], list[tuple[int, int]]] = {}
        for face in self.indices:
            if len(set(face)) < 3:
                issues.append("DEGENERATE_FACE")
            if any(not 0 <= index < len(self.vertices) for index in face):
                issues.append("INDEX_OUT_OF_BOUNDS")
                continue
            for source, target in zip(face, face[1:]+face[:1]):
                edge_uses.setdefault(tuple(sorted((source, target))), []).append((source, target))
        for uses in edge_uses.values():
            if len(uses) > 2:
                issues.append("NON_MANIFOLD_EDGE")
            elif len(uses) == 2 and uses[0] == uses[1]:
                issues.append("INCONSISTENT_ORIENTATION")
        return ValidationReport(not issues, tuple(sorted(set(issues))),
                                "indexed-surface" if not issues else "invalid")

    def transform(self, transform: Transform3) -> "Mesh":
        _require(isinstance(transform, Transform3), "NEBO-G042-TRANSFORM", "mesh.transform")
        return replace(self, vertices=tuple(transform.apply(point) for point in self.vertices), normals=())


Bounds = tuple[Fraction, Fraction, Fraction, Fraction]


def _bounds(value: Sequence[Any], operation: str) -> Bounds:
    _require(len(value) == 4, "NEBO-G042-BOUNDS", operation)
    result = tuple(_exact(item, operation) for item in value)
    _require(result[0] <= result[2] and result[1] <= result[3],
             "NEBO-G042-BOUNDS", operation)
    return result  # type: ignore[return-value]


class SpatialIndex:
    def __init__(self, kind: str, options: Mapping[str, Any]) -> None:
        _require(isinstance(options, Mapping) and set(options) <= {"capacity", "metric"},
                 "NEBO-G042-INDEX-OPTIONS", f"{kind}.new")
        capacity = options.get("capacity", MAX_INDEX_ITEMS)
        _require(isinstance(capacity, int) and not isinstance(capacity, bool) and
                 0 < capacity <= MAX_INDEX_ITEMS,
                 "NEBO-G042-INDEX-CAPACITY", f"{kind}.new")
        self.kind = kind
        self.capacity = capacity
        self.metric = options.get("metric", "euclidean")
        _require(self.metric == "euclidean", "NEBO-G042-INDEX-METRIC", f"{kind}.new")
        self._items: dict[int, tuple[Bounds, Any]] = {}
        self._next = 1

    def insert(self, bounds: Sequence[Any], value: Any) -> int:
        operation = "index.insert"
        parsed = _bounds(bounds, operation)
        _require(len(self._items) < self.capacity, "NEBO-G042-INDEX-CAPACITY", operation)
        handle = self._next
        self._next += 1
        self._items[handle] = (parsed, value)
        return handle

    def remove(self, handle: int) -> Any:
        _require(isinstance(handle, int) and not isinstance(handle, bool) and handle in self._items,
                 "NEBO-G042-INDEX-HANDLE", "index.remove")
        _, value = self._items.pop(handle)
        return value

    def update(self, handle: int, bounds: Sequence[Any]) -> None:
        _require(isinstance(handle, int) and not isinstance(handle, bool) and handle in self._items,
                 "NEBO-G042-INDEX-HANDLE", "index.update")
        parsed = _bounds(bounds, "index.update")
        self._items[handle] = (parsed, self._items[handle][1])

    def within(self, region: Sequence[Any], limit: int) -> tuple[Any, ...]:
        query = _bounds(region, "index.within")
        _require(isinstance(limit, int) and not isinstance(limit, bool) and 0 < limit <= self.capacity,
                 "NEBO-G042-INDEX-LIMIT", "index.within")
        return tuple(value for _, (bounds, value) in sorted(self._items.items())
                     if query[0] <= bounds[0] and query[1] <= bounds[1] and
                     bounds[2] <= query[2] and bounds[3] <= query[3])[:limit]

    def intersecting(self, bounds: Sequence[Any], limit: int) -> tuple[Any, ...]:
        query = _bounds(bounds, "index.intersecting")
        _require(isinstance(limit, int) and not isinstance(limit, bool) and 0 < limit <= self.capacity,
                 "NEBO-G042-INDEX-LIMIT", "index.intersecting")
        return tuple(value for _, (item, value) in sorted(self._items.items())
                     if not (item[2] < query[0] or query[2] < item[0] or
                             item[3] < query[1] or query[3] < item[1]))[:limit]

    def nearest(self, point: Point2, count: int) -> tuple[Any, ...]:
        _require(isinstance(point, Point2) and isinstance(count, int) and not isinstance(count, bool) and
                 0 < count <= self.capacity,
                 "NEBO-G042-INDEX-LIMIT", "index.nearest")
        ranked = []
        for handle, (bounds, value) in self._items.items():
            x = min(max(point.x, bounds[0]), bounds[2])
            y = min(max(point.y, bounds[1]), bounds[3])
            ranked.append(((point.x-x)**2+(point.y-y)**2, handle, value))
        return tuple(value for _, _, value in sorted(ranked)[:count])

    def verifyAgainst(self, items: Sequence[tuple[Sequence[Any], Any]]) -> Mapping[str, Any]:
        expected = tuple(sorted(((_bounds(bounds, "index.verifyAgainst"), value)
                                 for bounds, value in items), key=repr))
        observed = tuple(sorted((item for _, item in self._items.items()), key=repr))
        return MappingProxyType({"valid": observed == expected,
                                 "indexedCount": len(observed), "scanCount": len(expected)})


class RTree:
    @staticmethod
    def new(options: Mapping[str, Any]) -> SpatialIndex:
        return SpatialIndex("rtree", options)


class KdTree:
    @staticmethod
    def from_(points: Sequence[Point2], options: Mapping[str, Any]) -> SpatialIndex:
        values = _limit(points, MAX_INDEX_ITEMS, "KdTree.from")
        index = SpatialIndex("kdtree", options)
        for point in values:
            _require(isinstance(point, Point2), "NEBO-G042-INDEX-POINT", "KdTree.from")
            index.insert((point.x, point.y, point.x, point.y), point)
        return index


@dataclass(frozen=True)
class Crs:
    identifier: str
    axisOrder: str
    units: str
    definitionVersion: str

    @staticmethod
    def parse(identifier: str) -> "Crs":
        normalized = identifier.upper()
        if normalized == "EPSG:4326":
            return Crs(normalized, "latitude-longitude", "degree", "EPSG-10.076")
        if normalized == "EPSG:3857":
            return Crs(normalized, "easting-northing", "metre", "EPSG-10.076")
        raise SpatialError("NEBO-G042-CRS-UNSUPPORTED", "Crs.parse")


@dataclass(frozen=True)
class GeoCoordinate(_GeometryEvidence):
    latitude: float
    longitude: float
    altitude: float
    precision: PrecisionModel = PrecisionModel("filtered", 1e-9)
    crs: str = "EPSG:4326@EPSG-10.076"
    units: str = "degree/metre"

    @staticmethod
    def of(latitude: Any, longitude: Any, altitude: Any) -> "GeoCoordinate":
        lat = _finite(latitude, "GeoCoordinate.of")
        lon = _finite(longitude, "GeoCoordinate.of")
        alt = _finite(altitude, "GeoCoordinate.of")
        _require(-90 <= lat <= 90 and -180 <= lon <= 180,
                 "NEBO-G042-GEO-RANGE", "GeoCoordinate.of")
        return GeoCoordinate(lat, lon, alt)

    def distance(self, other: "GeoCoordinate", model: str) -> float:
        _require(isinstance(other, GeoCoordinate) and model == "WGS84_SPHERE_V1",
                 "NEBO-G042-GEO-MODEL", "geo.distance")
        phi1, phi2 = math.radians(self.latitude), math.radians(other.latitude)
        dphi = phi2-phi1
        dlambda = math.radians(other.longitude-self.longitude)
        a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
        return 2*EARTH_RADIUS_METRES*math.asin(math.sqrt(a))

    def bearingTo(self, other: "GeoCoordinate") -> float:
        _require(isinstance(other, GeoCoordinate), "NEBO-G042-GEO-POINT", "geo.bearingTo")
        phi1, phi2 = math.radians(self.latitude), math.radians(other.latitude)
        dlambda = math.radians(other.longitude-self.longitude)
        y = math.sin(dlambda)*math.cos(phi2)
        x = math.cos(phi1)*math.sin(phi2)-math.sin(phi1)*math.cos(phi2)*math.cos(dlambda)
        return (math.degrees(math.atan2(y, x))+360) % 360

    def buffer(self, distance: Any, options: Mapping[str, Any]) -> "GeoPolygon":
        metres = _finite(distance, "geo.buffer")
        _require(metres > 0 and isinstance(options, Mapping),
                 "NEBO-G042-BUFFER", "geo.buffer")
        segments = options.get("segments", 16)
        _require(isinstance(segments, int) and not isinstance(segments, bool) and
                 8 <= segments <= 128,
                 "NEBO-G042-BUFFER-SEGMENTS", "geo.buffer")
        points = []
        for index in range(segments):
            angle = 2*math.pi*index/segments
            dlat = math.degrees(metres*math.cos(angle)/EARTH_RADIUS_METRES)
            dlon = math.degrees(metres*math.sin(angle)/(EARTH_RADIUS_METRES*math.cos(math.radians(self.latitude))))
            points.append(GeoCoordinate.of(self.latitude+dlat, self.longitude+dlon, self.altitude))
        points.append(points[0])
        return GeoPolygon(tuple(points), PrecisionModel.approximate(metres/1000))


@dataclass(frozen=True)
class ProjectedPoint:
    x: float
    y: float
    z: float
    crs: Crs
    precision: PrecisionModel


class Projection:
    @staticmethod
    def convert(point: Any, from_: Crs, to: Crs) -> Any:
        operation = "Projection.convert"
        _require(isinstance(from_, Crs) and isinstance(to, Crs),
                 "NEBO-G042-CRS", operation)
        if from_.identifier == to.identifier:
            return point
        if isinstance(point, GeoCoordinate) and from_.identifier == "EPSG:4326" and to.identifier == "EPSG:3857":
            _require(abs(point.latitude) <= 85.05112878, "NEBO-G042-PROJECTION-RANGE", operation)
            x = WEB_MERCATOR_RADIUS_METRES*math.radians(point.longitude)
            y = WEB_MERCATOR_RADIUS_METRES*math.log(math.tan(math.pi/4+math.radians(point.latitude)/2))
            return ProjectedPoint(x, y, point.altitude, to, PrecisionModel.filtered(0.001))
        if isinstance(point, ProjectedPoint) and from_.identifier == "EPSG:3857" and to.identifier == "EPSG:4326":
            lon = math.degrees(point.x/WEB_MERCATOR_RADIUS_METRES)
            lat = math.degrees(2*math.atan(math.exp(point.y/WEB_MERCATOR_RADIUS_METRES))-math.pi/2)
            return GeoCoordinate.of(lat, lon, point.z)
        raise SpatialError("NEBO-G042-PROJECTION-UNSUPPORTED", operation)


@dataclass(frozen=True)
class GeoPolygon:
    points: tuple[GeoCoordinate, ...]
    precision: PrecisionModel = PrecisionModel("filtered", 1e-9)

    def contains(self, point: GeoCoordinate) -> bool:
        _require(isinstance(point, GeoCoordinate) and len(self.points) >= 4 and
                 self.points[0] == self.points[-1], "NEBO-G042-GEO-POLYGON", "GeoPolygon.contains")
        inside = False
        for a, b in zip(self.points, self.points[1:]):
            if (a.latitude > point.latitude) != (b.latitude > point.latitude):
                longitude = a.longitude + (point.latitude-a.latitude)*(b.longitude-a.longitude)/(b.latitude-a.latitude)
                if longitude > point.longitude:
                    inside = not inside
        return inside


@dataclass(frozen=True)
class GeoPath:
    points: tuple[GeoCoordinate, ...]

    def length(self, model: str) -> float:
        _require(len(self.points) >= 2, "NEBO-G042-GEO-PATH", "GeoPath.length")
        return sum(left.distance(right, model) for left, right in zip(self.points, self.points[1:]))


@dataclass(frozen=True)
class GraphEdge:
    source: str
    target: str
    cost: float
    restricted: bool = False


class SpatialGraph:
    def __init__(self, nodes: Mapping[str, Point2], edges: Sequence[GraphEdge], directed: bool) -> None:
        self.nodes = MappingProxyType(dict(nodes))
        self.edges = tuple(edges)
        self.directed = directed

    @staticmethod
    def from_(features: Mapping[str, Any], policy: Mapping[str, Any]) -> "SpatialGraph":
        operation = "SpatialGraph.fromFeatures"
        _require(isinstance(features, Mapping) and isinstance(policy, Mapping) and
                 policy.get("costUnits") == "metre" and isinstance(policy.get("directed"), bool),
                 "NEBO-G042-GRAPH-POLICY", operation)
        nodes = dict(features.get("nodes", {}))
        edges_raw = tuple(features.get("edges", ()))
        _require(0 < len(nodes) <= MAX_ROUTE_NODES and len(edges_raw) <= MAX_ROUTE_EDGES and
                 all(isinstance(name, str) and isinstance(point, Point2) for name, point in nodes.items()),
                 "NEBO-G042-GRAPH", operation)
        edges: list[GraphEdge] = []
        for raw in edges_raw:
            _require(isinstance(raw, Sequence) and len(raw) in {3, 4},
                     "NEBO-G042-GRAPH-EDGE", operation)
            source, target = raw[0], raw[1]
            cost = _finite(raw[2], operation)
            _require(len(raw) == 3 or isinstance(raw[3], bool),
                     "NEBO-G042-GRAPH-EDGE", operation)
            restricted = raw[3] if len(raw) == 4 else False
            _require(source in nodes and target in nodes and source != target and cost > 0,
                     "NEBO-G042-GRAPH-EDGE", operation)
            edges.append(GraphEdge(source, target, cost, restricted))
        return SpatialGraph(nodes, edges, bool(policy["directed"]))

    def _adjacent(self, disabled: frozenset[tuple[str, str]] = frozenset()) -> Mapping[str, tuple[GraphEdge, ...]]:
        table: dict[str, list[GraphEdge]] = {name: [] for name in self.nodes}
        for edge in self.edges:
            edge_disabled = ((edge.source, edge.target) in disabled or
                             (not self.directed and (edge.target, edge.source) in disabled))
            if not edge.restricted and not edge_disabled:
                table[edge.source].append(edge)
                if not self.directed:
                    table[edge.target].append(GraphEdge(edge.target, edge.source, edge.cost))
        return MappingProxyType({name: tuple(sorted(edges, key=lambda edge: (edge.target, edge.cost)))
                                 for name, edges in table.items()})


class RouteResult:
    def __init__(self, graph: SpatialGraph, nodes: Sequence[str], total: float, model: str) -> None:
        self._graph = graph
        self._nodes = tuple(nodes)
        self._total = total
        self._model = model

    def alternatives(self, count: int, diversity: Any) -> tuple["RouteResult", ...]:
        value = _finite(diversity, "route.alternatives")
        _require(isinstance(count, int) and not isinstance(count, bool) and
                 0 < count <= 8 and 0 <= value <= 1,
                 "NEBO-G042-ROUTE-ALTERNATIVES", "route.alternatives")
        results: list[RouteResult] = []
        seen: set[tuple[str, ...]] = set()
        for edge in zip(self._nodes, self._nodes[1:]):
            try:
                candidate = Route._find(self._graph, self._nodes[0], self._nodes[-1], self._model,
                                        frozenset((edge,)))
            except SpatialError:
                continue
            original_edges = set(zip(self._nodes, self._nodes[1:]))
            candidate_edges = set(zip(candidate._nodes, candidate._nodes[1:]))
            overlap = len(original_edges & candidate_edges)/max(1, len(original_edges))
            if (candidate._nodes != self._nodes and candidate._nodes not in seen and
                    1.0-overlap >= value):
                seen.add(candidate._nodes)
                results.append(candidate)
            if len(results) == count:
                break
        return tuple(results)

    def costs(self) -> Mapping[str, Any]:
        return MappingProxyType({"model": self._model, "total": self._total, "units": "metre"})

    def instructions(self) -> tuple[str, ...]:
        return tuple(f"continue:{source}->{target}" for source, target in zip(self._nodes, self._nodes[1:]))

    def geometry(self) -> Polyline:
        return Polyline.from_(tuple(self._graph.nodes[name] for name in self._nodes))

    def replan(self, changes: Mapping[str, Any]) -> "RouteResult":
        _require(isinstance(changes, Mapping) and set(changes) <= {"disabledEdges"},
                 "NEBO-G042-REPLAN", "route.replan")
        disabled = frozenset(tuple(edge) for edge in changes.get("disabledEdges", ()))
        return Route._find(self._graph, self._nodes[0], self._nodes[-1], self._model, disabled)


class Route:
    @staticmethod
    def find(start: str, end: str, costModel: Mapping[str, Any], graph: SpatialGraph | None = None) -> RouteResult:
        _require(isinstance(graph, SpatialGraph), "NEBO-G042-GRAPH", "Route.find")
        _require(isinstance(costModel, Mapping) and costModel.get("name") == "distance" and
                 costModel.get("units") == "metre", "NEBO-G042-COST-MODEL", "Route.find")
        return Route._find(graph, start, end, "distance")

    @staticmethod
    def _find(graph: SpatialGraph, start: str, end: str, model: str,
              disabled: frozenset[tuple[str, str]] = frozenset()) -> RouteResult:
        _require(start in graph.nodes and end in graph.nodes and start != end,
                 "NEBO-G042-ROUTE-ENDPOINT", "Route.find")
        queue: list[tuple[float, tuple[str, ...], str]] = [(0.0, (start,), start)]
        best = {start: 0.0}
        adjacent = graph._adjacent(disabled)
        while queue:
            cost, path, node = heapq.heappop(queue)
            if node == end:
                return RouteResult(graph, path, cost, model)
            if cost != best.get(node):
                continue
            for edge in adjacent[node]:
                candidate = cost+edge.cost
                _require(math.isfinite(candidate) and candidate <= 1e15,
                         "NEBO-G042-ROUTE-OVERFLOW", "Route.find")
                if candidate < best.get(edge.target, math.inf):
                    best[edge.target] = candidate
                    heapq.heappush(queue, (candidate, path+(edge.target,), edge.target))
        raise SpatialError("NEBO-G042-ROUTE-DISCONNECTED", "Route.find")


@dataclass(frozen=True)
class MatchResult:
    nodeIds: tuple[str, ...]
    distances: tuple[float, ...]
    maximumDistance: float

    def confidence(self) -> float:
        if not self.distances:
            return 0.0
        return max(0.0, 1.0-sum(self.distances)/(len(self.distances)*self.maximumDistance))


class MapMatcher:
    @staticmethod
    def match(observations: Sequence[Point2], graph: SpatialGraph,
              options: Mapping[str, Any]) -> MatchResult:
        operation = "MapMatcher.match"
        values = _limit(observations, 1024, operation)
        _require(isinstance(graph, SpatialGraph) and isinstance(options, Mapping),
                 "NEBO-G042-MAP-MATCH", operation)
        maximum = _finite(options.get("maximumDistance"), operation)
        _require(maximum > 0, "NEBO-G042-MAP-MATCH", operation)
        node_ids: list[str] = []
        distances: list[float] = []
        for observation in values:
            ranked = sorted((geometry.distance(observation, point), name)
                            for name, point in graph.nodes.items())
            _require(ranked[0][0] <= maximum, "NEBO-G042-MAP-MATCH-DISTANCE", operation)
            distances.append(ranked[0][0])
            node_ids.append(ranked[0][1])
        return MatchResult(tuple(node_ids), tuple(distances), maximum)


_POINT_RE = re.compile(r"POINT\((-?\d+) (-?\d+)\)\Z")
_LINE_RE = re.compile(r"LINESTRING\(([^()]*)\)\Z")
_POLYGON_RE = re.compile(r"POLYGON\(\(([^()]*)\)\)\Z")
_WKT_COORDINATE_RE = re.compile(r"-?\d+ -?\d+\Z")


def _wkt_points(payload: str, operation: str) -> tuple[Point2, ...]:
    items = payload.split(",")
    _require(bool(payload) and all(_WKT_COORDINATE_RE.fullmatch(item) for item in items),
             "NEBO-G042-CODEC-SYNTAX", operation)
    try:
        return tuple(Point2.of(*map(int, item.split(" "))) for item in items)
    except (ValueError, OverflowError):
        raise SpatialError("NEBO-G042-CODEC-SYNTAX", operation) from None


class GeometryCodec:
    @staticmethod
    def read(stream: Any, format: str, limits: Mapping[str, Any]) -> _GeometryEvidence:
        operation = "GeometryCodec.read"
        _require(format == "WKT_BOUNDED_V1" and isinstance(limits, Mapping),
                 "NEBO-G042-CODEC-FORMAT", operation)
        maximum = limits.get("maximumBytes", MAX_CODEC_BYTES)
        _require(isinstance(maximum, int) and not isinstance(maximum, bool) and
                 0 < maximum <= MAX_CODEC_BYTES,
                 "NEBO-G042-CODEC-LIMIT", operation)
        text = stream.read() if hasattr(stream, "read") else stream
        _require(isinstance(text, str) and len(text.encode("utf-8")) <= maximum,
                 "NEBO-G042-CODEC-LIMIT", operation)
        match = _POINT_RE.fullmatch(text)
        if match:
            return _wkt_points(" ".join(match.groups()), operation)[0]
        match = _LINE_RE.fullmatch(text)
        if match:
            return Polyline.from_(_wkt_points(match.group(1), operation))
        match = _POLYGON_RE.fullmatch(text)
        if match:
            ring = _wkt_points(match.group(1), operation)
            return Polygon.from_((ring,), {"boundary": "include", "precision": "exact"})
        raise SpatialError("NEBO-G042-CODEC-SYNTAX", operation)

    @staticmethod
    def write(geometry_: _GeometryEvidence, format: str, options: Mapping[str, Any]) -> str:
        operation = "GeometryCodec.write"
        _require(format == "WKT_BOUNDED_V1" and isinstance(options, Mapping) and
                 options.get("canonical") is True, "NEBO-G042-CODEC-FORMAT", operation)
        def number(value: Fraction) -> str:
            _require(value.denominator == 1, "NEBO-G042-CODEC-PRECISION", operation)
            return str(value.numerator)
        if isinstance(geometry_, Point2):
            return f"POINT({number(geometry_.x)} {number(geometry_.y)})"
        if isinstance(geometry_, Polyline):
            return "LINESTRING("+",".join(f"{number(p.x)} {number(p.y)}" for p in geometry_.points)+")"
        if isinstance(geometry_, Polygon) and len(geometry_.rings) == 1:
            return "POLYGON(("+",".join(f"{number(p.x)} {number(p.y)}" for p in geometry_.rings[0])+"))"
        raise SpatialError("NEBO-G042-CODEC-KIND", operation)


class SpatialDataset:
    def __init__(self, geometries: Sequence[_GeometryEvidence]) -> None:
        self.geometries = _limit(geometries, MAX_INDEX_ITEMS, "SpatialDataset")

    def index(self, options: Mapping[str, Any]) -> SpatialIndex:
        index = RTree.new(options)
        for geometry_ in self.geometries:
            if isinstance(geometry_, Point2):
                bounds = (geometry_.x, geometry_.y, geometry_.x, geometry_.y)
            elif isinstance(geometry_, Polygon):
                points = geometry_.rings[0]
                bounds = (min(p.x for p in points), min(p.y for p in points),
                          max(p.x for p in points), max(p.y for p in points))
            else:
                raise SpatialError("NEBO-G042-DATASET-KIND", "SpatialDataset.index")
            index.insert(bounds, geometry_)
        return index
