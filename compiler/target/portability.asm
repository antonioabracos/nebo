; PORTABILITY-F06 bounded target predicates and portability analysis; no source syntax.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/target_registry.inc"
%include "compiler/target/portability.inc"
section .text
%macro PREDICATE_NEW 2
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%source
 mov qword [rdi+NEBOC_PRED_KIND_OFFSET],%2
 mov [rdi+NEBOC_PRED_VALUE_OFFSET],rsi
 xor eax,eax
 ret
%%source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
PREDICATE_NEW neboc_target_predicate_architecture,NEBOC_PRED_ARCH
PREDICATE_NEW neboc_target_predicate_os,NEBOC_PRED_OS
PREDICATE_NEW neboc_target_predicate_has_capability,NEBOC_PRED_CAPABILITY
PREDICATE_NEW neboc_target_predicate_has_feature,NEBOC_PRED_FEATURE
NEBOC_ABI_FUNCTION neboc_target_selection_contract
 ; rdi=predicate rsi=target descriptor rdx=bool output. Contract evaluator only.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rdx],0
 mov rax,[rdi]
 mov rcx,[rdi+8]
 cmp rax,NEBOC_PRED_ARCH
 je .arch
 cmp rax,NEBOC_PRED_OS
 je .os
 cmp rax,NEBOC_PRED_CAPABILITY
 je .cap
 cmp rax,NEBOC_PRED_FEATURE
 je .feature
 jmp .source
.arch:
 cmp [rsi+NEBOC_TARGET_TRIPLE_OFFSET],rcx
 sete al
 jmp .write
.os:
 cmp [rsi+NEBOC_TARGET_SYSCALL_OFFSET],rcx
 sete al
 jmp .write
.cap:
 mov rax,[rsi+NEBOC_TARGET_CAPABILITIES_OFFSET]
 and rax,rcx
 cmp rax,rcx
 sete al
 jmp .write
.feature:
 mov rax,[rsi+NEBOC_TARGET_CPU_OFFSET]
 or rax,[rsi+NEBOC_TARGET_FEATURES_OFFSET]
 and rax,rcx
 cmp rax,rcx
 sete al
.write:
 movzx rax,al
 mov [rdx],rax
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_portable_api_require
 ; rdi=target rsi=required capability mask.
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_TARGET_CAPABILITIES_OFFSET]
 not rax
 and rax,rsi
 jnz .unsupported
 xor eax,eax
 ret
.unsupported: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_portable_api_fallback
 ; rdi=available rsi=primary rdx=alternative rcx=selection output (1/2).
 test rcx,rcx
 jz .invalid
 mov rax,rdi
 and rax,rsi
 cmp rax,rsi
 je .primary
 mov rax,rdi
 and rax,rdx
 cmp rax,rdx
 je .alternative
 mov qword [rcx],0
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.primary: mov qword [rcx],1
 xor eax,eax
 ret
.alternative: mov qword [rcx],2
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_portability_analyzer_analyze
 ; rdi=report rsi=array of capability masks rdx=count rcx=required.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_PORT_MAX_TARGETS
 ja .limit
 mov r8,-1
 xor r9d,r9d
 xor r10d,r10d
.loop:
 cmp r10,rdx
 jae .done
 mov rax,[rsi+r10*8]
 and r8,rax
 mov r11,rcx
 not rax
 and r11,rax
 or r9,r11
 inc r10
 jmp .loop
.done:
 mov [rdi+NEBOC_PORT_REPORT_COMMON_OFFSET],r8
 mov rax,r8
 not rax
 mov r11,-1
 and r11,rax
 mov [rdi+NEBOC_PORT_REPORT_SPECIFIC_OFFSET],r11
 mov [rdi+NEBOC_PORT_REPORT_MISSING_OFFSET],r9
 mov [rdi+NEBOC_PORT_REPORT_TARGETS_OFFSET],rdx
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_portability_report_common_subset
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_PORT_REPORT_COMMON_OFFSET]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_portability_report_target_specific_items
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_PORT_REPORT_SPECIFIC_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_PORT_REPORT_MISSING_OFFSET]
 mov [rsi+8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_portability_check
 ; Same bounded analyzer; no code generation and no source mutation.
 call neboc_portability_analyzer_analyze
 ret
NEBOC_ABI_FUNCTION neboc_cli_portability_report
 ; rdi=report rsi=4-qword output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov ecx,NEBOC_PORT_REPORT_SIZE/8
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
section .note.GNU-stack noalloc noexec nowrite progbits
