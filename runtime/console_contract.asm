; G089 composed internal ABI for schema, model, limits, conflicts and atomic
; normalized publication. It delegates to the single registry/normalizer.
bits 64
default rel
%include "runtime/console_contract.inc"
%include "compiler/parser/console_arguments.inc"
%include "runtime/console_options.inc"
%include "runtime/console_option_registry.inc"
extern nebo_option_registry_validate_names
extern nebo_option_registry_lookup
extern nebo_console_options_normalize
global nebo_console_options_validate

%define G89_VALIDATE_NORMALIZE_OFFSET 0
%define G89_VALIDATE_LOOKUP_OFFSET 48
%define G89_VALIDATE_INDEX_OFFSET 56
%define G89_VALIDATE_STACK_SIZE 64

section .text
; rdi=validation request. The caller-owned normalized destination and receipt
; remain untouched until every schema, kind, bound and conflict is accepted.
nebo_console_options_validate:
    test rdi, rdi
    jz .invalid_direct
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, G89_VALIDATE_STACK_SIZE
    mov rbx, rdi
    mov r12, [rbx + NEBO_CONSOLE_VALIDATE_MODEL_OFFSET]
    mov r13, [rbx + NEBO_CONSOLE_VALIDATE_REGISTRY_OFFSET]
    mov r14, [rbx + NEBO_CONSOLE_VALIDATE_REGISTRY_COUNT_OFFSET]
    test r12, r12
    jz .invalid
    test r13, r13
    jz .invalid
    cmp qword [r12 + NEBO_CONSOLE_OPTIONS_STATE_OFFSET], NEBO_CONSOLE_OPTIONS_READY
    jne .invalid
    mov r15, [r12 + NEBO_CONSOLE_OPTIONS_COUNT_OFFSET]
    cmp r15, NEBOC_MAX_CONSOLE_OPTIONS
    ja .budget
    cmp r15, [r12 + NEBO_CONSOLE_OPTIONS_CAPACITY_OFFSET]
    ja .capacity
    test r15, r15
    jz .registry
    cmp qword [r12 + NEBO_CONSOLE_OPTIONS_VALUES_OFFSET], 0
    je .invalid
.registry:
    mov rdi, r13
    mov rsi, r14
    call nebo_option_registry_validate_names
    test eax, eax
    jnz .done
    xor r10d, r10d
.kind_loop:
    cmp r10, r15
    jae .normalize
    mov rax, r10
    imul rax, NEBO_OPTION_VALUE_SIZE
    add rax, [r12 + NEBO_CONSOLE_OPTIONS_VALUES_OFFSET]
    mov rdx, [rax + NEBO_OPTION_VALUE_KIND_OFFSET]
    mov rdi, r13
    mov rsi, r14
    lea rcx, [rsp + G89_VALIDATE_LOOKUP_OFFSET]
    mov [rsp + G89_VALIDATE_INDEX_OFFSET], r10
    call nebo_option_registry_lookup
    mov r10, [rsp + G89_VALIDATE_INDEX_OFFSET]
    test eax, eax
    jnz .done
    inc r10
    jmp .kind_loop
.normalize:
    mov rax, [r12 + NEBO_CONSOLE_OPTIONS_VALUES_OFFSET]
    mov [rsp + G89_VALIDATE_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_VALUES_OFFSET], rax
    mov [rsp + G89_VALIDATE_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_COUNT_OFFSET], r15
    mov rax, [rbx + NEBO_CONSOLE_VALIDATE_SCRATCH_OFFSET]
    mov [rsp + G89_VALIDATE_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_DESTINATION_OFFSET], rax
    mov rax, [rbx + NEBO_CONSOLE_VALIDATE_SCRATCH_CAPACITY_OFFSET]
    mov [rsp + G89_VALIDATE_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_CAPACITY_OFFSET], rax
    mov rax, [rbx + NEBO_CONSOLE_VALIDATE_RECEIPT_OFFSET]
    mov [rsp + G89_VALIDATE_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_RECEIPT_OFFSET], rax
    lea rdi, [rsp + G89_VALIDATE_NORMALIZE_OFFSET]
    call nebo_console_options_normalize
    jmp .done
.capacity:
    mov eax, NEBO_OPTIONS_CAPACITY
    jmp .done
.budget:
    mov eax, NEBO_OPTIONS_BUDGET
    jmp .done
.invalid:
    mov eax, NEBO_OPTIONS_INVALID
.done:
    add rsp, G89_VALIDATE_STACK_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.invalid_direct:
    mov eax, NEBO_OPTIONS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
