bits 64
default rel
%include "runtime/distributed/remote_task.inc"
extern nebo_remote_task_init,nebo_remote_task_submit,nebo_remote_task_update
section .bss
state resb NEBO_REMOTE_STATE_SIZE
entries resb NEBO_REMOTE_TASK_SIZE*2
task resb NEBO_REMOTE_TASK_SIZE
init_req resb NEBO_REMOTE_INIT_SIZE
submit_req resb NEBO_REMOTE_SUBMIT_SIZE
update_req resb NEBO_REMOTE_UPDATE_SIZE
section .text
global _start
_start:
 lea rax,[state]
 mov [init_req+NEBO_REMOTE_INIT_STATE],rax
 lea rax,[entries]
 mov [init_req+NEBO_REMOTE_INIT_ENTRIES],rax
 mov qword [init_req+NEBO_REMOTE_INIT_CAPACITY],2
 mov qword [init_req+NEBO_REMOTE_INIT_OWNER],0x2607
 mov qword [init_req+NEBO_REMOTE_INIT_CAPABILITY],0xcafe
 lea rdi,[init_req]
 call nebo_remote_task_init
 test eax,eax
 jnz fail
 mov qword [task+NEBO_REMOTE_TASK_ID],1
 mov qword [task+NEBO_REMOTE_TASK_KEY],0xabc
 mov qword [task+NEBO_REMOTE_TASK_FUNCTION],1
 mov qword [task+NEBO_REMOTE_TASK_SCHEMA],1
 mov qword [task+NEBO_REMOTE_TASK_PROVENANCE],0x123
 mov qword [task+NEBO_REMOTE_TASK_PARTITION],7
 mov qword [task+NEBO_REMOTE_TASK_REPLICAS],2
 lea rax,[state]
 mov [submit_req+NEBO_REMOTE_SUBMIT_STATE],rax
 lea rax,[task]
 mov [submit_req+NEBO_REMOTE_SUBMIT_TASK],rax
 mov qword [submit_req+NEBO_REMOTE_SUBMIT_CAPABILITY],0xcafe
 lea rdi,[submit_req]
 call nebo_remote_task_submit
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_REMOTE_ST_COUNT],1
 jne fail
 lea rdi,[submit_req]
 call nebo_remote_task_submit
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_REMOTE_ST_COUNT],1
 jne fail
 mov qword [task+NEBO_REMOTE_TASK_ID],2
 lea rdi,[submit_req]
 call nebo_remote_task_submit
 cmp eax,NEBO_REMOTE_STATUS_DUPLICATE
 jne fail
 mov qword [task+NEBO_REMOTE_TASK_ID],1
 mov qword [task+NEBO_REMOTE_TASK_FUNCTION],33
 lea rdi,[submit_req]
 call nebo_remote_task_submit
 cmp eax,NEBO_REMOTE_STATUS_UNKNOWN_FUNCTION
 jne fail
 mov qword [task+NEBO_REMOTE_TASK_FUNCTION],1
 mov qword [task+NEBO_REMOTE_TASK_FLAGS],1
 lea rdi,[submit_req]
 call nebo_remote_task_submit
 cmp eax,NEBO_REMOTE_STATUS_CODE_SHIPPING
 jne fail
 mov qword [task+NEBO_REMOTE_TASK_FLAGS],0
 mov qword [task+NEBO_REMOTE_TASK_PROVENANCE],0
 lea rdi,[submit_req]
 call nebo_remote_task_submit
 cmp eax,NEBO_REMOTE_STATUS_PROVENANCE
 jne fail
 mov qword [task+NEBO_REMOTE_TASK_PROVENANCE],0x123
 lea rax,[state]
 mov [update_req+NEBO_REMOTE_UPDATE_STATE],rax
 mov qword [update_req+NEBO_REMOTE_UPDATE_KEY],0xabc
 mov qword [update_req+NEBO_REMOTE_UPDATE_CAPABILITY],0xcafe
 mov qword [update_req+NEBO_REMOTE_UPDATE_NEW_STATE],NEBO_REMOTE_STATE_CANCELLED
 lea rdi,[update_req]
 call nebo_remote_task_update
 test eax,eax
 jnz fail
 cmp qword [entries+NEBO_REMOTE_TASK_STATE],NEBO_REMOTE_STATE_CANCELLED
 jne fail
 lea rdi,[update_req]
 call nebo_remote_task_update
 cmp eax,NEBO_REMOTE_STATUS_STATE
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
