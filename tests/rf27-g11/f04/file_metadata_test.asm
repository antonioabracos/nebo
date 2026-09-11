bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"

extern nebo_file_capability_init
extern nebo_file_create
extern nebo_file_write_all
extern nebo_file_seek
extern nebo_file_metadata
extern nebo_file_set_length
extern nebo_path_exists
extern nebo_path_is_file
extern nebo_path_is_directory
extern nebo_file_close

%define SYS_OPENAT 257
%define SYS_CLOSE 3
%define AT_FDCWD -100
%define O_DIRECTORY 0x10000
%define O_CLOEXEC 0x80000

section .rodata
file_name db 'metadata.bin',0
payload db 'abcdefgh'

section .bss
capability resb NEBO_FILE_CAPABILITY_SIZE
file resb NEBO_FILE_SIZE
metadata resb NEBO_FILE_METADATA_SIZE

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
 mov edx,17
 mov ecx,NEBO_FILE_CAP_READ | NEBO_FILE_CAP_WRITE | NEBO_FILE_CAP_CREATE | NEBO_FILE_CAP_METADATA
 mov r8d,2
 mov r9d,4096
 call nebo_file_capability_init
 test eax,eax
 jnz .fail3
 lea rdi,[file]
 lea rsi,[capability]
 lea rdx,[file_name]
 mov ecx,12
 mov r8d,NEBO_FILE_OPEN_EXCLUSIVE
 mov r9d,0600o
 call nebo_file_create
 test eax,eax
 jnz .fail4
 lea rdi,[file]
 lea rsi,[payload]
 mov edx,8
 call nebo_file_write_all
 test eax,eax
 jnz .fail5
 lea rdi,[file]
 xor esi,esi
 mov edx,NEBO_FILE_SEEK_SET
 call nebo_file_seek
 test eax,eax
 jnz .fail6
 test rdx,rdx
 jnz .fail7
 lea rdi,[file]
 mov rsi,3
 mov edx,NEBO_FILE_SEEK_CURRENT
 call nebo_file_seek
 test eax,eax
 jnz .fail8
 cmp rdx,3
 jne .fail9
 lea rdi,[file]
 lea rsi,[metadata]
 call nebo_file_metadata
 test eax,eax
 jnz .fail10
 cmp qword [metadata+NEBO_FILE_METADATA_SIZE_BYTES],8
 jne .fail11
 cmp qword [metadata+NEBO_FILE_METADATA_POSITION],3
 jne .fail12
 cmp qword [metadata+NEBO_FILE_METADATA_TYPE],NEBO_FILE_TYPE_REGULAR
 jne .fail13
 cmp qword [metadata+NEBO_FILE_METADATA_EXISTS],1
 jne .fail14
 lea rdi,[file]
 mov rsi,4
 call nebo_file_set_length
 test eax,eax
 jnz .fail15
 lea rdi,[file]
 xor esi,esi
 mov edx,NEBO_FILE_SEEK_END
 call nebo_file_seek
 test eax,eax
 jnz .fail16
 cmp rdx,4
 jne .fail17
 lea rdi,[file]
 mov rsi,-1
 call nebo_file_set_length
 cmp eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jne .fail18
 lea rdi,[file]
 call nebo_file_close
 test eax,eax
 jnz .fail19
 lea rdi,[file]
 xor esi,esi
 xor edx,edx
 call nebo_file_seek
 cmp eax,NEBO_FILE_ERROR_CLOSED
 jne .fail20
 lea rdi,[capability]
 lea rsi,[file_name]
 mov edx,12
 call nebo_path_exists
 test eax,eax
 jnz .fail21
 cmp edx,1
 jne .fail22
 lea rdi,[capability]
 lea rsi,[file_name]
 mov edx,12
 call nebo_path_is_file
 test eax,eax
 jnz .fail23
 cmp edx,1
 jne .fail24
 lea rdi,[capability]
 lea rsi,[file_name]
 mov edx,12
 call nebo_path_is_directory
 test eax,eax
 jnz .fail25
 test edx,edx
 jnz .fail26
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
