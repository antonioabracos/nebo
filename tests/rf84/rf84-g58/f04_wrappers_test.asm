bits 64
default rel
%include "runtime/textual/text_privacy.inc"
%include "compiler/semantic/privacy/text_privacy.inc"
extern neboc_text_with_privacy_label
extern neboc_text_privacy_label
extern neboc_semantic_privacy_validate_label
section .data
align 8
public_meta: dq 0x3000,NEBO_TRUST_VERIFIED,8000,9000,0x101,nebo_text_privacy_PRIVACY_PUBLIC,NEBO_PRIVACY_FLAG_TRUSTED,0
section .bss
wrapped: resb NEBO_PRIVACY_METADATA_SIZE
section .text
global _start
_start:
 xor ebx,ebx
.wrapper_loop:
 lea rdi,[rel public_meta]
 mov rsi,rbx
 lea rdx,[rel wrapped]
 call neboc_text_with_privacy_label
 test eax,eax
 jnz fail
 lea rdi,[rel wrapped]
 call neboc_text_privacy_label
 cmp rax,rbx
 jne fail
 inc ebx
 cmp ebx,NEBO_PRIVACY_LABEL_MAX
 jbe .wrapper_loop
 mov edi,NEBO_PRIVACY_LABEL_MAX+1
 call neboc_semantic_privacy_validate_label
 cmp eax,NEBO_PRIVACY_SEMANTIC_REJECT
 jne fail
 mov qword [rel wrapped],0xabcdef
 lea rdi,[rel public_meta]
 mov esi,NEBO_PRIVACY_LABEL_MAX+1
 lea rdx,[rel wrapped]
 call neboc_text_with_privacy_label
 cmp eax,NEBO_PRIVACY_ERROR_LABEL
 jne fail
 cmp qword [rel wrapped],0xabcdef
 jne fail
 mov qword [rel public_meta+NEBO_PRIVACY_LABEL_OFFSET],nebo_text_privacy_PRIVACY_SECRET
 lea rdi,[rel public_meta]
 mov esi,nebo_text_privacy_PRIVACY_PUBLIC
 lea rdx,[rel wrapped]
 call neboc_text_with_privacy_label
 cmp eax,NEBO_PRIVACY_ERROR_POLICY
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,4
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
