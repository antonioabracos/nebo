bits 64
default rel
%define NEBO_ML_DATASET_IMPLEMENTATION 1
%include "runtime/training/ml_dataset.inc"
section .rodata align=16
d_exp dq 0x7ff0000000000000,0
section .text
global nebo_dataset_init
global nebo_dataset_shuffle
global nebo_dataset_batch
global nebo_dataset_split
global nebo_dataset_augment_affine
global nebo_dataset_prefetch_acquire
global nebo_dataset_prefetch_release

; Dataset64: size,cursor,seed,generation,prefetch,cancel*,flags,reserved.
nebo_dataset_init:
 test rdi,rdi
 jz .init_arg
 test rcx,rcx
 jz .init_arg
 test rsi,rsi
 jz .init_limit
 cmp rsi,NEBO_DATASET_MAX_SAMPLES
 ja .init_limit
 test rdx,rdx
 jz .init_arg
 mov [rdi],rsi
 mov qword [rdi+8],0
 mov [rdi+16],rdx
 inc qword [rdi+24]
 mov qword [rdi+32],0
 mov [rdi+40],rcx
 mov qword [rdi+48],0
 mov qword [rdi+56],0
 mov qword [rcx],0
 xor eax,eax
 ret
.init_arg:
 mov eax,NEBO_DATASET_E_ARGUMENT
 ret
.init_limit:
 mov eax,NEBO_DATASET_E_LIMIT
 ret

; rdi=dataset,rsi=indices,rdx=capacity. Fisher-Yates with xorshift64 state.
nebo_dataset_shuffle:
 test rdi,rdi
 jz .shuffle_arg
 test rsi,rsi
 jz .shuffle_arg
 mov r8,[rdi]
 test r8,r8
 jz .shuffle_state
 cmp rdx,r8
 jb .shuffle_capacity
 mov rax,[rdi+40]
 cmp qword [rax],0
 jne .shuffle_cancelled
 xor ecx,ecx
.shuffle_fill:
 cmp rcx,r8
 jae .shuffle_start
 mov [rsi+rcx*8],rcx
 inc rcx
 jmp .shuffle_fill
.shuffle_start:
 mov r9,[rdi+16]
 mov rcx,r8
 dec rcx
.shuffle_loop:
 test rcx,rcx
 jz .shuffle_done
 mov rax,r9
 shl rax,13
 xor r9,rax
 mov rax,r9
 shr rax,7
 xor r9,rax
 mov rax,r9
 shl rax,17
 xor r9,rax
 mov rax,r9
 xor edx,edx
 lea r10,[rcx+1]
 div r10
 mov rax,[rsi+rcx*8]
 mov r10,[rsi+rdx*8]
 mov [rsi+rcx*8],r10
 mov [rsi+rdx*8],rax
 dec rcx
 jmp .shuffle_loop
.shuffle_done:
 mov [rdi+16],r9
 mov qword [rdi+8],0
 xor eax,eax
 ret
.shuffle_arg:
 mov eax,NEBO_DATASET_E_ARGUMENT
 ret
.shuffle_state:
 mov eax,NEBO_DATASET_E_STATE
 ret
.shuffle_capacity:
 mov eax,NEBO_DATASET_E_CAPACITY
 ret
.shuffle_cancelled:
 mov eax,NEBO_DATASET_E_CANCELLED
 ret

; rdi=dataset,rsi=indices,rdx=batchSize,rcx=out,r8=capacity,r9=Report16.
nebo_dataset_batch:
 test rdi,rdi
 jz .batch_arg
 test rsi,rsi
 jz .batch_arg
 test rcx,rcx
 jz .batch_arg
 test r9,r9
 jz .batch_arg
 test rdx,rdx
 jz .batch_limit
 cmp rdx,NEBO_DATASET_MAX_BATCH
 ja .batch_limit
 mov r10,[rdi]
 test r10,r10
 jz .batch_state
 mov rax,[rdi+40]
 cmp qword [rax],0
 jne .batch_cancelled
 mov r11,[rdi+8]
 cmp r11,r10
 jae .batch_end
 sub r10,r11
 cmp r10,rdx
 cmova r10,rdx
 cmp r8,r10
 jb .batch_capacity
 mov rax,r11
 lea r8,[r11+r10]
.batch_validate:
 cmp rax,r8
 jae .batch_copy
 mov rdx,[rsi+rax*8]
 cmp rdx,[rdi]
 jae .batch_state
 inc rax
 jmp .batch_validate
.batch_copy:
 xor eax,eax
.batch_loop:
 cmp rax,r10
 jae .batch_done
 mov rdx,[rsi+r11*8]
 mov [rcx+rax*8],rdx
 inc r11
 inc rax
 jmp .batch_loop
.batch_done:
 mov rax,[rdi+8]
 mov [r9+8],rax
 mov [r9],r10
 add [rdi+8],r10
 xor eax,eax
 ret
.batch_arg:
 mov eax,NEBO_DATASET_E_ARGUMENT
 ret
.batch_limit:
 mov eax,NEBO_DATASET_E_LIMIT
 ret
.batch_state:
 mov eax,NEBO_DATASET_E_STATE
 ret
.batch_capacity:
 mov eax,NEBO_DATASET_E_CAPACITY
 ret
.batch_cancelled:
 mov eax,NEBO_DATASET_E_CANCELLED
 ret
.batch_end:
 mov eax,NEBO_DATASET_E_END
 ret

; rdi=size,rsi=numerator,rdx=denominator,rcx=train*,r8=validation*.
nebo_dataset_split:
 test rcx,rcx
 jz .split_arg
 test r8,r8
 jz .split_arg
 test rdi,rdi
 jz .split_limit
 cmp rdi,NEBO_DATASET_MAX_SAMPLES
 ja .split_limit
 test rdx,rdx
 jz .split_ratio
 test rsi,rsi
 jz .split_ratio
 cmp rsi,rdx
 jae .split_ratio
 mov r9,rdx
 mov rax,rdi
 mul rsi
 test rdx,rdx
 jnz .split_limit
 div r9
 mov [rcx],rax
 sub rdi,rax
 mov [r8],rdi
 xor eax,eax
 ret
.split_arg:
 mov eax,NEBO_DATASET_E_ARGUMENT
 ret
.split_limit:
 mov eax,NEBO_DATASET_E_LIMIT
 ret
.split_ratio:
 mov eax,NEBO_DATASET_E_RATIO
 ret

; rdi=input,rsi=count,rdx=*scale,rcx=*bias,r8=output.
nebo_dataset_augment_affine:
 test rdi,rdi
 jz .augment_arg
 test rdx,rdx
 jz .augment_arg
 test rcx,rcx
 jz .augment_arg
 test r8,r8
 jz .augment_arg
 test rsi,rsi
 jz .augment_limit
 cmp rsi,NEBO_DATASET_MAX_SAMPLES
 ja .augment_limit
 movsd xmm2,[rdx]
 movsd xmm3,[rcx]
 movq rax,xmm2
 mov r9,rax
 and r9,[rel d_exp]
 cmp r9,[rel d_exp]
 je .augment_nonfinite
 movq rax,xmm3
 mov r9,rax
 and r9,[rel d_exp]
 cmp r9,[rel d_exp]
 je .augment_nonfinite
 xor ecx,ecx
.augment_check:
 cmp rcx,rsi
 jae .augment_apply
 mov rax,[rdi+rcx*8]
 mov r9,rax
 and r9,[rel d_exp]
 cmp r9,[rel d_exp]
 je .augment_nonfinite
 movsd xmm0,[rdi+rcx*8]
 mulsd xmm0,xmm2
 addsd xmm0,xmm3
 movq rax,xmm0
 and rax,[rel d_exp]
 cmp rax,[rel d_exp]
 je .augment_nonfinite
 inc rcx
 jmp .augment_check
.augment_apply:
 xor ecx,ecx
.augment_loop:
 cmp rcx,rsi
 jae .augment_ok
 movsd xmm0,[rdi+rcx*8]
 mulsd xmm0,xmm2
 addsd xmm0,xmm3
 movsd [r8+rcx*8],xmm0
 inc rcx
 jmp .augment_loop
.augment_ok:
 xor eax,eax
 ret
.augment_arg:
 mov eax,NEBO_DATASET_E_ARGUMENT
 ret
.augment_limit:
 mov eax,NEBO_DATASET_E_LIMIT
 ret
.augment_nonfinite:
 mov eax,NEBO_DATASET_E_NONFINITE
 ret

nebo_dataset_prefetch_acquire:
 test rdi,rdi
 jz .pa_arg
 mov rax,[rdi+40]
 test rax,rax
 jz .pa_state
 cmp qword [rax],0
 jne .pa_cancelled
 cmp qword [rdi+32],NEBO_DATASET_MAX_PREFETCH
 jae .pa_backpressure
 inc qword [rdi+32]
 xor eax,eax
 ret
.pa_arg:
 mov eax,NEBO_DATASET_E_ARGUMENT
 ret
.pa_state:
 mov eax,NEBO_DATASET_E_STATE
 ret
.pa_cancelled:
 mov eax,NEBO_DATASET_E_CANCELLED
 ret
.pa_backpressure:
 mov eax,NEBO_DATASET_E_BACKPRESSURE
 ret

nebo_dataset_prefetch_release:
 test rdi,rdi
 jz .pr_arg
 cmp qword [rdi+32],0
 je .pr_state
 dec qword [rdi+32]
 xor eax,eax
 ret
.pr_arg:
 mov eax,NEBO_DATASET_E_ARGUMENT
 ret
.pr_state:
 mov eax,NEBO_DATASET_E_STATE
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
