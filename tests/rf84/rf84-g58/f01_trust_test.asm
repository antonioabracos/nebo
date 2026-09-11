bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_privacy.inc"
%include "compiler/semantic/privacy/text_privacy.inc"
extern neboc_text_as_trusted
extern neboc_text_trust_zone
extern neboc_semantic_privacy_validate_zone
section .rodata
data: db 'trusted'
align 8
text: dq data,7,NEBO_TEXT_FLAG_ASCII|NEBO_TEXT_FLAG_VALID_UTF8,NEBO_TEXT_STORAGE_STATIC
section .bss
metadata: resb NEBO_PRIVACY_METADATA_SIZE
section .text
global _start
_start:
 mov edi,NEBO_TRUST_VERIFIED
 call neboc_semantic_privacy_validate_zone
 test eax,eax
 jnz fail
 lea rdi,[rel text]
 mov esi,NEBO_TRUST_VERIFIED
 mov edx,NEBO_TRUST_VALIDATION_TOKEN_BASE|NEBO_TRUST_VERIFIED
 lea rcx,[rel metadata]
 call neboc_text_as_trusted
 test eax,eax
 jnz fail
 lea rdi,[rel metadata]
 call neboc_text_trust_zone
 cmp eax,NEBO_TRUST_VERIFIED
 jne fail
 mov qword [rel metadata],0x11223344
 lea rdi,[rel text]
 mov esi,NEBO_TRUST_SYSTEM
 xor edx,edx
 lea rcx,[rel metadata]
 call neboc_text_as_trusted
 cmp eax,NEBO_PRIVACY_ERROR_VALIDATION
 jne fail
 cmp qword [rel metadata],0x11223344
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
