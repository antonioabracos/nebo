bits 64
default rel
%include "runtime/textual/text_privacy.inc"
extern neboc_quality_score_valid
extern neboc_text_with_quality
extern neboc_text_with_confidence
section .data
align 8
input: dq 0x1000,NEBO_TRUST_VERIFIED,NEBO_SCORE_UNKNOWN,NEBO_SCORE_UNKNOWN,0,0,NEBO_PRIVACY_FLAG_TRUSTED,0
section .bss
quality: resb NEBO_PRIVACY_METADATA_SIZE
confidence: resb NEBO_PRIVACY_METADATA_SIZE
section .text
global _start
_start:
 mov edi,NEBO_SCORE_MAX
 call neboc_quality_score_valid
 cmp eax,1
 jne fail
 lea rdi,[rel input]
 mov esi,8750
 lea rdx,[rel quality]
 call neboc_text_with_quality
 test eax,eax
 jnz fail
 cmp qword [rel quality+NEBO_PRIVACY_QUALITY_OFFSET],8750
 jne fail
 cmp qword [rel quality+NEBO_PRIVACY_CONFIDENCE_OFFSET],NEBO_SCORE_UNKNOWN
 jne fail
 lea rdi,[rel quality]
 mov esi,9250
 lea rdx,[rel confidence]
 call neboc_text_with_confidence
 test eax,eax
 jnz fail
 cmp qword [rel confidence+NEBO_PRIVACY_QUALITY_OFFSET],8750
 jne fail
 cmp qword [rel confidence+NEBO_PRIVACY_CONFIDENCE_OFFSET],9250
 jne fail
 mov qword [rel confidence],0x55667788
 lea rdi,[rel input]
 mov esi,NEBO_SCORE_MAX+1
 lea rdx,[rel confidence]
 call neboc_text_with_quality
 cmp eax,NEBO_PRIVACY_ERROR_SCORE
 jne fail
 cmp qword [rel confidence],0x55667788
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,2
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
