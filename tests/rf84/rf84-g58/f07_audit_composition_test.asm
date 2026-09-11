bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_privacy.inc"
extern neboc_text_with_quality
extern neboc_text_with_confidence
extern neboc_text_with_lineage
extern neboc_text_with_privacy_label
extern neboc_privacy_propagate
extern neboc_privacy_redact
extern neboc_privacy_sink_check
extern neboc_privacy_error_diagnostic
extern neboc_privacy_audit_valid
section .rodata
result_bytes: db 'joined'
align 8
result_text: dq result_bytes,6,NEBO_TEXT_FLAG_STATIC|NEBO_TEXT_FLAG_VALID_UTF8|NEBO_TEXT_FLAG_ASCII,NEBO_TEXT_STORAGE_STATIC
section .data
align 8
base: dq result_text,NEBO_TRUST_VERIFIED,NEBO_SCORE_UNKNOWN,NEBO_SCORE_UNKNOWN,0,nebo_text_privacy_PRIVACY_PUBLIC,NEBO_PRIVACY_FLAG_TRUSTED,0
right: dq result_text,NEBO_TRUST_USER_VALIDATED,7000,7500,0x202,NEBO_PRIVACY_PERSONAL_DATA,NEBO_PRIVACY_FLAG_TRUSTED|NEBO_PRIVACY_FLAG_CLASSIFIED,0
section .bss
stage1: resb NEBO_PRIVACY_METADATA_SIZE
stage2: resb NEBO_PRIVACY_METADATA_SIZE
stage3: resb NEBO_PRIVACY_METADATA_SIZE
stage4: resb NEBO_PRIVACY_METADATA_SIZE
joined: resb NEBO_PRIVACY_METADATA_SIZE
redacted: resb NEBO_PRIVACY_METADATA_SIZE
violation: resb NEBO_VIOLATION_SIZE
section .text
global _start
_start:
 lea rdi,[rel base]
 mov esi,9000
 lea rdx,[rel stage1]
 call neboc_text_with_quality
 test eax,eax
 jnz fail
 lea rdi,[rel stage1]
 mov esi,8500
 lea rdx,[rel stage2]
 call neboc_text_with_confidence
 test eax,eax
 jnz fail
 lea rdi,[rel stage2]
 mov esi,0x101
 lea rdx,[rel stage3]
 call neboc_text_with_lineage
 test eax,eax
 jnz fail
 lea rdi,[rel stage3]
 mov esi,nebo_text_privacy_PRIVACY_SENSITIVE
 lea rdx,[rel stage4]
 call neboc_text_with_privacy_label
 test eax,eax
 jnz fail
 lea rdi,[rel stage4]
 lea rsi,[rel right]
 lea rdx,[rel result_text]
 lea rcx,[rel joined]
 call neboc_privacy_propagate
 test eax,eax
 jnz fail
 cmp qword [rel joined+NEBO_PRIVACY_TRUST_OFFSET],NEBO_TRUST_USER_VALIDATED
 jne fail
 cmp qword [rel joined+NEBO_PRIVACY_QUALITY_OFFSET],7000
 jne fail
 cmp qword [rel joined+NEBO_PRIVACY_CONFIDENCE_OFFSET],7500
 jne fail
 cmp qword [rel joined+NEBO_PRIVACY_LABEL_OFFSET],nebo_text_privacy_PRIVACY_SENSITIVE
 jne fail
 lea rdi,[rel joined]
 mov esi,NEBO_REDACTION_POLICY_FULL
 lea rdx,[rel redacted]
 call neboc_privacy_redact
 test eax,eax
 jnz fail
 lea rdi,[rel redacted]
 call neboc_privacy_audit_valid
 cmp eax,1
 jne fail
 lea rdi,[rel redacted]
 mov esi,NEBO_PRIVACY_REDACTED
 lea rdx,[rel violation]
 call neboc_privacy_sink_check
 test eax,eax
 jnz fail
 mov edi,NEBO_PRIVACY_ERROR_SINK
 call neboc_privacy_error_diagnostic
 cmp eax,NEBO_DIAG_PRIVACY_SINK
 jne fail
 mov edi,99
 call neboc_privacy_error_diagnostic
 cmp eax,-NEBO_PRIVACY_ERROR_POLICY
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,7
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
