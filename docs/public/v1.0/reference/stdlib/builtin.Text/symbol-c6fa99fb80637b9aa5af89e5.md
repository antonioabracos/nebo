# builtin.Text — Text.console()

Current typed source proof g170-console:Text.console. Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table&lt;Int&gt; 32x8, Tree&lt;Int&gt; 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01. Corrected G018 SHA256=0944468ee395ee0c83aa6697baf52d111053327405fafd499e3cf08d57031718 Retained document/headless software profile; exact nodes and bytes; no live desktop claim

```text
Identity: g018-declaration:Text.console() (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
Text.console()
Current typed source proof g170-console:Text.console. Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table<Int> 32x8, Tree<Int> 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01. Corrected G018 SHA256=0944468ee395ee0c83aa6697baf52d111053327405fafd499e3cf08d57031718 Retained document/headless software profile; exact nodes and bytes; no live desktop claim
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Current typed source proof g170-console:Text.console. Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table&lt;Int&gt; 32x8, Tree&lt;Int&gt; 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01. Corrected G018 SHA256=0944468ee395ee0c83aa6697baf52d111053327405fafd499e3cf08d57031718 Retained document/headless software profile; exact nodes and bytes; no live desktop claim

## Effects, capabilities and sandbox

console; SYNTHETIC_INPUT_AND_RETAINED_CONSOLE. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Current typed source proof g170-console:Text.console. Retained source values plus opt-in pointer-free document/RenderTree/software observation; 256x128 BGRA8 synthetic glyphs; linear document 4096 bytes and title 256 bytes; size is UTF-8 bytes/lines; style selects zero-based payload nodes; Position is logical software pixels; typed Color RGBA8 and native Result; structured Table&lt;Int&gt; 32x8, Tree&lt;Int&gt; 32 nodes/depth16, named products 8 fields/declarations; 4096 rendered bytes and 64 structured publications. Every effect executes once; no window/backend capability inferred. See G170 checklist for narrower method bounds; metadata joins remain in F01. Corrected G018 SHA256=0944468ee395ee0c83aa6697baf52d111053327405fafd499e3cf08d57031718 Retained document/headless software profile; exact nodes and bytes; no live desktop claim Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

CORRECTED_VISUAL_DECLARATION. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### console:publish-seed; expected 23

```nebo
start(){("seed").console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_state_trace": true, "console_text_utf8": "seed", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "observation": {"native_oracle": "console_public_test.compare"}, "process_exit": 23, "publications": 1, "runtime_determinism": "DOMAIN_INVARIANTS", "runtime_sha256": "5b66017b71682513cc01bf330af28328e8ecc808a6c3b6c7e75e418fd0791aff", "text": {"bytes_hex": "73656564"}}

## Rejected examples

### console:bare-color; expected NEBO_TYPE_MISMATCH

```nebo
start(){"seed".console(Color.rgb(17,29,53));23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-744da926f94929d16c738e1a](symbol-744da926f94929d16c738e1a.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/console_public_test.py — SHA-256 4ff1b67ea212ce82443057d944c9993e64ad919fe90faadb19f0cb6014f4cff5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
