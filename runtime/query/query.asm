; MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-F03 bounded typed scan/filter/project/limit/collect kernel.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/query/query.inc"
section .text
NEBOC_ABI_FUNCTION nebo_query_plan_validate
 test rdi,rdi
 jz .invalid
 cmp rdi,NEBO_QUERY_MAX_NODES
 ja .limit
 cmp rsi,NEBO_QUERY_MAX_JOINS
 ja .limit
 cmp rdx,NEBO_QUERY_MAX_GROUPS
 ja .limit
 test rcx,rcx
 jz .limit
 cmp rcx,NEBO_QUERY_MAX_RESULTS
 ja .limit
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_QUERY_STATUS_INVALID
 ret
.limit:
 mov eax,NEBO_QUERY_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_query_filter_sum
 ; values,count,threshold,limit,out_count,out_sum
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,NEBO_QUERY_MAX_RESULTS
 ja .limit
 test rcx,rcx
 jz .limit
 cmp rcx,NEBO_QUERY_MAX_RESULTS
 ja .limit
 push rbx
 mov rbx,rdx
 xor r10d,r10d
 xor r11d,r11d
 xor eax,eax
.loop:
 cmp rax,rsi
 jae .done
 cmp r10,rcx
 jae .done
 mov rdx,[rdi+rax*8]
 cmp rdx,rbx
 jl .next
 add r11,rdx
 inc r10
.next:
 inc rax
 jmp .loop
.done:
 mov [r8],r10
 mov [r9],r11
 pop rbx
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_QUERY_STATUS_INVALID
 ret
.limit:
 mov eax,NEBO_QUERY_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
