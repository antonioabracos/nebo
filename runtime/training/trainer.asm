bits 64
default rel
%define NEBO_TRAINER_IMPLEMENTATION 1
%include "runtime/training/trainer.inc"
section .rodata align=16
t_exp dq 0x7ff0000000000000,0
section .text
global nebo_trainer_init
global nebo_trainer_fit
global nebo_trainer_train_batch
global nebo_trainer_evaluate
global nebo_trainer_cancel
global nebo_trainer_progress
global nebo_trainer_close

; Trainer96: state,epoch,batches,samples,best,stale,patience,maxEpoch,cancel*,callback*,context,generation.
; rdi=trainer,rsi=maxEpoch,rdx=patience,rcx=cancel*,r8=callback,r9=context.
nebo_trainer_init:
 test rdi,rdi
 jz .init_arg
 test rcx,rcx
 jz .init_arg
 test rsi,rsi
 jz .init_limit
 cmp rsi,NEBO_TRAINER_MAX_EPOCHS
 ja .init_limit
 cmp rdx,rsi
 ja .init_limit
 cmp qword [rdi],NEBO_TRAINER_STATE_ACTIVE
 je .init_state
 mov qword [rdi],NEBO_TRAINER_STATE_READY
 mov qword [rdi+8],0
 mov qword [rdi+16],0
 mov qword [rdi+24],0
 mov qword [rdi+32],0
 mov qword [rdi+40],0
 mov [rdi+48],rdx
 mov [rdi+56],rsi
 mov [rdi+64],rcx
 mov [rdi+72],r8
 mov [rdi+80],r9
 inc qword [rdi+88]
 mov qword [rcx],0
 xor eax,eax
 ret
.init_arg:
 mov eax,NEBO_TRAINER_E_ARGUMENT
 ret
.init_limit:
 mov eax,NEBO_TRAINER_E_LIMIT
 ret
.init_state:
 mov eax,NEBO_TRAINER_E_STATE
 ret

; FitRequest40: trainer*,losses*,sampleCounts*,batchCount,Report40*.
nebo_trainer_fit:
 test rdi,rdi
 jz .fit_arg
 mov r11,[rdi]
 test r11,r11
 jz .fit_arg
 mov rax,[rdi+8]
 test rax,rax
 jz .fit_arg
 mov rax,[rdi+16]
 test rax,rax
 jz .fit_arg
 mov rax,[rdi+32]
 test rax,rax
 jz .fit_arg
 mov rcx,[rdi+24]
 test rcx,rcx
 jz .fit_limit
 cmp rcx,NEBO_TRAINER_MAX_EPOCHS
 ja .fit_limit
 cmp qword [r11],NEBO_TRAINER_STATE_ACTIVE
 je .fit_reentry
 cmp qword [r11],NEBO_TRAINER_STATE_READY
 jne .fit_state
 xor rdx,rdx
 xor r9d,r9d
.fit_validate:
 cmp rdx,rcx
 jae .fit_start
 mov rax,[rdi+8]
 mov rax,[rax+rdx*8]
 mov r8,rax
 and r8,[rel t_exp]
 cmp r8,[rel t_exp]
 je .fit_nonfinite
 mov rax,[rdi+16]
 mov rax,[rax+rdx*8]
 test rax,rax
 jz .fit_limit
 cmp rax,NEBO_TRAINER_MAX_BATCH
 ja .fit_limit
 add r9,rax
 jc .fit_overflow_pre
 inc rdx
 jmp .fit_validate
.fit_start:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,r11
 mov r13,rdi
 mov r14,rcx
 xor r12d,r12d
 mov qword [rbx],NEBO_TRAINER_STATE_ACTIVE
.fit_loop:
 mov rax,[rbx+64]
 cmp qword [rax],0
 jne .fit_cancelled
 cmp r12,r14
 jae .fit_completed
 mov rax,[rbx+8]
 cmp rax,[rbx+56]
 jae .fit_completed
 mov rax,[r13+8]
 movsd xmm0,[rax+r12*8]
 cmp qword [rbx+8],0
 je .fit_better
 ucomisd xmm0,[rbx+32]
 jb .fit_better
 inc qword [rbx+40]
 jmp .fit_progress
.fit_better:
 movsd [rbx+32],xmm0
 mov qword [rbx+40],0
.fit_progress:
 inc qword [rbx+8]
 inc qword [rbx+16]
 mov rax,[r13+16]
 mov rax,[rax+r12*8]
 add [rbx+24],rax
 jc .fit_overflow
 mov r15,[rbx+72]
 test r15,r15
 jz .fit_early_check
 mov rdi,[rbx+80]
 mov rsi,[rbx+8]
 mov rax,[r13+8]
 movsd xmm0,[rax+r12*8]
 call r15
 test eax,eax
 jnz .fit_callback
.fit_early_check:
 mov rax,[rbx+48]
 test rax,rax
 jz .fit_next
 cmp [rbx+40],rax
 jae .fit_early
.fit_next:
 inc r12
 jmp .fit_loop
.fit_completed:
 mov rdx,NEBO_TRAINER_OUTCOME_COMPLETED
 xor r15d,r15d
 jmp .fit_publish
.fit_early:
 mov rdx,NEBO_TRAINER_OUTCOME_EARLY_STOP
 xor r15d,r15d
 jmp .fit_publish
.fit_cancelled:
 mov rdx,NEBO_TRAINER_OUTCOME_CANCELLED
 mov r15d,NEBO_TRAINER_E_CANCELLED
 jmp .fit_publish
.fit_callback:
 mov rdx,NEBO_TRAINER_OUTCOME_CALLBACK
 mov r15d,NEBO_TRAINER_E_CALLBACK
 jmp .fit_publish
.fit_overflow:
 mov rdx,NEBO_TRAINER_OUTCOME_CALLBACK
 mov r15d,NEBO_TRAINER_E_OVERFLOW
.fit_publish:
 mov qword [rbx],NEBO_TRAINER_STATE_READY
 mov rdi,rbx
 mov rsi,[r13+32]
 call trainer_report
 mov eax,r15d
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.fit_arg:
 mov eax,NEBO_TRAINER_E_ARGUMENT
 ret
.fit_limit:
 mov eax,NEBO_TRAINER_E_LIMIT
 ret
.fit_state:
 mov eax,NEBO_TRAINER_E_STATE
 ret
.fit_reentry:
 mov eax,NEBO_TRAINER_E_REENTRY
 ret
.fit_nonfinite:
 mov eax,NEBO_TRAINER_E_NONFINITE
 ret
.fit_overflow_pre:
 mov eax,NEBO_TRAINER_E_OVERFLOW
 ret

; rdi=trainer,rsi=*loss,rdx=samples. Single ready-state batch without callback.
nebo_trainer_train_batch:
 test rdi,rdi
 jz .tb_arg
 test rsi,rsi
 jz .tb_arg
 cmp qword [rdi],NEBO_TRAINER_STATE_ACTIVE
 je .tb_reentry
 cmp qword [rdi],NEBO_TRAINER_STATE_READY
 jne .tb_state
 test rdx,rdx
 jz .tb_limit
 cmp rdx,NEBO_TRAINER_MAX_BATCH
 ja .tb_limit
 mov rax,[rsi]
 mov rcx,rax
 and rcx,[rel t_exp]
 cmp rcx,[rel t_exp]
 je .tb_nonfinite
 mov rax,[rdi+64]
 cmp qword [rax],0
 jne .tb_cancelled
 mov rax,[rdi+8]
 cmp rax,[rdi+56]
 jae .tb_limit
 mov r8,[rdi+24]
 add r8,rdx
 jc .tb_overflow
 movsd xmm0,[rsi]
 cmp qword [rdi+8],0
 je .tb_better
 ucomisd xmm0,[rdi+32]
 jb .tb_better
 inc qword [rdi+40]
 jmp .tb_update
.tb_better:
 movsd [rdi+32],xmm0
 mov qword [rdi+40],0
.tb_update:
 inc qword [rdi+8]
 inc qword [rdi+16]
 mov [rdi+24],r8
 xor eax,eax
 ret
.tb_arg:
 mov eax,NEBO_TRAINER_E_ARGUMENT
 ret
.tb_limit:
 mov eax,NEBO_TRAINER_E_LIMIT
 ret
.tb_state:
 mov eax,NEBO_TRAINER_E_STATE
 ret
.tb_reentry:
 mov eax,NEBO_TRAINER_E_REENTRY
 ret
.tb_cancelled:
 mov eax,NEBO_TRAINER_E_CANCELLED
 ret
.tb_nonfinite:
 mov eax,NEBO_TRAINER_E_NONFINITE
 ret
.tb_overflow:
 mov eax,NEBO_TRAINER_E_OVERFLOW
 ret

; rdi=losses,rsi=count,rdx=*mean.
nebo_trainer_evaluate:
 test rdi,rdi
 jz .ev_arg
 test rdx,rdx
 jz .ev_arg
 test rsi,rsi
 jz .ev_limit
 cmp rsi,NEBO_TRAINER_MAX_BATCH
 ja .ev_limit
 xorpd xmm1,xmm1
 xor ecx,ecx
.ev_loop:
 cmp rcx,rsi
 jae .ev_done
 mov rax,[rdi+rcx*8]
 mov r8,rax
 and r8,[rel t_exp]
 cmp r8,[rel t_exp]
 je .ev_nonfinite
 addsd xmm1,[rdi+rcx*8]
 movq rax,xmm1
 and rax,[rel t_exp]
 cmp rax,[rel t_exp]
 je .ev_nonfinite
 inc rcx
 jmp .ev_loop
.ev_done:
 cvtsi2sd xmm0,rsi
 divsd xmm1,xmm0
 movsd [rdx],xmm1
 xor eax,eax
 ret
.ev_arg:
 mov eax,NEBO_TRAINER_E_ARGUMENT
 ret
.ev_limit:
 mov eax,NEBO_TRAINER_E_LIMIT
 ret
.ev_nonfinite:
 mov eax,NEBO_TRAINER_E_NONFINITE
 ret

nebo_trainer_cancel:
 test rdi,rdi
 jz .cancel_arg
 cmp qword [rdi],NEBO_TRAINER_STATE_CLOSED
 je .cancel_state
 mov rax,[rdi+64]
 test rax,rax
 jz .cancel_arg
 mov qword [rax],1
 xor eax,eax
 ret
.cancel_arg:
 mov eax,NEBO_TRAINER_E_ARGUMENT
 ret
.cancel_state:
 mov eax,NEBO_TRAINER_E_STATE
 ret

; rdi=trainer,rsi=Report40. Progress is observable during callbacks.
nebo_trainer_progress:
 test rdi,rdi
 jz .progress_arg
 test rsi,rsi
 jz .progress_arg
 cmp qword [rdi],NEBO_TRAINER_STATE_EMPTY
 je .progress_state
 mov rdx,NEBO_TRAINER_OUTCOME_COMPLETED
 call trainer_report
 xor eax,eax
 ret
.progress_arg:
 mov eax,NEBO_TRAINER_E_ARGUMENT
 ret
.progress_state:
 mov eax,NEBO_TRAINER_E_STATE
 ret

nebo_trainer_close:
 test rdi,rdi
 jz .close_arg
 cmp qword [rdi],NEBO_TRAINER_STATE_ACTIVE
 je .close_state
 cmp qword [rdi],NEBO_TRAINER_STATE_READY
 jne .close_state
 mov qword [rdi],NEBO_TRAINER_STATE_CLOSED
 mov qword [rdi+72],0
 mov qword [rdi+80],0
 inc qword [rdi+88]
 xor eax,eax
 ret
.close_arg:
 mov eax,NEBO_TRAINER_E_ARGUMENT
 ret
.close_state:
 mov eax,NEBO_TRAINER_E_STATE
 ret

; rdi=trainer,rsi=report,rdx=outcome.
trainer_report:
 mov rax,[rdi+8]
 mov [rsi],rax
 mov rax,[rdi+24]
 mov [rsi+8],rax
 movsd xmm0,[rdi+32]
 movsd [rsi+16],xmm0
 mov [rsi+24],rdx
 mov rax,[rdi+40]
 mov [rsi+32],rax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
