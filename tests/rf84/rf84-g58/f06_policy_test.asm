bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_privacy.inc"
extern neboc_privacy_redact
extern neboc_privacy_declassify
extern neboc_privacy_sink_check
extern neboc_semantic_privacy_sink_accepts
section .rodata
secret_bytes: db 'token-value'
align 8
secret_text: dq secret_bytes,11,NEBO_TEXT_FLAG_STATIC|NEBO_TEXT_FLAG_VALID_UTF8|NEBO_TEXT_FLAG_ASCII,NEBO_TEXT_STORAGE_STATIC
section .data
align 8
secret_meta: dq secret_text,NEBO_TRUST_VERIFIED,9000,9000,0x303,nebo_text_privacy_PRIVACY_SECRET,NEBO_PRIVACY_FLAG_TRUSTED|NEBO_PRIVACY_FLAG_CLASSIFIED,0
section .bss
redacted: resb NEBO_PRIVACY_METADATA_SIZE
public_meta: resb NEBO_PRIVACY_METADATA_SIZE
violation: resb NEBO_VIOLATION_SIZE
section .text
global _start
_start:
 lea rdi,[rel secret_meta]
 mov esi,NEBO_REDACTION_POLICY_FULL
 lea rdx,[rel redacted]
 call neboc_privacy_redact
 test eax,eax
 jnz fail
 cmp qword [rel redacted+NEBO_PRIVACY_LABEL_OFFSET],NEBO_PRIVACY_REDACTED
 jne fail
 mov rax,[rel redacted+NEBO_PRIVACY_TEXT_OFFSET]
 lea rcx,[rel secret_text]
 cmp rax,rcx
 je fail
 cmp qword [rax+NEBO_TEXT_LENGTH_OFFSET],10
 jne fail
 mov rax,[rax+NEBO_TEXT_DATA_OFFSET]
 cmp byte [rax],'['
 jne fail
 lea rdi,[rel redacted]
 mov esi,nebo_text_privacy_PRIVACY_PUBLIC
 lea rdx,[rel violation]
 call neboc_privacy_sink_check
 cmp eax,NEBO_PRIVACY_ERROR_SINK
 jne fail
 cmp qword [rel violation+NEBO_VIOLATION_DIAGNOSTIC_OFFSET],NEBO_DIAG_PRIVACY_SINK
 jne fail
 mov qword [rel public_meta],0x11223344
 lea rdi,[rel secret_meta]
 mov esi,nebo_text_privacy_PRIVACY_PUBLIC
 mov edx,7
 xor ecx,ecx
 lea r8,[rel public_meta]
 call neboc_privacy_declassify
 cmp eax,NEBO_PRIVACY_ERROR_CAPABILITY
 jne fail
 cmp qword [rel public_meta],0x11223344
 jne fail
 lea rdi,[rel secret_meta]
 mov esi,nebo_text_privacy_PRIVACY_PUBLIC
 mov edx,7
 mov rcx,NEBO_DECLASSIFY_CAPABILITY_V1
 lea r8,[rel public_meta]
 call neboc_privacy_declassify
 test eax,eax
 jnz fail
 cmp qword [rel public_meta+NEBO_PRIVACY_LABEL_OFFSET],nebo_text_privacy_PRIVACY_PUBLIC
 jne fail
 cmp qword [rel public_meta+NEBO_PRIVACY_AUDIT_OFFSET],0
 je fail
 mov edi,nebo_text_privacy_PRIVACY_PUBLIC
 mov esi,nebo_text_privacy_PRIVACY_PUBLIC
 call neboc_semantic_privacy_sink_accepts
 cmp eax,1
 jne fail
 lea rdi,[rel public_meta]
 mov esi,nebo_text_privacy_PRIVACY_PUBLIC
 lea rdx,[rel violation]
 call neboc_privacy_sink_check
 test eax,eax
 jnz fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,6
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
