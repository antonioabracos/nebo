bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"

extern nebo_file_open
extern nebo_file_create
extern nebo_file_read
extern nebo_file_write_all
extern nebo_file_flush
extern nebo_file_seek
extern nebo_file_close

%define EINTR 4
%define TEXT_WRITE_TRUNCATE 0
%define TEXT_WRITE_APPEND 1
%define TEXT_WRITE_ATOMIC 2

section .rodata
temp_suffix db '.nebo-tmp'
temp_suffix_len equ $-temp_suffix

section .text
global nebo_utf8_validate
global nebo_file_read_bytes
global nebo_file_read_text
global nebo_file_write_bytes
global nebo_file_write_text
global nebo_text_lines
global nebo_file_read_line

; rdi=bytes, rsi=len. Strict scalar UTF-8; eax=status.
nebo_utf8_validate:
 test rsi,rsi
 jz .utf8_ok
 test rdi,rdi
 jz .utf8_bad
 xor ecx,ecx
.utf8_loop:
 cmp rcx,rsi
 jae .utf8_ok
 movzx eax,byte [rdi+rcx]
 inc rcx
 cmp eax,0x80
 jb .utf8_loop
 cmp eax,0xc2
 jb .utf8_bad
 cmp eax,0xdf
 jbe .utf8_two
 cmp eax,0xef
 jbe .utf8_three
 cmp eax,0xf4
 jbe .utf8_four
 jmp .utf8_bad
.utf8_two:
 cmp rcx,rsi
 jae .utf8_bad
 movzx edx,byte [rdi+rcx]
 and edx,0xc0
 cmp edx,0x80
 jne .utf8_bad
 inc rcx
 jmp .utf8_loop
.utf8_three:
 mov r8d,eax
 mov r9,rcx
 add r9,2
 cmp r9,rsi
 ja .utf8_bad
 movzx edx,byte [rdi+rcx]
 cmp r8d,0xe0
 jne .utf8_three_not_e0
 cmp edx,0xa0
 jb .utf8_bad
.utf8_three_not_e0:
 cmp r8d,0xed
 jne .utf8_three_second
 cmp edx,0x9f
 ja .utf8_bad
.utf8_three_second:
 and edx,0xc0
 cmp edx,0x80
 jne .utf8_bad
 movzx edx,byte [rdi+rcx+1]
 and edx,0xc0
 cmp edx,0x80
 jne .utf8_bad
 add rcx,2
 jmp .utf8_loop
.utf8_four:
 mov r8d,eax
 mov r9,rcx
 add r9,3
 cmp r9,rsi
 ja .utf8_bad
 movzx edx,byte [rdi+rcx]
 cmp r8d,0xf0
 jne .utf8_four_not_f0
 cmp edx,0x90
 jb .utf8_bad
.utf8_four_not_f0:
 cmp r8d,0xf4
 jne .utf8_four_second
 cmp edx,0x8f
 ja .utf8_bad
.utf8_four_second:
 and edx,0xc0
 cmp edx,0x80
 jne .utf8_bad
 movzx edx,byte [rdi+rcx+1]
 and edx,0xc0
 cmp edx,0x80
 jne .utf8_bad
 movzx edx,byte [rdi+rcx+2]
 and edx,0xc0
 cmp edx,0x80
 jne .utf8_bad
 add rcx,3
 jmp .utf8_loop
.utf8_ok:
 xor eax,eax
 ret
.utf8_bad:
 mov eax,NEBO_FILE_ERROR_INVALID_ENCODING
 ret

; rdi=cap, rsi=path, rdx=path len, rcx=output, r8=max bytes.
; eax=status, rdx=bytes. Reads one extra byte into private scratch to prove bound.
nebo_file_read_bytes:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 test rbp,rbp
 jz .read_bytes_limit
 lea rdi,[rsp]
 mov rsi,r12
 mov rdx,r13
 mov rcx,r14
 xor r8d,r8d
 xor r9d,r9d
 call nebo_file_open
 test eax,eax
 jnz .read_bytes_return_zero
 xor ebx,ebx
.read_bytes_loop:
 cmp rbx,rbp
 jae .read_bytes_probe
 lea rdi,[rsp]
 lea rsi,[r15+rbx]
 mov rdx,rbp
 sub rdx,rbx
 call nebo_file_read
 cmp eax,NEBO_FILE_ERROR_EOF
 je .read_bytes_success
 test eax,eax
 jnz .read_bytes_close_error
 add rbx,rdx
 jmp .read_bytes_loop
.read_bytes_probe:
 lea rdi,[rsp]
 lea rsi,[rsp+72]
 mov edx,1
 call nebo_file_read
 cmp eax,NEBO_FILE_ERROR_EOF
 je .read_bytes_success
 test eax,eax
 jnz .read_bytes_close_error
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jmp .read_bytes_close_error
.read_bytes_success:
 xor eax,eax
.read_bytes_close_status:
 mov ebp,eax
 lea rdi,[rsp]
 call nebo_file_close
 test ebp,ebp
 jnz .read_bytes_restore
 test eax,eax
 jnz .read_bytes_restore_close
 xor eax,eax
 mov rdx,rbx
 jmp .read_bytes_return
.read_bytes_restore_close:
 mov ebp,eax
.read_bytes_restore:
 mov eax,ebp
 xor edx,edx
 jmp .read_bytes_return
.read_bytes_close_error:
 jmp .read_bytes_close_status
.read_bytes_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.read_bytes_return_zero:
 xor edx,edx
.read_bytes_return:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; Same ABI as read_bytes; validates exactly the bytes returned.
nebo_file_read_text:
 push rbx
 push r12
 mov r12,rcx
 call nebo_file_read_bytes
 test eax,eax
 jnz .read_text_return
 mov rbx,rdx
 mov rdi,r12
 mov rsi,rbx
 call nebo_utf8_validate
 mov rdx,rbx
.read_text_return:
 pop r12
 pop rbx
 ret

; rdi=cap, rsi=path, rdx=path len, rcx=data, r8=data len, r9=mode.
nebo_file_write_bytes:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,4208
 mov r12,rdi
 mov r13,rsi
 mov [rsp+4200],rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rbx,r9
 cmp rbx,TEXT_WRITE_ATOMIC
 ja .write_bytes_invalid
 cmp rbx,TEXT_WRITE_ATOMIC
 jne .write_bytes_direct
 test r12,r12
 jz .write_bytes_denied
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 cmp [r12+NEBO_FILE_CAPABILITY_MAGIC],rax
 jne .write_bytes_denied
 mov rax,[r12+NEBO_FILE_CAPABILITY_PERMISSIONS]
 and eax,NEBO_FILE_CAP_WRITE | NEBO_FILE_CAP_CREATE | NEBO_FILE_CAP_DELETE
 cmp eax,NEBO_FILE_CAP_WRITE | NEBO_FILE_CAP_CREATE | NEBO_FILE_CAP_DELETE
 jne .write_bytes_denied
 mov rax,r14
 add rax,temp_suffix_len
 cmp rax,NEBO_PATH_MAX_BYTES
 ja .write_bytes_limit
 xor ecx,ecx
.write_bytes_copy_path:
 cmp rcx,r14
 jae .write_bytes_copy_suffix
 mov dl,[r13+rcx]
 test dl,dl
 jz .write_bytes_invalid
 mov [rsp+80+rcx],dl
 inc rcx
 jmp .write_bytes_copy_path
.write_bytes_copy_suffix:
 xor edx,edx
 lea r8,[rel temp_suffix]
.write_bytes_suffix_loop:
 cmp rdx,temp_suffix_len
 jae .write_bytes_suffix_done
 mov al,[r8+rdx]
 mov [rsp+80+rcx],al
 inc rcx
 inc rdx
 jmp .write_bytes_suffix_loop
.write_bytes_suffix_done:
 mov byte [rsp+80+rcx],0
 lea r13,[rsp+80]
 mov r14,rcx
 lea rdi,[rsp]
 mov rsi,r12
 mov rdx,r13
 mov rcx,r14
 mov r8d,NEBO_FILE_OPEN_EXCLUSIVE
 mov r9d,0600o
 call nebo_file_create
 jmp .write_bytes_opened
.write_bytes_direct:
 lea rdi,[rsp]
 mov rsi,r12
 mov rdx,r13
 mov rcx,r14
 mov r8d,NEBO_FILE_OPEN_TRUNCATE
 cmp rbx,TEXT_WRITE_APPEND
 jne .write_bytes_direct_flags
 mov r8d,NEBO_FILE_OPEN_APPEND
.write_bytes_direct_flags:
 mov r9d,0600o
 call nebo_file_create
.write_bytes_opened:
 test eax,eax
 jnz .write_bytes_return_zero
 lea rdi,[rsp]
 mov rsi,r15
 mov rdx,rbp
 call nebo_file_write_all
 test eax,eax
 jnz .write_bytes_close_error
 lea rdi,[rsp]
 call nebo_file_flush
 test eax,eax
 jnz .write_bytes_close_error
 xor eax,eax
.write_bytes_close_status:
 mov dword [rsp+4192],eax
 lea rdi,[rsp]
 call nebo_file_close
 mov edx,[rsp+4192]
 test edx,edx
 jnz .write_bytes_restore
 test eax,eax
 jnz .write_bytes_return_zero
 cmp rbx,TEXT_WRITE_ATOMIC
 jne .write_bytes_success
.write_bytes_rename_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_RENAMEAT2
 mov rdi,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 mov rsi,r13
 mov rdx,rdi
 mov r10,[rsp+4200]
 xor r8d,r8d
 syscall
 cmp rax,-EINTR
 je .write_bytes_rename_retry
 cmp rax,-4095
 jae .write_bytes_rename_error
.write_bytes_success:
 xor eax,eax
 mov rdx,rbp
 jmp .write_bytes_return
.write_bytes_rename_error:
 mov dword [rsp+4192],NEBO_FILE_ERROR_IO
 mov eax,NEBO_LINUX_X86_64_SYS_UNLINKAT
 mov rdi,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 mov rsi,r13
 xor edx,edx
 syscall
 mov eax,[rsp+4192]
 jmp .write_bytes_return_zero
.write_bytes_close_error:
 jmp .write_bytes_close_status
.write_bytes_restore:
 mov eax,edx
 jmp .write_bytes_return_zero
.write_bytes_invalid:
 mov eax,NEBO_FILE_ERROR_IO
 jmp .write_bytes_return_zero
.write_bytes_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 jmp .write_bytes_return_zero
.write_bytes_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.write_bytes_return_zero:
 xor edx,edx
.write_bytes_return:
 add rsp,4208
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; Same ABI as write_bytes, with strict UTF-8 validation before any mutation.
nebo_file_write_text:
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
 mov rdi,r15
 mov rsi,rbp
 call nebo_utf8_validate
 test eax,eax
 jnz .write_text_return
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 mov r8,rbp
 mov r9,rbx
 call nebo_file_write_bytes
.write_text_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=text, rsi=len, rdx=pair output(offset,len), rcx=max lines.
; Includes a final empty line when text ends in a terminator.
nebo_text_lines:
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
 test r14,r14
 jz .lines_invalid
 test r15,r15
 jz .lines_limit
 xor ebx,ebx
 xor ebp,ebp
 xor ecx,ecx
.lines_scan:
 cmp rcx,r13
 jae .lines_emit_final
 cmp byte [r12+rcx],10
 jne .lines_next
 mov r8,rcx
 sub r8,rbp
 test r8,r8
 jz .lines_emit
 cmp byte [r12+rcx-1],13
 jne .lines_emit
 dec r8
.lines_emit:
 cmp rbx,r15
 jae .lines_limit
 mov r9,rbx
 shl r9,4
 mov [r14+r9],rbp
 mov [r14+r9+8],r8
 inc rbx
 lea rbp,[rcx+1]
.lines_next:
 inc rcx
 jmp .lines_scan
.lines_emit_final:
 cmp rbx,r15
 jae .lines_limit
 mov r8,r13
 sub r8,rbp
 mov r9,rbx
 shl r9,4
 mov [r14+r9],rbp
 mov [r14+r9+8],r8
 inc rbx
 xor eax,eax
 mov rdx,rbx
 jmp .lines_return
.lines_invalid:
 mov eax,NEBO_FILE_ERROR_IO
 jmp .lines_zero
.lines_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.lines_zero:
 xor edx,edx
.lines_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=File, rsi=output, rdx=limit. eax=status, rdx=len, rcx=has_line.
nebo_file_read_line:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r13,r13
 jz .read_line_invalid
 test r14,r14
 jz .read_line_limit
 xor ebx,ebx
.read_line_loop:
 cmp rbx,r14
 jae .read_line_limit
 mov rdi,r12
 lea rsi,[rsp]
 mov edx,1
 call nebo_file_read
 cmp eax,NEBO_FILE_ERROR_EOF
 je .read_line_eof
 test eax,eax
 jnz .read_line_error
 cmp byte [rsp],10
 je .read_line_success
 cmp byte [rsp],13
 je .read_line_cr
 mov al,[rsp]
 mov [r13+rbx],al
 inc rbx
 jmp .read_line_loop
.read_line_cr:
 mov rdi,r12
 lea rsi,[rsp]
 mov edx,1
 call nebo_file_read
 cmp eax,NEBO_FILE_ERROR_EOF
 je .read_line_success
 test eax,eax
 jnz .read_line_error
 cmp byte [rsp],10
 je .read_line_success
 mov rdi,r12
 mov rsi,-1
 mov edx,NEBO_FILE_SEEK_CURRENT
 call nebo_file_seek
 test eax,eax
 jnz .read_line_error
 jmp .read_line_success
.read_line_eof:
 test rbx,rbx
 jnz .read_line_success
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 jmp .read_line_return
.read_line_success:
 xor eax,eax
 mov rdx,rbx
 mov ecx,1
 jmp .read_line_return
.read_line_invalid:
 mov eax,NEBO_FILE_ERROR_IO
 jmp .read_line_zero
.read_line_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jmp .read_line_zero
.read_line_error:
.read_line_zero:
 xor edx,edx
 xor ecx,ecx
.read_line_return:
 add rsp,16
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
