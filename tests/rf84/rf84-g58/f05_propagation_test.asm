bits 64
default rel
%include "runtime/textual/text_privacy.inc"
extern neboc_privacy_propagate
extern neboc_semantic_privacy_join
section .data
align 8
left: dq 0x4000,NEBO_TRUST_SYSTEM,9000,NEBO_SCORE_UNKNOWN,0x101,NEBO_PRIVACY_PERSONAL_DATA,NEBO_PRIVACY_FLAG_TRUSTED|NEBO_PRIVACY_FLAG_CLASSIFIED,0x10
right: dq 0x5000,NEBO_TRUST_EXTERNAL,7000,8000,0x202,nebo_text_privacy_PRIVACY_SECRET,NEBO_PRIVACY_FLAG_CLASSIFIED,0x20
section .bss
joined: resb NEBO_PRIVACY_METADATA_SIZE
joined_again: resb NEBO_PRIVACY_METADATA_SIZE
section .text
global _start
_start:
 mov edi,NEBO_PRIVACY_PERSONAL_DATA
 mov esi,nebo_text_privacy_PRIVACY_SECRET
 call neboc_semantic_privacy_join
 cmp eax,nebo_text_privacy_PRIVACY_SECRET
 jne fail
 lea rdi,[rel left]
 lea rsi,[rel right]
 mov rdx,0x6000
 lea rcx,[rel joined]
 call neboc_privacy_propagate
 test eax,eax
 jnz fail
 cmp qword [rel joined+NEBO_PRIVACY_TEXT_OFFSET],0x6000
 jne fail
 cmp qword [rel joined+NEBO_PRIVACY_TRUST_OFFSET],NEBO_TRUST_EXTERNAL
 jne fail
 cmp qword [rel joined+NEBO_PRIVACY_QUALITY_OFFSET],7000
 jne fail
 cmp qword [rel joined+NEBO_PRIVACY_CONFIDENCE_OFFSET],NEBO_SCORE_UNKNOWN
 jne fail
 cmp qword [rel joined+NEBO_PRIVACY_LABEL_OFFSET],nebo_text_privacy_PRIVACY_SECRET
 jne fail
 cmp qword [rel joined+NEBO_PRIVACY_AUDIT_OFFSET],0x20
 jne fail
 lea rdi,[rel left]
 lea rsi,[rel right]
 mov rdx,0x6000
 lea rcx,[rel joined_again]
 call neboc_privacy_propagate
 test eax,eax
 jnz fail
 mov rax,[rel joined+NEBO_PRIVACY_LINEAGE_OFFSET]
 cmp rax,[rel joined_again+NEBO_PRIVACY_LINEAGE_OFFSET]
 jne fail
 mov qword [rel joined_again],0x11223344
 mov qword [rel right+NEBO_PRIVACY_LABEL_OFFSET],NEBO_PRIVACY_LABEL_MAX+1
 lea rdi,[rel left]
 lea rsi,[rel right]
 xor edx,edx
 lea rcx,[rel joined_again]
 call neboc_privacy_propagate
 cmp eax,NEBO_PRIVACY_ERROR_LABEL
 jne fail
 cmp qword [rel joined_again],0x11223344
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,5
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
