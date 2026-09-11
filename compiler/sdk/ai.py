"""Bounded local G023 tokenizer, causal generation, tools, and agents.

This dependency-free reference profile reads only authenticated local manifests.
It never downloads models, opens a network connection, launches a process, or
claims that Python callbacks provide an operating-system sandbox.
"""

from __future__ import annotations

import hashlib
import json
import math
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Any, Callable, Mapping, Sequence


MAX_MANIFEST_BYTES = 65536
MAX_TEXT_BYTES = 8192
MAX_VOCABULARY = 512
MAX_CONTEXT = 4096
MAX_GENERATED_TOKENS = 256
MAX_SCHEMA_FIELDS = 64
MAX_TOOLS = 32
MAX_TOOL_ARGUMENTS = 16
MAX_PLAN_STEPS = 32
MAX_EVALUATION_CASES = 256


class AiError(ValueError):
    """Stable failure with a code and public operation name."""

    def __init__(self, code: str, operation: str, message: str) -> None:
        super().__init__(f"{code}: {operation}: {message}")
        self.code = code
        self.operation = operation


def _fail(code: str, operation: str, message: str) -> None:
    raise AiError(code, operation, message)


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


def _boolean(value: Any, operation: str, name: str) -> bool:
    if not isinstance(value, bool):
        _fail("INVALID_BOOLEAN", operation, f"{name} must be Bool")
    return value


def _text(value: Any, operation: str, name: str, *, allow_empty: bool = False) -> str:
    if not isinstance(value, str) or (not allow_empty and not value):
        _fail("INVALID_TEXT", operation, f"{name} must be text")
    if len(value.encode("utf-8")) > MAX_TEXT_BYTES:
        _fail("LIMIT_EXCEEDED", operation, f"{name} exceeds {MAX_TEXT_BYTES} UTF-8 bytes")
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


def _canonical(value: Any) -> bytes:
    def thaw(item: Any) -> Any:
        if isinstance(item, Mapping):
            return {str(key): thaw(inner) for key, inner in item.items()}
        if isinstance(item, (list, tuple)):
            return [thaw(inner) for inner in item]
        if isinstance(item, (set, frozenset)):
            return sorted(thaw(inner) for inner in item)
        return item

    try:
        return json.dumps(thaw(value), sort_keys=True, separators=(",", ":"), ensure_ascii=True, allow_nan=False).encode("ascii")
    except (TypeError, ValueError):
        _fail("NON_CANONICAL_VALUE", "canonicalize", "value is not canonical JSON")


def _digest(value: Any) -> str:
    return hashlib.sha256(_canonical(value)).hexdigest()


def _read_manifest(path: Any, options: Any, expected_kind: str, operation: str) -> tuple[Mapping[str, Any], str]:
    config = _mapping(options, operation, "options")
    root_text = _text(config.get("allowedRoot"), operation, "options.allowedRoot")
    path_text = _text(path, operation, "path")
    root_lexical = Path(root_text).absolute()
    candidate_lexical = Path(path_text).absolute()
    try:
        relative = candidate_lexical.relative_to(root_lexical)
    except ValueError:
        _fail("PATH_OUTSIDE_ROOT", operation, "path must be inside allowedRoot")
    probe = root_lexical
    for part in relative.parts:
        probe = probe / part
        if probe.is_symlink():
            _fail("SYMLINK_FORBIDDEN", operation, "manifest path cannot traverse a symlink")
    try:
        root = root_lexical.resolve(strict=True)
        candidate = candidate_lexical.resolve(strict=True)
        candidate.relative_to(root)
    except (FileNotFoundError, OSError, ValueError):
        _fail("PATH_INVALID", operation, "manifest path or allowed root is invalid")
    if not candidate.is_file():
        _fail("PATH_INVALID", operation, "manifest must be a regular file")
    maximum_bytes = _integer(config.get("maximumBytes", MAX_MANIFEST_BYTES), operation, "options.maximumBytes", 1, MAX_MANIFEST_BYTES)
    data = candidate.read_bytes()
    if len(data) > maximum_bytes:
        _fail("LIMIT_EXCEEDED", operation, "manifest exceeds the declared byte budget")
    try:
        document = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        _fail("MALFORMED_MANIFEST", operation, "manifest must be valid UTF-8 JSON")
    if not isinstance(document, dict) or document.get("kind") != expected_kind or document.get("version") != 1:
        _fail("UNSUPPORTED_MANIFEST", operation, "manifest kind/version is unsupported")
    checksum = document.get("checksum")
    if not isinstance(checksum, str) or len(checksum) != 64:
        _fail("CHECKSUM_REQUIRED", operation, "manifest must contain a SHA-256 checksum")
    payload = dict(document)
    del payload["checksum"]
    actual = _digest(payload)
    if checksum != actual:
        _fail("CHECKSUM_MISMATCH", operation, "manifest checksum does not match its payload")
    expected_checksum = config.get("expectedChecksum")
    if expected_checksum is not None and expected_checksum != checksum:
        _fail("IDENTITY_MISMATCH", operation, "manifest identity differs from expectedChecksum")
    return document, checksum


class Tokenizer:
    def __init__(self, manifest: Mapping[str, Any], checksum: str) -> None:
        operation = "Tokenizer.load"
        tokens = _sequence(manifest.get("tokens"), operation, "tokens")
        if not tokens or len(tokens) > MAX_VOCABULARY:
            _fail("INVALID_VOCABULARY", operation, "vocabulary size is outside the bounded profile")
        self.tokens = tuple(_text(token, operation, f"tokens[{index}]") for index, token in enumerate(tokens))
        if len(set(self.tokens)) != len(self.tokens):
            _fail("INVALID_VOCABULARY", operation, "tokens must be unique")
        special = _mapping(manifest.get("specialTokens"), operation, "specialTokens")
        required = {"PAD", "BOS", "EOS", "UNK"}
        if set(special) != required:
            _fail("INVALID_SPECIAL_TOKENS", operation, "PAD, BOS, EOS, and UNK are required")
        self.special_tokens = MappingProxyType(
            {name: _integer(special[name], operation, f"specialTokens.{name}", 0, len(self.tokens) - 1) for name in sorted(required)}
        )
        if len(set(self.special_tokens.values())) != len(required):
            _fail("INVALID_SPECIAL_TOKENS", operation, "special token IDs must be distinct")
        merges = _sequence(manifest.get("merges", ()), operation, "merges")
        if len(merges) > MAX_VOCABULARY:
            _fail("LIMIT_EXCEEDED", operation, "merge table exceeds vocabulary budget")
        if merges:
            _fail("UNSUPPORTED_MERGES", operation, "version-1 reference accepts only an explicit empty merge table")
        self.merges = tuple(merges)
        self.checksum = checksum
        special_ids = set(self.special_tokens.values())
        self._lexical = tuple(sorted(((token, index) for index, token in enumerate(self.tokens) if index not in special_ids), key=lambda pair: (-len(pair[0]), pair[1])))

    @classmethod
    def load(cls, path: str, options: Mapping[str, Any] | None = None) -> "Tokenizer":
        manifest, checksum = _read_manifest(path, options or {}, "nebo-tokenizer", "Tokenizer.load")
        return cls(manifest, checksum)

    def _scan(self, text: str, options: Mapping[str, Any], collect: bool) -> tuple[tuple[int, ...], int]:
        operation = "tokenizer.encode" if collect else "tokenizer.count"
        source = _text(text, operation, "text", allow_empty=True)
        policy = str(options.get("errorPolicy", "reject")).lower()
        if policy not in {"reject", "replace"}:
            _fail("UNSUPPORTED_POLICY", operation, "errorPolicy must be reject or replace")
        maximum = _integer(options.get("maximumTokens", MAX_GENERATED_TOKENS), operation, "options.maximumTokens", 1, MAX_CONTEXT)
        output: list[int] = []
        count = 0
        if _boolean(options.get("addBos", False), operation, "options.addBos"):
            output.append(self.special_tokens["BOS"])
            count += 1
        offset = 0
        while offset < len(source):
            match: tuple[str, int] | None = None
            for token, token_id in self._lexical:
                if source.startswith(token, offset):
                    match = (token, token_id)
                    break
            if match is None:
                if policy == "reject":
                    _fail("UNKNOWN_TEXT", operation, f"no token begins at character {offset}")
                token_text, token_id = source[offset], self.special_tokens["UNK"]
            else:
                token_text, token_id = match
            if collect:
                output.append(token_id)
            count += 1
            if count > maximum:
                _fail("TOKEN_BUDGET", operation, "encoded token count exceeds maximumTokens")
            offset += len(token_text)
        if _boolean(options.get("addEos", False), operation, "options.addEos"):
            if collect:
                output.append(self.special_tokens["EOS"])
            count += 1
            if count > maximum:
                _fail("TOKEN_BUDGET", operation, "encoded token count exceeds maximumTokens")
        return tuple(output), count

    def encode(self, text: str, options: Mapping[str, Any] | None = None) -> tuple[int, ...]:
        return self._scan(text, _mapping(options or {}, "tokenizer.encode", "options"), True)[0]

    def decode(self, tokens: Sequence[int], options: Mapping[str, Any] | None = None) -> str:
        operation = "tokenizer.decode"
        config = _mapping(options or {}, operation, "options")
        values = _sequence(tokens, operation, "tokens")
        if len(values) > MAX_CONTEXT:
            _fail("TOKEN_BUDGET", operation, "token sequence exceeds the context budget")
        special_policy = str(config.get("specialPolicy", "skip")).lower()
        error_policy = str(config.get("errorPolicy", "reject")).lower()
        if special_policy not in {"skip", "keep", "error"} or error_policy not in {"reject", "replace"}:
            _fail("UNSUPPORTED_POLICY", operation, "decode policies are unsupported")
        reverse_special = {value: name for name, value in self.special_tokens.items()}
        pieces: list[str] = []
        for index, token in enumerate(values):
            token_id = _integer(token, operation, f"tokens[{index}]", 0, len(self.tokens) - 1)
            if token_id == self.special_tokens["UNK"]:
                if error_policy == "reject":
                    _fail("UNKNOWN_TOKEN", operation, "UNK cannot be decoded under reject policy")
                pieces.append("\ufffd")
            elif token_id in reverse_special:
                if special_policy == "error":
                    _fail("SPECIAL_TOKEN", operation, "special token is forbidden by policy")
                if special_policy == "keep":
                    pieces.append(self.tokens[token_id])
            else:
                pieces.append(self.tokens[token_id])
        return "".join(pieces)

    def vocabularySize(self) -> int:
        return len(self.tokens)

    def specialToken(self, name: str) -> int:
        key = _text(name, "tokenizer.specialToken", "name").upper()
        if key not in self.special_tokens:
            _fail("UNKNOWN_SPECIAL_TOKEN", "tokenizer.specialToken", f"unknown special token {key}")
        return self.special_tokens[key]

    def count(self, text: str) -> int:
        return self._scan(text, {"maximumTokens": MAX_CONTEXT, "errorPolicy": "reject"}, False)[1]

    def provenance(self) -> Mapping[str, Any]:
        return _freeze({"kind": "tokenizer", "version": 1, "checksum": self.checksum, "vocabularySize": len(self.tokens)})


class KvCache:
    def __init__(self, config: Mapping[str, Any]) -> None:
        operation = "KvCache.new"
        self.maximum_length = _integer(config.get("maximumLength"), operation, "config.maximumLength", 1, MAX_CONTEXT)
        model_checksum = config.get("modelChecksum")
        if model_checksum is not None and (not isinstance(model_checksum, str) or len(model_checksum) != 64):
            _fail("INVALID_IDENTITY", operation, "modelChecksum must be SHA-256 text")
        self.model_checksum = model_checksum
        self._tokens: list[int] = []
        self.generation = 1

    @classmethod
    def new(cls, config: Mapping[str, Any]) -> "KvCache":
        return cls(_mapping(config, "KvCache.new", "config"))

    def length(self) -> int:
        return len(self._tokens)

    def truncate(self, length: int) -> "KvCache":
        target = _integer(length, "cache.truncate", "length", 0, len(self._tokens))
        del self._tokens[target:]
        self.generation += 1
        return self

    @property
    def tokens(self) -> tuple[int, ...]:
        return tuple(self._tokens)


@dataclass(frozen=True)
class ForwardResult:
    logits: tuple[float, ...]
    cache: KvCache
    operations: int


class CausalLanguageModel:
    def __init__(self, manifest: Mapping[str, Any], checksum: str) -> None:
        operation = "CausalLanguageModel.load"
        self.vocabulary_size = _integer(manifest.get("vocabSize"), operation, "vocabSize", 2, MAX_VOCABULARY)
        self.context_length = _integer(manifest.get("contextLength"), operation, "contextLength", 1, MAX_CONTEXT)
        bias = _sequence(manifest.get("bias"), operation, "bias")
        if len(bias) != self.vocabulary_size:
            _fail("MODEL_SHAPE", operation, "bias length must equal vocabSize")
        self.bias = tuple(_number(value, operation, f"bias[{index}]") for index, value in enumerate(bias))
        self.token_scale = _number(manifest.get("tokenScale"), operation, "tokenScale")
        self.position_scale = _number(manifest.get("positionScale"), operation, "positionScale")
        self.quantization = manifest.get("quantization")
        if self.quantization != "none-f64-reference":
            _fail("UNSUPPORTED_QUANTIZATION", operation, "tiny model must declare none-f64-reference quantization")
        self.checksum = checksum

    @classmethod
    def load(cls, path: str, options: Mapping[str, Any]) -> "CausalLanguageModel":
        manifest, checksum = _read_manifest(path, options, "nebo-tiny-causal", "CausalLanguageModel.load")
        return cls(manifest, checksum)

    def forward(self, tokens: Sequence[int], cache: KvCache) -> ForwardResult:
        operation = "model.forward"
        if not isinstance(cache, KvCache):
            _fail("INVALID_CACHE", operation, "cache must be KvCache")
        if cache.model_checksum not in {None, self.checksum}:
            _fail("IDENTITY_MISMATCH", operation, "cache belongs to another model")
        values = _sequence(tokens, operation, "tokens")
        if not values:
            _fail("EMPTY_TOKENS", operation, "at least one token is required")
        validated = tuple(_integer(token, operation, f"tokens[{index}]", 0, self.vocabulary_size - 1) for index, token in enumerate(values))
        if cache.length() + len(validated) > min(cache.maximum_length, self.context_length):
            _fail("CONTEXT_LIMIT", operation, "forward pass exceeds cache/model context")
        combined = cache.tokens + validated
        accumulator = sum((index + 1) * (token + 1) for index, token in enumerate(combined))
        logits = tuple(
            bias + ((accumulator * (candidate + self.token_scale) + len(combined) * self.position_scale) % 97.0) - 48.0
            for candidate, bias in enumerate(self.bias)
        )
        cache._tokens.extend(validated)
        return ForwardResult(logits, cache, len(combined) * self.vocabulary_size)

    def contextLength(self) -> int:
        return self.context_length

    def provenance(self) -> Mapping[str, Any]:
        return _freeze(
            {
                "kind": "tiny-causal-model",
                "version": 1,
                "checksum": self.checksum,
                "vocabSize": self.vocabulary_size,
                "quantization": self.quantization,
            }
        )


class Sampler:
    def __init__(self, mode: str, parameter: float | int | None = None, penalty: float = 1.0) -> None:
        self.mode = mode
        self.parameter = parameter
        self.penalty = penalty

    @classmethod
    def greedy(cls) -> "Sampler":
        return cls("greedy")

    @classmethod
    def temperature(cls, value: float) -> "Sampler":
        temperature = _number(value, "Sampler.temperature", "value")
        if temperature <= 0.0 or temperature > 10.0:
            _fail("INVALID_TEMPERATURE", "Sampler.temperature", "temperature must be in (0, 10]")
        return cls("temperature", temperature)

    @classmethod
    def topK(cls, k: int) -> "Sampler":
        return cls("top-k", _integer(k, "Sampler.topK", "k", 1, MAX_VOCABULARY))

    @classmethod
    def topP(cls, probability: float) -> "Sampler":
        value = _number(probability, "Sampler.topP", "probability")
        if value <= 0.0 or value > 1.0:
            _fail("INVALID_PROBABILITY", "Sampler.topP", "probability must be in (0, 1]")
        return cls("top-p", value)

    def repetitionPenalty(self, value: float) -> "Sampler":
        penalty = _number(value, "sampler.repetitionPenalty", "value")
        if penalty < 1.0 or penalty > 4.0:
            _fail("INVALID_PENALTY", "sampler.repetitionPenalty", "penalty must be in [1, 4]")
        return Sampler(self.mode, self.parameter, penalty)

    def _select(self, logits: Sequence[float], recent: Sequence[int], seed: int, step: int) -> int:
        adjusted = list(logits)
        for token in set(recent):
            adjusted[token] = adjusted[token] / self.penalty if adjusted[token] >= 0.0 else adjusted[token] * self.penalty
        ranked = sorted(range(len(adjusted)), key=lambda index: (-adjusted[index], index))
        if self.mode == "greedy":
            return ranked[0]
        temperature = float(self.parameter) if self.mode == "temperature" else 1.0
        maximum = max(adjusted)
        weighted = [(index, math.exp((adjusted[index] - maximum) / temperature)) for index in ranked]
        if self.mode == "top-k":
            weighted = weighted[: min(int(self.parameter), len(weighted))]
        elif self.mode == "top-p":
            total = sum(weight for _, weight in weighted)
            cumulative = 0.0
            candidates_with_weight: list[tuple[int, float]] = []
            for index, weight in weighted:
                candidates_with_weight.append((index, weight))
                cumulative += weight / total
                if cumulative >= float(self.parameter):
                    break
            weighted = candidates_with_weight
        entropy = hashlib.sha256(f"{seed}:{step}:{','.join(map(str, recent[-16:]))}".encode("ascii")).digest()
        threshold = ((int.from_bytes(entropy[:8], "little") + 0.5) / (1 << 64)) * sum(weight for _, weight in weighted)
        cumulative_weight = 0.0
        for index, weight in weighted:
            cumulative_weight += weight
            if threshold <= cumulative_weight:
                return index
        return weighted[-1][0]


@dataclass(frozen=True)
class GenerationResult:
    text: str
    tokens: tuple[int, ...]
    finishReason: str
    modelChecksum: str
    tokenizerChecksum: str
    operations: int

    def provenance(self) -> Mapping[str, Any]:
        return _freeze(
            {
                "kind": "generation",
                "model": self.modelChecksum,
                "tokenizer": self.tokenizerChecksum,
                "tokenDigest": _digest(self.tokens),
            }
        )


class Prompt:
    def __init__(self, parts: Sequence[Mapping[str, Any]]) -> None:
        operation = "Prompt.new"
        if len(parts) > 32:
            _fail("LIMIT_EXCEEDED", operation, "prompt exceeds 32 parts")
        normalized: list[Mapping[str, Any]] = []
        for index, part in enumerate(parts):
            item = _mapping(part, operation, f"parts[{index}]")
            role = item.get("role")
            if role not in {"system", "user", "assistant", "context"}:
                _fail("INVALID_ROLE", operation, f"unsupported role at part {index}")
            text = _text(item.get("text"), operation, f"parts[{index}].text", allow_empty=True)
            provenance = item.get("provenance")
            if role == "context":
                context_provenance = _mapping(provenance, operation, f"parts[{index}].provenance")
                source = context_provenance.get("source")
                digest = context_provenance.get("digest")
                if not isinstance(source, str) or not source or len(source.encode("utf-8")) > MAX_TEXT_BYTES or digest != hashlib.sha256(text.encode("utf-8")).hexdigest():
                    _fail("PROVENANCE_MISMATCH", operation, "context role requires matching source and text digest")
            normalized.append(_freeze({"role": role, "text": text, "provenance": provenance}))
        self._parts = tuple(normalized)
        if len(self.render().encode("utf-8")) > MAX_TEXT_BYTES:
            _fail("LIMIT_EXCEEDED", operation, "rendered prompt exceeds the byte budget")

    @classmethod
    def new(cls, parts: Sequence[Mapping[str, Any]]) -> "Prompt":
        return cls(_sequence(parts, "Prompt.new", "parts"))

    def withSystem(self, text: str) -> "Prompt":
        value = _text(text, "prompt.withSystem", "text")
        return Prompt(({"role": "system", "text": value},) + tuple(self._parts))

    def withContext(self, document: Mapping[str, Any]) -> "Prompt":
        operation = "prompt.withContext"
        item = _mapping(document, operation, "document")
        text = _text(item.get("text"), operation, "document.text")
        provenance = _mapping(item.get("provenance"), operation, "document.provenance")
        if provenance.get("digest") != hashlib.sha256(text.encode("utf-8")).hexdigest() or not provenance.get("source"):
            _fail("PROVENANCE_MISMATCH", operation, "context digest/source must authenticate document text")
        return Prompt(self._parts + (_freeze({"role": "context", "text": text, "provenance": dict(provenance)}),))

    def render(self) -> str:
        return "\n".join(f"[{part['role']}] {part['text']}" for part in self._parts)

    @property
    def parts(self) -> tuple[Mapping[str, Any], ...]:
        return self._parts


class OutputSchema:
    def __init__(self, fields: Mapping[str, str]) -> None:
        operation = "OutputSchema.fromType"
        if not fields or len(fields) > MAX_SCHEMA_FIELDS:
            _fail("INVALID_SCHEMA", operation, "schema needs 1..64 fields")
        allowed = {"int", "float", "bool", "text"}
        normalized: dict[str, str] = {}
        for name in sorted(fields):
            type_name = fields[name]
            key = _text(name, operation, "field name")
            if type_name not in allowed:
                _fail("INELIGIBLE_TYPE", operation, f"field {key} has unsupported type")
            normalized[key] = type_name
        self.fields = MappingProxyType(normalized)
        self.digest = _digest(normalized)

    @classmethod
    def fromType(cls, type_spec: Mapping[str, str]) -> "OutputSchema":
        return cls(_mapping(type_spec, "OutputSchema.fromType", "type"))


@dataclass(frozen=True)
class StructuredOutput:
    value: Mapping[str, Any]
    errors: tuple[str, ...]
    generation: GenerationResult

    def validationErrors(self) -> tuple[str, ...]:
        return self.errors

    def provenance(self) -> Mapping[str, Any]:
        return _freeze({"kind": "structured-output", "schemaFields": tuple(self.value), "generation": dict(self.generation.provenance())})


class Generator:
    def __init__(self, model: CausalLanguageModel, tokenizer: Tokenizer, sampler: Sampler) -> None:
        operation = "Generator.new"
        if not isinstance(model, CausalLanguageModel) or not isinstance(tokenizer, Tokenizer) or not isinstance(sampler, Sampler):
            _fail("INVALID_COMPONENT", operation, "model, tokenizer, and sampler are required")
        if model.vocabulary_size != tokenizer.vocabularySize():
            _fail("MODEL_TOKENIZER_MISMATCH", operation, "model and tokenizer vocabulary sizes differ")
        self.model = model
        self.tokenizer = tokenizer
        self.sampler = sampler
        self._cancelled = False
        self._cache: KvCache | None = None

    @classmethod
    def new(cls, model: CausalLanguageModel, tokenizer: Tokenizer, sampler: Sampler) -> "Generator":
        return cls(model, tokenizer, sampler)

    def generate(self, prompt: str | Prompt, limits: Mapping[str, Any]) -> GenerationResult:
        operation = "generator.generate"
        if self._cancelled:
            _fail("CANCELLED", operation, "generation session was cancelled")
        config = _mapping(limits, operation, "limits")
        source = prompt.render() if isinstance(prompt, Prompt) else _text(prompt, operation, "prompt")
        maximum = _integer(config.get("maxTokens"), operation, "limits.maxTokens", 1, MAX_GENERATED_TOKENS)
        seed = _integer(config.get("seed", 0), operation, "limits.seed", 0, (1 << 31) - 1)
        stop_values = _sequence(config.get("stopTokens", ()), operation, "limits.stopTokens")
        stop_tokens = frozenset(_integer(value, operation, "stop token", 0, self.model.vocabulary_size - 1) for value in stop_values)
        prompt_tokens = self.tokenizer.encode(source, {"addBos": True, "errorPolicy": "replace", "maximumTokens": self.model.contextLength()})
        if len(prompt_tokens) + maximum > self.model.contextLength():
            _fail("CONTEXT_LIMIT", operation, "prompt plus generation exceeds model context")
        self._cache = KvCache.new({"maximumLength": self.model.contextLength(), "modelChecksum": self.model.checksum})
        generated: list[int] = []
        operations = 0
        forward_tokens: Sequence[int] = prompt_tokens
        finish = "length"
        for step in range(maximum):
            result = self.model.forward(forward_tokens, self._cache)
            operations += result.operations
            token = self.sampler._select(result.logits, self._cache.tokens, seed, step)
            if token in stop_tokens or token == self.tokenizer.specialToken("EOS"):
                finish = "stop"
                break
            generated.append(token)
            forward_tokens = (token,)
        text = self.tokenizer.decode(generated, {"specialPolicy": "skip", "errorPolicy": "replace"})
        return GenerationResult(text, tuple(generated), finish, self.model.checksum, self.tokenizer.checksum, operations)

    def cancel(self) -> None:
        self._cancelled = True
        if self._cache is not None:
            self._cache.truncate(0)

    def generateStructured(self, prompt: Prompt, schema: OutputSchema) -> StructuredOutput:
        operation = "generator.generateStructured"
        if not isinstance(prompt, Prompt) or not isinstance(schema, OutputSchema):
            _fail("INVALID_COMPONENT", operation, "prompt and schema are required")
        result = self.generate(prompt, {"maxTokens": len(schema.fields), "seed": int(schema.digest[:8], 16) & 0x7FFFFFFF, "stopTokens": ()})
        if len(result.tokens) != len(schema.fields):
            return StructuredOutput(MappingProxyType({}), ("generation stopped before all fields",), result)
        value: dict[str, Any] = {}
        for (name, type_name), token in zip(schema.fields.items(), result.tokens):
            if type_name == "int":
                value[name] = token
            elif type_name == "float":
                value[name] = token / 10.0
            elif type_name == "bool":
                value[name] = token % 2 == 0
            else:
                decoded = self.tokenizer.decode((token,), {"specialPolicy": "keep", "errorPolicy": "replace"})
                value[name] = decoded
        return StructuredOutput(_freeze(value), (), result)


def _type_matches(value: Any, type_name: str) -> bool:
    if type_name == "int":
        return isinstance(value, int) and not isinstance(value, bool)
    if type_name == "float":
        return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(float(value))
    if type_name == "bool":
        return isinstance(value, bool)
    if type_name == "text":
        return isinstance(value, str)
    return False


class Tool:
    def __init__(self, function: Callable[..., Any], schema: Mapping[str, Any]) -> None:
        operation = "Tool.fromFunction"
        if not callable(function) or not getattr(function, "__name__", "") or function.__name__.startswith("_"):
            _fail("INVALID_FUNCTION", operation, "function needs a public stable name")
        arguments = _mapping(schema.get("arguments"), operation, "schema.arguments")
        if len(arguments) > MAX_TOOL_ARGUMENTS:
            _fail("LIMIT_EXCEEDED", operation, "tool argument schema exceeds the budget")
        allowed_types = {"int", "float", "bool", "text"}
        if any(type_name not in allowed_types for type_name in arguments.values()) or schema.get("returns") not in allowed_types:
            _fail("INVALID_SCHEMA", operation, "tool types must be int, float, bool, or text")
        capabilities = schema.get("capabilities", ())
        if isinstance(capabilities, (str, bytes)) or not isinstance(capabilities, (set, frozenset, list, tuple)):
            _fail("INVALID_CAPABILITIES", operation, "capabilities must be a literal collection")
        effect = schema.get("effect", "pure")
        if effect not in {"pure", "reversible"}:
            _fail("UNSAFE_EFFECT", operation, "only pure or reversible tools are supported")
        compensation = schema.get("compensate")
        if effect == "reversible" and not callable(compensation):
            _fail("COMPENSATION_REQUIRED", operation, "reversible tool requires compensation")
        self.function = function
        self.name = function.__name__
        self.arguments = MappingProxyType(dict(arguments))
        self.return_type = str(schema["returns"])
        self.capabilities = frozenset(_text(value, operation, "capability") for value in capabilities)
        if not self.capabilities.issubset({"compute", "local-read", "network"}):
            _fail("UNSAFE_CAPABILITY", operation, "capability is outside the bounded tool profile")
        self.effect = effect
        self.compensation = compensation
        self.requires_approval = _boolean(schema.get("requiresApproval", effect == "reversible"), operation, "schema.requiresApproval")
        self.version = _integer(schema.get("version", 1), operation, "schema.version", 1, 1)

    @classmethod
    def fromFunction(cls, function: Callable[..., Any], schema: Mapping[str, Any]) -> "Tool":
        return cls(function, _mapping(schema, "Tool.fromFunction", "schema"))

    def requiredCapabilities(self) -> frozenset[str]:
        return self.capabilities


class ToolRegistry:
    def __init__(self, allowed_tools: Sequence[str]) -> None:
        if isinstance(allowed_tools, (str, bytes)):
            _fail("INVALID_ALLOWLIST", "ToolRegistry", "allowed tools must be a literal collection")
        self.allowed_tools = frozenset(_text(name, "ToolRegistry", "allowed tool") for name in allowed_tools)
        self._tools: dict[str, Tool] = {}

    def register(self, tool: Tool) -> "ToolRegistry":
        operation = "ToolRegistry.register"
        if not isinstance(tool, Tool):
            _fail("INVALID_TOOL", operation, "tool must be a Tool")
        if tool.name not in self.allowed_tools:
            _fail("TOOL_DENIED", operation, "tool is not in the registry allowlist")
        if tool.name in self._tools:
            _fail("DUPLICATE_TOOL", operation, "tool name is already registered")
        if len(self._tools) >= MAX_TOOLS:
            _fail("LIMIT_EXCEEDED", operation, "tool registry is full")
        self._tools[tool.name] = tool
        return self


@dataclass(frozen=True)
class ApprovalRequest:
    callId: str
    tool: str
    required: bool


class ToolExecutionContext:
    def __init__(self, capabilities: Sequence[str], approvals: Sequence[str], maximum_calls: int, network: bool = False) -> None:
        operation = "ToolExecutionContext"
        if isinstance(capabilities, (str, bytes)) or not isinstance(capabilities, (set, frozenset, list, tuple)):
            _fail("INVALID_CAPABILITIES", operation, "capabilities must be a literal collection")
        self.capabilities = frozenset(_text(value, operation, "capability") for value in capabilities)
        if not self.capabilities.issubset({"compute", "local-read", "network"}):
            _fail("INVALID_CAPABILITIES", operation, "context capability is outside the bounded profile")
        if isinstance(approvals, (str, bytes)) or not isinstance(approvals, (set, frozenset, list, tuple)):
            _fail("INVALID_APPROVALS", operation, "approvals must be a literal collection")
        self.approvals = frozenset(_text(value, operation, "approval") for value in approvals)
        self.remaining_calls = _integer(maximum_calls, "ToolExecutionContext", "maximum_calls", 0, 256)
        self.network = _boolean(network, operation, "network")


@dataclass(frozen=True)
class ToolResult:
    value: Any
    tool: str
    callId: str
    effect: str
    identity: str

    def provenance(self) -> Mapping[str, Any]:
        return _freeze({"kind": "tool-result", "tool": self.tool, "callId": self.callId, "effect": self.effect, "identity": self.identity})


class ToolCall:
    def __init__(self, name: str, arguments: Mapping[str, Any]) -> None:
        self.name = _text(name, "ToolCall", "name")
        self.arguments = MappingProxyType(dict(_mapping(arguments, "ToolCall", "arguments")))
        self.call_id = _digest({"name": self.name, "arguments": self.arguments})
        self._tool: Tool | None = None
        self._approval_requested = False

    def validate(self, registry: ToolRegistry) -> "ToolCall":
        operation = "ToolCall.validate"
        if not isinstance(registry, ToolRegistry) or self.name not in registry._tools:
            _fail("UNKNOWN_TOOL", operation, "tool is not registered")
        tool = registry._tools[self.name]
        if set(self.arguments) != set(tool.arguments):
            _fail("SCHEMA_MISMATCH", operation, "argument names differ from tool schema")
        for name, type_name in tool.arguments.items():
            if not _type_matches(self.arguments[name], type_name):
                _fail("SCHEMA_MISMATCH", operation, f"argument {name} has the wrong type")
        self._tool = tool
        return self

    def requireApproval(self) -> ApprovalRequest:
        if self._tool is None:
            _fail("CALL_NOT_VALIDATED", "toolCall.requireApproval", "validate the call before requesting approval")
        self._approval_requested = True
        return ApprovalRequest(self.call_id, self.name, self._tool.requires_approval)

    def execute(self, context: ToolExecutionContext) -> ToolResult:
        operation = "toolCall.execute"
        if self._tool is None:
            _fail("CALL_NOT_VALIDATED", operation, "validate the call before execution")
        if not isinstance(context, ToolExecutionContext):
            _fail("INVALID_CONTEXT", operation, "context must be ToolExecutionContext")
        if not self._tool.capabilities.issubset(context.capabilities):
            _fail("CAPABILITY_DENIED", operation, "required capabilities are absent")
        if "network" in self._tool.capabilities and not context.network:
            _fail("NETWORK_DENIED", operation, "network is disabled by policy")
        if self._tool.requires_approval and self.call_id not in context.approvals:
            _fail("APPROVAL_REQUIRED", operation, "matching human approval is required")
        if context.remaining_calls <= 0:
            _fail("TOOL_BUDGET", operation, "tool call budget is exhausted")
        context.remaining_calls -= 1
        try:
            value = self._tool.function(**self.arguments)
        except Exception:
            if self._tool.effect == "reversible":
                try:
                    assert self._tool.compensation is not None
                    self._tool.compensation(dict(self.arguments), None)
                except Exception:
                    _fail("COMPENSATION_FAILED", operation, "failed tool could not be compensated")
            _fail("TOOL_EXECUTION_FAILED", operation, "tool callback failed")
        if not _type_matches(value, self._tool.return_type):
            if self._tool.effect == "reversible":
                try:
                    assert self._tool.compensation is not None
                    self._tool.compensation(dict(self.arguments), value)
                except Exception:
                    _fail("COMPENSATION_FAILED", operation, "invalid tool result could not be compensated")
            _fail("RETURN_SCHEMA_MISMATCH", operation, "tool result violates return schema")
        identity = _digest({"tool": self.name, "version": self._tool.version, "arguments": self.arguments, "value": value})
        return ToolResult(value, self.name, self.call_id, self._tool.effect, identity)


@dataclass(frozen=True)
class AiPolicy:
    maximum_tokens: int
    maximum_tool_calls: int = 0
    allowed_tools: frozenset[str] = frozenset()
    network_enabled: bool = False

    @classmethod
    def maxTokens(cls, value: int) -> "AiPolicy":
        return cls(_integer(value, "AiPolicy.maxTokens", "value", 1, MAX_GENERATED_TOKENS))

    def maxToolCalls(self, value: int) -> "AiPolicy":
        return AiPolicy(self.maximum_tokens, _integer(value, "AiPolicy.maxToolCalls", "value", 0, 256), self.allowed_tools, self.network_enabled)

    def allowedTools(self, set: Sequence[str]) -> "AiPolicy":
        if isinstance(set, (str, bytes)) or not isinstance(set, (list, tuple, frozenset, builtins_set)):
            _fail("INVALID_ALLOWLIST", "AiPolicy.allowedTools", "set must be a literal collection")
        allowed = frozenset(_text(name, "AiPolicy.allowedTools", "tool") for name in set)
        if len(allowed) > MAX_TOOLS:
            _fail("LIMIT_EXCEEDED", "AiPolicy.allowedTools", "allowlist exceeds tool budget")
        return AiPolicy(self.maximum_tokens, self.maximum_tool_calls, allowed, self.network_enabled)

    def network(self, enabled: bool) -> "AiPolicy":
        if not isinstance(enabled, bool):
            _fail("INVALID_BOOLEAN", "AiPolicy.network", "enabled must be Bool")
        return AiPolicy(self.maximum_tokens, self.maximum_tool_calls, self.allowed_tools, enabled)


builtins_set = set


@dataclass(frozen=True)
class PlanStep:
    kind: str
    payload: Mapping[str, Any]


class Plan:
    def __init__(self, steps: Sequence[PlanStep], identity: str) -> None:
        self._steps = tuple(steps)
        self.identity = identity

    def steps(self) -> tuple[PlanStep, ...]:
        return self._steps


@dataclass(frozen=True)
class AgentExecution:
    generation: GenerationResult
    toolResults: tuple[ToolResult, ...]
    checkpoint: int


class Agent:
    def __init__(self, model: CausalLanguageModel, tools: ToolRegistry, policy: AiPolicy) -> None:
        operation = "Agent.new"
        if not isinstance(model, CausalLanguageModel) or not isinstance(tools, ToolRegistry) or not isinstance(policy, AiPolicy):
            _fail("INVALID_COMPONENT", operation, "model, registry, and policy are required")
        if not set(tools._tools).issubset(policy.allowed_tools):
            _fail("POLICY_CONFLICT", operation, "registered tools exceed policy allowlist")
        self.model = model
        self.tools = tools
        self.policy = policy
        self._paused = False
        self._audit: list[Mapping[str, Any]] = []
        self._effects: list[tuple[Tool, Mapping[str, Any], Any]] = []

    @classmethod
    def new(cls, model: CausalLanguageModel, tools: ToolRegistry, policy: AiPolicy) -> "Agent":
        return cls(model, tools, policy)

    def _generate_plan_text(self, prompt: str) -> GenerationResult:
        operation = "agent.execute"
        prompt_tokens = tuple(byte % self.model.vocabulary_size for byte in prompt.encode("utf-8"))
        if not prompt_tokens or len(prompt_tokens) + self.policy.maximum_tokens > self.model.contextLength():
            _fail("CONTEXT_LIMIT", operation, "agent prompt plus generation exceeds model context")
        cache = KvCache.new({"maximumLength": self.model.contextLength(), "modelChecksum": self.model.checksum})
        generated: list[int] = []
        operations = 0
        forward_tokens: Sequence[int] = prompt_tokens
        for _ in range(self.policy.maximum_tokens):
            result = self.model.forward(forward_tokens, cache)
            operations += result.operations
            token = max(range(len(result.logits)), key=lambda index: (result.logits[index], -index))
            generated.append(token)
            forward_tokens = (token,)
        profile = hashlib.sha256(b"agent-internal-byte-token-profile-v1").hexdigest()
        return GenerationResult(" ".join(map(str, generated)), tuple(generated), "length", self.model.checksum, profile, operations)

    def plan(self, goal: Mapping[str, Any], limits: Mapping[str, Any]) -> Plan:
        operation = "agent.plan"
        request = _mapping(goal, operation, "goal")
        config = _mapping(limits, operation, "limits")
        maximum_steps = _integer(config.get("maxSteps"), operation, "limits.maxSteps", 1, MAX_PLAN_STEPS)
        prompt = _text(request.get("prompt"), operation, "goal.prompt")
        if len(prompt.encode("utf-8")) + self.policy.maximum_tokens > self.model.contextLength():
            _fail("CONTEXT_LIMIT", operation, "goal prompt plus policy tokens exceeds model context")
        calls = _sequence(request.get("toolCalls", ()), operation, "goal.toolCalls")
        steps = [PlanStep("generate", _freeze({"prompt": prompt}))]
        for index, call in enumerate(calls):
            value = _mapping(call, operation, f"goal.toolCalls[{index}]")
            name = _text(value.get("name"), operation, "tool name")
            if name not in self.policy.allowed_tools:
                _fail("TOOL_DENIED", operation, f"tool {name} is outside policy")
            arguments = dict(_mapping(value.get("arguments"), operation, "arguments"))
            try:
                ToolCall(name, arguments).validate(self.tools)
            except AiError:
                _fail("PLAN_SCHEMA", operation, f"tool call {index} fails registry/schema validation")
            steps.append(PlanStep("tool", _freeze({"name": name, "arguments": arguments})))
        if len(steps) > maximum_steps or len(calls) > self.policy.maximum_tool_calls:
            _fail("PLAN_BUDGET", operation, "plan exceeds step or tool budget")
        identity = _digest([{"kind": step.kind, "payload": dict(step.payload)} for step in steps])
        return Plan(steps, identity)

    def execute(self, plan: Plan, context: ToolExecutionContext) -> AgentExecution:
        operation = "agent.execute"
        if self._paused:
            _fail("AGENT_PAUSED", operation, "agent is paused for review")
        if not isinstance(plan, Plan) or not isinstance(context, ToolExecutionContext):
            _fail("INVALID_COMPONENT", operation, "validated plan and context are required")
        expected_identity = _digest([{"kind": step.kind, "payload": dict(step.payload)} for step in plan.steps()])
        if plan.identity != expected_identity:
            _fail("PLAN_IDENTITY_MISMATCH", operation, "plan content does not match its identity")
        if any(step.kind not in {"generate", "tool"} for step in plan.steps()):
            _fail("INVALID_PLAN", operation, "plan contains an unsupported step kind")
        tool_steps = tuple(step for step in plan.steps() if step.kind == "tool")
        if not plan.steps() or plan.steps()[0].kind != "generate" or sum(step.kind == "generate" for step in plan.steps()) != 1:
            _fail("INVALID_PLAN", operation, "plan must contain exactly one leading generation step")
        if len(plan.steps()) > MAX_PLAN_STEPS or len(tool_steps) > self.policy.maximum_tool_calls:
            _fail("PLAN_BUDGET", operation, "plan exceeds current agent policy")
        if any(step.payload.get("name") not in self.policy.allowed_tools for step in tool_steps):
            _fail("TOOL_DENIED", operation, "plan contains a tool outside current policy")
        if context.network and not self.policy.network_enabled:
            _fail("NETWORK_DENIED", operation, "agent policy disables network capability")
        self._audit.append(_freeze({"event": "plan-start", "plan": plan.identity}))
        generation: GenerationResult | None = None
        results: list[ToolResult] = []
        for index, step in enumerate(plan.steps()):
            if step.kind == "generate":
                generation = self._generate_plan_text(step.payload["prompt"])
                self._audit.append(_freeze({"event": "generated", "step": index, "tokens": len(generation.tokens)}))
            else:
                call = ToolCall(step.payload["name"], step.payload["arguments"]).validate(self.tools)
                result = call.execute(context)
                results.append(result)
                tool = self.tools._tools[result.tool]
                if tool.effect == "reversible":
                    self._effects.append((tool, dict(call.arguments), result.value))
                self._audit.append(_freeze({"event": "tool", "step": index, "callId": result.callId, "identity": result.identity}))
        assert generation is not None
        self._audit.append(_freeze({"event": "plan-complete", "plan": plan.identity}))
        return AgentExecution(generation, tuple(results), len(self._effects))

    def pause(self) -> None:
        self._paused = True
        self._audit.append(_freeze({"event": "paused"}))

    def rollback(self, checkpoint: int) -> int:
        operation = "agent.rollback"
        target = _integer(checkpoint, operation, "checkpoint", 0, len(self._effects))
        reverted = 0
        while len(self._effects) > target:
            tool, arguments, result = self._effects[-1]
            assert tool.compensation is not None
            try:
                tool.compensation(arguments, result)
            except Exception:
                _fail("COMPENSATION_FAILED", operation, "tool compensation failed")
            self._effects.pop()
            reverted += 1
            self._audit.append(_freeze({"event": "rollback", "tool": tool.name}))
        return reverted

    def auditTrail(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(self._audit)


@dataclass(frozen=True)
class EvaluationResult:
    values: Mapping[str, Any]
    suiteDigest: str
    modelChecksum: str
    promptDigest: str
    toolchain: str

    def metrics(self) -> Mapping[str, Any]:
        return self.values

    def provenance(self) -> Mapping[str, Any]:
        return _freeze(
            {
                "kind": "evaluation",
                "model": self.modelChecksum,
                "data": self.suiteDigest,
                "prompt": self.promptDigest,
                "toolchain": self.toolchain,
            }
        )


class Evaluation:
    @staticmethod
    def run(suite: Mapping[str, Any], model: CausalLanguageModel) -> EvaluationResult:
        operation = "Evaluation.run"
        document = _mapping(suite, operation, "suite")
        if document.get("version") != 1 or not isinstance(model, CausalLanguageModel):
            _fail("INVALID_SUITE", operation, "version-1 suite and model are required")
        prompt_digest = document.get("promptDigest")
        toolchain = document.get("toolchain")
        if (
            not isinstance(prompt_digest, str)
            or len(prompt_digest) != 64
            or any(character not in "0123456789abcdef" for character in prompt_digest)
            or not isinstance(toolchain, str)
            or not toolchain
        ):
            _fail("INCOMPLETE_PROVENANCE", operation, "suite must bind a SHA-256 prompt digest and toolchain identity")
        toolchain = _text(toolchain, operation, "suite.toolchain")
        cases = _sequence(document.get("cases"), operation, "suite.cases")
        if not cases or len(cases) > MAX_EVALUATION_CASES:
            _fail("LIMIT_EXCEEDED", operation, "suite case count is outside the bounded profile")
        correct = 0
        safe = 0
        operations = 0
        for index, case in enumerate(cases):
            item = _mapping(case, operation, f"cases[{index}]")
            tokens = _sequence(item.get("tokens"), operation, "case.tokens")
            cache = KvCache.new({"maximumLength": model.contextLength(), "modelChecksum": model.checksum})
            result = model.forward(tokens, cache)
            predicted = max(range(len(result.logits)), key=lambda token: (result.logits[token], -token))
            expected = _integer(item.get("expectedTopToken"), operation, "expectedTopToken", 0, model.vocabulary_size - 1)
            correct += predicted == expected
            secret_present = item.get("secretPresent", False)
            policy_bypass = item.get("policyBypass", False)
            if not isinstance(secret_present, bool) or not isinstance(policy_bypass, bool):
                _fail("INVALID_BOOLEAN", operation, "safety flags must be Bool")
            expected_decision = item.get("expectedSafetyDecision")
            if expected_decision not in {"allow", "deny"}:
                _fail("INVALID_DECISION", operation, "expectedSafetyDecision must be allow or deny")
            observed_decision = "deny" if secret_present or policy_bypass else "allow"
            safe += observed_decision == expected_decision
            operations += result.operations
        values = _freeze(
            {
                "cases": len(cases),
                "accuracy": correct / len(cases),
                "safetyRate": safe / len(cases),
                "operations": operations,
                "performanceClaim": "logical-operations-only",
            }
        )
        return EvaluationResult(values, _digest(document), model.checksum, prompt_digest, toolchain)


__all__ = [
    "Agent",
    "AgentExecution",
    "AiError",
    "AiPolicy",
    "ApprovalRequest",
    "CausalLanguageModel",
    "Evaluation",
    "EvaluationResult",
    "ForwardResult",
    "GenerationResult",
    "Generator",
    "KvCache",
    "OutputSchema",
    "Plan",
    "PlanStep",
    "Prompt",
    "Sampler",
    "StructuredOutput",
    "Tool",
    "ToolCall",
    "ToolExecutionContext",
    "ToolRegistry",
    "ToolResult",
    "Tokenizer",
]
