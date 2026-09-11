; Typed multiline input uses the existing G078 line-budget and G080 JSON
; owners. Source adapters stop at the actual delimiter without consuming a
; following response. Returned bytes remain owned by the ScanPlan frame.
%include "runtime/textual/scan_editor_source_probe.inc"
%include "runtime/textual/tabular_json_formats_source_probe.inc"
section .text
sp_multiline_option:
 mov rax,[rsi]
 cmp rax,49
 je .until
 cmp rax,50
 je .max_lines
 cmp rax,52
 je .block
 cmp rax,54
 je .code
 cmp rax,48
 je .multiline
 sub rax,48
 mov [rdi+SP_INPUT_MODE],rax
 xor eax,eax
 ret
.multiline:
 mov qword [rdi+SP_INPUT_MODE],NEBO_G105_INPUT_MULTILINE
 xor eax,eax
 ret
.block:
 mov qword [rdi+SP_INPUT_MODE],NEBO_G105_INPUT_BLOCK
.until:
 mov rax,[rsi+8]
 mov [rdi+SP_DELIMITER],rax
 cmp qword [rdi+SP_INPUT_MODE],NEBO_G105_INPUT_LINE
 jne .ok
 mov qword [rdi+SP_INPUT_MODE],NEBO_G105_INPUT_MULTILINE
.ok:
 xor eax,eax
 ret
.max_lines:
 mov rax,[rsi+8]
 test rax,rax
 jz .bad
 cmp rax,256
 ja .bad
 mov [rdi+SP_MAX_LINES],rax
 mov qword [rdi+SP_MAX_LINES_ACTIVE],1
 xor eax,eax
 ret
.code:
 push rbx
 mov rbx,rdi
 mov rdi,[rsi+8]
 call sp_metadata_identity
 test rax,rax
 jz .code_bad
 mov [rbx+SP_LANGUAGE],rax
 mov qword [rbx+SP_INPUT_MODE],NEBO_G105_INPUT_CODE
 xor eax,eax
 pop rbx
 ret
.code_bad:
 pop rbx
.bad:
 mov eax,SCAN_E_INVALID
 ret

sp_multiline_plan:
 push rbx
 mov rbx,rdi
 cmp qword [rbx+SP_INPUT_MODE],NEBO_G105_INPUT_RAW_BLOCK
 jne .flags
 and qword [rbx+SP_FLAGS],~SCAN_FLAG_CHOMP
.flags:
 xor ecx,ecx
 mov rax,[rbx+SP_DELIMITER]
 test rax,rax
 jz .delimiter
 cmp word [rax+20],1
 jne .bad
 mov rcx,[rax+8]
 test rcx,rcx
 jz .bad
 cmp rcx,256
 ja .bad
.delimiter:
 lea rdi,[rbx+SP_ADAPTER_PLAN]
 mov rsi,[rbx+SP_INPUT_MODE]
 mov rdx,[rbx+SP_MAX_LINES]
 cmp rsi,NEBO_G105_INPUT_LINE
 jne .call
 mov edx,1
.call:
 call nebo_scan_console_plan_multiline
 pop rbx
 ret
.bad:
 mov eax,SCAN_E_INVALID
 pop rbx
 ret

; RDI frame, RSI buffer, RDX prefix length -> EAX 1 when its final line
; terminates this block, 0 otherwise. No input byte is changed.
sp_multiline_boundary:
 mov r8,rdx
 test r8,r8
 jz .no
 cmp byte [rsi+r8-1],10
 jne .without_lf
 dec r8
.without_lf:
 test r8,r8
 jz .line_start
 cmp byte [rsi+r8-1],13
 jne .line_start
 dec r8
.line_start:
 mov r9,r8
.previous:
 test r9,r9
 jz .compare
 cmp byte [rsi+r9-1],10
 je .compare
 dec r9
 jmp .previous
.compare:
 sub r8,r9
 cmp qword [rdi+SP_INPUT_MODE],NEBO_G105_INPUT_PARAGRAPH
 jne .delimiter
 test r8,r8
 jz .yes
.delimiter:
 mov rax,[rdi+SP_DELIMITER]
 test rax,rax
 jz .no
 cmp r8,[rax+8]
 jne .no
 mov r10,[rax]
 xor ecx,ecx
.bytes:
 cmp rcx,r8
 jae .yes
 mov al,[r10+rcx]
 lea r11,[rsi+r9]
 cmp al,[r11+rcx]
 jne .no
 inc rcx
 jmp .bytes
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; RDI frame, RSI input, RDX byte length -> RAX retained content length or
; negative Scan error. RSI remains the input pointer for the normalizer.
sp_multiline_finish:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rax,rdx
 cmp qword [rbx+SP_INPUT_MODE],NEBO_G105_INPUT_LINE
 je .done
 xor r14d,r14d
 xor r15d,r15d
.scan:
 cmp r14,r13
 jae .last
 mov al,[r12+r14]
 inc r14
 cmp al,10
 jne .scan
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r14
 call sp_multiline_boundary
 test eax,eax
 jnz .terminated
 mov r15,r14
 jmp .scan
.last:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call sp_multiline_boundary
 test eax,eax
 jnz .terminated
 cmp qword [rbx+SP_DELIMITER],0
 jne .missing
 mov rax,r13
 jmp .done
.terminated:
 mov rax,r15
 jmp .done
.missing:
 mov rax,-SCAN_E_VALIDATE
.done:
 mov rsi,r12
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

sp_multiline_validate:
 push rbx
 mov rbx,rdi
 cmp qword [rbx+SP_INPUT_MODE],NEBO_G105_INPUT_LINE
 jne .lines
 cmp qword [rbx+SP_MAX_LINES_ACTIVE],0
 je .ok
.lines:
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 test rsi,rsi
 jz .json
 mov rdx,[rbx+SP_MAX_LINES]
 lea rcx,[rbx+10784]
 call nebo_g078_multiline_stats
 test eax,eax
 jnz .done
.json:
 cmp qword [rbx+SP_INPUT_MODE],NEBO_G105_INPUT_JSON_BLOCK
 jne .ok
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 mov edx,G080_MAX_DEPTH
 mov ecx,G080_DUPLICATE_REJECT
 call nebo_g080_json_validate
 jmp .done
.ok:
 xor eax,eax
.done:
 pop rbx
 ret
section .text
