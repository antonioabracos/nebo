bits 64
default rel
%include "runtime/system/random.inc"

section .bss
random resb NEBO_RANDOM_SIZE
random2 resb NEBO_RANDOM_SIZE
entropy resb NEBO_ENTROPY_CAPABILITY_SIZE
secure_buffer resb 64

section .text
global _start
_start:
 lea rdi,[random]
 xor esi,esi
 call nebo_random_seed
 test eax,eax
 jnz .fail1
 lea rdi,[random]
 call nebo_random_next_u64
 test eax,eax
 jnz .fail2
 mov r8,0xe220a8397b1dcdaf
 cmp rdx,r8
 jne .fail3
 lea rdi,[random]
 call nebo_random_next_u64
 mov r8,0x6e789e6aa1b965f4
 cmp rdx,r8
 jne .fail4
 lea rdi,[random]
 call nebo_random_next_u64
 mov r8,0x06c45d188009454f
 cmp rdx,r8
 jne .fail5
 cmp qword [random+NEBO_RANDOM_CALLS],3
 jne .fail6
 lea rdi,[random2]
 xor esi,esi
 call nebo_random_seed
 test eax,eax
 jnz .fail7
 lea rdi,[random2]
 call nebo_random_next_u64
 mov r8,0xe220a8397b1dcdaf
 cmp rdx,r8
 jne .fail8
 lea rdi,[random2]
 mov esi,5
 mov edx,12
 call nebo_random_next_range
 test eax,eax
 jnz .fail9
 cmp rdx,5
 jb .fail10
 cmp rdx,12
 jae .fail11
 lea rdi,[random2]
 mov esi,12
 mov edx,12
 call nebo_random_next_range
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail12
 lea rdi,[random2]
 mov rsi,-1
 mov edx,12
 call nebo_random_next_range
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail13
 mov qword [random2+NEBO_RANDOM_MAGIC],0
 lea rdi,[random2]
 call nebo_random_next_u64
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail14
 lea rdi,[entropy]
 mov esi,40
 mov edx,2
 call nebo_entropy_capability_init
 test eax,eax
 jnz .fail15
 lea rdi,[secure_buffer]
 mov esi,32
 lea rdx,[entropy]
 call nebo_random_fill_secure
 test eax,eax
 jnz .fail16
 cmp rdx,32
 jne .fail17
 cmp qword [entropy+NEBO_ENTROPY_CAPABILITY_BYTES_USED],32
 jne .fail18
 cmp qword [entropy+NEBO_ENTROPY_CAPABILITY_GENERATION],1
 jne .fail19
 xor r8,r8
 xor ecx,ecx
.scan:
 or r8,[secure_buffer+rcx]
 add rcx,8
 cmp rcx,32
 jb .scan
 test r8,r8
 jz .fail20
 lea rdi,[secure_buffer+32]
 mov esi,9
 lea rdx,[entropy]
 call nebo_random_fill_secure
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail21
 cmp qword [entropy+NEBO_ENTROPY_CAPABILITY_BYTES_USED],32
 jne .fail22
 mov qword [entropy+NEBO_ENTROPY_CAPABILITY_MAGIC],0
 lea rdi,[secure_buffer+32]
 mov esi,1
 lea rdx,[entropy]
 call nebo_random_fill_secure
 cmp eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jne .fail23
 lea rdi,[entropy]
 xor esi,esi
 mov edx,1
 call nebo_entropy_capability_init
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail24
 lea rdi,[entropy]
 mov rsi,NEBO_ENTROPY_MAX_BYTES+1
 mov edx,1
 call nebo_entropy_capability_init
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail25
 xor edi,edi
 jmp .exit
%assign i 1
%rep 25
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
