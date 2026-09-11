bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .rodata align=8
shape: dq 4,4,4

section .bss align=16
left: resb NEBO_TENSOR_SIZE
right: resb NEBO_TENSOR_SIZE
out: resb NEBO_TENSOR_SIZE
decoded: resb NEBO_TENSOR_SIZE
bad: resb NEBO_TENSOR_SIZE
left_payload: resq 64
right_payload: resq 64
out_payload: resq 64
decoded_payload: resq 64
bad_payload: resq 64
encoded: resb NEBO_TENSOR_I64_NBT1_MAX_BYTES

section .text
global _start
_start:
 ; Deterministic independent inputs: left=i-31, right=(i&7)-3.
 xor ecx,ecx
.seed:
 cmp ecx,64
 je .owners
 mov rax,rcx
 sub rax,31
 mov [left_payload+rcx*8],rax
 mov rax,rcx
 and eax,7
 sub rax,3
 mov [right_payload+rcx*8],rax
 inc ecx
 jmp .seed
.owners:
 lea rdi,[left]
 lea rsi,[left_payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape]
 mov r9d,1501
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail1
 lea rdi,[right]
 lea rsi,[right_payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape]
 mov r9d,1502
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail2

 ; Runtime add is compared element-by-element with independent scalar add.
 lea rdi,[out]
 lea rsi,[out_payload]
 lea rdx,[left]
 lea rcx,[right]
 mov r8d,1503
 call nebo_tensor_i64_add
 test eax,eax
 jnz .fail3
 xor ecx,ecx
.check_add:
 cmp ecx,64
 je .multiply
 mov rax,[left_payload+rcx*8]
 add rax,[right_payload+rcx*8]
 cmp rax,[out_payload+rcx*8]
 jne .fail4
 inc ecx
 jmp .check_add

 ; Runtime multiply is compared with independent scalar multiply.
.multiply:
 lea rdi,[out]
 lea rsi,[out_payload]
 lea rdx,[left]
 lea rcx,[right]
 mov r8d,1504
 call nebo_tensor_i64_multiply
 test eax,eax
 jnz .fail5
 xor ecx,ecx
.check_multiply:
 cmp ecx,64
 je .sum_reference
 mov rax,[left_payload+rcx*8]
 imul rax,[right_payload+rcx*8]
 cmp rax,[out_payload+rcx*8]
 jne .fail6
 inc ecx
 jmp .check_multiply

 ; Sum/min/max use independent scalar folds over the immutable payload.
.sum_reference:
 xor ecx,ecx
 xor r12d,r12d
 mov r13,[left_payload]
 mov r14,r13
.fold:
 cmp ecx,64
 je .runtime_reductions
 mov rax,[left_payload+rcx*8]
 add r12,rax
 cmp rax,r13
 cmovl r13,rax
 cmp rax,r14
 cmovg r14,rax
 inc ecx
 jmp .fold
.runtime_reductions:
 lea rdi,[left]
 call nebo_tensor_i64_sum_all
 test edx,edx
 jnz .fail7
 cmp rax,r12
 jne .fail8
 lea rdi,[left]
 call nebo_tensor_i64_min
 test edx,edx
 jnz .fail9
 cmp rax,r13
 jne .fail10
 lea rdi,[left]
 call nebo_tensor_i64_max
 test edx,edx
 jnz .fail11
 cmp rax,r14
 jne .fail12

 ; Byte-exact NBT1 roundtrip for the maximum selected element count.
 lea rdi,[left]
 lea rsi,[encoded]
 mov edx,NEBO_TENSOR_I64_NBT1_MAX_BYTES
 call nebo_tensor_i64_serialize
 test eax,eax
 jnz .fail13
 cmp rdx,NEBO_TENSOR_I64_NBT1_MAX_BYTES
 jne .fail14
 lea rdi,[decoded]
 lea rsi,[decoded_payload]
 lea rdx,[encoded]
 mov ecx,NEBO_TENSOR_I64_NBT1_MAX_BYTES
 mov r8d,1505
 call nebo_tensor_i64_deserialize
 test eax,eax
 jnz .fail15
 lea rsi,[left_payload]
 lea rdi,[decoded_payload]
 mov ecx,64
 repe cmpsq
 jne .fail16

 ; 64 invalid public ranks, each reconstructed from valid metadata.
 mov r15,4
.rank_fuzz:
 cmp r15,68
 jae .truncation_setup
 lea rsi,[left]
 lea rdi,[bad]
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 mov [bad+NEBO_TENSOR_RANK],r15
 lea rdi,[bad]
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jz .fail17
 inc r15
 jmp .rank_fuzz

 ; Every truncation shorter than the 144-byte header is rejected and leaves
 ; the destination sentinel intact: 144 additional fail-closed cases.
.truncation_setup:
 mov r15,0
.truncation_fuzz:
 cmp r15,NEBO_TENSOR_I64_NBT1_HEADER_BYTES
 jae .success
 mov rax,0x6666666666666666
 mov [bad],rax
 mov rax,0x7777777777777777
 mov [bad_payload],rax
 lea rdi,[bad]
 lea rsi,[bad_payload]
 lea rdx,[encoded]
 mov rcx,r15
 mov r8d,1506
 call nebo_tensor_i64_deserialize
 test eax,eax
 jz .fail18
 mov rax,0x6666666666666666
 cmp [bad],rax
 jne .fail19
 mov rax,0x7777777777777777
 cmp [bad_payload],rax
 jne .fail20
 inc r15
 jmp .truncation_fuzz
.success:
 xor edi,edi
 jmp .exit
%assign i 1
%rep 20
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
