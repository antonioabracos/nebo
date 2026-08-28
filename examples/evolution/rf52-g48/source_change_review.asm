bits 64
default rel
%include "compiler/refactor/source_change_review.inc"
global _start
extern neboc_fix_plan_new,neboc_cli_fix_verify,neboc_cli_change_review
extern neboc_host_process_exit
section .data
source: db 'same'
backup: times 4 db 0
sources: dq 1,0x91,0x91,source,4,backup,4
source_set: dq sources,1
change:
 dq 0x99,0x99,plan,0,1,0,0
 dq 1,1,2,2,3,3
 dq NEBOC_HIR_EQUIVALENCE_REQUIRED,NEBOC_REFACTOR_API_COMPATIBLE
 dq 0,1,0,1,4,4,0,0,0,1
section .bss align=16
plan: resb NEBOC_FIX_PLAN_SIZE
edits: resb NEBOC_FIX_EDIT_SIZE
journal: resb NEBOC_FIX_JOURNAL_SIZE
report: resb NEBOC_REVIEW_SIZE
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
 lea rdi,[rel change]
 mov esi,NEBOC_VERIFY_LEVEL_DIFFERENTIAL
 call neboc_cli_fix_verify
 test eax,eax
 jnz .done
 lea rdi,[rel change]
 lea rsi,[rel report]
 call neboc_cli_change_review
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
