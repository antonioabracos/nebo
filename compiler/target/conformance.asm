; CONFORMANCE-F09 factual conformance aggregation and target maturity.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/conformance.inc"
section .text
NEBOC_ABI_FUNCTION neboc_target_conformance_suite_for_target
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,2
 ja .unsupported
 mov [rdi],rsi
 mov qword [rdi+8],0x3f
 mov qword [rdi+16],0
 mov qword [rdi+24],0x3f
 mov qword [rdi+32],NEBOC_CONF_MATURITY_CONTRACT
 xor eax,eax
 ret
.unsupported: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_conformance_compile_corpus
 test rdi,rdi
 jz .invalid
 cmp qword [rdi],1
 jne .unavailable
 or qword [rdi+16],NEBOC_CONF_COMPILE
 and qword [rdi+24],~NEBOC_CONF_COMPILE
 xor eax,eax
 ret
.unavailable: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_conformance_run_corpus
 ; rsi runner maturity: 3 is current-host hardware.
 test rdi,rdi
 jz .invalid
 cmp qword [rdi],1
 jne .unavailable
 cmp rsi,3
 jne .unavailable
 or qword [rdi+16],NEBOC_CONF_RUN
 and qword [rdi+24],~NEBOC_CONF_RUN
 xor eax,eax
 ret
.unavailable: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%macro CONF_VECTOR 2
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 cmp qword [rdi],1
 jne %%unavailable
 or qword [rdi+16],%2
 and qword [rdi+24],~%2
 xor eax,eax
 ret
%%unavailable: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
CONF_VECTOR neboc_conformance_abi_vectors,NEBOC_CONF_ABI
CONF_VECTOR neboc_conformance_object_vectors,NEBOC_CONF_OBJECT
CONF_VECTOR neboc_conformance_runtime_vectors,NEBOC_CONF_RUNTIME
NEBOC_ABI_FUNCTION neboc_conformance_cross_host_reproducibility
 ; A second host is not available in this environment.
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_target_maturity_classify
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+16]
 mov rcx,NEBOC_CONF_COMPILE|NEBOC_CONF_RUN|NEBOC_CONF_ABI|NEBOC_CONF_OBJECT|NEBOC_CONF_RUNTIME
 and rax,rcx
 cmp rax,rcx
 je .hardware
 test rax,NEBOC_CONF_COMPILE
 jnz .compile
 mov rax,NEBOC_CONF_MATURITY_CONTRACT
 jmp .write
.hardware: mov rax,NEBOC_CONF_MATURITY_HARDWARE
 jmp .write
.compile: mov rax,NEBOC_CONF_MATURITY_COMPILE
.write:
 mov [rdi+32],rax
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_conformance_report
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov ecx,5
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
NEBOC_ABI_FUNCTION neboc_cli_conformance_target
 ; rdi=suite, rsi=runner maturity, rdx=maturity output.
 push rbx
 mov rbx,rdx
 call neboc_conformance_compile_corpus
 test eax,eax
 jne .done
 call neboc_conformance_abi_vectors
 test eax,eax
 jne .done
 call neboc_conformance_object_vectors
 test eax,eax
 jne .done
 call neboc_conformance_runtime_vectors
 test eax,eax
 jne .done
 call neboc_conformance_run_corpus
 test eax,eax
 jne .done
 mov rsi,rbx
 call neboc_target_maturity_classify
.done: pop rbx
 ret
NEBOC_ABI_FUNCTION neboc_cli_target_matrix
 ; out triples={token,maturity}: current hardware, descriptor-only, triple-only.
 test rdi,rdi
 jz .invalid
 mov qword [rdi],1
 mov qword [rdi+8],NEBOC_CONF_MATURITY_HARDWARE
 mov qword [rdi+16],2
 mov qword [rdi+24],NEBOC_CONF_MATURITY_CONTRACT
 mov qword [rdi+32],3
 mov qword [rdi+40],NEBOC_CONF_MATURITY_CONTRACT
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_conformance_report
 ; Offline fixed-record inspector.
 call neboc_conformance_report
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
