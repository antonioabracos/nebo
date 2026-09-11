; RF166-G157-F01/F08 schema, staleness and whole-validator orchestration.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/docs/doc_validation.inc"
global neboc_doc_schema_validate
global neboc_doc_validate
extern neboc_doc_validate_parameters
extern neboc_doc_validate_return
extern neboc_doc_validate_errors
extern neboc_doc_validate_effects
extern neboc_doc_validate_ownership
extern neboc_doc_validate_lifecycle
section .text
neboc_doc_schema_validate:
 DOCV_VALIDATE_REQUEST .schema
.schema:
 mov r8,[rdi+NEBOC_DOCV_REQUIRED_MASK_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_FIELD_MASK_OFFSET]
 mov rax,r9
 not rax
 and rax,r8
 jnz .required
 mov r8,[rdi+NEBOC_DOCV_SIGNATURE_HASH_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_PREVIOUS_SIGNATURE_HASH_OFFSET]
 test r9,r9
 jz .same
 cmp r8,r9
 jne .stale
.same:
 DOCV_PUBLISH_NONE
.required:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_SCHEMA_REQUIRED,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_SCAFFOLD_FIELD
.stale:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_STALE,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_NONE

; validate(request, seven_issue_report) -> status.
NEBOC_ABI_FUNCTION neboc_doc_validate
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .argument
 test r13,r13
 jz .argument
 test r13,7
 jnz .argument
 lea rbx,[rel .validators]
 xor r14d,r14d
.loop:
 cmp r14d,NEBOC_DOCV_VALIDATOR_COUNT
 jae .ok
 mov rdi,r12
 mov rsi,r13
 call qword [rbx+r14*8]
 test eax,eax
 jnz .done
 add r13,NEBOC_DOCV_ISSUE_SIZE
 inc r14d
 jmp .loop
.ok:
 xor eax,eax
 jmp .done
.argument:
 mov eax,NEBOC_DOCV_STATUS_ARGUMENT
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
align 8
.validators:
 dq neboc_doc_schema_validate
 dq neboc_doc_validate_parameters
 dq neboc_doc_validate_return
 dq neboc_doc_validate_errors
 dq neboc_doc_validate_effects
 dq neboc_doc_validate_ownership
 dq neboc_doc_validate_lifecycle
section .note.GNU-stack noalloc noexec nowrite progbits
