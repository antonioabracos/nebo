bits 64
default rel
%include "runtime/ml/model_format.inc"
%include "compiler/semantic/system/filesystem_contract.inc"

%define SYS_READ 0
%define SYS_CLOSE 3
%define SYS_PIPE 22

section .rodata
valid_model:
 db 0x4e,0x4d,0x46,0x31,0x01,0x00,0x40,0x00,0x80,0x00,0x00,0x00,0x01,0x00,0x01,0x00
 db 0x02,0x00,0x00,0x00,0x40,0x00,0x00,0x00,0x30,0x00,0x00,0x00,0x70,0x00,0x00,0x00
 db 0xff,0x44,0xf7,0xce,0xb1,0xd4,0x02,0x62,0x3d,0xdb,0x74,0xbd,0xb5,0x5a,0x5e,0x75
 db 0x1c,0xfa,0x1d,0x27,0xe8,0x5a,0x26,0x44,0x03,0x8d,0xfb,0x81,0xf7,0xfa,0xd2,0xb2
 db 0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x02,0x00,0x00,0x00
 db 0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
 db 0x00,0x00,0x00,0x00,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
 db 0x00,0x00,0x00,0x00,0x00,0x00,0xf8,0x3f,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc0
valid_model_end:

section .bss
summary resb NEBO_NMF1_SUMMARY_SIZE
state resb NEBO_NMF1_STATE_SIZE
loaded resb 32
mutant resb 129
pipe_fds resd 2
saved resb 128
capability resb NEBO_FILE_CAPABILITY_SIZE
file_value resb NEBO_FILE_SIZE

section .text
global _start
_start:
 lea rdi,[rel valid_model]
 mov esi,valid_model_end-valid_model
 lea rdx,[rel summary]
 call nebo_nmf1_inspect
 test eax,eax
 jnz .fail1
 cmp qword [rel summary+NEBO_NMF1_SUMMARY_FILE_BYTES],128
 jne .fail2
 cmp qword [rel summary+NEBO_NMF1_SUMMARY_NODES],1
 jne .fail3
 cmp qword [rel summary+NEBO_NMF1_SUMMARY_TENSORS],1
 jne .fail4
 cmp qword [rel summary+NEBO_NMF1_SUMMARY_ELEMENTS],2
 jne .fail5
 lea rax,[rel valid_model+112]
 cmp [rel summary+NEBO_NMF1_SUMMARY_DATA],rax
 jne .fail6
 cmp qword [rel summary+NEBO_NMF1_SUMMARY_DATA_BYTES],16
 jne .fail7

 lea rdi,[rel valid_model]
 mov esi,128
 mov edx,0x101
 lea rcx,[rel state]
 call nebo_nmf1_state_lookup
 test eax,eax
 jnz .fail8
 cmp qword [rel state+NEBO_NMF1_STATE_DTYPE],NEBO_NMF1_DTYPE_F64
 jne .fail9
 cmp qword [rel state+NEBO_NMF1_STATE_RANK],1
 jne .fail10
 cmp qword [rel state+NEBO_NMF1_STATE_ELEMENTS],2
 jne .fail11
 mov rax,0x3ff8000000000000
 mov rdx,[rel state+NEBO_NMF1_STATE_DATA]
 cmp [rdx],rax
 jne .fail12

 mov qword [rel state],0x11223344
 lea rdi,[rel valid_model]
 mov esi,128
 mov edx,0x999
 lea rcx,[rel state]
 call nebo_nmf1_state_lookup
 cmp eax,NEBO_NMF1_E_NOT_FOUND
 jne .fail13
 cmp qword [rel state],0x11223344
 jne .fail14

 lea rdi,[rel valid_model]
 mov esi,128
 lea rdx,[rel loaded]
 mov ecx,32
 lea r8,[rel summary]
 call nebo_nmf1_load
 test eax,eax
 jnz .fail15
 mov rax,0x3ff8000000000000
 cmp [rel loaded],rax
 jne .fail16
 mov rax,0xc000000000000000
 cmp [rel loaded+8],rax
 jne .fail17
 mov byte [rel loaded],0x5a
 lea rdi,[rel valid_model]
 mov esi,128
 lea rdx,[rel loaded]
 mov ecx,15
 lea r8,[rel summary]
 call nebo_nmf1_load
 cmp eax,NEBO_NMF1_E_CAPACITY
 jne .fail18
 cmp byte [rel loaded],0x5a
 jne .fail19

 call .copy_valid
 xor byte [rel mutant+127],1
 mov qword [rel summary],0x55667788
 lea rdi,[rel mutant]
 mov esi,128
 lea rdx,[rel summary]
 call nebo_nmf1_inspect
 cmp eax,NEBO_NMF1_E_CHECKSUM
 jne .fail20
 cmp qword [rel summary],0x55667788
 jne .fail21
 call .copy_valid
 mov word [rel mutant+4],2
 lea rdi,[rel mutant]
 mov esi,128
 lea rdx,[rel summary]
 call nebo_nmf1_inspect
 cmp eax,NEBO_NMF1_E_VERSION
 jne .fail22
 lea rdi,[rel valid_model]
 mov esi,127
 lea rdx,[rel summary]
 call nebo_nmf1_inspect
 cmp eax,NEBO_NMF1_E_SIZE
 jne .fail23
 lea rdi,[rel valid_model]
 mov esi,129
 lea rdx,[rel summary]
 call nebo_nmf1_inspect
 cmp eax,NEBO_NMF1_E_SIZE
 jne .fail24
 call .copy_valid
 mov dword [rel mutant+20],65
 lea rdi,[rel mutant]
 mov esi,128
 lea rdx,[rel summary]
 call nebo_nmf1_inspect
 cmp eax,NEBO_NMF1_E_MANIFEST
 jne .fail25
 call .copy_valid
 mov dword [rel mutant+76],0
 lea rdi,[rel mutant]
 mov esi,128
 lea rdx,[rel summary]
 call nebo_nmf1_inspect
 cmp eax,NEBO_NMF1_E_MANIFEST
 jne .fail26
 call .copy_valid
 mov dword [rel mutant],0
 lea rdi,[rel mutant]
 mov esi,128
 lea rdx,[rel summary]
 call nebo_nmf1_inspect
 cmp eax,NEBO_NMF1_E_MAGIC
 jne .fail27

 lea rdi,[rel pipe_fds]
 mov eax,SYS_PIPE
 syscall
 test eax,eax
 jnz .fail28
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 mov [rel capability+NEBO_FILE_CAPABILITY_MAGIC],rax
 mov qword [rel capability+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_WRITE
 mov qword [rel capability+NEBO_FILE_CAPABILITY_MAX_IO_BYTES],NEBO_NMF1_MAX_FILE_BYTES
 mov eax,[rel pipe_fds+4]
 mov [rel file_value+NEBO_FILE_FD],rax
 mov qword [rel file_value+NEBO_FILE_STATE],NEBO_FILE_STATE_OPEN
 lea rax,[rel capability]
 mov [rel file_value+NEBO_FILE_CAPABILITY],rax
 mov qword [rel file_value+NEBO_FILE_BYTES_READ],0
 mov qword [rel file_value+NEBO_FILE_BYTES_WRITTEN],0
 lea rdi,[rel file_value]
 lea rsi,[rel valid_model]
 mov edx,128
 call nebo_nmf1_save
 test eax,eax
 jnz .fail29
 mov eax,SYS_CLOSE
 mov edi,[rel pipe_fds+4]
 syscall
 mov eax,SYS_READ
 mov edi,[rel pipe_fds]
 lea rsi,[rel saved]
 mov edx,128
 syscall
 cmp eax,128
 jne .fail30
 lea rsi,[rel valid_model]
 lea rdi,[rel saved]
 mov ecx,16
 repe cmpsq
 jne .fail31
 mov eax,SYS_CLOSE
 mov edi,[rel pipe_fds]
 syscall
 xor edi,edi
 jmp .exit

.copy_valid:
 lea rsi,[rel valid_model]
 lea rdi,[rel mutant]
 mov ecx,16
 rep movsq
 ret

%assign i 1
%rep 31
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
