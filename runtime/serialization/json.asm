bits 64
default rel
%include "compiler/semantic/system/codec_contract.inc"
extern nebo_utf8_validate

section .text
global nebo_json_validate
global nebo_json_canonical_copy

; rdi=input, rsi=len, rdx=max depth, rcx=max values.
; eax=status, rdx=value count. Object keys must be strictly raw-byte sorted.
nebo_json_validate:
 push rbx
 push r12
 sub rsp,NEBO_JSON_CONTEXT_SIZE
 test rdi,rdi
 jz .validate_bad
 test rsi,rsi
 jz .validate_bad
 test rdx,rdx
 jz .validate_limit
 cmp rdx,64
 ja .validate_limit
 test rcx,rcx
 jz .validate_limit
 cmp rcx,1024
 ja .validate_limit
 mov rbx,rdi
 mov r12,rsi
 mov [rsp+NEBO_JSON_MAX_DEPTH],rdx
 mov [rsp+NEBO_JSON_MAX_ENTRIES],rcx
 call nebo_utf8_validate
 test eax,eax
 jnz .validate_return_zero
 mov [rsp+NEBO_JSON_INPUT],rbx
 mov [rsp+NEBO_JSON_LENGTH],r12
 mov qword [rsp+NEBO_JSON_POSITION],0
 mov qword [rsp+NEBO_JSON_DEPTH],0
 mov qword [rsp+NEBO_JSON_ENTRIES],0
 mov qword [rsp+NEBO_JSON_FLAGS],0
 mov r12,rsp
 call json_skip_ws
 call json_parse_value
 test eax,eax
 jnz .validate_return_zero
 call json_skip_ws
 mov rax,[r12+NEBO_JSON_POSITION]
 cmp rax,[r12+NEBO_JSON_LENGTH]
 jne .validate_bad
 mov rdx,[r12+NEBO_JSON_ENTRIES]
 xor eax,eax
 jmp .validate_return
.validate_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jmp .validate_return_zero
.validate_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.validate_return_zero:
 xor edx,edx
.validate_return:
 add rsp,NEBO_JSON_CONTEXT_SIZE
 pop r12
 pop rbx
 ret

; rdi=input rsi=len rdx=output rcx=capacity r8=max depth r9=max values.
; Validates, then removes only insignificant whitespace.
nebo_json_canonical_copy:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rbx,r9
 mov rdx,rbp
 mov rcx,rbx
 call nebo_json_validate
 test eax,eax
 jnz .copy_zero
 test r14,r14
 jz .copy_bad
 xor ecx,ecx
 xor edx,edx
 xor r8d,r8d                 ; in string
 xor r9d,r9d                 ; escape pending
.copy_loop:
 cmp rcx,r13
 jae .copy_done
 mov al,[r12+rcx]
 inc rcx
 test r8d,r8d
 jnz .copy_string
 cmp al,' '
 je .copy_loop
 cmp al,9
 je .copy_loop
 cmp al,10
 je .copy_loop
 cmp al,13
 je .copy_loop
 cmp al,'"'
 jne .copy_emit
 mov r8d,1
 jmp .copy_emit
.copy_string:
 test r9d,r9d
 jnz .copy_after_escape
 cmp al,92
 jne .copy_string_quote
 mov r9d,1
 jmp .copy_emit
.copy_after_escape:
 xor r9d,r9d
 jmp .copy_emit
.copy_string_quote:
 cmp al,'"'
 jne .copy_emit
 xor r8d,r8d
.copy_emit:
 cmp rdx,r15
 jae .copy_limit
 mov [r14+rdx],al
 inc rdx
 jmp .copy_loop
.copy_done:
 xor eax,eax
 jmp .copy_return
.copy_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jmp .copy_zero
.copy_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.copy_zero:
 xor edx,edx
.copy_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

json_skip_ws:
 mov rax,[r12+NEBO_JSON_POSITION]
 mov rcx,[r12+NEBO_JSON_LENGTH]
 mov rdx,[r12+NEBO_JSON_INPUT]
.ws_loop:
 cmp rax,rcx
 jae .ws_done
 mov r8b,[rdx+rax]
 cmp r8b,' '
 je .ws_next
 cmp r8b,9
 je .ws_next
 cmp r8b,10
 je .ws_next
 cmp r8b,13
 jne .ws_done
.ws_next:
 inc rax
 jmp .ws_loop
.ws_done:
 mov [r12+NEBO_JSON_POSITION],rax
 ret

json_parse_value:
 mov rax,[r12+NEBO_JSON_ENTRIES]
 cmp rax,[r12+NEBO_JSON_MAX_ENTRIES]
 jae json_limit
 inc rax
 mov [r12+NEBO_JSON_ENTRIES],rax
 call json_skip_ws
 mov rax,[r12+NEBO_JSON_POSITION]
 cmp rax,[r12+NEBO_JSON_LENGTH]
 jae json_bad
 mov rdx,[r12+NEBO_JSON_INPUT]
 mov cl,[rdx+rax]
 cmp cl,'{'
 je json_parse_object
 cmp cl,'['
 je json_parse_array
 cmp cl,'"'
 je json_parse_string
 cmp cl,'t'
 je .value_true
 cmp cl,'f'
 je .value_false
 cmp cl,'n'
 je .value_null
 cmp cl,'-'
 je json_parse_number
 cmp cl,'0'
 jb json_bad
 cmp cl,'9'
 jbe json_parse_number
 jmp json_bad
.value_true:
 lea rdi,[rel json_true]
 mov esi,4
 jmp json_match_literal
.value_false:
 lea rdi,[rel json_false]
 mov esi,5
 jmp json_match_literal
.value_null:
 lea rdi,[rel json_null]
 mov esi,4
 jmp json_match_literal

; String returns rdx=raw content pointer, rcx=raw length.
json_parse_string:
 push rbx
 push rbp
 push r13
 push r14
 mov r13,[r12+NEBO_JSON_INPUT]
 mov r14,[r12+NEBO_JSON_LENGTH]
 mov rbx,[r12+NEBO_JSON_POSITION]
 cmp byte [r13+rbx],'"'
 jne .string_bad
 inc rbx
 mov rbp,rbx
.string_loop:
 cmp rbx,r14
 jae .string_bad
 mov al,[r13+rbx]
 inc rbx
 cmp al,'"'
 je .string_done
 cmp al,0x20
 jb .string_bad
 cmp al,92
 jne .string_loop
 cmp rbx,r14
 jae .string_bad
 mov al,[r13+rbx]
 inc rbx
 cmp al,'"'
 je .string_loop
 cmp al,92
 je .string_loop
 cmp al,'/'
 je .string_loop
 cmp al,'b'
 je .string_loop
 cmp al,'f'
 je .string_loop
 cmp al,'n'
 je .string_loop
 cmp al,'r'
 je .string_loop
 cmp al,'t'
 je .string_loop
 cmp al,'u'
 jne .string_bad
 mov rdi,r13
 mov rsi,r14
 mov rdx,rbx
 call json_hex4
 test r8d,r8d
 jz .string_bad
 mov rbx,rdx
 cmp eax,0xd800
 jb .string_loop
 cmp eax,0xdbff
 ja .string_low_check
 ; High surrogate requires an immediately escaped low surrogate.
 mov rdx,rbx
 add rdx,2
 cmp rdx,r14
 jae .string_bad
 cmp byte [r13+rbx],92
 jne .string_bad
 cmp byte [r13+rbx+1],'u'
 jne .string_bad
 add rbx,2
 mov rdi,r13
 mov rsi,r14
 mov rdx,rbx
 call json_hex4
 test r8d,r8d
 jz .string_bad
 cmp eax,0xdc00
 jb .string_bad
 cmp eax,0xdfff
 ja .string_bad
 mov rbx,rdx
 jmp .string_loop
.string_low_check:
 cmp eax,0xdc00
 jb .string_loop
 cmp eax,0xdfff
 jbe .string_bad
 jmp .string_loop
.string_done:
 mov [r12+NEBO_JSON_POSITION],rbx
 lea rdx,[r13+rbp]
 mov rcx,rbx
 sub rcx,rbp
 dec rcx
 xor eax,eax
 jmp .string_return
.string_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 xor edx,edx
 xor ecx,ecx
.string_return:
 pop r14
 pop r13
 pop rbp
 pop rbx
 ret

json_parse_array:
 push rbx
 call json_enter_depth
 test eax,eax
 jnz .array_return
 inc qword [r12+NEBO_JSON_POSITION]
 call json_skip_ws
 call json_peek
 cmp al,']'
 je .array_empty
.array_value:
 call json_parse_value
 test eax,eax
 jnz .array_error
 call json_skip_ws
 call json_peek
 cmp al,']'
 je .array_close
 cmp al,','
 jne .array_bad
 inc qword [r12+NEBO_JSON_POSITION]
 call json_skip_ws
 jmp .array_value
.array_empty:
.array_close:
 inc qword [r12+NEBO_JSON_POSITION]
 call json_leave_depth
 jmp .array_return
.array_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
.array_error:
 dec qword [r12+NEBO_JSON_DEPTH]
.array_return:
 pop rbx
 ret

json_parse_object:
 push rbx
 push rbp
 push r13
 push r14
 push r15
 call json_enter_depth
 test eax,eax
 jnz .object_return
 inc qword [r12+NEBO_JSON_POSITION]
 xor ebp,ebp                 ; have previous key
 xor r13d,r13d               ; previous ptr
 xor r14d,r14d               ; previous len
 call json_skip_ws
 call json_peek
 cmp al,'}'
 je .object_empty
.object_key:
 call json_peek
 cmp al,'"'
 jne .object_bad
 call json_parse_string
 test eax,eax
 jnz .object_error
 test ebp,ebp
 jz .object_store
 mov rdi,r13
 mov rsi,r14
 ; current key is rdx,rcx
 call json_key_compare
 cmp eax,-1
 jne .object_bad
.object_store:
 mov r13,rdx
 mov r14,rcx
 mov ebp,1
 call json_skip_ws
 call json_peek
 cmp al,':'
 jne .object_bad
 inc qword [r12+NEBO_JSON_POSITION]
 call json_parse_value
 test eax,eax
 jnz .object_error
 call json_skip_ws
 call json_peek
 cmp al,'}'
 je .object_close
 cmp al,','
 jne .object_bad
 inc qword [r12+NEBO_JSON_POSITION]
 call json_skip_ws
 jmp .object_key
.object_empty:
.object_close:
 inc qword [r12+NEBO_JSON_POSITION]
 call json_leave_depth
 jmp .object_return
.object_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
.object_error:
 dec qword [r12+NEBO_JSON_DEPTH]
.object_return:
 pop r15
 pop r14
 pop r13
 pop rbp
 pop rbx
 ret

json_parse_number:
 push rbx
 push rbp
 push r13
 mov r13,[r12+NEBO_JSON_INPUT]
 mov rbx,[r12+NEBO_JSON_POSITION]
 mov rbp,rbx
 cmp byte [r13+rbx],'-'
 jne .number_int
 inc rbx
.number_int:
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_bad
 cmp byte [r13+rbx],'0'
 jne .number_nonzero
 inc rbx
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_fraction
 mov al,[r13+rbx]
 cmp al,'0'
 jb .number_fraction
 cmp al,'9'
 jbe .number_bad
 jmp .number_fraction
.number_nonzero:
 mov al,[r13+rbx]
 cmp al,'1'
 jb .number_bad
 cmp al,'9'
 ja .number_bad
.number_digits:
 inc rbx
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_fraction
 mov al,[r13+rbx]
 cmp al,'0'
 jb .number_fraction
 cmp al,'9'
 jbe .number_digits
.number_fraction:
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_exponent
 cmp byte [r13+rbx],'.'
 jne .number_exponent
 inc rbx
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_bad
 mov al,[r13+rbx]
 cmp al,'0'
 jb .number_bad
 cmp al,'9'
 ja .number_bad
.number_frac_digits:
 inc rbx
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_exponent
 mov al,[r13+rbx]
 cmp al,'0'
 jb .number_exponent
 cmp al,'9'
 jbe .number_frac_digits
.number_exponent:
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_done
 mov al,[r13+rbx]
 cmp al,'e'
 je .number_exp_start
 cmp al,'E'
 jne .number_done
.number_exp_start:
 inc rbx
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_bad
 mov al,[r13+rbx]
 cmp al,'+'
 je .number_exp_sign
 cmp al,'-'
 jne .number_exp_digits_begin
.number_exp_sign:
 inc rbx
.number_exp_digits_begin:
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_bad
 mov al,[r13+rbx]
 cmp al,'0'
 jb .number_bad
 cmp al,'9'
 ja .number_bad
 xor ecx,ecx
.number_exp_digits:
 movzx eax,byte [r13+rbx]
 sub eax,'0'
 imul ecx,ecx,10
 add ecx,eax
 cmp ecx,NEBO_JSON_MAX_EXPONENT
 ja .number_bad
 inc rbx
 cmp rbx,[r12+NEBO_JSON_LENGTH]
 jae .number_done
 mov al,[r13+rbx]
 cmp al,'0'
 jb .number_done
 cmp al,'9'
 jbe .number_exp_digits
.number_done:
 mov rax,rbx
 sub rax,rbp
 cmp rax,NEBO_JSON_MAX_NUMBER_BYTES
 ja .number_limit
 mov [r12+NEBO_JSON_POSITION],rbx
 xor eax,eax
 jmp .number_return
.number_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jmp .number_return
.number_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.number_return:
 pop r13
 pop rbp
 pop rbx
 ret

json_match_literal:
 ; rdi=literal rsi=len, context in r12.
 mov rax,[r12+NEBO_JSON_POSITION]
 mov rcx,rax
 add rcx,rsi
 cmp rcx,[r12+NEBO_JSON_LENGTH]
 ja json_bad
 mov rdx,[r12+NEBO_JSON_INPUT]
 lea r10,[rdx+rax]
 xor r8d,r8d
.literal_loop:
 cmp r8,rsi
 jae .literal_ok
 mov r9b,[rdi+r8]
 cmp [r10+r8],r9b
 jne json_bad
 inc r8
 jmp .literal_loop
.literal_ok:
 mov [r12+NEBO_JSON_POSITION],rcx
 xor eax,eax
 ret

json_enter_depth:
 mov rax,[r12+NEBO_JSON_DEPTH]
 cmp rax,[r12+NEBO_JSON_MAX_DEPTH]
 jae json_limit
 inc rax
 mov [r12+NEBO_JSON_DEPTH],rax
 xor eax,eax
 ret
json_leave_depth:
 cmp qword [r12+NEBO_JSON_DEPTH],0
 je json_bad
 dec qword [r12+NEBO_JSON_DEPTH]
 xor eax,eax
 ret

json_peek:
 mov rax,[r12+NEBO_JSON_POSITION]
 cmp rax,[r12+NEBO_JSON_LENGTH]
 jae .peek_zero
 mov rdx,[r12+NEBO_JSON_INPUT]
 mov al,[rdx+rax]
 ret
.peek_zero:
 xor eax,eax
 ret

; rdi=input, rsi=len, rdx=index. eax=code unit, rdx=new index, r8d=valid.
json_hex4:
 xor eax,eax
 xor ecx,ecx
.hex_loop:
 cmp ecx,4
 jae .hex_ok
 cmp rdx,rsi
 jae .hex_bad
 movzx r9d,byte [rdi+rdx]
 inc rdx
 cmp r9d,'0'
 jb .hex_bad
 cmp r9d,'9'
 jbe .hex_digit
 or r9d,0x20
 cmp r9d,'a'
 jb .hex_bad
 cmp r9d,'f'
 ja .hex_bad
 sub r9d,'a'-10
 jmp .hex_add
.hex_digit:
 sub r9d,'0'
.hex_add:
 shl eax,4
 or eax,r9d
 inc ecx
 jmp .hex_loop
.hex_ok:
 mov r8d,1
 ret
.hex_bad:
 xor r8d,r8d
 ret

; rdi=previous ptr, rsi=previous len, rdx=current ptr, rcx=current len.
json_key_compare:
 xor r8d,r8d
 mov r9,rsi
 cmp r9,rcx
 cmova r9,rcx
.key_loop:
 cmp r8,r9
 jae .key_prefix
 mov al,[rdi+r8]
 mov r10b,[rdx+r8]
 cmp al,r10b
 jb .key_less
 ja .key_greater
 inc r8
 jmp .key_loop
.key_prefix:
 cmp rsi,rcx
 jb .key_less
 ja .key_greater
 xor eax,eax
 ret
.key_less:
 mov eax,-1
 ret
.key_greater:
 mov eax,1
 ret

json_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 ret
json_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 ret

section .rodata
json_true db 'true'
json_false db 'false'
json_null db 'null'
