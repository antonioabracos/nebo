; OPERADORES-DE-FLUXO-E-BRANCHING-PIPELINES-F06 structured, join-before-return numeric chunk execution.
bits 64
default rel
%define NEBO_NUMERIC_PARALLEL_IMPLEMENTATION 1
%include "runtime/kernel/numeric_parallel.inc"
section .text
global nebo_parallel_plan
global nebo_parallel_add_f64
global nebo_parallel_reduce_sum_f64
; elements rdi, requested workers rsi, plan rdx.
nebo_parallel_plan:
 test rdx,rdx
 jz parallel_argument_error
 push r12
 mov r12,rdx
 mov r8,rdi
 mov r9,rsi
 mov rdi,rdx
 xor eax,eax
 mov ecx,NEBO_PARALLEL_PLAN_SIZE/8
 rep stosq
 cmp r8,NEBO_NUMERIC_MAX_ELEMENTS
 ja .bounds
 test r9,r9
 jz .bounds
 cmp r9,NEBO_NUMERIC_MAX_WORKERS
 ja .bounds
 mov rax,r8
 add rax,NEBO_NUMERIC_CHUNK_ELEMENTS-1
 shr rax,8
 mov [r12+NEBO_PARALLEL_PLAN_CHUNKS],rax
 mov qword [r12+NEBO_PARALLEL_PLAN_CHUNK_SIZE],NEBO_NUMERIC_CHUNK_ELEMENTS
 test r8,r8
 jz .empty
 mov rcx,rax
 cmp r9,rcx
 cmovb rcx,r9
 mov [r12+NEBO_PARALLEL_PLAN_WORKERS],rcx
 mov rax,r8
 and rax,NEBO_NUMERIC_CHUNK_ELEMENTS-1
 jnz .last
 mov eax,NEBO_NUMERIC_CHUNK_ELEMENTS
.last: mov [r12+NEBO_PARALLEL_PLAN_LAST_CHUNK],rax
 jmp .trace
.empty:
 mov qword [r12+NEBO_PARALLEL_PLAN_WORKERS],1
 mov qword [r12+NEBO_PARALLEL_PLAN_LAST_CHUNK],0
.trace:
 mov rax,r8
 mov rcx,r9
 shl rcx,16
 or rax,rcx
 mov rcx,[r12+NEBO_PARALLEL_PLAN_WORKERS]
 shl rcx,24
 or rax,rcx
 mov rcx,[r12+NEBO_PARALLEL_PLAN_CHUNKS]
 shl rcx,32
 or rax,rcx
 mov [r12+NEBO_PARALLEL_PLAN_TRACE],rax
 xor eax,eax
 pop r12
 ret
.bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 pop r12
 ret
; out,a,b,count,requested workers,optional cancellation state pointer.
nebo_parallel_add_f64:
 cmp rcx,NEBO_NUMERIC_MAX_ELEMENTS
 ja parallel_bounds_error
 test r8,r8
 jz parallel_bounds_error
 cmp r8,NEBO_NUMERIC_MAX_WORKERS
 ja parallel_bounds_error
 test rcx,rcx
 jz parallel_ok
 test rdi,rdi
 jz parallel_argument_error
 test rsi,rsi
 jz parallel_argument_error
 test rdx,rdx
 jz parallel_argument_error
 mov rax,rcx
 shl rax,3
 lea r10,[rdi+rax]
 lea r11,[rsi+rax]
 cmp rdi,r11
 jae .check_b
 cmp rsi,r10
 jb parallel_alias_error
.check_b:
 lea r11,[rdx+rax]
 cmp rdi,r11
 jae .cancel
 cmp rdx,r10
 jb parallel_alias_error
.cancel:
 test r9,r9
 jz .execute
 cmp qword [r9],0
 jne parallel_cancelled_error
.execute:
 ; Each bounded chunk is completed before the next one; return implies join.
 xor eax,eax
.loop: cmp rax,rcx
 jae parallel_ok
 movsd xmm0,[rsi+rax*8]
 addsd xmm0,[rdx+rax*8]
 movsd [rdi+rax*8],xmm0
 inc rax
 jmp .loop
; input,count,requested workers,optional cancellation state pointer -> xmm0/status.
nebo_parallel_reduce_sum_f64:
 cmp rsi,NEBO_NUMERIC_MAX_ELEMENTS
 ja parallel_bounds_error
 test rdx,rdx
 jz parallel_bounds_error
 cmp rdx,NEBO_NUMERIC_MAX_WORKERS
 ja parallel_bounds_error
 test rsi,rsi
 jz .zero
 test rdi,rdi
 jz parallel_argument_error
 test rcx,rcx
 jz .begin
 cmp qword [rcx],0
 jne parallel_cancelled_zero_error
.begin:
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov r12,rdi
 mov r13,rsi
 mov r15,rcx
 xor r14d,r14d
 xor r8d,r8d
.chunk:
 cmp r14,r13
 jae .combine
 test r15,r15
 jz .chunk_start
 cmp qword [r15],0
 jne .cancelled
.chunk_start:
 mov rax,r13
 sub rax,r14
 cmp rax,NEBO_NUMERIC_CHUNK_ELEMENTS
 jbe .chunk_count
 mov eax,NEBO_NUMERIC_CHUNK_ELEMENTS
.chunk_count:
 pxor xmm0,xmm0
 xor edx,edx
.element: addsd xmm0,[r12+r14*8]
 inc r14
 inc rdx
 cmp rdx,rax
 jb .element
 movsd [rsp+r8*8],xmm0
 inc r8
 jmp .chunk
.combine:
 pxor xmm0,xmm0
 xor ecx,ecx
.combine_loop: cmp rcx,r8
 jae .done
 addsd xmm0,[rsp+rcx*8]
 inc rcx
 jmp .combine_loop
.done: xor eax,eax
 jmp .return
.cancelled: mov eax,NEBO_NUMERIC_ERROR_CANCELLED
 pxor xmm0,xmm0
.return:
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.zero: pxor xmm0,xmm0
parallel_ok: xor eax,eax
 ret
parallel_argument_error: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
parallel_bounds_error: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
parallel_alias_error: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret
parallel_cancelled_zero_error: pxor xmm0,xmm0
parallel_cancelled_error: mov eax,NEBO_NUMERIC_ERROR_CANCELLED
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
