bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"

extern nebo_file_capability_init
extern nebo_file_open
extern nebo_file_create
extern nebo_file_read
extern nebo_file_read_exact
extern nebo_file_write_all
extern nebo_file_flush
extern nebo_file_close

%define SYS_CLOSE 3
%define SYS_OPENAT 257
%define AT_FDCWD -100
%define O_DIRECTORY 0x10000
%define O_CLOEXEC 0x80000

section .rodata
sample db 'sample.bin',0
sample_len equ 10
escape db 'escape',0
escape_len equ 6
payload db 'hello'

section .bss
capability resb NEBO_FILE_CAPABILITY_SIZE
readonly_capability resb NEBO_FILE_CAPABILITY_SIZE
file_one resb NEBO_FILE_SIZE
file_two resb NEBO_FILE_SIZE
read_buffer resb 16

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
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
 mov edx,1
 mov ecx,NEBO_FILE_CAP_READ | NEBO_FILE_CAP_WRITE | NEBO_FILE_CAP_CREATE
 mov r8d,1
 mov r9d,4096
 call nebo_file_capability_init
 test eax,eax
 jnz .fail3

 lea rdi,[file_one]
 lea rsi,[capability]
 lea rdx,[sample]
 mov ecx,sample_len
 mov r8d,NEBO_FILE_OPEN_EXCLUSIVE
 mov r9d,0600o
 call nebo_file_create
 test eax,eax
 jnz .fail4
 cmp dword [capability+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES],1
 jne .fail5

 lea rdi,[file_two]
 lea rsi,[capability]
 lea rdx,[sample]
 mov ecx,sample_len
 xor r8d,r8d
 xor r9d,r9d
 call nebo_file_open
 cmp eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jne .fail6

 lea rdi,[file_one]
 lea rsi,[payload]
 mov edx,5
 call nebo_file_write_all
 test eax,eax
 jnz .fail7
 cmp rdx,5
 jne .fail8
 lea rdi,[file_one]
 call nebo_file_flush
 test eax,eax
 jnz .fail9
 lea rdi,[file_one]
 call nebo_file_close
 test eax,eax
 jnz .fail10
 cmp dword [capability+NEBO_FILE_CAPABILITY_ACTIVE_HANDLES],0
 jne .fail11
 lea rdi,[file_one]
 call nebo_file_close
 cmp eax,NEBO_FILE_ERROR_CLOSED
 jne .fail12

 lea rdi,[file_one]
 lea rsi,[capability]
 lea rdx,[sample]
 mov ecx,sample_len
 xor r8d,r8d
 xor r9d,r9d
 call nebo_file_open
 test eax,eax
 jnz .fail13
 lea rdi,[file_one]
 lea rsi,[read_buffer]
 mov edx,5
 call nebo_file_read_exact
 test eax,eax
 jnz .fail14
 cmp rdx,5
 jne .fail15
 cmp dword [read_buffer],0x6c6c6568
 jne .fail16
 cmp byte [read_buffer+4],'o'
 jne .fail17
 lea rdi,[file_one]
 lea rsi,[read_buffer+5]
 mov edx,1
 call nebo_file_read
 cmp eax,NEBO_FILE_ERROR_EOF
 jne .fail18
 test rdx,rdx
 jnz .fail19
 lea rdi,[file_one]
 call nebo_file_close
 test eax,eax
 jnz .fail20

 lea rdi,[file_one]
 lea rsi,[capability]
 lea rdx,[sample]
 mov ecx,sample_len
 mov r8d,NEBO_FILE_OPEN_EXCLUSIVE
 mov r9d,0600o
 call nebo_file_create
 cmp eax,NEBO_FILE_ERROR_ALREADY_EXISTS
 jne .fail21

 lea rdi,[readonly_capability]
 mov rsi,r15
 mov edx,2
 mov ecx,NEBO_FILE_CAP_READ
 mov r8d,2
 mov r9d,4096
 call nebo_file_capability_init
 test eax,eax
 jnz .fail22
 lea rdi,[file_two]
 lea rsi,[readonly_capability]
 lea rdx,[sample]
 mov ecx,sample_len
 mov r8d,NEBO_FILE_OPEN_EXCLUSIVE
 mov r9d,0600o
 call nebo_file_create
 cmp eax,NEBO_FILE_ERROR_PERMISSION_DENIED
 jne .fail23

 lea rdi,[file_one]
 lea rsi,[capability]
 lea rdx,[sample]
 mov ecx,sample_len
 xor r8d,r8d
 xor r9d,r9d
 call nebo_file_open
 test eax,eax
 jnz .fail24
 lea rdi,[file_one]
 lea rsi,[read_buffer]
 mov edx,7
 call nebo_file_read_exact
 cmp eax,NEBO_FILE_ERROR_EOF
 jne .fail25
 cmp rdx,5
 jne .fail26
 lea rdi,[file_one]
 call nebo_file_close
 test eax,eax
 jnz .fail27

 lea rdi,[file_one]
 lea rsi,[capability]
 lea rdx,[escape]
 mov ecx,escape_len
 xor r8d,r8d
 xor r9d,r9d
 call nebo_file_open
 cmp eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jne .fail28

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
 jmp .exit
.fail27: mov edi,27
 jmp .exit
.fail28: mov edi,28
.exit:
 mov eax,60
 syscall
