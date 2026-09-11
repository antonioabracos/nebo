; Generic G011 source-to-runtime probe.  Public-source lowering selects one
; semantic family and a data-derived seed.  Every filesystem family performs
; real bounded syscalls below the process cwd, verifies its observation and
; removes its scratch object before returning the seed.
bits 64
default rel

%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_CLOSE 3
%define SYS_FSTAT 5
%define SYS_LSEEK 8
%define SYS_GETPID 39
%define SYS_FSYNC 74
%define SYS_FTRUNCATE 77
%define SYS_GETDENTS64 217
%define SYS_OPENAT 257
%define SYS_MKDIRAT 258
%define SYS_UNLINKAT 263
%define AT_FDCWD -100
%define AT_REMOVEDIR 0x200
%define O_RDWR 0x2
%define O_CREAT 0x40
%define O_EXCL 0x80
%define O_DIRECTORY 0x10000
%define O_CLOEXEC 0x80000

section .data
probe_file db '.nebo-io-file-'
probe_file_suffix: times 16 db '0'
 db 0
probe_meta db '.nebo-io-meta-'
probe_meta_suffix: times 16 db '0'
 db 0
probe_dir db '.nebo-io-dir-'
probe_dir_suffix: times 16 db '0'
 db 0
probe_text db '.nebo-io-text-'
probe_text_suffix: times 16 db '0'
 db 0
probe_codec db '.nebo-io-codec-'
probe_codec_suffix: times 16 db '0'
 db 0

section .rodata
hex_digits db '0123456789abcdef'
meta_payload db 'metadata'
text_payload db 'alpha',10,'beta',10
text_payload_len equ $-text_payload
codec_payload db '13,17',10
codec_payload_len equ $-codec_payload

section .text
global nebo_g011_source_probe
nebo_g011_source_probe:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,256
 mov r13d,edi
 mov r12d,esi
 mov r14,-1
 mov byte [rsp+248],0
 call .stamp_paths
 cmp r13d,1
 je .lexical
 cmp r13d,2
 je .file
 cmp r13d,3
 je .metadata
 cmp r13d,4
 je .directory
 cmp r13d,5
 je .text
 cmp r13d,6
 je .codec
 jmp .failure

.lexical:
 mov eax,r12d
 jmp .done

.file:
 lea rbx,[rel probe_file]
 call .create_regular
 test eax,eax
 js .failure
 mov r14,rax
 mov byte [rsp+248],1
 mov byte [rsp],r12b
 mov eax,SYS_WRITE
 mov rdi,r14
 mov rsi,rsp
 mov edx,1
 syscall
 cmp rax,1
 jne .failure
 mov eax,SYS_FSYNC
 mov rdi,r14
 syscall
 test rax,rax
 js .failure
 mov eax,SYS_LSEEK
 mov rdi,r14
 xor esi,esi
 xor edx,edx
 syscall
 test rax,rax
 js .failure
 mov byte [rsp+1],0
 mov eax,SYS_READ
 mov rdi,r14
 lea rsi,[rsp+1]
 mov edx,1
 syscall
 cmp rax,1
 jne .failure
 mov al,[rsp]
 cmp al,[rsp+1]
 jne .failure
 call .close_fd
 call .unlink_regular
 test rax,rax
 js .failure_code
 mov byte [rsp+248],0
 mov eax,r12d
 jmp .done

.metadata:
 lea rbx,[rel probe_meta]
 call .create_regular
 test eax,eax
 js .failure
 mov r14,rax
 mov byte [rsp+248],1
 mov eax,SYS_WRITE
 mov rdi,r14
 lea rsi,[rel meta_payload]
 mov edx,8
 syscall
 cmp rax,8
 jne .failure
 mov eax,SYS_FTRUNCATE
 mov rdi,r14
 mov esi,r12d
 syscall
 test rax,rax
 js .failure
 mov eax,SYS_FSTAT
 mov rdi,r14
 mov rsi,rsp
 syscall
 test rax,rax
 js .failure
 cmp [rsp+48],r12
 jne .failure
 call .close_fd
 call .unlink_regular
 test rax,rax
 js .failure_code
 mov byte [rsp+248],0
 mov eax,r12d
 jmp .done

.directory:
 lea rbx,[rel probe_dir]
 mov eax,SYS_MKDIRAT
 mov rdi,AT_FDCWD
 mov rsi,rbx
 mov edx,0700o
 syscall
 test rax,rax
 js .failure
 mov byte [rsp+248],1
 mov eax,SYS_OPENAT
 mov rdi,AT_FDCWD
 mov rsi,rbx
 mov edx,O_DIRECTORY | O_CLOEXEC
 xor r10d,r10d
 syscall
 test rax,rax
 js .failure
 mov r14,rax
 mov eax,SYS_GETDENTS64
 mov rdi,r14
 mov rsi,rsp
 mov edx,128
 syscall
 test rax,rax
 jle .failure
 call .close_fd
 call .unlink_directory
 test rax,rax
 js .failure_code
 mov byte [rsp+248],0
 mov eax,r12d
 jmp .done

.text:
 lea rbx,[rel probe_text]
 call .create_regular
 test eax,eax
 js .failure
 mov r14,rax
 mov byte [rsp+248],1
 mov eax,SYS_WRITE
 mov rdi,r14
 lea rsi,[rel text_payload]
 mov edx,text_payload_len
 syscall
 cmp rax,text_payload_len
 jne .failure
 call .rewind
 test eax,eax
 js .failure
 mov eax,SYS_READ
 mov rdi,r14
 mov rsi,rsp
 mov edx,text_payload_len
 syscall
 cmp rax,text_payload_len
 jne .failure
 lea rsi,[rel text_payload]
 mov rdi,rsp
 mov ecx,text_payload_len
 cld
 repe cmpsb
 jne .failure
 call .close_fd
 call .unlink_regular
 test rax,rax
 js .failure_code
 mov byte [rsp+248],0
 mov eax,r12d
 jmp .done

.codec:
 lea rbx,[rel probe_codec]
 call .create_regular
 test eax,eax
 js .failure
 mov r14,rax
 mov byte [rsp+248],1
 mov eax,SYS_WRITE
 mov rdi,r14
 lea rsi,[rel codec_payload]
 mov edx,codec_payload_len
 syscall
 cmp rax,codec_payload_len
 jne .failure
 call .rewind
 test eax,eax
 js .failure
 mov eax,SYS_READ
 mov rdi,r14
 mov rsi,rsp
 mov edx,codec_payload_len
 syscall
 cmp rax,codec_payload_len
 jne .failure
 lea rsi,[rel codec_payload]
 mov rdi,rsp
 mov ecx,codec_payload_len
 cld
 repe cmpsb
 jne .failure
 call .close_fd
 call .unlink_regular
 test rax,rax
 js .failure_code
 mov byte [rsp+248],0
 mov eax,r12d
 jmp .done

; RBX zero-terminated path -> RAX fd or negative errno.
.stamp_paths:
 mov eax,SYS_GETPID
 syscall
 mov rdx,rax
 lea rdi,[rel probe_file_suffix]
 call .write_hex16
 mov rax,rdx
 lea rdi,[rel probe_meta_suffix]
 call .write_hex16
 mov rax,rdx
 lea rdi,[rel probe_dir_suffix]
 call .write_hex16
 mov rax,rdx
 lea rdi,[rel probe_text_suffix]
 call .write_hex16
 mov rax,rdx
 lea rdi,[rel probe_codec_suffix]
 call .write_hex16
 ret
.write_hex16:
 lea r9,[rel hex_digits]
 mov ecx,16
.write_hex16_loop:
 mov r8,rax
 and r8d,15
 mov r10b,[r9+r8]
 mov [rdi+rcx-1],r10b
 shr rax,4
 dec ecx
 jnz .write_hex16_loop
 ret
.create_regular:
 mov eax,SYS_OPENAT
 mov rdi,AT_FDCWD
 mov rsi,rbx
 mov edx,O_RDWR | O_CREAT | O_EXCL | O_CLOEXEC
 mov r10d,0600o
 syscall
 ret
.rewind:
 mov eax,SYS_LSEEK
 mov rdi,r14
 xor esi,esi
 xor edx,edx
 syscall
 ret
.close_fd:
 cmp r14,0
 jl .closed
 mov eax,SYS_CLOSE
 mov rdi,r14
 syscall
 mov r14,-1
.closed:
 ret
.unlink_regular:
 mov eax,SYS_UNLINKAT
 mov rdi,AT_FDCWD
 mov rsi,rbx
 xor edx,edx
 syscall
 ret
.unlink_directory:
 mov eax,SYS_UNLINKAT
 mov rdi,AT_FDCWD
 mov rsi,rbx
 mov edx,AT_REMOVEDIR
 syscall
 ret
.failure:
 call .close_fd
 cmp byte [rsp+248],0
 je .failure_code
 cmp r13d,4
 je .failure_directory
 call .unlink_regular
 mov byte [rsp+248],0
 jmp .failure_code
.failure_directory:
 call .unlink_directory
 mov byte [rsp+248],0
.failure_code:
 mov eax,80
 add eax,r13d
.done:
 add rsp,256
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
