; BIBLIOTECA-PADRAO-POR-DOMINIOS-PF003 authenticated pure std.math semantic model
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/stdlib/std_math_semantic.inc"
section .text
; semantic_build(syntax*, authority*, out*)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_std_math_semantic_build
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    mov rax,rdi
    or rax,rsi
    or rax,rdx
    test rax,7
    jnz .invalid
    push rbx
    push r12
    push r13
    push r14
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov rdi,r13
    mov ecx,neboc_biblioteca_padrao_por_dominios_SEM_QWORDS
    xor eax,eax
    rep stosq
    cmp qword [rbx+neboc_biblioteca_padrao_por_dominios_SYNTAX_FLAGS_OFFSET],neboc_biblioteca_padrao_por_dominios_SYNTAX_REQUIRED_FLAGS
    jne .type
    mov rsi,rbx
    mov ecx,neboc_biblioteca_padrao_por_dominios_SYNTAX_HASHED_BYTES
    call biblioteca_padrao_por_dominios_sem_hash
    cmp rax,[rbx+neboc_biblioteca_padrao_por_dominios_SYNTAX_SHAPE_HASH_OFFSET]
    jne .security
    mov rax,neboc_biblioteca_padrao_por_dominios_MAGIC
    cmp [r12+neboc_biblioteca_padrao_por_dominios_MAGIC_OFFSET],rax
    jne .type
    cmp qword [r12+neboc_biblioteca_padrao_por_dominios_INITIALIZED_OFFSET],1
    jne .type
    mov rsi,r12
    mov ecx,neboc_biblioteca_padrao_por_dominios_HASHED_BYTES
    call biblioteca_padrao_por_dominios_sem_hash
    cmp rax,[r12+neboc_biblioteca_padrao_por_dominios_STATE_HASH_OFFSET]
    jne .security
    cmp qword [r12+neboc_biblioteca_padrao_por_dominios_FLAGS_OFFSET],neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
    jne .security
%macro MATCH_COPY 3
    mov rax,[rbx+%1]
    cmp rax,[r12+%2]
    jne .type
    mov [r13+%3],rax
%endmacro
    MATCH_COPY neboc_biblioteca_padrao_por_dominios_SYNTAX_OPERATION_OFFSET,neboc_biblioteca_padrao_por_dominios_OPERATION_OFFSET,neboc_biblioteca_padrao_por_dominios_SEM_OPERATION_OFFSET
    MATCH_COPY neboc_biblioteca_padrao_por_dominios_SYNTAX_VALUE_OFFSET,neboc_biblioteca_padrao_por_dominios_VALUE_OFFSET,neboc_biblioteca_padrao_por_dominios_SEM_VALUE_OFFSET
    MATCH_COPY NEBOC_SYNTAX_LOWER_OFFSET,NEBOC_LOWER_OFFSET,NEBOC_SEM_LOWER_OFFSET
    MATCH_COPY NEBOC_SYNTAX_UPPER_OFFSET,NEBOC_UPPER_OFFSET,NEBOC_SEM_UPPER_OFFSET
    mov rax,neboc_biblioteca_padrao_por_dominios_SEM_MAGIC
    mov [r13+neboc_biblioteca_padrao_por_dominios_SEM_MAGIC_OFFSET],rax
    mov rax,[rbx+neboc_biblioteca_padrao_por_dominios_SYNTAX_ARITY_OFFSET]
    mov [r13+neboc_biblioteca_padrao_por_dominios_SEM_ARITY_OFFSET],rax
    mov qword [r13+neboc_biblioteca_padrao_por_dominios_SEM_TYPE_OFFSET],neboc_biblioteca_padrao_por_dominios_SEM_TYPE_INT64
    mov qword [r13+neboc_biblioteca_padrao_por_dominios_SEM_EFFECT_OFFSET],neboc_biblioteca_padrao_por_dominios_SEM_EFFECT_PURE
    mov rax,[rbx+neboc_biblioteca_padrao_por_dominios_SYNTAX_SHAPE_HASH_OFFSET]
    mov [r13+neboc_biblioteca_padrao_por_dominios_SEM_SYNTAX_HASH_OFFSET],rax
    mov rax,[r12+neboc_biblioteca_padrao_por_dominios_STATE_HASH_OFFSET]
    mov [r13+neboc_biblioteca_padrao_por_dominios_SEM_AUTHORITY_HASH_OFFSET],rax
    mov qword [r13+neboc_biblioteca_padrao_por_dominios_SEM_RESULT_TYPE_OFFSET],neboc_biblioteca_padrao_por_dominios_SEM_TYPE_INT64
    mov qword [r13+neboc_biblioteca_padrao_por_dominios_SEM_DECISION_OFFSET],neboc_biblioteca_padrao_por_dominios_SEM_DECISION_PERMIT
    mov qword [r13+neboc_biblioteca_padrao_por_dominios_SEM_FLAGS_OFFSET],neboc_biblioteca_padrao_por_dominios_SEM_REQUIRED_FLAGS
    mov rsi,r13
    mov ecx,neboc_biblioteca_padrao_por_dominios_SEM_HASHED_BYTES
    call biblioteca_padrao_por_dominios_sem_hash
    mov [r13+neboc_biblioteca_padrao_por_dominios_SEM_HASH_OFFSET],rax
    xor eax,eax
    jmp .done
.type:
    mov r14d,neboc_biblioteca_padrao_por_dominios_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .fail
.security:
    mov r14d,neboc_biblioteca_padrao_por_dominios_DIAG_SECURITY_codegen_stdlib_x86_64
.fail:
    mov rdi,r13
    mov ecx,neboc_biblioteca_padrao_por_dominios_SEM_QWORDS
    xor eax,eax
    rep stosq
    mov [r13+neboc_biblioteca_padrao_por_dominios_SEM_DIAGNOSTIC_OFFSET],r14
    mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%undef call
biblioteca_padrao_por_dominios_sem_hash:
    mov rax,14695981039346656037
    mov r8,1099511628211
    xor edx,edx
.loop:
    cmp edx,ecx
    jae .done
    movzx r9d,byte [rsi+rdx]
    xor rax,r9
    imul rax,r8
    inc edx
    jmp .loop
.done:
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
