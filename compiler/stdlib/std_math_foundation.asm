; Nebo Assembly — BIBLIOTECA-PADRAO-POR-DOMINIOS-PF001 bounded pure std.math authority
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/std_math_foundation.inc"

section .text

; std_math_init(record*, operation, value, lower_or_rhs, upper, flags)
NEBOC_ABI_FUNCTION neboc_std_math_init
    test rdi, rdi
    jz .bad_transport
    test rdi, neboc_biblioteca_padrao_por_dominios_ALIGNMENT - 1
    jnz .bad_transport
    cmp rsi, NEBOC_OP_ABS
    jb .bad_source
    cmp rsi, NEBOC_OP_MAX
    ja .bad_source
    cmp r9, neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
    jne .bad_source
    cmp qword [rdi + neboc_biblioteca_padrao_por_dominios_MAGIC_OFFSET], 0
    jne .bad_source
    cmp rsi, NEBOC_OP_CLAMP
    je .validate_clamp
    test r8, r8
    jnz .bad_source
    cmp rsi, NEBOC_OP_ABS
    jne .store
    test rcx, rcx
    jnz .bad_source
    jmp .store
.validate_clamp:
    cmp rcx, r8
    jg .bad_source
.store:
    push r12
    mov r12, rdi
    mov rax, neboc_biblioteca_padrao_por_dominios_MAGIC
    mov [r12 + neboc_biblioteca_padrao_por_dominios_MAGIC_OFFSET], rax
    mov [r12 + neboc_biblioteca_padrao_por_dominios_OPERATION_OFFSET], rsi
    mov [r12 + neboc_biblioteca_padrao_por_dominios_VALUE_OFFSET], rdx
    mov [r12 + NEBOC_LOWER_OFFSET], rcx
    mov [r12 + NEBOC_UPPER_OFFSET], r8
    mov [r12 + neboc_biblioteca_padrao_por_dominios_FLAGS_OFFSET], r9
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_INITIALIZED_OFFSET], 1
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_IMMUTABLE_RESERVED_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_RESULT_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_DECISION_OFFSET], neboc_biblioteca_padrao_por_dominios_DECISION_PERMIT
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_EVALUATION_COUNT_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_RESERVED0_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_RESERVED1_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_RESERVED2_OFFSET], 0
    call hash_math_identity
    mov [r12 + neboc_biblioteca_padrao_por_dominios_STATE_HASH_OFFSET], rax
    xor eax, eax
    pop r12
    cld
    ret
.bad_source:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    cld
    ret
.bad_transport:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; std_math_evaluate(record*) writes the signed Int result into the record.
NEBOC_ABI_FUNCTION neboc_std_math_evaluate
    test rdi, rdi
    jz .eval_bad_transport
    test rdi, neboc_biblioteca_padrao_por_dominios_ALIGNMENT - 1
    jnz .eval_bad_transport
    push r12
    mov r12, rdi
    mov rax, neboc_biblioteca_padrao_por_dominios_MAGIC
    cmp [r12 + neboc_biblioteca_padrao_por_dominios_MAGIC_OFFSET], rax
    jne .eval_type
    cmp qword [r12 + neboc_biblioteca_padrao_por_dominios_INITIALIZED_OFFSET], 1
    jne .eval_type
    call hash_math_identity
    cmp rax, [r12 + neboc_biblioteca_padrao_por_dominios_STATE_HASH_OFFSET]
    jne .eval_security
    cmp qword [r12 + neboc_biblioteca_padrao_por_dominios_FLAGS_OFFSET], neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
    jne .eval_security
    mov rax, [r12 + neboc_biblioteca_padrao_por_dominios_VALUE_OFFSET]
    mov rcx, [r12 + neboc_biblioteca_padrao_por_dominios_OPERATION_OFFSET]
    cmp rcx, NEBOC_OP_ABS
    je .abs
    cmp rcx, NEBOC_OP_CLAMP
    je .clamp
    cmp rcx, NEBOC_OP_MIN
    je .min
    cmp rcx, NEBOC_OP_MAX
    je .max
    jmp .eval_type
.abs:
    test rax, rax
    jns .success
    mov rdx, 0x8000000000000000
    cmp rax, rdx
    je .eval_runtime
    neg rax
    jmp .success
.clamp:
    cmp rax, [r12 + NEBOC_LOWER_OFFSET]
    jl .use_lower
    cmp rax, [r12 + NEBOC_UPPER_OFFSET]
    jg .use_upper
    jmp .success
.use_lower:
    mov rax, [r12 + NEBOC_LOWER_OFFSET]
    jmp .success
.use_upper:
    mov rax, [r12 + NEBOC_UPPER_OFFSET]
    jmp .success
.min:
    cmp rax, [r12 + NEBOC_LOWER_OFFSET]
    jle .success
    mov rax, [r12 + NEBOC_LOWER_OFFSET]
    jmp .success
.max:
    cmp rax, [r12 + NEBOC_LOWER_OFFSET]
    jge .success
    mov rax, [r12 + NEBOC_LOWER_OFFSET]
.success:
    mov [r12 + neboc_biblioteca_padrao_por_dominios_RESULT_OFFSET], rax
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_DECISION_OFFSET], neboc_biblioteca_padrao_por_dominios_DECISION_PERMIT
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_DIAGNOSTIC_OFFSET], 0
    inc qword [r12 + neboc_biblioteca_padrao_por_dominios_EVALUATION_COUNT_OFFSET]
    xor eax, eax
    pop r12
    cld
    ret
.eval_type:
    mov eax, neboc_biblioteca_padrao_por_dominios_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .deny
.eval_runtime:
    mov eax, neboc_biblioteca_padrao_por_dominios_DIAG_RUNTIME_driver_cli_linux_x86_64
    jmp .deny
.eval_security:
    mov eax, neboc_biblioteca_padrao_por_dominios_DIAG_SECURITY_codegen_stdlib_x86_64
.deny:
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_DECISION_OFFSET], neboc_biblioteca_padrao_por_dominios_DECISION_DENY
    mov [r12 + neboc_biblioteca_padrao_por_dominios_DIAGNOSTIC_OFFSET], rax
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    pop r12
    cld
    ret
.eval_bad_transport:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

hash_math_identity:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.hash_loop:
    cmp rcx, neboc_biblioteca_padrao_por_dominios_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
