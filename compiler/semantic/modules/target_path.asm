; C03-F02-A1 canonical target path and Linux openat2 security owner.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/target_path.inc"

section .text

; target_path_validate_bytes(bytes*, length, suffix_kind) -> status.
NEBOC_ABI_FUNCTION neboc_target_path_validate_bytes
 test rdi,rdi
 jz .invalid_argument
 test rsi,rsi
 jz .malformed
 cmp rsi,NEBOC_TARGET_PATH_MAX_BYTES
 ja .limit
 cmp rdx,NEBOC_TARGET_PATH_SUFFIX_SOURCE
 je .suffix_source
 cmp rdx,NEBOC_TARGET_PATH_SUFFIX_INTERFACE
 jne .invalid_argument
 cmp rsi,3
 jb .malformed
 cmp byte [rdi+rsi-3],'.'
 jne .malformed
 cmp byte [rdi+rsi-2],'n'
 jne .malformed
 cmp byte [rdi+rsi-1],'i'
 jne .malformed
 jmp .scan_init
.suffix_source:
 cmp rsi,3
 jb .malformed
 cmp byte [rdi+rsi-3],'.'
 jne .malformed
 cmp byte [rdi+rsi-2],'n'
 jne .malformed
 cmp byte [rdi+rsi-1],'o'
 jne .malformed
.scan_init:
 cmp byte [rdi],'/'
 je .escape
 xor ecx,ecx
 xor r8d,r8d                         ; component start
 mov r9d,1                           ; component count
.scan:
 cmp rcx,rsi
 jae .final_component
 movzx eax,byte [rdi+rcx]
 cmp al,'/'
 je .separator
 cmp al,92
 je .malformed
 cmp al,'.'
 je .next
 cmp al,'_'
 je .next
 cmp al,'-'
 je .next
 cmp al,'0'
 jb .letter_upper
 cmp al,'9'
 jbe .next
.letter_upper:
 cmp al,'A'
 jb .letter_lower
 cmp al,'Z'
 jbe .next
.letter_lower:
 cmp al,'a'
 jb .malformed
 cmp al,'z'
 ja .malformed
.next:
 inc rcx
 jmp .scan
.separator:
 cmp rcx,r8
 je .malformed
 mov rax,rcx
 sub rax,r8
 cmp rax,1
 jne .component_dotdot
 cmp byte [rdi+r8],'.'
 je .escape
.component_dotdot:
 cmp rax,2
 jne .component_ok
 cmp byte [rdi+r8],'.'
 jne .component_ok
 cmp byte [rdi+r8+1],'.'
 je .escape
.component_ok:
 inc r9
 cmp r9,NEBOC_TARGET_PATH_MAX_COMPONENTS
 ja .limit
 lea r8,[rcx+1]
 inc rcx
 jmp .scan
.final_component:
 cmp r8,rsi
 je .malformed
 mov rax,rsi
 sub rax,r8
 cmp rax,1
 jne .final_dotdot
 cmp byte [rdi+r8],'.'
 je .escape
.final_dotdot:
 cmp rax,2
 jne .ok
 cmp byte [rdi+r8],'.'
 jne .ok
 cmp byte [rdi+r8+1],'.'
 je .escape
.ok:
 xor eax,eax
 ret
.malformed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.escape:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; target_path_open_read(request*) -> status.
; The manifest directory fd is already opened by the CLI. The path is copied
; only to form the NUL-terminated openat2 operand; logical identity remains the
; original manifest bytes.
NEBOC_ABI_FUNCTION neboc_target_path_open_read
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,440
 mov rbx,rdi
 test rbx,rbx
 jz .open_invalid
 test rbx,7
 jnz .open_invalid
 mov qword [rbx+NEBOC_TARGET_PATH_RESULT_LENGTH],0
 mov qword [rbx+NEBOC_TARGET_PATH_DEVICE],0
 mov qword [rbx+NEBOC_TARGET_PATH_INODE],0
 mov qword [rbx+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_NONE
 mov rdi,[rbx+NEBOC_TARGET_PATH_BYTES]
 mov rsi,[rbx+NEBOC_TARGET_PATH_LENGTH]
 mov rdx,[rbx+NEBOC_TARGET_PATH_SUFFIX]
 call neboc_target_path_validate_bytes
 test eax,eax
 jz .path_valid
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .open_limit
 mov qword [rbx+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_MALFORMED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .open_done
.path_valid:
 mov r13,[rbx+NEBOC_TARGET_PATH_LENGTH]
 mov rsi,[rbx+NEBOC_TARGET_PATH_BYTES]
 lea rdi,[rsp]
 xor ecx,ecx
.copy:
 cmp rcx,r13
 jae .copy_done
 mov al,[rsi+rcx]
 mov [rdi+rcx],al
 inc rcx
 jmp .copy
.copy_done:
 mov byte [rdi+r13],0
 mov qword [rsp+256],0x80000         ; O_RDONLY|O_CLOEXEC
 mov qword [rsp+264],0
 mov qword [rsp+272],NEBOC_TARGET_RESOLVE_FLAGS
 mov eax,437                         ; openat2
 mov rdi,[rbx+NEBOC_TARGET_PATH_ROOT_FD]
 lea rsi,[rsp]
 lea rdx,[rsp+256]
 mov r10d,24
 syscall
 cmp rax,-4095
 jae .open_syscall_error
 mov rbp,rax

 mov eax,5                           ; fstat
 mov rdi,rbp
 lea rsi,[rsp+280]
 syscall
 test rax,rax
 js .open_close_io
 mov rax,[rsp+280]
 mov [rbx+NEBOC_TARGET_PATH_DEVICE],rax
 mov rax,[rsp+288]
 mov [rbx+NEBOC_TARGET_PATH_INODE],rax
 mov eax,[rsp+304]
 and eax,0xf000
 cmp eax,0x8000                      ; selected members must be regular files
 jne .open_close_malformed

 xor r12d,r12d
 mov r14,[rbx+NEBOC_TARGET_PATH_BUFFER]
 mov r15,[rbx+NEBOC_TARGET_PATH_CAPACITY]
 test r14,r14
 jz .open_close_invalid
 test r15,r15
 jz .open_close_invalid
.read:
 cmp r12,r15
 jae .probe_extra
 xor eax,eax
 mov rdi,rbp
 lea rsi,[r14+r12]
 mov rdx,r15
 sub rdx,r12
 syscall
 test rax,rax
 jz .eof
 js .read_error
 add r12,rax
 jmp .read
.probe_extra:
 xor eax,eax
 mov rdi,rbp
 lea rsi,[rsp+432]
 mov edx,1
 syscall
 test rax,rax
 jz .eof
 js .read_error
 jmp .open_close_limit
.read_error:
 cmp rax,-4
 je .read
 jmp .open_close_io
.eof:
 mov eax,3
 mov rdi,rbp
 syscall
 mov byte [r14+r12],0
 mov [rbx+NEBOC_TARGET_PATH_RESULT_LENGTH],r12
 xor eax,eax
 jmp .open_done
.open_syscall_error:
 cmp rax,-40                         ; ELOOP
 je .open_symlink
 cmp rax,-18                         ; EXDEV from RESOLVE_BENEATH
 je .open_escape
 mov qword [rbx+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_IO
 mov eax,NEBOC_STATUS_IO_ERROR
 jmp .open_done
.open_symlink:
 mov qword [rbx+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_SYMLINK
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .open_done
.open_escape:
 mov qword [rbx+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_ESCAPE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .open_done
.open_close_io:
 mov eax,3
 mov rdi,rbp
 syscall
 mov qword [rbx+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_IO
 mov eax,NEBOC_STATUS_IO_ERROR
 jmp .open_done
.open_close_invalid:
 mov eax,3
 mov rdi,rbp
 syscall
.open_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .open_done
.open_close_malformed:
 mov eax,3
 mov rdi,rbp
 syscall
 mov qword [rbx+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_MALFORMED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .open_done
.open_close_limit:
 mov eax,3
 mov rdi,rbp
 syscall
.open_limit:
 mov qword [rbx+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.open_done:
 add rsp,440
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
