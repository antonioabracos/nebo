bits 64
default rel
%include "runtime/training/trainer.inc"
section .data
losses dq 3.0,2.0,2.5,2.6,1.0
sample_counts dq 2,2,2,2,2
eval_losses dq 1.0,2.0,3.0
single_loss dq 1.5
bad_losses dq 1.0,0x7ff0000000000000
two dq 2.0
one_point_five dq 1.5
sentinel dq 0x55aa55aa55aa55aa
section .bss
trainer resq 12
fit_request resq 5
fit_report resq 5
callback_report resq 5
cancel_word resq 1
callback_count resq 1
reentry_status resq 1
eval_out resq 1
section .text
global _start
_start:
 lea rdi,[rel trainer]
 mov esi,10
 mov edx,2
 lea rcx,[rel cancel_word]
 lea r8,[rel .test_callback]
 lea r9,[rel trainer]
 call nebo_trainer_init
 test eax,eax
 jnz .fail1
 cmp qword [rel trainer],NEBO_TRAINER_STATE_READY
 jne .fail2
 cmp qword [rel trainer+88],1
 jne .fail3
 lea rax,[rel trainer]
 mov [rel fit_request],rax
 lea rax,[rel losses]
 mov [rel fit_request+8],rax
 lea rax,[rel sample_counts]
 mov [rel fit_request+16],rax
 mov qword [rel fit_request+24],5
 lea rax,[rel fit_report]
 mov [rel fit_request+32],rax
 lea rdi,[rel fit_request]
 call nebo_trainer_fit
 test eax,eax
 jnz .fail4
 cmp qword [rel fit_report],4
 jne .fail5
 cmp qword [rel fit_report+8],8
 jne .fail6
 mov rax,[rel two]
 cmp [rel fit_report+16],rax
 jne .fail7
 cmp qword [rel fit_report+24],NEBO_TRAINER_OUTCOME_EARLY_STOP
 jne .fail8
 cmp qword [rel fit_report+32],2
 jne .fail9
 cmp qword [rel callback_count],4
 jne .fail10
 cmp qword [rel reentry_status],NEBO_TRAINER_E_REENTRY
 jne .fail11
 cmp qword [rel trainer],NEBO_TRAINER_STATE_READY
 jne .fail12
 lea rdi,[rel eval_losses]
 mov esi,3
 lea rdx,[rel eval_out]
 call nebo_trainer_evaluate
 test eax,eax
 jnz .fail13
 mov rax,[rel two]
 cmp [rel eval_out],rax
 jne .fail14
 lea rdi,[rel trainer]
 mov esi,10
 mov edx,0
 lea rcx,[rel cancel_word]
 xor r8d,r8d
 xor r9d,r9d
 call nebo_trainer_init
 test eax,eax
 jnz .fail15
 lea rdi,[rel trainer]
 call nebo_trainer_cancel
 test eax,eax
 jnz .fail16
 lea rdi,[rel fit_request]
 call nebo_trainer_fit
 cmp eax,NEBO_TRAINER_E_CANCELLED
 jne .fail17
 cmp qword [rel fit_report],0
 jne .fail18
 cmp qword [rel fit_report+24],NEBO_TRAINER_OUTCOME_CANCELLED
 jne .fail19
 lea rdi,[rel trainer]
 mov esi,10
 xor edx,edx
 lea rcx,[rel cancel_word]
 xor r8d,r8d
 xor r9d,r9d
 call nebo_trainer_init
 test eax,eax
 jnz .fail20
 lea rdi,[rel trainer]
 lea rsi,[rel single_loss]
 mov edx,4
 call nebo_trainer_train_batch
 test eax,eax
 jnz .fail21
 lea rdi,[rel trainer]
 lea rsi,[rel fit_report]
 call nebo_trainer_progress
 test eax,eax
 jnz .fail22
 cmp qword [rel fit_report],1
 jne .fail23
 cmp qword [rel fit_report+8],4
 jne .fail24
 mov rax,[rel one_point_five]
 cmp [rel fit_report+16],rax
 jne .fail25
 mov rax,[rel sentinel]
 mov [rel fit_report],rax
 lea rax,[rel bad_losses]
 mov [rel fit_request+8],rax
 mov qword [rel fit_request+24],2
 lea rdi,[rel fit_request]
 call nebo_trainer_fit
 cmp eax,NEBO_TRAINER_E_NONFINITE
 jne .fail26
 mov rax,[rel sentinel]
 cmp [rel fit_report],rax
 jne .fail27
 cmp qword [rel trainer],NEBO_TRAINER_STATE_READY
 jne .fail28
 lea rdi,[rel trainer]
 call nebo_trainer_close
 test eax,eax
 jnz .fail29
 cmp qword [rel trainer],NEBO_TRAINER_STATE_CLOSED
 jne .fail30
 cmp qword [rel trainer+72],0
 jne .fail31
 lea rdi,[rel trainer]
 call nebo_trainer_close
 cmp eax,NEBO_TRAINER_E_STATE
 jne .fail32
 xor edi,edi
 jmp .exit

.test_callback:
 push rbx
 mov rbx,rdi
 inc qword [rel callback_count]
 mov rdi,rbx
 lea rsi,[rel callback_report]
 call nebo_trainer_progress
 test eax,eax
 jnz .callback_fail
 mov rdi,rbx
 lea rsi,[rel single_loss]
 mov edx,1
 call nebo_trainer_train_batch
 mov [rel reentry_status],rax
 xor eax,eax
 pop rbx
 ret
.callback_fail:
 mov eax,1
 pop rbx
 ret

%assign i 1
%rep 32
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
