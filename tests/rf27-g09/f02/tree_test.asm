bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"
extern neboc_tree_init
extern neboc_tree_add
extern neboc_tree_get
extern neboc_tree_replace
extern neboc_tree_parent
extern neboc_tree_reparent
extern neboc_tree_child_count
extern neboc_tree_remove_subtree
global _start
section .text
_start:
 lea rdi,[rel tree]
 lea rsi,[rel values]
 lea rdx,[rel generations]
 lea rcx,[rel alive]
 lea r8,[rel parents]
 mov r9d,8
 call neboc_tree_init
 test eax,eax
 jnz fail1
 cmp qword [rel tree+NEBO_TREE_ROOT],NEBO_INVALID_HANDLE
 jne fail1

 lea rdi,[rel tree]
 mov rsi,NEBO_INVALID_HANDLE
 mov edx,10
 lea rcx,[rel root_handle]
 call neboc_tree_add
 test eax,eax
 jnz fail2
 mov rax,[rel root_handle]
 cmp [rel tree+NEBO_TREE_ROOT],rax
 jne fail2

 lea rdi,[rel tree]
 mov rsi,[rel root_handle]
 mov edx,20
 lea rcx,[rel child1_handle]
 call neboc_tree_add
 test eax,eax
 jnz fail3
 lea rdi,[rel tree]
 mov rsi,[rel root_handle]
 mov edx,30
 lea rcx,[rel child2_handle]
 call neboc_tree_add
 test eax,eax
 jnz fail3

 lea rdi,[rel tree]
 mov rsi,[rel root_handle]
 lea rdx,[rel out]
 call neboc_tree_child_count
 test eax,eax
 jnz fail4
 cmp qword [rel out],2
 jne fail4

 lea rdi,[rel tree]
 mov rsi,[rel child1_handle]
 lea rdx,[rel out]
 call neboc_tree_get
 test eax,eax
 jnz fail5
 cmp qword [rel out],20
 jne fail5

 lea rdi,[rel tree]
 mov rsi,[rel child1_handle]
 mov edx,21
 lea rcx,[rel out]
 call neboc_tree_replace
 test eax,eax
 jnz fail6
 cmp qword [rel out],20
 jne fail6

 lea rdi,[rel tree]
 mov rsi,[rel child1_handle]
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_tree_parent
 test eax,eax
 jnz fail7
 cmp qword [rel found],1
 jne fail7
 mov rax,[rel root_handle]
 cmp [rel out],rax
 jne fail7

 lea rdi,[rel tree]
 mov rsi,[rel child2_handle]
 mov rdx,[rel child1_handle]
 call neboc_tree_reparent
 test eax,eax
 jnz fail8
 lea rdi,[rel tree]
 mov rsi,[rel root_handle]
 lea rdx,[rel out]
 call neboc_tree_child_count
 test eax,eax
 jnz fail8
 cmp qword [rel out],1
 jne fail8

 lea rdi,[rel tree]
 mov rsi,[rel child1_handle]
 mov rdx,[rel child2_handle]
 call neboc_tree_reparent
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail9

 mov qword [rel tree+NEBO_TREE_BORROW],1
 lea rdi,[rel tree]
 mov rsi,[rel child1_handle]
 mov edx,99
 lea rcx,[rel out]
 call neboc_tree_replace
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail10
 mov qword [rel tree+NEBO_TREE_BORROW],0

 lea rdi,[rel tree]
 mov rsi,[rel child1_handle]
 call neboc_tree_remove_subtree
 test eax,eax
 jnz fail11
 cmp qword [rel tree+NEBO_TREE_LENGTH],1
 jne fail11
 lea rdi,[rel tree]
 mov rsi,[rel child2_handle]
 lea rdx,[rel out]
 call neboc_tree_get
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail11

 lea rdi,[rel tree]
 mov rsi,[rel root_handle]
 mov edx,40
 lea rcx,[rel replacement_handle]
 call neboc_tree_add
 test eax,eax
 jnz fail12
 mov rax,[rel replacement_handle]
 cmp rax,[rel child1_handle]
 je fail12
 mov edx,eax
 mov rax,[rel child1_handle]
 cmp edx,eax
 jne fail12

 lea rdi,[rel tree]
 mov rsi,[rel root_handle]
 call neboc_tree_remove_subtree
 test eax,eax
 jnz fail13
 cmp qword [rel tree+NEBO_TREE_LENGTH],0
 jne fail13
 cmp qword [rel tree+NEBO_TREE_ROOT],NEBO_INVALID_HANDLE
 jne fail13

 lea rdi,[rel tree]
 lea rsi,[rel values]
 lea rdx,[rel generations]
 lea rcx,[rel alive]
 lea r8,[rel parents]
 mov r9d,33
 call neboc_tree_init
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail14
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
 jmp exit
fail11: mov edi,11
 jmp exit
fail12: mov edi,12
 jmp exit
fail13: mov edi,13
 jmp exit
fail14: mov edi,14
exit:
 mov eax,60
 syscall
section .bss
align 8
tree: resb NEBO_TREE_SIZE
values: resq 8
generations: resd 8
alive: resb 8
align 8
parents: resq 8
root_handle: resq 1
child1_handle: resq 1
child2_handle: resq 1
replacement_handle: resq 1
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
