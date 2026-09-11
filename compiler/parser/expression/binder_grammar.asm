; Bounded binder/domain grammar contracts. No binder lexeme is activated by P01.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/parser/expression/binder_grammar.inc"

section .rodata
name_sum: db "sum"
name_product: db "product"
name_integral: db "integral"
name_quantifier: db "quantifier"
name_domain: db "domain"
align 8
binder_specs:
 dq NEBOC_BINDER_KIND_SUM,name_sum,3,NEBOC_BINDER_MAX_CLAUSES,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_BINDER_KIND_PRODUCT,name_product,7,NEBOC_BINDER_MAX_CLAUSES,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_BINDER_KIND_INTEGRAL,name_integral,8,NEBOC_BINDER_MAX_CLAUSES,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_BINDER_KIND_QUANTIFIER,name_quantifier,10,NEBOC_BINDER_MAX_CLAUSES,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_BINDER_KIND_DOMAIN,name_domain,6,NEBOC_BINDER_MAX_CLAUSES,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED

section .text
; Validate without mutating the request on failure. Only VALIDATED becomes one
; after every bound and domain proof has passed.
NEBOC_ABI_FUNCTION neboc_binder_grammar_validate
 test rdi,rdi
 jz .invalid_argument
 mov rax,[rdi+NEBOC_BINDER_REQUEST_KIND_OFFSET]
 test rax,rax
 jz .invalid_source
 cmp rax,NEBOC_BINDER_KIND_COUNT
 ja .invalid_source
 cmp qword [rdi+NEBOC_BINDER_REQUEST_DOMAIN_PROOF_OFFSET],NEBOC_BINDER_DOMAIN_PROOF_PRESENT
 jne .invalid_source
 mov rax,[rdi+NEBOC_BINDER_REQUEST_CLAUSE_COUNT_OFFSET]
 test rax,rax
 jz .invalid_source
 cmp rax,NEBOC_BINDER_MAX_CLAUSES
 ja .limit
 mov rax,[rdi+NEBOC_BINDER_REQUEST_NESTING_OFFSET]
 cmp rax,NEBOC_BINDER_MAX_NESTING
 ja .limit
 mov rax,[rdi+NEBOC_BINDER_REQUEST_SOURCE_START_OFFSET]
 cmp rax,[rdi+NEBOC_BINDER_REQUEST_SOURCE_END_OFFSET]
 ja .invalid_source
 mov qword [rdi+NEBOC_BINDER_REQUEST_VALIDATED_OFFSET],1
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.invalid_source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; Explain/inspect the grammar kind through one immutable specification table.
NEBOC_ABI_FUNCTION neboc_binder_grammar_spec
 test rdi,rdi
 jz .missing
 cmp rdi,NEBOC_BINDER_KIND_COUNT
 ja .missing
 dec rdi
 imul rdi,NEBOC_BINDER_SPEC_SIZE
 lea rax,[rel binder_specs]
 add rax,rdi
 ret
.missing:
 xor eax,eax
 ret

NEBOC_ABI_FUNCTION neboc_binder_grammar_limits
 mov eax,NEBOC_BINDER_MAX_CLAUSES
 mov edx,NEBOC_BINDER_MAX_NESTING
 mov ecx,NEBOC_BINDER_REQUEST_SIZE
 mov r8d,NEBOC_BINDER_SPEC_SIZE
 mov r9d,NEBOC_BINDER_GRAMMAR_SCHEMA_VERSION
 ret

; parseDomainGrammar is deliberately fail-closed: proof and bounds are
; validated, but inactive binder spellings are not promoted by this group.
NEBOC_ABI_FUNCTION neboc_parse_domain_grammar
 jmp neboc_binder_grammar_validate

section .note.GNU-stack noalloc noexec nowrite progbits
