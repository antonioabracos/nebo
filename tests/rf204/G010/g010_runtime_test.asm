; Independent native oracle for every G010 source-to-effect runtime mode.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern nebo_g010_source_probe
extern neboc_column_from
extern neboc_column_cast
global _start
section .text
_start:
 mov edi,1
 mov esi,91
 call nebo_g010_source_probe
 cmp eax,91
 jne fail1
 mov edi,2
 mov esi,92
 call nebo_g010_source_probe
 cmp eax,92
 jne fail2
 mov edi,3
 mov esi,93
 call nebo_g010_source_probe
 cmp eax,93
 jne fail3
 mov edi,4
 mov esi,94
 call nebo_g010_source_probe
 cmp eax,94
 jne fail4
 mov edi,5
 mov esi,95
 call nebo_g010_source_probe
 cmp eax,95
 jne fail5
 mov edi,6
 mov esi,96
 call nebo_g010_source_probe
 cmp eax,96
 jne fail6
 mov edi,2
 mov esi,255
 call nebo_g010_source_probe
 cmp eax,255
 jne fail7
 mov edi,7
 mov esi,97
 call nebo_g010_source_probe
 cmp eax,111
 jne fail8
 ; Checked I64-to-U64 conversion rejects a negative value before output commit.
 mov qword [rel cast_values],-1
 mov qword [rel cast_values+8],2
 lea rdi,[rel cast_source]
 lea rsi,[rel cast_values]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_from
 test eax,eax
 jnz fail9
 mov rax,0x1122334455667788
 mov [rel cast_target],rax
 mov [rel cast_output],rax
 lea rdi,[rel cast_source]
 mov esi,NEBO_DTYPE_U64
 lea rdx,[rel cast_target]
 lea rcx,[rel cast_output]
 mov r8d,2
 call neboc_column_cast
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail9
 mov rax,0x1122334455667788
 cmp [rel cast_target],rax
 jne fail9
 cmp [rel cast_output],rax
 jne fail9
 xor edi,edi
 jmp exit
fail1: mov edi,1
 jmp exit
fail2: mov edi,2
 jmp exit
fail3: mov edi,3
 jmp exit
fail4: mov edi,4
 jmp exit
fail5: mov edi,5
 jmp exit
fail6: mov edi,6
 jmp exit
fail7: mov edi,7
 jmp exit
fail8: mov edi,8
 jmp exit
fail9: mov edi,9
exit:
 mov eax,60
 syscall
section .bss
align 8
cast_values: resq 2
cast_source: resb NEBO_COLUMN_SIZE
cast_target: resb NEBO_COLUMN_SIZE
cast_output: resq 2
section .note.GNU-stack noalloc noexec nowrite progbits
