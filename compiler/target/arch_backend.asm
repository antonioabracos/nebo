; ARCH-BACKEND-F03 bounded x86_64 System V architecture backend and ABI facts.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/target_registry.inc"
%include "compiler/target/arch_backend.inc"

section .text
backend_validate:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_BACKEND_ARCH_OFFSET],NEBOC_BACKEND_ARCH_X86_64
 jne .unsupported
 cmp qword [rdi+NEBOC_BACKEND_CALLING_OFFSET],NEBOC_BACKEND_ABI_SYSTEMV
 jne .unsupported
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arch_backend_new
 ; rdi=backend, rsi=TargetDescriptor. Only factual x86_64 System V ELF is active.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_TARGET_TRIPLE_OFFSET],NEBOC_BACKEND_ARCH_X86_64
 jne .unsupported
 cmp qword [rsi+NEBOC_TARGET_POINTER_OFFSET],64
 jne .unsupported
 cmp qword [rsi+NEBOC_TARGET_ALIGNMENT_OFFSET],NEBOC_BACKEND_STACK_ALIGNMENT
 jne .unsupported
 cmp qword [rsi+NEBOC_TARGET_CALLING_OFFSET],NEBOC_BACKEND_ABI_SYSTEMV
 jne .unsupported
 mov [rdi+NEBOC_BACKEND_TARGET_OFFSET],rsi
 mov qword [rdi+NEBOC_BACKEND_ARCH_OFFSET],NEBOC_BACKEND_ARCH_X86_64
 mov rax,[rsi+NEBOC_TARGET_VERSION_OFFSET]
 mov [rdi+NEBOC_BACKEND_ABI_VERSION_OFFSET],rax
 mov rax,[rsi+NEBOC_TARGET_CPU_OFFSET]
 or rax,[rsi+NEBOC_TARGET_FEATURES_OFFSET]
 mov [rdi+NEBOC_BACKEND_FEATURES_OFFSET],rax
 mov qword [rdi+NEBOC_BACKEND_CALLING_OFFSET],NEBOC_BACKEND_ABI_SYSTEMV
 mov qword [rdi+NEBOC_BACKEND_STACK_ALIGN_OFFSET],NEBOC_BACKEND_STACK_ALIGNMENT
 mov qword [rdi+NEBOC_BACKEND_CODE_MODEL_OFFSET],NEBOC_BACKEND_CODE_SMALL_STATIC
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_backend_legalize
 ; rsi is a bounded LIR operation token: scalar add/load/call or gated vector add.
 call backend_validate
 test eax,eax
 jne .return
 test rdx,rdx
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,4
 ja .source
 cmp rsi,4
 jne .write
 test qword [rdi+NEBOC_BACKEND_FEATURES_OFFSET],NEBOC_BACKEND_FEATURE_VECTOR
 jz .source
.write:
 mov [rdx],rsi
 xor eax,eax
.return:
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_backend_select_instructions
 ; Returns an instruction-selection token, never instruction bytes.
 call backend_validate
 test eax,eax
 jne .return
 test rdx,rdx
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,4
 ja .source
 cmp rsi,4
 jne .selected
 test qword [rdi+NEBOC_BACKEND_FEATURES_OFFSET],NEBOC_BACKEND_FEATURE_VECTOR
 jz .source
.selected:
 mov rax,0x1000
 add rax,rsi
 mov [rdx],rax
 xor eax,eax
.return:
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_backend_register_file
 ; out={gpr_count, vector_count, integer_arg_mask, caller_saved_mask, callee_saved_mask}.
 call backend_validate
 test eax,eax
 jne .return
 test rsi,rsi
 jz .invalid
 mov qword [rsi],16
 mov qword [rsi+8],16
 mov qword [rsi+16],0x3f
 mov qword [rsi+24],0xfc7
 mov qword [rsi+32],0xf038
 xor eax,eax
.return:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_backend_stack_frame
 ; rsi=local bytes, rdx=spill bytes, rcx=out{frame,alignment,red_zone,probe_count}.
 call backend_validate
 test eax,eax
 jne .return
 test rcx,rcx
 jz .invalid
 mov rax,rsi
 add rax,rdx
 jc .limit
 add rax,NEBOC_BACKEND_STACK_ALIGNMENT-1
 jc .limit
 and rax,-NEBOC_BACKEND_STACK_ALIGNMENT
 mov [rcx],rax
 mov qword [rcx+8],NEBOC_BACKEND_STACK_ALIGNMENT
 mov qword [rcx+16],0
 xor edx,edx
 test rax,rax
 jz .probe_done
 add rax,NEBOC_BACKEND_STACK_PROBE_THRESHOLD-1
 mov r8,NEBOC_BACKEND_STACK_PROBE_THRESHOLD
 div r8
.probe_done:
 mov [rcx+24],rax
 xor eax,eax
.return:
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_backend_lower_call
 ; rsi=params, rdx=return words, rcx=variadic flag, r8=classification output.
 call backend_validate
 test eax,eax
 jne .return
 test r8,r8
 jz .invalid
 cmp rsi,NEBOC_BACKEND_MAX_PARAMETERS
 ja .limit
 cmp rdx,NEBOC_BACKEND_MAX_RETURN_WORDS
 ja .source
 test rcx,rcx
 jnz .source
 mov rax,rsi
 cmp rax,NEBOC_BACKEND_INTEGER_ARG_REGS
 jbe .regs_ready
 mov rax,NEBOC_BACKEND_INTEGER_ARG_REGS
.regs_ready:
 mov [r8],rax
 mov r9,rsi
 sub r9,rax
 mov [r8+8],r9
 mov [r8+16],rdx
 mov qword [r8+24],0
 xor eax,eax
.return:
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

NEBOC_ABI_FUNCTION neboc_backend_lower_atomic
 ; Bounded baseline tokens: load, store, compare-exchange.
 call backend_validate
 test eax,eax
 jne .return
 test rdx,rdx
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,3
 ja .source
 mov rax,0x3000
 add rax,rsi
 mov [rdx],rax
 xor eax,eax
.return:
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%macro BACKEND_FACT 2
NEBOC_ABI_FUNCTION %1
 call backend_validate
 test eax,eax
 jne %%return
 test rsi,rsi
 jz %%invalid
 mov qword [rsi],%2
 xor eax,eax
%%return:
 ret
%%invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
BACKEND_FACT neboc_backend_relocation_kinds,(NEBOC_BACKEND_RELOC_ABS64|NEBOC_BACKEND_RELOC_PC32)
BACKEND_FACT neboc_backend_code_model,NEBOC_BACKEND_CODE_SMALL_STATIC
BACKEND_FACT neboc_backend_disassembly_oracle,1
BACKEND_FACT neboc_backend_conformance_corpus,1

NEBOC_ABI_FUNCTION neboc_cli_emit_asm_target
 ; rdi=backend, rsi=LIR token, rdx=out{arch,instruction token}; no fallback to host.
 test rdx,rdx
 jz .invalid
 push rbx
 mov rbx,rdx
 sub rsp,16
 lea rdx,[rsp]
 call neboc_backend_legalize
 test eax,eax
 jne .done
 mov rsi,[rsp]
 lea rdx,[rbx+8]
 call neboc_backend_select_instructions
 test eax,eax
 jne .done
 mov rax,[rdi+NEBOC_BACKEND_ARCH_OFFSET]
 mov [rbx],rax
 xor eax,eax
.done:
 add rsp,16
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
