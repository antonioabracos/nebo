#!/usr/bin/env python3
"""Independent value/effect oracle for all 47 current G023 surfaces."""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
from typing import Any, Callable

from compiler.sdk.ai import (
    Agent,
    AiError,
    AiPolicy,
    CausalLanguageModel,
    Evaluation,
    Generator,
    KvCache,
    OutputSchema,
    Prompt,
    Sampler,
    Tool,
    ToolCall,
    ToolExecutionContext,
    ToolRegistry,
    Tokenizer,
)


FIXTURES = Path("tests/rf204/G023/fixtures").resolve()
TOKENIZER_PATH = FIXTURES / "tokenizer.json"
MODEL_PATH = FIXTURES / "tiny-model.json"
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
    except AiError as error:
        require(error.code == code, f"{operation} code was {error.code}, expected {code}")
        require(error.operation == operation, f"negative operation was {error.operation}, expected {operation}")
        COUNTS["negative"] += 1
        COUNTS["diagnostics"] += 1
        EVIDENCE.append(f"negative:{operation}:{code}")
        return
    raise AssertionError(f"negative case unexpectedly passed: {operation}:{code}")


def load_tokenizer() -> Tokenizer:
    return Tokenizer.load(str(TOKENIZER_PATH), {"allowedRoot": str(FIXTURES), "expectedChecksum": "658fceb153e6f4e88f849defb354368d0056309e54c39d8e36858b8ae2378fa5"})


def load_model() -> CausalLanguageModel:
    return CausalLanguageModel.load(str(MODEL_PATH), {"allowedRoot": str(FIXTURES), "expectedChecksum": "441cd3871ae0b4bd77f21bd48cc806d2418aca44490d04c18974d69cb333f563"})


def subgroup_s01() -> None:
    tokenizer = load_tokenizer()
    surface("G023-S01-01", tokenizer.checksum.startswith("658fceb1") and tokenizer.merges == (), tokenizer.provenance())
    encoded = tokenizer.encode("hello world!", {"maximumTokens": 8, "errorPolicy": "reject"})
    surface("G023-S01-02", encoded == (4, 6, 5, 7), encoded)
    decoded = tokenizer.decode(encoded, {"specialPolicy": "skip", "errorPolicy": "reject"})
    surface("G023-S01-03", decoded == "hello world!", decoded)
    surface("G023-S01-04", tokenizer.vocabularySize() == 15, tokenizer.vocabularySize())
    surface("G023-S01-05", tokenizer.specialToken("EOS") == 2 and tokenizer.specialToken("bos") == 1, 2)
    surface("G023-S01-06", tokenizer.count("hello world!") == 4, tokenizer.count("hello world!"))

    claim("composition", tokenizer.decode(tokenizer.encode("hello!"), None) == "hello!", "tokenizer roundtrip composes")
    claim("metamorphic", tokenizer.encode("world!") != encoded, "text governs token IDs")
    snapshot = tokenizer.tokens
    tokenizer.encode("hello", None)
    claim("ownership", isinstance(snapshot, tuple) and snapshot == tokenizer.tokens, "vocabulary is an immutable snapshot")
    claim("boundary", tokenizer.encode("", {"maximumTokens": 1}) == (), "empty text has zero tokens")
    claim("determinism", load_tokenizer().encode("hello world!") == encoded, "tokenization is deterministic")
    before = tokenizer.vocabularySize()
    negative("UNKNOWN_TEXT", "tokenizer.encode", lambda: tokenizer.encode("?", {"errorPolicy": "reject"}))
    claim("failure_atomicity", tokenizer.vocabularySize() == before, "failed encode does not mutate vocabulary")
    claim("adversarial", tokenizer.encode("?", {"errorPolicy": "replace"}) == (3,), "unknown text follows explicit replacement policy")
    negative("IDENTITY_MISMATCH", "Tokenizer.load", lambda: Tokenizer.load(str(TOKENIZER_PATH), {"allowedRoot": str(FIXTURES), "expectedChecksum": "0" * 64}))
    negative("MALFORMED_MANIFEST", "Tokenizer.load", lambda: Tokenizer.load(str(FIXTURES / "malformed.json"), {"allowedRoot": str(FIXTURES)}))
    negative("PATH_OUTSIDE_ROOT", "Tokenizer.load", lambda: Tokenizer.load(str(MODEL_PATH), {"allowedRoot": str(FIXTURES / "child")}))
    unsupported_tokenizer = json.loads(TOKENIZER_PATH.read_text())
    unsupported_tokenizer["merges"] = (("h", "e"),)
    negative("UNSUPPORTED_MERGES", "Tokenizer.load", lambda: Tokenizer(unsupported_tokenizer, "f" * 64))
    negative("INVALID_INTEGER", "tokenizer.encode", lambda: tokenizer.encode("hello", {"maximumTokens": True}))
    negative("INVALID_BOOLEAN", "tokenizer.encode", lambda: tokenizer.encode("hello", {"addBos": 1}))
    negative("UNKNOWN_TOKEN", "tokenizer.decode", lambda: tokenizer.decode((3,), {"errorPolicy": "reject"}))
    negative("SPECIAL_TOKEN", "tokenizer.decode", lambda: tokenizer.decode((1,), {"specialPolicy": "error"}))
    negative("UNKNOWN_SPECIAL_TOKEN", "tokenizer.specialToken", lambda: tokenizer.specialToken("MASK"))


def independent_logits(model: CausalLanguageModel, tokens: tuple[int, ...]) -> tuple[float, ...]:
    accumulator = sum((index + 1) * (token + 1) for index, token in enumerate(tokens))
    return tuple(
        bias + ((accumulator * (candidate + model.token_scale) + len(tokens) * model.position_scale) % 97.0) - 48.0
        for candidate, bias in enumerate(model.bias)
    )


def subgroup_s02() -> None:
    model = load_model()
    surface("G023-S02-01", model.vocabulary_size == 15 and model.checksum.startswith("441cd387") and model.quantization == "none-f64-reference", model.provenance())
    cache = KvCache.new({"maximumLength": 64, "modelChecksum": model.checksum})
    result = model.forward((4, 6, 5, 7), cache)
    expected = independent_logits(model, (4, 6, 5, 7))
    surface("G023-S02-02", result.logits == expected and result.operations == 60, result.logits)
    second_cache = KvCache.new({"maximumLength": 8, "modelChecksum": model.checksum})
    surface("G023-S02-03", second_cache.length() == 0 and second_cache.maximum_length == 8, second_cache.maximum_length)
    surface("G023-S02-04", cache.length() == 4, cache.length())
    generation_before = cache.generation
    cache.truncate(2)
    surface("G023-S02-05", cache.length() == 2 and cache.generation == generation_before + 1, cache.tokens)
    surface("G023-S02-06", model.contextLength() == 64, model.contextLength())

    altered = independent_logits(model, (4, 6, 5, 8))
    claim("metamorphic", altered != expected, "causal tokens govern logits")
    model.forward((5,), cache)
    claim("composition", cache.tokens == (4, 6, 5), "truncate and forward compose")
    cache_snapshot = cache.tokens
    model.forward((7,), cache)
    claim("ownership", cache_snapshot == (4, 6, 5) and cache.tokens != cache_snapshot, "cache snapshots are detached")
    claim("boundary", KvCache.new({"maximumLength": 1}).maximum_length == 1, "minimum KV cache")
    repeat_cache = KvCache.new({"maximumLength": 64, "modelChecksum": model.checksum})
    claim("determinism", load_model().forward((4, 6, 5, 7), repeat_cache).logits == expected, "CPU model is deterministic")
    before_invalid = cache.tokens
    negative("INVALID_INTEGER", "model.forward", lambda: model.forward((True,), cache))
    claim("failure_atomicity", cache.tokens == before_invalid, "invalid token does not append to cache")
    claim("adversarial", max(range(15), key=lambda token: (result.logits[token], -token)) == 8, "independent argmax checks observed logits")
    negative("IDENTITY_MISMATCH", "CausalLanguageModel.load", lambda: CausalLanguageModel.load(str(MODEL_PATH), {"allowedRoot": str(FIXTURES), "expectedChecksum": "f" * 64}))
    unsupported_model = json.loads(MODEL_PATH.read_text())
    unsupported_model["quantization"] = "int4"
    negative("UNSUPPORTED_QUANTIZATION", "CausalLanguageModel.load", lambda: CausalLanguageModel(unsupported_model, "f" * 64))
    negative("INVALID_CACHE", "model.forward", lambda: model.forward((1,), object()))
    negative("IDENTITY_MISMATCH", "model.forward", lambda: model.forward((1,), KvCache.new({"maximumLength": 4, "modelChecksum": "a" * 64})))
    negative("EMPTY_TOKENS", "model.forward", lambda: model.forward((), KvCache.new({"maximumLength": 4})))
    full_cache = KvCache.new({"maximumLength": 1})
    model.forward((1,), full_cache)
    negative("CONTEXT_LIMIT", "model.forward", lambda: model.forward((2,), full_cache))
    negative("LIMIT_EXCEEDED", "cache.truncate", lambda: cache.truncate(cache.length() + 1))


def subgroup_s03() -> None:
    tokenizer = load_tokenizer()
    model = load_model()
    greedy = Sampler.greedy()
    surface("G023-S03-01", greedy.mode == "greedy", greedy.mode)
    temperature = Sampler.temperature(0.75)
    surface("G023-S03-02", temperature.mode == "temperature" and temperature.parameter == 0.75, temperature.parameter)
    top_k = Sampler.topK(3)
    surface("G023-S03-03", top_k.mode == "top-k" and top_k.parameter == 3, top_k.parameter)
    top_p = Sampler.topP(0.8)
    surface("G023-S03-04", top_p.mode == "top-p" and top_p.parameter == 0.8, top_p.parameter)
    penalized = greedy.repetitionPenalty(1.5)
    surface("G023-S03-05", penalized.penalty == 1.5 and greedy.penalty == 1.0, penalized.penalty)
    generator = Generator.new(model, tokenizer, penalized)
    surface("G023-S03-06", generator.model is model and generator.tokenizer is tokenizer, True)
    generated = generator.generate("hello", {"maxTokens": 3, "seed": 11, "stopTokens": ()})
    surface("G023-S03-07", 1 <= len(generated.tokens) <= 3 and generated.operations > 0 and bool(generated.text) and generated.finishReason in {"stop", "length"}, generated)
    generator.cancel()
    surface("G023-S03-08", generator._cancelled and generator._cache is not None and generator._cache.length() == 0, "cache-released")

    repeat = Generator.new(model, tokenizer, penalized).generate("hello", {"maxTokens": 3, "seed": 11, "stopTokens": ()})
    claim("determinism", generated == repeat, "seeded generation is deterministic")
    changed = Generator.new(model, tokenizer, penalized).generate("world", {"maxTokens": 3, "seed": 11, "stopTokens": ()})
    claim("metamorphic", changed.tokens != generated.tokens, "prompt governs generated tokens")
    claim("composition", tokenizer.decode(generated.tokens, {"specialPolicy": "skip", "errorPolicy": "replace"}) == generated.text, "model sampling and decoding compose")
    tokens_snapshot = generated.tokens
    Generator.new(model, tokenizer, greedy).generate("hello!", {"maxTokens": 1, "seed": 0, "stopTokens": ()})
    claim("ownership", generated.tokens == tokens_snapshot, "generation result is immutable")
    claim("boundary", len(Generator.new(model, tokenizer, greedy).generate("hello", {"maxTokens": 1, "seed": 0, "stopTokens": ()}).tokens) == 1, "one-token generation")
    negative("CANCELLED", "generator.generate", lambda: generator.generate("hello", {"maxTokens": 1}))
    claim("failure_atomicity", generator._cache is not None and generator._cache.length() == 0, "cancelled generation retains released cache")
    logits = independent_logits(model, (4,))
    selected = top_k._select(logits, (), 9, 0)
    claim("adversarial", selected in sorted(range(15), key=lambda token: (-logits[token], token))[:3], "top-K cannot escape candidate set")
    negative("INVALID_TEMPERATURE", "Sampler.temperature", lambda: Sampler.temperature(0.0))
    negative("INVALID_INTEGER", "Sampler.topK", lambda: Sampler.topK(True))
    negative("INVALID_PROBABILITY", "Sampler.topP", lambda: Sampler.topP(1.1))
    negative("INVALID_PENALTY", "sampler.repetitionPenalty", lambda: greedy.repetitionPenalty(0.5))
    short_manifest = json.loads(TOKENIZER_PATH.read_text())
    short_manifest["tokens"] = short_manifest["tokens"][:-1]
    short_tokenizer = Tokenizer(short_manifest, "f" * 64)
    negative("MODEL_TOKENIZER_MISMATCH", "Generator.new", lambda: Generator.new(model, short_tokenizer, greedy))
    negative("CONTEXT_LIMIT", "generator.generate", lambda: Generator.new(model, tokenizer, greedy).generate("?" * 63, {"maxTokens": 2, "seed": 0, "stopTokens": ()}))


def subgroup_s04() -> None:
    base = Prompt.new(({"role": "user", "text": "h"},))
    surface("G023-S04-01", base.render() == "[user] h", base.render())
    with_system = base.withSystem("hello")
    surface("G023-S04-02", with_system.parts[0]["role"] == "system" and base.parts[0]["role"] == "user", with_system.render())
    context_text = "world"
    context = with_system.withContext({"text": context_text, "provenance": {"source": "fixture:context", "digest": hashlib.sha256(context_text.encode()).hexdigest()}})
    surface("G023-S04-03", context.parts[-1]["role"] == "context" and context.parts[-1]["provenance"]["source"] == "fixture:context", context.render())
    schema = OutputSchema.fromType({"answer": "int", "safe": "bool"})
    surface("G023-S04-04", tuple(schema.fields) == ("answer", "safe") and len(schema.digest) == 64, schema.fields)
    structured = Generator.new(load_model(), load_tokenizer(), Sampler.greedy()).generateStructured(context, schema)
    surface("G023-S04-05", set(structured.value) == {"answer", "safe"} and isinstance(structured.value["answer"], int) and isinstance(structured.value["safe"], bool), structured.value)
    surface("G023-S04-06", structured.validationErrors() == (), structured.validationErrors())

    changed = base.withSystem("world")
    claim("metamorphic", changed.render() != with_system.render(), "system text governs rendered prompt")
    claim("composition", structured.provenance()["generation"]["model"] == load_model().checksum, "prompt schema generation and provenance compose")
    parts_snapshot = context.parts
    base.withSystem("world")
    claim("ownership", context.parts == parts_snapshot and isinstance(parts_snapshot, tuple), "prompt parts are immutable")
    claim("boundary", len(OutputSchema.fromType({"x": "int"}).fields) == 1, "single-field eligible schema")
    repeat = Generator.new(load_model(), load_tokenizer(), Sampler.greedy()).generateStructured(context, schema)
    claim("determinism", repeat.value == structured.value, "structured generation is deterministic")
    negative("INVALID_ROLE", "Prompt.new", lambda: Prompt.new(({"role": "root", "text": "h"},)))
    negative("PROVENANCE_MISMATCH", "Prompt.new", lambda: Prompt.new(({"role": "context", "text": "h", "provenance": {"source": "x", "digest": "0" * 64}},)))
    negative("PROVENANCE_MISMATCH", "prompt.withContext", lambda: base.withContext({"text": "h", "provenance": {"source": "x", "digest": "0" * 64}}))
    negative("INELIGIBLE_TYPE", "OutputSchema.fromType", lambda: OutputSchema.fromType({"x": "object"}))
    negative("INVALID_COMPONENT", "generator.generateStructured", lambda: Generator.new(load_model(), load_tokenizer(), Sampler.greedy()).generateStructured("h", schema))
    claim("failure_atomicity", base.parts == ({"role": "user", "text": "h", "provenance": None},), "failed prompt extension leaves original unchanged")
    claim("adversarial", "fixture:context" in repr(context.parts) and "fixture:context" not in base.render(), "context provenance is explicit rather than ambient")


def add(left: int, right: int) -> int:
    return left + right


def wrong_return(value: int) -> str:
    return str(value)


def subgroup_s05() -> None:
    schema = {"arguments": {"left": "int", "right": "int"}, "returns": "int", "capabilities": ("compute",), "effect": "pure", "version": 1}
    tool = Tool.fromFunction(add, schema)
    surface("G023-S05-01", tool.name == "add" and tool.arguments["left"] == "int", tool.name)
    surface("G023-S05-02", tool.requiredCapabilities() == frozenset({"compute"}), tool.requiredCapabilities())
    registry = ToolRegistry(("add",)).register(tool)
    surface("G023-S05-03", registry._tools["add"] is tool, tuple(registry._tools))
    call = ToolCall("add", {"left": 2, "right": 5}).validate(registry)
    surface("G023-S05-04", call._tool is tool and len(call.call_id) == 64, call.call_id)
    result = call.execute(ToolExecutionContext(("compute",), (), 1))
    surface("G023-S05-05", result.value == 7 and result.tool == "add", result)
    provenance = result.provenance()
    surface("G023-S05-06", provenance["identity"] == result.identity and provenance["effect"] == "pure", provenance)

    reversible_state: list[int] = []
    def store(value: int) -> int:
        reversible_state.append(value)
        return value
    def compensate(arguments: dict[str, Any], value: Any) -> None:
        require(reversible_state[-1] == value == arguments["value"], "compensation identity")
        reversible_state.pop()
    reversible = Tool.fromFunction(store, {"arguments": {"value": "int"}, "returns": "int", "capabilities": ("compute",), "effect": "reversible", "compensate": compensate, "requiresApproval": True})
    reversible_registry = ToolRegistry(("store",)).register(reversible)
    approval_call = ToolCall("store", {"value": 9}).validate(reversible_registry)
    approval = approval_call.requireApproval()
    surface("G023-S05-07", approval.required and approval.callId == approval_call.call_id and reversible_state == [], approval)

    changed = ToolCall("add", {"left": 4, "right": 5}).validate(registry).execute(ToolExecutionContext(("compute",), (), 1))
    claim("metamorphic", changed.value == 9 and changed.identity != result.identity, "tool arguments govern value and provenance")
    claim("composition", provenance["callId"] == call.call_id and result.value == add(2, 5), "registry validation execution and provenance compose")
    registry_snapshot = tuple(registry._tools)
    ToolRegistry(("add",)).register(tool)
    arguments_immutable = False
    try:
        call.arguments["left"] = 99
    except TypeError:
        arguments_immutable = True
    claim("ownership", tuple(registry._tools) == registry_snapshot and arguments_immutable, "registries are independent and validated call arguments are immutable")
    claim("boundary", ToolExecutionContext(("compute",), (), 0).remaining_calls == 0, "zero tool-call budget is representable")
    claim("determinism", ToolCall("add", {"left": 2, "right": 5}).call_id == call.call_id, "tool-call identity is canonical")
    calls = {"count": 0}
    def counted(value: int) -> int:
        calls["count"] += 1
        return value
    counted_tool = Tool.fromFunction(counted, {"arguments": {"value": "int"}, "returns": "int", "capabilities": (), "effect": "pure"})
    counted_registry = ToolRegistry(("counted",)).register(counted_tool)
    negative("SCHEMA_MISMATCH", "ToolCall.validate", lambda: ToolCall("counted", {"value": True}).validate(counted_registry))
    claim("failure_atomicity", calls["count"] == 0, "schema failure occurs before callback")
    claim("adversarial", reversible_state == [], "approval request does not execute a tool")
    negative("CALL_NOT_VALIDATED", "toolCall.requireApproval", lambda: ToolCall("add", {"left": 1, "right": 2}).requireApproval())
    negative("UNSAFE_CAPABILITY", "Tool.fromFunction", lambda: Tool.fromFunction(add, {**schema, "capabilities": ("shell",)}))
    negative("INVALID_BOOLEAN", "Tool.fromFunction", lambda: Tool.fromFunction(add, {**schema, "requiresApproval": 1}))
    negative("TOOL_DENIED", "ToolRegistry.register", lambda: ToolRegistry(()).register(tool))
    negative("UNKNOWN_TOOL", "ToolCall.validate", lambda: ToolCall("missing", {}).validate(registry))
    negative("CAPABILITY_DENIED", "toolCall.execute", lambda: ToolCall("add", {"left": 1, "right": 2}).validate(registry).execute(ToolExecutionContext((), (), 1)))
    negative("INVALID_BOOLEAN", "ToolExecutionContext", lambda: ToolExecutionContext(("network",), (), 1, network="false"))
    negative("APPROVAL_REQUIRED", "toolCall.execute", lambda: approval_call.execute(ToolExecutionContext(("compute",), (), 1)))
    negative("TOOL_BUDGET", "toolCall.execute", lambda: ToolCall("add", {"left": 1, "right": 2}).validate(registry).execute(ToolExecutionContext(("compute",), (), 0)))
    wrong_tool = Tool.fromFunction(wrong_return, {"arguments": {"value": "int"}, "returns": "int", "capabilities": (), "effect": "pure"})
    negative("RETURN_SCHEMA_MISMATCH", "toolCall.execute", lambda: ToolCall("wrong_return", {"value": 2}).validate(ToolRegistry(("wrong_return",)).register(wrong_tool)).execute(ToolExecutionContext((), (), 1)))


def subgroup_s06() -> None:
    state: list[int] = []
    def store(value: int) -> int:
        state.append(value)
        return value
    def compensate(arguments: dict[str, Any], value: Any) -> None:
        require(state[-1] == value == arguments["value"], "agent compensation identity")
        state.pop()
    tool = Tool.fromFunction(store, {"arguments": {"value": "int"}, "returns": "int", "capabilities": ("compute",), "effect": "reversible", "compensate": compensate, "requiresApproval": True})
    registry = ToolRegistry(("store",)).register(tool)
    policy = AiPolicy.maxTokens(2).maxToolCalls(1).allowedTools(("store",)).network(False)
    model = load_model()
    agent = Agent.new(model, registry, policy)
    surface("G023-S06-01", agent.model is model and agent.policy.maximum_tool_calls == 1, True)
    goal = {"prompt": "hello", "toolCalls": ({"name": "store", "arguments": {"value": 5}},)}
    plan = agent.plan(goal, {"maxSteps": 2})
    surface("G023-S06-02", len(plan.steps()) == 2 and len(plan.identity) == 64, plan.identity)
    steps = plan.steps()
    surface("G023-S06-03", steps[0].kind == "generate" and steps[1].payload["name"] == "store", steps)
    approval_id = ToolCall("store", {"value": 5}).validate(registry).requireApproval().callId
    execution = agent.execute(plan, ToolExecutionContext(("compute",), (approval_id,), 1))
    surface("G023-S06-04", len(execution.generation.tokens) == 2 and execution.toolResults[0].value == 5 and state == [5], execution)
    agent.pause()
    surface("G023-S06-05", agent._paused is True, agent.auditTrail()[-1])
    reverted = agent.rollback(0)
    surface("G023-S06-06", reverted == 1 and state == [], reverted)
    audit = agent.auditTrail()
    surface("G023-S06-07", tuple(event["event"] for event in audit) == ("plan-start", "generated", "tool", "plan-complete", "paused", "rollback"), audit)

    alternate = Agent.new(model, registry, policy).plan({"prompt": "hello", "toolCalls": ({"name": "store", "arguments": {"value": 6}},)}, {"maxSteps": 2})
    claim("metamorphic", alternate.identity != plan.identity, "goal arguments govern plan identity")
    claim("composition", execution.checkpoint == 1 and reverted == 1 and state == [], "execute checkpoint and compensation compose")
    claim("ownership", isinstance(steps, tuple) and steps == plan.steps(), "plan steps are immutable")
    empty_agent = Agent.new(model, ToolRegistry(()), AiPolicy.maxTokens(1).maxToolCalls(0).allowedTools(()))
    empty_plan = empty_agent.plan({"prompt": "h", "toolCalls": ()}, {"maxSteps": 1})
    claim("boundary", len(empty_plan.steps()) == 1, "generation-only one-step plan")
    claim("determinism", Agent.new(model, registry, policy).plan(goal, {"maxSteps": 2}).identity == plan.identity, "plan identity deterministic")
    audit_before = len(agent.auditTrail())
    negative("PLAN_BUDGET", "agent.plan", lambda: agent.plan(goal, {"maxSteps": 1}))
    claim("failure_atomicity", len(agent.auditTrail()) == audit_before, "rejected plan does not append audit events")
    claim("adversarial", all(event["event"] != "tool" or "identity" in event for event in audit), "tool audit entries carry result identity")
    negative("AGENT_PAUSED", "agent.execute", lambda: agent.execute(plan, ToolExecutionContext(("compute",), (approval_id,), 1)))
    negative("LIMIT_EXCEEDED", "agent.rollback", lambda: agent.rollback(2))
    negative("POLICY_CONFLICT", "Agent.new", lambda: Agent.new(model, registry, AiPolicy.maxTokens(1).maxToolCalls(1).allowedTools(())))
    negative("TOOL_DENIED", "agent.plan", lambda: empty_agent.plan(goal, {"maxSteps": 2}))
    negative("NETWORK_DENIED", "agent.execute", lambda: empty_agent.execute(empty_plan, ToolExecutionContext((), (), 0, network=True)))
    negative("PLAN_SCHEMA", "agent.plan", lambda: Agent.new(model, registry, policy).plan({"prompt": "h", "toolCalls": ({"name": "store", "arguments": {"value": True}},)}, {"maxSteps": 2}))
    negative("CONTEXT_LIMIT", "agent.plan", lambda: empty_agent.plan({"prompt": "h" * 64, "toolCalls": ()}, {"maxSteps": 1}))
    forged_agent = Agent.new(model, ToolRegistry(()), AiPolicy.maxTokens(1).maxToolCalls(0).allowedTools(()))
    forged_plan = forged_agent.plan({"prompt": "h", "toolCalls": ()}, {"maxSteps": 1})
    forged_plan.identity = "0" * 64
    negative("PLAN_IDENTITY_MISMATCH", "agent.execute", lambda: forged_agent.execute(forged_plan, ToolExecutionContext((), (), 0)))


def expected_top(model: CausalLanguageModel, tokens: tuple[int, ...]) -> int:
    logits = independent_logits(model, tokens)
    return max(range(len(logits)), key=lambda token: (logits[token], -token))


def subgroup_s07() -> None:
    policy = AiPolicy.maxTokens(3)
    surface("G023-S07-01", policy.maximum_tokens == 3 and policy.maximum_tool_calls == 0, policy.maximum_tokens)
    policy = policy.maxToolCalls(2)
    surface("G023-S07-02", policy.maximum_tool_calls == 2, policy.maximum_tool_calls)
    policy = policy.allowedTools(("add", "lookup"))
    surface("G023-S07-03", policy.allowed_tools == frozenset({"add", "lookup"}), policy.allowed_tools)
    policy = policy.network(False)
    surface("G023-S07-04", policy.network_enabled is False, policy.network_enabled)
    model = load_model()
    cases = (
        {"tokens": (4,), "expectedTopToken": expected_top(model, (4,)), "secretPresent": False, "policyBypass": False, "expectedSafetyDecision": "allow"},
        {"tokens": (5, 7), "expectedTopToken": expected_top(model, (5, 7)), "secretPresent": False, "policyBypass": False, "expectedSafetyDecision": "allow"},
    )
    prompt_digest = hashlib.sha256(b"[system] evaluate tiny local cases").hexdigest()
    suite = {"version": 1, "name": "tiny-local-evaluation", "promptDigest": prompt_digest, "toolchain": "neboc-1.0.0+g023-sdk-v1", "cases": cases}
    evaluation = Evaluation.run(suite, model)
    surface("G023-S07-05", evaluation.values["cases"] == 2 and evaluation.values["accuracy"] == 1.0, evaluation.values)
    metrics = evaluation.metrics()
    surface("G023-S07-06", metrics["safetyRate"] == 1.0 and metrics["performanceClaim"] == "logical-operations-only", metrics)
    provenance = evaluation.provenance()
    surface("G023-S07-07", provenance["model"] == model.checksum and len(provenance["data"]) == 64 and provenance["prompt"] == prompt_digest and provenance["toolchain"] == "neboc-1.0.0+g023-sdk-v1", provenance)

    wrong_suite = {**suite, "cases": ({**cases[0], "expectedTopToken": (cases[0]["expectedTopToken"] + 1) % 15}, cases[1])}
    claim("metamorphic", Evaluation.run(wrong_suite, model).metrics()["accuracy"] == 0.5, "expected corpus labels govern accuracy")
    claim("composition", evaluation.metrics()["cases"] == 2 and evaluation.provenance()["model"] == model.checksum, "evaluation metrics and provenance compose")
    metrics_snapshot = evaluation.metrics()
    claim("ownership", type(metrics_snapshot).__name__ == "mappingproxy", "evaluation metrics are immutable")
    one_case = Evaluation.run({**suite, "cases": (cases[0],)}, model)
    claim("boundary", one_case.metrics()["cases"] == 1, "single-case evaluation")
    claim("determinism", Evaluation.run(suite, model) == evaluation, "evaluation is deterministic")
    guarded = Evaluation.run({**suite, "cases": ({**cases[0], "secretPresent": True, "expectedSafetyDecision": "deny"},)}, model)
    bypassed_expectation = Evaluation.run({**suite, "cases": ({**cases[0], "secretPresent": True, "expectedSafetyDecision": "allow"},)}, model)
    claim("adversarial", guarded.metrics()["safetyRate"] == 1.0 and bypassed_expectation.metrics()["safetyRate"] == 0.0, "secret-bearing case is safe only when deny is expected")
    policy_before = policy
    negative("INVALID_BOOLEAN", "AiPolicy.network", lambda: policy.network(1))
    claim("failure_atomicity", policy == policy_before, "invalid network policy leaves prior value intact")
    negative("INVALID_INTEGER", "AiPolicy.maxTokens", lambda: AiPolicy.maxTokens(True))
    negative("INVALID_INTEGER", "AiPolicy.maxToolCalls", lambda: policy.maxToolCalls(True))
    negative("INVALID_ALLOWLIST", "AiPolicy.allowedTools", lambda: policy.allowedTools("add"))
    negative("INVALID_SUITE", "Evaluation.run", lambda: Evaluation.run({"version": 2, "cases": cases}, model))
    negative("INCOMPLETE_PROVENANCE", "Evaluation.run", lambda: Evaluation.run({"version": 1, "cases": cases}, model))
    negative("LIMIT_EXCEEDED", "Evaluation.run", lambda: Evaluation.run({**suite, "cases": ()}, model))
    negative("INVALID_INTEGER", "Evaluation.run", lambda: Evaluation.run({**suite, "cases": ({**cases[0], "expectedTopToken": True},)}, model))
    negative("INVALID_BOOLEAN", "Evaluation.run", lambda: Evaluation.run({**suite, "cases": ({**cases[0], "secretPresent": 1},)}, model))
    negative("INVALID_DECISION", "Evaluation.run", lambda: Evaluation.run({**suite, "cases": ({**cases[0], "expectedSafetyDecision": "maybe"},)}, model))


def static_checks() -> None:
    source = Path("compiler/sdk/ai.py").read_text(encoding="utf-8")
    require("socket" not in source and "subprocess" not in source and "urlopen" not in source and "requests" not in source, "no network/process dependency")
    require("downloads models" in source and "operating-system sandbox" in source, "honest local/sandbox limitations")
    claim("adversarial", "APPROVAL_REQUIRED" in source and "CAPABILITY_DENIED" in source and "NETWORK_DENIED" in source, "deny-default gates are implemented")


def main() -> None:
    subgroup_s01()
    subgroup_s02()
    subgroup_s03()
    subgroup_s04()
    subgroup_s05()
    subgroup_s06()
    subgroup_s07()
    static_checks()
    require(COUNTS["positive"] == 47 and COUNTS["sdk"] == 47, "all 47 public surfaces need observations")
    digest = hashlib.sha256(json.dumps(EVIDENCE, separators=(",", ":"), ensure_ascii=True).encode("ascii")).hexdigest()
    fields = " ".join(f"{name}={value}" for name, value in COUNTS.items())
    print(f"G023_SDK_ORACLE_GREEN {fields} digest={digest}")


if __name__ == "__main__":
    main()
