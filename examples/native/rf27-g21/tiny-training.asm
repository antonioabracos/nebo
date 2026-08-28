bits 64
default rel
%include "runtime/training/losses.inc"
%include "runtime/training/optimizers.inc"
section .data
parameter dq 1.0
target dq 0.0
gradient dq 0.0
learning_rate dq 0.1
two dq 2.0
loss_threshold dq 0.012
section .bss
loss_value resq 1
section .text
global _start
_start:
 mov r12d,10
.train:
 lea rdi,[rel parameter]
 lea rsi,[rel target]
 mov edx,1
 lea rcx,[rel loss_value]
 call nebo_loss_mse
 test eax,eax
 jnz .fail
 movsd xmm0,[rel parameter]
 mulsd xmm0,[rel two]
 movsd [rel gradient],xmm0
 lea rdi,[rel parameter]
 lea rsi,[rel gradient]
 mov edx,1
 lea rcx,[rel learning_rate]
 call nebo_optimizer_sgd
 test eax,eax
 jnz .fail
 dec r12
 jnz .train
 lea rdi,[rel parameter]
 lea rsi,[rel target]
 mov edx,1
 lea rcx,[rel loss_value]
 call nebo_loss_mse
 test eax,eax
 jnz .fail
 movsd xmm0,[rel loss_value]
 ucomisd xmm0,[rel loss_threshold]
 ja .fail
 xor edi,edi
 jmp .exit
.fail:
 mov edi,1
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
