; TIPOS-PRIMITIVOS-ESCALARES-F04 signed-i64 bit-pattern lowering
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/textual/int_bits_lowering.inc"

section .text
NEBOC_ABI_FUNCTION neboc_int_bits_lower
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_INT_BITS_RESULT_OFFSET],0
 mov qword [rdi+NEBOC_INT_BITS_ERROR_OFFSET],NEBOC_INT_BITS_ERROR_NONE
 mov rax,[rdi+NEBOC_INT_BITS_RECEIVER_OFFSET]
 mov rcx,[rdi+NEBOC_INT_BITS_ARGUMENT_OFFSET]
 mov rdx,[rdi+NEBOC_INT_BITS_OPERATION_OFFSET]
 cmp rdx,NEBOC_INT_BITS_AND
 je .and
 cmp rdx,NEBOC_INT_BITS_OR
 je .or
 cmp rdx,NEBOC_INT_BITS_XOR
 je .xor
 cmp rdx,NEBOC_INT_BITS_NOT
 je .not
 cmp rdx,NEBOC_INT_BITS_SHIFT_LEFT
 je .shift_left
 cmp rdx,NEBOC_INT_BITS_SHIFT_RIGHT
 je .shift_right
 cmp rdx,NEBOC_INT_BITS_TEST_BIT
 je .test_bit
 cmp rdx,NEBOC_INT_BITS_WITH_BIT
 je .with_bit
 mov qword [rdi+NEBOC_INT_BITS_ERROR_OFFSET],NEBOC_INT_BITS_ERROR_OPERATION
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.and: and rax,rcx
 jmp .ok
.or: or rax,rcx
 jmp .ok
.xor: xor rax,rcx
 jmp .ok
.not: not rax
 jmp .ok
.shift_left:
 cmp rcx,63
 ja .range
 shl rax,cl
 jmp .ok
.shift_right:
 cmp rcx,63
 ja .range
 sar rax,cl
 jmp .ok
.test_bit:
 cmp rcx,63
 ja .range
 bt rax,rcx
 setc al
 movzx rax,al
 jmp .ok
.with_bit:
 cmp rcx,63
 ja .range
 mov rdx,[rdi+NEBOC_INT_BITS_ENABLED_OFFSET]
 cmp rdx,1
 ja .enabled
 test rdx,rdx
 jz .clear
 bts rax,rcx
 jmp .ok
.clear:
 btr rax,rcx
 jmp .ok
.range:
 mov qword [rdi+NEBOC_INT_BITS_ERROR_OFFSET],NEBOC_INT_BITS_ERROR_RANGE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.enabled:
 mov qword [rdi+NEBOC_INT_BITS_ERROR_OFFSET],NEBOC_INT_BITS_ERROR_ENABLED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.ok:
 mov [rdi+NEBOC_INT_BITS_RESULT_OFFSET],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
