; Nebo Assembly — approved compilation limits v0
;
; Purpose:
;   Initialize, validate, query and reduce DG-009 compiler resource limits.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX and explicit out values.
;
; Status:
;   OK, INVALID_ARGUMENT or LIMIT_EXCEEDED.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   Unchanged; no red-zone dependency.
;
; Ownership:
;   The caller owns the limits block.
;
; Thread safety:
;   Reentrant; session ownership is enforced by the session layer.
;
; Errors:
;   Unknown resources, zero values and values above approved defaults fail.
;
; Tests:
;   MF010 session contract suite and TR02 exit gate.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/limits/compilation_limits.inc"

section .text

NEBOC_ABI_FUNCTION neboc_compilation_limits_defaults
    test rdi, rdi
    jz .invalid
    mov qword [rdi + NEBOC_LIMIT_SOURCE_BYTES_OFFSET], NEBOC_LIMIT_DEFAULT_SOURCE_BYTES
    mov qword [rdi + NEBOC_LIMIT_TOKENS_OFFSET], NEBOC_LIMIT_DEFAULT_TOKENS
    mov qword [rdi + NEBOC_LIMIT_AST_NODES_OFFSET], NEBOC_LIMIT_DEFAULT_AST_NODES
    mov qword [rdi + NEBOC_LIMIT_SYMBOLS_OFFSET], NEBOC_LIMIT_DEFAULT_SYMBOLS
    mov qword [rdi + NEBOC_LIMIT_FUNCTIONS_OFFSET], NEBOC_LIMIT_DEFAULT_FUNCTIONS
    mov qword [rdi + NEBOC_LIMIT_DIAGNOSTICS_OFFSET], NEBOC_LIMIT_DEFAULT_DIAGNOSTICS
    mov qword [rdi + NEBOC_LIMIT_PARSER_NESTING_OFFSET], NEBOC_LIMIT_DEFAULT_PARSER_NESTING
    mov qword [rdi + NEBOC_LIMIT_DEPENDENCY_NODES_OFFSET], NEBOC_LIMIT_DEFAULT_DEPENDENCY_NODES
    mov qword [rdi + NEBOC_LIMIT_DEPENDENCY_EDGES_OFFSET], NEBOC_LIMIT_DEFAULT_DEPENDENCY_EDGES
    mov qword [rdi + NEBOC_LIMIT_GENERATED_ASM_BYTES_OFFSET], NEBOC_LIMIT_DEFAULT_GENERATED_ASM_BYTES
    mov qword [rdi + NEBOC_LIMIT_TOOL_OUTPUT_BYTES_OFFSET], NEBOC_LIMIT_DEFAULT_TOOL_OUTPUT_BYTES
    mov qword [rdi + NEBOC_LIMIT_RESERVED_OFFSET], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_compilation_limits_validate
    test rdi, rdi
    jz .invalid
%macro CHECK_LIMIT_FIELD 2
    mov rax, [rdi + %1]
    test rax, rax
    jz .invalid
    cmp rax, %2
    ja .limit
%endmacro
    CHECK_LIMIT_FIELD NEBOC_LIMIT_SOURCE_BYTES_OFFSET, NEBOC_LIMIT_DEFAULT_SOURCE_BYTES
    CHECK_LIMIT_FIELD NEBOC_LIMIT_TOKENS_OFFSET, NEBOC_LIMIT_DEFAULT_TOKENS
    CHECK_LIMIT_FIELD NEBOC_LIMIT_AST_NODES_OFFSET, NEBOC_LIMIT_DEFAULT_AST_NODES
    CHECK_LIMIT_FIELD NEBOC_LIMIT_SYMBOLS_OFFSET, NEBOC_LIMIT_DEFAULT_SYMBOLS
    CHECK_LIMIT_FIELD NEBOC_LIMIT_FUNCTIONS_OFFSET, NEBOC_LIMIT_DEFAULT_FUNCTIONS
    CHECK_LIMIT_FIELD NEBOC_LIMIT_DIAGNOSTICS_OFFSET, NEBOC_LIMIT_DEFAULT_DIAGNOSTICS
    CHECK_LIMIT_FIELD NEBOC_LIMIT_PARSER_NESTING_OFFSET, NEBOC_LIMIT_DEFAULT_PARSER_NESTING
    CHECK_LIMIT_FIELD NEBOC_LIMIT_DEPENDENCY_NODES_OFFSET, NEBOC_LIMIT_DEFAULT_DEPENDENCY_NODES
    CHECK_LIMIT_FIELD NEBOC_LIMIT_DEPENDENCY_EDGES_OFFSET, NEBOC_LIMIT_DEFAULT_DEPENDENCY_EDGES
    CHECK_LIMIT_FIELD NEBOC_LIMIT_GENERATED_ASM_BYTES_OFFSET, NEBOC_LIMIT_DEFAULT_GENERATED_ASM_BYTES
    CHECK_LIMIT_FIELD NEBOC_LIMIT_TOOL_OUTPUT_BYTES_OFFSET, NEBOC_LIMIT_DEFAULT_TOOL_OUTPUT_BYTES
%unmacro CHECK_LIMIT_FIELD 2
    cmp qword [rdi + NEBOC_LIMIT_RESERVED_OFFSET], 0
    jne .invalid
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; limits_get(limits*, resource_kind, out_value*)
NEBOC_ABI_FUNCTION neboc_compilation_limit_get
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    mov qword [rdx], 0
    cmp rsi, NEBOC_RESOURCE_SOURCE_BYTES
    je .source
    cmp rsi, NEBOC_RESOURCE_TOKENS
    je .tokens
    cmp rsi, NEBOC_RESOURCE_AST_NODES
    je .ast
    cmp rsi, NEBOC_RESOURCE_SYMBOLS
    je .symbols
    cmp rsi, NEBOC_RESOURCE_FUNCTIONS
    je .functions
    cmp rsi, NEBOC_RESOURCE_DIAGNOSTICS
    je .diagnostics
    cmp rsi, NEBOC_RESOURCE_PARSER_NESTING
    je .nesting
    cmp rsi, NEBOC_RESOURCE_DEPENDENCY_NODES
    je .dep_nodes
    cmp rsi, NEBOC_RESOURCE_DEPENDENCY_EDGES
    je .dep_edges
    cmp rsi, NEBOC_RESOURCE_GENERATED_ASM_BYTES
    je .generated
    cmp rsi, NEBOC_RESOURCE_TOOL_OUTPUT_BYTES
    je .tool_output
    jmp .invalid
.source:
    mov rax, [rdi + NEBOC_LIMIT_SOURCE_BYTES_OFFSET]
    jmp .store
.tokens:
    mov rax, [rdi + NEBOC_LIMIT_TOKENS_OFFSET]
    jmp .store
.ast:
    mov rax, [rdi + NEBOC_LIMIT_AST_NODES_OFFSET]
    jmp .store
.symbols:
    mov rax, [rdi + NEBOC_LIMIT_SYMBOLS_OFFSET]
    jmp .store
.functions:
    mov rax, [rdi + NEBOC_LIMIT_FUNCTIONS_OFFSET]
    jmp .store
.diagnostics:
    mov rax, [rdi + NEBOC_LIMIT_DIAGNOSTICS_OFFSET]
    jmp .store
.nesting:
    mov rax, [rdi + NEBOC_LIMIT_PARSER_NESTING_OFFSET]
    jmp .store
.dep_nodes:
    mov rax, [rdi + NEBOC_LIMIT_DEPENDENCY_NODES_OFFSET]
    jmp .store
.dep_edges:
    mov rax, [rdi + NEBOC_LIMIT_DEPENDENCY_EDGES_OFFSET]
    jmp .store
.generated:
    mov rax, [rdi + NEBOC_LIMIT_GENERATED_ASM_BYTES_OFFSET]
    jmp .store
.tool_output:
    mov rax, [rdi + NEBOC_LIMIT_TOOL_OUTPUT_BYTES_OFFSET]
.store:
    mov [rdx], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; limits_set_checked(limits*, resource_kind, value)
NEBOC_ABI_FUNCTION neboc_compilation_limit_set_checked
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp rsi, NEBOC_RESOURCE_SOURCE_BYTES
    je .source
    cmp rsi, NEBOC_RESOURCE_TOKENS
    je .tokens
    cmp rsi, NEBOC_RESOURCE_AST_NODES
    je .ast
    cmp rsi, NEBOC_RESOURCE_SYMBOLS
    je .symbols
    cmp rsi, NEBOC_RESOURCE_FUNCTIONS
    je .functions
    cmp rsi, NEBOC_RESOURCE_DIAGNOSTICS
    je .diagnostics
    cmp rsi, NEBOC_RESOURCE_PARSER_NESTING
    je .nesting
    cmp rsi, NEBOC_RESOURCE_DEPENDENCY_NODES
    je .dep_nodes
    cmp rsi, NEBOC_RESOURCE_DEPENDENCY_EDGES
    je .dep_edges
    cmp rsi, NEBOC_RESOURCE_GENERATED_ASM_BYTES
    je .generated
    cmp rsi, NEBOC_RESOURCE_TOOL_OUTPUT_BYTES
    je .tool_output
    jmp .invalid
.source:
    cmp rdx, NEBOC_LIMIT_DEFAULT_SOURCE_BYTES
    ja .limit
    mov [rdi + NEBOC_LIMIT_SOURCE_BYTES_OFFSET], rdx
    jmp .ok
.tokens:
    cmp rdx, NEBOC_LIMIT_DEFAULT_TOKENS
    ja .limit
    mov [rdi + NEBOC_LIMIT_TOKENS_OFFSET], rdx
    jmp .ok
.ast:
    cmp rdx, NEBOC_LIMIT_DEFAULT_AST_NODES
    ja .limit
    mov [rdi + NEBOC_LIMIT_AST_NODES_OFFSET], rdx
    jmp .ok
.symbols:
    cmp rdx, NEBOC_LIMIT_DEFAULT_SYMBOLS
    ja .limit
    mov [rdi + NEBOC_LIMIT_SYMBOLS_OFFSET], rdx
    jmp .ok
.functions:
    cmp rdx, NEBOC_LIMIT_DEFAULT_FUNCTIONS
    ja .limit
    mov [rdi + NEBOC_LIMIT_FUNCTIONS_OFFSET], rdx
    jmp .ok
.diagnostics:
    cmp rdx, NEBOC_LIMIT_DEFAULT_DIAGNOSTICS
    ja .limit
    mov [rdi + NEBOC_LIMIT_DIAGNOSTICS_OFFSET], rdx
    jmp .ok
.nesting:
    cmp rdx, NEBOC_LIMIT_DEFAULT_PARSER_NESTING
    ja .limit
    mov [rdi + NEBOC_LIMIT_PARSER_NESTING_OFFSET], rdx
    jmp .ok
.dep_nodes:
    cmp rdx, NEBOC_LIMIT_DEFAULT_DEPENDENCY_NODES
    ja .limit
    mov [rdi + NEBOC_LIMIT_DEPENDENCY_NODES_OFFSET], rdx
    jmp .ok
.dep_edges:
    cmp rdx, NEBOC_LIMIT_DEFAULT_DEPENDENCY_EDGES
    ja .limit
    mov [rdi + NEBOC_LIMIT_DEPENDENCY_EDGES_OFFSET], rdx
    jmp .ok
.generated:
    cmp rdx, NEBOC_LIMIT_DEFAULT_GENERATED_ASM_BYTES
    ja .limit
    mov [rdi + NEBOC_LIMIT_GENERATED_ASM_BYTES_OFFSET], rdx
    jmp .ok
.tool_output:
    cmp rdx, NEBOC_LIMIT_DEFAULT_TOOL_OUTPUT_BYTES
    ja .limit
    mov [rdi + NEBOC_LIMIT_TOOL_OUTPUT_BYTES_OFFSET], rdx
.ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

section .note.GNU-stack noalloc noexec nowrite progbits
