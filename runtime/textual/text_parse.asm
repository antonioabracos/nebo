; PARSING-OPERACOES-CHECKED-CONVERSAO-E-INTEGRACAO-COM-A-LINGUAGEM allocation-free checked Text parsers.
bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_parse.inc"
%include "compiler/tokens/token_kind.inc"
global neboc_text_parse_int
global neboc_text_parse_float
global neboc_text_parse_bool
global neboc_text_parse_error_diagnostic
global neboc_text_checked_add
global neboc_int_to_text
global neboc_bool_to_text
global nebo_runtime_textual_text_parse_int
global nebo_runtime_textual_text_parse_float
global nebo_runtime_textual_text_parse_bool
global nebo_runtime_textual_text_parse_error_diagnostic
global nebo_runtime_textual_text_parse_error_offset
global nebo_runtime_textual_text_split_checked
global nebo_runtime_textual_text_replace_all_checked
global nebo_runtime_textual_text_to_text
global nebo_runtime_textual_int_to_text
global nebo_runtime_textual_bool_to_text
global nebo_runtime_textual_text_is_nebo_identifier
extern nebo_runtime_textual_text_split
extern nebo_runtime_textual_text_replace_all
section .rodata
true_bytes: db 't','r','u','e'
false_bytes: db 'f','a','l','s','e'
%include "compiler/tokens/keyword_table.inc"
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
 test r10d,r10d
 jnz .int_negative_digit
 add rax,r11
 jo .int_overflow
 jmp .int_digit_done
.int_negative_digit:
 sub rax,r11
 jo .int_overflow
.int_digit_done:
 inc r9
 jmp .int_digit
.int_done:
.int_commit:
 mov [rdx],rax
 xor eax,eax
 ret
.int_null:
 xor ecx,ecx
 mov eax,NEBO_PARSE_NULL
 ret
.int_empty:
 xor ecx,ecx
 mov eax,NEBO_PARSE_EMPTY
 ret
.int_invalid:
 mov rcx,r9
 mov eax,NEBO_PARSE_INVALID_DIGIT
 ret
.int_overflow:
 mov rcx,r9
 mov eax,NEBO_PARSE_OVERFLOW
 ret
.int_unsupported:
 xor ecx,ecx
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
 xor ecx,ecx
 mov eax,NEBO_PARSE_NULL
 ret
.float_empty:
 xor ecx,ecx
 mov eax,NEBO_PARSE_EMPTY
 ret
.float_invalid:
 mov rcx,r9
 mov eax,NEBO_PARSE_INVALID_DIGIT
 ret
.float_overflow:
 mov rcx,r9
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
 test rcx,rcx
 jz .bool_empty
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
 xor ecx,ecx
 mov eax,NEBO_PARSE_NULL
 ret
.bool_empty:
 xor ecx,ecx
 mov eax,NEBO_PARSE_EMPTY
 ret
.bool_invalid:
 xor ecx,ecx
 mov eax,NEBO_PARSE_INVALID_DIGIT
 ret

align 16
neboc_text_parse_error_diagnostic:
 and edi,NEBO_PARSE_ERROR_CODE_MASK
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

; ---------------------------------------------------------------------------
; G056 public bounded Result integration.
;
; Scalar Result layout is the canonical 16-byte G005 layout: byte tag at 0,
; zero padding, qword payload at 8. Ok=0 and Err=1. Parse errors pack the
; stable error code in the low 32 bits and the offending byte offset in the
; high 32 bits. Checked Text results extend the same header with an inline
; 32-byte Text/TextSplit descriptor at offset 16, so failure cannot expose a
; partially committed descriptor.

; rdi=result slot, esi=tag, rdx=payload -> rax=result slot.
align 16
text_parse_store_result:
 pxor xmm0,xmm0
 movdqu [rdi],xmm0
 mov byte [rdi+NEBO_PARSE_RESULT_TAG_OFFSET],sil
 mov [rdi+NEBO_PARSE_RESULT_PAYLOAD_OFFSET],rdx
 mov rax,rdi
 ret

; eax=error code, ecx=byte offset -> rdx=packed TextParseError.
align 16
text_parse_pack_error:
 mov edx,eax
 shl rcx,NEBO_PARSE_ERROR_OFFSET_SHIFT
 or rdx,rcx
 ret

; rdi=Text, rsi=Result<Int,TextParseError> slot.
align 16
nebo_runtime_textual_text_parse_int:
 test rsi,rsi
 jz text_parse_public_trap
 push rbx
 sub rsp,16
 mov rbx,rsi
 mov rdx,rsp
 mov esi,10
 call neboc_text_parse_int
 test eax,eax
 jnz .parse_int_err
 mov rdx,[rsp]
 mov rdi,rbx
 xor esi,esi
 call text_parse_store_result
 add rsp,16
 pop rbx
 ret
.parse_int_err:
 call text_parse_pack_error
 mov rdi,rbx
 mov esi,NEBO_PARSE_RESULT_ERR
 call text_parse_store_result
 add rsp,16
 pop rbx
 ret

; rdi=Text, rsi=Result<Float,TextParseError> slot. Payload stores f64 bits.
align 16
nebo_runtime_textual_text_parse_float:
 test rsi,rsi
 jz text_parse_public_trap
 push rbx
 sub rsp,16
 mov rbx,rsi
 mov rsi,rsp
 call neboc_text_parse_float
 test eax,eax
 jnz .parse_float_err
 mov rdx,[rsp]
 mov rdi,rbx
 xor esi,esi
 call text_parse_store_result
 add rsp,16
 pop rbx
 ret
.parse_float_err:
 call text_parse_pack_error
 mov rdi,rbx
 mov esi,NEBO_PARSE_RESULT_ERR
 call text_parse_store_result
 add rsp,16
 pop rbx
 ret

; rdi=Text, rsi=Result<Bool,TextParseError> slot.
align 16
nebo_runtime_textual_text_parse_bool:
 test rsi,rsi
 jz text_parse_public_trap
 push rbx
 sub rsp,16
 mov rbx,rsi
 mov rsi,rsp
 call neboc_text_parse_bool
 test eax,eax
 jnz .parse_bool_err
 movzx edx,byte [rsp]
 mov rdi,rbx
 xor esi,esi
 call text_parse_store_result
 add rsp,16
 pop rbx
 ret
.parse_bool_err:
 call text_parse_pack_error
 mov rdi,rbx
 mov esi,NEBO_PARSE_RESULT_ERR
 call text_parse_store_result
 add rsp,16
 pop rbx
 ret

align 16
nebo_runtime_textual_text_parse_error_diagnostic:
 mov eax,edi
 and edi,NEBO_PARSE_ERROR_CODE_MASK
 jmp neboc_text_parse_error_diagnostic

align 16
nebo_runtime_textual_text_parse_error_offset:
 mov rax,rdi
 shr rax,NEBO_PARSE_ERROR_OFFSET_SHIFT
 ret

; rdi=input, rsi=separator, rdx=48-byte Result<TextSplit,TextError>,
; rcx=caller item array, r8=item capacity. No output is touched on Err.
align 16
nebo_runtime_textual_text_split_checked:
 test rdx,rdx
 jz text_parse_public_trap
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 mov r14,rcx
 mov r15,r8
 test r12,r12
 jz .split_checked_null
 test r13,r13
 jz .split_checked_null
 test r14,r14
 jz .split_checked_null
 mov r9,[r13+NEBO_TEXT_LENGTH_OFFSET]
 test r9,r9
 jz .split_checked_empty
 mov r10,[r12+NEBO_TEXT_LENGTH_OFFSET]
 mov r11,[r12+NEBO_TEXT_DATA_OFFSET]
 mov rdx,[r13+NEBO_TEXT_DATA_OFFSET]
 xor ecx,ecx
 mov qword [rsp],1
.split_checked_count:
 cmp rcx,r10
 jae .split_checked_capacity
 mov rax,rcx
 add rax,r9
 jc .split_checked_overflow
 cmp rax,r10
 ja .split_checked_next
 xor esi,esi
.split_checked_compare:
 cmp rsi,r9
 jae .split_checked_match
 lea rax,[rcx+rsi]
 mov al,[r11+rax]
 cmp al,[rdx+rsi]
 jne .split_checked_next
 inc rsi
 jmp .split_checked_compare
.split_checked_match:
 inc qword [rsp]
 add rcx,r9
 jmp .split_checked_count
.split_checked_next:
 inc rcx
 jmp .split_checked_count
.split_checked_capacity:
 mov rax,[rsp]
 cmp rax,r15
 ja .split_checked_overflow
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 lea r8,[rbx+NEBO_PARSE_CHECKED_VALUE_OFFSET]
 call nebo_runtime_textual_text_split
 pxor xmm0,xmm0
 movdqu [rbx],xmm0
 mov rax,rbx
 jmp .split_checked_done
.split_checked_null:
 mov eax,NEBO_PARSE_NULL
 xor ecx,ecx
 jmp .split_checked_err
.split_checked_empty:
 mov eax,NEBO_PARSE_EMPTY
 xor ecx,ecx
 jmp .split_checked_err
.split_checked_overflow:
 mov eax,NEBO_PARSE_OVERFLOW
 xor ecx,ecx
.split_checked_err:
 call text_parse_pack_error
 mov rdi,rbx
 mov esi,NEBO_PARSE_RESULT_ERR
 call text_parse_store_result
.split_checked_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=input, rsi=old, rdx=new, rcx=48-byte Result<Text,TextError>,
; r8=caller output bytes, r9=capacity. Pre-sizing guarantees atomic failure.
align 16
nebo_runtime_textual_text_replace_all_checked:
 test rcx,rcx
 jz text_parse_public_trap
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rcx
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,r8
 mov [rsp],r9
 test r12,r12
 jz .replace_checked_null
 test r13,r13
 jz .replace_checked_null
 test r14,r14
 jz .replace_checked_null
 mov r8,[r13+NEBO_TEXT_LENGTH_OFFSET]
 test r8,r8
 jz .replace_checked_empty
 mov r9,[r12+NEBO_TEXT_LENGTH_OFFSET]
 mov r10,[r12+NEBO_TEXT_DATA_OFFSET]
 mov r11,[r13+NEBO_TEXT_DATA_OFFSET]
 xor ecx,ecx
 xor edx,edx
.replace_checked_count:
 cmp rcx,r9
 jae .replace_checked_size
 mov rax,rcx
 add rax,r8
 jc .replace_checked_overflow
 cmp rax,r9
 ja .replace_checked_next
 xor esi,esi
.replace_checked_compare:
 cmp rsi,r8
 jae .replace_checked_match
 lea rax,[rcx+rsi]
 mov al,[r10+rax]
 cmp al,[r11+rsi]
 jne .replace_checked_next
 inc rsi
 jmp .replace_checked_compare
.replace_checked_match:
 inc rdx
 add rcx,r8
 jmp .replace_checked_count
.replace_checked_next:
 inc rcx
 jmp .replace_checked_count
.replace_checked_size:
 mov rax,[r14+NEBO_TEXT_LENGTH_OFFSET]
 cmp rax,r8
 jae .replace_checked_grow
 mov rcx,r8
 sub rcx,rax
 imul rcx,rdx
 jo .replace_checked_overflow
 cmp rcx,r9
 ja .replace_checked_overflow
 sub r9,rcx
 jmp .replace_checked_capacity
.replace_checked_grow:
 sub rax,r8
 imul rax,rdx
 jo .replace_checked_overflow
 add r9,rax
 jc .replace_checked_overflow
.replace_checked_capacity:
 cmp r9,[rsp]
 ja .replace_checked_overflow
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 mov r8,[rsp]
 lea r9,[rbx+NEBO_PARSE_CHECKED_VALUE_OFFSET]
 call nebo_runtime_textual_text_replace_all
 pxor xmm0,xmm0
 movdqu [rbx],xmm0
 mov rax,rbx
 jmp .replace_checked_done
.replace_checked_null:
 mov eax,NEBO_PARSE_NULL
 xor ecx,ecx
 jmp .replace_checked_err
.replace_checked_empty:
 mov eax,NEBO_PARSE_EMPTY
 xor ecx,ecx
 jmp .replace_checked_err
.replace_checked_overflow:
 mov eax,NEBO_PARSE_OVERFLOW
 xor ecx,ecx
.replace_checked_err:
 call text_parse_pack_error
 mov rdi,rbx
 mov esi,NEBO_PARSE_RESULT_ERR
 call text_parse_store_result
.replace_checked_done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Explicit conversions. Text and Int produce caller-owned Text; Bool returns a
; static immutable descriptor. Generated code bounds owned buffers to 4096.
align 16
nebo_runtime_textual_text_to_text:
 test rdi,rdi
 jz text_parse_public_trap
 test rcx,rcx
 jz text_parse_public_trap
 mov r8,rdi
 mov r9,rsi
 mov rax,[r8+NEBO_TEXT_LENGTH_OFFSET]
 cmp rax,rdx
 ja text_parse_public_trap
 test rax,rax
 jz .text_to_text_commit
 test r9,r9
 jz text_parse_public_trap
 push rax
 push rcx
 mov rdi,r9
 mov rsi,[r8+NEBO_TEXT_DATA_OFFSET]
 mov rcx,rax
 rep movsb
 pop rcx
 pop rax
.text_to_text_commit:
 mov [rcx+NEBO_TEXT_DATA_OFFSET],r9
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],rax
 mov rdx,[r8+NEBO_TEXT_FLAGS_OFFSET]
 and rdx,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov [rcx+NEBO_TEXT_FLAGS_OFFSET],rdx
 mov qword [rcx+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 mov rax,rcx
 ret

align 16
nebo_runtime_textual_int_to_text:
 push rbx
 mov rbx,rcx
 call neboc_int_to_text
 test eax,eax
 jnz text_conversion_trap
 mov rax,rbx
 pop rbx
 ret
text_conversion_trap:
 pop rbx
 jmp text_parse_public_trap

align 16
nebo_runtime_textual_bool_to_text:
 push rbx
 mov rbx,rsi
 call neboc_bool_to_text
 test eax,eax
 jnz text_conversion_trap
 mov rax,rbx
 pop rbx
 ret

; Exact current lexer profile: ASCII start/continue rules and all live keyword
; spellings. Unicode bytes are rejected by the lexer as invalid identifiers.
align 16
nebo_runtime_textual_text_is_nebo_identifier:
 test rdi,rdi
 jz .identifier_false
 mov rsi,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 test rsi,rsi
 jz .identifier_false
 mov rdi,[rdi+NEBO_TEXT_DATA_OFFSET]
 test rdi,rdi
 jz .identifier_false
 mov al,[rdi]
 cmp al,'A'
 jb .identifier_first_lower
 cmp al,'Z'
 jbe .identifier_rest_setup
.identifier_first_lower:
 cmp al,'a'
 jb .identifier_first_underscore
 cmp al,'z'
 jbe .identifier_rest_setup
.identifier_first_underscore:
 cmp al,'_'
 jne .identifier_false
.identifier_rest_setup:
 mov ecx,1
.identifier_rest:
 cmp rcx,rsi
 jae .identifier_keyword
 mov al,[rdi+rcx]
 cmp al,'A'
 jb .identifier_digit
 cmp al,'Z'
 jbe .identifier_next
 cmp al,'a'
 jb .identifier_underscore
 cmp al,'z'
 jbe .identifier_next
.identifier_digit:
 cmp al,'0'
 jb .identifier_false
 cmp al,'9'
 jbe .identifier_next
.identifier_underscore:
 cmp al,'_'
 jne .identifier_false
.identifier_next:
 inc rcx
 jmp .identifier_rest
.identifier_keyword:
 ; The runtime and live lexer consume the same canonical spelling table.
 mov r8,rdi
 mov r9,rsi
 lea r10,[rel keyword_table]
 mov edx,KEYWORD_COUNT
.identifier_keyword_loop:
 test edx,edx
 jz .identifier_true
 cmp [r10+8],r9
 jne .identifier_keyword_next
 mov rdi,r8
 mov rsi,[r10]
 mov rcx,r9
 cld
 repe cmpsb
 je .identifier_false
.identifier_keyword_next:
 add r10,24
 dec edx
 jnz .identifier_keyword_loop
.identifier_true:
 mov eax,1
 ret
.identifier_false:
 xor eax,eax
 ret

text_parse_public_trap:
 ; Match the existing bounded Text descriptor/capacity failure adapter.
 ; A valid source exceeding a public workspace limit must not SIGILL.
 mov eax,60
 mov edi,170
 syscall
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
