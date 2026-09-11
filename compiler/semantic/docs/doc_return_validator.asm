; RF166-G157-F03 resolved return class (void/scalar/tuple/Option/Result).
bits 64
default rel
%include "compiler/semantic/docs/doc_validation.inc"
global neboc_doc_return_validate
global neboc_doc_validate_return
section .text
neboc_doc_return_validate:
neboc_doc_validate_return:
 DOCV_VALIDATE_REQUEST .validated
.validated:
 mov r8,[rdi+NEBOC_DOCV_SYMBOL_RETURN_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_RETURN_OFFSET]
 cmp r8,r9
 jne .different
 DOCV_PUBLISH_NONE
.different:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_RETURN,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_SCAFFOLD_FIELD
section .note.GNU-stack noalloc noexec nowrite progbits
