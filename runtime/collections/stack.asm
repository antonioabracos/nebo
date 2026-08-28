; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-F04 bounded Stack facade over the F02 List substrate.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_list_pop
extern neboc_list_at
extern neboc_list_clear
extern neboc_list_is_empty
extern neboc_list_validate
section .text
NEBOC_ABI_FUNCTION neboc_stack_init
 jmp neboc_list_init
NEBOC_ABI_FUNCTION neboc_stack_push
 jmp neboc_list_push
NEBOC_ABI_FUNCTION neboc_stack_pop
 jmp neboc_list_pop
NEBOC_ABI_FUNCTION neboc_stack_clear
 jmp neboc_list_clear
NEBOC_ABI_FUNCTION neboc_stack_is_empty
 jmp neboc_list_is_empty
; stack_peek(desc*, out*, found*)
NEBOC_ABI_FUNCTION neboc_stack_peek
 test rsi,rsi
 jz .peek_invalid
 test rdx,rdx
 jz .peek_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_list_validate
 test eax,eax
 jnz .peek_done
 mov rsi,[r12+NEBOC_LIST_LENGTH_OFFSET]
 test rsi,rsi
 jz .peek_ok
 dec rsi
 mov rdi,r12
 mov rdx,r13
 call neboc_list_at
 test eax,eax
 jnz .peek_done
 mov qword [r14],1
.peek_ok:
 xor eax,eax
.peek_done:
 pop r14
 pop r13
 pop r12
 ret
.peek_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
; stack_length(desc*, out*)
NEBOC_ABI_FUNCTION neboc_stack_length
 test rsi,rsi
 jz .length_invalid
 push r12
 mov r12,rsi
 call neboc_list_validate
 test eax,eax
 jnz .length_done
 mov rax,[rdi+NEBOC_LIST_LENGTH_OFFSET]
 mov [r12],rax
 xor eax,eax
.length_done:
 pop r12
 ret
.length_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
