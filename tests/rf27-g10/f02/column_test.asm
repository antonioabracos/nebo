bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern neboc_column_init
extern neboc_column_get
extern neboc_column_is_missing
extern neboc_column_set
extern neboc_column_set_missing
extern neboc_colecoes_primitivas_column_count_missing
extern neboc_column_sum_i64
extern neboc_column_min_i64
extern neboc_column_max_i64
extern neboc_column_iterator_begin
extern neboc_column_iterator_next
extern neboc_column_iterator_release
global _start
section .text
_start:
 mov qword [rel values],1
 mov qword [rel values+8],2
 mov qword [rel values+16],3
 mov qword [rel values+24],4
 lea rdi,[rel column]
 lea rsi,[rel values]
 mov edx,4
 mov ecx,8
 mov r8d,NEBO_DTYPE_I64
 mov r9d,2
 call neboc_column_init
 test eax,eax
 jnz fail1
 cmp qword [rel column+NEBO_COLUMN_CAPACITY],8
 jne fail1
 cmp qword [rel column+NEBO_COLUMN_LENGTH],4
 jne fail1

 lea rdi,[rel column]
 xor esi,esi
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_column_get
 test eax,eax
 jnz fail2
 cmp qword [rel found],1
 jne fail2
 cmp qword [rel out],1
 jne fail2
 lea rdi,[rel column]
 mov esi,1
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_column_get
 test eax,eax
 jnz fail2
 cmp qword [rel found],0
 jne fail2
 lea rdi,[rel column]
 mov esi,1
 lea rdx,[rel missing]
 call neboc_column_is_missing
 test eax,eax
 jnz fail2
 cmp qword [rel missing],1
 jne fail2

 lea rdi,[rel column]
 mov esi,1
 mov edx,20
 lea rcx,[rel out]
 lea r8,[rel missing]
 call neboc_column_set
 test eax,eax
 jnz fail3
 cmp qword [rel missing],1
 jne fail3
 cmp qword [rel out],0
 jne fail3

 lea rdi,[rel column]
 mov esi,2
 mov edx,1
 lea rcx,[rel missing]
 call neboc_column_set_missing
 test eax,eax
 jnz fail4
 cmp qword [rel missing],0
 jne fail4
 lea rdi,[rel column]
 lea rsi,[rel out]
 call neboc_colecoes_primitivas_column_count_missing
 test eax,eax
 jnz fail4
 cmp qword [rel out],1
 jne fail4

 lea rdi,[rel column]
 lea rsi,[rel out]
 call neboc_column_sum_i64
 test eax,eax
 jnz fail5
 cmp qword [rel out],25
 jne fail5
 lea rdi,[rel column]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_column_min_i64
 test eax,eax
 jnz fail5
 cmp qword [rel found],1
 jne fail5
 cmp qword [rel out],1
 jne fail5
 lea rdi,[rel column]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_column_max_i64
 test eax,eax
 jnz fail5
 cmp qword [rel out],20
 jne fail5

 lea rdi,[rel iterator]
 lea rsi,[rel column]
 call neboc_column_iterator_begin
 test eax,eax
 jnz fail6
 cmp qword [rel column+NEBO_COLUMN_BORROW],1
 jne fail6
 lea rdi,[rel column]
 xor esi,esi
 mov edx,9
 lea rcx,[rel out]
 lea r8,[rel missing]
 call neboc_column_set
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6

 lea rdi,[rel iterator]
 lea rsi,[rel out]
 lea rdx,[rel found]
 lea rcx,[rel missing]
 call neboc_column_iterator_next
 test eax,eax
 jnz fail7
 cmp qword [rel found],1
 jne fail7
 cmp qword [rel missing],0
 jne fail7
 cmp qword [rel out],1
 jne fail7
 lea rdi,[rel iterator]
 lea rsi,[rel out]
 lea rdx,[rel found]
 lea rcx,[rel missing]
 call neboc_column_iterator_next
 test eax,eax
 jnz fail7
 cmp qword [rel out],20
 jne fail7
 lea rdi,[rel iterator]
 lea rsi,[rel out]
 lea rdx,[rel found]
 lea rcx,[rel missing]
 call neboc_column_iterator_next
 test eax,eax
 jnz fail7
 cmp qword [rel found],1
 jne fail7
 cmp qword [rel missing],1
 jne fail7
 lea rdi,[rel iterator]
 lea rsi,[rel out]
 lea rdx,[rel found]
 lea rcx,[rel missing]
 call neboc_column_iterator_next
 test eax,eax
 jnz fail7
 cmp qword [rel out],4
 jne fail7
 lea rdi,[rel iterator]
 lea rsi,[rel out]
 lea rdx,[rel found]
 lea rcx,[rel missing]
 call neboc_column_iterator_next
 test eax,eax
 jnz fail7
 cmp qword [rel found],0
 jne fail7

 inc qword [rel column+NEBO_COLUMN_GENERATION]
 lea rdi,[rel iterator]
 lea rsi,[rel out]
 lea rdx,[rel found]
 lea rcx,[rel missing]
 call neboc_column_iterator_next
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail8
 dec qword [rel column+NEBO_COLUMN_GENERATION]
 lea rdi,[rel iterator]
 call neboc_column_iterator_release
 test eax,eax
 jnz fail8
 cmp qword [rel column+NEBO_COLUMN_BORROW],0
 jne fail8
 lea rdi,[rel iterator]
 call neboc_column_iterator_release
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail8

 mov rax,0x1122334455667788
 mov [rel bad_column],rax
 lea rdi,[rel bad_column]
 lea rsi,[rel values]
 mov edx,4
 mov ecx,33
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_init
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail9
 mov rax,0x1122334455667788
 cmp [rel bad_column],rax
 jne fail9

 lea rdi,[rel bad_column]
 lea rsi,[rel values]
 mov edx,4
 mov ecx,8
 mov r8d,9
 xor r9d,r9d
 call neboc_column_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail10
 lea rdi,[rel bad_column]
 lea rsi,[rel values]
 mov edx,4
 mov ecx,8
 mov r8d,NEBO_DTYPE_I64
 mov r9d,16
 call neboc_column_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail10

 mov rax,0x7fffffffffffffff
 mov [rel values],rax
 mov qword [rel values+8],1
 lea rdi,[rel column]
 lea rsi,[rel values]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_init
 test eax,eax
 jnz fail11
 lea rdi,[rel column]
 lea rsi,[rel out]
 call neboc_column_sum_i64
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail11

 lea rdi,[rel column]
 mov esi,2
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_column_get
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail12
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
exit:
 mov eax,60
 syscall
section .bss
align 8
column: resb NEBO_COLUMN_SIZE
bad_column: resb NEBO_COLUMN_SIZE
iterator: resb NEBO_COLUMN_ITERATOR_SIZE
values: resq 8
out: resq 1
found: resq 1
missing: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
