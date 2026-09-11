bits 64
default rel
%include "runtime/training/checkpoint.inc"
%include "compiler/semantic/system/filesystem_contract.inc"
%define SYS_CLOSE 3
%define SYS_LSEEK 8
%define SYS_MEMFD_CREATE 319
section .rodata
memfd_name db "rf27-g21-f08",0
golden:
 db 0x54,0x43,0x4b,0x31,0x01,0x00,0x40,0x00,0x58,0x00,0x00,0x00,0x18,0x00,0x00,0x00
 db 0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2a,0x00,0x00,0x00,0x00,0x00,0x00,0x00
 db 0xa6,0x8d,0xe4,0xb5,0xe9,0x6a,0x60,0xc8,0xce,0xb3,0xc7,0xb7,0xef,0x93,0x46,0x17
 db 0x25,0xbd,0xbb,0xff,0x35,0x16,0xb1,0x36,0x58,0x5a,0x74,0x3b,0x5c,0x0e,0xc6,0x64
 db 0x00,0x00,0x00,0x00,0x00,0x00,0xf0,0x3f,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40
 db 0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x40
section .data
payload dq 1.0,2.0,3.0
sentinel dq 0x55aa55aa55aa55aa
section .bss
packed resb 88
mutant resb 88
restored resb 24
loaded resb 88
summary resq 4
capability resb NEBO_FILE_CAPABILITY_SIZE
file_value resb NEBO_FILE_SIZE
equal_out resq 1
slot resq 1
seed_a resq 1
seed_b resq 1
seed_a_again resq 1
seed_b_again resq 1
section .text
global _start
_start:
 mov rax,[rel sentinel]
 mov [rel packed],rax
 lea rdi,[rel payload]
 mov esi,24
 mov edx,7
 mov ecx,42
 lea r8,[rel packed]
 mov r9d,87
 call nebo_checkpoint_pack
 cmp eax,NEBO_CHECKPOINT_E_CAPACITY
 jne .fail1
 mov rax,[rel sentinel]
 cmp [rel packed],rax
 jne .fail2
 lea rdi,[rel payload]
 mov esi,24
 mov edx,7
 mov ecx,42
 lea r8,[rel packed]
 mov r9d,88
 call nebo_checkpoint_pack
 test eax,eax
 jnz .fail3
 lea rsi,[rel golden]
 lea rdi,[rel packed]
 mov ecx,11
 repe cmpsq
 jne .fail4
 lea rdi,[rel packed]
 mov esi,88
 lea rdx,[rel summary]
 call nebo_checkpoint_inspect
 test eax,eax
 jnz .fail5
 cmp qword [rel summary+8],24
 jne .fail6
 cmp qword [rel summary+16],7
 jne .fail7
 cmp qword [rel summary+24],42
 jne .fail8
 lea rdi,[rel packed]
 mov esi,88
 lea rdx,[rel restored]
 mov ecx,24
 lea r8,[rel summary]
 call nebo_checkpoint_restore
 test eax,eax
 jnz .fail9
 mov rax,[rel payload]
 cmp [rel restored],rax
 jne .fail10
 mov rax,[rel payload+16]
 cmp [rel restored+16],rax
 jne .fail11
 mov rax,[rel sentinel]
 mov [rel restored],rax
 lea rdi,[rel packed]
 mov esi,88
 lea rdx,[rel restored]
 mov ecx,23
 lea r8,[rel summary]
 call nebo_checkpoint_restore
 cmp eax,NEBO_CHECKPOINT_E_CAPACITY
 jne .fail12
 mov rax,[rel sentinel]
 cmp [rel restored],rax
 jne .fail13
 lea rsi,[rel packed]
 lea rdi,[rel mutant]
 mov ecx,11
 rep movsq
 xor byte [rel mutant+87],1
 mov rax,[rel sentinel]
 mov [rel summary],rax
 lea rdi,[rel mutant]
 mov esi,88
 lea rdx,[rel summary]
 call nebo_checkpoint_inspect
 cmp eax,NEBO_CHECKPOINT_E_CHECKSUM
 jne .fail14
 mov rax,[rel sentinel]
 cmp [rel summary],rax
 jne .fail15
 lea rdi,[rel packed]
 mov esi,88
 lea rdx,[rel golden]
 mov ecx,88
 lea r8,[rel equal_out]
 call nebo_checkpoint_compare
 test eax,eax
 jnz .fail16
 cmp qword [rel equal_out],1
 jne .fail17
 lea rdi,[rel packed]
 mov esi,88
 lea rdx,[rel mutant]
 mov ecx,88
 lea r8,[rel equal_out]
 call nebo_checkpoint_compare
 test eax,eax
 jnz .fail18
 cmp qword [rel equal_out],0
 jne .fail19
 mov qword [rel slot],7
 lea rdi,[rel slot]
 mov esi,8
 call nebo_checkpoint_rotate
 test eax,eax
 jnz .fail20
 cmp qword [rel slot],0
 jne .fail21
 lea rdi,[rel slot]
 mov esi,9
 call nebo_checkpoint_rotate
 cmp eax,NEBO_CHECKPOINT_E_LIMIT
 jne .fail22
 mov edi,42
 lea rsi,[rel seed_a]
 lea rdx,[rel seed_b]
 call nebo_checkpoint_seed_all
 test eax,eax
 jnz .fail23
 mov edi,42
 lea rsi,[rel seed_a_again]
 lea rdx,[rel seed_b_again]
 call nebo_checkpoint_seed_all
 test eax,eax
 jnz .fail24
 mov rax,[rel seed_a]
 cmp [rel seed_a_again],rax
 jne .fail25
 mov rax,[rel seed_b]
 cmp [rel seed_b_again],rax
 jne .fail26
 cmp rax,[rel seed_a]
 je .fail27
 lea rdi,[rel memfd_name]
 xor esi,esi
 mov eax,SYS_MEMFD_CREATE
 syscall
 test eax,eax
 js .fail28
 mov [rel file_value+NEBO_FILE_FD],rax
 mov rdx,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 mov [rel capability+NEBO_FILE_CAPABILITY_MAGIC],rdx
 mov qword [rel capability+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_READ|NEBO_FILE_CAP_WRITE
 mov qword [rel capability+NEBO_FILE_CAPABILITY_MAX_IO_BYTES],NEBO_CHECKPOINT_MAX_BYTES
 mov qword [rel file_value+NEBO_FILE_STATE],NEBO_FILE_STATE_OPEN
 lea rdx,[rel capability]
 mov [rel file_value+NEBO_FILE_CAPABILITY],rdx
 lea rdi,[rel file_value]
 lea rsi,[rel packed]
 mov edx,88
 call nebo_checkpoint_save
 test eax,eax
 jnz .fail29
 mov eax,SYS_LSEEK
 mov rdi,[rel file_value+NEBO_FILE_FD]
 xor esi,esi
 xor edx,edx
 syscall
 test eax,eax
 js .fail30
 lea rdi,[rel file_value]
 lea rsi,[rel loaded]
 mov edx,88
 lea rcx,[rel summary]
 call nebo_checkpoint_load
 test eax,eax
 jnz .fail31
 lea rsi,[rel packed]
 lea rdi,[rel loaded]
 mov ecx,11
 repe cmpsq
 jne .fail32
 mov eax,SYS_CLOSE
 mov rdi,[rel file_value+NEBO_FILE_FD]
 syscall
 xor edi,edi
 jmp .exit
%assign i 1
%rep 32
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
