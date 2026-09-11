; DIAGNOSTICS-LSP-E-MIGRACAO-DE-OPERADORES canonical fact parity across terminal/JSON/JSONL/LSP/SARIF.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"

section .text
; operator_machine_parity(diag*, format, out_render*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_operator_machine_parity
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBOC_OPERATOR_RENDER_MAX
 ja .source
 mov r8,0xcbf29ce484222325
 xor r9d,r9d
.hash:
 cmp r9d,11
 jae .store
 xor r8,[rdi+r9*8]
 mov rax,0x100000001b3
 imul r8,rax
 inc r9d
 jmp .hash
.store:
 mov [rdx+NEBOC_OPERATOR_RENDER_FORMAT_OFFSET],rsi
 mov [rdx+NEBOC_OPERATOR_RENDER_FACT_HASH_OFFSET],r8
 mov qword [rdx+NEBOC_OPERATOR_RENDER_FIELD_COUNT_OFFSET],11
 mov rax,[rdi+NEBOC_OPERATOR_DIAG_CODE_OFFSET]
 mov [rdx+NEBOC_OPERATOR_RENDER_CODE_OFFSET],rax
 mov rax,[rdi+NEBOC_OPERATOR_DIAG_START_OFFSET]
 mov [rdx+NEBOC_OPERATOR_RENDER_START_OFFSET],rax
 mov rax,[rdi+NEBOC_OPERATOR_DIAG_END_OFFSET]
 mov [rdx+NEBOC_OPERATOR_RENDER_END_OFFSET],rax
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
