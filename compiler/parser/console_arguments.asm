; Nebo Assembly — CHAMADAS-ANINHADAS-EM-CONSOLE-E-AVALIACAO-EXACTLY-ONCE general Console ArgumentList model
bits 64
default rel
%include "compiler/parser/console_arguments.inc"
global neboc_console_argument_list_build
global neboc_console_budget_validate
section .text
; rdi=array of argument nodes, rsi=count, rdx=out list. Atomic on failure.
neboc_console_argument_list_build:
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .empty
    test rdi, rdi
    jz .invalid
    cmp rsi, NEBOC_MAX_CONSOLE_OPTIONS
    ja .too_many
    xor r8d, r8d                    ; index
    xor r9d, r9d                    ; total nodes
    xor r10d, r10d                  ; maximum depth
.next:
    cmp r8, rsi
    jae .commit
    mov rax, r8
    imul rax, NEBOC_ARGUMENT_NODE_SIZE
    lea rcx, [rdi + rax]
    mov rax, [rcx + NEBOC_ARGUMENT_NODE_KIND_OFFSET]
    cmp eax, NEBOC_ARGUMENT_EXPR
    je .kind_ok
    cmp eax, NEBOC_ARGUMENT_OPTION_CALL
    jne .invalid
.kind_ok:
    mov rax, [rcx + NEBOC_ARGUMENT_NODE_SPAN_START_OFFSET]
    cmp rax, [rcx + NEBOC_ARGUMENT_NODE_SPAN_END_OFFSET]
    ja .invalid
    mov rax, [rcx + NEBOC_ARGUMENT_NODE_SUBTREE_NODES_OFFSET]
    test rax, rax
    jz .invalid
    add r9, rax
    jc .nodes
    cmp r9, NEBOC_MAX_OPTION_AST_NODES
    ja .nodes
    mov rax, [rcx + NEBOC_ARGUMENT_NODE_DEPTH_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, NEBOC_MAX_NESTED_CALL_DEPTH
    ja .depth
    cmp rax, r10
    cmova r10, rax
    inc r8
    jmp .next
.empty:
    xor rdi, rdi
    xor r9d, r9d
    xor r10d, r10d
.commit:
    mov [rdx + NEBOC_ARGUMENT_LIST_ITEMS_OFFSET], rdi
    mov [rdx + NEBOC_ARGUMENT_LIST_COUNT_OFFSET], rsi
    mov [rdx + NEBOC_ARGUMENT_LIST_TOTAL_NODES_OFFSET], r9
    mov [rdx + NEBOC_ARGUMENT_LIST_MAX_DEPTH_OFFSET], r10
    xor eax, eax
    ret
.too_many:
    mov eax, NEBOC_CONSOLE_ARGS_TOO_MANY
    ret
.depth:
    mov eax, NEBOC_CONSOLE_ARGS_DEPTH
    ret
.nodes:
    mov eax, NEBOC_CONSOLE_ARGS_NODES
    ret
.invalid:
    mov eax, NEBOC_CONSOLE_ARGS_INVALID
    ret

; rdi=options, rsi=max arguments in one option, rdx=depth, rcx=AST nodes,
; r8=build steps, r9=out accepted budget snapshot.
neboc_console_budget_validate:
    test r9, r9
    jz .budget_invalid
    cmp rdi, NEBOC_MAX_CONSOLE_OPTIONS
    ja .budget_options
    cmp rsi, NEBOC_MAX_OPTION_ARGUMENTS
    ja .budget_arguments
    cmp rdx, NEBOC_MAX_NESTED_CALL_DEPTH
    ja .budget_depth
    cmp rcx, NEBOC_MAX_OPTION_AST_NODES
    ja .budget_nodes
    cmp r8, NEBOC_MAX_OPTION_BUILD_STEPS
    ja .budget_steps
    mov [r9 + NEBOC_BUDGET_OPTIONS_OFFSET], rdi
    mov [r9 + NEBOC_BUDGET_ARGUMENTS_OFFSET], rsi
    mov [r9 + NEBOC_BUDGET_DEPTH_OFFSET], rdx
    mov [r9 + NEBOC_BUDGET_NODES_OFFSET], rcx
    mov [r9 + NEBOC_BUDGET_STEPS_OFFSET], r8
    xor eax, eax
    ret
.budget_options:
    mov eax, NEBOC_CONSOLE_ARGS_TOO_MANY
    ret
.budget_arguments:
    mov eax, NEBOC_CONSOLE_ARGS_ARGUMENTS
    ret
.budget_depth:
    mov eax, NEBOC_CONSOLE_ARGS_DEPTH
    ret
.budget_nodes:
    mov eax, NEBOC_CONSOLE_ARGS_NODES
    ret
.budget_steps:
    mov eax, NEBOC_CONSOLE_ARGS_STEPS
    ret
.budget_invalid:
    mov eax, NEBOC_CONSOLE_ARGS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
