bits 64
default rel
%include "compiler/reflection/reflection.inc"
extern nebo_reflect_validate_type,nebo_reflect_field_at
section .bss
align 16
type resb NEBO_REFLECT_TYPE_DESC_SIZE
fields resb NEBO_REFLECT_FIELD_DESC_SIZE*2
output resb NEBO_REFLECT_FIELD_DESC_SIZE
section .text
global _start
_start:
 mov rax,NEBO_REFLECT_MAGIC
 mov [type+NEBO_REFLECT_TYPE_MAGIC],rax
 mov qword [type+NEBO_REFLECT_TYPE_VERSION],1
 mov qword [type+NEBO_REFLECT_TYPE_SIZE],16
 mov qword [type+NEBO_REFLECT_TYPE_ALIGN],8
 mov qword [type+NEBO_REFLECT_TYPE_CAPABILITIES],3
 lea rax,[fields]
 mov [type+NEBO_REFLECT_TYPE_FIELDS],rax
 mov qword [type+NEBO_REFLECT_TYPE_FIELD_COUNT],2
 mov qword [type+NEBO_REFLECT_TYPE_VISIBILITY],3
 mov qword [fields+NEBO_REFLECT_FIELD_NAME_ID],1
 mov qword [fields+NEBO_REFLECT_FIELD_TYPE_ID],10
 mov qword [fields+NEBO_REFLECT_FIELD_OFFSET],0
 mov qword [fields+NEBO_REFLECT_FIELD_SIZE],8
 mov qword [fields+NEBO_REFLECT_FIELD_VISIBILITY],1
 mov qword [fields+40+NEBO_REFLECT_FIELD_NAME_ID],2
 mov qword [fields+40+NEBO_REFLECT_FIELD_TYPE_ID],11
 mov qword [fields+40+NEBO_REFLECT_FIELD_OFFSET],8
 mov qword [fields+40+NEBO_REFLECT_FIELD_SIZE],8
 mov qword [fields+40+NEBO_REFLECT_FIELD_VISIBILITY],2
 lea rdi,[type]
 call nebo_reflect_validate_type
 test eax,eax
 jnz fail
 lea rdi,[type]
 mov esi,1
 mov edx,2
 lea rcx,[output]
 call nebo_reflect_field_at
 test eax,eax
 jnz fail
 cmp qword [output+NEBO_REFLECT_FIELD_NAME_ID],2
 jne fail
 lea rdi,[type]
 mov esi,1
 mov edx,1
 lea rcx,[output]
 call nebo_reflect_field_at
 cmp eax,NEBO_REFLECT_STATUS_VISIBILITY
 jne fail
 mov qword [fields+40+NEBO_REFLECT_FIELD_OFFSET],12
 lea rdi,[type]
 call nebo_reflect_validate_type
 cmp eax,NEBO_REFLECT_STATUS_LAYOUT
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
