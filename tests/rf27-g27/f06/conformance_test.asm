bits 64
default rel
%include "compiler/conformance/conformance.inc"
extern nebo_conformance_case
extern nebo_conformance_manifest
section .bss
align 16
cases resb NEBO_CONF_CASE_SIZE*3
manifest resb NEBO_CONF_MANIFEST_SIZE
section .text
prepare:
 lea rdi,[cases]
 mov ecx,NEBO_CONF_CASE_SIZE*3/8
 xor eax,eax
 rep stosq
 xor ecx,ecx
.p:
 mov rax,rcx
 imul rax,NEBO_CONF_CASE_SIZE
 lea rdx,[cases+rax]
 mov qword [rdx+NEBO_CONF_CASE_SCHEMA],1
 lea rax,[rcx+101]
 mov [rdx+NEBO_CONF_CASE_RULE],rax
 lea rax,[rcx+1]
 mov [rdx+NEBO_CONF_CASE_CLASS],rax
 mov qword [rdx+NEBO_CONF_CASE_TARGET],1
 mov qword [rdx+NEBO_CONF_CASE_EDITION],2
 inc rcx
 cmp rcx,3
 jb .p
 ret
global _start
_start:
 call prepare
 lea rdi,[cases]
 call nebo_conformance_case
 test eax,eax
 jnz .f1
 mov qword [cases+NEBO_CONF_CASE_SCHEMA],2
 lea rdi,[cases]
 call nebo_conformance_case
 cmp eax,NEBO_CONF_STATUS_SCHEMA
 jne .f2
 mov qword [cases+NEBO_CONF_CASE_SCHEMA],1
 mov qword [cases+NEBO_CONF_CASE_RULE],0
 lea rdi,[cases]
 call nebo_conformance_case
 cmp eax,NEBO_CONF_STATUS_RULE
 jne .f3
 mov qword [cases+NEBO_CONF_CASE_RULE],101
 mov qword [cases+NEBO_CONF_CASE_CLASS],4
 lea rdi,[cases]
 call nebo_conformance_case
 cmp eax,NEBO_CONF_STATUS_CLASS
 jne .f4
 mov qword [cases+NEBO_CONF_CASE_CLASS],1
 mov qword [cases+NEBO_CONF_CASE_ACTUAL],1
 lea rdi,[cases]
 call nebo_conformance_case
 cmp eax,NEBO_CONF_STATUS_EXPECTED
 jne .f5
 mov qword [cases+NEBO_CONF_CASE_ACTUAL],0
 mov qword [cases+NEBO_CONF_CASE_TARGET],2
 lea rdi,[cases]
 call nebo_conformance_case
 cmp eax,NEBO_CONF_STATUS_TARGET
 jne .f6
 mov qword [cases+NEBO_CONF_CASE_TARGET],1
 mov qword [cases+NEBO_CONF_CASE_ABI],1
 lea rdi,[cases]
 call nebo_conformance_case
 cmp eax,NEBO_CONF_STATUS_ABI
 jne .f7
 mov qword [cases+NEBO_CONF_CASE_ABI],0
 mov qword [cases+NEBO_CONF_CASE_EDITION],3
 lea rdi,[cases]
 call nebo_conformance_case
 cmp eax,NEBO_CONF_STATUS_EDITION
 jne .f8
 call prepare
 lea rdi,[manifest]
 mov ecx,NEBO_CONF_MANIFEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[cases]
 mov [manifest+NEBO_CONF_MANIFEST_CASES],rax
 mov qword [manifest+NEBO_CONF_MANIFEST_COUNT],3
 lea rdi,[manifest]
 call nebo_conformance_manifest
 test eax,eax
 jnz .f9
 cmp qword [manifest+NEBO_CONF_MANIFEST_PASS],3
 jne .f10
 cmp qword [manifest+NEBO_CONF_MANIFEST_FAIL],0
 jne .f11
 cmp qword [manifest+NEBO_CONF_MANIFEST_HASH],0
 je .f12
 mov qword [cases+NEBO_CONF_CASE_SIZE+NEBO_CONF_CASE_ACTUAL],1
 lea rdi,[manifest]
 call nebo_conformance_manifest
 cmp eax,NEBO_CONF_STATUS_EXPECTED
 jne .f13
 cmp qword [manifest+NEBO_CONF_MANIFEST_PASS],2
 jne .f14
 cmp qword [manifest+NEBO_CONF_MANIFEST_FAIL],1
 jne .f15
 cmp qword [manifest+NEBO_CONF_MANIFEST_FIRST],2
 jne .f16
 mov qword [manifest+NEBO_CONF_MANIFEST_COUNT],4097
 lea rdi,[manifest]
 call nebo_conformance_manifest
 cmp eax,NEBO_CONF_STATUS_LIMIT
 jne .f17
 xor edi,edi
 call nebo_conformance_case
 cmp eax,NEBO_CONF_STATUS_INVALID_ARGUMENT
 jne .f18
 xor edi,edi
 call nebo_conformance_manifest
 cmp eax,NEBO_CONF_STATUS_INVALID_ARGUMENT
 jne .f19
 xor edi,edi
 mov eax,60
 syscall
%macro FAIL 1
.f%1: mov edi,%1
 mov eax,60
 syscall
%endmacro
%assign i 1
%rep 19
FAIL i
%assign i i+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
