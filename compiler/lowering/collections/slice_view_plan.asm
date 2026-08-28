; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F04 pointerless authenticated internal Slice lowering plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/semantic/collections/slice_view.inc"
%include "compiler/lowering/collections/slice_view_plan.inc"

section .text

NEBOC_ABI_FUNCTION neboc_slice_lower
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
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 cmp qword [r12+NEBOC_AR_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_AR_DIAGNOSTIC_OFFSET],0
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_SLICE_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,NEBOC_SLICE_PLAN_MAGIC
 mov [r13+NEBOC_SLICE_PLAN_MAGIC_OFFSET],rax
 mov rax,NEBOC_SLICE_LAYOUT_ID
 mov [r13+NEBOC_SLICE_PLAN_LAYOUT_ID_OFFSET],rax
 mov rax,[r12+NEBOC_AR_SEMANTIC_HASH_OFFSET]
 mov [r13+NEBOC_SLICE_PLAN_BASE_SEMANTIC_HASH_OFFSET],rax
 mov r14,14695981039346656037
 mov r15,1099511628211
 xor ebx,ebx
.scan:
 cmp rbx,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .scanned
 mov rax,rbx
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .next
 ; NPT-LANG-32 B01: an authenticated S04-derived record is a compiler-only
 ; borrowed provenance fact. It is lowered by the function sret path and is
 ; not a callee-owned local Array view requiring release in this legacy plan.
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_S04_DERIVED
 jnz .next
 cmp qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RELEASED
 jne .source
 mov rcx,[rax+NEBOC_AR_BIND_START_OFFSET]
 cmp rcx,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .source
 mov rdx,rcx
 imul rdx,NEBOC_AR_BIND_SIZE
 add rdx,[r12+NEBOC_AR_BINDINGS_OFFSET]
 mov r8,[rdx+NEBOC_AR_BIND_KIND_OFFSET]
 cmp r8,NEBOC_AR_KIND_ARRAY
 je .owner
 cmp r8,NEBOC_AR_KIND_BYTES_OWNER
 jne .source
.owner:
 cmp qword [rdx+NEBOC_AR_BIND_END_OFFSET],0
 jne .source
 mov r8,[rdx+NEBOC_AR_BIND_START_OFFSET]
 cmp r8,[rax+NEBOC_AR_BIND_END_OFFSET]
 jne .source
 xor r14,rcx
 imul r14,r15
 xor r14,r8
 imul r14,r15
 xor r14,[rax+NEBOC_AR_BIND_STEP_OFFSET]
 imul r14,r15
 xor r14,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 imul r14,r15
 xor r14,[rax+NEBOC_AR_BIND_STRIDE_OFFSET]
 imul r14,r15
 xor r14,[rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 imul r14,r15
 inc qword [r13+NEBOC_SLICE_PLAN_VIEW_COUNT_OFFSET]
.next:
 inc rbx
 jmp .scan
.scanned:
 mov rax,[r13+NEBOC_SLICE_PLAN_VIEW_COUNT_OFFSET]
 test rax,rax
 jz .no_slice
 cmp rax,NEBOC_SLICE_MAX_VIEWS
 ja .source
 mov qword [r13+NEBOC_SLICE_PLAN_FOUND_OFFSET],1
 mov [r13+NEBOC_SLICE_PLAN_RELEASE_COUNT_OFFSET],rax
 mov [r13+NEBOC_SLICE_PLAN_VIEW_HASH_OFFSET],r14
 mov rax,[r12+NEBOC_AR_RESULT_TYPE_OFFSET]
 mov [r13+NEBOC_SLICE_PLAN_RESULT_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_AR_RESULT_VALUE_OFFSET]
 mov [r13+NEBOC_SLICE_PLAN_RESULT_VALUE_OFFSET],rax
 mov qword [r13+NEBOC_SLICE_PLAN_LAYOUT_SIZE_OFFSET],40
 mov qword [r13+NEBOC_SLICE_PLAN_LAYOUT_ALIGN_OFFSET],8
.no_slice:
 mov rdi,r13
 mov ecx,NEBOC_SLICE_PLAN_HASHED_BYTES
 call hash_bytes
 mov [r13+NEBOC_SLICE_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
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

hash_bytes:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rdi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
