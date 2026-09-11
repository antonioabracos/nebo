; RF166-G157 native resolved-contract and failure-atomicity test.
bits 64
default rel
%include "compiler/semantic/docs/doc_validation.inc"
global _start
extern neboc_doc_validate
extern neboc_doc_validate_parameters
extern neboc_doc_validate_return
extern neboc_doc_validate_errors
extern neboc_doc_validate_capabilities
extern neboc_doc_validate_complexity
extern neboc_doc_validate_risks
extern neboc_doc_validate_target_availability

%define SENTINEL 0xa5a5a5a5a5a5a5a5
section .text
_start:
 ; A fully resolved, equal DocRecord/SymbolContract produces seven zero issues.
 lea rdi,[rel request]
 lea rsi,[rel report]
 call neboc_doc_validate
 test eax,eax
 jnz fail
 lea rdi,[rel report]
 mov ecx,NEBOC_DOCV_VALIDATOR_COUNT
.zero_loop:
 cmp qword [rdi+NEBOC_DOCV_ISSUE_CODE_OFFSET],0
 jne fail
 add rdi,NEBOC_DOCV_ISSUE_SIZE
 loop .zero_loop

 ; Same cardinality but changed resolved identity is a mechanical rename issue.
 mov qword [rel request+NEBOC_DOCV_DOC_PARAM_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_DOCV_SYMBOL_PARAM_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_DOCV_DOC_PARAMS_OFFSET],41
 mov qword [rel request+NEBOC_DOCV_SYMBOL_PARAMS_OFFSET],43
 lea rdi,[rel request]
 lea rsi,[rel issue]
 call neboc_doc_validate_parameters
 test eax,eax
 jnz fail
 cmp qword [rel issue+NEBOC_DOCV_ISSUE_CODE_OFFSET],NEBOC_DOCV_CODE_PARAMETER_IDENTITY
 jne fail
 cmp qword [rel issue+NEBOC_DOCV_ISSUE_FIX_KIND_OFFSET],NEBOC_DOCV_FIX_RENAME_PARAMETER
 jne fail
 mov rax,[rel request+NEBOC_DOCV_DOC_SPAN_OFFSET]
 cmp [rel issue+NEBOC_DOCV_ISSUE_PRIMARY_SPAN_OFFSET],rax
 jne fail
 mov rax,[rel request+NEBOC_DOCV_DECL_SPAN_OFFSET]
 cmp [rel issue+NEBOC_DOCV_ISSUE_RELATED_SPAN_OFFSET],rax
 jne fail
 mov qword [rel request+NEBOC_DOCV_DOC_PARAMS_OFFSET],43

 ; Return, error, capability, complexity, risk and target families retain
 ; distinct stable codes over the same SymbolId and two spans.
 mov qword [rel request+NEBOC_DOCV_SYMBOL_RETURN_OFFSET],47
 call_return:
 lea rdi,[rel request]
 lea rsi,[rel issue]
 call neboc_doc_validate_return
 cmp qword [rel issue],NEBOC_DOCV_CODE_RETURN
 jne fail
 mov qword [rel request+NEBOC_DOCV_DOC_RETURN_OFFSET],47

 mov qword [rel request+NEBOC_DOCV_SYMBOL_ERRORS_OFFSET],1
 lea rdi,[rel request]
 lea rsi,[rel issue]
 call neboc_doc_validate_errors
 cmp qword [rel issue],NEBOC_DOCV_CODE_ERRORS_MISSING
 jne fail
 cmp qword [rel issue+8],NEBOC_DOCV_SEVERITY_ERROR
 jne fail
 mov qword [rel request+NEBOC_DOCV_DOC_ERRORS_OFFSET],1

 mov qword [rel request+NEBOC_DOCV_SYMBOL_CAPABILITIES_OFFSET],4
 lea rdi,[rel request]
 lea rsi,[rel issue]
 call neboc_doc_validate_capabilities
 cmp qword [rel issue],NEBOC_DOCV_CODE_CAPABILITIES
 jne fail
 mov qword [rel request+NEBOC_DOCV_DOC_CAPABILITIES_OFFSET],4

 mov qword [rel request+NEBOC_DOCV_SYMBOL_COMPLEXITY_OFFSET],53
 lea rdi,[rel request]
 lea rsi,[rel issue]
 call neboc_doc_validate_complexity
 cmp qword [rel issue],NEBOC_DOCV_CODE_COMPLEXITY
 jne fail
 mov qword [rel request+NEBOC_DOCV_DOC_COMPLEXITY_OFFSET],53

 mov qword [rel request+NEBOC_DOCV_REQUIRED_RISKS_OFFSET],8
 lea rdi,[rel request]
 lea rsi,[rel issue]
 call neboc_doc_validate_risks
 cmp qword [rel issue],NEBOC_DOCV_CODE_RISKS
 jne fail
 mov qword [rel request+NEBOC_DOCV_DOC_RISKS_OFFSET],8

 mov qword [rel request+NEBOC_DOCV_DOC_TARGET_OFFSET],2
 lea rdi,[rel request]
 lea rsi,[rel issue]
 call neboc_doc_validate_target_availability
 cmp qword [rel issue],NEBOC_DOCV_CODE_TARGET
 jne fail

 ; A malformed request is rejected before touching caller storage.
 mov rax,SENTINEL
 mov [rel issue],rax
 mov qword [rel request+NEBOC_DOCV_MAGIC_OFFSET],0
 lea rdi,[rel request]
 lea rsi,[rel issue]
 call neboc_doc_validate_return
 cmp eax,NEBOC_DOCV_STATUS_CONTRACT
 jne fail
 mov rax,SENTINEL
 cmp [rel issue],rax
 jne fail
 xor edi,edi
 jmp exit
fail:
 mov edi,1
exit:
 mov eax,60
 syscall

section .data align=16
request:
 dq NEBOC_DOC_VALIDATION_MAGIC,NEBOC_DOC_VALIDATION_VERSION,7
 dq 1,1                       ; fields, required
 dq 0,0                       ; parameter counts
 dq 0,0,0,0                   ; documented params
 dq 0,0,0,0                   ; symbol params
 dq 0,0                       ; return
 dq 0,0                       ; errors
 dq 0,0                       ; effects
 dq 0,0                       ; capabilities
 dq 0,0                       ; ownership
 dq 0,0                       ; complexity
 dq 0,0                       ; risks
 dq 1,0,1                     ; since, deprecated, current
 dq 0,1                       ; documented/active targets
 dq 0x0000000800000010        ; doc span
 dq 0x0000000c00000040        ; declaration span
 dq 0x71,0                    ; current/previous signature
 dq NEBOC_DOCV_POLICY_CONTRADICTIONS_ERROR,NEBOC_DOCV_VISIBILITY_PUBLIC
report: times NEBOC_DOCV_REPORT_SIZE db 0
issue: times NEBOC_DOCV_ISSUE_SIZE db 0
section .note.GNU-stack noalloc noexec nowrite progbits
