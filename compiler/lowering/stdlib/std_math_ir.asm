; BIBLIOTECA-PADRAO-POR-DOMINIOS-PF003 authenticated target-neutral pure std.math IR
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/stdlib/std_math_ir.inc"
section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_std_math_ir_lower
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,rdi
    or rax,rsi
    test rax,7
    jnz .invalid
    push rbx
    push r12
    mov rbx,rdi
    mov r12,rsi
    mov rdi,r12
    mov ecx,neboc_biblioteca_padrao_por_dominios_IR_QWORDS
    xor eax,eax
    rep stosq
    mov rax,neboc_biblioteca_padrao_por_dominios_SEM_MAGIC
    cmp [rbx+neboc_biblioteca_padrao_por_dominios_SEM_MAGIC_OFFSET],rax
    jne .fail
    cmp qword [rbx+neboc_biblioteca_padrao_por_dominios_SEM_DECISION_OFFSET],neboc_biblioteca_padrao_por_dominios_SEM_DECISION_PERMIT
    jne .fail
    cmp qword [rbx+neboc_biblioteca_padrao_por_dominios_SEM_FLAGS_OFFSET],neboc_biblioteca_padrao_por_dominios_SEM_REQUIRED_FLAGS
    jne .fail
    mov rsi,rbx
    mov ecx,neboc_biblioteca_padrao_por_dominios_SEM_HASHED_BYTES
    call biblioteca_padrao_por_dominios_ir_hash
    cmp rax,[rbx+neboc_biblioteca_padrao_por_dominios_SEM_HASH_OFFSET]
    jne .fail
    mov rax,neboc_biblioteca_padrao_por_dominios_IR_MAGIC
    mov [r12+neboc_biblioteca_padrao_por_dominios_IR_MAGIC_OFFSET],rax
%macro COPY 2
    mov rax,[rbx+%1]
    mov [r12+%2],rax
%endmacro
    COPY neboc_biblioteca_padrao_por_dominios_SEM_OPERATION_OFFSET,neboc_biblioteca_padrao_por_dominios_IR_OPERATION_OFFSET
    COPY neboc_biblioteca_padrao_por_dominios_SEM_ARITY_OFFSET,neboc_biblioteca_padrao_por_dominios_IR_ARITY_OFFSET
    COPY neboc_biblioteca_padrao_por_dominios_SEM_VALUE_OFFSET,neboc_biblioteca_padrao_por_dominios_IR_VALUE_OFFSET
    COPY NEBOC_SEM_LOWER_OFFSET,NEBOC_IR_LOWER_OFFSET
    COPY NEBOC_SEM_UPPER_OFFSET,NEBOC_IR_UPPER_OFFSET
    COPY neboc_biblioteca_padrao_por_dominios_SEM_RESULT_TYPE_OFFSET,neboc_biblioteca_padrao_por_dominios_IR_RESULT_TYPE_OFFSET
    COPY neboc_biblioteca_padrao_por_dominios_SEM_EFFECT_OFFSET,neboc_biblioteca_padrao_por_dominios_IR_EFFECT_OFFSET
    COPY neboc_biblioteca_padrao_por_dominios_SEM_SYNTAX_HASH_OFFSET,neboc_biblioteca_padrao_por_dominios_IR_SYNTAX_HASH_OFFSET
    COPY neboc_biblioteca_padrao_por_dominios_SEM_AUTHORITY_HASH_OFFSET,neboc_biblioteca_padrao_por_dominios_IR_AUTHORITY_HASH_OFFSET
    COPY neboc_biblioteca_padrao_por_dominios_SEM_HASH_OFFSET,neboc_biblioteca_padrao_por_dominios_IR_SEMANTIC_HASH_OFFSET
    mov qword [r12+neboc_biblioteca_padrao_por_dominios_IR_DECISION_OFFSET],neboc_biblioteca_padrao_por_dominios_SEM_DECISION_PERMIT
    mov qword [r12+neboc_biblioteca_padrao_por_dominios_IR_FLAGS_OFFSET],neboc_biblioteca_padrao_por_dominios_IR_REQUIRED_FLAGS
    mov rsi,r12
    mov ecx,neboc_biblioteca_padrao_por_dominios_IR_HASHED_BYTES
    call biblioteca_padrao_por_dominios_ir_hash
    mov [r12+neboc_biblioteca_padrao_por_dominios_IR_HASH_OFFSET],rax
    xor eax,eax
    pop r12
    pop rbx
    cld
    ret
.fail:
    mov qword [r12+neboc_biblioteca_padrao_por_dominios_IR_DIAGNOSTIC_OFFSET],neboc_biblioteca_padrao_por_dominios_DIAG_SECURITY_codegen_stdlib_x86_64
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%undef call
biblioteca_padrao_por_dominios_ir_hash:
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
