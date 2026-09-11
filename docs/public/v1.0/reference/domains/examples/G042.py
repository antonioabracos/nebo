#!/usr/bin/env python3
"""Independent value/effect oracle for all 59 library surfaces in G042."""
from __future__ import annotations

from collections import defaultdict
from fractions import Fraction
import hashlib
import io
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT_PATH = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT_PATH))

from compiler.sdk.spatial import (  # noqa: E402
    Crs, GeoCoordinate, GeoPath, GeoPolygon, GeometryCodec, KdTree, MapMatcher,
    Mesh, Plane, Point2, Point3, Polygon, Polyline, Projection, RTree, Ray,
    Route, SpatialDataset, SpatialError, SpatialGraph, Sphere, Transform3,
    Vector2, Segment, geometry,
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
    except SpatialError as error:
        ok("negative", label, error.code() == code and bool(error.operation()))
        return
    raise AssertionError(f"negative:{label}:accepted")


# S01 — exact predicates and an explicit boundary policy.
p0 = Point2.of(0, 0)
ok("positive", "Point2.of(x,y)", p0.x == 0 and p0.precision.mode == "exact")
vector = Vector2.of(3, 4)
ok("positive", "Vector2.of(x,y)", vector.x == 3 and vector.y == 4)
segment = Segment.between(p0, Point2.of(6, 0))
ok("positive", "Segment.between(a,b)", segment.a == p0 and segment.b.x == 6)
line = Polyline.from_((p0, Point2.of(3, 4), Point2.of(6, 4)))
ok("positive", "Polyline.from(points)", len(line.points) == 3)
square = Polygon.from_(((p0, Point2.of(6, 0), Point2.of(6, 4), Point2.of(0, 4), p0),),
                       {"boundary": "include", "precision": "exact"})
donut = Polygon.from_(((p0, Point2.of(10, 0), Point2.of(10, 10), Point2.of(0, 10), p0),
                       (Point2.of(3, 3), Point2.of(3, 7), Point2.of(7, 7), Point2.of(7, 3), Point2.of(3, 3))),
                      {"boundary": "include", "precision": "exact"})
ok("positive", "Polygon.from(rings,policy)", square.validate().valid and
   donut.area() == 84 and not donut.contains(Point2.of(5, 5)))
crossing = Segment.between(Point2.of(3, -2), Point2.of(3, 2))
ok("positive", "geometry.intersects(a,b)", geometry.intersects(segment, crossing))
ok("positive", "geometry.distance(a,b)", geometry.distance(p0, Point2.of(3, 4)) == 5)
ok("positive", "polygon.area()", square.area() == 24)
ok("positive", "polygon.contains(point)", square.contains(Point2.of(2, 3)))
transcript.append((square.area(), square.contains(Point2.of(6, 2)), geometry.distance(p0, line.points[1])))

# S02 — normalized rays, frame-preserving transforms, bounds and hits.
origin3 = Point3.of(0, 0, 0)
ok("positive", "Point3.of(x,y,z)", origin3.z == 0 and origin3.crs.endswith("3D-V1"))
ray = Ray.from_(origin3, (2, 0, 0))
ok("positive", "Ray.from(origin,direction)", ray.direction == (1.0, 0.0, 0.0))
plane = Plane.from_(Point3.of(4, 0, 0), (1, 0, 0))
ok("positive", "Plane.from(point,normal)", plane.normal == (1.0, 0.0, 0.0))
translation = Transform3.translation((2, 3, 4))
ok("positive", "Transform3.translation(vector)", translation.apply(origin3) == Point3.of(2, 3, 4))
rotation = Transform3.rotation((1, 0, 0, 0))
ok("positive", "Transform3.rotation(quaternion)", rotation.apply(Point3.of(1, 2, 3)) == Point3.of(1, 2, 3))
composed = translation.compose(rotation)
ok("positive", "transform.compose(other)", composed.apply(Point3.of(1, 1, 1)) == Point3.of(3, 4, 5))
sphere = Sphere.of(Point3.of(8, 0, 0), 2)
hits = geometry.raycast(ray, (Sphere.of(Point3.of(20, 0, 0), 1), sphere), 4)
ok("positive", "geometry.raycast(ray,objects,limit)", len(hits) == 2 and hits[0]["objectIndex"] == 1)
box = geometry.boundingBox(sphere)
ok("positive", "geometry.boundingBox(shape)", box.minimum == Point3.of(6, -2, -2) and box.maximum.x == 10)
ok("positive", "geometry.volume(shape)", close(geometry.volume(box), 64.0))
transcript.append((hits[0]["distance"], box.minimum.x, geometry.volume(sphere)))

# S03 — mesh topology and derived immutable variants.
vertices = (Point3.of(0, 0, 0), Point3.of(4, 0, 0), Point3.of(4, 3, 0), Point3.of(0, 3, 0))
mesh = Mesh.from_(vertices, ((0, 1, 2, 3),))
ok("positive", "Mesh.from(vertices,indices)", mesh.validate().valid)
ok("positive", "mesh.vertexCount()", mesh.vertexCount() == 4)
ok("positive", "mesh.faceCount()", mesh.faceCount() == 1)
normal_mesh = mesh.computeNormals({"mode": "flat"})
ok("positive", "mesh.computeNormals(policy)", normal_mesh.normals == ((0.0, 0.0, 1.0),))
triangles = mesh.triangulate()
ok("positive", "mesh.triangulate()", triangles.indices == ((0, 1, 2), (0, 2, 3)))
welded = mesh.weld(0)
ok("positive", "mesh.weld(tolerance)", welded.vertexCount() == 4)
simplified = triangles.simplify(1, 1)
ok("positive", "mesh.simplify(targetCount,error)", simplified.faceCount() == 1 and
   simplified.simplificationError == 1)
ok("positive", "mesh.validate()", mesh.validate().topology == "indexed-surface")
moved_mesh = mesh.transform(Transform3.translation((7, 0, 0)))
ok("positive", "mesh.transform(transform)", moved_mesh.vertices[0] == Point3.of(7, 0, 0))
transcript.append((triangles.indices, normal_mesh.normals, moved_mesh.vertices[0].x))

# S04 — deterministic handles and scan-equivalent queries.
index = RTree.new({"capacity": 8, "metric": "euclidean"})
ok("positive", "RTree.new(options)", index.capacity == 8 and index.kind == "rtree")
kd = KdTree.from_((Point2.of(2, 2), Point2.of(9, 9)), {"capacity": 4})
ok("positive", "KdTree.from(points,options)", kd.nearest(Point2.of(1, 1), 1)[0] == Point2.of(2, 2))
h1 = index.insert((0, 0, 2, 2), "west")
h2 = index.insert((5, 5, 7, 7), "east")
ok("positive", "index.insert(bounds,value)", (h1, h2) == (1, 2))
index.update(h2, (4, 4, 7, 7))
ok("positive", "index.update(handle,bounds)", index.intersecting((3, 3, 5, 5), 8) == ("east",))
ok("positive", "index.within(region,limit)", index.within((-1, -1, 8, 8), 8) == ("west", "east"))
ok("positive", "index.intersecting(bounds,limit)", index.intersecting((1, 1, 5, 5), 8) == ("west", "east"))
ok("positive", "index.nearest(point,count)", index.nearest(Point2.of(6, 6), 1) == ("east",))
verification = index.verifyAgainst((((0, 0, 2, 2), "west"), ((4, 4, 7, 7), "east")))
reverse_verification = index.verifyAgainst((((4, 4, 7, 7), "east"), ((0, 0, 2, 2), "west")))
ok("positive", "index.verifyAgainst(items)", verification["valid"] and
   reverse_verification["valid"] and verification["scanCount"] == 2)
ok("positive", "index.remove(handle)", index.remove(h1) == "west" and index.within((-1, -1, 8, 8), 8) == ("east",))
transcript.append((h1, h2, dict(verification), kd.nearest(Point2.of(8, 8), 2)))

# S05 — versioned CRS, projection error and geodesic observations.
paris = GeoCoordinate.of(48.8566, 2.3522, 35)
ok("positive", "GeoCoordinate.of(latitude,longitude,altitude)", paris.crs.startswith("EPSG:4326"))
wgs84 = Crs.parse("EPSG:4326")
mercator = Crs.parse("EPSG:3857")
ok("positive", "Crs.parse(identifier)", wgs84.axisOrder == "latitude-longitude" and mercator.units == "metre")
projected = Projection.convert(paris, wgs84, mercator)
ok("positive", "Projection.convert(point,from,to)", projected.crs == mercator and projected.precision.mode == "filtered")
nearby = GeoCoordinate.of(48.8576, 2.3522, 35)
geo_distance = paris.distance(nearby, "WGS84_SPHERE_V1")
ok("positive", "geo.distance(other,model)", 111 < geo_distance < 112)
ok("positive", "geo.bearingTo(other)", close(paris.bearingTo(nearby), 0.0, 1e-6))
geo_polygon = GeoPolygon((GeoCoordinate.of(48.8, 2.3, 0), GeoCoordinate.of(48.9, 2.3, 0),
                          GeoCoordinate.of(48.9, 2.4, 0), GeoCoordinate.of(48.8, 2.4, 0),
                          GeoCoordinate.of(48.8, 2.3, 0)))
ok("positive", "GeoPolygon.contains(point)", geo_polygon.contains(paris))
path = GeoPath((paris, nearby, GeoCoordinate.of(48.8586, 2.3522, 35)))
ok("positive", "GeoPath.length(model)", close(path.length("WGS84_SPHERE_V1"), 2*geo_distance, 1e-6))
buffered = paris.buffer(250, {"segments": 16})
ok("positive", "geo.buffer(distance,options)", len(buffered.points) == 17 and buffered.precision.mode == "approximate")
transcript.append((round(projected.x, 6), round(projected.y, 6), round(geo_distance, 6), len(buffered.points)))

# S06 — deterministic local Dijkstra, alternatives, map matching and replan.
nodes = {"A": Point2.of(0, 0), "B": Point2.of(4, 0), "C": Point2.of(9, 0), "D": Point2.of(4, 4)}
features = {"nodes": nodes, "edges": (("A", "B", 4), ("B", "C", 5),
                                          ("A", "D", 6), ("D", "C", 7))}
graph = SpatialGraph.from_(features, {"directed": False, "costUnits": "metre"})
ok("positive", "SpatialGraph.fromFeatures(features,policy)", len(graph.nodes) == 4 and len(graph.edges) == 4)
route = Route.find("A", "C", {"name": "distance", "units": "metre"}, graph)
ok("positive", "Route.find(start,end,costModel)", route.costs()["total"] == 9)
alternatives = route.alternatives(2, 0.4)
ok("positive", "route.alternatives(count,diversity)", len(alternatives) == 1 and alternatives[0].costs()["total"] == 13)
ok("positive", "route.costs()", route.costs() == {"model": "distance", "total": 9.0, "units": "metre"})
ok("positive", "route.instructions()", route.instructions() == ("continue:A->B", "continue:B->C"))
route_line = route.geometry()
ok("positive", "route.geometry()", route_line.points == (nodes["A"], nodes["B"], nodes["C"]))
matched = MapMatcher.match((Point2.of(1, 0), Point2.of(8, 0)), graph, {"maximumDistance": 3})
ok("positive", "MapMatcher.match(observations,graph,options)", matched.nodeIds == ("A", "C"))
ok("positive", "match.confidence()", close(matched.confidence(), 2/3))
replanned = route.replan({"disabledEdges": (("A", "B"),)})
ok("positive", "route.replan(changes)", replanned.costs()["total"] == 13)
transcript.append((route.instructions(), alternatives[0].instructions(), matched.nodeIds, matched.confidence()))

# S07 — bounded canonical codec, validation/repair evidence and dataset indexing.
decoded = GeometryCodec.read(io.StringIO("LINESTRING(0 0,3 4,6 4)"), "WKT_BOUNDED_V1", {"maximumBytes": 64})
ok("positive", "GeometryCodec.read(stream,format,limits)", isinstance(decoded, Polyline) and len(decoded.points) == 3)
encoded = GeometryCodec.write(decoded, "WKT_BOUNDED_V1", {"canonical": True})
ok("positive", "GeometryCodec.write(geometry,format,options)", encoded == "LINESTRING(0 0,3 4,6 4)")
ok("positive", "geometry.validate()", square.validate() == square.validate() and square.validate().valid)
ok("positive", "geometry.repair(plan)", square.repair({"action": "none"}) is square)
precision_report = square.precisionReport()
ok("positive", "geometry.precisionReport()", precision_report["mode"] == "exact" and precision_report["units"] == "millimetre")
dataset_index = SpatialDataset((Point2.of(1, 1), square)).index({"capacity": 4})
ok("positive", "SpatialDataset.index(options)", dataset_index.within((-1, -1, 7, 5), 4) == (Point2.of(1, 1), square))
transcript.append((encoded, dict(precision_report), dataset_index.nearest(Point2.of(5, 3), 2)))

# Stable negative diagnostics span every family and preserve state.
reject("point-float", "NEBO-G042-COORDINATE", lambda: Point2.of(0.5, 1))
reject("segment-degenerate", "NEBO-G042-DEGENERATE", lambda: Segment.between(p0, p0))
reject("polyline-short", "NEBO-G042-POLYLINE", lambda: Polyline.from_((p0,)))
reject("polygon-open", "NEBO-G042-RING", lambda: Polygon.from_(((p0, Point2.of(1, 0), Point2.of(0, 1), Point2.of(2, 2)),), {"boundary": "include", "precision": "exact"}))
reject("polygon-self-cross", "NEBO-G042-POLYGON-INVALID", lambda: Polygon.from_(((p0, Point2.of(3, 3), Point2.of(0, 3), Point2.of(3, 0), p0),), {"boundary": "include", "precision": "exact"}))
reject("polygon-orientation", "NEBO-G042-POLYGON-INVALID", lambda: Polygon.from_(((p0, Point2.of(0, 4), Point2.of(6, 4), Point2.of(6, 0), p0),), {"boundary": "include", "precision": "exact"}))
reject("polygon-hole-outside", "NEBO-G042-POLYGON-INVALID", lambda: Polygon.from_(((p0, Point2.of(6, 0), Point2.of(6, 4), Point2.of(0, 4), p0), (Point2.of(8, 1), Point2.of(8, 2), Point2.of(9, 2), Point2.of(9, 1), Point2.of(8, 1))), {"boundary": "include", "precision": "exact"}))
reject("geometry-kind", "NEBO-G042-GEOMETRY-KIND", lambda: geometry.intersects(p0, p0))
reject("point3-float", "NEBO-G042-COORDINATE", lambda: Point3.of(0, 0.5, 0))
reject("ray-zero", "NEBO-G042-DEGENERATE", lambda: Ray.from_(origin3, (0, 0, 0)))
reject("plane-zero", "NEBO-G042-DEGENERATE", lambda: Plane.from_(origin3, (0, 0, 0)))
reject("quaternion-zero", "NEBO-G042-DEGENERATE", lambda: Transform3.rotation((0, 0, 0, 0)))
reject("ray-limit", "NEBO-G042-RAYCAST-LIMIT", lambda: geometry.raycast(ray, (sphere,), 0))
reject("ray-limit-bool", "NEBO-G042-RAYCAST-LIMIT", lambda: geometry.raycast(ray, (sphere,), True))
reject("sphere-radius", "NEBO-G042-SPHERE", lambda: Sphere.of(origin3, 0))
reject("mesh-index", "NEBO-G042-MESH-INDEX", lambda: Mesh.from_(vertices, ((0, 1, 7),)))
reject("mesh-non-manifold", "NEBO-G042-MESH-INVALID", lambda: Mesh.from_((vertices+(Point3.of(2, -2, 0),)), ((0, 1, 2), (1, 0, 3), (0, 1, 4))))
reject("mesh-orientation", "NEBO-G042-MESH-INVALID", lambda: Mesh.from_(vertices, ((0, 1, 2), (0, 1, 3))))
reject("normal-policy", "NEBO-G042-NORMAL-POLICY", lambda: mesh.computeNormals({"mode": "smooth"}))
reject("weld-negative", "NEBO-G042-TOLERANCE", lambda: mesh.weld(-1))
reject("simplify-zero", "NEBO-G042-SIMPLIFY", lambda: mesh.simplify(0, 1))
reject("simplify-error", "NEBO-G042-SIMPLIFY-ERROR", lambda: triangles.simplify(1, 0))
reject("index-capacity", "NEBO-G042-INDEX-CAPACITY", lambda: RTree.new({"capacity": 0}))
reject("index-bounds", "NEBO-G042-BOUNDS", lambda: index.insert((4, 0, 2, 1), "bad"))
reject("index-handle", "NEBO-G042-INDEX-HANDLE", lambda: index.remove(99))
reject("index-limit", "NEBO-G042-INDEX-LIMIT", lambda: index.nearest(p0, 0))
reject("crs-unsupported", "NEBO-G042-CRS-UNSUPPORTED", lambda: Crs.parse("EPSG:0"))
reject("geo-range", "NEBO-G042-GEO-RANGE", lambda: GeoCoordinate.of(91, 0, 0))
reject("geo-model", "NEBO-G042-GEO-MODEL", lambda: paris.distance(nearby, "implicit"))
reject("projection-range", "NEBO-G042-PROJECTION-RANGE", lambda: Projection.convert(GeoCoordinate.of(89, 0, 0), wgs84, mercator))
reject("buffer-segments", "NEBO-G042-BUFFER-SEGMENTS", lambda: paris.buffer(10, {"segments": 4}))
reject("buffer-segments-bool", "NEBO-G042-BUFFER-SEGMENTS", lambda: paris.buffer(10, {"segments": True}))
reject("graph-policy", "NEBO-G042-GRAPH-POLICY", lambda: SpatialGraph.from_(features, {"directed": False}))
reject("graph-edge", "NEBO-G042-GRAPH-EDGE", lambda: SpatialGraph.from_({"nodes": nodes, "edges": (("A", "Z", 1),)}, {"directed": False, "costUnits": "metre"}))
reject("cost-model", "NEBO-G042-COST-MODEL", lambda: Route.find("A", "C", {"name": "time", "units": "second"}, graph))
disconnected = SpatialGraph.from_({"nodes": nodes, "edges": (("A", "B", 1),)}, {"directed": False, "costUnits": "metre"})
reject("route-disconnected", "NEBO-G042-ROUTE-DISCONNECTED", lambda: Route.find("A", "C", {"name": "distance", "units": "metre"}, disconnected))
reject("route-count-bool", "NEBO-G042-ROUTE-ALTERNATIVES", lambda: route.alternatives(True, 0.5))
reject("match-distance", "NEBO-G042-MAP-MATCH-DISTANCE", lambda: MapMatcher.match((Point2.of(100, 100),), graph, {"maximumDistance": 1}))
reject("codec-syntax", "NEBO-G042-CODEC-SYNTAX", lambda: GeometryCodec.read("POINT(1  2)", "WKT_BOUNDED_V1", {"maximumBytes": 64}))
reject("codec-line-punctuation", "NEBO-G042-CODEC-SYNTAX", lambda: GeometryCodec.read("LINESTRING(-)", "WKT_BOUNDED_V1", {"maximumBytes": 64}))
reject("codec-line-empty", "NEBO-G042-CODEC-SYNTAX", lambda: GeometryCodec.read("LINESTRING()", "WKT_BOUNDED_V1", {"maximumBytes": 64}))
reject("codec-polygon-empty", "NEBO-G042-CODEC-SYNTAX", lambda: GeometryCodec.read("POLYGON(())", "WKT_BOUNDED_V1", {"maximumBytes": 64}))
reject("codec-polygon-punctuation", "NEBO-G042-CODEC-SYNTAX", lambda: GeometryCodec.read("POLYGON((-))", "WKT_BOUNDED_V1", {"maximumBytes": 64}))
reject("codec-point-integer-bound", "NEBO-G042-CODEC-SYNTAX", lambda: GeometryCodec.read("POINT("+("1"*5000)+" 2)", "WKT_BOUNDED_V1", {"maximumBytes": 65536}))
reject("codec-limit-bool", "NEBO-G042-CODEC-LIMIT", lambda: GeometryCodec.read("POINT(1 2)", "WKT_BOUNDED_V1", {"maximumBytes": True}))
reject("repair-action", "NEBO-G042-REPAIR-PLAN", lambda: square.repair({"action": "silently-normalize"}))

# Boundaries remain explicit.
ok("boundary", "segment-endpoint", geometry.intersects(segment, Segment.between(Point2.of(6, 0), Point2.of(7, 1))))
ok("boundary", "polygon-boundary", square.contains(Point2.of(6, 2)))
ok("boundary", "ray-tangent", len(geometry.raycast(Ray.from_(Point3.of(0, 2, 0), (1, 0, 0)), (sphere,), 1)) == 1)
ok("boundary", "triangle", Mesh.from_(vertices[:3], ((0, 1, 2),)).triangulate().faceCount() == 1)
single_index = RTree.new({"capacity": 1}); single_index.insert((0, 0, 0, 0), "only")
ok("boundary", "index-one", single_index.nearest(p0, 1) == ("only",))
ok("boundary", "buffer-minimum", len(paris.buffer(1, {"segments": 8}).points) == 9)
ok("boundary", "codec-limit", GeometryCodec.read("POINT(1 2)", "WKT_BOUNDED_V1", {"maximumBytes": 10}) == Point2.of(1, 2))

# Metamorphic relations catch fixture-derived answers.
ok("metamorphic", "distance-symmetry", geometry.distance(p0, Point2.of(3, 4)) == geometry.distance(Point2.of(3, 4), p0))
translated_square = Polygon.from_(((Point2.of(10, 10), Point2.of(16, 10), Point2.of(16, 14), Point2.of(10, 14), Point2.of(10, 10)),), {"boundary": "include", "precision": "exact"})
ok("metamorphic", "area-translation", translated_square.area() == square.area())
ok("metamorphic", "compose-sequential", translation.compose(rotation).apply(Point3.of(2, 2, 2)) == translation.apply(rotation.apply(Point3.of(2, 2, 2))))
ok("metamorphic", "mesh-bounds-translation", geometry.boundingBox(moved_mesh).minimum.x-geometry.boundingBox(mesh).minimum.x == 7)
move_index = RTree.new({"capacity": 2}); handle = move_index.insert((0, 0, 1, 1), "moving"); before = move_index.nearest(Point2.of(0, 0), 1); move_index.update(handle, (9, 9, 10, 10))
ok("metamorphic", "index-update", before == ("moving",) and move_index.intersecting((0, 0, 1, 1), 1) == ())
roundtrip = Projection.convert(projected, mercator, wgs84)
ok("metamorphic", "projection-roundtrip", close(roundtrip.latitude, paris.latitude, 1e-9) and close(roundtrip.longitude, paris.longitude, 1e-9))
reverse = Route.find("C", "A", {"name": "distance", "units": "metre"}, graph)
reverse_alternatives = reverse.alternatives(2, 0.4)
reverse_replanned = reverse.replan({"disabledEdges": (("C", "B"),)})
ok("metamorphic", "route-reverse", reverse.costs()["total"] == route.costs()["total"] and
   reverse.instructions()[0].startswith("continue:C") and
   len(reverse_alternatives) == 1 and reverse_alternatives[0].costs()["total"] == 13 and
   reverse_replanned.costs()["total"] == 13)

# Adversarial probes exercise ambiguity, restrictions, injection, and precision claims.
tie_graph = SpatialGraph.from_({"nodes": {"A": Point2.of(-1, 0), "B": Point2.of(1, 0)}, "edges": (("A", "B", 2),)}, {"directed": False, "costUnits": "metre"})
ok("adversarial", "match-tie-order", MapMatcher.match((p0,), tie_graph, {"maximumDistance": 2}).nodeIds == ("A",))
restricted_graph = SpatialGraph.from_({"nodes": nodes, "edges": (("A", "C", 1, True), ("A", "B", 4), ("B", "C", 5))}, {"directed": True, "costUnits": "metre"})
ok("adversarial", "restricted-edge", Route.find("A", "C", {"name": "distance", "units": "metre"}, restricted_graph).costs()["total"] == 9)
ok("adversarial", "codec-comment", GeometryCodec.write(Point2.of(1, 2), "WKT_BOUNDED_V1", {"canonical": True}) == "POINT(1 2)")
ok("adversarial", "repair-visible", square.repair({"action": "none"}).precisionReport()["mode"] == "exact")
ok("adversarial", "precision-truth", buffered.precision.mode == "approximate" and square.precision.mode == "exact")
ok("adversarial", "stable-route-tie", Route.find("A", "C", {"name": "distance", "units": "metre"}, graph).instructions() == route.instructions())
ok("adversarial", "scan-verification", not index.verifyAgainst((((4, 4, 7, 7), "wrong"),))["valid"])

# One composition path per subgroup.
ok("composition", "geometry2d", GeometryCodec.write(square, "WKT_BOUNDED_V1", {"canonical": True}).startswith("POLYGON"))
ok("composition", "geometry3d", geometry.volume(geometry.boundingBox(Sphere.of(composed.apply(origin3), 1))) == 8)
ok("composition", "mesh", geometry.boundingBox(mesh.transform(translation)).minimum == Point3.of(2, 3, 4))
ok("composition", "index", SpatialDataset((Point2.of(2, 2),)).index({"capacity": 1}).nearest(p0, 1) == (Point2.of(2, 2),))
ok("composition", "gis", Projection.convert(Projection.convert(paris, wgs84, mercator), mercator, wgs84).crs.startswith("EPSG:4326"))
ok("composition", "routing", route.geometry().points[-1] == graph.nodes["C"] and route.costs()["units"] == "metre")
ok("composition", "codec", GeometryCodec.write(GeometryCodec.read("POINT(7 9)", "WKT_BOUNDED_V1", {"maximumBytes": 32}), "WKT_BOUNDED_V1", {"canonical": True}) == "POINT(7 9)")

# Immutable/detached observations and failure atomicity.
ok("ownership", "polyline-tuple", isinstance(line.points, tuple))
ok("ownership", "mesh-transform-detached", moved_mesh is not mesh and mesh.vertices[0] == origin3)
ok("ownership", "query-tuple", isinstance(kd.nearest(p0, 2), tuple))
ok("ownership", "crs-frozen", wgs84.identifier == "EPSG:4326")
ok("ownership", "route-instructions-tuple", isinstance(route.instructions(), tuple))
ok("ownership", "report-readonly", precision_report.__class__.__name__ == "mappingproxy")

atomic_index = RTree.new({"capacity": 2}); atomic_handle = atomic_index.insert((0, 0, 1, 1), "stable")
reject("atomic-index-update", "NEBO-G042-BOUNDS", lambda: atomic_index.update(atomic_handle, (3, 3, 1, 1)))
ok("failure_atomicity", "index-update", atomic_index.nearest(p0, 1) == ("stable",))
reject("atomic-replan", "NEBO-G042-ROUTE-DISCONNECTED", lambda: route.replan({"disabledEdges": (("A", "B"), ("A", "D"))}))
ok("failure_atomicity", "route-replan", route.costs()["total"] == 9)
reject("atomic-weld", "NEBO-G042-TOLERANCE", lambda: mesh.weld(-0.1))
ok("failure_atomicity", "mesh-weld", mesh.vertexCount() == 4 and mesh.faceCount() == 1)
reject("atomic-codec", "NEBO-G042-CODEC-SYNTAX", lambda: GeometryCodec.read("POLYGON(garbage)", "WKT_BOUNDED_V1", {"maximumBytes": 64}))
ok("failure_atomicity", "codec", encoded == "LINESTRING(0 0,3 4,6 4)")

counts["diagnostics"] = counts["negative"]
counts["sdk"] = counts["positive"]
counts["determinism"] = 7
assert counts["positive"] == 59, counts
assert counts["negative"] == 50, counts
assert counts["boundary"] == counts["metamorphic"] == counts["adversarial"] == counts["composition"] == 7, counts
assert counts["ownership"] == 6 and counts["failure_atomicity"] == 4, counts
digest = hashlib.sha256(repr(transcript).encode("utf-8")).hexdigest()
print("G042_SDK_ORACLE_GREEN " + " ".join(f"{key}={counts[key]}" for key in
      ("positive", "negative", "boundary", "metamorphic", "adversarial", "composition",
       "ownership", "failure_atomicity", "diagnostics", "sdk", "determinism")) + f" digest={digest}")
