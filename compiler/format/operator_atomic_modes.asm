; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA check/diff/stdout/atomic-write execution plans.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/format/symbol_style_profile.inc"

section .text
; operator_atomic_mode(mode, input_len, output_len, changed, equivalent, out_plan*)
NEBOC_ABI_FUNCTION neboc_operator_atomic_mode
 test r9,r9
 jz .invalid
 cmp rdi,NEBOC_SYMBOL_FORMAT_MODE_WRITE
 ja .source
 cmp rsi,NEBOC_SYMBOL_FORMAT_MAX_INPUT_BYTES
 ja .limit
 cmp rdx,NEBOC_SYMBOL_FORMAT_MAX_OUTPUT_BYTES
 ja .limit
 cmp rcx,1
 ja .source
 cmp r8,1
 jne .source
 xor r10d,r10d
 xor r11d,r11d
 xor eax,eax
 cmp rdi,NEBOC_SYMBOL_FORMAT_MODE_CHECK
 je .check
 mov r10,rcx
 cmp rdi,NEBOC_SYMBOL_FORMAT_MODE_WRITE
 jne .store
 xor r10d,r10d
 mov r11,rcx
 jmp .store
.check:
 mov rax,rcx
.store:
 mov [r9+NEBOC_FORMAT_MODE_PLAN_MODE_OFFSET],rdi
 mov [r9+NEBOC_FORMAT_MODE_PLAN_EMIT_OFFSET],r10
 mov [r9+NEBOC_FORMAT_MODE_PLAN_WRITE_OFFSET],r11
 mov [r9+NEBOC_FORMAT_MODE_PLAN_TEMP_OFFSET],r11
 mov [r9+NEBOC_FORMAT_MODE_PLAN_ROLLBACK_OFFSET],r11
 mov qword [r9+NEBOC_FORMAT_MODE_PLAN_COMMIT_OFFSET],1
 mov [r9+NEBOC_FORMAT_MODE_PLAN_EXIT_OFFSET],rax
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
