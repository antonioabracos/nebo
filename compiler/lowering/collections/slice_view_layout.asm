; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F04 checked 40-byte borrowed Slice native substrate.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/collections/slice_view_layout.inc"

section .text

; owner_init(owner*, base, length, stride, generation)
NEBOC_ABI_FUNCTION neboc_slice_owner_init
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 test rdx,rdx
 jz .empty
 test rsi,rsi
 jz .invalid
.empty:
 mov [rdi+NEBOC_SLICE_OWNER_BASE_OFFSET],rsi
 mov [rdi+NEBOC_SLICE_OWNER_LENGTH_OFFSET],rdx
 mov [rdi+NEBOC_SLICE_OWNER_STRIDE_OFFSET],rcx
 mov [rdi+neboc_option_result_null_externo_e_erros_tipados_SLICE_OWNER_GENERATION_OFFSET],r8
 mov qword [rdi+NEBOC_SLICE_OWNER_BORROWS_OFFSET],0
 mov qword [rdi+NEBOC_SLICE_OWNER_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; create(slice*, owner*, start, end, token)
NEBOC_ABI_FUNCTION neboc_slice_view_create
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp qword [rsi+NEBOC_SLICE_OWNER_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rsi+NEBOC_SLICE_OWNER_BORROWS_OFFSET],-1
 je .bounds
 cmp rdx,rcx
 ja .bounds
 cmp rcx,[rsi+NEBOC_SLICE_OWNER_LENGTH_OFFSET]
 ja .bounds
 mov r9,rdx
 mov r10,rcx
 mov rax,[rsi+NEBOC_SLICE_OWNER_STRIDE_OFFSET]
 test rax,rax
 jz .invalid
 mul r9
 test rdx,rdx
 jnz .bounds
 add rax,[rsi+NEBOC_SLICE_OWNER_BASE_OFFSET]
 jc .bounds
 mov [rdi+NEBOC_SLICE_BASE_OFFSET],rax
 sub r10,r9
 mov [rdi+neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET],r10
 mov rax,[rsi+NEBOC_SLICE_OWNER_STRIDE_OFFSET]
 mov [rdi+NEBOC_SLICE_STRIDE_OFFSET],rax
 mov rax,[rsi+neboc_option_result_null_externo_e_erros_tipados_SLICE_OWNER_GENERATION_OFFSET]
 test rax,rax
 jz .invalid
 mov [rdi+NEBOC_SLICE_VIEW_LAYOUT_SLICE_GENERATION_OFFSET],rax
 mov [rdi+NEBOC_SLICE_TOKEN_OFFSET],r8
 inc qword [rsi+NEBOC_SLICE_OWNER_BORROWS_OFFSET]
 jc .bounds
 xor eax,eax
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.bounds:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; validate(slice*, owner*, token)
NEBOC_ABI_FUNCTION neboc_slice_view_validate
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rsi+NEBOC_SLICE_OWNER_ACTIVE_OFFSET],1
 jne .invalid
 cmp [rdi+NEBOC_SLICE_TOKEN_OFFSET],rdx
 jne .invalid
 mov rax,[rsi+neboc_option_result_null_externo_e_erros_tipados_SLICE_OWNER_GENERATION_OFFSET]
 cmp [rdi+NEBOC_SLICE_VIEW_LAYOUT_SLICE_GENERATION_OFFSET],rax
 jne .invalid
 cmp qword [rsi+NEBOC_SLICE_OWNER_BORROWS_OFFSET],0
 je .invalid
 mov rcx,[rdi+NEBOC_SLICE_STRIDE_OFFSET]
 test rcx,rcx
 jz .invalid
 cmp rcx,[rsi+NEBOC_SLICE_OWNER_STRIDE_OFFSET]
 jne .invalid
 mov rcx,[rdi+NEBOC_SLICE_BASE_OFFSET]
 cmp rcx,[rsi+NEBOC_SLICE_OWNER_BASE_OFFSET]
 jb .bounds
 mov rcx,[rdi+NEBOC_SLICE_STRIDE_OFFSET]
 mov rax,[rdi+neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET]
 mul rcx
 test rdx,rdx
 jnz .bounds
 add rax,[rdi+NEBOC_SLICE_BASE_OFFSET]
 jc .bounds
 mov r8,rax
 mov rax,[rsi+NEBOC_SLICE_OWNER_LENGTH_OFFSET]
 mul qword [rsi+NEBOC_SLICE_OWNER_STRIDE_OFFSET]
 test rdx,rdx
 jnz .bounds
 add rax,[rsi+NEBOC_SLICE_OWNER_BASE_OFFSET]
 jc .bounds
 cmp r8,rax
 ja .bounds
 xor eax,eax
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.bounds:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; at(slice*, owner*, token, index, out_pointer*)
NEBOC_ABI_FUNCTION neboc_slice_view_at
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
 mov rbx,r8
 call neboc_slice_view_validate
 test eax,eax
 jnz .done
 cmp r15,[r12+neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET]
 jae .bounds
 mov rax,[r12+NEBOC_SLICE_STRIDE_OFFSET]
 mul r15
 test rdx,rdx
 jnz .bounds
 add rax,[r12+NEBOC_SLICE_BASE_OFFSET]
 jc .bounds
 mov [rbx],rax
 xor eax,eax
 jmp .done
.bounds:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; subslice(out*, parent*, owner*, start, end), reuses the parent token.
NEBOC_ABI_FUNCTION neboc_slice_view_subslice
 test rdi,rdi
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
 mov rbx,r8
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r13+NEBOC_SLICE_TOKEN_OFFSET]
 call neboc_slice_view_validate
 test eax,eax
 jnz .done
 cmp r15,rbx
 ja .bounds
 cmp rbx,[r13+neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET]
 ja .bounds
 mov rax,[r13+NEBOC_SLICE_STRIDE_OFFSET]
 mul r15
 test rdx,rdx
 jnz .bounds
 add rax,[r13+NEBOC_SLICE_BASE_OFFSET]
 jc .bounds
 mov [r12+NEBOC_SLICE_BASE_OFFSET],rax
 mov rax,rbx
 sub rax,r15
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET],rax
 mov rax,[r13+NEBOC_SLICE_STRIDE_OFFSET]
 mov [r12+NEBOC_SLICE_STRIDE_OFFSET],rax
 mov rax,[r13+NEBOC_SLICE_VIEW_LAYOUT_SLICE_GENERATION_OFFSET]
 mov [r12+NEBOC_SLICE_VIEW_LAYOUT_SLICE_GENERATION_OFFSET],rax
 mov rax,[r13+NEBOC_SLICE_TOKEN_OFFSET]
 mov [r12+NEBOC_SLICE_TOKEN_OFFSET],rax
 xor eax,eax
 jmp .done
.bounds:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; release(slice*, owner*, token)
NEBOC_ABI_FUNCTION neboc_slice_view_release
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 call neboc_slice_view_validate
 test eax,eax
 jnz .done
 dec qword [r13+NEBOC_SLICE_OWNER_BORROWS_OFFSET]
 mov qword [r12+NEBOC_SLICE_TOKEN_OFFSET],0
 xor eax,eax
.done:
 add rsp,8
 pop r13
 pop r12
 ret

; mutate(owner*) rejects while any borrowed view is live, then advances gen.
NEBOC_ABI_FUNCTION neboc_slice_owner_mutate
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_SLICE_OWNER_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rdi+NEBOC_SLICE_OWNER_BORROWS_OFFSET],0
 jne .conflict
 inc qword [rdi+neboc_option_result_null_externo_e_erros_tipados_SLICE_OWNER_GENERATION_OFFSET]
 jz .invalid
 xor eax,eax
 ret
.conflict:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
