; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F04 bounded lexical Slice semantics over Array/Bytes owners.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/semantic/collections/slice_view.inc"

section .text

; create(request*, owner_record*, out_record**)
NEBOC_ABI_FUNCTION neboc_slice_create
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 test rdx,rdx
 jz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 mov rax,[r13+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rax,NEBOC_AR_KIND_ARRAY
 je .owner_kind
 cmp rax,NEBOC_AR_KIND_BYTES_OWNER
 jne .unavailable
.owner_kind:
 mov rax,r13
 sub rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 jc .internal
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 test rdx,rdx
 jnz .internal
 cmp rax,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .internal
 mov r15,rax
 call slice_alloc
 test rax,rax
 jz .done
 mov rbx,rax
 mov qword [rbx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 mov rax,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 mov [rbx+NEBOC_AR_BIND_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 mov [rbx+NEBOC_AR_BIND_COUNT_OFFSET],rax
 mov rax,[r13+NEBOC_AR_BIND_STRIDE_OFFSET]
 test rax,rax
 jz .internal
 mov [rbx+NEBOC_AR_BIND_STRIDE_OFFSET],rax
 mov qword [rbx+NEBOC_AR_BIND_SIZE_OFFSET],40
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 mov [rbx+NEBOC_AR_BIND_DATA_INDEX_OFFSET],rax
 mov [rbx+NEBOC_AR_BIND_START_OFFSET],r15
 mov rax,[r13+NEBOC_AR_BIND_START_OFFSET]
 test rax,rax
 jnz .generation_ready
 mov eax,1
 mov [r13+NEBOC_AR_BIND_START_OFFSET],rax
.generation_ready:
 mov [rbx+NEBOC_AR_BIND_END_OFFSET],rax
 mov rax,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 mov [rbx+NEBOC_AR_BIND_STEP_OFFSET],rax
 mov qword [rbx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_LIVE
 inc qword [r13+NEBOC_AR_BIND_END_OFFSET]
 jc .internal
 inc qword [r12+NEBOC_AR_CONSTRUCT_COUNT_OFFSET]
 mov [r14],rbx
 xor eax,eax
 jmp .done
.unavailable:
 mov esi,NEBOC_AR_DIAG_SLICE_UNAVAILABLE
 jmp .error
.internal:
 mov esi,NEBOC_AR_DIAG_INTERNAL
.error:
 call slice_error
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; subslice(request*, parent_slice*, start, end, out_record**)
NEBOC_ABI_FUNCTION neboc_slice_subslice
 test r8,r8
 jz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r8],0
 sub rsp,16
 mov [rsp],r8
 mov rdi,r12
 mov rsi,r13
 call neboc_slice_view_validate
 test eax,eax
 jnz .done
 cmp r14,r15
 ja .bounds
 cmp r15,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 ja .bounds
 mov rax,[r13+NEBOC_AR_BIND_START_OFFSET]
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp+8],rax
 call slice_alloc
 test rax,rax
 jz .done
 mov rbx,rax
 mov qword [rbx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 mov rax,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 mov [rbx+NEBOC_AR_BIND_TYPE_OFFSET],rax
 mov rax,r15
 sub rax,r14
 mov [rbx+NEBOC_AR_BIND_COUNT_OFFSET],rax
 mov rax,[r13+NEBOC_AR_BIND_STRIDE_OFFSET]
 mov [rbx+NEBOC_AR_BIND_STRIDE_OFFSET],rax
 mov qword [rbx+NEBOC_AR_BIND_SIZE_OFFSET],40
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,r14
 jc .bounds
 mov [rbx+NEBOC_AR_BIND_DATA_INDEX_OFFSET],rax
 mov rax,[r13+NEBOC_AR_BIND_START_OFFSET]
 mov [rbx+NEBOC_AR_BIND_START_OFFSET],rax
 mov rax,[r13+NEBOC_AR_BIND_END_OFFSET]
 mov [rbx+NEBOC_AR_BIND_END_OFFSET],rax
 mov rax,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 mov [rbx+NEBOC_AR_BIND_STEP_OFFSET],rax
 mov qword [rbx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_LIVE
 mov rax,[rsp+8]
 inc qword [rax+NEBOC_AR_BIND_END_OFFSET]
 jc .internal
 inc qword [r12+NEBOC_AR_CONSTRUCT_COUNT_OFFSET]
 mov rax,[rsp]
 mov [rax],rbx
 xor eax,eax
 jmp .done
.bounds:
 mov esi,NEBOC_AR_DIAG_BOUNDS
 jmp .error
.internal:
 mov esi,NEBOC_AR_DIAG_INTERNAL
.error:
 call slice_error
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

; validate(request*, slice_record*)
NEBOC_ABI_FUNCTION neboc_slice_view_validate
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 cmp qword [rsi+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .stale
 cmp qword [rsi+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_LIVE
 jne .stale
 mov rax,[rsi+NEBOC_AR_BIND_STRIDE_OFFSET]
 test rax,rax
 jz .stale
 mov rax,[rsi+NEBOC_AR_BIND_START_OFFSET]
 cmp rax,[rdi+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .stale
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[rdi+NEBOC_AR_BINDINGS_OFFSET]
 mov rcx,[rax+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rcx,NEBOC_AR_KIND_ARRAY
 je .owner
 cmp rcx,NEBOC_AR_KIND_BYTES_OWNER
 jne .stale
.owner:
 mov rcx,[rax+NEBOC_AR_BIND_START_OFFSET]
 cmp rcx,[rsi+NEBOC_AR_BIND_END_OFFSET]
 jne .stale
 cmp qword [rax+NEBOC_AR_BIND_END_OFFSET],0
 je .stale
 mov rax,[rsi+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,[rsi+NEBOC_AR_BIND_COUNT_OFFSET]
 jc .stale
 cmp rax,[rdi+NEBOC_AR_VALUE_COUNT_OFFSET]
 ja .stale
 xor eax,eax
 ret
.stale:
 mov esi,NEBOC_AR_DIAG_SLICE_STALE
 jmp slice_error
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; read(request*, slice*, index, out_value*)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_slice_read
 test rcx,rcx
 jz .invalid_direct
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov qword [rcx],0
 mov [rsp],rcx
 call neboc_slice_view_validate
 test eax,eax
 jnz .done
 cmp rbx,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .bounds
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,rbx
 jc .bounds
 mov rdx,[r12+NEBOC_AR_VALUES_OFFSET]
 mov rdx,[rdx+rax*8]
 mov rax,[rsp]
 mov [rax],rdx
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.bounds:
 mov esi,NEBOC_AR_DIAG_BOUNDS
 mov rdi,r12
 call slice_error
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; sum(request*, Int slice*, out_value*) -- bounded deterministic iteration.
%undef call
NEBOC_ABI_FUNCTION neboc_slice_sum
 test rdx,rdx
 jz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_slice_view_validate
 test eax,eax
 jnz .done
 cmp qword [r13+NEBOC_AR_BIND_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 jne .type
 xor ebx,ebx
 xor r15d,r15d
.loop:
 cmp rbx,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .store
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,rbx
 mov rdx,[r12+NEBOC_AR_VALUES_OFFSET]
 add r15,[rdx+rax*8]
 jo .range
 inc rbx
 jmp .loop
.store:
 mov [r14],r15
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.type:
 mov esi,NEBOC_AR_DIAG_TYPE
 jmp .error
.range:
 mov esi,NEBOC_AR_DIAG_RANGE
.error:
 mov rdi,r12
 call slice_error
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; release(request*, slice*)
NEBOC_ABI_FUNCTION neboc_slice_release
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 call neboc_slice_view_validate
 test eax,eax
 jnz .done
 mov rax,[r13+NEBOC_AR_BIND_START_OFFSET]
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [rax+NEBOC_AR_BIND_END_OFFSET],0
 je .internal
 dec qword [rax+NEBOC_AR_BIND_END_OFFSET]
 mov qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RELEASED
 xor eax,eax
 jmp .done
.internal:
 mov esi,NEBOC_AR_DIAG_INTERNAL
 mov rdi,r12
 call slice_error
.done:
 add rsp,8
 pop r13
 pop r12
 ret

; mutation_probe(request*, owner*) always rejects if a view is live.
NEBOC_ABI_FUNCTION neboc_slice_mutation_probe
 cmp qword [rsi+NEBOC_AR_BIND_END_OFFSET],0
 je .unavailable
 mov esi,NEBOC_AR_DIAG_SLICE_MUTATION_CONFLICT
 jmp slice_error
.unavailable:
 mov esi,NEBOC_AR_DIAG_SLICE_UNAVAILABLE
 jmp slice_error

; cleanup(request*) releases every still-live view in reverse record order.
NEBOC_ABI_FUNCTION neboc_slice_cleanup
 test rdi,rdi
 jz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov rbx,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
.loop:
 test rbx,rbx
 jz .done_ok
 dec rbx
 mov rax,rbx
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .loop
 cmp qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_LIVE
 jne .loop
 mov r13,rax
 mov r14,[r13+NEBOC_AR_BIND_START_OFFSET]
 cmp r14,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .internal
 imul r14,NEBOC_AR_BIND_SIZE
 add r14,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [r14+NEBOC_AR_BIND_END_OFFSET],0
 je .internal
 dec qword [r14+NEBOC_AR_BIND_END_OFFSET]
 mov qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RELEASED
 jmp .loop
.done_ok:
 xor eax,eax
 jmp .done
.internal:
 mov esi,NEBOC_AR_DIAG_INTERNAL
 mov rdi,r12
 call slice_error
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
slice_alloc:
 mov rax,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_AR_BINDING_CAPACITY_OFFSET]
 jae .limit
 mov rcx,rax
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 mov qword [rax+NEBOC_AR_BIND_NAME_OFFSET],NEBOC_AR_UNBOUND_NAME
 inc qword [r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 ret
.limit:
 mov esi,NEBOC_AR_DIAG_CONST_LENGTH
 mov rdi,r12
 call slice_error
 xor eax,eax
 ret

; RDI request, ESI diagnostic.
%undef call
slice_error:
 mov [rdi+NEBOC_AR_DIAGNOSTIC_OFFSET],rsi
 mov rax,[rdi+NEBOC_AR_CURSOR_OFFSET]
 mov [rdi+NEBOC_AR_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
