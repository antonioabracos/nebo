; Nebo Assembly — CHAMADAS-ANINHADAS-EM-CONSOLE-E-AVALIACAO-EXACTLY-ONCE failure-atomic ConsoleOption construction
bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "runtime/console_options.inc"
global nebo_console_options_commit
global nebo_console_options_normalize
global nebo_console_options_budget_check
global nebo_console_options_default
global nebo_console_options_init
global nebo_console_option_model
section .text
; rdi=out ConsoleOption model. Defaults contain no values, borrow no memory,
; and authorize only the ordinary write effect.
nebo_console_options_default:
    test rdi, rdi
    jz console_model_invalid
    mov qword [rdi + NEBO_CONSOLE_OPTIONS_VALUES_OFFSET], 0
    mov qword [rdi + NEBO_CONSOLE_OPTIONS_COUNT_OFFSET], 0
    mov qword [rdi + NEBO_CONSOLE_OPTIONS_CAPACITY_OFFSET], NEBOC_MAX_CONSOLE_OPTIONS
    mov qword [rdi + NEBO_CONSOLE_OPTIONS_CAPABILITIES_OFFSET], NEBO_CONSOLE_OPTIONS_DEFAULT_CAPABILITIES
    mov qword [rdi + NEBO_CONSOLE_OPTIONS_STATE_OFFSET], NEBO_CONSOLE_OPTIONS_READY
    xor eax, eax
    ret

; rdi=out model, rsi=borrowed option values, rdx=count, rcx=capacity.
; Publication is atomic: every invariant is checked before the first write.
nebo_console_options_init:
    test rdi, rdi
    jz console_model_invalid
    cmp rdx, NEBOC_MAX_CONSOLE_OPTIONS
    ja console_model_budget
    cmp rcx, NEBOC_MAX_CONSOLE_OPTIONS
    ja console_model_capacity
    cmp rdx, rcx
    ja console_model_capacity
    test rdx, rdx
    jz .model_init_commit
    test rsi, rsi
    jz console_model_invalid
.model_init_commit:
    mov [rdi + NEBO_CONSOLE_OPTIONS_VALUES_OFFSET], rsi
    mov [rdi + NEBO_CONSOLE_OPTIONS_COUNT_OFFSET], rdx
    mov [rdi + NEBO_CONSOLE_OPTIONS_CAPACITY_OFFSET], rcx
    mov qword [rdi + NEBO_CONSOLE_OPTIONS_CAPABILITIES_OFFSET], NEBO_CONSOLE_OPTIONS_DEFAULT_CAPABILITIES
    mov qword [rdi + NEBO_CONSOLE_OPTIONS_STATE_OFFSET], NEBO_CONSOLE_OPTIONS_READY
    xor eax, eax
    ret

; rdi=ready model, rsi=out model snapshot.  The copied snapshot preserves the
; explicit borrowed ownership contract and never publishes on failure.
nebo_console_option_model:
    test rdi, rdi
    jz console_model_invalid
    test rsi, rsi
    jz console_model_invalid
    cmp qword [rdi + NEBO_CONSOLE_OPTIONS_STATE_OFFSET], NEBO_CONSOLE_OPTIONS_READY
    jne console_model_invalid
    mov rax, [rdi + NEBO_CONSOLE_OPTIONS_COUNT_OFFSET]
    cmp rax, NEBOC_MAX_CONSOLE_OPTIONS
    ja console_model_budget
    cmp rax, [rdi + NEBO_CONSOLE_OPTIONS_CAPACITY_OFFSET]
    ja console_model_capacity
    test rax, rax
    jz .model_copy
    cmp qword [rdi + NEBO_CONSOLE_OPTIONS_VALUES_OFFSET], 0
    je console_model_invalid
.model_copy:
    mov rax, [rdi + NEBO_CONSOLE_OPTIONS_VALUES_OFFSET]
    mov [rsi + NEBO_CONSOLE_OPTIONS_VALUES_OFFSET], rax
    mov rax, [rdi + NEBO_CONSOLE_OPTIONS_COUNT_OFFSET]
    mov [rsi + NEBO_CONSOLE_OPTIONS_COUNT_OFFSET], rax
    mov rax, [rdi + NEBO_CONSOLE_OPTIONS_CAPACITY_OFFSET]
    mov [rsi + NEBO_CONSOLE_OPTIONS_CAPACITY_OFFSET], rax
    mov rax, [rdi + NEBO_CONSOLE_OPTIONS_CAPABILITIES_OFFSET]
    mov [rsi + NEBO_CONSOLE_OPTIONS_CAPABILITIES_OFFSET], rax
    mov qword [rsi + NEBO_CONSOLE_OPTIONS_STATE_OFFSET], NEBO_CONSOLE_OPTIONS_READY
    xor eax, eax
    ret
console_model_capacity:
    mov eax, NEBO_OPTIONS_CAPACITY
    ret
console_model_budget:
    mov eax, NEBO_OPTIONS_BUDGET
    ret
console_model_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret

; rdi=request. validator(value, context) returns eax status. The destination
; and receipt are not touched until all values have passed validation.
nebo_console_options_commit:
    test rdi, rdi
    jz .invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rdi
    mov r12, [rbx + NEBO_OPTIONS_REQUEST_COUNT_OFFSET]
    cmp r12, NEBOC_MAX_CONSOLE_OPTIONS
    ja .budget
    cmp r12, [rbx + NEBO_OPTIONS_REQUEST_CAPACITY_OFFSET]
    ja .capacity
    mov r13, [rbx + NEBO_OPTIONS_REQUEST_RECEIPT_OFFSET]
    test r13, r13
    jz .invalid_saved
    test r12, r12
    jz .publish
    mov r14, [rbx + NEBO_OPTIONS_REQUEST_VALUES_OFFSET]
    mov r15, [rbx + NEBO_OPTIONS_REQUEST_DESTINATION_OFFSET]
    test r14, r14
    jz .invalid_saved
    test r15, r15
    jz .invalid_saved
    mov r10, [rbx + NEBO_OPTIONS_REQUEST_VALIDATOR_OFFSET]
    test r10, r10
    jz .invalid_saved
    xor r9d, r9d
.validate:
    cmp r9, r12
    jae .copy_start
    mov rdi, [r14 + r9 * 8]
    mov rsi, [rbx + NEBO_OPTIONS_REQUEST_CONTEXT_OFFSET]
    push r9
    push r10
    call r10
    pop r10
    pop r9
    test eax, eax
    jnz .validation_failed
    inc r9
    jmp .validate
.copy_start:
    xor r9d, r9d
.copy:
    cmp r9, r12
    jae .publish
    mov rax, [r14 + r9 * 8]
    mov [r15 + r9 * 8], rax
    inc r9
    jmp .copy
.publish:
    mov [r13 + NEBO_OPTIONS_RECEIPT_COUNT_OFFSET], r12
    mov [r13 + NEBO_OPTIONS_RECEIPT_STEPS_OFFSET], r12
    mov qword [r13 + NEBO_OPTIONS_RECEIPT_STATE_OFFSET], NEBO_OPTIONS_RECEIPT_COMMITTED
    xor eax, eax
    jmp .done
.validation_failed:
    mov eax, NEBO_OPTIONS_VALIDATION_FAILED
    jmp .done
.capacity:
    mov eax, NEBO_OPTIONS_CAPACITY
    jmp .done
.budget:
    mov eax, NEBO_OPTIONS_BUDGET
    jmp .done
.invalid_saved:
    mov eax, NEBO_OPTIONS_INVALID
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret

; rdi=normalize request. Validates duplicates/conflicts before canonical sorting.
nebo_console_options_normalize:
    test rdi, rdi
    jz .normalize_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rdi
    mov r12, [rbx + NEBO_OPTIONS_NORMALIZE_COUNT_OFFSET]
    cmp r12, NEBOC_MAX_CONSOLE_OPTIONS
    ja .normalize_budget
    cmp r12, [rbx + NEBO_OPTIONS_NORMALIZE_CAPACITY_OFFSET]
    ja .normalize_capacity
    mov r13, [rbx + NEBO_OPTIONS_NORMALIZE_VALUES_OFFSET]
    mov r14, [rbx + NEBO_OPTIONS_NORMALIZE_DESTINATION_OFFSET]
    mov r15, [rbx + NEBO_OPTIONS_NORMALIZE_RECEIPT_OFFSET]
    test r15, r15
    jz .normalize_invalid_saved
    test r12, r12
    jz .normalize_publish
    test r13, r13
    jz .normalize_invalid_saved
    test r14, r14
    jz .normalize_invalid_saved
    xor r8d, r8d
.normalize_outer:
    cmp r8, r12
    jae .normalize_copy_start
    imul rax, r8, NEBO_OPTION_VALUE_SIZE
    lea r9, [r13 + rax]
    mov r10, [r9 + NEBO_OPTION_VALUE_KIND_OFFSET]
    cmp r10, 1
    jb .normalize_invalid_saved
    cmp r10, 32
    ja .normalize_invalid_saved
    lea r11, [r8 + 1]
.normalize_pair:
    cmp r11, r12
    jae .normalize_next
    imul rax, r11, NEBO_OPTION_VALUE_SIZE
    lea rdx, [r13 + rax]
    mov rax, [rdx + NEBO_OPTION_VALUE_KIND_OFFSET]
    cmp rax, r10
    je .normalize_duplicate
    cmp rax, 1
    jb .normalize_invalid_saved
    cmp rax, 32
    ja .normalize_invalid_saved
    mov ecx, eax
    dec ecx
    mov rax, 1
    shl rax, cl
    test [r9 + NEBO_OPTION_VALUE_CONFLICT_MASK_OFFSET], rax
    jnz .normalize_conflict
    mov ecx, r10d
    dec ecx
    mov rax, 1
    shl rax, cl
    test [rdx + NEBO_OPTION_VALUE_CONFLICT_MASK_OFFSET], rax
    jnz .normalize_conflict
    inc r11
    jmp .normalize_pair
.normalize_next:
    inc r8
    jmp .normalize_outer
.normalize_copy_start:
    xor r8d, r8d
.normalize_copy:
    cmp r8, r12
    jae .normalize_sort_start
    imul rax, r8, NEBO_OPTION_VALUE_SIZE
    lea rdx, [r13 + rax]
    lea rcx, [r14 + rax]
    mov r9, [rdx]
    mov [rcx], r9
    mov r9, [rdx + 8]
    mov [rcx + 8], r9
    mov r9, [rdx + 16]
    mov [rcx + 16], r9
    inc r8
    jmp .normalize_copy
.normalize_sort_start:
    mov r8, 1
.normalize_sort_outer:
    cmp r8, r12
    jae .normalize_publish
    imul rax, r8, NEBO_OPTION_VALUE_SIZE
    lea rcx, [r14 + rax]
    mov r9, [rcx]
    mov r10, [rcx + 8]
    mov r11, [rcx + 16]
    mov rdx, r8
.normalize_sort_inner:
    test rdx, rdx
    jz .normalize_insert
    lea rax, [rdx - 1]
    imul rax, rax, NEBO_OPTION_VALUE_SIZE
    lea rcx, [r14 + rax]
    cmp [rcx], r9
    jbe .normalize_insert
    mov rax, [rcx]
    mov [rcx + NEBO_OPTION_VALUE_SIZE], rax
    mov rax, [rcx + 8]
    mov [rcx + NEBO_OPTION_VALUE_SIZE + 8], rax
    mov rax, [rcx + 16]
    mov [rcx + NEBO_OPTION_VALUE_SIZE + 16], rax
    dec rdx
    jmp .normalize_sort_inner
.normalize_insert:
    imul rax, rdx, NEBO_OPTION_VALUE_SIZE
    lea rcx, [r14 + rax]
    mov [rcx], r9
    mov [rcx + 8], r10
    mov [rcx + 16], r11
    inc r8
    jmp .normalize_sort_outer
.normalize_publish:
    mov [r15 + NEBO_OPTIONS_RECEIPT_COUNT_OFFSET], r12
    mov [r15 + NEBO_OPTIONS_RECEIPT_STEPS_OFFSET], r12
    mov qword [r15 + NEBO_OPTIONS_RECEIPT_STATE_OFFSET], NEBO_OPTIONS_RECEIPT_COMMITTED
    xor eax, eax
    jmp .normalize_done
.normalize_duplicate:
    mov eax, NEBO_OPTIONS_DUPLICATE
    jmp .normalize_done
.normalize_conflict:
    mov eax, NEBO_OPTIONS_CONFLICT
    jmp .normalize_done
.normalize_capacity:
    mov eax, NEBO_OPTIONS_CAPACITY
    jmp .normalize_done
.normalize_budget:
    mov eax, NEBO_OPTIONS_BUDGET
    jmp .normalize_done
.normalize_invalid_saved:
    mov eax, NEBO_OPTIONS_INVALID
.normalize_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.normalize_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret

; rdi=observed budget snapshot, rsi=out accepted snapshot. Atomic on overflow.
nebo_console_options_budget_check:
    test rdi, rdi
    jz .runtime_budget_invalid
    test rsi, rsi
    jz .runtime_budget_invalid
    mov rax, [rdi + NEBOC_BUDGET_OPTIONS_OFFSET]
    cmp rax, NEBOC_MAX_CONSOLE_OPTIONS
    ja .runtime_budget_options
    mov rcx, [rdi + NEBOC_BUDGET_ARGUMENTS_OFFSET]
    cmp rcx, NEBOC_MAX_OPTION_ARGUMENTS
    ja .runtime_budget_arguments
    mov rdx, [rdi + NEBOC_BUDGET_DEPTH_OFFSET]
    cmp rdx, NEBOC_MAX_NESTED_CALL_DEPTH
    ja .runtime_budget_depth
    mov r8, [rdi + NEBOC_BUDGET_NODES_OFFSET]
    cmp r8, NEBOC_MAX_OPTION_AST_NODES
    ja .runtime_budget_nodes
    mov r9, [rdi + NEBOC_BUDGET_STEPS_OFFSET]
    cmp r9, NEBOC_MAX_OPTION_BUILD_STEPS
    ja .runtime_budget_steps
    mov [rsi + NEBOC_BUDGET_OPTIONS_OFFSET], rax
    mov [rsi + NEBOC_BUDGET_ARGUMENTS_OFFSET], rcx
    mov [rsi + NEBOC_BUDGET_DEPTH_OFFSET], rdx
    mov [rsi + NEBOC_BUDGET_NODES_OFFSET], r8
    mov [rsi + NEBOC_BUDGET_STEPS_OFFSET], r9
    xor eax, eax
    ret
.runtime_budget_options:
    mov eax, NEBO_OPTIONS_BUDGET_OPTIONS
    ret
.runtime_budget_arguments:
    mov eax, NEBO_OPTIONS_BUDGET_ARGUMENTS
    ret
.runtime_budget_depth:
    mov eax, NEBO_OPTIONS_BUDGET_DEPTH
    ret
.runtime_budget_nodes:
    mov eax, NEBO_OPTIONS_BUDGET_NODES
    ret
.runtime_budget_steps:
    mov eax, NEBO_OPTIONS_BUDGET_STEPS
    ret
.runtime_budget_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
