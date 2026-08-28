; SEMANTIC-REFACTOR-F07 write-free semantic rename preview.
bits 64
default rel

%include "compiler/refactor/semantic_refactor.inc"

global _start
extern neboc_fix_plan_new,neboc_fix_plan_add,neboc_fix_plan_order_canonical
extern neboc_refactor_rename,neboc_refactor_affected_files
extern neboc_refactor_public_api_impact,neboc_cli_refactor
extern neboc_host_process_exit

section .data
source: db 'old'
backup: times 3 db 0
replacement: db 'new'
sources: dq 7,0x7007,0x7007,source,3,backup,3
source_set: dq sources,1
edit: dq 7,0,3,replacement,3,0x7007,NEBOC_FIXIT_MACHINE_APPLICABLE
affected: dq 7
request:
 dq 0,0x7001,0x7002,0x7003,0x7003
 dq NEBOC_REFACTOR_PROOF_ALL,plan,affected,1
 dq NEBOC_REFACTOR_API_COMPATIBLE,0,0,0,0

section .bss align=16
plan: resb NEBOC_FIX_PLAN_SIZE
edits: resb NEBOC_FIX_EDIT_SIZE
journal: resb NEBOC_FIX_JOURNAL_SIZE
preview: resb NEBOC_FIX_PREVIEW_SIZE
preview_edit: resb NEBOC_FIX_EDIT_SIZE
file_result: resb NEBOC_REFACTOR_FILES_SIZE
file_output: resq 1
impact: resq 1

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
 jnz .done
 lea rdi,[rel plan]
 lea rsi,[rel edit]
 call neboc_fix_plan_add
 test eax,eax
 jnz .done
 lea rdi,[rel plan]
 call neboc_fix_plan_order_canonical
 test eax,eax
 jnz .done
 lea rdi,[rel request]
 call neboc_refactor_rename
 test eax,eax
 jnz .done
 lea rax,[rel file_output]
 mov [rel file_result+NEBOC_REFACTOR_FILES_ITEMS_OFFSET],rax
 mov qword [rel file_result+NEBOC_REFACTOR_FILES_CAPACITY_OFFSET],1
 lea rdi,[rel request]
 lea rsi,[rel file_result]
 call neboc_refactor_affected_files
 test eax,eax
 jnz .done
 lea rdi,[rel request]
 lea rsi,[rel impact]
 call neboc_refactor_public_api_impact
 test eax,eax
 jnz .done
 lea rax,[rel preview_edit]
 mov [rel preview+NEBOC_FIX_PREVIEW_EDITS_OFFSET],rax
 mov qword [rel preview+NEBOC_FIX_PREVIEW_CAPACITY_OFFSET],1
 lea rdi,[rel request]
 mov esi,NEBOC_REFACTOR_CLI_PREVIEW
 lea rdx,[rel preview]
 xor ecx,ecx
 xor r8d,r8d
 call neboc_cli_refactor
.done:
 mov edi,eax
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
