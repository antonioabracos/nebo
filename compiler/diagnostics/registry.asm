; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F01 canonical diagnostic code registry v1.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/registry.inc"

section .rodata
code_e0001: db "NEBO-E0001"
code_e0001_len equ $-code_e0001
key_e0001: db "diagnostic.schema.invalid"
key_e0001_len equ $-key_e0001
code_e0002: db "NEBO-E0002"
code_e0002_len equ $-code_e0002
key_e0002: db "diagnostic.limit.exceeded"
key_e0002_len equ $-key_e0002
code_w0001: db "NEBO-W0001"
code_w0001_len equ $-code_w0001
key_w0001: db "diagnostic.compatibility.warning"
key_w0001_len equ $-key_w0001
code_n0001: db "NEBO-N0001"
code_n0001_len equ $-code_n0001
key_n0001: db "diagnostic.context.note"
key_n0001_len equ $-key_n0001
code_h0001: db "NEBO-H0001"
code_h0001_len equ $-code_h0001
key_h0001: db "diagnostic.action.help"
key_h0001_len equ $-key_h0001
code_ice0001: db "NEBO-ICE-0001"
code_ice0001_len equ $-code_ice0001
key_ice0001: db "diagnostic.internal.invariant"
key_ice0001_len equ $-key_ice0001

align 8
registry:
 dq code_e0001,code_e0001_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key_e0001,key_e0001_len,NEBOC_DIAGNOSTIC_SCHEMA_V1
 dq code_e0002,code_e0002_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key_e0002,key_e0002_len,NEBOC_DIAGNOSTIC_SCHEMA_V1
 dq code_w0001,code_w0001_len,NEBOC_DIAGNOSTIC_SEVERITY_WARNING,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key_w0001,key_w0001_len,NEBOC_DIAGNOSTIC_SCHEMA_V1
 dq code_n0001,code_n0001_len,NEBOC_DIAGNOSTIC_SEVERITY_NOTE,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key_n0001,key_n0001_len,NEBOC_DIAGNOSTIC_SCHEMA_V1
 dq code_h0001,code_h0001_len,NEBOC_DIAGNOSTIC_SEVERITY_HELP,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key_h0001,key_h0001_len,NEBOC_DIAGNOSTIC_SCHEMA_V1
 dq code_ice0001,code_ice0001_len,NEBOC_DIAGNOSTIC_SEVERITY_BUG,NEBOC_DIAGNOSTIC_CATEGORY_INTERNAL,NEBOC_DIAGNOSTIC_PHASE_INTERNAL,key_ice0001,key_ice0001_len,NEBOC_DIAGNOSTIC_SCHEMA_V1

section .text
; code_registry_lookup(code*, code_len, out_entry*)
NEBOC_ABI_FUNCTION neboc_diagnostic_code_registry_lookup
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 lea rbx,[rel registry]
 xor r15d,r15d
.entry:
 cmp r15d,NEBOC_DIAGNOSTIC_CODE_COUNT
 jae .not_found
 cmp [rbx+NEBOC_DIAGNOSTIC_CODE_ENTRY_CODE_LENGTH_OFFSET],r13
 jne .next
 mov rdi,[rbx+NEBOC_DIAGNOSTIC_CODE_ENTRY_CODE_OFFSET]
 xor ecx,ecx
.compare:
 cmp rcx,r13
 jae .found
 mov al,[r12+rcx]
 cmp al,[rdi+rcx]
 jne .next
 inc rcx
 jmp .compare
.next:
 add rbx,NEBOC_DIAGNOSTIC_CODE_ENTRY_SIZE
 inc r15d
 jmp .entry
.found:
 mov rdi,r14
 mov rsi,rbx
 mov ecx,NEBOC_DIAGNOSTIC_CODE_ENTRY_SIZE/8
 rep movsq
 xor eax,eax
 jmp .finish
.not_found:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.finish:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; code_registry_count()
NEBOC_ABI_FUNCTION neboc_diagnostic_code_registry_count
 mov eax,NEBOC_DIAGNOSTIC_CODE_COUNT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
