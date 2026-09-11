bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"
extern nebo_file_capability_init
extern nebo_file_create
extern nebo_file_close
extern nebo_directory_create
extern nebo_directory_create_all
extern nebo_directory_open
extern nebo_directory_entries
extern nebo_directory_walk
extern nebo_directory_close
extern nebo_path_remove_file
extern nebo_path_remove_directory
extern nebo_path_remove_tree

%define SYS_OPENAT 257
%define SYS_CLOSE 3
%define AT_FDCWD -100
%define O_DIRECTORY 0x10000
%define O_CLOEXEC 0x80000

section .rodata
single db 'single',0
nested db 'tree/child',0
nested_file db 'tree/child/item',0
tree db 'tree',0
victim db 'victim',0
escape db 'escape',0

section .bss
capability resb NEBO_FILE_CAPABILITY_SIZE
directory resb NEBO_DIRECTORY_SIZE
file resb NEBO_FILE_SIZE
entries resb 4096

section .text
global _start
_start:
 cmp qword [rsp],2
 jne .fail1
 mov rsi,[rsp+16]
 mov eax,SYS_OPENAT
 mov rdi,AT_FDCWD
 mov edx,O_DIRECTORY | O_CLOEXEC
 xor r10d,r10d
 syscall
 test rax,rax
 js .fail2
 mov r15,rax
 lea rdi,[capability]
 mov rsi,r15
 mov edx,23
 mov ecx,NEBO_FILE_CAP_ALL
 mov r8d,4
 mov r9d,16384
 call nebo_file_capability_init
 test eax,eax
 jnz .fail3
 lea rdi,[capability]
 lea rsi,[single]
 mov edx,6
 mov ecx,0700o
 call nebo_directory_create
 test eax,eax
 jnz .fail4
 cmp edx,1
 jne .fail5
 lea rdi,[capability]
 lea rsi,[single]
 mov edx,6
 mov ecx,0700o
 call nebo_directory_create
 cmp eax,NEBO_FILE_ERROR_ALREADY_EXISTS
 jne .fail6
 lea rdi,[capability]
 lea rsi,[nested]
 mov edx,10
 mov ecx,0700o
 call nebo_directory_create_all
 test eax,eax
 jnz .fail7
 cmp edx,2
 jne .fail8
 lea rdi,[capability]
 lea rsi,[nested]
 mov edx,10
 mov ecx,0700o
 call nebo_directory_create_all
 test eax,eax
 jnz .fail9
 test edx,edx
 jnz .fail10
 lea rdi,[file]
 lea rsi,[capability]
 lea rdx,[nested_file]
 mov ecx,15
 mov r8d,NEBO_FILE_OPEN_EXCLUSIVE
 mov r9d,0600o
 call nebo_file_create
 test eax,eax
 jnz .fail24
 lea rdi,[file]
 call nebo_file_close
 test eax,eax
 jnz .fail25
 lea rdi,[directory]
 lea rsi,[capability]
 lea rdx,[nested]
 mov ecx,10
 mov r8d,4
 mov r9d,16
 call nebo_directory_open
 test eax,eax
 jnz .fail11
 lea rdi,[directory]
 lea rsi,[entries]
 mov edx,4096
 call nebo_directory_entries
 test eax,eax
 jnz .fail12
 cmp ecx,1
 jne .fail13
 lea rdi,[directory]
 lea rsi,[entries]
 mov edx,4096
 mov ecx,2
 call nebo_directory_walk
 test eax,eax
 jnz .fail14
 test ecx,ecx
 jnz .fail15
 lea rdi,[directory]
 call nebo_directory_close
 test eax,eax
 jnz .fail16
 lea rdi,[directory]
 call nebo_directory_close
 cmp eax,NEBO_FILE_ERROR_CLOSED
 jne .fail17
 lea rdi,[file]
 lea rsi,[capability]
 lea rdx,[victim]
 mov ecx,6
 mov r8d,NEBO_FILE_OPEN_EXCLUSIVE
 mov r9d,0600o
 call nebo_file_create
 test eax,eax
 jnz .fail18
 lea rdi,[file]
 call nebo_file_close
 test eax,eax
 jnz .fail19
 lea rdi,[capability]
 lea rsi,[victim]
 mov edx,6
 call nebo_path_remove_file
 test eax,eax
 jnz .fail20
 lea rdi,[capability]
 lea rsi,[single]
 mov edx,6
 call nebo_path_remove_directory
 test eax,eax
 jnz .fail21
 lea rdi,[capability]
 lea rsi,[tree]
 mov edx,4
 mov ecx,4
 call nebo_path_remove_tree
 test eax,eax
 jne .fail22
 lea rdi,[capability]
 lea rsi,[tree]
 mov edx,4
 mov ecx,4
 call nebo_path_remove_tree
 cmp eax,NEBO_FILE_ERROR_NOT_FOUND
 jne .fail26
 lea rdi,[directory]
 lea rsi,[capability]
 lea rdx,[escape]
 mov ecx,6
 mov r8d,4
 mov r9d,16
 call nebo_directory_open
 cmp eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jne .fail23
 mov eax,SYS_CLOSE
 mov rdi,r15
 syscall
 xor edi,edi
 jmp .exit
.fail1: mov edi,1
 jmp .exit
.fail2: mov edi,2
 jmp .exit
.fail3: mov edi,3
 jmp .exit
.fail4: mov edi,4
 jmp .exit
.fail5: mov edi,5
 jmp .exit
.fail6: mov edi,6
 jmp .exit
.fail7: mov edi,7
 jmp .exit
.fail8: mov edi,8
 jmp .exit
.fail9: mov edi,9
 jmp .exit
.fail10: mov edi,10
 jmp .exit
.fail11: mov edi,11
 jmp .exit
.fail12: mov edi,12
 jmp .exit
.fail13: mov edi,13
 jmp .exit
.fail14: mov edi,14
 jmp .exit
.fail15: mov edi,15
 jmp .exit
.fail16: mov edi,16
 jmp .exit
.fail17: mov edi,17
 jmp .exit
.fail18: mov edi,18
 jmp .exit
.fail19: mov edi,19
 jmp .exit
.fail20: mov edi,20
 jmp .exit
.fail21: mov edi,21
 jmp .exit
.fail22: mov edi,22
 jmp .exit
.fail23: mov edi,23
 jmp .exit
.fail24: mov edi,24
 jmp .exit
.fail25: mov edi,25
 jmp .exit
.fail26: mov edi,26
.exit:
 mov eax,60
 syscall
