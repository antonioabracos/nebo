; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-PF001 bounded pure visual summary authority
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/visual_summary_foundation.inc"
section .text
NEBOC_ABI_FUNCTION neboc_visual_summary_init
 test rdi,rdi
 jz .bad_transvalue
 test rdi,neboc_console_visual_dashboard_e_plots_ALIGNMENT-1
 jnz .bad_transvalue
 cmp rsi,NEBOC_OP_SUMMARIZE
 jne .bad_source
 cmp rdx,255
 ja .bad_source
 test rcx,rcx
 jz .bad_source
 cmp rcx,3
 ja .bad_source
 test r8,r8
 jz .bad_source
 cmp r9,neboc_console_visual_dashboard_e_plots_REQUIRED_FLAGS
 jne .bad_source
 cmp qword [rdi+neboc_console_visual_dashboard_e_plots_MAGIC_OFFSET],0
 jne .bad_source
 push r12
 mov r12,rdi
 mov rax,neboc_console_visual_dashboard_e_plots_MAGIC
 mov [r12+neboc_console_visual_dashboard_e_plots_MAGIC_OFFSET],rax
 mov [r12+neboc_console_visual_dashboard_e_plots_OPERATION_OFFSET],rsi
 mov [r12+neboc_console_visual_dashboard_e_plots_VALUE_OFFSET],rdx
 mov [r12+neboc_console_visual_dashboard_e_plots_DIGIT_COUNT_OFFSET],rcx
 mov [r12+neboc_console_visual_dashboard_e_plots_LITERAL_HASH_OFFSET],r8
 mov [r12+neboc_console_visual_dashboard_e_plots_FLAGS_OFFSET],r9
 mov qword [r12+neboc_console_visual_dashboard_e_plots_INITIALIZED_OFFSET],1
 mov qword [r12+neboc_console_visual_dashboard_e_plots_IMMUTABLE_RESERVED_OFFSET],0
 mov qword [r12+neboc_console_visual_dashboard_e_plots_RESULT_OFFSET],0
 mov qword [r12+neboc_console_visual_dashboard_e_plots_DECISION_OFFSET],neboc_console_visual_dashboard_e_plots_DECISION_PERMIT
 mov qword [r12+neboc_console_visual_dashboard_e_plots_DIAGNOSTIC_OFFSET],0
 mov qword [r12+neboc_console_visual_dashboard_e_plots_EVALUATION_COUNT_OFFSET],0
 mov qword [r12+neboc_console_visual_dashboard_e_plots_RESERVED0_OFFSET],0
 mov qword [r12+neboc_console_visual_dashboard_e_plots_RESERVED1_OFFSET],0
 mov qword [r12+neboc_console_visual_dashboard_e_plots_RESERVED2_OFFSET],0
 call console_visual_dashboard_e_plots_hash
 mov [r12+neboc_console_visual_dashboard_e_plots_STATE_HASH_OFFSET],rax
 xor eax,eax
 pop r12
 ret
.bad_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.bad_transvalue:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
NEBOC_ABI_FUNCTION neboc_visual_summary_evaluate
 test rdi,rdi
 jz .transvalue
 test rdi,neboc_console_visual_dashboard_e_plots_ALIGNMENT-1
 jnz .transvalue
 push r12
 mov r12,rdi
 mov rax,neboc_console_visual_dashboard_e_plots_MAGIC
 cmp [r12+neboc_console_visual_dashboard_e_plots_MAGIC_OFFSET],rax
 jne .type
 cmp qword [r12+neboc_console_visual_dashboard_e_plots_INITIALIZED_OFFSET],1
 jne .type
 call console_visual_dashboard_e_plots_hash
 cmp rax,[r12+neboc_console_visual_dashboard_e_plots_STATE_HASH_OFFSET]
 jne .security
 cmp qword [r12+neboc_console_visual_dashboard_e_plots_OPERATION_OFFSET],NEBOC_OP_SUMMARIZE
 jne .type
 mov rax,[r12+neboc_console_visual_dashboard_e_plots_VALUE_OFFSET]
 mov [r12+neboc_console_visual_dashboard_e_plots_RESULT_OFFSET],rax
 mov qword [r12+neboc_console_visual_dashboard_e_plots_DECISION_OFFSET],neboc_console_visual_dashboard_e_plots_DECISION_PERMIT
 mov qword [r12+neboc_console_visual_dashboard_e_plots_DIAGNOSTIC_OFFSET],0
 inc qword [r12+neboc_console_visual_dashboard_e_plots_EVALUATION_COUNT_OFFSET]
 xor eax,eax
 pop r12
 ret
.type:
 mov eax,neboc_console_visual_dashboard_e_plots_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .deny
.security:
 mov eax,neboc_console_visual_dashboard_e_plots_DIAG_SECURITY_codegen_stdlib_x86_64
.deny:
 mov qword [r12+neboc_console_visual_dashboard_e_plots_DECISION_OFFSET],neboc_console_visual_dashboard_e_plots_DECISION_DENY
 mov [r12+neboc_console_visual_dashboard_e_plots_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop r12
 ret
.transvalue:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
console_visual_dashboard_e_plots_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ecx,ecx
.loop:
 cmp rcx,neboc_console_visual_dashboard_e_plots_HASHED_BYTES
 jae .done
 movzx edx,byte [r12+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .loop
.done:
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
