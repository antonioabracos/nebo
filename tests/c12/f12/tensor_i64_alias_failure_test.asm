bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"
section .rodata align=8
shape_23: dq 2,3
values: dq 1,2,3,4,5,6
index1: dq 1
section .bss align=8
owner: resb NEBO_TENSOR_SIZE
view: resb NEBO_TENSOR_SIZE
copy: resb NEBO_TENSOR_SIZE
other: resb NEBO_TENSOR_SIZE
payload: resq 64
copy_payload: resq 64
other_payload: resq 64
section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_23]
 mov r9d,1201
 push qword 6
 lea rax,[values]
 push rax
 call nebo_tensor_i64_from_buffer
 add rsp,16
 test eax,eax
 jnz .fail1
 ; Select row 1 then explicitly materialize [4,5,6].
 lea rdi,[owner]
 lea rsi,[view]
 xor edx,edx
 mov ecx,1
 call nebo_tensor_i64_select_view
 test eax,eax
 jnz .fail2
 lea rdi,[copy]
 lea rsi,[copy_payload]
 lea rdx,[view]
 lea rcx,[owner]
 mov r8d,1202
 call nebo_tensor_i64_contiguous
 test eax,eax
 jnz .fail3
 cmp qword [copy_payload],4
 jne .fail4
 cmp qword [copy_payload+8],5
 jne .fail5
 cmp qword [copy_payload+16],6
 jne .fail6
 cmp qword [copy+NEBO_TENSOR_STORAGE_ID],1202
 jne .fail7
 ; Partial overlap with an input payload is rejected before writes.
 lea rdi,[other]
 lea rsi,[payload+8]
 lea rdx,[owner]
 lea rcx,[owner]
 mov r8d,1203
 call nebo_tensor_i64_add
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail8
 cmp qword [payload+8],2
 jne .fail9
 ; Explicit materialization cannot target the owner's payload.
 lea rdi,[other]
 lea rsi,[payload+16]
 lea rdx,[view]
 lea rcx,[owner]
 mov r8d,1204
 call nebo_tensor_i64_contiguous
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail10
 cmp qword [payload+16],3
 jne .fail11
 ; Owner invalidation makes the old view relation stale/fail-closed.
 lea rdi,[owner]
 call nebo_tensor_i64_owner_invalidate
 test eax,eax
 jnz .fail12
 lea rdi,[view]
 lea rsi,[owner]
 call nebo_tensor_i64_view_validate_owner
 test eax,eax
 jz .fail13
 ; A view never becomes a mutation receiver.
 lea rdi,[view]
 lea rsi,[index1]
 mov edx,1
 mov ecx,99
 call nebo_tensor_i64_set
 test eax,eax
 jz .fail14
 xor edi,edi
 jmp .exit
%assign i 1
%rep 14
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
