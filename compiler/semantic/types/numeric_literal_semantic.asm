; Nebo Assembly — LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF003 isolated numeric literal semantic model
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
%include "compiler/semantic/types/numeric_literal_semantic.inc"

section .text

; numeric_literal_semantic_analyze(request*) -> StatusCode
; Consumes a successful LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF002 syntax request plus AST provenance. It is
; deliberately isolated from the public typechecker/CLI in PF003.
NEBOC_ABI_FUNCTION neboc_numeric_literal_semantic_analyze
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_literais_numericos_bases_e_representacao_SEM_SYNTAX_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 ; Clear outputs only.
 lea rdi,[r12+NEBOC_SEM_TYPE_ID_OFFSET]
 mov ecx,(neboc_literais_numericos_bases_e_representacao_SEM_REQUEST_SIZE-NEBOC_SEM_TYPE_ID_OFFSET)/8
 xor eax,eax
 rep stosq
 mov r14,[r12+NEBOC_SEM_CONTEXT_FLAGS_OFFSET]
 mov rax,r14
 and rax,~NEBOC_SEM_CONTEXT_ALLOWED_MASK
 jnz .context_error

 ; Syntax failure is propagated as a semantic source failure with exact span.
 cmp qword [r13+NEBOC_NUMERIC_ERROR_CODE_OFFSET],NEBOC_NUMERIC_DIAG_NONE
 jne .syntax_error
 cmp qword [r13+NEBOC_NUMERIC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .token_error
 test qword [r13+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_ERROR
 jnz .token_error
 cmp qword [r13+NEBOC_NUMERIC_DIGIT_COUNT_OFFSET],0
 je .token_error

 ; AST/token provenance must be exact and immutable.
 mov rax,[r13+NEBOC_NUMERIC_SOURCE_ID_OFFSET]
 cmp rax,[r12+neboc_literais_numericos_bases_e_representacao_SEM_AST_SOURCE_ID_OFFSET]
 jne .span_error
 mov rax,[r13+NEBOC_NUMERIC_TOKEN_START_OFFSET]
 cmp rax,[r12+NEBOC_SEM_AST_START_OFFSET]
 jne .span_error
 mov rbx,[r13+NEBOC_NUMERIC_TOKEN_END_OFFSET]
 cmp rbx,[r12+NEBOC_SEM_AST_END_OFFSET]
 jne .span_error
 cmp rbx,rax
 jb .span_error
 sub rbx,rax
 cmp rbx,[r13+NEBOC_NUMERIC_LENGTH_OFFSET]
 jne .span_error

 ; Base and flag invariants.
 mov r15,[r13+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET]
 mov rax,[r13+NEBOC_NUMERIC_BASE_OFFSET]
 cmp rax,NEBOC_NUMERIC_BASE_DECIMAL
 je .base_decimal
 cmp rax,NEBOC_NUMERIC_BASE_BINARY
 je .base_binary
 cmp rax,NEBOC_NUMERIC_BASE_OCTAL
 je .base_octal
 cmp rax,NEBOC_NUMERIC_BASE_HEX
 je .base_hex
 jmp .provenance_error
.base_decimal:
 test r15,NEBOC_TOKEN_FLAG_INT_BASE_MASK
 jnz .provenance_error
 jmp .base_common
.base_binary:
 mov rax,r15
 and rax,NEBOC_TOKEN_FLAG_INT_BASE_MASK
 cmp rax,NEBOC_TOKEN_FLAG_INT_BASE_BINARY
 jne .provenance_error
 test r15,neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
 jz .provenance_error
 jmp .base_common
.base_octal:
 mov rax,r15
 and rax,NEBOC_TOKEN_FLAG_INT_BASE_MASK
 cmp rax,NEBOC_TOKEN_FLAG_INT_BASE_OCTAL
 jne .provenance_error
 test r15,neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
 jz .provenance_error
 jmp .base_common
.base_hex:
 mov rax,r15
 and rax,NEBOC_TOKEN_FLAG_INT_BASE_MASK
 cmp rax,NEBOC_TOKEN_FLAG_INT_BASE_HEX
 jne .provenance_error
 test r15,neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
 jz .provenance_error
.base_common:
 mov rax,[r13+NEBOC_NUMERIC_SEPARATOR_COUNT_OFFSET]
 test rax,rax
 jz .no_separators
 test r15,NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR
 jz .provenance_error
 test r15,neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
 jz .provenance_error
 jmp .separator_ok
.no_separators:
 test r15,NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR
 jnz .provenance_error
.separator_ok:

 ; Produce the semantic value. 2^63 is accepted only under one unary minus.
 mov rbx,[r13+NEBOC_NUMERIC_VALUE_OFFSET]
 mov rax,0x8000000000000000
 cmp rbx,rax
 je .reserved_magnitude
 test r15,NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 jnz .provenance_error
 test r14,NEBOC_SEM_CONTEXT_UNARY_MINUS
 jz .signed_ready
 neg rbx
 jmp .signed_ready
.reserved_magnitude:
 test r15,NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 jz .provenance_error
 test r14,NEBOC_SEM_CONTEXT_UNARY_MINUS
 jz .positive_overflow
 ; Negating 2^63 in two's complement yields the canonical INT64_MIN bits.
 mov rbx,0x8000000000000000

.signed_ready:
 mov qword [r12+NEBOC_SEM_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 mov [r12+NEBOC_SEM_SIGNED_VALUE_OFFSET],rbx
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_SEM_CONSTANT_STATE_OFFSET],NEBOC_SEM_CONSTANT_VALID
 xor eax,eax
 test r14,NEBOC_SEM_CONTEXT_UNARY_MINUS
 jz .flag_explicit
 or rax,NEBOC_SEM_FLAG_UNARY_MINUS
 mov rdx,0x8000000000000000
 cmp rbx,rdx
 jne .flag_explicit
 or rax,NEBOC_SEM_FLAG_INT64_MIN
.flag_explicit:
 test r14,NEBOC_SEM_CONTEXT_EXPLICIT_INT
 jz .flag_base
 or rax,NEBOC_SEM_FLAG_EXPLICIT_INT
.flag_base:
 cmp qword [r13+NEBOC_NUMERIC_BASE_OFFSET],NEBOC_NUMERIC_BASE_DECIMAL
 je .flag_separator
 or rax,NEBOC_SEM_FLAG_BASE_PROVENANCE
.flag_separator:
 cmp qword [r13+NEBOC_NUMERIC_SEPARATOR_COUNT_OFFSET],0
 je .store_sem_flags
 or rax,NEBOC_SEM_FLAG_SEPARATOR_PROVENANCE
.store_sem_flags:
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_FLAGS_OFFSET],rax
 mov rax,[r13+NEBOC_NUMERIC_BASE_OFFSET]
 mov [r12+NEBOC_SEM_PROVENANCE_BASE_OFFSET],rax
 mov rax,[r13+NEBOC_NUMERIC_DIGIT_COUNT_OFFSET]
 mov [r12+NEBOC_SEM_PROVENANCE_DIGITS_OFFSET],rax
 mov rax,[r13+NEBOC_NUMERIC_SEPARATOR_COUNT_OFFSET]
 mov [r12+NEBOC_SEM_PROVENANCE_SEPARATORS_OFFSET],rax
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_INT_CONSTANT
 mov qword [r12+NEBOC_SEM_LIR_REPR_OFFSET],NEBOC_SEM_LIR_SIGNED_I64
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_SEM_RUNTIME_METADATA_OFFSET],neboc_literais_numericos_bases_e_representacao_SEM_RUNTIME_METADATA_NONE
 call .compute_hashes
 xor eax,eax
 jmp .done

.syntax_error:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],NEBOC_SEM_ERROR_SYNTAX_INVALID
 mov rax,[r13+NEBOC_NUMERIC_ERROR_CODE_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_SOURCE_DIAG_OFFSET],rax
 mov rax,[r13+NEBOC_NUMERIC_ERROR_START_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_START_OFFSET],rax
 mov rax,[r13+NEBOC_NUMERIC_ERROR_END_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.positive_overflow:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],NEBOC_SEM_ERROR_POSITIVE_MAGNITUDE_OVERFLOW
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_SEM_SOURCE_DIAG_OFFSET],NEBOC_NUMERIC_DIAG_OVERFLOW
 mov rax,[r13+NEBOC_NUMERIC_TOKEN_START_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_START_OFFSET],rax
 mov rax,[r13+NEBOC_NUMERIC_TOKEN_END_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.context_error:
 mov ecx,neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CONTEXT_INVARIANT
 jmp .internal_error
.token_error:
 mov ecx,NEBOC_SEM_ERROR_TOKEN_INVARIANT
 jmp .internal_error
.provenance_error:
 mov ecx,NEBOC_SEM_ERROR_PROVENANCE_INVARIANT
 jmp .internal_error
.span_error:
 mov ecx,neboc_literais_numericos_bases_e_representacao_SEM_ERROR_SPAN_INVARIANT
.internal_error:
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],rcx
 mov rax,[r13+NEBOC_NUMERIC_TOKEN_START_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_START_OFFSET],rax
 mov rax,[r13+NEBOC_NUMERIC_TOKEN_END_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done

.compute_hashes:
 ; Semantic hash intentionally excludes spelling/base/explicit form.
 mov rax,neboc_literais_numericos_bases_e_representacao_SEM_HASH_OFFSET_BASIS
 mov rcx,neboc_literais_numericos_bases_e_representacao_SEM_HASH_PRIME
 xor rax,[r12+NEBOC_SEM_TYPE_ID_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_SIGNED_VALUE_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_SEM_CONSTANT_STATE_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_SEM_HIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_LIR_REPR_OFFSET]
 imul rax,rcx
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_SEMANTIC_HASH_OFFSET],rax
 ; Provenance hash includes exact syntax hash, token index and semantic flags.
 mov rax,neboc_literais_numericos_bases_e_representacao_SEM_HASH_OFFSET_BASIS
 xor rax,[r13+NEBOC_NUMERIC_HASH_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_AST_TOKEN_INDEX_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_SEM_FLAGS_OFFSET]
 imul rax,rcx
 mov [r12+neboc_literais_numericos_bases_e_representacao_SEM_PROVENANCE_HASH_OFFSET],rax
 ret
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
