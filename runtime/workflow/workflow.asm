; OBSERVABILIDADE-EXPLAIN-DEBUG-SIMULACAO-E-EVOLUCAO-F03 durable logical workflow records and atomic checkpoints.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/workflow/workflow.inc"
section .text
NEBOC_ABI_FUNCTION nebo_workflow_checksum
 test rdi,rdi
 jz .invalid
 xor rax,rax
 xor ecx,ecx
.loop:
 cmp ecx,8
 jae .done
 xor rax,[rdi+rcx*8]
 inc ecx
 jmp .loop
.done: ret
.invalid: xor eax,eax
 ret

NEBOC_ABI_FUNCTION nebo_workflow_resume
 ; record, expected definition version
 test rdi,rdi
 jz .invalid
 mov rax,NEBO_WORKFLOW_MAGIC
 cmp [rdi],rax
 jne .invalid
 cmp [rdi+16],rsi
 jne .version
 push rdi
 call nebo_workflow_checksum
 pop rdi
 cmp rax,[rdi+64]
 jne .checksum
 xor eax,eax
 ret
.invalid: mov eax,NEBO_WORKFLOW_INVALID
 ret
.version: mov eax,NEBO_WORKFLOW_VERSION
 ret
.checksum: mov eax,NEBO_WORKFLOW_CHECKSUM
 ret

NEBOC_ABI_FUNCTION nebo_workflow_checkpoint
 ; source,out,expected_revision,new_step,new_timer,event_id
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,NEBO_WORKFLOW_MAGIC
 cmp [rdi],rax
 jne .invalid
 cmp [rdi+24],rdx
 jne .revision
 cmp [rdi+56],r9
 je .duplicate
 push rdi
 push rsi
 push rcx
 push r8
 push r9
 call nebo_workflow_checksum
 pop r9
 pop r8
 pop rcx
 pop rsi
 pop rdi
 cmp rax,[rdi+64]
 jne .checksum
 mov rax,[rdi]
 mov [rsi],rax
 mov rax,[rdi+8]
 mov [rsi+8],rax
 mov rax,[rdi+16]
 mov [rsi+16],rax
 mov rax,[rdi+24]
 inc rax
 mov [rsi+24],rax
 mov [rsi+32],rcx
 mov rax,[rdi+40]
 mov [rsi+40],rax
 mov [rsi+48],r8
 mov [rsi+56],r9
 push rsi
 mov rdi,rsi
 call nebo_workflow_checksum
 pop rsi
 mov [rsi+64],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBO_WORKFLOW_INVALID
 ret
.revision: mov eax,NEBO_WORKFLOW_REVISION
 ret
.duplicate: mov eax,NEBO_WORKFLOW_DUPLICATE
 ret
.checksum: mov eax,NEBO_WORKFLOW_CHECKSUM
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
