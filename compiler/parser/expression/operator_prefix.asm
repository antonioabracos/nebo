; Prefix and power precedence contracts. Power is specified here but remains
; inactive until its Registry front assigns a token and semantic protocol.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/expression/operator_precedence.inc"

%define PREFIX_TOKEN_OFFSET 0
%define PREFIX_REGISTRY_ID_OFFSET 8
%define PREFIX_RIGHT_BP_OFFSET 16
%define PREFIX_ASSOC_OFFSET 24
%define PREFIX_FLAGS_OFFSET 32
%define PREFIX_ENTRY_SIZE 40
%define PREFIX_ENTRY_COUNT 3

section .rodata
align 8
prefix_entries:
 dq NEBOC_TOKEN_PLUS,18,NEBOC_OPERATOR_BP_PREFIX,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 dq NEBOC_TOKEN_MINUS,19,NEBOC_OPERATOR_BP_PREFIX,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 dq NEBOC_TOKEN_BANG,20,NEBOC_OPERATOR_BP_PREFIX,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT

section .text
; prefix_lookup(token_kind) -> RAX=record or zero, EDX=Registry numeric ID,
; ECX=right BP, R8D=associativity, R9D=activation flags.
NEBOC_ABI_FUNCTION neboc_operator_prefix_lookup
 lea rax,[rel prefix_entries]
 mov r10d,PREFIX_ENTRY_COUNT
.loop:
 cmp [rax+PREFIX_TOKEN_OFFSET],rdi
 je .found
 add rax,PREFIX_ENTRY_SIZE
 dec r10d
 jnz .loop
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 ret
.found:
 mov edx,[rax+PREFIX_REGISTRY_ID_OFFSET]
 mov ecx,[rax+PREFIX_RIGHT_BP_OFFSET]
 mov r8d,[rax+PREFIX_ASSOC_OFFSET]
 mov r9d,[rax+PREFIX_FLAGS_OFFSET]
 ret

; Power binds above prefix and is right associative: left BP == right BP.
; The precedence contract is active in P02; token activation remains owned by
; the canonical caret front in G123.
NEBOC_ABI_FUNCTION neboc_operator_power_contract
 xor eax,eax
 mov edx,NEBOC_OPERATOR_BP_POWER
 mov ecx,NEBOC_OPERATOR_BP_POWER
 mov r8d,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT
 mov r9d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
