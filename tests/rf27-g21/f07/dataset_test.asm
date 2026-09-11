bits 64
default rel
%include "runtime/training/ml_dataset.inc"
section .data
input_values dq 1.0,2.0
bad_values dq 1.0,0x7ff0000000000000
scale dq 2.0
bias dq 1.0
three dq 3.0
five dq 5.0
sentinel dq 0x55aa55aa55aa55aa
section .bss
dataset resq 8
cancel_word resq 1
indices resq 5
batch_out resq 4
batch_report resq 2
train_count resq 1
validation_count resq 1
augment_out resq 2
section .text
global _start
_start:
 lea rdi,[rel dataset]
 mov esi,5
 mov edx,1
 lea rcx,[rel cancel_word]
 call nebo_dataset_init
 test eax,eax
 jnz .fail1
 cmp qword [rel dataset],5
 jne .fail2
 cmp qword [rel dataset+24],1
 jne .fail3
 mov rax,[rel sentinel]
 mov [rel indices],rax
 lea rdi,[rel dataset]
 lea rsi,[rel indices]
 mov edx,4
 call nebo_dataset_shuffle
 cmp eax,NEBO_DATASET_E_CAPACITY
 jne .fail4
 mov rax,[rel sentinel]
 cmp [rel indices],rax
 jne .fail5
 lea rdi,[rel dataset]
 lea rsi,[rel indices]
 mov edx,5
 call nebo_dataset_shuffle
 test eax,eax
 jnz .fail6
 cmp qword [rel indices],2
 jne .fail7
 cmp qword [rel indices+8],3
 jne .fail8
 cmp qword [rel indices+16],0
 jne .fail9
 cmp qword [rel indices+24],4
 jne .fail10
 cmp qword [rel indices+32],1
 jne .fail11
 lea rdi,[rel dataset]
 lea rsi,[rel indices]
 mov edx,2
 lea rcx,[rel batch_out]
 mov r8d,2
 lea r9,[rel batch_report]
 call nebo_dataset_batch
 test eax,eax
 jnz .fail12
 cmp qword [rel batch_out],2
 jne .fail13
 cmp qword [rel batch_out+8],3
 jne .fail14
 cmp qword [rel batch_report],2
 jne .fail15
 cmp qword [rel batch_report+8],0
 jne .fail16
 lea rdi,[rel dataset]
 lea rsi,[rel indices]
 mov edx,4
 lea rcx,[rel batch_out]
 mov r8d,4
 lea r9,[rel batch_report]
 call nebo_dataset_batch
 test eax,eax
 jnz .fail17
 cmp qword [rel batch_report],3
 jne .fail18
 cmp qword [rel batch_report+8],2
 jne .fail19
 cmp qword [rel dataset+8],5
 jne .fail20
 lea rdi,[rel dataset]
 lea rsi,[rel indices]
 mov edx,1
 lea rcx,[rel batch_out]
 mov r8d,1
 lea r9,[rel batch_report]
 call nebo_dataset_batch
 cmp eax,NEBO_DATASET_E_END
 jne .fail21
 mov edi,5
 mov esi,4
 mov edx,5
 lea rcx,[rel train_count]
 lea r8,[rel validation_count]
 call nebo_dataset_split
 test eax,eax
 jnz .fail22
 cmp qword [rel train_count],4
 jne .fail23
 cmp qword [rel validation_count],1
 jne .fail24
 mov edi,5
 mov esi,5
 mov edx,5
 lea rcx,[rel train_count]
 lea r8,[rel validation_count]
 call nebo_dataset_split
 cmp eax,NEBO_DATASET_E_RATIO
 jne .fail25
 lea rdi,[rel input_values]
 mov esi,2
 lea rdx,[rel scale]
 lea rcx,[rel bias]
 lea r8,[rel augment_out]
 call nebo_dataset_augment_affine
 test eax,eax
 jnz .fail26
 mov rax,[rel three]
 cmp [rel augment_out],rax
 jne .fail27
 mov rax,[rel five]
 cmp [rel augment_out+8],rax
 jne .fail28
 mov rax,[rel sentinel]
 mov [rel augment_out],rax
 lea rdi,[rel bad_values]
 mov esi,2
 lea rdx,[rel scale]
 lea rcx,[rel bias]
 lea r8,[rel augment_out]
 call nebo_dataset_augment_affine
 cmp eax,NEBO_DATASET_E_NONFINITE
 jne .fail29
 mov rax,[rel sentinel]
 cmp [rel augment_out],rax
 jne .fail30
 mov ecx,8
.acquire_loop:
 lea rdi,[rel dataset]
 call nebo_dataset_prefetch_acquire
 test eax,eax
 jnz .fail31
 loop .acquire_loop
 cmp qword [rel dataset+32],8
 jne .fail32
 lea rdi,[rel dataset]
 call nebo_dataset_prefetch_acquire
 cmp eax,NEBO_DATASET_E_BACKPRESSURE
 jne .fail33
 lea rdi,[rel dataset]
 call nebo_dataset_prefetch_release
 test eax,eax
 jnz .fail34
 cmp qword [rel dataset+32],7
 jne .fail35
 mov qword [rel cancel_word],1
 lea rdi,[rel dataset]
 lea rsi,[rel indices]
 mov edx,5
 call nebo_dataset_shuffle
 cmp eax,NEBO_DATASET_E_CANCELLED
 jne .fail36
 xor edi,edi
 jmp .exit
%assign i 1
%rep 36
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
