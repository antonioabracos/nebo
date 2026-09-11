bits 64
default rel
%include "runtime/error/system_error.inc"
%include "compiler/semantic/system/system_contract.inc"
section .bss
error resb NEBO_ERROR_SIZE
section .text
global _start
_start:
 lea rdi,[error]
 mov esi,NEBO_ERROR_CATEGORY_NETWORK
 mov edx,NEBO_SYSTEM_ERROR_TIMEOUT
 mov ecx,77
 mov r8,0x1234
 call nebo_system_error_map
 test eax,eax
 jnz .fail1
 cmp dword [error+NEBO_ERROR_CODE],NEBO_SYSTEM_ERROR_TIMEOUT
 jne .fail2
 cmp word [error+NEBO_ERROR_CATEGORY],NEBO_ERROR_CATEGORY_NETWORK
 jne .fail3
 test word [error+NEBO_ERROR_FLAGS],NEBO_ERROR_FLAG_RETRYABLE
 jz .fail4
 cmp qword [error+NEBO_ERROR_SOURCE_ID],77
 jne .fail5
 cmp qword [error+NEBO_ERROR_CONTEXT_HASH],0x1234
 jne .fail6
 cmp qword [error+NEBO_ERROR_MESSAGE],0
 jne .fail7
 cmp qword [error+NEBO_ERROR_MESSAGE_LENGTH],0
 jne .fail8
 lea rdi,[error]
 mov esi,99
 call nebo_system_error_with_cause
 test eax,eax
 jnz .fail9
 cmp qword [error+NEBO_ERROR_CAUSE_ID],99
 jne .fail10
 lea rdi,[error]
 mov esi,100
 call nebo_system_error_with_cause
 cmp eax,NEBO_SYSTEM_ERROR_ALREADY_COMPLETED
 jne .fail11
 lea rdi,[error]
 xor esi,esi
 mov edx,1
 xor ecx,ecx
 xor r8d,r8d
 call nebo_system_error_map
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail12
 xor rdi,rdi
 mov esi,1
 mov edx,1
 xor ecx,ecx
 xor r8d,r8d
 call nebo_system_error_map
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail13
 xor edi,edi
 jmp .exit
%assign i 1
%rep 13
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
