; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-PF004 bounded single-use pure offline visual-summary runtime
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/stdlib/visual_summary_runtime.inc"
section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_visual_summary_runtime_execute
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
    cmp qword [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_MAGIC_OFFSET],0
    jne .replay
    mov rax,neboc_console_visual_dashboard_e_plots_NATIVE_MAGIC
    cmp [rbx+neboc_console_visual_dashboard_e_plots_NATIVE_MAGIC_OFFSET],rax
    jne .security
    cmp qword [rbx+neboc_console_visual_dashboard_e_plots_NATIVE_TARGET_OFFSET],neboc_console_visual_dashboard_e_plots_NATIVE_TARGET_X86_64_SYSV_ELF
    jne .security
    cmp qword [rbx+neboc_console_visual_dashboard_e_plots_NATIVE_ABI_OFFSET],neboc_console_visual_dashboard_e_plots_NATIVE_ABI_INTERNAL_V1
    jne .security
    mov rsi,rbx
    mov ecx,neboc_console_visual_dashboard_e_plots_NATIVE_HASHED_BYTES
    call console_visual_dashboard_e_plots_runtime_hash
    cmp rax,[rbx+neboc_console_visual_dashboard_e_plots_NATIVE_HASH_OFFSET]
    jne .security
    test qword [rbx+neboc_console_visual_dashboard_e_plots_NATIVE_FLAGS_OFFSET],NEBOC_NATIVE_FLAG_INVALID_VALUE
    jnz .domain
    mov rax,neboc_console_visual_dashboard_e_plots_RUNTIME_MAGIC
    mov [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_MAGIC_OFFSET],rax
    mov rax,[rbx+neboc_console_visual_dashboard_e_plots_NATIVE_HASH_OFFSET]
    mov [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_PLAN_HASH_OFFSET],rax
    mov rax,[rbx+neboc_console_visual_dashboard_e_plots_NATIVE_RESULT_OFFSET]
    mov [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_RESULT_OFFSET],rax
    mov rax,[rbx+neboc_console_visual_dashboard_e_plots_NATIVE_OPERATION_OFFSET]
    mov [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_OPERATION_OFFSET],rax
    mov qword [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_GENERATION_OFFSET],1
    mov qword [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_CONSUMED_OFFSET],1
    mov rsi,r12
    mov ecx,neboc_console_visual_dashboard_e_plots_RUNTIME_HASHED_BYTES
    call console_visual_dashboard_e_plots_runtime_hash
    mov [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_HASH_OFFSET],rax
    xor eax,eax
    jmp .done
.domain:
    mov qword [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_DIAGNOSTIC_OFFSET],neboc_console_visual_dashboard_e_plots_DIAG_RUNTIME_driver_cli_linux_x86_64
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    jmp .done
.replay:
    mov qword [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_DIAGNOSTIC_OFFSET],neboc_console_visual_dashboard_e_plots_DIAG_RUNTIME_driver_cli_linux_x86_64
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    jmp .done
.security:
    mov qword [r12+neboc_console_visual_dashboard_e_plots_RUNTIME_DIAGNOSTIC_OFFSET],neboc_console_visual_dashboard_e_plots_DIAG_SECURITY_codegen_stdlib_x86_64
    mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%undef call
console_visual_dashboard_e_plots_runtime_hash:
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
