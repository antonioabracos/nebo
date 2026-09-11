; RF166-G157-F02 resolved parameter identity/type/default/order validation.
bits 64
default rel
%include "compiler/semantic/docs/doc_validation.inc"
global neboc_doc_parameter_validate
global neboc_doc_validate_parameters
section .text
neboc_doc_parameter_validate:
neboc_doc_validate_parameters:
 DOCV_VALIDATE_REQUEST .validated
.validated:
 mov r8,[rdi+NEBOC_DOCV_SYMBOL_PARAM_COUNT_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_PARAM_COUNT_OFFSET]
 cmp r8,r9
 jne .count
 xor ecx,ecx
.loop:
 cmp rcx,r8
 jae .same
 mov rax,[rdi+NEBOC_DOCV_SYMBOL_PARAMS_OFFSET+rcx*8]
 cmp rax,[rdi+NEBOC_DOCV_DOC_PARAMS_OFFSET+rcx*8]
 jne .identity
 inc rcx
 jmp .loop
.count:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_PARAMETER_COUNT,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_SCAFFOLD_FIELD
.identity:
 mov r8,[rdi+NEBOC_DOCV_SYMBOL_PARAMS_OFFSET+rcx*8]
 mov r9,[rdi+NEBOC_DOCV_DOC_PARAMS_OFFSET+rcx*8]
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_PARAMETER_IDENTITY,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_RENAME_PARAMETER
.same:
 DOCV_PUBLISH_NONE
section .note.GNU-stack noalloc noexec nowrite progbits
