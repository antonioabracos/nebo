"""Bounded local knowledge graphs, reasoning, search, and grounding for G034.

The reference profile is deterministic and memory-only.  It performs no network
access, crawling, model download, or persistence, and never treats similarity as
factual proof or exposes private chain-of-thought.
"""

from __future__ import annotations

import hashlib
import json
import math
from dataclasses import dataclass
from types import MappingProxyType
from typing import Any, Iterable, Mapping, Sequence


MAX_ENTITIES = 512
MAX_FACTS = 4096
MAX_TYPES = 128
MAX_PROPERTIES = 256
MAX_RULES = 256
MAX_ROUNDS = 64
MAX_DERIVED = 4096
MAX_QUERY_RESULTS = 1024
MAX_PATH_DEPTH = 16
MAX_INDEX_ITEMS = 2048
MAX_VECTOR_DIMENSION = 64
MAX_CONTEXT_BYTES = 16384


class KnowledgeError(ValueError):
    """Stable bounded-profile failure."""

    def __init__(self, code: str, operation: str, message: str) -> None:
        super().__init__(f"{code}: {operation}: {message}")
        self.code = code
        self.operation = operation


def _fail(code: str, operation: str, message: str) -> None:
    raise KnowledgeError(code, operation, message)


def _integer(value: Any, operation: str, name: str, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        _fail("INVALID_INTEGER", operation, f"{name} must be an integer")
    if value < minimum or value > maximum:
        _fail("LIMIT_EXCEEDED", operation, f"{name} must be in [{minimum}, {maximum}]")
    return value


def _number(value: Any, operation: str, name: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        _fail("INVALID_NUMBER", operation, f"{name} must be numeric")
    result = float(value)
    if not math.isfinite(result):
        _fail("NON_FINITE", operation, f"{name} must be finite")
    return result


def _text(value: Any, operation: str, name: str, *, allow_empty: bool = False) -> str:
    if not isinstance(value, str) or (not allow_empty and not value):
        _fail("INVALID_TEXT", operation, f"{name} must be text")
    if len(value.encode("utf-8")) > 8192:
        _fail("LIMIT_EXCEEDED", operation, f"{name} exceeds the text budget")
    return value


def _mapping(value: Any, operation: str, name: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        _fail("INVALID_MAPPING", operation, f"{name} must be a mapping")
    return value


def _sequence(value: Any, operation: str, name: str) -> Sequence[Any]:
    if isinstance(value, (str, bytes, bytearray)) or not isinstance(value, Sequence):
        _fail("INVALID_SEQUENCE", operation, f"{name} must be a sequence")
    return value


def _freeze(value: Any) -> Any:
    if isinstance(value, Mapping):
        return MappingProxyType({str(key): _freeze(inner) for key, inner in value.items()})
    if isinstance(value, (list, tuple, set, frozenset)):
        return tuple(_freeze(inner) for inner in value)
    return value


def _thaw(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {str(key): _thaw(inner) for key, inner in value.items()}
    if isinstance(value, (list, tuple)):
        return [_thaw(inner) for inner in value]
    if isinstance(value, (set, frozenset)):
        return sorted(_thaw(inner) for inner in value)
    if isinstance(value, Entity):
        return {"type": value.type, "identity": value.identity}
    return value


def _canonical(value: Any) -> bytes:
    try:
        return json.dumps(_thaw(value), sort_keys=True, separators=(",", ":"), ensure_ascii=True, allow_nan=False).encode("ascii")
    except (TypeError, ValueError):
        _fail("NON_CANONICAL_VALUE", "canonicalize", "value is not canonical JSON")


def _digest(value: Any) -> str:
    return hashlib.sha256(_canonical(value)).hexdigest()


def _provenance(value: Any, operation: str) -> Mapping[str, Any]:
    item = _mapping(value, operation, "provenance")
    source = _text(item.get("source"), operation, "provenance.source")
    version = _integer(item.get("version"), operation, "provenance.version", 1, (1 << 31) - 1)
    digest = item.get("digest")
    if not isinstance(digest, str) or len(digest) != 64 or any(character not in "0123456789abcdef" for character in digest):
        _fail("INVALID_PROVENANCE", operation, "provenance.digest must be lowercase SHA-256 text")
    return _freeze({"source": source, "version": version, "digest": digest})


@dataclass(frozen=True, order=True)
class Entity:
    type: str
    identity: str


@dataclass(frozen=True)
class Fact:
    factId: str
    subject: Entity
    predicate: str
    object: Any
    provenance: Mapping[str, Any]
    assertedVersion: int
    derived: bool = False

    def triple(self) -> tuple[Any, ...]:
        return (self.subject.identity, self.predicate, self.object.identity if isinstance(self.object, Entity) else self.object)


@dataclass(frozen=True)
class GraphSnapshot:
    graphIdentity: str
    version: int
    entities: tuple[Entity, ...]
    facts: tuple[Fact, ...]
    retractions: tuple[Mapping[str, Any], ...]


@dataclass(frozen=True)
class VerificationResult:
    valid: bool
    violations: tuple[Mapping[str, Any], ...]
    checkedFacts: int
    graphVersion: int


@dataclass(frozen=True)
class CompatibilityResult:
    compatible: bool
    breakingChanges: tuple[str, ...]
    fromVersion: int
    toVersion: int


class Ontology:
    def __init__(self, name: str, version: int) -> None:
        self.name = _text(name, "Ontology.new", "name")
        self.version = _integer(version, "Ontology.new", "version", 1, (1 << 31) - 1)
        self._types: set[str] = set()
        self._subtypes: set[tuple[str, str]] = set()
        self._properties: dict[str, tuple[str, str]] = {}
        self._inverses: dict[str, str] = {}
        self._constraints: list[Mapping[str, Any]] = []
        self._sealed = False

    @classmethod
    def new(cls, name: str, version: int) -> "Ontology":
        return cls(name, version)

    def defineType(self, name: str) -> "Ontology":
        operation = "ontology.defineType"
        self._require_mutable(operation)
        value = _text(name, operation, "name")
        if len(self._types) >= MAX_TYPES and value not in self._types:
            _fail("LIMIT_EXCEEDED", operation, "type budget is exhausted")
        self._types.add(value)
        return self

    def _require_mutable(self, operation: str) -> None:
        if self._sealed:
            _fail("ONTOLOGY_FROZEN", operation, "ontology is bound to a graph and cannot change")

    def _require_type(self, name: Any, operation: str) -> str:
        value = _text(name, operation, "type")
        if value not in self._types:
            _fail("UNKNOWN_TYPE", operation, f"unknown type {value}")
        return value

    def _is_subtype(self, child: str, parent: str) -> bool:
        if child == parent:
            return True
        frontier = [child]
        visited: set[str] = set()
        while frontier:
            current = frontier.pop()
            if current in visited:
                continue
            visited.add(current)
            for candidate, target in self._subtypes:
                if candidate == current:
                    if target == parent:
                        return True
                    frontier.append(target)
        return False

    def subtype(self, child: str, parent: str) -> "Ontology":
        operation = "ontology.subtype"
        self._require_mutable(operation)
        child_name = self._require_type(child, operation)
        parent_name = self._require_type(parent, operation)
        if child_name == parent_name or self._is_subtype(parent_name, child_name):
            _fail("CYCLIC_SUBTYPE", operation, "subtype relation must be acyclic in this profile")
        self._subtypes.add((child_name, parent_name))
        return self

    def property(self, name: str, domain: str, range: str) -> "Ontology":
        operation = "ontology.property"
        self._require_mutable(operation)
        key = _text(name, operation, "name")
        domain_name = self._require_type(domain, operation)
        range_name = _text(range, operation, "range")
        if range_name not in self._types and range_name not in {"Text", "Int", "Float", "Bool"}:
            _fail("UNKNOWN_RANGE", operation, f"unknown range {range_name}")
        signature = (domain_name, range_name)
        if key in self._properties and self._properties[key] != signature:
            _fail("PROPERTY_CONFLICT", operation, "property already has a different signature")
        if len(self._properties) >= MAX_PROPERTIES and key not in self._properties:
            _fail("LIMIT_EXCEEDED", operation, "property budget is exhausted")
        self._properties[key] = signature
        return self

    def inverse(self, property: str, inverse: str) -> "Ontology":
        operation = "ontology.inverse"
        self._require_mutable(operation)
        left = _text(property, operation, "property")
        right = _text(inverse, operation, "inverse")
        if left not in self._properties or right not in self._properties:
            _fail("UNKNOWN_PROPERTY", operation, "both inverse properties must exist")
        left_domain, left_range = self._properties[left]
        right_domain, right_range = self._properties[right]
        if left_range not in self._types or (right_domain, right_range) != (left_range, left_domain):
            _fail("INVERSE_MISMATCH", operation, "inverse signatures must be reversed nominal types")
        self._inverses[left] = right
        self._inverses[right] = left
        return self

    def constraint(self, rule: Mapping[str, Any]) -> "Ontology":
        operation = "ontology.constraint"
        self._require_mutable(operation)
        item = dict(_mapping(rule, operation, "rule"))
        kind = item.get("kind")
        if kind not in {"required", "cardinality", "unique", "disjoint"}:
            _fail("UNSUPPORTED_CONSTRAINT", operation, "constraint kind is unsupported")
        if kind in {"required", "cardinality", "unique"}:
            name = _text(item.get("property"), operation, "rule.property")
            if name not in self._properties:
                _fail("UNKNOWN_PROPERTY", operation, f"unknown property {name}")
        if kind == "required":
            item["type"] = self._require_type(item.get("type"), operation)
        elif kind == "cardinality":
            item["maximum"] = _integer(item.get("maximum"), operation, "rule.maximum", 1, MAX_FACTS)
        elif kind == "disjoint":
            item["left"] = self._require_type(item.get("left"), operation)
            item["right"] = self._require_type(item.get("right"), operation)
            if item["left"] == item["right"]:
                _fail("INVALID_CONSTRAINT", operation, "disjoint types must differ")
        frozen = _freeze(item)
        if _digest(frozen) not in {_digest(existing) for existing in self._constraints}:
            self._constraints.append(frozen)
        return self

    def validate(self, graph: "KnowledgeGraph") -> tuple[Mapping[str, Any], ...]:
        operation = "ontology.validate"
        if not isinstance(graph, KnowledgeGraph) or graph.ontology is not self:
            _fail("SCHEMA_MISMATCH", operation, "graph must use this ontology instance")
        violations: list[Mapping[str, Any]] = []
        facts = graph._active_facts()
        by_subject_property: dict[tuple[str, str], list[Fact]] = {}
        for fact in facts:
            signature = self._properties.get(fact.predicate)
            if signature is None:
                violations.append(_freeze({"code": "UNKNOWN_PROPERTY", "fact": fact.factId}))
                continue
            domain, range_name = signature
            if not self._is_subtype(fact.subject.type, domain):
                violations.append(_freeze({"code": "DOMAIN_MISMATCH", "fact": fact.factId}))
            if range_name in self._types:
                if not isinstance(fact.object, Entity) or not self._is_subtype(fact.object.type, range_name):
                    violations.append(_freeze({"code": "RANGE_MISMATCH", "fact": fact.factId}))
            elif not _scalar_matches(fact.object, range_name):
                violations.append(_freeze({"code": "RANGE_MISMATCH", "fact": fact.factId}))
            by_subject_property.setdefault((fact.subject.identity, fact.predicate), []).append(fact)
        for constraint in self._constraints:
            kind = constraint["kind"]
            if kind == "required":
                for entity in graph._entities.values():
                    if self._is_subtype(entity.type, constraint["type"]) and not by_subject_property.get((entity.identity, constraint["property"])):
                        violations.append(_freeze({"code": "REQUIRED_MISSING", "entity": entity.identity, "property": constraint["property"]}))
            elif kind == "cardinality":
                for (identity, predicate), values in by_subject_property.items():
                    if predicate == constraint["property"] and len(values) > constraint["maximum"]:
                        violations.append(_freeze({"code": "CARDINALITY", "entity": identity, "property": predicate}))
            elif kind == "unique":
                seen: dict[Any, str] = {}
                for fact in facts:
                    if fact.predicate == constraint["property"]:
                        value = fact.object.identity if isinstance(fact.object, Entity) else fact.object
                        if value in seen and seen[value] != fact.subject.identity:
                            violations.append(_freeze({"code": "UNIQUENESS", "property": fact.predicate, "value": value}))
                        seen[value] = fact.subject.identity
            elif kind == "disjoint":
                if self._is_subtype(constraint["left"], constraint["right"]) or self._is_subtype(constraint["right"], constraint["left"]):
                    violations.append(_freeze({"code": "DISJOINTNESS", "left": constraint["left"], "right": constraint["right"]}))
        return tuple(sorted(violations, key=lambda item: _canonical(item)))

    def compatibility(self, previous: "Ontology") -> CompatibilityResult:
        operation = "ontology.compatibility"
        if not isinstance(previous, Ontology) or previous.name != self.name:
            _fail("ONTOLOGY_IDENTITY_MISMATCH", operation, "ontologies must share a nominal name")
        breaking: list[str] = []
        for name in sorted(previous._types - self._types):
            breaking.append(f"removed-type:{name}")
        for name, signature in sorted(previous._properties.items()):
            if name not in self._properties:
                breaking.append(f"removed-property:{name}")
            elif self._properties[name] != signature:
                breaking.append(f"changed-property:{name}")
        return CompatibilityResult(not breaking, tuple(breaking), previous.version, self.version)

    def identity(self) -> str:
        return _digest(
            {
                "name": self.name,
                "version": self.version,
                "types": sorted(self._types),
                "subtypes": sorted(self._subtypes),
                "properties": self._properties,
                "inverses": self._inverses,
                "constraints": self._constraints,
            }
        )


def _scalar_matches(value: Any, name: str) -> bool:
    if name == "Text":
        return isinstance(value, str)
    if name == "Int":
        return isinstance(value, int) and not isinstance(value, bool)
    if name == "Float":
        return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(float(value))
    if name == "Bool":
        return isinstance(value, bool)
    return False


class KnowledgeGraph:
    def __init__(self, schema: Ontology, options: Mapping[str, Any]) -> None:
        operation = "KnowledgeGraph.new"
        if not isinstance(schema, Ontology):
            _fail("INVALID_SCHEMA", operation, "schema must be an Ontology")
        self.ontology = schema
        schema._sealed = True
        self.max_entities = _integer(options.get("maxEntities", MAX_ENTITIES), operation, "options.maxEntities", 1, MAX_ENTITIES)
        self.max_facts = _integer(options.get("maxFacts", MAX_FACTS), operation, "options.maxFacts", 1, MAX_FACTS)
        audit = options.get("auditRetractions", True)
        if not isinstance(audit, bool):
            _fail("INVALID_BOOLEAN", operation, "options.auditRetractions must be Bool")
        self.audit_retractions = audit
        self.graph_identity = _digest({"ontology": schema.identity(), "maxEntities": self.max_entities, "maxFacts": self.max_facts})
        self.version = 1
        self._entities: dict[tuple[str, str], Entity] = {}
        self._facts: dict[str, Fact] = {}
        self._subject_index: dict[str, set[str]] = {}
        self._object_index: dict[str, set[str]] = {}
        self._retractions: list[Mapping[str, Any]] = []

    @classmethod
    def new(cls, schema: Ontology, options: Mapping[str, Any] | None = None) -> "KnowledgeGraph":
        return cls(schema, _mapping(options or {}, "KnowledgeGraph.new", "options"))

    def entity(self, type: str, identity: str) -> Entity:
        operation = "graph.entity"
        type_name = self.ontology._require_type(type, operation)
        key = (type_name, _text(identity, operation, "identity"))
        if any(existing.identity == key[1] and existing.type != type_name for existing in self._entities.values()):
            _fail("ENTITY_TYPE_CONFLICT", operation, "nominal identity already belongs to another type")
        if key not in self._entities:
            if len(self._entities) >= self.max_entities:
                _fail("ENTITY_LIMIT", operation, "entity budget is exhausted")
            self._entities[key] = Entity(*key)
            self.version += 1
        return self._entities[key]

    def _validate_fact(self, subject: Entity, predicate: str, object: Any, operation: str) -> tuple[str, Any]:
        if not isinstance(subject, Entity) or (subject.type, subject.identity) not in self._entities:
            _fail("UNKNOWN_ENTITY", operation, "subject must belong to this graph")
        name = _text(predicate, operation, "predicate")
        if name not in self.ontology._properties:
            _fail("UNKNOWN_PROPERTY", operation, f"unknown property {name}")
        domain, range_name = self.ontology._properties[name]
        if not self.ontology._is_subtype(subject.type, domain):
            _fail("DOMAIN_MISMATCH", operation, "subject type violates property domain")
        if range_name in self.ontology._types:
            if not isinstance(object, Entity) or (object.type, object.identity) not in self._entities or not self.ontology._is_subtype(object.type, range_name):
                _fail("RANGE_MISMATCH", operation, "object entity violates property range")
        elif not _scalar_matches(object, range_name):
            _fail("RANGE_MISMATCH", operation, "object value violates property range")
        return name, object

    def assertFact(self, subject: Entity, predicate: str, object: Any, provenance: Mapping[str, Any]) -> Fact:
        operation = "graph.assert"
        name, value = self._validate_fact(subject, predicate, object, operation)
        source = _provenance(provenance, operation)
        fact_id = _digest({"graph": self.graph_identity, "subject": subject, "predicate": name, "object": value, "provenance": source})
        if fact_id in self._facts:
            return self._facts[fact_id]
        if len(self._facts) >= self.max_facts:
            _fail("FACT_LIMIT", operation, "fact budget is exhausted")
        self.version += 1
        fact = Fact(fact_id, subject, name, value, source, self.version)
        self._facts[fact_id] = fact
        self._subject_index.setdefault(subject.identity, set()).add(fact_id)
        if isinstance(value, Entity):
            self._object_index.setdefault(value.identity, set()).add(fact_id)
        return fact

    def retract(self, factId: str) -> Fact:
        operation = "graph.retract"
        identity = _text(factId, operation, "factId")
        fact = self._facts.get(identity)
        if fact is None:
            _fail("UNKNOWN_FACT", operation, "fact is not active")
        self.version += 1
        del self._facts[identity]
        self._subject_index[fact.subject.identity].discard(identity)
        if isinstance(fact.object, Entity):
            self._object_index[fact.object.identity].discard(identity)
        if self.audit_retractions:
            self._retractions.append(_freeze({"factId": identity, "version": self.version, "provenanceDigest": _digest(fact.provenance)}))
        return fact

    def fact(self, factId: str) -> Fact:
        identity = _text(factId, "graph.fact", "factId")
        if identity not in self._facts:
            _fail("UNKNOWN_FACT", "graph.fact", "fact is not active")
        return self._facts[identity]

    def factsAbout(self, entity: Entity, limit: int) -> tuple[Fact, ...]:
        operation = "graph.factsAbout"
        if not isinstance(entity, Entity) or (entity.type, entity.identity) not in self._entities:
            _fail("UNKNOWN_ENTITY", operation, "entity must belong to this graph")
        maximum = _integer(limit, operation, "limit", 1, MAX_QUERY_RESULTS)
        identities = self._subject_index.get(entity.identity, set()) | self._object_index.get(entity.identity, set())
        return tuple(self._facts[identity] for identity in sorted(identities)[:maximum])

    def _active_facts(self) -> tuple[Fact, ...]:
        return tuple(self._facts[identity] for identity in sorted(self._facts))

    def snapshot(self) -> GraphSnapshot:
        return GraphSnapshot(
            self.graph_identity,
            self.version,
            tuple(sorted(self._entities.values())),
            self._active_facts(),
            tuple(self._retractions),
        )

    def verify(self) -> VerificationResult:
        violations = list(self.ontology.validate(self))
        expected_subject: dict[str, set[str]] = {}
        expected_object: dict[str, set[str]] = {}
        for fact in self._facts.values():
            expected_subject.setdefault(fact.subject.identity, set()).add(fact.factId)
            if isinstance(fact.object, Entity):
                expected_object.setdefault(fact.object.identity, set()).add(fact.factId)
        if expected_subject != {key: value for key, value in self._subject_index.items() if value}:
            violations.append(_freeze({"code": "SUBJECT_INDEX_MISMATCH"}))
        if expected_object != {key: value for key, value in self._object_index.items() if value}:
            violations.append(_freeze({"code": "OBJECT_INDEX_MISMATCH"}))
        return VerificationResult(not violations, tuple(violations), len(self._facts), self.version)


setattr(KnowledgeGraph, "assert", KnowledgeGraph.assertFact)


class Rule:
    def __init__(self, patterns: Sequence[Mapping[str, Any]], conclusion: Mapping[str, Any] | None = None, priority_value: int = 0) -> None:
        self.patterns = tuple(_freeze(dict(pattern)) for pattern in patterns)
        self.conclusion = _freeze(dict(conclusion)) if conclusion is not None else None
        self.priority_value = priority_value

    @classmethod
    def when(cls, pattern: Mapping[str, Any]) -> "Rule":
        return cls((_validate_pattern(pattern, "Rule.when"),))

    def andCondition(self, condition: Mapping[str, Any]) -> "Rule":
        return Rule(self.patterns + (_validate_pattern(condition, "rule.and"),), self.conclusion, self.priority_value)

    def then(self, conclusion: Mapping[str, Any]) -> "Rule":
        return Rule(self.patterns, _validate_pattern(conclusion, "rule.then"), self.priority_value)

    def priority(self, value: int) -> "Rule":
        return Rule(self.patterns, self.conclusion, _integer(value, "rule.priority", "value", -1000, 1000))

    def identity(self) -> str:
        if self.conclusion is None:
            _fail("INCOMPLETE_RULE", "Reasoner.new", "rule requires a conclusion")
        return _digest({"patterns": self.patterns, "conclusion": self.conclusion, "priority": self.priority_value})


setattr(Rule, "and", Rule.andCondition)


def _validate_pattern(pattern: Any, operation: str) -> Mapping[str, Any]:
    item = _mapping(pattern, operation, "pattern")
    if set(item) != {"subject", "predicate", "object"}:
        _fail("INVALID_PATTERN", operation, "pattern needs subject, predicate, and object")
    predicate = _text(item["predicate"], operation, "predicate")
    return {"subject": item["subject"], "predicate": predicate, "object": item["object"]}


@dataclass(frozen=True)
class ProofLink:
    factId: str
    ruleId: str
    premises: tuple[str, ...]
    ontology: str


@dataclass(frozen=True)
class InferenceResult:
    facts: tuple[Fact, ...]
    proofs: Mapping[str, ProofLink]
    rounds: int
    graphVersion: int
    mode: str = "full"
    recomputed: tuple[str, ...] = ()


@dataclass(frozen=True)
class Explanation:
    factId: str
    ruleId: str
    premises: tuple[str, ...]
    provenance: Mapping[str, Any]
    includesPrivateReasoning: bool = False


class Reasoner:
    def __init__(self, ontology: Ontology, rules: Sequence[Rule], options: Mapping[str, Any]) -> None:
        operation = "Reasoner.new"
        if not isinstance(ontology, Ontology):
            _fail("INVALID_ONTOLOGY", operation, "ontology is required")
        values = _sequence(rules, operation, "rules")
        if not values or len(values) > MAX_RULES or any(not isinstance(rule, Rule) for rule in values):
            _fail("INVALID_RULES", operation, "1..256 complete rules are required")
        strategy = options.get("strategy", "monotonic")
        if strategy != "monotonic":
            _fail("UNSUPPORTED_STRATEGY", operation, "non-monotonic reasoning requires a separate explicit profile")
        self.ontology = ontology
        self.rules = tuple(sorted(values, key=lambda rule: (-rule.priority_value, rule.identity())))
        self.max_rounds = _integer(options.get("maxRounds", MAX_ROUNDS), operation, "options.maxRounds", 1, MAX_ROUNDS)
        self.max_derived = _integer(options.get("maxDerived", MAX_DERIVED), operation, "options.maxDerived", 1, MAX_DERIVED)
        self._last_result: InferenceResult | None = None
        self._last_graph: KnowledgeGraph | None = None

    @classmethod
    def new(cls, ontology: Ontology, rules: Sequence[Rule], options: Mapping[str, Any] | None = None) -> "Reasoner":
        return cls(ontology, rules, _mapping(options or {}, "Reasoner.new", "options"))

    @staticmethod
    def _term(value: Any) -> Any:
        return value.identity if isinstance(value, Entity) else value

    @staticmethod
    def _bind(term: Any, actual: Any, binding: dict[str, Any]) -> bool:
        if isinstance(term, str) and term.startswith("$"):
            if term in binding:
                return binding[term] == actual
            binding[term] = actual
            return True
        return Reasoner._term(term) == actual

    def _matches(self, pattern: Mapping[str, Any], fact: Fact, binding: Mapping[str, Any]) -> dict[str, Any] | None:
        candidate = dict(binding)
        actual = (fact.subject.identity, fact.predicate, self._term(fact.object))
        if pattern["predicate"] != actual[1]:
            return None
        if not self._bind(pattern["subject"], actual[0], candidate):
            return None
        if not self._bind(pattern["object"], actual[2], candidate):
            return None
        return candidate

    def infer(self, graph: KnowledgeGraph) -> InferenceResult:
        operation = "reasoner.infer"
        if not isinstance(graph, KnowledgeGraph) or graph.ontology is not self.ontology:
            _fail("SCHEMA_MISMATCH", operation, "graph must use reasoner ontology")
        if self.ontology.validate(graph):
            _fail("INVALID_GRAPH", operation, "graph violates ontology constraints")
        facts: dict[tuple[Any, ...], Fact] = {fact.triple(): fact for fact in graph._active_facts()}
        proofs: dict[str, ProofLink] = {}
        rounds = 0
        for round_number in range(1, self.max_rounds + 1):
            pending: list[tuple[Fact, ProofLink]] = []
            for rule in self.rules:
                rule_id = rule.identity()
                bindings: list[tuple[dict[str, Any], tuple[str, ...]]] = [({}, ())]
                for pattern in rule.patterns:
                    next_bindings: list[tuple[dict[str, Any], tuple[str, ...]]] = []
                    for binding, premises in bindings:
                        for fact in sorted(facts.values(), key=lambda value: value.factId):
                            matched = self._matches(pattern, fact, binding)
                            if matched is not None:
                                next_bindings.append((matched, premises + (fact.factId,)))
                    bindings = next_bindings
                assert rule.conclusion is not None
                for binding, premises in bindings:
                    subject_identity = binding.get(rule.conclusion["subject"], rule.conclusion["subject"])
                    object_value = binding.get(rule.conclusion["object"], rule.conclusion["object"])
                    subjects = [entity for entity in graph._entities.values() if entity.identity == subject_identity]
                    if len(subjects) != 1:
                        _fail("RULE_ENTITY_MISMATCH", operation, "derived subject is not a unique graph entity")
                    range_name = self.ontology._properties.get(rule.conclusion["predicate"], (None, None))[1]
                    if range_name in self.ontology._types:
                        objects = [entity for entity in graph._entities.values() if entity.identity == object_value and self.ontology._is_subtype(entity.type, range_name)]
                        if len(objects) != 1:
                            _fail("RULE_ENTITY_MISMATCH", operation, "derived object is not a unique graph entity")
                        object_value = objects[0]
                    self_graph_subject = subjects[0]
                    predicate, checked_object = graph._validate_fact(self_graph_subject, rule.conclusion["predicate"], object_value, operation)
                    triple = (self_graph_subject.identity, predicate, self._term(checked_object))
                    if triple in facts or any(candidate.triple() == triple for candidate, _ in pending):
                        continue
                    fact_id = _digest({"graph": graph.graph_identity, "triple": triple, "rule": rule_id, "premises": premises})
                    provenance = _freeze({"source": f"rule:{rule_id}", "version": self.ontology.version, "digest": _digest(premises)})
                    derived = Fact(fact_id, self_graph_subject, predicate, checked_object, provenance, graph.version, True)
                    pending.append((derived, ProofLink(fact_id, rule_id, tuple(sorted(premises)), self.ontology.identity())))
                    if len(proofs) + len(pending) > self.max_derived:
                        _fail("INFERENCE_LIMIT", operation, "derived fact budget is exhausted")
            rounds = round_number
            if not pending:
                break
            for fact, proof in sorted(pending, key=lambda pair: pair[0].factId):
                facts[fact.triple()] = fact
                proofs[fact.factId] = proof
        else:
            _fail("INFERENCE_LIMIT", operation, "reasoner did not converge within maxRounds")
        result = InferenceResult(tuple(sorted((fact for fact in facts.values() if fact.derived), key=lambda value: value.factId)), MappingProxyType(dict(proofs)), rounds, graph.version)
        self._last_result = result
        self._last_graph = graph
        return result

    def incremental(self, changes: Mapping[str, Any]) -> InferenceResult:
        operation = "reasoner.incremental"
        item = _mapping(changes, operation, "changes")
        graph = item.get("graph")
        if not isinstance(graph, KnowledgeGraph):
            _fail("INVALID_CHANGES", operation, "changes.graph is required")
        added = tuple(_text(value, operation, "added fact") for value in _sequence(item.get("added", ()), operation, "changes.added"))
        retracted = tuple(_text(value, operation, "retracted fact") for value in _sequence(item.get("retracted", ()), operation, "changes.retracted"))
        previous = self._last_result
        result = self.infer(graph)
        changed = set(added) | set(retracted)
        affected: set[str] = set()
        if previous is not None:
            previous_ids = {fact.factId for fact in previous.facts}
            current_ids = {fact.factId for fact in result.facts}
            affected.update(previous_ids.symmetric_difference(current_ids))
            expanded = set(changed)
            progress = True
            while progress:
                progress = False
                for fact_id, proof in previous.proofs.items():
                    if fact_id not in expanded and expanded.intersection(proof.premises):
                        expanded.add(fact_id)
                        affected.add(fact_id)
                        progress = True
        mode = "full-recompute" if retracted or previous is None else "affected"
        incremental = InferenceResult(result.facts, result.proofs, result.rounds, result.graphVersion, mode, tuple(sorted(affected)))
        self._last_result = incremental
        return incremental

    def explain(self, fact: Fact | str) -> Explanation:
        operation = "reasoner.explain"
        if self._last_result is None:
            _fail("NO_INFERENCE", operation, "infer before requesting an explanation")
        identity = fact.factId if isinstance(fact, Fact) else _text(fact, operation, "fact")
        proof = self._last_result.proofs.get(identity)
        if proof is None:
            _fail("NO_PROOF", operation, "fact has no derived proof")
        return Explanation(identity, proof.ruleId, proof.premises, _freeze({"ontology": proof.ontology, "graphVersion": self._last_result.graphVersion}))


class KnowledgeQuery:
    def __init__(self, graph: KnowledgeGraph, pattern: Mapping[str, Any], conditions: Sequence[Mapping[str, Any]] = (), optional_patterns: Sequence[Mapping[str, Any]] = (), path_spec: Mapping[str, Any] | None = None, projection: Sequence[str] = ()) -> None:
        self.graph = graph
        self.pattern = _freeze(pattern)
        self.conditions = tuple(_freeze(value) for value in conditions)
        self.optional_patterns = tuple(_freeze(value) for value in optional_patterns)
        self.path_spec = _freeze(path_spec) if path_spec else None
        self.projection = tuple(projection)

    @classmethod
    def match(cls, pattern: Mapping[str, Any]) -> "KnowledgeQuery":
        operation = "KnowledgeQuery.match"
        item = dict(_mapping(pattern, operation, "pattern"))
        graph = item.pop("graph", None)
        if not isinstance(graph, KnowledgeGraph):
            _fail("GRAPH_REQUIRED", operation, "pattern.graph must be a KnowledgeGraph")
        validated = _validate_pattern(item, operation)
        if validated["predicate"] not in graph.ontology._properties:
            _fail("UNKNOWN_PROPERTY", operation, "query predicate is absent from the ontology")
        return cls(graph, validated)

    def where(self, condition: Mapping[str, Any]) -> "KnowledgeQuery":
        operation = "query.where"
        item = dict(_mapping(condition, operation, "condition"))
        if item.get("operator") not in {"eq", "ne", "prefix"}:
            _fail("UNSUPPORTED_CONDITION", operation, "operator must be eq, ne, or prefix")
        item["binding"] = _text(item.get("binding"), operation, "binding")
        return KnowledgeQuery(self.graph, self.pattern, self.conditions + (item,), self.optional_patterns, self.path_spec, self.projection)

    def optional(self, pattern: Mapping[str, Any]) -> "KnowledgeQuery":
        validated = _validate_pattern(pattern, "query.optional")
        if validated["predicate"] not in self.graph.ontology._properties:
            _fail("UNKNOWN_PROPERTY", "query.optional", "optional predicate is absent from the ontology")
        return KnowledgeQuery(self.graph, self.pattern, self.conditions, self.optional_patterns + (validated,), self.path_spec, self.projection)

    def path(self, predicate: str, bounds: Mapping[str, Any]) -> "KnowledgeQuery":
        operation = "query.path"
        item = _mapping(bounds, operation, "bounds")
        spec = {
            "predicate": _text(predicate, operation, "predicate"),
            "from": _text(item.get("from"), operation, "bounds.from"),
            "to": _text(item.get("to"), operation, "bounds.to"),
            "minDepth": _integer(item.get("minDepth", 1), operation, "bounds.minDepth", 0, MAX_PATH_DEPTH),
            "maxDepth": _integer(item.get("maxDepth"), operation, "bounds.maxDepth", 1, MAX_PATH_DEPTH),
        }
        if spec["predicate"] not in self.graph.ontology._properties:
            _fail("UNKNOWN_PROPERTY", operation, "path predicate is absent from the ontology")
        if spec["minDepth"] > spec["maxDepth"]:
            _fail("INVALID_BOUNDS", operation, "minDepth exceeds maxDepth")
        return KnowledgeQuery(self.graph, self.pattern, self.conditions, self.optional_patterns, spec, self.projection)

    def project(self, bindings: Sequence[str]) -> "KnowledgeQuery":
        operation = "query.project"
        values = _sequence(bindings, operation, "bindings")
        projection = tuple(_text(value, operation, "binding") for value in values)
        if not projection:
            _fail("EMPTY_PROJECTION", operation, "at least one binding is required")
        return KnowledgeQuery(self.graph, self.pattern, self.conditions, self.optional_patterns, self.path_spec, projection)

    @staticmethod
    def _match(pattern: Mapping[str, Any], fact: Fact, row: Mapping[str, Any]) -> Mapping[str, Any] | None:
        candidate = dict(row)
        actual = (fact.subject.identity, fact.predicate, fact.object.identity if isinstance(fact.object, Entity) else fact.object)
        if pattern["predicate"] != actual[1]:
            return None
        for term, value in zip((pattern["subject"], pattern["object"]), (actual[0], actual[2])):
            if isinstance(term, str) and term.startswith("$"):
                if term in candidate and candidate[term] != value:
                    return None
                candidate[term] = value
            elif term != value:
                return None
        candidate["$fact"] = fact.factId
        return candidate

    def _path_exists(self, start: Any, end: Any) -> bool:
        assert self.path_spec is not None
        if start == end and self.path_spec["minDepth"] == 0:
            return True
        frontier = [(start, 0)]
        visited: set[tuple[Any, int]] = set()
        while frontier:
            current, depth = frontier.pop(0)
            if (current, depth) in visited or depth >= self.path_spec["maxDepth"]:
                continue
            visited.add((current, depth))
            for fact in self.graph._active_facts():
                if fact.predicate == self.path_spec["predicate"] and fact.subject.identity == current and isinstance(fact.object, Entity):
                    next_depth = depth + 1
                    if fact.object.identity == end and next_depth >= self.path_spec["minDepth"]:
                        return True
                    frontier.append((fact.object.identity, next_depth))
        return False

    def _execute(self) -> tuple[Mapping[str, Any], ...]:
        rows: list[Mapping[str, Any]] = []
        for fact in self.graph._active_facts():
            matched = self._match(self.pattern, fact, {})
            if matched is not None:
                rows.append(matched)
        for pattern in self.optional_patterns:
            expanded: list[Mapping[str, Any]] = []
            variables = [value for value in (pattern["subject"], pattern["object"]) if isinstance(value, str) and value.startswith("$")]
            for row in rows:
                matches = [candidate for fact in self.graph._active_facts() if (candidate := self._match(pattern, fact, row)) is not None]
                if matches:
                    expanded.extend(matches)
                else:
                    fallback = dict(row)
                    for variable in variables:
                        fallback.setdefault(variable, None)
                    expanded.append(fallback)
            rows = expanded
        for condition in self.conditions:
            expected = condition.get("value")
            operator = condition["operator"]
            actual_rows: list[Mapping[str, Any]] = []
            for row in rows:
                actual = row.get(condition["binding"])
                keep = actual == expected if operator == "eq" else actual != expected if operator == "ne" else isinstance(actual, str) and actual.startswith(str(expected))
                if keep:
                    actual_rows.append(row)
            rows = actual_rows
        if self.path_spec:
            rows = [row for row in rows if self._path_exists(row.get(self.path_spec["from"]), row.get(self.path_spec["to"]))]
        projected = []
        for row in rows:
            value = {key: row.get(key) for key in self.projection} if self.projection else dict(row)
            projected.append(_freeze(value))
        projected.sort(key=_canonical)
        return tuple(projected)

    def explain(self) -> Mapping[str, Any]:
        estimates = sum(1 for fact in self.graph._active_facts() if fact.predicate == self.pattern["predicate"])
        return _freeze({"index": "predicate+subject", "rules": (), "estimatedRows": estimates, "pathBound": self.path_spec["maxDepth"] if self.path_spec else 0})

    def stream(self) -> "ResultStream":
        return ResultStream(self._execute())

    def collect(self, limit: int) -> tuple[Mapping[str, Any], ...]:
        maximum = _integer(limit, "query.collect", "limit", 1, MAX_QUERY_RESULTS)
        return self._execute()[:maximum]


class ResultStream:
    def __init__(self, rows: Sequence[Mapping[str, Any]]) -> None:
        self._rows = tuple(rows)
        self._offset = 0

    def request(self, count: int) -> tuple[Mapping[str, Any], ...]:
        amount = _integer(count, "resultStream.request", "count", 1, MAX_QUERY_RESULTS)
        result = self._rows[self._offset : self._offset + amount]
        self._offset += len(result)
        return result


@dataclass(frozen=True)
class SearchResult:
    identity: str
    item: Mapping[str, Any]
    score: float
    _breakdown: Mapping[str, float]
    _provenance: Mapping[str, Any]

    def scoreBreakdown(self) -> Mapping[str, float]:
        return self._breakdown

    def provenance(self) -> Mapping[str, Any]:
        return self._provenance


class SemanticIndex:
    def __init__(self, items: Sequence[Mapping[str, Any]], representation: Mapping[str, Sequence[float]], options: Mapping[str, Any]) -> None:
        operation = "SemanticIndex.build"
        self.version = _integer(options.get("version"), operation, "options.version", 1, (1 << 31) - 1)
        self.dimension = _integer(options.get("dimension"), operation, "options.dimension", 1, MAX_VECTOR_DIMENSION)
        self.max_items = _integer(options.get("maxItems", MAX_INDEX_ITEMS), operation, "options.maxItems", 1, MAX_INDEX_ITEMS)
        if options.get("metric", "cosine") != "cosine":
            _fail("UNSUPPORTED_METRIC", operation, "only cosine is supported")
        self._items: dict[str, Mapping[str, Any]] = {}
        self._vectors: dict[str, tuple[float, ...]] = {}
        self._removals: list[Mapping[str, Any]] = []
        queries = _mapping(options.get("queryRepresentations", {}), operation, "options.queryRepresentations")
        self._query_vectors = {str(text): self._vector(vector, operation) for text, vector in queries.items()}
        values = _sequence(items, operation, "items")
        vectors = _mapping(representation, operation, "representation")
        if len(values) > self.max_items:
            _fail("INDEX_LIMIT", operation, "item budget is exhausted")
        for item in values:
            identity = _text(_mapping(item, operation, "item").get("identity"), operation, "item.identity")
            if identity not in vectors:
                _fail("MISSING_REPRESENTATION", operation, f"missing vector for {identity}")
            self._insert(item, vectors[identity], operation)

    @classmethod
    def build(cls, items: Sequence[Mapping[str, Any]], representation: Mapping[str, Sequence[float]], options: Mapping[str, Any]) -> "SemanticIndex":
        return cls(items, representation, _mapping(options, "SemanticIndex.build", "options"))

    def _vector(self, value: Any, operation: str) -> tuple[float, ...]:
        vector = _sequence(value, operation, "representation")
        if len(vector) != self.dimension:
            _fail("DIMENSION_MISMATCH", operation, "vector dimension differs from index")
        result = tuple(_number(component, operation, "component") for component in vector)
        if math.sqrt(sum(component * component for component in result)) == 0.0:
            _fail("ZERO_VECTOR", operation, "zero vectors are not searchable")
        return result

    def _insert(self, item: Mapping[str, Any], representation: Sequence[float], operation: str) -> None:
        value = dict(_mapping(item, operation, "item"))
        identity = _text(value.get("identity"), operation, "item.identity")
        _text(value.get("text"), operation, "item.text")
        value["provenance"] = _provenance(value.get("provenance"), operation)
        vector = self._vector(representation, operation)
        self._items[identity] = _freeze(value)
        self._vectors[identity] = vector

    def insert(self, item: Mapping[str, Any], representation: Sequence[float]) -> "SemanticIndex":
        operation = "index.insert"
        identity = _text(_mapping(item, operation, "item").get("identity"), operation, "item.identity")
        if identity not in self._items and len(self._items) >= self.max_items:
            _fail("INDEX_LIMIT", operation, "item budget is exhausted")
        self._insert(item, representation, operation)
        self.version += 1
        return self

    def remove(self, identity: str) -> Mapping[str, Any]:
        operation = "index.remove"
        key = _text(identity, operation, "identity")
        if key not in self._items:
            _fail("UNKNOWN_ITEM", operation, "item is absent")
        provenance = self._items[key]["provenance"]
        del self._items[key]
        del self._vectors[key]
        self.version += 1
        removal = _freeze({"identity": key, "indexVersion": self.version, "sourceDigest": _digest(provenance)})
        self._removals.append(removal)
        return removal

    @staticmethod
    def _cosine(left: Sequence[float], right: Sequence[float]) -> float:
        dot = sum(a * b for a, b in zip(left, right))
        return dot / math.sqrt(sum(a * a for a in left) * sum(b * b for b in right))

    def search(self, query: Sequence[float], limit: int) -> tuple[SearchResult, ...]:
        operation = "index.search"
        vector = self._vector(query, operation)
        maximum = _integer(limit, operation, "limit", 1, MAX_QUERY_RESULTS)
        results = []
        for identity in sorted(self._items):
            score = self._cosine(vector, self._vectors[identity])
            provenance = _freeze({"source": self._items[identity]["provenance"], "indexVersion": self.version, "representationDigest": _digest(self._vectors[identity]), "claim": "similarity-only"})
            results.append(SearchResult(identity, self._items[identity], score, _freeze({"semantic": score}), provenance))
        return tuple(sorted(results, key=lambda result: (-result.score, result.identity))[:maximum])

    def queryVector(self, text: str) -> tuple[float, ...]:
        key = _text(text, "search.query", "text")
        if key not in self._query_vectors:
            _fail("MISSING_REPRESENTATION", "search.query", "query needs an explicit local representation")
        return self._query_vectors[key]


class TextIndex:
    def __init__(self, items: Sequence[Mapping[str, Any]], version: int = 1) -> None:
        self.version = _integer(version, "TextIndex", "version", 1, (1 << 31) - 1)
        self._items = {str(item["identity"]): _freeze(dict(item)) for item in items}

    def score(self, identity: str, text: str) -> float:
        terms = {term.lower() for term in text.split() if term}
        document = {term.lower() for term in str(self._items.get(identity, {}).get("text", "")).split() if term}
        return len(terms & document) / max(1, len(terms))


class HybridSearch:
    def __init__(self, graph: KnowledgeGraph, textIndex: TextIndex, semanticIndex: SemanticIndex) -> None:
        operation = "HybridSearch.new"
        if not isinstance(graph, KnowledgeGraph) or not isinstance(textIndex, TextIndex) or not isinstance(semanticIndex, SemanticIndex):
            _fail("INVALID_COMPONENT", operation, "graph, text index, and semantic index are required")
        self.graph = graph
        self.text_index = textIndex
        self.semantic_index = semanticIndex

    @classmethod
    def new(cls, graph: KnowledgeGraph, textIndex: TextIndex, semanticIndex: SemanticIndex) -> "HybridSearch":
        return cls(graph, textIndex, semanticIndex)

    def query(self, text: str, filters: Mapping[str, Any], limit: int) -> tuple[SearchResult, ...]:
        operation = "search.query"
        source = _text(text, operation, "text")
        config = _mapping(filters, operation, "filters")
        maximum = _integer(limit, operation, "limit", 1, MAX_QUERY_RESULTS)
        allowed_type = config.get("entityType")
        if allowed_type is not None:
            allowed_type = self.graph.ontology._require_type(allowed_type, operation)
        semantic = self.semantic_index.search(self.semantic_index.queryVector(source), MAX_QUERY_RESULTS)
        results: list[SearchResult] = []
        for candidate in semantic:
            entities = [entity for entity in self.graph._entities.values() if entity.identity == candidate.identity]
            if allowed_type is not None and not any(self.graph.ontology._is_subtype(entity.type, allowed_type) for entity in entities):
                continue
            keyword = self.text_index.score(candidate.identity, source)
            graph_score = 1.0 if entities and any(self.graph.factsAbout(entity, MAX_QUERY_RESULTS) for entity in entities) else 0.0
            combined = 0.35 * keyword + 0.45 * candidate.score + 0.20 * graph_score
            breakdown = _freeze({"keyword": keyword, "semantic": candidate.score, "graph": graph_score, "combined": combined})
            provenance = _freeze({"item": candidate.provenance(), "textIndexVersion": self.text_index.version, "graphVersion": self.graph.version, "claim": "ranking-not-proof"})
            results.append(SearchResult(candidate.identity, candidate.item, combined, breakdown, provenance))
        return tuple(sorted(results, key=lambda result: (-result.score, result.identity))[:maximum])


@dataclass(frozen=True)
class KnowledgeContext:
    text: str
    citations: tuple[str, ...]
    queryDigest: str
    graphVersion: int
    truncated: bool


@dataclass(frozen=True)
class ClaimResult:
    status: str
    evidence: tuple[str, ...]
    graphVersion: int


class Knowledge:
    def __init__(self, graph: KnowledgeGraph) -> None:
        if not isinstance(graph, KnowledgeGraph):
            _fail("INVALID_GRAPH", "Knowledge", "graph is required")
        self.graph = graph

    def context(self, query: KnowledgeQuery, budget: Mapping[str, Any]) -> KnowledgeContext:
        operation = "knowledge.context"
        if not isinstance(query, KnowledgeQuery) or query.graph is not self.graph:
            _fail("QUERY_SCOPE", operation, "query must target this knowledge graph")
        config = _mapping(budget, operation, "budget")
        maximum_results = _integer(config.get("maxResults"), operation, "budget.maxResults", 1, MAX_QUERY_RESULTS)
        maximum_bytes = _integer(config.get("maxBytes"), operation, "budget.maxBytes", 1, MAX_CONTEXT_BYTES)
        rows = query.collect(maximum_results)
        fragments: list[str] = []
        citations: list[str] = []
        used = 0
        truncated = False
        for row in rows:
            rendered = _canonical(row).decode("ascii")
            encoded = rendered.encode("utf-8")
            if used + len(encoded) > maximum_bytes:
                truncated = True
                break
            fragments.append(rendered)
            used += len(encoded)
            fact_id = row.get("$fact")
            if isinstance(fact_id, str):
                citations.append(fact_id)
        return KnowledgeContext("\n".join(fragments), tuple(dict.fromkeys(citations)), _digest({"pattern": query.pattern, "conditions": query.conditions, "projection": query.projection}), self.graph.version, truncated)

    def verifyClaim(self, claim: Mapping[str, Any]) -> ClaimResult:
        operation = "knowledge.verifyClaim"
        item = _mapping(claim, operation, "claim")
        if set(item) != {"subject", "predicate", "object"}:
            _fail("INVALID_CLAIM", operation, "claim needs subject, predicate, and object")
        subject = _text(item["subject"], operation, "claim.subject")
        predicate = _text(item["predicate"], operation, "claim.predicate")
        expected = item["object"]
        candidates = [fact for fact in self.graph._active_facts() if fact.subject.identity == subject and fact.predicate == predicate]
        exact = [fact for fact in candidates if (fact.object.identity if isinstance(fact.object, Entity) else fact.object) == expected]
        if exact and len(candidates) == len(exact):
            status, evidence = "supported", exact
        elif exact:
            status, evidence = "ambiguous", candidates
        elif candidates:
            functional = any(constraint["kind"] == "cardinality" and constraint.get("property") == predicate and constraint.get("maximum") == 1 for constraint in self.graph.ontology._constraints)
            status, evidence = ("contradicted" if functional else "ambiguous"), candidates
        else:
            status, evidence = "unknown", []
        return ClaimResult(status, tuple(sorted(fact.factId for fact in evidence)), self.graph.version)

    def detectContradictions(self, scope: Mapping[str, Any]) -> tuple[Mapping[str, Any], ...]:
        operation = "knowledge.detectContradictions"
        config = _mapping(scope, operation, "scope")
        predicate_filter = config.get("predicate")
        if predicate_filter is not None:
            predicate_filter = _text(predicate_filter, operation, "scope.predicate")
        contradictions: list[Mapping[str, Any]] = []
        groups: dict[tuple[str, str], list[Fact]] = {}
        for fact in self.graph._active_facts():
            if predicate_filter is None or fact.predicate == predicate_filter:
                groups.setdefault((fact.subject.identity, fact.predicate), []).append(fact)
        for (subject, predicate), facts in groups.items():
            values = {fact.object.identity if isinstance(fact.object, Entity) else _canonical(fact.object).decode("ascii") for fact in facts}
            functional = any(constraint["kind"] == "cardinality" and constraint.get("property") == predicate and constraint.get("maximum") == 1 for constraint in self.graph.ontology._constraints)
            if functional and len(values) > 1:
                contradictions.append(_freeze({"subject": subject, "predicate": predicate, "facts": tuple(sorted(fact.factId for fact in facts)), "code": "FUNCTIONAL_CONFLICT"}))
        return tuple(sorted(contradictions, key=_canonical))


@dataclass(frozen=True)
class GroundingAudit:
    queryDigest: str
    citationDigests: tuple[str, ...]
    versions: tuple[int, ...]
    decision: str

    def audit(self) -> Mapping[str, Any]:
        return _freeze({"queryDigest": self.queryDigest, "citationDigests": self.citationDigests, "versions": self.versions, "decision": self.decision, "sensitiveContent": "omitted"})


@dataclass(frozen=True)
class GroundedGeneration:
    text: str
    _citations: tuple[str, ...]
    grounding: GroundingAudit

    def citations(self) -> tuple[str, ...]:
        return self._citations


class Generation:
    def __init__(self, text: str, category: str = "general", policy: "GroundingRequirement | None" = None) -> None:
        self.text = _text(text, "Generation", "text")
        self.category = _text(category, "Generation", "category")
        if policy is not None and not isinstance(policy, GroundingRequirement):
            _fail("INVALID_POLICY", "Generation", "policy must be a GroundingRequirement")
        self.policy = policy

    def ground(self, results: KnowledgeContext) -> GroundedGeneration:
        operation = "generation.ground"
        if not isinstance(results, KnowledgeContext) or not results.citations:
            _fail("GROUNDING_REQUIRED", operation, "a cited knowledge context is required")
        if self.policy is not None and self.category in self.policy.categories and len(results.citations) < self.policy.minimumCitations:
            _fail("GROUNDING_POLICY", operation, "grounding does not satisfy the required citation count")
        audit = GroundingAudit(results.queryDigest, tuple(_digest(citation) for citation in results.citations), (results.graphVersion,), "grounded")
        return GroundedGeneration(self.text, results.citations, audit)


@dataclass(frozen=True)
class GroundingRequirement:
    categories: frozenset[str]
    minimumCitations: int


class AiPolicy:
    @staticmethod
    def requireGrounding(policy: Mapping[str, Any]) -> GroundingRequirement:
        operation = "AiPolicy.requireGrounding"
        item = _mapping(policy, operation, "policy")
        categories = item.get("categories")
        if isinstance(categories, (str, bytes)) or not isinstance(categories, (set, frozenset, list, tuple)):
            _fail("INVALID_POLICY", operation, "categories must be a literal collection")
        names = frozenset(_text(value, operation, "category") for value in categories)
        if not names:
            _fail("INVALID_POLICY", operation, "at least one grounded category is required")
        minimum = _integer(item.get("minimumCitations", 1), operation, "minimumCitations", 1, 32)
        return GroundingRequirement(names, minimum)


@dataclass(frozen=True)
class KnowledgeCapability:
    graphs: frozenset[str]
    indexes: frozenset[str]


class KnowledgeAgent:
    def __init__(self, name: str, scope: KnowledgeCapability | None = None) -> None:
        self.name = _text(name, "KnowledgeAgent", "name")
        self.scope = scope

    def knowledgeScope(self, capability: Mapping[str, Any]) -> "KnowledgeAgent":
        operation = "agent.knowledgeScope"
        item = _mapping(capability, operation, "capability")
        graphs = item.get("graphs")
        indexes = item.get("indexes")
        if isinstance(graphs, (str, bytes)) or not isinstance(graphs, (set, frozenset, list, tuple)):
            _fail("INVALID_CAPABILITY", operation, "graphs must be a literal allowlist")
        if isinstance(indexes, (str, bytes)) or not isinstance(indexes, (set, frozenset, list, tuple)):
            _fail("INVALID_CAPABILITY", operation, "indexes must be a literal allowlist")
        scope = KnowledgeCapability(frozenset(_text(value, operation, "graph") for value in graphs), frozenset(_text(value, operation, "index") for value in indexes))
        return KnowledgeAgent(self.name, scope)

    def authorize(self, graph: str, index: str) -> None:
        operation = "agent.knowledgeScope"
        if self.scope is None or graph not in self.scope.graphs or index not in self.scope.indexes:
            _fail("CAPABILITY_DENIED", operation, "knowledge graph or index is outside the agent scope")


__all__ = [
    "AiPolicy",
    "ClaimResult",
    "CompatibilityResult",
    "Entity",
    "Explanation",
    "Fact",
    "Generation",
    "GroundedGeneration",
    "GroundingAudit",
    "GroundingRequirement",
    "HybridSearch",
    "InferenceResult",
    "Knowledge",
    "KnowledgeAgent",
    "KnowledgeCapability",
    "KnowledgeContext",
    "KnowledgeError",
    "KnowledgeGraph",
    "KnowledgeQuery",
    "Ontology",
    "Reasoner",
    "ResultStream",
    "Rule",
    "SearchResult",
    "SemanticIndex",
    "TextIndex",
    "VerificationResult",
]
