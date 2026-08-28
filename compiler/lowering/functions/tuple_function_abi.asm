; C07-F07 internal all-path Tuple merge and explicit caller-storage sret.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/functions/tuple_function_abi.inc"

section .text

; merge(request*) -> Status. Every reachable return path must carry an exact
; arity/type/layout/drop descriptor. The request and descriptors are bounded,
; caller-owned and contain no pointers to escaping Tuple elements.
NEBOC_ABI_FUNCTION neboc_tuple_function_merge
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 lea rdi,[r12+NEBOC_TFA_MERGED_ARITY_OFFSET]
 mov ecx,7
 xor eax,eax
 rep stosq
 mov r13,[r12+NEBOC_TFA_PATHS_OFFSET]
 test r13,r13
 jz .descriptor
 test r13,7
 jnz .descriptor
 mov r14,[r12+NEBOC_TFA_PATH_COUNT_OFFSET]
 test r14,r14
 jz .descriptor
 cmp r14,NEBOC_TFA_MAX_PATHS
 ja .descriptor
 mov r15,r13
 call validate_path
 test eax,eax
 jnz .done
 mov rax,[r15+NEBOC_TFA_PATH_ARITY_OFFSET]
 mov [r12+NEBOC_TFA_MERGED_ARITY_OFFSET],rax
 mov rax,[r15+NEBOC_TFA_PATH_SIZE_OFFSET]
 mov [r12+NEBOC_TFA_MERGED_SIZE_OFFSET],rax
 mov rax,[r15+NEBOC_TFA_PATH_ALIGN_OFFSET]
 mov [r12+NEBOC_TFA_MERGED_ALIGN_OFFSET],rax
 mov rax,[r15+NEBOC_TFA_PATH_DROP_COUNT_OFFSET]
 mov [r12+NEBOC_TFA_MERGED_DROP_COUNT_OFFSET],rax
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ebx,ebx
.hash_types:
 cmp rbx,[r15+NEBOC_TFA_PATH_ARITY_OFFSET]
 jae .hash_facts
 mov rcx,[r15+NEBOC_TFA_PATH_TYPES_OFFSET+rbx*8]
 xor rax,rcx
 imul rax,r8
 inc rbx
 jmp .hash_types
.hash_facts:
 xor rax,[r15+NEBOC_TFA_PATH_ARITY_OFFSET]
 imul rax,r8
 xor rax,[r15+NEBOC_TFA_PATH_SIZE_OFFSET]
 imul rax,r8
 xor rax,[r15+NEBOC_TFA_PATH_ALIGN_OFFSET]
 imul rax,r8
 xor rax,[r15+NEBOC_TFA_PATH_DROP_COUNT_OFFSET]
 imul rax,r8
 mov [r12+NEBOC_TFA_MERGED_TYPE_HASH_OFFSET],rax
 mov ebx,1
.path:
 cmp rbx,r14
 jae .success
 mov rax,rbx
 imul rax,NEBOC_TFA_PATH_SIZE
 lea r15,[r13+rax]
 call validate_path
 test eax,eax
 jnz .done
 mov rax,[r15+NEBOC_TFA_PATH_ARITY_OFFSET]
 cmp rax,[r12+NEBOC_TFA_MERGED_ARITY_OFFSET]
 jne .mismatch
 mov rax,[r15+NEBOC_TFA_PATH_SIZE_OFFSET]
 cmp rax,[r12+NEBOC_TFA_MERGED_SIZE_OFFSET]
 jne .mismatch
 mov rax,[r15+NEBOC_TFA_PATH_ALIGN_OFFSET]
 cmp rax,[r12+NEBOC_TFA_MERGED_ALIGN_OFFSET]
 jne .mismatch
 mov rax,[r15+NEBOC_TFA_PATH_DROP_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_TFA_MERGED_DROP_COUNT_OFFSET]
 jne .mismatch
 xor ecx,ecx
.type:
 cmp rcx,[r12+NEBOC_TFA_MERGED_ARITY_OFFSET]
 jae .next
 mov rax,[r15+NEBOC_TFA_PATH_TYPES_OFFSET+rcx*8]
 cmp rax,[r13+NEBOC_TFA_PATH_TYPES_OFFSET+rcx*8]
 jne .mismatch
 inc rcx
 jmp .type
.next:
 inc rbx
 jmp .path
.success:
 xor eax,eax
 jmp .done
.mismatch:
 mov qword [r12+NEBOC_TFA_DIAGNOSTIC_OFFSET],NEBOC_TFA_DIAG_PATH_MISMATCH
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.descriptor:
 mov qword [r12+NEBOC_TFA_DIAGNOSTIC_OFFSET],NEBOC_TFA_DIAG_INVALID_DESCRIPTOR
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; R15 path descriptor; return Status in EAX.
validate_path:
 mov rax,[r15+NEBOC_TFA_PATH_ARITY_OFFSET]
 cmp rax,NEBOC_TFA_MAX_ARITY
 ja .bad
 mov rax,[r15+NEBOC_TFA_PATH_SIZE_OFFSET]
 test rax,rax
 jz .bad
 cmp rax,NEBOC_TFA_MAX_SIZE
 ja .bad
 mov rax,[r15+NEBOC_TFA_PATH_ALIGN_OFFSET]
 test rax,rax
 jz .bad
 cmp rax,NEBOC_TFA_MAX_ALIGN
 ja .bad
 lea rdx,[rax-1]
 test rax,rdx
 jnz .bad
 cmp qword [r15+NEBOC_TFA_PATH_DROP_COUNT_OFFSET],NEBOC_TFA_MAX_DROP_LEAVES
 ja .bad
 xor ecx,ecx
.type:
 cmp rcx,[r15+NEBOC_TFA_PATH_ARITY_OFFSET]
 jae .ok
 cmp qword [r15+NEBOC_TFA_PATH_TYPES_OFFSET+rcx*8],0
 je .bad
 inc rcx
 jmp .type
.ok:
 xor eax,eax
 ret
.bad:
 mov qword [r12+NEBOC_TFA_DIAGNOSTIC_OFFSET],NEBOC_TFA_DIAG_INVALID_DESCRIPTOR
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; sret(request*) -> Status. Merge first, then copy exact bytes into a distinct,
; aligned caller-owned destination. Overlap is rejected rather than guessed.
NEBOC_ABI_FUNCTION neboc_tuple_function_sret
 test rdi,rdi
 jz .invalid_direct
 push r12
 mov r12,rdi
 call neboc_tuple_function_merge
 test eax,eax
 jnz .done
 mov rsi,[r12+NEBOC_TFA_SOURCE_OFFSET]
 mov rdi,[r12+NEBOC_TFA_DESTINATION_OFFSET]
 test rsi,rsi
 jz .invalid_storage
 test rdi,rdi
 jz .invalid_storage
 mov rdx,[r12+NEBOC_TFA_MERGED_ALIGN_OFFSET]
 dec rdx
 test rsi,rdx
 jnz .invalid_storage
 test rdi,rdx
 jnz .invalid_storage
 mov rcx,[r12+NEBOC_TFA_MERGED_SIZE_OFFSET]
 lea r8,[rsi+rcx]
 jc .invalid_storage
 lea r9,[rdi+rcx]
 jc .invalid_storage
 cmp rdi,r8
 jae .copy
 cmp rsi,r9
 jae .copy
 mov qword [r12+NEBOC_TFA_DIAGNOSTIC_OFFSET],NEBOC_TFA_DIAG_STORAGE_OVERLAP
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.copy:
 rep movsb
 mov rax,[r12+NEBOC_TFA_MERGED_SIZE_OFFSET]
 mov [r12+NEBOC_TFA_SRET_BYTES_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid_storage:
 mov qword [r12+NEBOC_TFA_DIAGNOSTIC_OFFSET],NEBOC_TFA_DIAG_INVALID_DESCRIPTOR
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
