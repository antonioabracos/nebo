; POTENCIA-XOR-E-COMPARACAO-TOTAL one coherent Bool projection from Ordering and exact Bool logic.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"

%define NEBOC_ORDERING_LESS 0
%define NEBOC_ORDERING_EQUAL 1
%define NEBOC_ORDERING_GREATER 2

section .text
; comparison_from_ordering(token, ordering, out_bool*)
NEBOC_ABI_FUNCTION neboc_core_comparison_from_ordering
 test rdx,rdx
 jz .compare_invalid
 cmp rsi,NEBOC_ORDERING_GREATER
 ja .compare_source
 cmp edi,NEBOC_TOKEN_EQUAL_EQUAL
 je .equal
 cmp edi,NEBOC_TOKEN_BANG_EQUAL
 je .not_equal
 cmp edi,NEBOC_TOKEN_LESS
 je .less
 cmp edi,NEBOC_TOKEN_LESS_EQUAL
 je .less_equal
 cmp edi,NEBOC_TOKEN_GREATER
 je .greater
 cmp edi,NEBOC_TOKEN_GREATER_EQUAL
 je .greater_equal
 jmp .compare_source
.equal:
 xor eax,eax
 cmp esi,NEBOC_ORDERING_EQUAL
 sete al
 jmp .compare_store
.not_equal:
 xor eax,eax
 cmp esi,NEBOC_ORDERING_EQUAL
 setne al
 jmp .compare_store
.less:
 xor eax,eax
 cmp esi,NEBOC_ORDERING_LESS
 sete al
 jmp .compare_store
.less_equal:
 xor eax,eax
 cmp esi,NEBOC_ORDERING_GREATER
 setne al
 jmp .compare_store
.greater:
 xor eax,eax
 cmp esi,NEBOC_ORDERING_GREATER
 sete al
 jmp .compare_store
.greater_equal:
 xor eax,eax
 cmp esi,NEBOC_ORDERING_LESS
 setne al
.compare_store:
 mov [rdx],rax
 xor eax,eax
 ret
.compare_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.compare_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; bool_logic(token, left, right, out_bool*). For unary !, right is ignored.
NEBOC_ABI_FUNCTION neboc_core_bool_logic
 test rcx,rcx
 jz .logic_invalid
 cmp rsi,1
 ja .logic_source
 cmp edi,NEBOC_TOKEN_BANG
 je .logic_not
 cmp rdx,1
 ja .logic_source
 cmp edi,NEBOC_TOKEN_AND_AND
 je .logic_and
 cmp edi,NEBOC_TOKEN_OR_OR
 je .logic_or
 cmp edi,NEBOC_TOKEN_XOR
 je .logic_xor
 jmp .logic_source
.logic_not:
 xor rsi,1
 mov [rcx],rsi
 xor eax,eax
 ret
.logic_and:
 and rsi,rdx
 jmp .logic_store
.logic_or:
 or rsi,rdx
 jmp .logic_store
.logic_xor:
 xor rsi,rdx
.logic_store:
 mov [rcx],rsi
 xor eax,eax
 ret
.logic_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.logic_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
