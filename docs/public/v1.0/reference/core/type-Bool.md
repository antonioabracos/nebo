# Bool

A Boolean value, distinct from Int.

```text
Identity: type:Bool (INTRINSIC_TYPE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NATIVE_AND_SOURCE_PROFILE
```

## Syntax or signature

```text
Bool
Native TypeId: 2 (not SymbolId)
```

## Logical layout

One logical truth value; native scalar layout uses one byte.

## Construction and members

true or false; !, &amp;&amp;, ||, xor and comparisons; console emits Bool nodes.

## Protocols and ownership

The Bool value preserves its concrete semantic identity through bindings and arguments. Arithmetic/comparison does not grant I/O authority; console is an explicit effect. Only the documented comparisons and generic constraint profiles apply. A TypeId does not synthesize a user-defined Eq/Ord, clone or drop implementation.

## Errors, limits and target

Use x86_64 Linux System V ELF for the executed examples. Incompatible types reject before publication; bounds and ownership checks precede an invalid read, mutation or drop. Internal descriptor layouts are not portable ABI promises.

## Executed examples

### binding:Bool-1-typed; expected 23

```nebo
start(){Bool.value;true.value;value.console();23.return;}
```

Oracle: {"console_text_utf8": "true", "independent_builds": 2, "kinds": \[5\], "process_exit": 23, "runtime_sha256": "26e99610443e30ab87a629aa5de2392ce6d0117574455307c7c97e44b2fcac90"}

## Rejected examples

### semantics:no-coercion-Bool; expected NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH

```nebo
start(){Bool.x;17.x;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH"}

## Additional observations and limits

```text
[
  {
    "base": 0,
    "case_id": "types:type-2",
    "category": "native-type",
    "flags": 1,
    "kind": 2,
    "observed_sha256": "600970fbc9fbf307e9cbc27eb83e851f731ccefd0f115d17ec7e682beb34f53d",
    "type_id": 2
  }
]
```

## Related entries

[Index](index.md)

- [type-Void](type-Void.md)

- [type-Int](type-Int.md)

- [type-Text](type-Text.md)

- [type-Console](type-Console.md)

## Provenance

- compiler/semantic/types/type_table.inc — SHA-256 a104864da8c77b21c4186ba1cdcf8d40800c464a8edbcccf31fc1ed57b4cf528

- compiler/semantic/types/type_table.asm — SHA-256 1c04c832d2df1cd5900cf37fa73aa91884c79d7754d1e85c8ce29fa473e227b3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
