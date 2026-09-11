bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_init
extern neboc_dict_insert
extern neboc_dict_get
extern neboc_dict_contains_checked
extern neboc_dict_get_or
extern neboc_dict_entry_snapshot
global _start
section .text
_start:
 lea rdi,[rel dict]
 lea rsi,[rel storage]
 mov edx,8
 mov ecx,42
 xor r8d,r8d
 call neboc_dict_init
 lea rdi,[rel dict]
 mov esi,7
 mov edx,70
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail1

 mov qword [rel value],999
 mov qword [rel found],999
 lea rdi,[rel dict]
 mov esi,8
 lea rdx,[rel value]
 lea rcx,[rel found]
 call neboc_dict_get
 test eax,eax
 jnz fail2
 cmp qword [rel found],0
 jne fail2
 cmp qword [rel value],999
 jne fail2
 lea rdi,[rel dict]
 mov esi,7
 lea rdx,[rel value]
 lea rcx,[rel found]
 call neboc_dict_get
 test eax,eax
 jnz fail2
 cmp qword [rel found],1
 jne fail2
 cmp qword [rel value],70
 jne fail2

 lea rdi,[rel dict]
 mov esi,7
 lea rdx,[rel flag]
 call neboc_dict_contains_checked
 test eax,eax
 jnz fail3
 cmp qword [rel flag],1
 jne fail3
 lea rdi,[rel dict]
 mov esi,8
 lea rdx,[rel flag]
 call neboc_dict_contains_checked
 test eax,eax
 jnz fail3
 cmp qword [rel flag],0
 jne fail3

 lea rdi,[rel dict]
 mov esi,7
 mov edx,123
 lea rcx,[rel value]
 lea r8,[rel flag]
 call neboc_dict_get_or
 test eax,eax
 jnz fail4
 cmp qword [rel value],70
 jne fail4
 cmp qword [rel flag],0
 jne fail4
 lea rdi,[rel dict]
 mov esi,8
 mov edx,123
 lea rcx,[rel value]
 lea r8,[rel flag]
 call neboc_dict_get_or
 test eax,eax
 jnz fail4
 cmp qword [rel value],123
 jne fail4
 cmp qword [rel flag],1
 jne fail4

 lea rdi,[rel dict]
 mov esi,7
 lea rdx,[rel key]
 lea rcx,[rel value]
 lea r8,[rel found]
 call neboc_dict_entry_snapshot
 test eax,eax
 jnz fail5
 cmp qword [rel found],1
 jne fail5
 cmp qword [rel key],7
 jne fail5
 cmp qword [rel value],70
 jne fail5
 mov qword [rel key],999
 mov qword [rel value],999
 lea rdi,[rel dict]
 mov esi,8
 lea rdx,[rel key]
 lea rcx,[rel value]
 lea r8,[rel found]
 call neboc_dict_entry_snapshot
 test eax,eax
 jnz fail5
 cmp qword [rel found],0
 jne fail5
 cmp qword [rel key],999
 jne fail5
 cmp qword [rel value],999
 jne fail5

 ; Actual errors preserve outputs.
 mov dword [rel dict+NEBO_DICT_MAGIC_OFFSET],0
 mov qword [rel value],999
 mov qword [rel found],999
 lea rdi,[rel dict]
 mov esi,7
 lea rdx,[rel value]
 lea rcx,[rel found]
 call neboc_dict_get
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 cmp qword [rel value],999
 jne fail6
 cmp qword [rel found],999
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
section .bss
align 8
dict: resb NEBO_DICT_SIZE
storage: resb NEBO_DICT_U64_SLOT_SIZE*8
old: resq 1
found: resq 1
value: resq 1
key: resq 1
flag: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
