; Nebo Assembly — bounded Linux system allocator with explicit ownership.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/memory/system_allocator.inc"

section .text

NEBOC_ABI_FUNCTION neboc_system_allocator_init
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 mov rax,NEBOC_SYSTEM_ALLOCATOR_MAGIC
 mov [rdi+NEBOC_SYSTEM_ALLOCATOR_MAGIC_OFFSET],rax
 mov qword [rdi+NEBOC_SYSTEM_ALLOCATOR_LIVE_OFFSET],0
 mov qword [rdi+NEBOC_SYSTEM_ALLOCATOR_BYTES_OFFSET],0
 call system_allocator_hash
 mov [rdi+NEBOC_SYSTEM_ALLOCATOR_HASH_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; allocate(allocator*, layout*, block*) -> Status. Each block has an independent
; mmap mapping, which makes deallocation exact and keeps failure atomic.
NEBOC_ABI_FUNCTION neboc_system_allocator_allocate
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 test rdx,rdx
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 test rsi,7
 jnz .invalid_direct
 test rdx,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 call system_allocator_validate
 test eax,eax
 jz .internal
 mov rdi,r14
 mov ecx,NEBOC_SYSTEM_BLOCK_QWORDS
 xor eax,eax
 rep stosq
 mov rbx,[r13+NEBOC_SYSTEM_LAYOUT_SIZE_OFFSET]
 mov r15,[r13+NEBOC_SYSTEM_LAYOUT_ALIGNMENT_OFFSET]
 test rbx,rbx
 jz .layout
 cmp rbx,NEBOC_SYSTEM_ALLOCATOR_MAX_REQUEST
 ja .layout
 test r15,r15
 jz .layout
 cmp r15,NEBOC_SYSTEM_ALLOCATOR_MAX_ALIGNMENT
 ja .layout
 mov rax,r15
 dec rax
 test r15,rax
 jnz .layout
 mov rax,rbx
 add rax,r15
 jc .layout
 dec rax
 mov [rsp],rax
 ; mmap(NULL, mapping_length, PROT_READ|PROT_WRITE,
 ;      MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)
 mov rsi,rax
 xor edi,edi
 mov edx,3
 mov r10d,0x22
 mov r8,-1
 xor r9d,r9d
 mov eax,9
 syscall
 cmp rax,-4095
 jae .oom
 mov [r14+NEBOC_SYSTEM_BLOCK_MAPPING_OFFSET],rax
 mov rcx,rax
 mov rdx,r15
 dec rdx
 add rcx,rdx
 not rdx
 and rcx,rdx
 mov qword [r14+NEBOC_SYSTEM_BLOCK_TAG_OFFSET],NEBOC_SYSTEM_BLOCK_OK
 mov qword [r14+NEBOC_SYSTEM_BLOCK_DIAGNOSTIC_OFFSET],0
 mov [r14+NEBOC_SYSTEM_BLOCK_POINTER_OFFSET],rcx
 mov rdx,[rsp]
 mov [r14+NEBOC_SYSTEM_BLOCK_MAPPING_LENGTH_OFFSET],rdx
 mov [r14+NEBOC_SYSTEM_BLOCK_SIZE_OFFSET],rbx
 mov [r14+NEBOC_SYSTEM_BLOCK_ALIGNMENT_OFFSET],r15
 mov qword [r14+NEBOC_SYSTEM_BLOCK_STATE_OFFSET],NEBOC_SYSTEM_BLOCK_LIVE
 inc qword [r12+NEBOC_SYSTEM_ALLOCATOR_LIVE_OFFSET]
 add [r12+NEBOC_SYSTEM_ALLOCATOR_BYTES_OFFSET],rbx
 mov rdi,r12
 call system_allocator_hash
 mov [r12+NEBOC_SYSTEM_ALLOCATOR_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.layout:
 mov qword [r14+NEBOC_SYSTEM_BLOCK_TAG_OFFSET],NEBOC_SYSTEM_BLOCK_ERR
 mov qword [r14+NEBOC_SYSTEM_BLOCK_DIAGNOSTIC_OFFSET],NEBOC_SYSTEM_ALLOCATOR_DIAG_LAYOUT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.oom:
 mov qword [r14+NEBOC_SYSTEM_BLOCK_TAG_OFFSET],NEBOC_SYSTEM_BLOCK_ERR
 mov qword [r14+NEBOC_SYSTEM_BLOCK_DIAGNOSTIC_OFFSET],NEBOC_SYSTEM_ALLOCATOR_DIAG_OUT_OF_MEMORY
 mov eax,NEBOC_STATUS_OUT_OF_MEMORY
 jmp .done
.internal:
 mov qword [r14+NEBOC_SYSTEM_BLOCK_TAG_OFFSET],NEBOC_SYSTEM_BLOCK_ERR
 mov qword [r14+NEBOC_SYSTEM_BLOCK_DIAGNOSTIC_OFFSET],NEBOC_SYSTEM_ALLOCATOR_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; deallocate(allocator*, block*) -> Status. The allocator state changes only
; after munmap succeeds; a second call is a deterministic double-drop error.
NEBOC_ABI_FUNCTION neboc_system_allocator_deallocate
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 test rsi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 call system_allocator_validate
 test eax,eax
 jz .internal
 cmp qword [r13+NEBOC_SYSTEM_BLOCK_STATE_OFFSET],NEBOC_SYSTEM_BLOCK_RELEASED
 je .double_drop
 cmp qword [r13+NEBOC_SYSTEM_BLOCK_TAG_OFFSET],NEBOC_SYSTEM_BLOCK_OK
 jne .invalid
 cmp qword [r13+NEBOC_SYSTEM_BLOCK_STATE_OFFSET],NEBOC_SYSTEM_BLOCK_LIVE
 jne .invalid
 mov rdi,[r13+NEBOC_SYSTEM_BLOCK_MAPPING_OFFSET]
 mov rsi,[r13+NEBOC_SYSTEM_BLOCK_MAPPING_LENGTH_OFFSET]
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 ; Authenticate accounting before the irreversible unmap. No allocator or
 ; block field is changed when these preconditions fail.
 cmp qword [r12+NEBOC_SYSTEM_ALLOCATOR_LIVE_OFFSET],0
 je .internal
 mov rbx,[r13+NEBOC_SYSTEM_BLOCK_SIZE_OFFSET]
 cmp [r12+NEBOC_SYSTEM_ALLOCATOR_BYTES_OFFSET],rbx
 jb .internal
 mov eax,11
 syscall
 test rax,rax
 jnz .internal
 dec qword [r12+NEBOC_SYSTEM_ALLOCATOR_LIVE_OFFSET]
 sub [r12+NEBOC_SYSTEM_ALLOCATOR_BYTES_OFFSET],rbx
 mov qword [r13+NEBOC_SYSTEM_BLOCK_STATE_OFFSET],NEBOC_SYSTEM_BLOCK_RELEASED
 mov qword [r13+NEBOC_SYSTEM_BLOCK_POINTER_OFFSET],0
 mov rdi,r12
 call system_allocator_hash
 mov [r12+NEBOC_SYSTEM_ALLOCATOR_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.double_drop:
 mov qword [r13+NEBOC_SYSTEM_BLOCK_TAG_OFFSET],NEBOC_SYSTEM_BLOCK_ERR
 mov qword [r13+NEBOC_SYSTEM_BLOCK_DIAGNOSTIC_OFFSET],NEBOC_SYSTEM_ALLOCATOR_DIAG_DOUBLE_DROP
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

system_allocator_validate:
 mov rax,NEBOC_SYSTEM_ALLOCATOR_MAGIC
 cmp [rdi+NEBOC_SYSTEM_ALLOCATOR_MAGIC_OFFSET],rax
 jne .no
 push rdi
 call system_allocator_hash
 pop rdi
 cmp rax,[rdi+NEBOC_SYSTEM_ALLOCATOR_HASH_OFFSET]
 sete al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

system_allocator_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 mov rcx,[rdi+NEBOC_SYSTEM_ALLOCATOR_MAGIC_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SYSTEM_ALLOCATOR_LIVE_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SYSTEM_ALLOCATOR_BYTES_OFFSET]
 xor rax,rcx
 imul rax,r8
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
