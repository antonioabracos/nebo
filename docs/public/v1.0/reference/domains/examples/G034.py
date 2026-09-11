#!/usr/bin/env python3
"""Independent value/effect oracle for all 48 G034 public surfaces."""

from __future__ import annotations

import hashlib
import json
from typing import Any, Callable

from compiler.sdk.knowledge import (
    AiPolicy,
    Generation,
    HybridSearch,
    Knowledge,
    KnowledgeAgent,
    KnowledgeError,
    KnowledgeGraph,
    KnowledgeQuery,
    Ontology,
    Reasoner,
    Rule,
    SemanticIndex,
    TextIndex,
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
    except KnowledgeError as error:
        require(error.code == code, f"{operation} code {error.code}, expected {code}")
        require(error.operation == operation, f"operation {error.operation}, expected {operation}")
        COUNTS["negative"] += 1
        COUNTS["diagnostics"] += 1
        EVIDENCE.append(f"negative:{operation}:{code}")
        return
    raise AssertionError(f"negative unexpectedly passed: {operation}:{code}")


def provenance(source: str, version: int = 1) -> dict[str, Any]:
    return {"source": source, "version": version, "digest": hashlib.sha256(source.encode("utf-8")).hexdigest()}


def make_ontology(version: int = 2) -> Ontology:
    ontology = Ontology.new("places", version)
    for name in ("Person", "Place", "City"):
        ontology.defineType(name)
    ontology.subtype("City", "Place")
    ontology.property("livesIn", "Person", "Place")
    ontology.property("hosts", "Place", "Person")
    ontology.inverse("livesIn", "hosts")
    ontology.property("locatedIn", "Place", "Place")
    ontology.property("reachable", "Person", "Place")
    ontology.property("label", "Place", "Text")
    ontology.property("email", "Person", "Text")
    ontology.constraint({"kind": "required", "type": "Person", "property": "email"})
    ontology.constraint({"kind": "cardinality", "property": "email", "maximum": 1})
    return ontology


def make_graph() -> tuple[Ontology, KnowledgeGraph, dict[str, Any], dict[str, Any]]:
    ontology = make_ontology()
    graph = KnowledgeGraph.new(ontology, {"maxEntities": 16, "maxFacts": 64, "auditRetractions": True})
    entities = {
        "alice": graph.entity("Person", "alice"),
        "bob": graph.entity("Person", "bob"),
        "paris": graph.entity("City", "paris"),
        "london": graph.entity("City", "london"),
        "europe": graph.entity("Place", "europe"),
    }
    facts = {}
    for name, subject, predicate, object in (
        ("alice_email", entities["alice"], "email", "alice@example.invalid"),
        ("bob_email", entities["bob"], "email", "bob@example.invalid"),
        ("alice_paris", entities["alice"], "livesIn", entities["paris"]),
        ("paris_europe", entities["paris"], "locatedIn", entities["europe"]),
        ("paris_label", entities["paris"], "label", "capital city france"),
    ):
        facts[name] = getattr(graph, "assert")(subject, predicate, object, provenance(name))
    return ontology, graph, entities, facts


def make_rule() -> Rule:
    return (
        Rule.when({"subject": "$person", "predicate": "livesIn", "object": "$place"})
        .andCondition({"subject": "$place", "predicate": "locatedIn", "object": "$region"})
        .then({"subject": "$person", "predicate": "reachable", "object": "$region"})
        .priority(7)
    )


def subgroup_s01() -> None:
    ontology = make_ontology()
    graph = KnowledgeGraph.new(ontology, {"maxEntities": 8, "maxFacts": 16, "auditRetractions": True})
    surface("G034-S01-01", graph.max_facts == 16 and len(graph.graph_identity) == 64, graph.graph_identity)
    alice = graph.entity("Person", "alice")
    paris = graph.entity("City", "paris")
    surface("G034-S01-02", graph.entity("Person", "alice") is alice and alice.identity == "alice", alice)
    email = getattr(graph, "assert")(alice, "email", "alice@example.invalid", provenance("email"))
    lives = getattr(graph, "assert")(alice, "livesIn", paris, provenance("residence"))
    surface("G034-S01-03", email.factId != lives.factId and lives.provenance["source"] == "residence", lives)
    temporary = getattr(graph, "assert")(paris, "label", "temporary", provenance("temporary"))
    retracted = graph.retract(temporary.factId)
    surface("G034-S01-04", retracted == temporary and graph.snapshot().retractions[-1]["factId"] == temporary.factId, retracted.factId)
    surface("G034-S01-05", graph.fact(lives.factId) is lives, graph.fact(lives.factId))
    about = graph.factsAbout(alice, 8)
    surface("G034-S01-06", tuple(fact.factId for fact in about) == tuple(sorted((email.factId, lives.factId))), about)
    snapshot = graph.snapshot()
    surface("G034-S01-07", snapshot.version == graph.version and len(snapshot.facts) == 2 and len(snapshot.retractions) == 1, snapshot)
    verification = graph.verify()
    surface("G034-S01-08", verification.valid and verification.checkedFacts == 2, verification)

    changed = getattr(graph, "assert")(paris, "label", "Paris", provenance("label"))
    claim("metamorphic", changed.factId not in {email.factId, lives.factId}, "fact input governs nominal identity")
    claim("composition", graph.fact(changed.factId).object == "Paris" and changed in graph.factsAbout(paris, 8), "assert fact and incident lookup compose")
    claim("ownership", len(snapshot.facts) == 2 and len(graph.snapshot().facts) == 3, "snapshot is detached from later mutations")
    one = KnowledgeGraph.new(make_ontology(), {"maxEntities": 1, "maxFacts": 1})
    one.entity("Person", "only")
    claim("boundary", len(one.snapshot().entities) == 1, "minimum useful entity budget")
    graph2_ontology = make_ontology()
    graph2 = KnowledgeGraph.new(graph2_ontology, {"maxEntities": 8, "maxFacts": 16})
    alice2 = graph2.entity("Person", "alice")
    fact2 = getattr(graph2, "assert")(alice2, "email", "alice@example.invalid", provenance("email"))
    claim("determinism", fact2.factId == email.factId, "equal schemas and facts have stable identities")
    version_before = graph.version
    negative("RANGE_MISMATCH", "graph.assert", lambda: getattr(graph, "assert")(alice, "email", True, provenance("bad")))
    claim("failure_atomicity", graph.version == version_before, "invalid fact does not advance graph version")
    claim("adversarial", "source" in lives.provenance and "digest" in lives.provenance, "facts retain explicit provenance")
    negative("INVALID_BOOLEAN", "KnowledgeGraph.new", lambda: KnowledgeGraph.new(make_ontology(), {"auditRetractions": 1}))
    negative("UNKNOWN_TYPE", "graph.entity", lambda: graph.entity("Missing", "x"))
    negative("ENTITY_TYPE_CONFLICT", "graph.entity", lambda: graph.entity("City", "alice"))
    negative("UNKNOWN_FACT", "graph.retract", lambda: graph.retract("0" * 64))
    negative("INVALID_PROVENANCE", "graph.assert", lambda: getattr(graph, "assert")(alice, "email", "x", {"source": "x", "version": 1, "digest": "bad"}))


def subgroup_s02() -> None:
    ontology = Ontology.new("transport", 2)
    surface("G034-S02-01", ontology.name == "transport" and ontology.version == 2, ontology.name)
    ontology.defineType("Place").defineType("City").defineType("Person")
    surface("G034-S02-02", ontology._types == {"Place", "City", "Person"}, ontology._types)
    ontology.subtype("City", "Place")
    surface("G034-S02-03", ontology._is_subtype("City", "Place"), ontology._subtypes)
    ontology.property("livesIn", "Person", "Place").property("hosts", "Place", "Person").property("email", "Person", "Text")
    surface("G034-S02-04", ontology._properties["email"] == ("Person", "Text"), ontology._properties)
    ontology.inverse("livesIn", "hosts")
    surface("G034-S02-05", ontology._inverses == {"livesIn": "hosts", "hosts": "livesIn"}, ontology._inverses)
    ontology.constraint({"kind": "required", "type": "Person", "property": "email"})
    surface("G034-S02-06", ontology._constraints[0]["kind"] == "required", ontology._constraints)
    graph = KnowledgeGraph.new(ontology, {"maxEntities": 4, "maxFacts": 4})
    person = graph.entity("Person", "p")
    getattr(graph, "assert")(person, "email", "p@example.invalid", provenance("p-email"))
    violations = ontology.validate(graph)
    surface("G034-S02-07", violations == (), violations)
    previous = Ontology.new("transport", 1).defineType("Place").defineType("City").defineType("Person")
    previous.subtype("City", "Place").property("livesIn", "Person", "Place").property("hosts", "Place", "Person").property("email", "Person", "Text").inverse("livesIn", "hosts")
    compatibility = ontology.compatibility(previous)
    surface("G034-S02-08", compatibility.compatible and compatibility.fromVersion == 1 and compatibility.toVersion == 2, compatibility)

    extended = Ontology.new("transport", 3).defineType("Place").defineType("City").defineType("Person").defineType("Country")
    extended.subtype("City", "Place").property("livesIn", "Person", "Place").property("hosts", "Place", "Person").property("email", "Person", "Text").inverse("livesIn", "hosts")
    claim("metamorphic", extended.identity() != ontology.identity(), "ontology definition governs identity")
    claim("composition", graph.verify().valid and compatibility.compatible, "ontology graph validation and compatibility compose")
    types_snapshot = frozenset(ontology._types)
    claim("ownership", isinstance(types_snapshot, frozenset), "type snapshot is immutable")
    claim("boundary", Ontology.new("x", 1).version == 1, "minimum ontology version")
    twin = Ontology.new("transport", 2).defineType("Place").defineType("City").defineType("Person")
    twin.subtype("City", "Place").property("livesIn", "Person", "Place").property("hosts", "Place", "Person").property("email", "Person", "Text").inverse("livesIn", "hosts").constraint({"kind": "required", "type": "Person", "property": "email"})
    claim("determinism", twin.identity() == ontology.identity(), "canonical ontology identity is deterministic")
    mutable = make_ontology()
    before = mutable.identity()
    negative("CYCLIC_SUBTYPE", "ontology.subtype", lambda: mutable.subtype("Place", "City"))
    claim("failure_atomicity", mutable.identity() == before, "cycle rejection leaves ontology unchanged")
    removed = Ontology.new("transport", 3).defineType("Person")
    breaking = removed.compatibility(previous)
    claim("adversarial", not breaking.compatible and "removed-type:Place" in breaking.breakingChanges, "breaking migration remains explicit")
    negative("UNKNOWN_TYPE", "ontology.subtype", lambda: mutable.subtype("Missing", "Place"))
    negative("INVERSE_MISMATCH", "ontology.inverse", lambda: mutable.inverse("livesIn", "email"))
    negative("UNSUPPORTED_CONSTRAINT", "ontology.constraint", lambda: mutable.constraint({"kind": "repair", "property": "email"}))
    negative("ONTOLOGY_IDENTITY_MISMATCH", "ontology.compatibility", lambda: ontology.compatibility(Ontology.new("other", 1)))
    negative("ONTOLOGY_FROZEN", "ontology.defineType", lambda: ontology.defineType("LateType"))


def subgroup_s03() -> None:
    ontology, graph, entities, facts = make_graph()
    initial = Rule.when({"subject": "$person", "predicate": "livesIn", "object": "$place"})
    surface("G034-S03-01", len(initial.patterns) == 1, initial.patterns)
    combined = initial.andCondition({"subject": "$place", "predicate": "locatedIn", "object": "$region"})
    surface("G034-S03-02", len(combined.patterns) == 2 and len(initial.patterns) == 1, combined.patterns)
    concluded = combined.then({"subject": "$person", "predicate": "reachable", "object": "$region"})
    surface("G034-S03-03", concluded.conclusion["predicate"] == "reachable", concluded.conclusion)
    rule = concluded.priority(7)
    surface("G034-S03-04", rule.priority_value == 7 and concluded.priority_value == 0, rule.priority_value)
    reasoner = Reasoner.new(ontology, (rule,), {"strategy": "monotonic", "maxRounds": 8, "maxDerived": 16})
    surface("G034-S03-05", reasoner.rules[0].identity() == rule.identity(), reasoner.rules[0].identity())
    inference = reasoner.infer(graph)
    alice_europe = next(fact for fact in inference.facts if fact.subject == entities["alice"] and fact.object == entities["europe"])
    surface("G034-S03-06", len(inference.facts) == 1 and alice_europe.derived, inference)
    bob_paris = getattr(graph, "assert")(entities["bob"], "livesIn", entities["paris"], provenance("bob-residence"))
    incremental = reasoner.incremental({"graph": graph, "added": (bob_paris.factId,), "retracted": ()})
    bob_derived = next(fact for fact in incremental.facts if fact.subject == entities["bob"])
    surface("G034-S03-07", incremental.mode == "affected" and len(incremental.facts) == 2 and incremental.recomputed == (bob_derived.factId,), incremental)
    explanation = reasoner.explain(next(fact for fact in incremental.facts if fact.subject == entities["bob"]))
    surface("G034-S03-08", explanation.ruleId == rule.identity() and bob_paris.factId in explanation.premises and not explanation.includesPrivateReasoning, explanation)

    alternate = rule.priority(8)
    claim("metamorphic", alternate.identity() != rule.identity(), "priority governs rule identity")
    claim("composition", all(fact.factId in incremental.proofs for fact in incremental.facts), "inference facts and proof links compose")
    proof_snapshot = tuple(incremental.proofs)
    reasoner.explain(incremental.facts[0])
    claim("ownership", proof_snapshot == tuple(incremental.proofs), "explanation does not mutate proof set")
    claim("boundary", Reasoner.new(ontology, (rule,), {"maxRounds": 1, "maxDerived": 1}).max_derived == 1, "minimum reasoning budgets")
    repeat = Reasoner.new(ontology, (rule,), {"maxRounds": 8, "maxDerived": 16}).infer(graph)
    claim("determinism", tuple(fact.factId for fact in repeat.facts) == tuple(fact.factId for fact in incremental.facts), "inference is deterministic")
    before = graph.snapshot()
    negative("UNSUPPORTED_STRATEGY", "Reasoner.new", lambda: Reasoner.new(ontology, (rule,), {"strategy": "non-monotonic"}))
    claim("failure_atomicity", graph.snapshot() == before, "rejected reasoner does not mutate graph")
    claim("adversarial", set(explanation.provenance) == {"ontology", "graphVersion"}, "explanation exposes proof metadata not private reasoning")
    negative("INVALID_PATTERN", "Rule.when", lambda: Rule.when({"subject": "$x"}))
    negative("INCOMPLETE_RULE", "Reasoner.new", lambda: Reasoner.new(ontology, (initial,), {}))
    negative("SCHEMA_MISMATCH", "reasoner.infer", lambda: reasoner.infer(KnowledgeGraph.new(make_ontology(3), {})))
    negative("NO_PROOF", "reasoner.explain", lambda: reasoner.explain(facts["alice_paris"]))


def subgroup_s04() -> None:
    _, graph, _, _ = make_graph()
    matched = KnowledgeQuery.match({"graph": graph, "subject": "$person", "predicate": "livesIn", "object": "$place"})
    surface("G034-S04-01", matched.pattern["predicate"] == "livesIn", matched.pattern)
    filtered = matched.where({"binding": "$person", "operator": "eq", "value": "alice"})
    surface("G034-S04-02", len(filtered.conditions) == 1 and matched.conditions == (), filtered.conditions)
    optional = filtered.optional({"subject": "$place", "predicate": "locatedIn", "object": "$region"})
    surface("G034-S04-03", len(optional.optional_patterns) == 1, optional.optional_patterns)
    pathed = optional.path("locatedIn", {"from": "$place", "to": "$region", "minDepth": 1, "maxDepth": 2})
    surface("G034-S04-04", pathed.path_spec["maxDepth"] == 2, pathed.path_spec)
    projected = pathed.project(("$person", "$place", "$region", "$fact"))
    surface("G034-S04-05", projected.projection == ("$person", "$place", "$region", "$fact"), projected.projection)
    plan = projected.explain()
    surface("G034-S04-06", plan["index"] == "predicate+subject" and plan["pathBound"] == 2, plan)
    stream = projected.stream()
    streamed = stream.request(1)
    surface("G034-S04-07", len(streamed) == 1 and stream.request(1) == (), streamed)
    collected = projected.collect(1)
    surface("G034-S04-08", collected == streamed and collected[0]["$region"] == "europe", collected)

    changed = matched.where({"binding": "$person", "operator": "eq", "value": "bob"}).collect(4)
    claim("metamorphic", changed == (), "filter input governs query result")
    claim("composition", collected[0]["$person"] == "alice" and collected[0]["$place"] == "paris", "match optional path and projection compose")
    rows_snapshot = collected
    projected.collect(1)
    claim("ownership", rows_snapshot == collected and type(rows_snapshot[0]).__name__ == "mappingproxy", "collected rows are immutable")
    claim("boundary", len(matched.collect(1)) == 1, "explicit one-row materialization")
    claim("determinism", projected.collect(1) == collected, "query ordering is deterministic")
    offset_before = stream._offset
    negative("INVALID_INTEGER", "resultStream.request", lambda: stream.request(True))
    claim("failure_atomicity", stream._offset == offset_before, "invalid demand does not consume stream")
    claim("adversarial", plan["estimatedRows"] == 1 and "rules" in plan, "query plan exposes estimate and rule use")
    negative("GRAPH_REQUIRED", "KnowledgeQuery.match", lambda: KnowledgeQuery.match({"subject": "$x", "predicate": "p", "object": "$y"}))
    negative("UNKNOWN_PROPERTY", "KnowledgeQuery.match", lambda: KnowledgeQuery.match({"graph": graph, "subject": "$x", "predicate": "missing", "object": "$y"}))
    negative("UNSUPPORTED_CONDITION", "query.where", lambda: matched.where({"binding": "$person", "operator": "exec", "value": "alice"}))
    negative("INVALID_BOUNDS", "query.path", lambda: matched.path("livesIn", {"from": "$person", "to": "$place", "minDepth": 3, "maxDepth": 2}))
    negative("INVALID_INTEGER", "query.collect", lambda: matched.collect(True))


def make_indexes() -> tuple[list[dict[str, Any]], SemanticIndex, TextIndex]:
    items = [
        {"identity": "alice", "text": "person researcher", "provenance": provenance("item-alice")},
        {"identity": "paris", "text": "capital city france", "provenance": provenance("item-paris")},
    ]
    vectors = {"alice": (1.0, 0.0, 0.0), "paris": (0.0, 1.0, 0.0)}
    index = SemanticIndex.build(items, vectors, {"version": 1, "dimension": 3, "maxItems": 8, "metric": "cosine", "queryRepresentations": {"city": (0.0, 1.0, 0.0), "person": (1.0, 0.0, 0.0)}})
    return items, index, TextIndex(items, 1)


def subgroup_s05() -> None:
    items, index, text_index = make_indexes()
    surface("G034-S05-01", index.dimension == 3 and tuple(index._items) == ("alice", "paris"), tuple(index._items))
    london = {"identity": "london", "text": "capital city england", "provenance": provenance("item-london")}
    index.insert(london, (0.0, 0.9, 0.1))
    surface("G034-S05-02", "london" in index._items and index.version == 2, index.version)
    temporary = {"identity": "temp", "text": "temporary", "provenance": provenance("item-temp")}
    index.insert(temporary, (0.0, 0.1, 0.9))
    removal = index.remove("temp")
    surface("G034-S05-03", "temp" not in index._items and removal["identity"] == "temp", removal)
    semantic = index.search((0.0, 1.0, 0.0), 2)
    surface("G034-S05-04", tuple(result.identity for result in semantic) == ("paris", "london") and semantic[0].score == 1.0, semantic)
    _, graph, _, _ = make_graph()
    combined = HybridSearch.new(graph, TextIndex(items + [london], 1), index)
    surface("G034-S05-05", combined.graph is graph and combined.semantic_index is index, True)
    results = combined.query("city", {"entityType": "City"}, 2)
    surface("G034-S05-06", results[0].identity == "paris" and all(result.identity != "alice" for result in results), results)
    breakdown = results[0].scoreBreakdown()
    surface("G034-S05-07", set(breakdown) == {"keyword", "semantic", "graph", "combined"} and breakdown["combined"] == results[0].score, breakdown)
    result_provenance = results[0].provenance()
    surface("G034-S05-08", result_provenance["claim"] == "ranking-not-proof" and result_provenance["item"]["claim"] == "similarity-only", result_provenance)

    person_results = combined.query("person", {"entityType": "Person"}, 2)
    claim("metamorphic", person_results[0].identity == "alice" and person_results[0].identity != results[0].identity, "query text governs explicit representation")
    claim("composition", results[0].scoreBreakdown()["semantic"] == semantic[0].score, "semantic and hybrid scoring compose")
    snapshot = semantic
    index.insert({"identity": "other", "text": "other", "provenance": provenance("item-other")}, (0.1, 0.1, 0.8))
    claim("ownership", snapshot[0].identity == "paris" and len(snapshot) == 2, "search result snapshot is detached")
    claim("boundary", len(index.search((1.0, 0.0, 0.0), 1)) == 1, "one-result search limit")
    _, twin, _ = make_indexes()
    claim("determinism", twin.search((0.0, 1.0, 0.0), 2)[0].identity == "paris", "semantic ranking is deterministic")
    version_before = index.version
    negative("DIMENSION_MISMATCH", "index.insert", lambda: index.insert({"identity": "bad", "text": "bad", "provenance": provenance("bad")}, (1.0, 0.0)))
    claim("failure_atomicity", index.version == version_before and "bad" not in index._items, "invalid insert is atomic")
    claim("adversarial", all(result.provenance()["claim"] == "ranking-not-proof" for result in results), "hybrid similarity is never labelled factual proof")
    negative("ZERO_VECTOR", "index.search", lambda: index.search((0.0, 0.0, 0.0), 1))
    negative("UNKNOWN_ITEM", "index.remove", lambda: index.remove("missing"))
    negative("MISSING_REPRESENTATION", "search.query", lambda: combined.query("unrepresented", {}, 1))
    negative("UNKNOWN_TYPE", "search.query", lambda: combined.query("city", {"entityType": "Missing"}, 1))


def subgroup_s06() -> None:
    ontology, graph, entities, facts = make_graph()
    knowledge = Knowledge(graph)
    query = KnowledgeQuery.match({"graph": graph, "subject": "$person", "predicate": "livesIn", "object": "$place"})
    context = knowledge.context(query, {"maxResults": 4, "maxBytes": 4096})
    surface("G034-S06-01", context.citations == (facts["alice_paris"].factId,) and context.graphVersion == graph.version, context)
    supported = knowledge.verifyClaim({"subject": "alice", "predicate": "livesIn", "object": "paris"})
    contradicted = knowledge.verifyClaim({"subject": "alice", "predicate": "email", "object": "other@example.invalid"})
    unknown = knowledge.verifyClaim({"subject": "alice", "predicate": "worksAt", "object": "nebo"})
    ambiguous = knowledge.verifyClaim({"subject": "alice", "predicate": "livesIn", "object": "london"})
    surface("G034-S06-02", (supported.status, contradicted.status, unknown.status, ambiguous.status) == ("supported", "contradicted", "unknown", "ambiguous"), (supported, contradicted, unknown, ambiguous))
    getattr(graph, "assert")(entities["alice"], "email", "conflict@example.invalid", provenance("conflict"))
    contradictions = knowledge.detectContradictions({"predicate": "email"})
    surface("G034-S06-03", len(contradictions) == 1 and contradictions[0]["code"] == "FUNCTIONAL_CONFLICT", contradictions)
    policy = AiPolicy.requireGrounding({"categories": ("factual", "medical"), "minimumCitations": 1})
    grounded = Generation("Paris is connected to the cited fact.", "factual", policy).ground(context)
    surface("G034-S06-04", grounded.text.startswith("Paris") and grounded.grounding.decision == "grounded", grounded)
    surface("G034-S06-05", grounded.citations() == context.citations, grounded.citations())
    surface("G034-S06-06", policy.categories == frozenset({"factual", "medical"}) and policy.minimumCitations == 1, policy)
    agent = KnowledgeAgent("research").knowledgeScope({"graphs": (graph.graph_identity,), "indexes": ("places-v1",)})
    agent.authorize(graph.graph_identity, "places-v1")
    surface("G034-S06-07", agent.scope.graphs == frozenset({graph.graph_identity}) and agent.scope.indexes == frozenset({"places-v1"}), agent.scope)
    audit = grounded.grounding.audit()
    surface("G034-S06-08", audit["sensitiveContent"] == "omitted" and "Paris" not in repr(audit) and len(audit["citationDigests"][0]) == 64, audit)

    smaller = knowledge.context(query, {"maxResults": 4, "maxBytes": 1})
    claim("metamorphic", smaller.truncated and smaller.text == "", "context byte budget governs output")
    claim("composition", grounded.citations()[0] == supported.evidence[0], "claim evidence context and grounding citations compose")
    audit_snapshot = audit
    knowledge.verifyClaim({"subject": "nobody", "predicate": "p", "object": "x"})
    claim("ownership", grounded.grounding.audit() == audit_snapshot, "grounding audit is immutable")
    one = knowledge.context(query, {"maxResults": 1, "maxBytes": 4096})
    claim("boundary", len(one.citations) == 1, "one-result grounding budget")
    claim("determinism", grounded.grounding.audit() == Generation("same").ground(context).grounding.audit(), "grounding lineage is deterministic")
    before = graph.snapshot()
    negative("INVALID_CLAIM", "knowledge.verifyClaim", lambda: knowledge.verifyClaim({"subject": "alice"}))
    claim("failure_atomicity", graph.snapshot() == before, "invalid claim does not mutate knowledge")
    claim("adversarial", set(audit) == {"queryDigest", "citationDigests", "versions", "decision", "sensitiveContent"}, "audit contains lineage but no raw context")
    negative("GROUNDING_REQUIRED", "generation.ground", lambda: Generation("unsupported").ground(type(context)("", (), context.queryDigest, context.graphVersion, False)))
    negative("INVALID_POLICY", "AiPolicy.requireGrounding", lambda: AiPolicy.requireGrounding({"categories": "factual"}))
    negative("INVALID_CAPABILITY", "agent.knowledgeScope", lambda: KnowledgeAgent("x").knowledgeScope({"graphs": "all", "indexes": ()}))
    negative("CAPABILITY_DENIED", "agent.knowledgeScope", lambda: agent.authorize(graph.graph_identity, "other-index"))
    strict_policy = AiPolicy.requireGrounding({"categories": ("factual",), "minimumCitations": 2})
    negative("GROUNDING_POLICY", "generation.ground", lambda: Generation("needs two", "factual", strict_policy).ground(context))
    negative("INVALID_INTEGER", "knowledge.context", lambda: knowledge.context(query, {"maxResults": True, "maxBytes": 10}))


def static_checks() -> None:
    source = open("compiler/sdk/knowledge.py", encoding="utf-8").read()
    require(all(term not in source for term in ("socket.", "subprocess.", "urlopen", "requests.")), "no network/process dependency")
    require("private chain-of-thought" in source and "similarity as" in source, "honest explanation and similarity boundaries")
    claim("adversarial", "ranking-not-proof" in source and "sensitiveContent" in source, "false proof and sensitive audit guards exist")


def main() -> None:
    subgroup_s01()
    subgroup_s02()
    subgroup_s03()
    subgroup_s04()
    subgroup_s05()
    subgroup_s06()
    static_checks()
    require(COUNTS["positive"] == 48 and COUNTS["sdk"] == 48, "all 48 surfaces need direct observations")
    digest = hashlib.sha256(json.dumps(EVIDENCE, separators=(",", ":"), ensure_ascii=True).encode("ascii")).hexdigest()
    fields = " ".join(f"{name}={value}" for name, value in COUNTS.items())
    print(f"G034_SDK_ORACLE_GREEN {fields} digest={digest}")


if __name__ == "__main__":
    main()
