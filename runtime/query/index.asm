; RF46-G32-F05 bounded sorted index and explainable planner.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/query/index.inc"
section .text
NEBOC_ABI_FUNCTION nebo_index_lookup
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test rsi,rsi
 jz .not_found
 cmp rsi,NEBO_INDEX_MAX_ENTRIES
 ja .limit
 xor r8d,r8d
 mov r9,rsi
.loop:
 cmp r8,r9
 jae .not_found
 mov rax,r8
 add rax,r9
 shr rax,1
 mov r10,rax
 shl r10,4
 mov r11,[rdi+r10]
 cmp rdx,r11
 je .found
 jb .lower
 lea r8,[rax+1]
 jmp .loop
.lower:
 mov r9,rax
 jmp .loop
.found:
 mov rax,[rdi+r10+8]
 mov [rcx],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBO_INDEX_INVALID
 ret
.limit: mov eax,NEBO_INDEX_LIMIT
 ret
.not_found: mov eax,NEBO_INDEX_NOT_FOUND
 ret

NEBOC_ABI_FUNCTION nebo_planner_choose
 ; rows,equality,index_valid,out_reason
 test rcx,rcx
 jz .invalid
 cmp rdi,NEBO_INDEX_MAX_ENTRIES
 ja .limit
 cmp rsi,1
 jne .scan
 cmp rdx,1
 jne .scan
 cmp rdi,8
 jb .scan
 mov qword [rcx],NEBO_PLAN_REASON_EQUALITY_INDEX
 mov eax,NEBO_PLAN_INDEX
 ret
.scan:
 mov qword [rcx],NEBO_PLAN_REASON_BOUNDED_SCAN
 mov eax,NEBO_PLAN_SCAN
 ret
.invalid: mov eax,NEBO_INDEX_INVALID
 ret
.limit: mov eax,NEBO_INDEX_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
