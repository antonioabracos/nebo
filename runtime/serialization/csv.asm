bits 64
default rel
%include "compiler/semantic/system/codec_contract.inc"
%include "compiler/semantic/data/data_contract.inc"
extern nebo_utf8_validate

section .text
global nebo_csv_parse_i64
global nebo_csv_write_i64

; rdi=input rsi=len rdx=values(8*32 qwords) rcx=missing[8]
; r8=cell capacity r9=(expected_fields<<32)|max_rows.
; eax=status, rdx=rows, rcx=fields. Two passes preserve output on failure.
nebo_csv_parse_i64:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rbx,r9
 test r12,r12
 jz .parse_bad
 test r13,r13
 jz .parse_bad
 test r14,r14
 jz .parse_bad
 test r15,r15
 jz .parse_bad
 mov eax,ebx
 test eax,eax
 jz .parse_limit
 cmp eax,NEBO_DATA_MAX_ROWS
 ja .parse_limit
 mov [rsp],rax
 shr rbx,32
 test ebx,ebx
 jz .parse_limit
 cmp ebx,NEBO_DATA_MAX_FIELDS
 ja .parse_limit
 mov [rsp+8],rbx
 mov rax,[rsp]
 imul rax,rbx
 cmp rax,rbp
 ja .parse_limit
 mov rdi,r12
 mov rsi,r13
 call nebo_utf8_validate
 test eax,eax
 jnz .parse_zero
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 mov r8,[rsp]
 mov r9,[rsp+8]
 xor r10d,r10d
 call csv_parse_pass
 test eax,eax
 jnz .parse_zero
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 ; Commit pass begins by clearing all authorized outputs.
 mov rdi,r14
 mov rcx,NEBO_DATA_MAX_FIELDS*NEBO_DATA_MAX_ROWS
 xor eax,eax
 rep stosq
 mov rdi,r15
 mov ecx,NEBO_DATA_MAX_FIELDS
 rep stosq
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 mov r8,[rsp]
 mov r9,[rsp+8]
 mov r10d,1
 call csv_parse_pass
 test eax,eax
 jnz .parse_zero
 cmp rdx,[rsp+16]
 jne .parse_bad
 cmp rcx,[rsp+24]
 jne .parse_bad
 jmp .parse_return
.parse_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jmp .parse_zero
.parse_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.parse_zero:
 xor edx,edx
 xor ecx,ecx
.parse_return:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; Pass ABI as public except r8=max rows r9=fields r10d=commit.
csv_parse_pass:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi                 ; input
 mov r13,rsi                 ; length
 mov r14,rdx                 ; values
 mov r15,rcx                 ; missing
 mov [rsp],r8                ; max rows
 mov [rsp+8],r9              ; fields
 mov [rsp+16],r10            ; commit
 xor ebx,ebx                 ; position
 xor ebp,ebp                 ; row
 mov qword [rsp+24],0        ; column
.pass_cell:
 cmp rbp,[rsp]
 jae .pass_limit
 mov r11,[rsp+24]
 cmp r11,[rsp+8]
 jae .pass_bad
 cmp rbx,r13
 jae .pass_bad
 xor r10d,r10d               ; quoted
 cmp byte [r12+rbx],'"'
 jne .cell_unquoted
 mov r10d,1
 inc rbx
 mov r8,rbx                  ; content start
.cell_quoted_scan:
 cmp rbx,r13
 jae .pass_bad
 cmp byte [r12+rbx],'"'
 je .cell_quoted_end
 cmp byte [r12+rbx],10
 je .pass_bad
 cmp byte [r12+rbx],13
 je .pass_bad
 inc rbx
 jmp .cell_quoted_scan
.cell_quoted_end:
 mov r9,rbx                  ; content end
 inc rbx
 cmp rbx,r13
 jae .cell_delimiter_eof
 mov al,[r12+rbx]
 cmp al,','
 je .cell_delimiter_comma
 cmp al,10
 je .cell_delimiter_lf
 cmp al,13
 je .cell_delimiter_cr
 jmp .pass_bad
.cell_unquoted:
 mov r8,rbx
.cell_unquoted_scan:
 cmp rbx,r13
 jae .cell_unquoted_end
 mov al,[r12+rbx]
 cmp al,','
 je .cell_unquoted_end
 cmp al,10
 je .cell_unquoted_end
 cmp al,13
 je .cell_unquoted_end
 cmp al,'"'
 je .pass_bad
 inc rbx
 jmp .cell_unquoted_scan
.cell_unquoted_end:
 mov r9,rbx
 cmp rbx,r13
 jae .cell_delimiter_eof
 mov al,[r12+rbx]
 cmp al,','
 je .cell_delimiter_comma
 cmp al,10
 je .cell_delimiter_lf
 jmp .cell_delimiter_cr
.cell_delimiter_comma:
 mov dword [rsp+32],1
 inc rbx
 jmp .cell_parse
.cell_delimiter_lf:
 mov dword [rsp+32],2
 inc rbx
 jmp .cell_parse
.cell_delimiter_cr:
 inc rbx
 cmp rbx,r13
 jae .pass_bad
 cmp byte [r12+rbx],10
 jne .pass_bad
 inc rbx
 mov dword [rsp+32],2
 jmp .cell_parse
.cell_delimiter_eof:
 mov dword [rsp+32],3
.cell_parse:
 mov rax,r9
 sub rax,r8
 test rax,rax
 jz .cell_missing
 lea rdi,[r12+r8]
 mov rsi,rax
 call csv_parse_i64_cell
 test eax,eax
 jnz .pass_done
 cmp qword [rsp+16],0
 je .cell_after_store
 mov r11,[rsp+24]
 imul r11,NEBO_DATA_MAX_ROWS
 add r11,rbp
 mov [r14+r11*8],rdx
 jmp .cell_after_store
.cell_missing:
 test r10d,r10d
 jnz .pass_bad              ; quoted empty is not implicit missing
 cmp qword [rsp+16],0
 je .cell_after_store
 mov r11,[rsp+24]
 bts qword [r15+r11*8],rbp
.cell_after_store:
 mov eax,[rsp+32]
 cmp eax,1
 je .cell_next_column
 ; Row terminator or EOF requires exact arity.
 mov r11,[rsp+24]
 inc r11
 cmp r11,[rsp+8]
 jne .pass_bad
 inc rbp
 mov qword [rsp+24],0
 cmp eax,3
 je .pass_success
 cmp rbx,r13
 je .pass_success
 jmp .pass_cell
.cell_next_column:
 inc qword [rsp+24]
 jmp .pass_cell
.pass_success:
 xor eax,eax
 mov rdx,rbp
 mov rcx,[rsp+8]
 jmp .pass_done
.pass_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 xor edx,edx
 xor ecx,ecx
 jmp .pass_done
.pass_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 xor ecx,ecx
.pass_done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=ASCII numeric bytes, rsi=len. eax=status, rdx=i64.
csv_parse_i64_cell:
 test rsi,rsi
 jz .i64_bad
 xor r8d,r8d
 xor r9d,r9d
 cmp byte [rdi],'-'
 jne .i64_digits
 mov r8d,1
 inc r9
 cmp r9,rsi
 jae .i64_bad
.i64_digits:
 xor eax,eax
.i64_loop:
 cmp r9,rsi
 jae .i64_done
 movzx ecx,byte [rdi+r9]
 sub ecx,'0'
 cmp ecx,9
 ja .i64_bad
 mov rdx,922337203685477580
 cmp rax,rdx
 ja .i64_limit
 imul rax,rax,10
 mov rdx,0x7fffffffffffffff
 test r8d,r8d
 jz .i64_bound
 inc rdx
.i64_bound:
 sub rdx,rcx
 cmp rax,rdx
 ja .i64_limit
 add rax,rcx
 inc r9
 jmp .i64_loop
.i64_done:
 test r8d,r8d
 jz .i64_positive
 neg rax
.i64_positive:
 mov rdx,rax
 xor eax,eax
 ret
.i64_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 ret
.i64_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 ret

; rdi=column-major values, rsi=missing bitmaps, rdx=rows, rcx=fields,
; r8=output, r9=capacity. Canonical LF output; failure atomic on capacity.
nebo_csv_write_i64:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rbx,r9
 test r12,r12
 jz .write_bad
 test r13,r13
 jz .write_bad
 test rbp,rbp
 jz .write_bad
 test r14,r14
 jz .write_limit
 cmp r14,NEBO_DATA_MAX_ROWS
 ja .write_limit
 test r15,r15
 jz .write_limit
 cmp r15,NEBO_DATA_MAX_FIELDS
 ja .write_limit
 xor r8d,r8d                 ; required bytes
 xor r9d,r9d                 ; row
.pre_row:
 cmp r9,r14
 jae .pre_done
 xor r10d,r10d               ; column
.pre_col:
 cmp r10,r15
 jae .pre_newline
 bt qword [r13+r10*8],r9
 jc .pre_delim
 mov rax,r10
 imul rax,NEBO_DATA_MAX_ROWS
 add rax,r9
 mov rax,[r12+rax*8]
 call csv_i64_length
 add r8,rax
 jc .write_limit
.pre_delim:
 inc r10
 cmp r10,r15
 jae .pre_col
 inc r8
 jmp .pre_col
.pre_newline:
 inc r8
 inc r9
 jmp .pre_row
.pre_done:
 cmp r8,rbx
 ja .write_limit
 mov [rsp],r8
 xor r8d,r8d                 ; cursor
 xor r9d,r9d
.emit_row:
 cmp r9,r14
 jae .emit_done
 xor r10d,r10d
.emit_col:
 cmp r10,r15
 jae .emit_newline
 bt qword [r13+r10*8],r9
 jc .emit_delim
 mov rax,r10
 imul rax,NEBO_DATA_MAX_ROWS
 add rax,r9
 mov rdx,[r12+rax*8]
 lea rdi,[rbp+r8]
 mov rsi,rbx
 sub rsi,r8
 push r8
 push r9
 push r10
 call csv_format_i64
 pop r10
 pop r9
 pop r8
 test eax,eax
 jnz .write_zero
 add r8,rdx
.emit_delim:
 inc r10
 cmp r10,r15
 jae .emit_col
 mov byte [rbp+r8],','
 inc r8
 jmp .emit_col
.emit_newline:
 mov byte [rbp+r8],10
 inc r8
 inc r9
 jmp .emit_row
.emit_done:
 xor eax,eax
 mov rdx,r8
 jmp .write_return
.write_bad:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jmp .write_zero
.write_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.write_zero:
 xor edx,edx
.write_return:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rax=value; returns rax decimal bytes.
csv_i64_length:
 xor ecx,ecx
 test rax,rax
 jnz .len_sign
 mov eax,1
 ret
.len_sign:
 jns .len_digits
 inc ecx
 neg rax
.len_digits:
 mov r8d,10
.len_loop:
 inc ecx
 xor edx,edx
 div r8
 test rax,rax
 jnz .len_loop
 mov eax,ecx
 ret

; rdi=dest rsi=capacity rdx=value. eax=status rdx=length.
csv_format_i64:
 push rbx
 push rbp
 sub rsp,32
 mov rbp,rdi
 mov rax,rdx
 xor ebx,ebx
 test rax,rax
 jnz .fmt_sign
 cmp rsi,1
 jb .fmt_limit
 mov byte [rbp],'0'
 mov edx,1
 xor eax,eax
 jmp .fmt_return
.fmt_sign:
 jns .fmt_digits
 mov bl,1
 neg rax
.fmt_digits:
 xor ecx,ecx
 mov r8d,10
.fmt_collect:
 xor edx,edx
 div r8
 add dl,'0'
 mov [rsp+rcx],dl
 inc ecx
 test rax,rax
 jnz .fmt_collect
 mov r9d,ecx
 add r9d,ebx
 cmp r9,rsi
 ja .fmt_limit
 xor edx,edx
 test ebx,ebx
 jz .fmt_reverse
 mov byte [rbp],'-'
 inc edx
.fmt_reverse:
 test ecx,ecx
 jz .fmt_ok
 dec ecx
 mov al,[rsp+rcx]
 mov [rbp+rdx],al
 inc edx
 jmp .fmt_reverse
.fmt_ok:
 xor eax,eax
 jmp .fmt_return
.fmt_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 xor edx,edx
.fmt_return:
 add rsp,32
 pop rbp
 pop rbx
 ret
