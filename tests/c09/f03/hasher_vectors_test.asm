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
 lea rdi,[rel hasher]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 test eax,eax
 jnz fail1
 mov rax,NEBO_HASHER_VERSION_TAG
 cmp [rel hasher+NEBO_HASHER_VERSION_OFFSET],rax
 jne fail1
 lea rdi,[rel hasher]
 call neboc_hasher_finish
 mov r12,0xcbf29ce484222325
 cmp rax,r12
 jne fail1

 lea rdi,[rel hasher]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 lea rdi,[rel hasher]
 lea rsi,[rel a]
 mov edx,1
 call neboc_hasher_write_bytes
 lea rdi,[rel hasher]
 call neboc_hasher_finish
 mov r12,0xaf63dc4c8601ec8c
 cmp rax,r12
 jne fail2

 lea rdi,[rel hasher]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 lea rdi,[rel hasher]
 lea rsi,[rel foobar]
 mov edx,6
 call neboc_hasher_write_bytes
 lea rdi,[rel hasher]
 call neboc_hasher_finish
 mov r12,0x85944171f73967e8
 cmp rax,r12
 jne fail3
 ; Split streaming is byte-for-byte equivalent.
 lea rdi,[rel split]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 lea rdi,[rel split]
 lea rsi,[rel foobar]
 mov edx,3
 call neboc_hasher_write_bytes
 lea rdi,[rel split]
 lea rsi,[rel foobar+3]
 mov edx,3
 call neboc_hasher_write_bytes
 lea rdi,[rel split]
 call neboc_hasher_finish
 cmp rax,r12
 jne fail3

 lea rdi,[rel hasher]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 lea rdi,[rel hasher]
 lea rsi,[rel hello]
 mov edx,5
 call neboc_hasher_write_bytes
 lea rdi,[rel hasher]
 call neboc_hasher_finish
 mov r12,0xa430d84680aabd0b
 cmp rax,r12
 jne fail4
 mov rdi,0x0102030405060708
 xor esi,esi
 call neboc_hash_u64
 mov r12,0x0c6d4496e17859d5
 cmp rax,r12
 jne fail4

 ; Effective process seed 42 XOR 99 equals deterministic seed 73.
 lea rdi,[rel hasher]
 mov esi,73
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 lea rdi,[rel hasher]
 lea rsi,[rel abc]
 mov edx,3
 call neboc_hasher_write_bytes
 lea rdi,[rel hasher]
 call neboc_hasher_finish
 mov r12,rax
 lea rdi,[rel split]
 mov esi,42
 mov edx,NEBO_HASH_MODE_PROCESS_SEEDED
 mov ecx,99
 call neboc_hasher_init
 lea rdi,[rel split]
 lea rsi,[rel abc]
 mov edx,3
 call neboc_hasher_write_bytes
 lea rdi,[rel split]
 call neboc_hasher_finish
 cmp rax,r12
 jne fail5
 ; An irrelevant process seed in deterministic mode is rejected.
 lea rdi,[rel split]
 xor esi,esi
 xor edx,edx
 mov ecx,1
 call neboc_hasher_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail5

 ; Limit and invalid version preserve the entire initialized state.
 lea rdi,[rel hasher]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 mov r12,[rel hasher]
 mov r13,[rel hasher+24]
 lea rdi,[rel hasher]
 lea rsi,[rel abc]
 mov edx,4097
 call neboc_hasher_write_bytes
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail6
 cmp [rel hasher],r12
 jne fail6
 cmp [rel hasher+24],r13
 jne fail6
 mov qword [rel hasher+NEBO_HASHER_VERSION_OFFSET],0
 lea rdi,[rel hasher]
 lea rsi,[rel abc]
 mov edx,3
 call neboc_hasher_write_bytes
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail6
 cmp [rel hasher],r12
 jne fail6
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
exit: mov eax,60
 syscall
section .data
a: db 'a'
foobar: db 'foobar'
hello: db 'hello'
abc: db 'abc'
section .bss
align 8
hasher: resb NEBO_HASHER_SIZE
split: resb NEBO_HASHER_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
