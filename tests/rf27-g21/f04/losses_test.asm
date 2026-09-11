bits 64
default rel
%include "runtime/training/losses.inc"
section .data
pred_values dq 1.0,2.0,3.0
target_values dq 1.0,4.0,2.0
bad_values dq 1.0,0x7ff0000000000000
bce_logits dq 0.0,0.0
bce_targets dq 0.0,1.0
bad_bce_targets dq 0.0,2.0
ce_logits dq 1.0,2.0,3.0,1.0,1.0,1.0
log_probs dq -0.1,-2.0,-3.0,-0.5,-1.0,-2.0
class_targets dq 2,0
bad_class_targets dq 3,0
pred_classes dq 1,2,0,1
metric_targets dq 1,0,0,1
one dq 1.0
three_quarters dq 0.75
five_thirds_low dq 1.666666666665
five_thirds_high dq 1.666666666668
ln2_low dq 0.693147180558
ln2_high dq 0.693147180562
ce_low dq 0.753109126554
ce_high dq 0.753109126559
nll_low dq 1.749999999999
nll_high dq 1.750000000001
sentinel dq 0x55aa55aa55aa55aa
infinity dq 0x7ff0000000000000
section .bss
loss_out resq 1
pr_report resq 5
matrix resq 9
section .text
global _start
_start:
 lea rdi,[rel pred_values]
 lea rsi,[rel target_values]
 mov edx,3
 lea rcx,[rel loss_out]
 call nebo_loss_mse
 test eax,eax
 jnz .fail1
 movsd xmm0,[rel loss_out]
 ucomisd xmm0,[rel five_thirds_low]
 jb .fail2
 ucomisd xmm0,[rel five_thirds_high]
 ja .fail3
 mov rax,[rel sentinel]
 mov [rel loss_out],rax
 lea rdi,[rel pred_values]
 lea rsi,[rel target_values]
 xor edx,edx
 lea rcx,[rel loss_out]
 call nebo_loss_mse
 cmp eax,NEBO_LOSS_E_LIMIT
 jne .fail4
 mov rax,[rel sentinel]
 cmp [rel loss_out],rax
 jne .fail5
 lea rdi,[rel bad_values]
 lea rsi,[rel target_values]
 mov edx,2
 lea rcx,[rel loss_out]
 call nebo_loss_mse
 cmp eax,NEBO_LOSS_E_NONFINITE
 jne .fail6
 mov rax,[rel sentinel]
 cmp [rel loss_out],rax
 jne .fail7
 lea rdi,[rel bce_logits]
 lea rsi,[rel bce_targets]
 mov edx,2
 lea rcx,[rel loss_out]
 call nebo_loss_binary_cross_entropy
 test eax,eax
 jnz .fail8
 movsd xmm0,[rel loss_out]
 ucomisd xmm0,[rel ln2_low]
 jb .fail9
 ucomisd xmm0,[rel ln2_high]
 ja .fail9
 mov rax,[rel sentinel]
 mov [rel loss_out],rax
 lea rdi,[rel bce_logits]
 lea rsi,[rel bad_bce_targets]
 mov edx,2
 lea rcx,[rel loss_out]
 call nebo_loss_binary_cross_entropy
 cmp eax,NEBO_LOSS_E_TARGET
 jne .fail10
 mov rax,[rel sentinel]
 cmp [rel loss_out],rax
 jne .fail11
 lea rdi,[rel ce_logits]
 lea rsi,[rel class_targets]
 mov edx,2
 mov ecx,3
 lea r8,[rel loss_out]
 call nebo_loss_cross_entropy
 test eax,eax
 jnz .fail12
 movsd xmm0,[rel loss_out]
 ucomisd xmm0,[rel ce_low]
 jb .fail13
 ucomisd xmm0,[rel ce_high]
 ja .fail13
 mov rax,[rel sentinel]
 mov [rel loss_out],rax
 lea rdi,[rel ce_logits]
 lea rsi,[rel bad_class_targets]
 mov edx,2
 mov ecx,3
 lea r8,[rel loss_out]
 call nebo_loss_cross_entropy
 cmp eax,NEBO_LOSS_E_TARGET
 jne .fail14
 mov rax,[rel sentinel]
 cmp [rel loss_out],rax
 jne .fail15
 lea rdi,[rel ce_logits]
 lea rsi,[rel class_targets]
 mov edx,2
 xor ecx,ecx
 lea r8,[rel loss_out]
 call nebo_loss_cross_entropy
 cmp eax,NEBO_LOSS_E_SHAPE
 jne .fail16
 lea rdi,[rel log_probs]
 lea rsi,[rel class_targets]
 mov edx,2
 mov ecx,3
 lea r8,[rel loss_out]
 call nebo_loss_nll
 test eax,eax
 jnz .fail17
 movsd xmm0,[rel loss_out]
 ucomisd xmm0,[rel nll_low]
 jb .fail18
 ucomisd xmm0,[rel nll_high]
 ja .fail18
 mov rax,[rel infinity]
 mov [rel log_probs],rax
 mov rax,[rel sentinel]
 mov [rel loss_out],rax
 lea rdi,[rel log_probs]
 lea rsi,[rel class_targets]
 mov edx,2
 mov ecx,3
 lea r8,[rel loss_out]
 call nebo_loss_nll
 cmp eax,NEBO_LOSS_E_NONFINITE
 jne .fail19
 mov rax,[rel sentinel]
 cmp [rel loss_out],rax
 jne .fail20
 mov rax,0xbfb999999999999a
 mov [rel log_probs],rax
 lea rdi,[rel pred_classes]
 lea rsi,[rel metric_targets]
 mov edx,4
 lea rcx,[rel loss_out]
 call nebo_metric_accuracy
 test eax,eax
 jnz .fail21
 mov rax,[rel three_quarters]
 cmp [rel loss_out],rax
 jne .fail22
 lea rdi,[rel pred_classes]
 lea rsi,[rel metric_targets]
 xor edx,edx
 lea rcx,[rel loss_out]
 call nebo_metric_accuracy
 cmp eax,NEBO_LOSS_E_LIMIT
 jne .fail23
 lea rdi,[rel pred_classes]
 lea rsi,[rel metric_targets]
 mov edx,4
 mov ecx,1
 lea r8,[rel pr_report]
 call nebo_metric_precision_recall
 test eax,eax
 jnz .fail24
 mov rax,[rel one]
 cmp [rel pr_report],rax
 jne .fail25
 cmp [rel pr_report+8],rax
 jne .fail26
 cmp qword [rel pr_report+16],2
 jne .fail27
 cmp qword [rel pr_report+24],0
 jne .fail28
 cmp qword [rel pr_report+32],0
 jne .fail29
 lea rdi,[rel pred_classes]
 lea rsi,[rel metric_targets]
 mov edx,4
 mov ecx,64
 lea r8,[rel pr_report]
 call nebo_metric_precision_recall
 cmp eax,NEBO_LOSS_E_TARGET
 jne .fail30
 lea rdi,[rel pred_classes]
 lea rsi,[rel metric_targets]
 mov edx,4
 mov ecx,3
 lea r8,[rel matrix]
 mov r9d,9
 call nebo_metric_confusion_matrix
 test eax,eax
 jnz .fail31
 cmp qword [rel matrix],1
 jne .fail32
 cmp qword [rel matrix+16],1
 jne .fail33
 cmp qword [rel matrix+32],2
 jne .fail34
 cmp qword [rel matrix+64],0
 jne .fail35
 mov rax,[rel sentinel]
 mov [rel matrix],rax
 lea rdi,[rel pred_classes]
 lea rsi,[rel metric_targets]
 mov edx,4
 mov ecx,3
 lea r8,[rel matrix]
 mov r9d,8
 call nebo_metric_confusion_matrix
 cmp eax,NEBO_LOSS_E_CAPACITY
 jne .fail36
 mov rax,[rel sentinel]
 cmp [rel matrix],rax
 jne .fail37
 lea rdi,[rel matrix]
 lea rsi,[rel metric_targets]
 mov edx,4
 mov ecx,3
 lea r8,[rel matrix]
 mov r9d,9
 call nebo_metric_confusion_matrix
 cmp eax,NEBO_LOSS_E_OVERLAP
 jne .fail38
 mov qword [rel metric_targets],3
 lea rdi,[rel pred_classes]
 lea rsi,[rel metric_targets]
 mov edx,4
 mov ecx,3
 lea r8,[rel matrix]
 mov r9d,9
 call nebo_metric_confusion_matrix
 cmp eax,NEBO_LOSS_E_TARGET
 jne .fail39
 mov rax,[rel sentinel]
 cmp [rel matrix],rax
 jne .fail40
 xor edi,edi
 jmp .exit
%assign i 1
%rep 40
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
