; Public noncapturing task callbacks reuse the native one-worker scheduler.
; The Int receiver is the child ordinal (zero for Task.spawn). No hidden
; thread or detached process is created. Future state is consumed exactly once.
bits 64
default rel
%include "runtime/concurrency/task.inc"
%include "runtime/concurrency/future.inc"
extern nebo_task_group_cancel
extern neboc_runtime_store_integer
extern nebo_runtime_trap_arithmetic_domain
global nebo_task_public
section .text
nebo_task_public:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r15,r8
 cmp ebx,40
 je .group
 cmp ebx,42
 je .single
 cmp ebx,41
 je .spawn
 cmp ebx,43
 je .join
 cmp ebx,44
 je .cancel
 cmp ebx,45
 je .await
 cmp ebx,46
 je .map
 cmp ebx,47
 jne .trap
 mov rdi,r12
 mov rsi,r13
 call nebo_future_select
 test eax,eax
 jnz .failed_future
 test edx,edx
 cmovnz r12,r13
 mov rsi,[r12+NEBO_FUTURE_VALUE]
 mov rdx,[r12+NEBO_FUTURE_ERROR]
 jmp .ready
.group:
 mov r12,r15
 call .init_group
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.single:
 lea r12,[r15+128]
 call .init_group
 test eax,eax
 jnz .trap
.spawn:
 mov r14,[r12+NEBO_TASK_GROUP_COUNT]
 cmp r14,64
 jae .limit
 mov rax,r14
 shl rax,4
 lea rcx,[r12+rax+4224]
 mov [rcx],r13
 mov [rcx+8],r14
 mov rax,r14
 shl rax,6
 lea rsi,[r12+rax+128]
 mov [rsp],rsi
 mov rdi,r12
 lea rdx,[rel task_public_callback]
 call nebo_task_group_spawn
 test eax,eax
 jnz .failed_future
 cmp ebx,42
 jne .child_result
 mov rdi,r12
 call nebo_task_group_join_all
 test eax,eax
 jnz .failed_future
.child_result:
 mov rax,[rsp]
 mov rsi,[rax+NEBO_TASK_RESULT]
 mov rdx,[rax+NEBO_TASK_ERROR]
 jmp .ready
.limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
.failed_future:
 mov edx,eax
 xor esi,esi
.ready:
 mov [rsp],rsi
 mov [rsp+8],rdx
 mov rdi,r15
 mov esi,64
 call nebo_future_init
 test eax,eax
 jnz .trap
 mov rdi,r15
 mov rsi,[rsp]
 mov rdx,[rsp+8]
 call nebo_future_complete
 test eax,eax
 jnz .trap
 mov rax,r15
 jmp .done
.join:
 mov rdi,r12
 call nebo_task_group_join_all
 jmp .result
.cancel:
 mov rdi,r12
 call nebo_task_group_cancel
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.await:
 mov rdi,r12
 call nebo_task_await
 test eax,eax
 jnz .result
 mov eax,r8d
 jmp .result
.map:
 ; Mapping an error does not invoke the source callback.
 cmp qword [r12+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_READY
 jne .transition
 cmp qword [r12+NEBO_FUTURE_ERROR],0
 jne .copy_error
 mov rdi,r15
 mov rsi,r12
 mov rdx,r13
 mov ecx,64
 call nebo_future_map
 test eax,eax
 jnz .failed_future
 mov rax,r15
 jmp .done
.copy_error:
 mov rsi,[r12+NEBO_FUTURE_VALUE]
 mov rdx,[r12+NEBO_FUTURE_ERROR]
 jmp .ready
.transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 jmp .failed_future
.result:
 xor esi,esi
 test eax,eax
 jz .store
 mov esi,1
 mov edx,eax
.store:
 mov rdi,r15
 call neboc_runtime_store_integer
 mov rax,r15
 jmp .done
.init_group:
 sub rsp,8
 mov rdi,r12
 xor eax,eax
 mov ecx,5248/8
 rep stosq
 lea rdi,[r12+64]
 mov esi,1
 mov edx,64
 mov ecx,64
 xor r8d,r8d
 mov r9d,64
 call nebo_scheduler_budget_init
 test eax,eax
 jnz .init_done
 mov rdi,r12
 lea rsi,[r12+64]
 lea rdx,[r12+128]
 mov ecx,64
 call nebo_task_group_init
.init_done:
 add rsp,8
 ret
.trap:
 jmp nebo_runtime_trap_arithmetic_domain
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
task_public_callback:
 sub rsp,8
 mov rax,[rdi]
 mov rdi,[rdi+8]
 call rax
 xor edx,edx
 add rsp,8
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
