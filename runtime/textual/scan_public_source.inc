; ScanPlan input adapters. Every read is bounded and uses caller-owned storage.
; Replay files are opened relative to the process working-directory capability
; through the existing filesystem owner, with no write or traversal permission.
%include "runtime/filesystem/file.inc"
%include "runtime/filesystem/text.inc"
extern nebo_runtime_scan_live_acquire
section .text
; RDI=Scan frame -> EAX=SCAN_E_*, RDX=bytes, RCX=length on success.
sp_read_source:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov rax,[rbx+SP_MOCK]
 test rax,rax
 jnz .mock
 cmp qword [rbx+SP_REPLAY],0
 je .stdin
 cmp qword [rbx+SP_SOURCE_LOADED],0
 jne .replay_line
 mov rdi,rbx
 call sp_load_replay
 test eax,eax
 jnz .done
.replay_line:
 mov r12,[rbx+SP_SOURCE_CURSOR]
 cmp r12,[rbx+SP_SOURCE_LENGTH]
 jae .eof
 mov r13,r12
.find_newline:
 cmp r13,[rbx+SP_SOURCE_LENGTH]
 jae .line_ready
 cmp byte [rbx+r13+5216],10
 je .newline
 inc r13
 jmp .find_newline
.newline:
 inc r13
 cmp qword [rbx+SP_INPUT_MODE],NEBO_G105_INPUT_LINE
 je .line_ready
 mov rdi,rbx
 lea rsi,[rbx+r12+5216]
 mov rdx,r13
 sub rdx,r12
 call sp_multiline_boundary
 test eax,eax
 jz .find_newline
.line_ready:
 mov [rbx+SP_SOURCE_CURSOR],r13
 lea rdx,[rbx+r12+5216]
 mov rcx,r13
 sub rcx,r12
 xor eax,eax
 jmp .done
.mock:
 cmp word [rax+20],1
 jne .invalid
 mov rcx,[rax+8]
 cmp rcx,4096
 ja .limit
 mov rdx,[rax]
 xor eax,eax
 jmp .done
.stdin:
 cmp qword [rbx+SP_CONSOLE],0
 je .stdin_prompt
 mov rdi,[rbx]
 cmp qword [rbx+SP_ATTEMPTS],1
 jbe .live_prompt_ready
 cmp qword [rbx+SP_RETRY_MESSAGE],0
 je .live_prompt_ready
 mov rdi,[rbx+SP_RETRY_MESSAGE]
.live_prompt_ready:
 mov rsi,[rbx+SP_REQUEST_ID]
 mov rdx,[rbx+SP_SECURITY]
 lea rcx,[rbx+5216]
 call nebo_runtime_scan_live_acquire
 cmp eax,1
 je .stdin_prompt
 cmp eax,8
 je .live_cancel
 test eax,eax
 jnz .io
 lea rdx,[rbx+5216]
 jmp .done
.live_cancel:
 mov eax,SCAN_E_CANCEL
 jmp .done
.stdin_prompt:
 ; Publish the actual prompt, then consume one bounded line. A byte-at-a-time
 ; read preserves following lines for a second scan/retry on a pipe or file.
 mov rax,[rbx]
 mov r12,[rax]
 mov r13,[rax+8]
.prompt:
 test r13,r13
 jz .read_start
 mov eax,1
 mov edi,1
 mov rsi,r12
 mov rdx,r13
 syscall
 test rax,rax
 jle .io
 add r12,rax
 sub r13,rax
 jmp .prompt
.read_start:
 xor r12d,r12d
.read:
 xor eax,eax
 xor edi,edi
 lea rsi,[rbx+r12+5216]
 mov edx,1
 syscall
 test rax,rax
 js .io
 jz .read_eof
 cmp r12,4096
 jae .limit
 cmp byte [rbx+r12+5216],10
 je .read_newline
 inc r12
 jmp .read
.read_newline:
 ; Keep LF for the canonical normalizer, except at the exact buffer limit.
 inc r12
 cmp qword [rbx+SP_INPUT_MODE],NEBO_G105_INPUT_LINE
 je .read_ready
 mov rdi,rbx
 lea rsi,[rbx+5216]
 mov rdx,r12
 call sp_multiline_boundary
 test eax,eax
 jz .read
.read_ready:
 lea rdx,[rbx+5216]
 mov rcx,r12
 xor eax,eax
 jmp .done
.read_eof:
 test r12,r12
 jnz .read_ready
.eof:
 mov eax,SCAN_E_EOF
 jmp .done
.invalid:
 mov eax,SCAN_E_INVALID
 jmp .done
.limit:
 mov eax,SCAN_E_LIMIT
 jmp .done
.io:
 mov eax,SCAN_E_IO
.done:
 pop r13
 pop r12
 pop rbx
 ret

; RDI=Scan frame -> EAX=Scan status. All file handles close on every path.
sp_load_replay:
 push rbx
 push r12
 push r13
 sub rsp,336
 mov rbx,rdi
 mov rax,[rbx+SP_REPLAY]
 cmp word [rax+20],1
 jne .invalid
 mov r13,[rax+8]
 test r13,r13
 jz .invalid
 cmp r13,256
 ja .limit
 mov rsi,[rax]
 lea rdi,[rsp+64]
 mov rcx,r13
 rep movsb
 mov byte [rdi],0
 mov eax,257
 mov rdi,-100
 lea rsi,[rel sp_current_directory]
 mov edx,0x290000
 xor r10d,r10d
 syscall
 test rax,rax
 js .io
 mov r12,rax
 mov rdi,rsp
 mov rsi,r12
 xor edx,edx
 mov ecx,NEBO_FILE_CAP_READ
 mov r8d,1
 mov r9d,4097
 call nebo_file_capability_init
 test eax,eax
 jnz .close_io
 mov rdi,rsp
 lea rsi,[rsp+64]
 mov rdx,r13
 lea rcx,[rbx+5216]
 mov r8d,4096
 call nebo_file_read_text
 test eax,eax
 jnz .close_io
 mov [rbx+SP_SOURCE_LENGTH],rdx
 mov qword [rbx+SP_SOURCE_LOADED],1
 xor r13d,r13d
 jmp .close
.close_io:
 mov r13d,SCAN_E_IO
.close:
 mov eax,3
 mov rdi,r12
 syscall
 test rax,rax
 js .io
 mov eax,r13d
 jmp .done
.invalid:
 mov eax,SCAN_E_INVALID
 jmp .done
.limit:
 mov eax,SCAN_E_LIMIT
 jmp .done
.io:
 mov eax,SCAN_E_IO
.done:
 add rsp,336
 pop r13
 pop r12
 pop rbx
 ret
; A source-supplied retry prompt uses bounded direct writes, never a pipeline.
sp_write_text:
 push rbx
 push r12
 push r13
 mov r12,[rdi]
 mov r13,[rdi+8]
 mov ebx,64
.write:
 test r13,r13
 jz .ok
 dec ebx
 jz .bad
 mov eax,1
 mov edi,1
 mov rsi,r12
 mov rdx,r13
 syscall
 cmp rax,-4
 je .write
 test rax,rax
 jle .bad
 add r12,rax
 sub r13,rax
 jmp .write
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,SCAN_E_IO
.done:
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
sp_current_directory: db '.',0
section .text
