; IPO-F03 bounded proof-gated cross-module IPO model.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/optimizer/ipo.inc"
section .text
NEBOC_ABI_FUNCTION neboc_ipo_context_new
 ; rdi=context rsi=functions rdx=count rcx=limits r8=active capability.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_IPO_MAX_FUNCTIONS
 ja .limit
 test rcx,rcx
 jz .invalid
 cmp rdx,[rcx+NEBOC_IPO_LIMIT_FUNCTIONS_OFFSET]
 ja .limit
 cmp qword [rcx+NEBOC_IPO_LIMIT_GROWTH_OFFSET],0
 je .invalid
 mov r9,rdi
 mov r10,rcx
 xor eax,eax
 mov ecx,NEBOC_IPO_CONTEXT_SIZE/8
 rep stosq
 mov [r9+NEBOC_IPO_CONTEXT_FUNCTIONS_OFFSET],rsi
 mov [r9+NEBOC_IPO_CONTEXT_COUNT_OFFSET],rdx
 mov rax,[r10+NEBOC_IPO_LIMIT_GROWTH_OFFSET]
 mov [r9+NEBOC_IPO_CONTEXT_GROWTH_LIMIT_OFFSET],rax
 mov rax,[r10+NEBOC_IPO_LIMIT_INLINE_SIZE_OFFSET]
 mov [r9+NEBOC_IPO_CONTEXT_INLINE_LIMIT_OFFSET],rax
 mov rax,[r10+NEBOC_IPO_LIMIT_STACK_ALLOC_OFFSET]
 mov [r9+NEBOC_IPO_CONTEXT_STACK_LIMIT_OFFSET],rax
 mov rax,[r10+NEBOC_IPO_LIMIT_ITERATIONS_OFFSET]
 mov [r9+NEBOC_IPO_CONTEXT_ITERATIONS_OFFSET],rax
 mov [r9+NEBOC_IPO_CONTEXT_ACTIVE_CAP_OFFSET],r8
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Iterate helpers use r8=functions r9=index.
NEBOC_ABI_FUNCTION neboc_ipo_inline_across_modules
 ; rdi=context rsi=policy flag.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .done
 test qword [r8+16],NEBOC_IPO_FLAG_INTERNAL
 jz .next
 cmp qword [r8+24],0
 jne .next
 mov rax,[r8+32]
 cmp rax,[rdi+24]
 ja .next
 shr rax,1
 mov r10,[rdi+64]
 add r10,rax
 cmp r10,[rdi+16]
 ja .limit
 mov [rdi+64],r10
 or qword [r8+104],1
 inc qword [rdi+56]
.next: add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .loop
.done: xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_propagate_constants
 test rdi,rdi
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .done
 test qword [r8+16],NEBOC_IPO_FLAG_INTERNAL
 jz .next
 cmp qword [r8+40],0
 je .next
 or qword [r8+104],2
 inc qword [rdi+56]
.next: add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .loop
.done: xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_devirtualize_calls
 test rdi,rdi
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .done
 cmp qword [r8+48],1
 jne .next
 or qword [r8+104],4
 inc qword [rdi+56]
.next: add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .loop
.done: xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_escape_analysis
 test rdi,rdi
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .done
 test qword [r8+16],NEBOC_IPO_FLAG_NO_ESCAPE
 jz .escaping
 mov qword [r8+56],1
 jmp .mark
.escaping: mov qword [r8+56],2
.mark: or qword [r8+104],8
 inc qword [rdi+80]
 add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .loop
.done: xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_promote_allocation_to_stack
 test rdi,rdi
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .done
 cmp qword [r8+56],1
 jne .next
 mov rax,[r8+64]
 test rax,rax
 jz .next
 cmp rax,[rdi+32]
 ja .next
 or qword [r8+104],16
 add [rdi+72],rax
 inc qword [rdi+56]
.next: add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .loop
.done: xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_merge_equivalent_functions
 test rdi,rdi
 jz .invalid
 push rbx
 mov r8,[rdi]
 xor r9d,r9d
.outer:
 cmp r9,[rdi+8]
 jae .done
 test qword [r8+16],NEBOC_IPO_FLAG_INTERNAL
 jz .outer_next
 lea r10,[r9+1]
 lea r11,[r8+NEBOC_IPO_FUNC_SIZE]
.inner:
 cmp r10,[rdi+8]
 jae .outer_next
 test qword [r11+16],NEBOC_IPO_FLAG_INTERNAL
 jz .inner_next
 mov rax,[r8+72]
 cmp rax,[r11+72]
 jne .inner_next
 or qword [r11+104],32
 mov rax,[r11+32]
 add [rdi+72],rax
 inc qword [rdi+56]
.inner_next: add r11,NEBOC_IPO_FUNC_SIZE
 inc r10
 jmp .inner
.outer_next: add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .outer
.done: pop rbx
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_remove_unused_parameters
 test rdi,rdi
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .done
 mov rax,[r8+16]
 and eax,NEBOC_IPO_FLAG_INTERNAL|NEBOC_IPO_FLAG_CLOSED_CALLS
 cmp eax,NEBOC_IPO_FLAG_INTERNAL|NEBOC_IPO_FLAG_CLOSED_CALLS
 jne .next
 mov rax,[r8+80]
 sub rax,[r8+88]
 jbe .next
 or qword [r8+104],64
 add [rdi+72],rax
 inc qword [rdi+56]
.next: add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .loop
.done: xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_tail_call_transform
 ; rdi=context rsi=policy.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .done
 test qword [r8+16],NEBOC_IPO_FLAG_TAIL_SAFE
 jz .next
 or qword [r8+104],128
 inc qword [rdi+56]
.next: add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .loop
.done: xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_specialize_by_capability
 test rdi,rdi
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .done
 mov rax,[r8+96]
 test rax,rax
 jz .next
 cmp rax,[rdi+48]
 jne .next
 or qword [r8+104],256
 inc qword [rdi+56]
.next: add r8,NEBOC_IPO_FUNC_SIZE
 inc r9
 jmp .loop
.done: xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_verify
 ; rdi=context rsi=pass registry mask rdx=corpus digest.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rdi+64]
 cmp rax,[rdi+16]
 ja .failed
 mov qword [rdi+88],1
 xor eax,eax
 ret
.failed: mov qword [rdi+88],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ipo_report
 ; rdi=context rsi=5-qword report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+56]
 mov [rsi],rax
 mov rax,[rdi+64]
 mov [rsi+8],rax
 mov rax,[rdi+72]
 mov [rsi+16],rax
 mov rax,[rdi+80]
 mov [rsi+24],rax
 mov rax,[rdi+88]
 mov [rsi+32],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
