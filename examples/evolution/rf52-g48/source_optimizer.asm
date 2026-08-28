bits 64
default rel
%include "compiler/refactor/source_optimizer.inc"
global _start
extern neboc_fix_plan_new,neboc_source_optimizer_new
extern neboc_source_optimizer_simplify_constants,neboc_cli_source_optimize
extern neboc_host_process_exit
section .data
source: db '1+1'
backup: times 3 db 0
replacement: db '2  '
sources: dq 1,0x88,0x88,source,3,backup,3
source_set: dq sources,1
edit: dq 1,0,3,replacement,3,0x88,NEBOC_FIXIT_MACHINE_APPLICABLE
candidate: dq NEBOC_SOURCE_PASS_CONSTANTS,1,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_DIAGNOSTICS),edit,1
config: dq NEBOC_SOURCE_PROFILE_V1,1,0x99,0x99,0,plan,candidate,1,1,2,1,NEBOC_SOURCE_COMMENT_PRESERVE
section .bss align=16
plan: resb NEBOC_FIX_PLAN_SIZE
edits: resb NEBOC_FIX_EDIT_SIZE
journal: resb NEBOC_FIX_JOURNAL_SIZE
optimizer: resb NEBOC_SOURCE_OPT_SIZE
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
 jnz .done
 lea rdi,[rel optimizer]
 lea rsi,[rel config]
 call neboc_source_optimizer_new
 test eax,eax
 jnz .done
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_simplify_constants
 test eax,eax
 jnz .done
 lea rax,[rel preview_edit]
 mov [rel preview+NEBOC_FIX_PREVIEW_EDITS_OFFSET],rax
 mov qword [rel preview+NEBOC_FIX_PREVIEW_CAPACITY_OFFSET],1
 lea rdi,[rel optimizer]
 mov esi,NEBOC_SOURCE_CLI_PREVIEW
 lea rdx,[rel preview]
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call neboc_cli_source_optimize
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
