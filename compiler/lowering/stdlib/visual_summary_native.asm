; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-PF004 authenticated x86_64 pure offline visual-summary plan
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/stdlib/visual_summary_native.inc"
section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_visual_summary_native_lower
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
    mov ecx,neboc_console_visual_dashboard_e_plots_NATIVE_QWORDS
    xor eax,eax
    rep stosq
    mov rax,neboc_console_visual_dashboard_e_plots_IR_MAGIC
    cmp [rbx+neboc_console_visual_dashboard_e_plots_IR_MAGIC_OFFSET],rax
    jne .fail
    cmp qword [rbx+neboc_console_visual_dashboard_e_plots_IR_TARGET_OFFSET],0
    jne .fail
    cmp qword [rbx+neboc_console_visual_dashboard_e_plots_IR_FLAGS_OFFSET],neboc_console_visual_dashboard_e_plots_IR_REQUIRED_FLAGS
    jne .fail
    mov rsi,rbx
    mov ecx,neboc_console_visual_dashboard_e_plots_IR_HASHED_BYTES
    call console_visual_dashboard_e_plots_native_hash
    cmp rax,[rbx+neboc_console_visual_dashboard_e_plots_IR_HASH_OFFSET]
    jne .fail
    mov rax,neboc_console_visual_dashboard_e_plots_NATIVE_MAGIC
    mov [r12+neboc_console_visual_dashboard_e_plots_NATIVE_MAGIC_OFFSET],rax
%macro COPY 2
    mov rax,[rbx+%1]
    mov [r12+%2],rax
%endmacro
    COPY neboc_console_visual_dashboard_e_plots_IR_OPERATION_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_OPERATION_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_ARITY_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_ARITY_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_VALUE_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_VALUE_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_DIGIT_COUNT_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_DIGIT_COUNT_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_LITERAL_HASH_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_LITERAL_HASH_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_RESULT_TYPE_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_RESULT_TYPE_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_EFFECT_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_EFFECT_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_SYNTAX_HASH_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_SYNTAX_HASH_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_AUTHORITY_HASH_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_AUTHORITY_HASH_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_SEMANTIC_HASH_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_SEMANTIC_HASH_OFFSET
    COPY neboc_console_visual_dashboard_e_plots_IR_HASH_OFFSET,neboc_console_visual_dashboard_e_plots_NATIVE_IR_HASH_OFFSET
    mov qword [r12+neboc_console_visual_dashboard_e_plots_NATIVE_TARGET_OFFSET],neboc_console_visual_dashboard_e_plots_NATIVE_TARGET_X86_64_SYSV_ELF
    mov qword [r12+neboc_console_visual_dashboard_e_plots_NATIVE_ABI_OFFSET],neboc_console_visual_dashboard_e_plots_NATIVE_ABI_INTERNAL_V1
    mov qword [r12+neboc_console_visual_dashboard_e_plots_NATIVE_DECISION_OFFSET],neboc_console_visual_dashboard_e_plots_SEM_DECISION_PERMIT
    mov qword [r12+neboc_console_visual_dashboard_e_plots_NATIVE_FLAGS_OFFSET],neboc_console_visual_dashboard_e_plots_NATIVE_REQUIRED_FLAGS
    cmp qword [rbx+neboc_console_visual_dashboard_e_plots_IR_OPERATION_OFFSET],NEBOC_OP_SUMMARIZE
    jne .fail
    mov rax,[rbx+neboc_console_visual_dashboard_e_plots_IR_VALUE_OFFSET]
    mov [r12+neboc_console_visual_dashboard_e_plots_NATIVE_RESULT_OFFSET],rax
    mov rsi,r12
    mov ecx,neboc_console_visual_dashboard_e_plots_NATIVE_HASHED_BYTES
    call console_visual_dashboard_e_plots_native_hash
    mov [r12+neboc_console_visual_dashboard_e_plots_NATIVE_HASH_OFFSET],rax
    xor eax,eax
    pop r12
    pop rbx
    cld
    ret
.fail:
    mov qword [r12+neboc_console_visual_dashboard_e_plots_NATIVE_DIAGNOSTIC_OFFSET],neboc_console_visual_dashboard_e_plots_DIAG_CODEGEN_codegen_stdlib_x86_64
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%undef call
console_visual_dashboard_e_plots_native_hash:
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
