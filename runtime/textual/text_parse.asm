; PARSING-OPERACOES-CHECKED-CONVERSAO-E-INTEGRACAO-COM-A-LINGUAGEM allocation-free checked Text parsers.
bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_parse.inc"
global neboc_text_parse_int
global neboc_text_parse_float
global neboc_text_parse_bool
global neboc_text_parse_error_diagnostic
global neboc_text_checked_add
global neboc_int_to_text
global neboc_bool_to_text
section .rodata
true_bytes: db 't','r','u','e'
false_bytes: db 'f','a','l','s','e'
section .text
section .text
; rdi=Text descriptor, esi=base (0 or 10), rdx=out i64.
align 16
neboc_text_parse_int:
 test rdi,rdi
 jz .int_null
 test rdx,rdx
 jz .int_null
 test esi,esi
 jz .base_ok
 cmp esi,10
 jne .int_unsupported
.base_ok:
 mov rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 test rcx,rcx
 jz .int_empty
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 xor r9d,r9d
 xor r10d,r10d
 cmp byte [r8],'-'
 jne .int_loop
 mov r10d,1
 inc r9
 cmp r9,rcx
 jae .int_empty
.int_loop:
 xor eax,eax
.int_digit:
 cmp r9,rcx
 jae .int_done
 movzx r11d,byte [r8+r9]
 sub r11d,'0'
 cmp r11d,9
 ja .int_invalid
 imul rax,rax,10
 jo .int_overflow
 add rax,r11
 jo .int_overflow
 inc r9
 jmp .int_digit
.int_done:
 test r10d,r10d
 jz .int_commit
 neg rax
 jo .int_overflow
.int_commit:
 mov [rdx],rax
 xor eax,eax
 ret
.int_null:
 mov eax,NEBO_PARSE_NULL
 ret
.int_empty:
 mov eax,NEBO_PARSE_EMPTY
 ret
.int_invalid:
 mov eax,NEBO_PARSE_INVALID_DIGIT
 ret
.int_overflow:
 mov eax,NEBO_PARSE_OVERFLOW
 ret
.int_unsupported:
 mov eax,NEBO_PARSE_UNSUPPORTED
 ret

; rdi=Text descriptor, rsi=out f64. Bounded decimal profile: sign, digits, one dot.
align 16
neboc_text_parse_float:
 test rdi,rdi
 jz .float_null
 test rsi,rsi
 jz .float_null
 mov rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 test rcx,rcx
 jz .float_empty
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 xor r9d,r9d
 xor r10d,r10d
 mov r11d,1
 xor edx,edx
 cmp byte [r8],'-'
 jne .float_loop
 mov edx,1
 inc r9
 cmp r9,rcx
 jae .float_empty
.float_loop:
 xor eax,eax
.float_digit:
 cmp r9,rcx
 jae .float_done
 movzx edi,byte [r8+r9]
 cmp dil,'.'
 je .float_dot
 sub edi,'0'
 cmp edi,9
 ja .float_invalid
 imul rax,rax,10
 jo .float_overflow
 add rax,rdi
 jo .float_overflow
 test r10d,r10d
 jz .float_next
 imul r11,r11,10
 jo .float_overflow
.float_next:
 inc r9
 jmp .float_digit
.float_dot:
 test r10d,r10d
 jnz .float_invalid
 mov r10d,1
 inc r9
 cmp r9,rcx
 jae .float_invalid
 jmp .float_digit
.float_done:
 cvtsi2sd xmm0,rax
 cvtsi2sd xmm1,r11
 divsd xmm0,xmm1
 test edx,edx
 jz .float_commit
 mov rax,0x8000000000000000
 movq xmm1,rax
 xorpd xmm0,xmm1
.float_commit:
 movsd [rsi],xmm0
 xor eax,eax
 ret
.float_null:
 mov eax,NEBO_PARSE_NULL
 ret
.float_empty:
 mov eax,NEBO_PARSE_EMPTY
 ret
.float_invalid:
 mov eax,NEBO_PARSE_INVALID_DIGIT
 ret
.float_overflow:
 mov eax,NEBO_PARSE_OVERFLOW
 ret

; rdi=Text descriptor, rsi=out byte. Canonical spellings are exactly true/false.
align 16
neboc_text_parse_bool:
 test rdi,rdi
 jz .bool_null
 test rsi,rsi
 jz .bool_null
 mov rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 cmp rcx,4
 je .bool_true
 cmp rcx,5
 je .bool_false
 jmp .bool_invalid
.bool_true:
 cmp dword [r8],0x65757274
 jne .bool_invalid
 mov byte [rsi],NEBO_PARSE_BOOL_TRUE
 xor eax,eax
 ret
.bool_false:
 cmp dword [r8],0x736c6166
 jne .bool_invalid
 cmp byte [r8+4],'e'
 jne .bool_invalid
 mov byte [rsi],NEBO_PARSE_BOOL_FALSE
 xor eax,eax
 ret
.bool_null:
 mov eax,NEBO_PARSE_NULL
 ret
.bool_invalid:
 mov eax,NEBO_PARSE_INVALID_DIGIT
 ret

align 16
neboc_text_parse_error_diagnostic:
 xor eax,eax
 test edi,edi
 jz .parse_diag_done
 cmp edi,NEBO_PARSE_UNSUPPORTED
 ja .parse_diag_done
 lea eax,[rdi+NEBO_PARSE_DIAG_BASE]
.parse_diag_done:
 ret

; rdi=lhs, rsi=rhs, rdx=out i64. Output is committed only without overflow.
align 16
neboc_text_checked_add:
 test rdx,rdx
 jz .checked_null
 mov rax,rdi
 add rax,rsi
 jo .checked_overflow
 mov [rdx],rax
 xor eax,eax
 ret
.checked_null:
 mov eax,NEBO_PARSE_NULL
 ret
.checked_overflow:
 mov eax,NEBO_PARSE_OVERFLOW
 ret

; rdi=value, rsi=out bytes, rdx=capacity, rcx=out Text descriptor.
align 16
neboc_int_to_text:
 test rcx,rcx
 jz .to_text_null
 test rsi,rsi
 jz .to_text_null
 sub rsp,32
 mov rax,rdi
 mov rdi,rdx
 xor r8d,r8d
 test rax,rax
 jns .digits_begin
 mov r8d,1
 neg rax
.digits_begin:
 xor r9d,r9d
 mov r10d,10
.digits_loop:
 xor edx,edx
 div r10
 add dl,'0'
 mov [rsp+r9],dl
 inc r9
 test rax,rax
 jnz .digits_loop
 mov r11,r9
 add r11,r8
 cmp r11,rdi
 ja .to_text_capacity_stack
 xor eax,eax
 test r8d,r8d
 jz .copy_digits
 mov byte [rsi],'-'
 inc rax
.copy_digits:
 test r9,r9
 jz .to_text_commit
 dec r9
 mov dl,[rsp+r9]
 mov [rsi+rax],dl
 inc rax
 jmp .copy_digits
.to_text_commit:
 mov [rcx+NEBO_TEXT_DATA_OFFSET],rsi
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],r11
 mov qword [rcx+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [rcx+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 add rsp,32
 xor eax,eax
 ret
.to_text_capacity_stack:
 add rsp,32
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret
.to_text_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; edi=0/1, rsi=out static Text descriptor.
align 16
neboc_bool_to_text:
 test rsi,rsi
 jz .bool_text_null
 test edi,edi
 jnz .bool_text_true
 lea rax,[rel false_bytes]
 mov edx,5
 jmp .bool_text_commit
.bool_text_true:
 cmp edi,1
 jne .bool_text_invalid
 lea rax,[rel true_bytes]
 mov edx,4
.bool_text_commit:
 mov [rsi+NEBO_TEXT_DATA_OFFSET],rax
 mov [rsi+NEBO_TEXT_LENGTH_OFFSET],rdx
 mov qword [rsi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_STATIC | NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [rsi+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_STATIC
 xor eax,eax
 ret
.bool_text_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.bool_text_invalid:
 mov eax,NEBO_PARSE_UNSUPPORTED
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
