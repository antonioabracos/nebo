; Nebo Assembly — MF022 fundamental operator typing and checked Int constants
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/operators/operator_rules.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

section .text
extern neboc_operator_resolve_builtin_type
extern neboc_core_checked_power
extern neboc_core_ordering_type

; operator_unary_type(operator_token_kind, operand_type_id, out_type_id*)
NEBOC_ABI_FUNCTION neboc_operator_unary_type
 test rdx,rdx
 jz .unary_invalid
 mov qword [rdx],0
 cmp rdi,NEBOC_TOKEN_MINUS
 je .unary_negate
 cmp rdi,NEBOC_TOKEN_BANG
 je .unary_not
 jmp .unary_mismatch
.unary_negate:
 mov edi,NEBOC_OPERATOR_PROTOCOL_NEGATE
 jmp .unary_resolve
.unary_not:
 mov edi,NEBOC_OPERATOR_PROTOCOL_LOGICAL_NOT
.unary_resolve:
 mov rcx,rdx
 xor edx,edx
 sub rsp,8
 call neboc_operator_resolve_builtin_type
 add rsp,8
 ret
.unary_mismatch:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.unary_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; operator_binary_type(operator_token_kind, left_type_id, right_type_id,
;                      out_type_id*)
NEBOC_ABI_FUNCTION neboc_operator_binary_type
 test rcx,rcx
 jz .binary_invalid
 mov qword [rcx],0
 cmp rdi,NEBOC_TOKEN_PLUS
 je .binary_add
 cmp rdi,NEBOC_TOKEN_MINUS
 je .binary_subtract
 cmp rdi,NEBOC_TOKEN_STAR
 je .binary_multiply
 cmp rdi,NEBOC_TOKEN_SLASH
 je .binary_divide
 cmp rdi,NEBOC_TOKEN_PERCENT
 je .binary_remainder
 cmp rdi,NEBOC_TOKEN_CARET
 je .binary_power
 cmp rdi,NEBOC_TOKEN_XOR
 je .binary_xor
 cmp rdi,NEBOC_TOKEN_SPACESHIP
 je .binary_spaceship
 cmp rdi,NEBOC_TOKEN_LESS
 je .binary_order
 cmp rdi,NEBOC_TOKEN_LESS_EQUAL
 je .binary_order
 cmp rdi,NEBOC_TOKEN_GREATER
 je .binary_order
 cmp rdi,NEBOC_TOKEN_GREATER_EQUAL
 je .binary_order
 cmp rdi,NEBOC_TOKEN_AND_AND
 je .binary_and
 cmp rdi,NEBOC_TOKEN_OR_OR
 je .binary_or
 cmp rdi,NEBOC_TOKEN_EQUAL_EQUAL
 je .binary_equal
 cmp rdi,NEBOC_TOKEN_BANG_EQUAL
 je .binary_equal
 jmp .binary_mismatch
.binary_add:
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 jmp .binary_resolve
.binary_subtract:
 mov edi,NEBOC_OPERATOR_PROTOCOL_SUBTRACT
 jmp .binary_resolve
.binary_multiply:
 mov edi,NEBOC_OPERATOR_PROTOCOL_MULTIPLY
 jmp .binary_resolve
.binary_divide:
 mov edi,NEBOC_OPERATOR_PROTOCOL_DIVIDE
 jmp .binary_resolve
.binary_remainder:
 mov edi,NEBOC_OPERATOR_PROTOCOL_REMAINDER
 jmp .binary_resolve
.binary_power:
 mov edi,NEBOC_OPERATOR_PROTOCOL_POWER
 jmp .binary_resolve
.binary_xor:
 mov edi,NEBOC_OPERATOR_PROTOCOL_XOR
 jmp .binary_resolve
.binary_spaceship:
 mov rdi,rsi
 mov rsi,rdx
 mov rdx,rcx
 jmp neboc_core_ordering_type
.binary_order:
 mov edi,NEBOC_OPERATOR_PROTOCOL_ORDER
 jmp .binary_resolve
.binary_and:
 mov edi,NEBOC_OPERATOR_PROTOCOL_LOGICAL_AND
 jmp .binary_resolve
.binary_or:
 mov edi,NEBOC_OPERATOR_PROTOCOL_LOGICAL_OR
 jmp .binary_resolve
.binary_equal:
 mov edi,NEBOC_OPERATOR_PROTOCOL_EQUAL
.binary_resolve:
 sub rsp,8
 call neboc_operator_resolve_builtin_type
 add rsp,8
 ret
.binary_mismatch:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.binary_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; checked_int_unary(operator_token_kind, value, out_value*)
; LIMIT_EXCEEDED means checked overflow.
NEBOC_ABI_FUNCTION neboc_checked_int_unary
 test rdx,rdx
 jz .checked_unary_invalid
 mov qword [rdx],0
 cmp rdi,NEBOC_TOKEN_MINUS
 jne .checked_unary_invalid
 mov rax,rsi
 neg rax
 jo .checked_unary_overflow
 mov [rdx],rax
 xor eax,eax
 ret
.checked_unary_overflow:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.checked_unary_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; checked_int_binary(operator_token_kind, left_value, right_value, out_value*)
; LIMIT_EXCEEDED means checked overflow. INVALID_SOURCE means division by zero.
NEBOC_ABI_FUNCTION neboc_checked_int_binary
 push rbx
 mov rbx,rcx
 test rbx,rbx
 jz .checked_invalid
 mov qword [rbx],0
 cmp rdi,NEBOC_TOKEN_PLUS
 je .checked_add
 cmp rdi,NEBOC_TOKEN_MINUS
 je .checked_sub
 cmp rdi,NEBOC_TOKEN_STAR
 je .checked_mul
 cmp rdi,NEBOC_TOKEN_SLASH
 je .checked_div
 cmp rdi,NEBOC_TOKEN_PERCENT
 je .checked_mod
 cmp rdi,NEBOC_TOKEN_CARET
 je .checked_power
 cmp rdi,NEBOC_TOKEN_XOR
 je .checked_xor
 cmp rdi,NEBOC_TOKEN_LESS
 je .checked_less
 cmp rdi,NEBOC_TOKEN_LESS_EQUAL
 je .checked_less_equal
 cmp rdi,NEBOC_TOKEN_GREATER
 je .checked_greater
 cmp rdi,NEBOC_TOKEN_GREATER_EQUAL
 je .checked_greater_equal
 cmp rdi,NEBOC_TOKEN_EQUAL_EQUAL
 je .checked_equal
 cmp rdi,NEBOC_TOKEN_BANG_EQUAL
 je .checked_not_equal
 jmp .checked_invalid
.checked_add:
 mov rax,rsi
 add rax,rdx
 jo .checked_overflow
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_sub:
 mov rax,rsi
 sub rax,rdx
 jo .checked_overflow
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_mul:
 mov rax,rsi
 imul rax,rdx
 jo .checked_overflow
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_div:
 test rdx,rdx
 jz .checked_div_zero
 mov rax,0x8000000000000000
 cmp rsi,rax
 jne .checked_div_exec
 cmp rdx,-1
 je .checked_overflow
.checked_div_exec:
 mov rax,rsi
 mov rcx,rdx
 cqo
 idiv rcx
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_mod:
 test rdx,rdx
 jz .checked_div_zero
 mov rax,0x8000000000000000
 cmp rsi,rax
 jne .checked_mod_exec
 cmp rdx,-1
 je .checked_mod_zero
.checked_mod_exec:
 mov rax,rsi
 mov rcx,rdx
 cqo
 idiv rcx
 mov [rbx],rdx
 xor eax,eax
 jmp .checked_done
.checked_mod_zero:
 mov qword [rbx],0
 xor eax,eax
 jmp .checked_done
.checked_power:
 mov rdi,rsi
 mov rsi,rdx
 mov rdx,rbx
 call neboc_core_checked_power
 jmp .checked_done
.checked_xor:
 mov rax,rsi
 xor rax,rdx
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_less:
 xor eax,eax
 cmp rsi,rdx
 setl al
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_less_equal:
 xor eax,eax
 cmp rsi,rdx
 setle al
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_greater:
 xor eax,eax
 cmp rsi,rdx
 setg al
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_greater_equal:
 xor eax,eax
 cmp rsi,rdx
 setge al
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_equal:
 xor eax,eax
 cmp rsi,rdx
 sete al
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_not_equal:
 xor eax,eax
 cmp rsi,rdx
 setne al
 mov [rbx],rax
 xor eax,eax
 jmp .checked_done
.checked_overflow:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .checked_done
.checked_div_zero:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .checked_done
.checked_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.checked_done:
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
