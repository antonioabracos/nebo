bits 64
default rel
%include "compiler/refactor/fix_plan.inc"
global _start
extern neboc_fix_plan_new,neboc_fix_plan_add,neboc_fix_plan_order_canonical
extern neboc_cli_fix_preview,neboc_host_process_exit
section .data
bytes: db 'code'
backup: times 4 db 0
replacement: db 'C'
source: dq 1,0x100,0x100,bytes,4,backup,4
source_set: dq source,1
edit: dq 1,0,1,replacement,1,0x100,NEBOC_FIXIT_MACHINE_APPLICABLE
section .bss align=16
plan: resb NEBOC_FIX_PLAN_SIZE
edits: resb NEBOC_FIX_EDIT_SIZE
journal: resb NEBOC_FIX_JOURNAL_SIZE
preview: resb NEBOC_FIX_PREVIEW_SIZE
preview_edit: resb NEBOC_FIX_EDIT_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel plan]
 lea rsi,[rel source_set]
 lea rdx,[rel edits]
 mov ecx,1
 lea r8,[rel journal]
 mov r9d,1
 call neboc_fix_plan_new
 test eax,eax
 jne .done
 lea rdi,[rel plan]
 lea rsi,[rel edit]
 call neboc_fix_plan_add
 test eax,eax
 jne .done
 lea rdi,[rel plan]
 call neboc_fix_plan_order_canonical
 test eax,eax
 jne .done
 lea rax,[rel preview_edit]
 mov [rel preview+NEBOC_FIX_PREVIEW_EDITS_OFFSET],rax
 mov qword [rel preview+NEBOC_FIX_PREVIEW_CAPACITY_OFFSET],1
 lea rdi,[rel plan]
 lea rsi,[rel preview]
 call neboc_cli_fix_preview
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
