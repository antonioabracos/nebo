bits 64
default rel
%include "compiler/optimizer/ipo.inc"
global _start
extern neboc_ipo_context_new,neboc_ipo_inline_across_modules
extern neboc_ipo_propagate_constants,neboc_ipo_devirtualize_calls
extern neboc_ipo_escape_analysis,neboc_ipo_promote_allocation_to_stack
extern neboc_ipo_merge_equivalent_functions,neboc_ipo_remove_unused_parameters
extern neboc_ipo_tail_call_transform,neboc_ipo_specialize_by_capability
extern neboc_ipo_verify,neboc_ipo_report,neboc_host_process_exit
section .data
functions:
 dq 1,1,NEBOC_IPO_FLAG_INTERNAL|NEBOC_IPO_FLAG_NO_ESCAPE|NEBOC_IPO_FLAG_CLOSED_CALLS|NEBOC_IPO_FLAG_TAIL_SAFE,0,10,1,1,0,8,0xaa,3,2,7,0
 dq 2,2,NEBOC_IPO_FLAG_INTERNAL|NEBOC_IPO_FLAG_NO_ESCAPE|NEBOC_IPO_FLAG_CLOSED_CALLS|NEBOC_IPO_FLAG_TAIL_SAFE,0,8,0,2,0,4,0xbb,2,2,0,0
 dq 3,2,0,1,30,1,1,0,8,0xcc,2,1,0,0
 dq 4,3,NEBOC_IPO_FLAG_INTERNAL,0,8,0,2,0,0,0xbb,0,0,0,0
section .bss align=16
context: resb NEBOC_IPO_CONTEXT_SIZE
limits: resb NEBOC_IPO_LIMIT_SIZE
report: resb NEBOC_IPO_REPORT_SIZE
section .text
_start:
 sub rsp,8
 mov qword [rel limits],4
 mov qword [rel limits+8],20
 mov qword [rel limits+16],12
 mov qword [rel limits+24],16
 mov qword [rel limits+32],8
 lea rdi,[rel context]
 lea rsi,[rel functions]
 mov edx,4
 lea rcx,[rel limits]
 mov r8d,7
 call neboc_ipo_context_new
 test eax,eax
 jne .fail1
 lea rdi,[rel context]
 mov esi,1
 call neboc_ipo_inline_across_modules
 test eax,eax
 jne .fail2
 cmp qword [rel context+NEBOC_IPO_CONTEXT_GROWTH_OFFSET],13
 jne .fail3
 lea rdi,[rel context]
 call neboc_ipo_propagate_constants
 test eax,eax
 jne .fail4
 lea rdi,[rel context]
 call neboc_ipo_devirtualize_calls
 test eax,eax
 jne .fail5
 lea rdi,[rel context]
 call neboc_ipo_escape_analysis
 test eax,eax
 jne .fail6
 cmp qword [rel context+NEBOC_IPO_CONTEXT_ASSUMPTIONS_OFFSET],4
 jne .fail7
 lea rdi,[rel context]
 call neboc_ipo_promote_allocation_to_stack
 test eax,eax
 jne .fail8
 lea rdi,[rel context]
 call neboc_ipo_merge_equivalent_functions
 test eax,eax
 jne .fail9
 lea rdi,[rel context]
 call neboc_ipo_remove_unused_parameters
 test eax,eax
 jne .fail10
 lea rdi,[rel context]
 mov esi,1
 call neboc_ipo_tail_call_transform
 test eax,eax
 jne .fail11
 lea rdi,[rel context]
 call neboc_ipo_specialize_by_capability
 test eax,eax
 jne .fail12
 lea rdi,[rel context]
 mov esi,0x3ff
 mov edx,0xabc
 call neboc_ipo_verify
 test eax,eax
 jne .fail13
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_ipo_report
 test eax,eax
 jne .fail14
 cmp qword [rel report],13
 jne .fail15
 cmp qword [rel report+8],13
 jne .fail16
 cmp qword [rel report+16],21
 jne .fail17
 cmp qword [rel report+24],4
 jne .fail18
 cmp qword [rel report+32],1
 jne .fail19
 ; Public function 3 was never inlined or parameter-pruned.
 test qword [rel functions+NEBOC_IPO_FUNC_SIZE*2+NEBOC_IPO_FUNC_TRANSFORMS_OFFSET],1|64
 jnz .fail20
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 20
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
