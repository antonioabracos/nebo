; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY deterministic failure/resource accounting.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

%define NEBOC_LEDGER_OPERAND_EVALS 0
%define NEBOC_LEDGER_TARGET_EVALS 8
%define NEBOC_LEDGER_STORE_COUNT 16
%define NEBOC_LEDGER_RESOURCES_ACQUIRED 24
%define NEBOC_LEDGER_RESOURCES_RELEASED 32
%define NEBOC_LEDGER_FAILURE_STATUS 40
%define NEBOC_LEDGER_DIAGNOSTIC 48
%define NEBOC_LEDGER_FLAGS 56
%define NEBOC_LEDGER_SIZE 64
%define NEBOC_LEDGER_FLAG_SEALED 1

section .text
NEBOC_ABI_FUNCTION neboc_failure_ledger_init
 test rdi,rdi
 jz .invalid
 xor eax,eax
 mov ecx,NEBOC_LEDGER_SIZE/8
 rep stosq
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; failure_ledger_seal(ledger*, operation_status, diagnostic)
NEBOC_ABI_FUNCTION neboc_failure_ledger_seal
 test rdi,rdi
 jz .seal_invalid
 test qword [rdi+NEBOC_LEDGER_FLAGS],NEBOC_LEDGER_FLAG_SEALED
 jnz .seal_source
 mov [rdi+NEBOC_LEDGER_FAILURE_STATUS],rsi
 mov [rdi+NEBOC_LEDGER_DIAGNOSTIC],rdx
 or qword [rdi+NEBOC_LEDGER_FLAGS],NEBOC_LEDGER_FLAG_SEALED
 test rsi,rsi
 jz .seal_ok
 ; A failed operation cannot have committed a target store.
 cmp qword [rdi+NEBOC_LEDGER_STORE_COUNT],0
 jne .seal_source
.seal_ok:
 xor eax,eax
 ret
.seal_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.seal_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; failure_ledger_validate(ledger*) checks exactly-once and leak freedom.
NEBOC_ABI_FUNCTION neboc_failure_ledger_validate
 test rdi,rdi
 jz .validate_invalid
 test qword [rdi+NEBOC_LEDGER_FLAGS],NEBOC_LEDGER_FLAG_SEALED
 jz .validate_source
 cmp qword [rdi+NEBOC_LEDGER_OPERAND_EVALS],2
 ja .validate_source
 cmp qword [rdi+NEBOC_LEDGER_TARGET_EVALS],1
 ja .validate_source
 cmp qword [rdi+NEBOC_LEDGER_STORE_COUNT],1
 ja .validate_source
 mov rax,[rdi+NEBOC_LEDGER_RESOURCES_ACQUIRED]
 cmp rax,[rdi+NEBOC_LEDGER_RESOURCES_RELEASED]
 jne .validate_source
 cmp qword [rdi+NEBOC_LEDGER_FAILURE_STATUS],0
 je .validate_ok
 cmp qword [rdi+NEBOC_LEDGER_STORE_COUNT],0
 jne .validate_source
.validate_ok:
 xor eax,eax
 ret
.validate_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.validate_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
