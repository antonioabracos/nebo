bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/conformance/conformance.inc"
section .text
NEBOC_ABI_FUNCTION nebo_conformance_case
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 cmp qword [rdi+NEBO_CONF_CASE_SCHEMA],1
 jne .schema
 cmp qword [rdi+NEBO_CONF_CASE_RULE],0
 je .rule
 mov rax,[rdi+NEBO_CONF_CASE_CLASS]
 cmp rax,1
 jb .class
 cmp rax,3
 ja .class
 mov rax,[rdi+NEBO_CONF_CASE_EXPECTED]
 cmp rax,[rdi+NEBO_CONF_CASE_ACTUAL]
 jne .expected
 cmp qword [rdi+NEBO_CONF_CASE_TARGET],1
 jne .target
 cmp qword [rdi+NEBO_CONF_CASE_ABI],0
 jne .abi
 mov rax,[rdi+NEBO_CONF_CASE_EDITION]
 cmp rax,1
 jb .edition
 cmp rax,2
 ja .edition
 xor eax,eax
 ret
.schema: mov eax,NEBO_CONF_STATUS_SCHEMA
 ret
.rule: mov eax,NEBO_CONF_STATUS_RULE
 ret
.class: mov eax,NEBO_CONF_STATUS_CLASS
 ret
.expected: mov eax,NEBO_CONF_STATUS_EXPECTED
 ret
.target: mov eax,NEBO_CONF_STATUS_TARGET
 ret
.abi: mov eax,NEBO_CONF_STATUS_ABI
 ret
.edition: mov eax,NEBO_CONF_STATUS_EDITION
 ret
.invalid: mov eax,NEBO_CONF_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION nebo_conformance_manifest
 test rdi,rdi
 jz .m_invalid
 test rdi,7
 jnz .m_invalid
 mov qword [rdi+NEBO_CONF_MANIFEST_PASS],0
 mov qword [rdi+NEBO_CONF_MANIFEST_FAIL],0
 mov qword [rdi+NEBO_CONF_MANIFEST_FIRST],0
 mov qword [rdi+NEBO_CONF_MANIFEST_HASH],0
 mov r8,[rdi+NEBO_CONF_MANIFEST_CASES]
 test r8,r8
 jz .m_invalid
 mov r9,[rdi+NEBO_CONF_MANIFEST_COUNT]
 test r9,r9
 jz .m_invalid
 cmp r9,NEBO_CONF_MAX_CASES
 ja .m_limit
 xor r10d,r10d
 xor r11d,r11d
 xor ecx,ecx
.loop:
 mov rax,rcx
 imul rax,NEBO_CONF_CASE_SIZE
 add rax,r8
 cmp qword [rax+NEBO_CONF_CASE_SCHEMA],1
 jne .bad
 cmp qword [rax+NEBO_CONF_CASE_RULE],0
 je .bad
 mov rdx,[rax+NEBO_CONF_CASE_CLASS]
 cmp rdx,1
 jb .bad
 cmp rdx,3
 ja .bad
 mov rdx,[rax+NEBO_CONF_CASE_EXPECTED]
 cmp rdx,[rax+NEBO_CONF_CASE_ACTUAL]
 jne .bad
 cmp qword [rax+NEBO_CONF_CASE_TARGET],1
 jne .bad
 cmp qword [rax+NEBO_CONF_CASE_ABI],0
 jne .bad
 mov rdx,[rax+NEBO_CONF_CASE_EDITION]
 cmp rdx,1
 jb .bad
 cmp rdx,2
 ja .bad
 inc r10
 mov rdx,[rax+NEBO_CONF_CASE_RULE]
 rol r11,7
 xor r11,rdx
 jmp .next
.bad:
 cmp qword [rdi+NEBO_CONF_MANIFEST_FIRST],0
 jne .bad_count
 lea rdx,[rcx+1]
 mov [rdi+NEBO_CONF_MANIFEST_FIRST],rdx
.bad_count: inc qword [rdi+NEBO_CONF_MANIFEST_FAIL]
.next: inc rcx
 cmp rcx,r9
 jb .loop
 mov [rdi+NEBO_CONF_MANIFEST_PASS],r10
 mov [rdi+NEBO_CONF_MANIFEST_HASH],r11
 cmp qword [rdi+NEBO_CONF_MANIFEST_FAIL],0
 jne .m_expected
 xor eax,eax
 ret
.m_expected: mov eax,NEBO_CONF_STATUS_EXPECTED
 ret
.m_limit: mov eax,NEBO_CONF_STATUS_LIMIT
 ret
.m_invalid: mov eax,NEBO_CONF_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
