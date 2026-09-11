bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_hasher_init
extern neboc_hasher_write_bytes
extern neboc_hasher_finish
extern neboc_hash_u64
global _start
section .text
_start:
 lea rdi,[rel h1]
 mov esi,42
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 test eax,eax
 jnz fail1
 cmp qword [rel h1+24],0
 jne fail1
 lea rdi,[rel h1]
 lea rsi,[rel abc]
 mov edx,3
 call neboc_hasher_write_bytes
 test eax,eax
 jnz fail2
 lea rdi,[rel h1]
 call neboc_hasher_finish
 test rax,rax
 jz fail2
 mov r12,rax
 lea rdi,[rel h2]
 mov esi,42
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 lea rdi,[rel h2]
 lea rsi,[rel abc]
 mov edx,3
 call neboc_hasher_write_bytes
 lea rdi,[rel h2]
 call neboc_hasher_finish
 cmp rax,r12
 jne fail3
 lea rdi,[rel h2]
 mov esi,43
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 lea rdi,[rel h2]
 lea rsi,[rel abc]
 mov edx,3
 call neboc_hasher_write_bytes
 lea rdi,[rel h2]
 call neboc_hasher_finish
 cmp rax,r12
 je fail4
 lea rdi,[rel h2]
 mov esi,42
 mov edx,1
 mov ecx,99
 call neboc_hasher_init
 test eax,eax
 jnz fail5
 cmp qword [rel h2+16],1
 jne fail5
 cmp qword [rel h2+8],73
 jne fail5
 lea rdi,[rel h2]
 xor esi,esi
 mov edx,2
 xor ecx,ecx
 call neboc_hasher_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail6
 lea rdi,[rel h2]
 xor esi,esi
 mov edx,1
 xor ecx,ecx
 call neboc_hasher_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail7
 lea rdi,[rel h1]
 xor esi,esi
 xor edx,edx
 call neboc_hasher_write_bytes
 test eax,eax
 jnz fail8
 mov r13,[rel h1]
 lea rdi,[rel h1]
 lea rsi,[rel abc]
 mov edx,4097
 call neboc_hasher_write_bytes
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail9
 cmp [rel h1],r13
 jne fail9
 mov rdi,0x0102030405060708
 mov esi,42
 call neboc_hash_u64
 mov r14,rax
 lea rdi,[rel h2]
 mov esi,42
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 lea rdi,[rel h2]
 lea rsi,[rel u64bytes]
 mov edx,8
 call neboc_hasher_write_bytes
 lea rdi,[rel h2]
 call neboc_hasher_finish
 cmp rax,r14
 jne fail10
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
 jmp exit
fail10: mov edi,10
exit: mov eax,60
 syscall
section .data
abc: db 'abc'
u64bytes: db 8,7,6,5,4,3,2,1
section .bss
align 8
h1: resb NEBO_HASHER_SIZE
h2: resb NEBO_HASHER_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
