bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"

%define EINTR 4
%define ENOENT 2
%define EACCES 13
%define EEXIST 17
%define ENOTEMPTY 39
%define ELOOP 40
%define EXDEV 18
%define ENOSYS 38
%define O_DIRECTORY 0x10000
%define O_CLOEXEC 0x80000
%define AT_REMOVEDIR 0x200

section .text
global nebo_directory_create
global nebo_directory_create_all
global nebo_directory_open
global nebo_directory_entries
global nebo_directory_walk
global nebo_directory_close
global nebo_path_remove_file
global nebo_path_remove_directory
global nebo_path_remove_tree

; rdi=capability, rsi=single normalized leaf, rdx=len, rcx=mode.
; eax=status, edx=created count.
nebo_directory_create:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbx,rcx
 mov rdi,r12
 mov esi,NEBO_FILE_CAP_CREATE | NEBO_FILE_CAP_TRAVERSE
 call directory_validate_cap
 test eax,eax
 jnz .create_return_zero
 mov rdi,r13
 mov rsi,r14
 call directory_validate_leaf
 test eax,eax
 jnz .create_return_zero
.create_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_MKDIRAT
 mov rdi,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 mov rsi,r13
 mov rdx,rbx
 syscall
 cmp rax,-EINTR
 je .create_retry
 cmp rax,-4095
 jae .create_error
 xor eax,eax
 mov edx,1
 jmp .create_return
.create_error:
 mov rdi,rax
 call directory_map_errno
.create_return_zero:
 xor edx,edx
.create_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=capability, rsi=normalized relative path, rdx=len, rcx=mode.
; Existing directory components are accepted after secure openat2 validation.
nebo_directory_create_all:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,288
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbp,rcx
 mov rdi,r12
 mov esi,NEBO_FILE_CAP_CREATE | NEBO_FILE_CAP_TRAVERSE
 call directory_validate_cap
 test eax,eax
 jnz .create_all_fail
 test r13,r13
 jz .create_all_invalid
 test r14,r14
 jz .create_all_invalid
 cmp r14,NEBO_PATH_MAX_BYTES
 ja .create_all_limit
 cmp byte [r13],'/'
 je .create_all_escape
 cmp byte [r13+r14],0
 jne .create_all_invalid
 mov r15,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 xor ebx,ebx                 ; created count
 mov dword [rsp+280],0        ; source index
 mov dword [rsp+284],0        ; component bytes
.create_all_scan:
 mov r10d,[rsp+280]
 mov r11d,[rsp+284]
 cmp r10,r14
 jae .create_all_finish_component
 mov al,[r13+r10]
 inc r10
 mov [rsp+280],r10d
 cmp al,'/'
 je .create_all_component
 test al,al
 jz .create_all_invalid_owned
 cmp r11,NEBO_PATH_MAX_COMPONENT_BYTES
 jae .create_all_limit_owned
 mov [rsp+r11],al
 inc r11
 mov [rsp+284],r11d
 jmp .create_all_scan
.create_all_finish_component:
 test r11,r11
 jz .create_all_success
.create_all_component:
 test r11,r11
 jz .create_all_invalid_owned
 mov byte [rsp+r11],0
.create_all_mkdir_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_MKDIRAT
 mov rdi,r15
 mov rsi,rsp
 mov rdx,rbp
 syscall
 cmp rax,-EINTR
 je .create_all_mkdir_retry
 cmp rax,-EEXIST
 je .create_all_open
 cmp rax,-4095
 jae .create_all_sys_error_owned
 inc ebx
.create_all_open:
 mov qword [rsp+256],O_DIRECTORY | O_CLOEXEC
 mov qword [rsp+264],0
 mov qword [rsp+272],NEBO_OPENAT2_REQUIRED_RESOLVE
.create_all_open_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_OPENAT2
 mov rdi,r15
 mov rsi,rsp
 lea rdx,[rsp+256]
 mov r10d,24
 syscall
 cmp rax,-EINTR
 je .create_all_open_retry
 cmp rax,-4095
 jae .create_all_sys_error_owned
 mov r9,rax
 cmp r15,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 je .create_all_take_child
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,r15
 syscall
.create_all_take_child:
 mov r15,r9
 mov dword [rsp+284],0
 jmp .create_all_scan
.create_all_success:
 cmp r15,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 je .create_all_success_no_close
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,r15
 syscall
.create_all_success_no_close:
 xor eax,eax
 mov edx,ebx
 jmp .create_all_return
.create_all_sys_error_owned:
 mov rdi,rax
 call directory_map_errno
 jmp .create_all_close_fail
.create_all_invalid_owned:
 mov eax,NEBO_FILE_ERROR_INVALID_PATH
 jmp .create_all_close_fail
.create_all_limit_owned:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.create_all_close_fail:
 mov ebx,eax
 cmp r15,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 je .create_all_restore_error
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,r15
 syscall
.create_all_restore_error:
 mov eax,ebx
 jmp .create_all_fail
.create_all_invalid:
 mov eax,NEBO_FILE_ERROR_INVALID_PATH
 jmp .create_all_fail
.create_all_escape:
 mov eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jmp .create_all_fail
.create_all_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.create_all_fail:
 xor edx,edx
.create_all_return:
 add rsp,288
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=Directory64, rsi=capability, rdx=path, rcx=len,
; r8=depth limit, r9=entry limit. eax=status.
nebo_directory_open:
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
 mov rdi,r13
 mov esi,NEBO_FILE_CAP_TRAVERSE
 call directory_validate_cap
 test eax,eax
 jnz .open_return
 test r12,r12
 jz .open_invalid
 test r14,r14
 jz .open_invalid
 test r15,r15
 jz .open_invalid
 cmp r15,NEBO_PATH_MAX_BYTES
 ja .open_limit
 test rbx,rbx
 jz .open_limit
 cmp rbx,NEBO_DIRECTORY_MAX_DEPTH
 ja .open_limit
 test r9,r9
 jz .open_limit
 cmp r9,NEBO_DIRECTORY_MAX_ENTRIES
 ja .open_limit
 mov eax,[r13+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES]
 cmp rax,[r13+NEBO_FILE_CAPABILITY_MAX_HANDLES]
 jae .open_limit
 sub rsp,32
 mov qword [rsp],O_DIRECTORY | O_CLOEXEC
 mov qword [rsp+8],0
 mov qword [rsp+16],NEBO_OPENAT2_REQUIRED_RESOLVE
.open_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_OPENAT2
 mov rdi,[r13+NEBO_FILE_CAPABILITY_ROOT_FD]
 mov rsi,r14
 mov rdx,rsp
 mov r10d,24
 syscall
 cmp rax,-EINTR
 je .open_retry
 add rsp,32
 cmp rax,-4095
 jae .open_error
 mov [r12+NEBO_DIRECTORY_FD],rax
 mov qword [r12+NEBO_DIRECTORY_STATE],NEBO_FILE_STATE_OPEN
 mov [r12+NEBO_DIRECTORY_CAPABILITY],r13
 mov [r12+NEBO_DIRECTORY_DEPTH_LIMIT],rbx
 mov [r12+NEBO_DIRECTORY_ENTRY_LIMIT],r9
 mov qword [r12+NEBO_DIRECTORY_GENERATION],1
 mov qword [r12+NEBO_DIRECTORY_FLAGS],0
 mov qword [r12+NEBO_DIRECTORY_RESERVED],0
 inc dword [r13+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES]
 xor eax,eax
 jmp .open_return
.open_error:
 mov rdi,rax
 call directory_map_errno
 jmp .open_return
.open_invalid:
 mov eax,NEBO_FILE_ERROR_INVALID_PATH
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

; rdi=Directory, rsi=caller buffer, rdx=capacity. eax=status,
; rdx=bytes returned, rcx=entry count. Dot entries are excluded from count.
nebo_directory_entries:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call directory_validate_open
 test eax,eax
 jnz .entries_zero
 test r13,r13
 jz .entries_invalid
 cmp r14,24
 jb .entries_limit
 cmp r14,65536
 ja .entries_limit
.entries_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_GETDENTS64
 mov rdi,[r12+NEBO_DIRECTORY_FD]
 mov rsi,r13
 mov rdx,r14
 syscall
 cmp rax,-EINTR
 je .entries_retry
 cmp rax,-4095
 jae .entries_error
 mov r14,rax
 xor ebx,ebx
 xor r8d,r8d
.entries_scan:
 cmp r8,r14
 jae .entries_success
 movzx r9d,word [r13+r8+16]
 cmp r9d,19
 jb .entries_invalid
 mov al,[r13+r8+19]
 cmp al,'.'
 jne .entries_count
 cmp byte [r13+r8+20],0
 je .entries_next
 cmp byte [r13+r8+20],'.'
 jne .entries_count
 cmp byte [r13+r8+21],0
 je .entries_next
.entries_count:
 inc ebx
 cmp rbx,[r12+NEBO_DIRECTORY_ENTRY_LIMIT]
 ja .entries_limit
.entries_next:
 add r8,r9
 cmp r8,r14
 ja .entries_invalid
 jmp .entries_scan
.entries_success:
 xor eax,eax
 mov rdx,r14
 mov ecx,ebx
 jmp .entries_return
.entries_error:
 mov rdi,rax
 call directory_map_errno
 jmp .entries_zero
.entries_invalid:
 mov eax,NEBO_FILE_ERROR_IO
 jmp .entries_zero
.entries_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.entries_zero:
 xor edx,edx
 xor ecx,ecx
.entries_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Bounded walk primitive: one directory page per call; caller supplies explicit
; depth and drives recursion with returned entries, so no hidden allocation.
; rdi=Directory, rsi=buffer, rdx=capacity, rcx=requested depth.
nebo_directory_walk:
 test rcx,rcx
 jz .walk_limit
 cmp rcx,[rdi+NEBO_DIRECTORY_DEPTH_LIMIT]
 ja .walk_limit
 jmp nebo_directory_entries
.walk_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 xor ecx,ecx
 ret

nebo_directory_close:
 push r12
 push r13
 mov r12,rdi
 call directory_validate_open
 test eax,eax
 jnz .close_return
 mov r13,[r12+NEBO_DIRECTORY_CAPABILITY]
 mov qword [r12+NEBO_DIRECTORY_STATE],NEBO_FILE_STATE_CLOSED
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,[r12+NEBO_DIRECTORY_FD]
 syscall
 mov qword [r12+NEBO_DIRECTORY_FD],-1
 cmp dword [r13+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES],0
 je .close_map
 dec dword [r13+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES]
.close_map:
 cmp rax,-4095
 jae .close_error
 xor eax,eax
 jmp .close_return
.close_error:
 mov rdi,rax
 call directory_map_errno
.close_return:
 pop r13
 pop r12
 ret

nebo_path_remove_file:
 xor ecx,ecx
 jmp path_remove_leaf
nebo_path_remove_directory:
 mov ecx,AT_REMOVEDIR
 jmp path_remove_leaf
; rdi=capability, rsi=single root leaf, rdx=len, rcx=depth limit.
nebo_path_remove_tree:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rcx
 mov rdi,r12
 mov esi,NEBO_FILE_CAP_DELETE | NEBO_FILE_CAP_TRAVERSE
 call directory_validate_cap
 test eax,eax
 jnz .remove_tree_return
 mov rdi,r13
 mov rsi,rdx
 call directory_validate_leaf
 test eax,eax
 jnz .remove_tree_return
 test r14,r14
 jz .remove_tree_limit
 cmp r14,NEBO_DIRECTORY_MAX_DEPTH
 ja .remove_tree_limit
 mov rdi,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 mov rsi,r13
 mov rdx,r14
 call directory_remove_tree_at
 jmp .remove_tree_return
.remove_tree_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.remove_tree_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

path_remove_leaf:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov ebx,ecx
 mov rdi,r12
 mov esi,NEBO_FILE_CAP_DELETE
 call directory_validate_cap
 test eax,eax
 jnz .remove_return
 mov rdi,r13
 mov rsi,r14
 call directory_validate_leaf
 test eax,eax
 jnz .remove_return
.remove_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_UNLINKAT
 mov rdi,[r12+NEBO_FILE_CAPABILITY_ROOT_FD]
 mov rsi,r13
 mov edx,ebx
 syscall
 cmp rax,-EINTR
 je .remove_retry
 cmp rax,-4095
 jae .remove_error
 xor eax,eax
 jmp .remove_return
.remove_error:
 mov rdi,rax
 call directory_map_errno
.remove_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=parent fd, rsi=NUL leaf, rdx=remaining depth. Recursively removes without
; following symlinks. Each frame owns one directory fd and a fixed 4096-byte page.
directory_remove_tree_at:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,4128
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov [rsp+4120],r13
 test r14,r14
 jz .tree_limit
 mov qword [rsp+4096],O_DIRECTORY | O_CLOEXEC
 mov qword [rsp+4104],0
 mov qword [rsp+4112],NEBO_OPENAT2_REQUIRED_RESOLVE
.tree_open_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_OPENAT2
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+4096]
 mov r10d,24
 syscall
 cmp rax,-EINTR
 je .tree_open_retry
 cmp rax,-4095
 jae .tree_open_error
 mov r15,rax
.tree_read:
 mov eax,NEBO_LINUX_X86_64_SYS_GETDENTS64
 mov rdi,r15
 mov rsi,rsp
 mov edx,4096
 syscall
 cmp rax,-EINTR
 je .tree_read
 cmp rax,-4095
 jae .tree_read_error
 test rax,rax
 jz .tree_empty
 mov rbp,rax
 xor ebx,ebx
.tree_scan:
 cmp rbx,rbp
 jae .tree_read
 movzx r8d,word [rsp+rbx+16]
 cmp r8d,19
 jb .tree_corrupt
 lea r13,[rsp+rbx+19]
 cmp byte [r13],'.'
 jne .tree_entry
 cmp byte [r13+1],0
 je .tree_next
 cmp byte [r13+1],'.'
 jne .tree_entry
 cmp byte [r13+2],0
 je .tree_next
.tree_entry:
 cmp byte [rsp+rbx+18],4
 jne .tree_unlink_file
 cmp r14,1
 jbe .tree_limit_open
 mov rdi,r15
 mov rsi,r13
 mov rdx,r14
 dec rdx
 call directory_remove_tree_at
 test eax,eax
 jnz .tree_child_error
 jmp .tree_next
.tree_unlink_file:
.tree_unlink_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_UNLINKAT
 mov rdi,r15
 mov rsi,r13
 xor edx,edx
 syscall
 cmp rax,-EINTR
 je .tree_unlink_retry
 cmp rax,-4095
 jae .tree_unlink_error
.tree_next:
 movzx r8d,word [rsp+rbx+16]
 add rbx,r8
 cmp rbx,rbp
 ja .tree_corrupt
 jmp .tree_scan
.tree_empty:
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,r15
 syscall
.tree_remove_dir_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_UNLINKAT
 mov rdi,r12
 mov rsi,[rsp+4120]
 mov edx,AT_REMOVEDIR
 syscall
 cmp rax,-EINTR
 je .tree_remove_dir_retry
 cmp rax,-4095
 jae .tree_remove_dir_error
 xor eax,eax
 jmp .tree_return
.tree_open_error:
 mov rdi,rax
 call directory_map_errno
 jmp .tree_return
.tree_read_error:
 mov rdi,rax
 call directory_map_errno
 jmp .tree_close_error
.tree_unlink_error:
 mov rdi,rax
 call directory_map_errno
 jmp .tree_close_error
.tree_remove_dir_error:
 mov rdi,rax
 call directory_map_errno
 jmp .tree_return
.tree_corrupt:
 mov eax,NEBO_FILE_ERROR_IO
 jmp .tree_close_error
.tree_limit_open:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jmp .tree_close_error
.tree_child_error:
.tree_close_error:
 mov ebx,eax
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,r15
 syscall
 mov eax,ebx
 jmp .tree_return
.tree_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.tree_return:
 add rsp,4128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

directory_validate_cap:
 test rdi,rdi
 jz .cap_denied
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 cmp [rdi+NEBO_FILE_CAPABILITY_MAGIC],rax
 jne .cap_denied
 mov rax,[rdi+NEBO_FILE_CAPABILITY_PERMISSIONS]
 and rax,rsi
 cmp rax,rsi
 jne .cap_denied
 xor eax,eax
 ret
.cap_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 ret

directory_validate_open:
 test r12,r12
 jz .open_closed
 cmp qword [r12+NEBO_DIRECTORY_STATE],NEBO_FILE_STATE_OPEN
 jne .open_closed
 mov rcx,[r12+NEBO_DIRECTORY_CAPABILITY]
 test rcx,rcx
 jz .open_denied
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 cmp [rcx+NEBO_FILE_CAPABILITY_MAGIC],rax
 jne .open_denied
 xor eax,eax
 ret
.open_closed:
 mov eax,NEBO_FILE_ERROR_CLOSED
 ret
.open_denied:
 mov eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 ret

; rdi=path rsi=len; single component only, NUL exactly at len.
directory_validate_leaf:
 test rdi,rdi
 jz .leaf_invalid
 test rsi,rsi
 jz .leaf_invalid
 cmp rsi,NEBO_PATH_MAX_COMPONENT_BYTES
 ja .leaf_limit
 cmp byte [rdi],'/'
 je .leaf_escape
 cmp byte [rdi+rsi],0
 jne .leaf_invalid
 xor ecx,ecx
.leaf_scan:
 cmp rcx,rsi
 jae .leaf_ok
 mov al,[rdi+rcx]
 test al,al
 jz .leaf_invalid
 cmp al,'/'
 je .leaf_escape
 inc rcx
 jmp .leaf_scan
.leaf_ok:
 xor eax,eax
 ret
.leaf_invalid:
 mov eax,NEBO_FILE_ERROR_INVALID_PATH
 ret
.leaf_escape:
 mov eax,NEBO_FILE_ERROR_PATH_ESCAPE
 ret
.leaf_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 ret

directory_map_errno:
 neg eax
 cmp eax,ENOENT
 je .errno_not_found
 cmp eax,EACCES
 je .errno_denied
 cmp eax,EEXIST
 je .errno_exists
 cmp eax,ENOTEMPTY
 je .errno_not_empty
 cmp eax,EINTR
 je .errno_interrupted
 cmp eax,ENOSYS
 je .errno_unsupported
 cmp eax,ELOOP
 je .errno_escape
 cmp eax,EXDEV
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
.errno_not_empty:
 mov eax,NEBO_FILE_ERROR_DIRECTORY_NOT_EMPTY
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
