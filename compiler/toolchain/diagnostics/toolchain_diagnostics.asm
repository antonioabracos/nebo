; Stable MF034 toolchain diagnostics
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/toolchain/toolchain_descriptor.inc"
%include "compiler/toolchain/diagnostics/toolchain_diagnostics.inc"
section .rodata
bad_request: db 'invalid-toolchain-request'
target: db 'toolchain-target-mismatch'
assembler: db 'toolchain-assembler-missing'
linker: db 'toolchain-linker-missing'
version: db 'toolchain-version-incompatible'
path: db 'toolchain-path-invalid'
runner: db 'toolchain-runner-failed'
process: db 'toolchain-process-failed'
section .text
NEBOC_ABI_FUNCTION neboc_toolchain_diagnostic_name
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rsi],0
 mov qword [rdx],0
 cmp edi,NEBOC_TOOLCHAIN_ERROR_BAD_REQUEST
 je .a
 cmp edi,NEBOC_TOOLCHAIN_ERROR_TARGET_MISMATCH
 je .b
 cmp edi,NEBOC_TOOLCHAIN_ERROR_ASSEMBLER_MISSING
 je .c
 cmp edi,NEBOC_TOOLCHAIN_ERROR_LINKER_MISSING
 je .d
 cmp edi,NEBOC_TOOLCHAIN_ERROR_VERSION_INCOMPATIBLE
 je .e
 cmp edi,NEBOC_TOOLCHAIN_ERROR_PATH_INVALID
 je .f
 cmp edi,NEBOC_TOOLCHAIN_ERROR_RUNNER_FAILED
 je .g
 cmp edi,NEBOC_TOOLCHAIN_ERROR_PROCESS_FAILED
 je .h
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.a: lea rax,[rel bad_request]
 mov ecx,NEBOC_TOOLCHAIN_DIAG_BAD_REQUEST_LENGTH
 jmp .store
.b: lea rax,[rel target]
 mov ecx,NEBOC_TOOLCHAIN_DIAG_TARGET_LENGTH
 jmp .store
.c: lea rax,[rel assembler]
 mov ecx,NEBOC_TOOLCHAIN_DIAG_ASSEMBLER_LENGTH
 jmp .store
.d: lea rax,[rel linker]
 mov ecx,NEBOC_TOOLCHAIN_DIAG_LINKER_LENGTH
 jmp .store
.e: lea rax,[rel version]
 mov ecx,NEBOC_TOOLCHAIN_DIAG_VERSION_LENGTH
 jmp .store
.f: lea rax,[rel path]
 mov ecx,NEBOC_TOOLCHAIN_DIAG_PATH_LENGTH
 jmp .store
.g: lea rax,[rel runner]
 mov ecx,NEBOC_TOOLCHAIN_DIAG_RUNNER_LENGTH
 jmp .store
.h: lea rax,[rel process]
 mov ecx,NEBOC_TOOLCHAIN_DIAG_PROCESS_LENGTH
.store:
 mov [rsi],rax
 mov [rdx],rcx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
section .note.GNU-stack noalloc noexec nowrite progbits
