bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"

%define EINTR 4
%define ENOENT 2
%define EACCES 13
%define EPERM 1
%define EEXIST 17
%define EXDEV 18
%define ENOSYS 38
%define ELOOP 40

section .text

global nebo_file_capability_init
global nebo_file_open
global nebo_file_create
global nebo_file_read
global nebo_file_read_exact
global nebo_file_write
global nebo_file_write_all
global nebo_file_flush
global nebo_file_seek
global nebo_file_metadata
global nebo_file_set_length
global nebo_path_metadata
global nebo_path_exists
global nebo_path_is_file
global nebo_path_is_directory
global nebo_file_close

; rdi=capability, rsi=root fd, rdx=root identity, rcx=permission bits,
; r8=max handles, r9=max cumulative bytes. eax=status.
nebo_file_capability_init:
 test rdi,rdi
 jz .cap_invalid
 test rsi,rsi
 js .cap_invalid
 test rcx,~NEBO_FILE_CAP_ALL
 jnz .cap_invalid
 test r8,r8
 jz .cap_limit
 cmp r8,NEBO_FILE_MAX_OPEN_PER_CAPABILITY
 ja .cap_limit
 test r9,r9
 jz .cap_limit
 cmp r9,NEBO_FILE_MAX_IO_BYTES
 ja .cap_limit
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 mov [rdi+NEBO_FILE_CAPABILITY_MAGIC],rax
 mov [rdi+NEBO_FILE_CAPABILITY_ROOT_FD],rsi
 mov [rdi+NEBO_FILE_CAPABILITY_ROOT_ID],rdx
 mov [rdi+NEBO_FILE_CAPABILITY_PERMISSIONS],rcx
 mov qword [rdi+NEBO_FILE_CAPABILITY_MAX_PATH_BYTES],NEBO_PATH_MAX_BYTES
 mov [rdi+NEBO_FILE_CAPABILITY_MAX_HANDLES],r8
 mov [rdi+NEBO_FILE_CAPABILITY_MAX_IO_BYTES],r9
 mov dword [rdi+NEBO_FILE_CAPABILITY_GENERATION],1
 mov dword [rdi+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES],0
 xor eax,eax
 ret
.cap_invalid:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 ret
.cap_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 ret

; rdi=File, rsi=capability, rdx=NUL-terminated normalized relative path,
; rcx=path bytes, r8=open flags, r9=mode. eax=status.
nebo_file_open:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r12,r12
 jz .open_invalid
 test r13,r13
 jz .open_denied
 test r14,r14
 jz .open_invalid
 test r15,r15
 jz .open_invalid
 cmp r15,NEBO_PATH_MAX_BYTES
 ja .open_limit
 cmp byte [r14],'/'
 je .open_escape
 cmp byte [r14+r15],0
 jne .open_invalid
 xor ecx,ecx
.open_path_scan:
 cmp rcx,r15
 jae .open_path_ok
 cmp byte [r14+rcx],0
 je .open_invalid
 inc rcx
 jmp .open_path_scan
.open_path_ok:
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 cmp [r13+NEBO_FILE_CAPABILITY_MAGIC],rax
 jne .open_denied
 mov rax,[r13+NEBO_FILE_CAPABILITY_PERMISSIONS]
 mov rdx,NEBO_FILE_CAP_READ
 mov rcx,rbx
 and ecx,3
 test ecx,ecx
 jz .open_permission_mode_done
 mov edx,NEBO_FILE_CAP_WRITE
 cmp ecx,2
 jne .open_permission_mode_done
 or edx,NEBO_FILE_CAP_READ
.open_permission_mode_done:
 test rbx,NEBO_FILE_OPEN_TRUNCATE | NEBO_FILE_OPEN_APPEND
 jz .open_permission_create
 or edx,NEBO_FILE_CAP_WRITE
.open_permission_create:
 test rbx,NEBO_FILE_OPEN_CREATE
 jz .open_permission_check
 or edx,NEBO_FILE_CAP_CREATE
.open_permission_check:
 mov rcx,rax
 and rcx,rdx
 cmp rcx,rdx
 jne .open_denied
 mov eax,[r13+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES]
 cmp rax,[r13+NEBO_FILE_CAPABILITY_MAX_HANDLES]
 jae .open_limit
 sub rsp,32
 mov [rsp],rbx
 or qword [rsp],NEBO_FILE_OPEN_CLOEXEC
 mov [rsp+8],r9
 mov qword [rsp+16],NEBO_OPENAT2_REQUIRED_RESOLVE
 mov eax,NEBO_LINUX_X86_64_SYS_OPENAT2
 mov rdi,[r13+NEBO_FILE_CAPABILITY_ROOT_FD]
 mov rsi,r14
 mov rdx,rsp
 mov r10d,24
 syscall
 add rsp,32
 cmp rax,-4095
 jae .open_sys_error
 mov [r12+NEBO_FILE_FD],rax
 mov qword [r12+NEBO_FILE_STATE],NEBO_FILE_STATE_OPEN
 mov [r12+NEBO_FILE_CAPABILITY],r13
 mov [r12+NEBO_FILE_FLAGS],rbx
 mov qword [r12+NEBO_FILE_GENERATION],1
 mov qword [r12+NEBO_FILE_BYTES_READ],0
 mov qword [r12+NEBO_FILE_BYTES_WRITTEN],0
 mov qword [r12+NEBO_FILE_RESERVED],0
 inc dword [r13+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES]
 xor eax,eax
 jmp .open_return
.open_sys_error:
 mov rdi,rax
 call file_map_errno
 jmp .open_return
.open_invalid:
 mov eax,NEBO_FILE_ERROR_INVALID_PATH
 jmp .open_return
.open_escape:
 mov eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jmp .open_return
.open_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 jmp .open_return
.open_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.open_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

nebo_file_create:
 or r8,NEBO_FILE_OPEN_WRITE | NEBO_FILE_OPEN_CREATE
 jmp nebo_file_open

; rdi=File, rsi=buffer, rdx=request bytes. eax=status, rdx=count.
nebo_file_read:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 call file_validate_open_read
 test eax,eax
 jnz .read_error_no_count
 test rbx,rbx
 jz .read_zero
 mov rax,[r12+NEBO_FILE_BYTES_READ]
 add rax,[r12+NEBO_FILE_BYTES_WRITTEN]
 jc .read_limit
 add rax,rbx
 jc .read_limit
 mov rcx,[r12+NEBO_FILE_CAPABILITY]
 cmp rax,[rcx+NEBO_FILE_CAPABILITY_MAX_IO_BYTES]
 ja .read_limit
.read_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_READ
 mov rdi,[r12+NEBO_FILE_FD]
 mov rsi,r13
 mov rdx,rbx
 syscall
 cmp rax,-EINTR
 je .read_retry
 cmp rax,-4095
 jae .read_sys_error
 test rax,rax
 jz .read_eof
 add [r12+NEBO_FILE_BYTES_READ],rax
 mov rdx,rax
 xor eax,eax
 jmp .read_return
.read_zero:
 xor eax,eax
 xor edx,edx
 jmp .read_return
.read_eof:
 mov eax,NEBO_FILE_ERROR_EOF
 xor edx,edx
 jmp .read_return
.read_sys_error:
 mov rdi,rax
 call file_map_errno
 xor edx,edx
 jmp .read_return
.read_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.read_error_no_count:
 xor edx,edx
.read_return:
 pop r13
 pop r12
 pop rbx
 ret

; same arguments. EOF preserves partial count in rdx.
nebo_file_read_exact:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 xor ebx,ebx
.read_exact_loop:
 cmp rbx,r14
 jae .read_exact_success
 mov rdi,r12
 lea rsi,[r13+rbx]
 mov rdx,r14
 sub rdx,rbx
 call nebo_file_read
 test eax,eax
 jnz .read_exact_status
 add rbx,rdx
 jmp .read_exact_loop
.read_exact_success:
 xor eax,eax
.read_exact_status:
 mov rdx,rbx
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

nebo_file_write:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 call file_validate_open_write
 test eax,eax
 jnz .write_error_no_count
 test rbx,rbx
 jz .write_zero
 mov rax,[r12+NEBO_FILE_BYTES_WRITTEN]
 add rax,[r12+NEBO_FILE_BYTES_READ]
 jc .write_limit
 add rax,rbx
 jc .write_limit
 mov rcx,[r12+NEBO_FILE_CAPABILITY]
 cmp rax,[rcx+NEBO_FILE_CAPABILITY_MAX_IO_BYTES]
 ja .write_limit
.write_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_WRITE
 mov rdi,[r12+NEBO_FILE_FD]
 mov rsi,r13
 mov rdx,rbx
 syscall
 cmp rax,-EINTR
 je .write_retry
 cmp rax,-4095
 jae .write_sys_error
 test rax,rax
 jz .write_sys_error_zero
 add [r12+NEBO_FILE_BYTES_WRITTEN],rax
 mov rdx,rax
 xor eax,eax
 jmp .write_return
.write_zero:
 xor eax,eax
 xor edx,edx
 jmp .write_return
.write_sys_error_zero:
 mov rax,-5
.write_sys_error:
 mov rdi,rax
 call file_map_errno
 xor edx,edx
 jmp .write_return
.write_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.write_error_no_count:
 xor edx,edx
.write_return:
 pop r13
 pop r12
 pop rbx
 ret

nebo_file_write_all:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 xor ebx,ebx
.write_all_loop:
 cmp rbx,r14
 jae .write_all_success
 mov rdi,r12
 lea rsi,[r13+rbx]
 mov rdx,r14
 sub rdx,rbx
 call nebo_file_write
 test eax,eax
 jnz .write_all_status
 add rbx,rdx
 jmp .write_all_loop
.write_all_success:
 xor eax,eax
.write_all_status:
 mov rdx,rbx
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

nebo_file_flush:
 push r12
 mov r12,rdi
 call file_validate_open_write
 test eax,eax
 jnz .flush_return
.flush_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_FSYNC
 mov rdi,[r12+NEBO_FILE_FD]
 syscall
 cmp rax,-EINTR
 je .flush_retry
 cmp rax,-4095
 jae .flush_error
 xor eax,eax
 jmp .flush_return
.flush_error:
 mov rdi,rax
 call file_map_errno
.flush_return:
 pop r12
 ret

; rdi=File, rsi=signed offset, rdx=SEEK_* origin. eax=status, rdx=position.
nebo_file_seek:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call file_validate_open
 test eax,eax
 jnz .seek_error_no_position
 cmp r14,NEBO_FILE_SEEK_END
 ja .seek_invalid
.seek_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_LSEEK
 mov rdi,[r12+NEBO_FILE_FD]
 mov rsi,r13
 mov rdx,r14
 syscall
 cmp rax,-EINTR
 je .seek_retry
 cmp rax,-4095
 jae .seek_sys_error
 mov rdx,rax
 xor eax,eax
 jmp .seek_return
.seek_invalid:
 mov eax,NEBO_FILE_ERROR_IO
 jmp .seek_error_no_position
.seek_sys_error:
 mov rdi,rax
 call file_map_errno
.seek_error_no_position:
 xor edx,edx
.seek_return:
 pop r14
 pop r13
 pop r12
 ret

; rdi=File, rsi=FileMetadata40. eax=status.
nebo_file_metadata:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call file_validate_open
 test eax,eax
 jnz .metadata_return
 test r13,r13
 jz .metadata_invalid
 mov rcx,[r12+NEBO_FILE_CAPABILITY]
 test qword [rcx+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_METADATA
 jz .metadata_denied
 sub rsp,160
.metadata_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_NEWFSTATAT
 mov rdi,[r12+NEBO_FILE_FD]
 lea rsi,[rel file_empty_path]
 mov rdx,rsp
 mov r10d,0x1000
 syscall
 cmp rax,-EINTR
 je .metadata_retry
 cmp rax,-4095
 jae .metadata_sys_error
 mov rax,[rsp+48]
 mov [r13+NEBO_FILE_METADATA_SIZE_BYTES],rax
 mov ebx,[rsp+24]
 mov [r13+NEBO_FILE_METADATA_MODE],rbx
 mov qword [r13+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_UNKNOWN
 mov eax,ebx
 and eax,0170000o
 cmp eax,0100000o
 jne .metadata_check_dir
 mov qword [r13+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_REGULAR
 jmp .metadata_type_done
.metadata_check_dir:
 cmp eax,0040000o
 jne .metadata_check_link
 mov qword [r13+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_DIRECTORY
 jmp .metadata_type_done
.metadata_check_link:
 cmp eax,0120000o
 jne .metadata_type_done
 mov qword [r13+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_SYMLINK
.metadata_type_done:
 mov qword [r13+NEBO_FILE_METADATA_EXISTS],1
 add rsp,160
 mov rdi,r12
 xor esi,esi
 mov edx,NEBO_FILE_SEEK_CURRENT
 call nebo_file_seek
 test eax,eax
 jnz .metadata_return
 mov [r13+NEBO_FILE_METADATA_POSITION],rdx
 xor eax,eax
 jmp .metadata_return
.metadata_sys_error:
 mov rdi,rax
 add rsp,160
 call file_map_errno
 jmp .metadata_return
.metadata_invalid:
 mov eax,NEBO_FILE_ERROR_IO
 jmp .metadata_return
.metadata_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
.metadata_return:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=File, rsi=non-negative new byte length. eax=status.
nebo_file_set_length:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call file_validate_open_write
 test eax,eax
 jnz .set_length_return
 test r13,r13
 js .set_length_limit
 mov rcx,[r12+NEBO_FILE_CAPABILITY]
 test qword [rcx+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_METADATA
 jz .set_length_denied
.set_length_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_FTRUNCATE
 mov rdi,[r12+NEBO_FILE_FD]
 mov rsi,r13
 syscall
 cmp rax,-EINTR
 je .set_length_retry
 cmp rax,-4095
 jae .set_length_error
 xor eax,eax
 jmp .set_length_return
.set_length_error:
 mov rdi,rax
 call file_map_errno
 jmp .set_length_return
.set_length_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 jmp .set_length_return
.set_length_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.set_length_return:
 pop r13
 pop r12
 ret

; rdi=capability, rsi=normalized relative path, rdx=length, rcx=metadata.
; ENOENT is a successful exists=false result; permission failures remain errors.
nebo_path_metadata:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r12,r12
 jz .path_metadata_denied
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 cmp [r12+NEBO_FILE_CAPABILITY_MAGIC],rax
 jne .path_metadata_denied
 test qword [r12+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_METADATA
 jz .path_metadata_denied
 test r13,r13
 jz .path_metadata_invalid
 test r14,r14
 jz .path_metadata_invalid
 cmp r14,NEBO_PATH_MAX_BYTES
 ja .path_metadata_limit
 test r15,r15
 jz .path_metadata_invalid
 cmp byte [r13],'/'
 je .path_metadata_escape
 cmp byte [r13+r14],0
 jne .path_metadata_invalid
 sub rsp,192
 mov qword [rsp],0x280000 ; O_PATH | O_CLOEXEC
 mov qword [rsp+8],0
 mov qword [rsp+16],NEBO_OPENAT2_REQUIRED_RESOLVE
.path_metadata_open_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_OPENAT2
 mov rdi,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 mov rsi,r13
 mov rdx,rsp
 mov r10d,24
 syscall
 cmp rax,-EINTR
 je .path_metadata_open_retry
 cmp rax,-4095
 jae .path_metadata_open_error
 mov rbx,rax
.path_metadata_stat_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_NEWFSTATAT
 mov rdi,rbx
 lea rsi,[rel file_empty_path]
 lea rdx,[rsp+32]
 mov r10d,0x1000
 syscall
 cmp rax,-EINTR
 je .path_metadata_stat_retry
 cmp rax,-4095
 jae .path_metadata_stat_error
 mov rax,[rsp+80]
 mov [r15+NEBO_FILE_METADATA_SIZE_BYTES],rax
 mov eax,[rsp+56]
 mov [r15+NEBO_FILE_METADATA_MODE],rax
 mov qword [r15+NEBO_FILE_METADATA_POSITION],0
 mov qword [r15+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_UNKNOWN
 mov edx,eax
 and edx,0170000o
 cmp edx,0100000o
 jne .path_metadata_dir
 mov qword [r15+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_REGULAR
 jmp .path_metadata_type_done
.path_metadata_dir:
 cmp edx,0040000o
 jne .path_metadata_link
 mov qword [r15+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_DIRECTORY
 jmp .path_metadata_type_done
.path_metadata_link:
 cmp edx,0120000o
 jne .path_metadata_type_done
 mov qword [r15+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_SYMLINK
.path_metadata_type_done:
 mov qword [r15+NEBO_FILE_METADATA_EXISTS],1
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,rbx
 syscall
 add rsp,192
 xor eax,eax
 jmp .path_metadata_return
.path_metadata_stat_error:
 mov rdi,rax
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rsi,rdi
 mov rdi,rbx
 syscall
 mov rdi,rsi
 add rsp,192
 call file_map_errno
 jmp .path_metadata_return
.path_metadata_open_error:
 cmp rax,-ENOENT
 jne .path_metadata_open_mapped
 mov qword [r15+NEBO_FILE_METADATA_SIZE_BYTES],0
 mov qword [r15+NEBO_FILE_METADATA_POSITION],0
 mov qword [r15+NEBO_FILE_METADATA_MODE],0
 mov qword [r15+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_UNKNOWN
 mov qword [r15+NEBO_FILE_METADATA_EXISTS],0
 add rsp,192
 xor eax,eax
 jmp .path_metadata_return
.path_metadata_open_mapped:
 mov rdi,rax
 add rsp,192
 call file_map_errno
 jmp .path_metadata_return
.path_metadata_invalid:
 mov eax,NEBO_FILE_ERROR_INVALID_PATH
 jmp .path_metadata_return
.path_metadata_escape:
 mov eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jmp .path_metadata_return
.path_metadata_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jmp .path_metadata_return
.path_metadata_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
.path_metadata_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=capability, rsi=path, rdx=length. eax=status, edx=boolean.
nebo_path_exists:
 mov r8d,NEBO_FILE_TYPE_UNKNOWN
 jmp path_query_type
nebo_path_is_file:
 mov r8d,NEBO_FILE_TYPE_REGULAR
 jmp path_query_type
nebo_path_is_directory:
 mov r8d,NEBO_FILE_TYPE_DIRECTORY
path_query_type:
 push rbx
 push r12
 sub rsp,NEBO_FILE_METADATA_SIZE
 mov ebx,r8d
 mov rcx,rsp
 call nebo_path_metadata
 test eax,eax
 jnz .path_query_return
 mov rdx,[rsp+NEBO_FILE_METADATA_EXISTS]
 test ebx,ebx
 jz .path_query_return
 test rdx,rdx
 jz .path_query_return
 xor edx,edx
 cmp [rsp+NEBO_FILE_METADATA_TYPE],rbx
 sete dl
.path_query_return:
 add rsp,NEBO_FILE_METADATA_SIZE
 pop r12
 pop rbx
 ret

nebo_file_close:
 push r12
 push r13
 mov r12,rdi
 test r12,r12
 jz .close_closed
 cmp qword [r12+NEBO_FILE_STATE],NEBO_FILE_STATE_OPEN
 jne .close_closed
 mov r13,[r12+NEBO_FILE_CAPABILITY]
 mov qword [r12+NEBO_FILE_STATE],NEBO_FILE_STATE_CLOSED
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,[r12+NEBO_FILE_FD]
 syscall
 mov qword [r12+NEBO_FILE_FD],-1
 test r13,r13
 jz .close_count_done
 cmp dword [r13+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES],0
 je .close_count_done
 dec dword [r13+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES]
.close_count_done:
 cmp rax,-4095
 jae .close_error
 xor eax,eax
 jmp .close_return
.close_error:
 mov rdi,rax
 call file_map_errno
 jmp .close_return
.close_closed:
 mov eax,NEBO_FILE_ERROR_CLOSED
.close_return:
 pop r13
 pop r12
 ret

file_validate_open_read:
 call file_validate_open
 test eax,eax
 jnz file_validate_open_done
 mov rcx,[r12+NEBO_FILE_CAPABILITY]
 test qword [rcx+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_READ
 jz file_validate_denied
 xor eax,eax
file_validate_open_done:
 ret
file_validate_open:
 test r12,r12
 jz file_validate_closed
 cmp qword [r12+NEBO_FILE_STATE],NEBO_FILE_STATE_OPEN
 jne file_validate_closed
 mov rcx,[r12+NEBO_FILE_CAPABILITY]
 test rcx,rcx
 jz file_validate_denied
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 cmp [rcx+NEBO_FILE_CAPABILITY_MAGIC],rax
 jne file_validate_denied
 xor eax,eax
 ret
file_validate_open_write:
 call file_validate_open
 test eax,eax
 jnz file_validate_open_done
 mov rcx,[r12+NEBO_FILE_CAPABILITY]
 test qword [rcx+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_WRITE
 jz file_validate_denied
 xor eax,eax
 ret
file_validate_closed:
 mov eax,NEBO_FILE_ERROR_CLOSED
 ret
file_validate_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 ret

; rdi holds a negative Linux syscall result.
file_map_errno:
 mov rax,rdi
 neg eax
 cmp eax,ENOENT
 je .errno_not_found
 cmp eax,EACCES
 je .errno_denied
 cmp eax,EPERM
 je .errno_denied
 cmp eax,EEXIST
 je .errno_exists
 cmp eax,EINTR
 je .errno_interrupted
 cmp eax,ENOSYS
 je .errno_unsupported
 cmp eax,EXDEV
 je .errno_escape
 cmp eax,ELOOP
 je .errno_escape
 mov eax,NEBO_FILE_ERROR_IO
 ret
.errno_not_found:
 mov eax,NEBO_FILE_ERROR_NOT_FOUND
 ret
.errno_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 ret
.errno_exists:
 mov eax,NEBO_FILE_ERROR_ALREADY_EXISTS
 ret
.errno_interrupted:
 mov eax,NEBO_FILE_ERROR_INTERRUPTED
 ret
.errno_unsupported:
 mov eax,NEBO_FILE_ERROR_UNSUPPORTED_TARGET
 ret
.errno_escape:
 mov eax,NEBO_FILE_ERROR_PATH_ESCAPE
 ret

section .rodata
file_empty_path db 0
