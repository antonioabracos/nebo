bits 64
default rel
%include "compiler/stdlib/visual_summary_foundation.inc"
%include "runtime/core/runtime_core.inc"
global nebo_runtime_visual_summary
extern neboc_visual_summary_init
extern neboc_visual_summary_evaluate
extern nebo_runtime_trap
section .text
; Int -> existing pure summary profile, 0..255. No display or document effect
; is promised by this owner. Its canonical result is the input value.
nebo_runtime_visual_summary:
 push rbp
 mov rbp,rsp
 sub rsp,160
 mov [rsp+128],rdi
 cmp rdi,255
 ja .bad
 mov rdi,rsp
 xor eax,eax
 mov ecx,16
 rep stosq
 ; Derive the canonical decimal provenance from the actual runtime operand.
 mov rax,[rsp+128]
 lea r11,[rsp+152]
 xor ecx,ecx
 mov r10d,10
.digits:
 xor edx,edx
 div r10
 add dl,'0'
 dec r11
 mov [r11],dl
 inc ecx
 test rax,rax
 jnz .digits
 mov r8,14695981039346656037
 mov r9,1099511628211
 xor eax,eax
.hash:
 movzx edx,byte [r11+rax]
 xor r8,rdx
 imul r8,r9
 inc eax
 cmp eax,ecx
 jb .hash
 mov rdi,rsp
 mov esi,NEBOC_OP_SUMMARIZE
 mov rdx,[rsp+128]
 mov r9d,neboc_console_visual_dashboard_e_plots_REQUIRED_FLAGS
 call neboc_visual_summary_init
 test eax,eax
 jnz .bad
 mov rdi,rsp
 call neboc_visual_summary_evaluate
 test eax,eax
 jnz .bad
 cmp qword [rsp+neboc_console_visual_dashboard_e_plots_EVALUATION_COUNT_OFFSET],1
 jne .bad
 mov rax,[rsp+neboc_console_visual_dashboard_e_plots_RESULT_OFFSET]
 leave
 ret
.bad:
 leave
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap
section .note.GNU-stack noalloc noexec nowrite progbits
