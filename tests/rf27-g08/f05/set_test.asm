bits 64
default rel
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_set_init
extern neboc_set_insert
extern neboc_set_contains
extern neboc_set_remove
extern neboc_set_union
extern neboc_set_intersection
extern neboc_set_difference
extern neboc_dict_clear
global _start
section .text
_start:
 lea rdi,[rel a]
 lea rsi,[rel astore]
 mov edx,8
 mov ecx,1
 xor r8d,r8d
 call neboc_set_init
 test eax,eax
 jnz fail1
 lea rdi,[rel b]
 lea rsi,[rel bstore]
 mov edx,8
 mov ecx,2
 xor r8d,r8d
 call neboc_set_init
 lea rdi,[rel dest]
 lea rsi,[rel dstore]
 mov edx,8
 mov ecx,3
 xor r8d,r8d
 call neboc_set_init
 mov r12d,1
.fill_a:
 lea rdi,[rel a]
 mov rsi,r12
 lea rdx,[rel flag]
 call neboc_set_insert
 test eax,eax
 jnz fail2
 cmp qword [rel flag],1
 jne fail2
 inc r12
 cmp r12,4
 jb .fill_a
 lea rdi,[rel a]
 mov esi,2
 lea rdx,[rel flag]
 call neboc_set_insert
 cmp qword [rel flag],0
 jne fail3
 lea rdi,[rel a]
 mov esi,2
 call neboc_set_contains
 cmp eax,1
 jne fail4
 lea rdi,[rel a]
 mov esi,3
 lea rdx,[rel flag]
 call neboc_set_remove
 cmp qword [rel flag],1
 jne fail5
 lea rdi,[rel b]
 mov esi,2
 lea rdx,[rel flag]
 call neboc_set_insert
 lea rdi,[rel b]
 mov esi,4
 lea rdx,[rel flag]
 call neboc_set_insert
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel dest]
 call neboc_set_union
 test eax,eax
 jnz fail6
 cmp qword [rel dest+NEBO_DICT_LENGTH],3
 jne fail6
 lea rdi,[rel dest]
 mov esi,4
 call neboc_set_contains
 cmp eax,1
 jne fail6
 lea rdi,[rel dest]
 call neboc_dict_clear
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel dest]
 call neboc_set_intersection
 test eax,eax
 jnz fail7
 cmp qword [rel dest+NEBO_DICT_LENGTH],1
 jne fail7
 lea rdi,[rel dest]
 mov esi,2
 call neboc_set_contains
 cmp eax,1
 jne fail7
 lea rdi,[rel dest]
 call neboc_dict_clear
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel dest]
 call neboc_set_difference
 test eax,eax
 jnz fail8
 cmp qword [rel dest+NEBO_DICT_LENGTH],1
 jne fail8
 lea rdi,[rel dest]
 mov esi,1
 call neboc_set_contains
 cmp eax,1
 jne fail8
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
exit: mov eax,60
 syscall
section .bss
align 8
a: resb NEBO_DICT_SIZE
b: resb NEBO_DICT_SIZE
dest: resb NEBO_DICT_SIZE
astore: resb NEBO_DICT_U64_SLOT_SIZE*8
bstore: resb NEBO_DICT_U64_SLOT_SIZE*8
dstore: resb NEBO_DICT_U64_SLOT_SIZE*8
flag: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
