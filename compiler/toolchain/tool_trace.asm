; TOOL-TRACE-F01 bounded local trace records; argument values are digests/tokens only.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/toolchain/tool_trace.inc"
section .text
NEBOC_ABI_FUNCTION neboc_toolchain_trace_start
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .invalid
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov qword [rdi+16],0
 mov qword [rdi+24],0
 mov qword [rdi+32],0
 mov qword [rdi+40],0
 mov qword [rdi+48],0
 mov qword [rdi+56],0
 mov qword [rdi+64],0x3f
 mov qword [rdi+72],0
 mov qword [rdi+80],NEBOC_TOOLCHAIN_UNKNOWN
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_record_process
 ; rsi=tool token, rdx=argv digest, rcx=parent token. No raw argv.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,4
 ja .source
 cmp qword [rdi+16],NEBOC_TRACE_MAX_EVENTS
 jae .limit
 inc qword [rdi+16]
 mov rax,1
 mov rcx,rsi
 dec rcx
 shl rax,cl
 or [rdi+48],rax
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_record_file
 ; rsi=path digest token, rdx=mode, rcx=classification.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 test rcx,rcx
 jz .source
 cmp qword [rdi+24],NEBOC_TRACE_MAX_EVENTS
 jae .limit
 inc qword [rdi+24]
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_record_environment
 ; rsi=name token, rdx=classification used/ignored/redacted; never a value.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 cmp rdx,3
 ja .source
 cmp qword [rdi+32],NEBOC_TRACE_MAX_EVENTS
 jae .limit
 inc qword [rdi+32]
 cmp rdx,3
 jne .ok
 inc qword [rdi+72]
.ok: xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_record_network
 ; Hermetic policy always records and blocks the attempt.
 test rdi,rdi
 jz .invalid
 inc qword [rdi+40]
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_external_tools
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+48]
 mov [rsi],rax
 popcnt rax,rax
 mov [rsi+8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_external_libraries
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+56]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_classify_maturity
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+48]
 test rax,NEBOC_TOOL_NASM
 jnz .external
 test rax,NEBOC_TOOL_LD
 jnz .linker
 test rax,rax
 jnz .unknown
 mov rax,NEBOC_TOOLCHAIN_FULLY_INTERNAL
 jmp .write
.external: mov rax,NEBOC_TOOLCHAIN_EXTERNAL_ASSEMBLER_LINKER
 jmp .write
.linker: mov rax,NEBOC_TOOLCHAIN_INTERNAL_CODEGEN_EXTERNAL_LINKER
 jmp .write
.unknown: mov rax,NEBOC_TOOLCHAIN_UNKNOWN
.write:
 mov [rdi+80],rax
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_reproducibility_inputs
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+64]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trace_redact
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 inc qword [rdi+72]
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_build_trace_tools
 ; rdi=trace rsi=11-qword local structured output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov ecx,11
.copy:
 mov rax,[rdi]
 mov [rsi],rax
 add rdi,8
 add rsi,8
 loop .copy
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_toolchain_report
 ; Same offline structured report path.
 call neboc_cli_build_trace_tools
 ret
NEBOC_ABI_FUNCTION neboc_cli_self_contained_audit
 ; Fails with first external tool bit while the current pipeline is external.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+48]
 test rax,rax
 jz .internal
 bsf rax,rax
 inc rax
 mov [rsi],rax
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.internal:
 mov qword [rsi],0
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
