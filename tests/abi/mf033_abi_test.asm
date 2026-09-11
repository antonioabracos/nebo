; Nebo Assembly — MF033 ABI Adapter and function lowering scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/data-layout/data_layout.inc"
%include "compiler/target/target_context.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"
%include "compiler/codegen/abi/diagnostics/abi_diagnostics.inc"

extern neboc_data_layout_init_first_target
extern neboc_target_context_init
extern neboc_assembly_writer_init
extern neboc_arch_backend_init
extern neboc_arch_backend_begin_module
extern neboc_arch_backend_begin_function
extern neboc_arch_backend_end_module
extern neboc_abi_adapter_init
extern neboc_abi_adapter_validate
extern neboc_abi_signature_init
extern neboc_abi_signature_validate
extern neboc_abi_adapter_begin_function
extern neboc_abi_adapter_emit_parameter_copy
extern neboc_abi_adapter_emit_call
extern neboc_abi_adapter_emit_return
extern neboc_abi_adapter_emit_runtime_thunk
extern neboc_abi_diagnostic_name
extern neboc_host_process_exit

global _start

%define OUTPUT_CAPACITY 16384

section .rodata
expected_golden: incbin "tests/abi/goldens/006-function-call.asm"
expected_golden_end:
expected_runtime: incbin "tests/abi/goldens/runtime-thunk.asm"
expected_runtime_end:
needle_push_rbp: db '    push rbp',10
needle_mov_rbp: db '    mov rbp, rsp',10
needle_pop_rbp: db '    pop rbp',10
needle_rbx: db 'rbx'
needle_r12: db 'r12'
needle_call_stack: db '    mov rax, 88',10,'    push rax',10,'    mov rax, 77',10,'    push rax',10
needle_call_regs: db '    mov rdi, 11',10,'    mov rsi, 22',10,'    mov rdx, 33',10,'    mov rcx, 44',10,'    mov r8, 55',10,'    mov r9, 66',10
needle_call: db '    call nebo_fn_2',10,'    add rsp, 16',10
needle_scalar: db '    mov rax, -17',10
needle_status: db '    mov eax, 7',10
needle_thunk: db 'global nebo_runtime_thunk_3',10,'nebo_runtime_thunk_3:',10
needle_runtime_contract: db '    jmp nebo_runtime_contract_3',10
expected_runtime_mismatch: db 'runtime-abi-version-mismatch'
arguments: dq 11,22,33,44,55,66,77,88

section .bss align=16
layout: resb NEBOC_DATA_LAYOUT_SIZE
context: resb NEBOC_TARGET_CONTEXT_SIZE
target_request: resb NEBOC_TARGET_REQUEST_SIZE
writer: resb NEBOC_ASSEMBLY_WRITER_SIZE
backend: resb NEBOC_ARCH_BACKEND_SIZE
adapter: resb NEBOC_ABI_ADAPTER_SIZE
abi_request: resb NEBOC_ABI_REQUEST_SIZE
signature_a: resb NEBOC_ABI_SIGNATURE_SIZE
signature_b: resb NEBOC_ABI_SIGNATURE_SIZE
output: resb OUTPUT_CAPACITY
diag_ptr: resq 1
diag_len: resq 1

section .text
_start:
 mov rax,[rsp]
 cmp rax,1
 je test_pass
 cmp rax,2
 jne test_usage
 mov rax,[rsp+16]
 cmp byte [rax+1],0
 jne test_usage
 movzx eax,byte [rax]
 sub eax,'0'
 cmp eax,1
 jb test_usage
 cmp eax,9
 ja test_usage
 cmp eax,1
 je scenario_1
 cmp eax,2
 je scenario_2
 cmp eax,3
 je scenario_3
 cmp eax,4
 je scenario_4
 cmp eax,5
 je scenario_5
 cmp eax,6
 je scenario_6
 cmp eax,7
 je scenario_7
 cmp eax,8
 je scenario_8
 jmp scenario_9

; NEBO-ABI-CONTRACT-001 — physical internal ABI version and masks match DG-005.
scenario_1:
 call reset_all
 call init_codegen
 test eax,eax
 jnz test_fail
 cmp qword [rel adapter+NEBOC_ABI_ADAPTER_INTERNAL_VERSION_OFFSET],NEBOC_INTERNAL_ABI_VERSION
 jne test_fail
 cmp qword [rel adapter+NEBOC_ABI_ADAPTER_RUNTIME_VERSION_OFFSET],NEBOC_RUNTIME_ABI_VERSION_V0
 jne test_fail
 cmp qword [rel adapter+NEBOC_ABI_ADAPTER_STACK_ALIGNMENT_OFFSET],16
 jne test_fail
 cmp qword [rel adapter+NEBOC_ABI_ADAPTER_CALLER_SAVED_MASK_OFFSET],NEBOC_ABI_CALLER_SAVED_MASK_V0
 jne test_fail
 cmp qword [rel adapter+NEBOC_ABI_ADAPTER_CALLEE_SAVED_MASK_OFFSET],NEBOC_ABI_CALLEE_SAVED_MASK_V0
 jne test_fail
 lea rdi,[rel adapter]
 call neboc_abi_adapter_validate
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-ABI-CONTRACT-002 — register/stack parameters and frame align to 16.
scenario_2:
 call reset_all
 lea rdi,[rel signature_a]
 mov esi,1
 mov edx,8
 mov ecx,3
 mov r8d,NEBOC_ABI_RETURN_SCALAR
 mov r9d,1
 call neboc_abi_signature_init
 test eax,eax
 jnz test_fail
 cmp qword [rel signature_a+NEBOC_ABI_SIGNATURE_REGISTER_PARAMETER_COUNT_OFFSET],6
 jne test_fail
 cmp qword [rel signature_a+NEBOC_ABI_SIGNATURE_STACK_PARAMETER_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel signature_a+NEBOC_ABI_SIGNATURE_FRAME_SIZE_OFFSET],32
 jne test_fail
 test qword [rel signature_a+NEBOC_ABI_SIGNATURE_FRAME_SIZE_OFFSET],15
 jnz test_fail
 cmp qword [rel signature_a+NEBOC_ABI_SIGNATURE_HASH_OFFSET],0
 je test_fail
 lea rdi,[rel signature_a]
 call neboc_abi_signature_validate
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-ABI-CONTRACT-003 — generated function preserves callee-saved registers.
scenario_3:
 call reset_all
 call init_codegen
 test eax,eax
 jnz test_fail
 lea rdi,[rel signature_a]
 mov esi,1
 xor edx,edx
 xor ecx,ecx
 mov r8d,NEBOC_ABI_RETURN_VOID
 xor r9d,r9d
 call neboc_abi_signature_init
 test eax,eax
 jnz test_fail
 lea rsi,[rel signature_a]
 call begin_function
 test eax,eax
 jnz test_fail
 lea rdi,[rel adapter]
 xor esi,esi
 call neboc_abi_adapter_emit_return
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_push_rbp]
 mov ecx,13
 call writer_contains
 test eax,eax
 jz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_mov_rbp]
 mov ecx,17
 call writer_contains
 test eax,eax
 jz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_pop_rbp]
 mov ecx,12
 call writer_contains
 test eax,eax
 jz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_rbx]
 mov ecx,3
 call writer_contains
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_r12]
 mov ecx,3
 call writer_contains
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-ABI-CONTRACT-004 — arguments use six registers then stack right-to-left.
scenario_4:
 call reset_all
 call build_call_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_call_stack]
 mov ecx,58
 call writer_contains
 test eax,eax
 jz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_call_regs]
 mov ecx,94
 call writer_contains
 test eax,eax
 jz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_call]
 mov ecx,35
 call writer_contains
 test eax,eax
 jz test_fail
 jmp test_pass

; NEBO-ABI-CONTRACT-005 — scalar and Status returns use RAX/EAX.
scenario_5:
 call reset_all
 call init_codegen
 test eax,eax
 jnz test_fail
 lea rdi,[rel signature_a]
 mov esi,1
 xor edx,edx
 xor ecx,ecx
 mov r8d,NEBOC_ABI_RETURN_SCALAR
 xor r9d,r9d
 call neboc_abi_signature_init
 test eax,eax
 jnz test_fail
 lea rsi,[rel signature_a]
 call begin_function
 test eax,eax
 jnz test_fail
 lea rdi,[rel adapter]
 mov rsi,-17
 call neboc_abi_adapter_emit_return
 test eax,eax
 jnz test_fail
 lea rdi,[rel signature_b]
 mov esi,2
 xor edx,edx
 xor ecx,ecx
 mov r8d,NEBOC_ABI_RETURN_KIND_STATUS
 xor r9d,r9d
 call neboc_abi_signature_init
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend]
 mov esi,2
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz test_fail
 lea rdi,[rel adapter]
 lea rsi,[rel signature_b]
 call neboc_abi_adapter_begin_function
 test eax,eax
 jnz test_fail
 lea rdi,[rel adapter]
 mov esi,7
 call neboc_abi_adapter_emit_return
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_scalar]
 mov ecx,17
 call writer_contains
 test eax,eax
 jz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel needle_status]
 mov ecx,15
 call writer_contains
 test eax,eax
 jz test_fail
 jmp test_pass

; NEBO-ABI-CONTRACT-006 — runtime thunk translates through a version guard.
scenario_6:
 call reset_all
 call init_codegen
 test eax,eax
 jnz test_fail
 lea rdi,[rel adapter]
 mov esi,3
 mov edx,NEBOC_RUNTIME_ABI_VERSION_V0
 call neboc_abi_adapter_emit_runtime_thunk
 test eax,eax
 jnz test_fail
 cmp qword [rel adapter+NEBOC_ABI_ADAPTER_EMITTED_THUNKS_OFFSET],1
 jne test_fail
 lea rdi,[rel backend]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer]
 lea rsi,[rel expected_runtime]
 mov edx,expected_runtime_end-expected_runtime
 call compare_output
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-ABI-NEG-008 — runtime ABI version mismatch fails before emission.
scenario_7:
 call reset_all
 call init_codegen_base
 test eax,eax
 jnz test_fail
 mov qword [rel abi_request+NEBOC_ABI_REQUEST_RUNTIME_VERSION_OFFSET],1
 lea rdi,[rel adapter]
 lea rsi,[rel context]
 lea rdx,[rel backend]
 lea rcx,[rel abi_request]
 call neboc_abi_adapter_init
 cmp eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jne test_fail
 cmp qword [rel abi_request+NEBOC_ABI_REQUEST_ERROR_CODE_OFFSET],NEBOC_ABI_ERROR_RUNTIME_VERSION_MISMATCH
 jne test_fail
 cmp qword [rel adapter+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_EMPTY
 jne test_fail
 mov edi,NEBOC_ABI_ERROR_RUNTIME_VERSION_MISMATCH
 lea rsi,[rel expected_runtime_mismatch]
 mov edx,NEBOC_ABI_DIAG_RUNTIME_VERSION_LENGTH
 call expect_diag
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-CODEGEN-GOLDEN-006 — canonical function call Assembly.
scenario_8:
 call reset_all
 call build_call_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer]
 lea rsi,[rel expected_golden]
 mov edx,expected_golden_end-expected_golden
 call compare_output
 test eax,eax
 jnz test_fail
 jmp test_pass

; Infrastructure — signature hash tampering is rejected without output mutation.
scenario_9:
 call reset_all
 call init_codegen
 test eax,eax
 jnz test_fail
 lea rdi,[rel signature_a]
 mov esi,1
 mov edx,2
 mov ecx,2
 mov r8d,NEBOC_ABI_RETURN_SCALAR
 xor r9d,r9d
 call neboc_abi_signature_init
 test eax,eax
 jnz test_fail
 xor qword [rel signature_a+NEBOC_ABI_SIGNATURE_HASH_OFFSET],1
 lea rdi,[rel signature_a]
 call neboc_abi_signature_validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 cmp qword [rel writer+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],20
 jne test_fail
 jmp test_pass

; Initializes target, writer, backend and starts module 1, but not adapter.
init_codegen_base:
 push rbx
 lea rdi,[rel layout]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz .done
 lea rdi,[rel target_request]
 call fill_target_request
 lea rdi,[rel context]
 lea rsi,[rel layout]
 lea rdx,[rel target_request]
 call neboc_target_context_init
 test eax,eax
 jnz .done
 lea rdi,[rel writer]
 lea rsi,[rel output]
 mov edx,OUTPUT_CAPACITY
 call neboc_assembly_writer_init
 test eax,eax
 jnz .done
 lea rdi,[rel backend]
 lea rsi,[rel context]
 xor edx,edx
 lea rcx,[rel writer]
 call neboc_arch_backend_init
 test eax,eax
 jnz .done
 lea rdi,[rel backend]
 mov esi,1
 xor edx,edx
 call neboc_arch_backend_begin_module
 test eax,eax
 jnz .done
 lea rdi,[rel abi_request]
 call fill_abi_request
 xor eax,eax
.done:
 pop rbx
 ret

init_codegen:
 push rbx
 call init_codegen_base
 test eax,eax
 jnz .done
 lea rdi,[rel adapter]
 lea rsi,[rel context]
 lea rdx,[rel backend]
 lea rcx,[rel abi_request]
 call neboc_abi_adapter_init
.done:
 pop rbx
 ret

; RSI = signature pointer; uses its function id.
begin_function:
 push rbx
 mov rbx,rsi
 lea rdi,[rel backend]
 mov rsi,[rbx+NEBOC_ABI_SIGNATURE_FUNCTION_ID_OFFSET]
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .done
 lea rdi,[rel adapter]
 mov rsi,rbx
 call neboc_abi_adapter_begin_function
.done:
 pop rbx
 ret

build_call_module:
 push rbx
 call init_codegen
 test eax,eax
 jnz .done
 lea rdi,[rel signature_a]
 mov esi,1
 mov edx,8
 mov ecx,2
 mov r8d,NEBOC_ABI_RETURN_SCALAR
 mov r9d,1
 call neboc_abi_signature_init
 test eax,eax
 jnz .done
 lea rsi,[rel signature_a]
 call begin_function
 test eax,eax
 jnz .done
 lea rdi,[rel adapter]
 xor esi,esi
 mov edx,1
 call neboc_abi_adapter_emit_parameter_copy
 test eax,eax
 jnz .done
 lea rdi,[rel adapter]
 mov esi,6
 mov edx,2
 call neboc_abi_adapter_emit_parameter_copy
 test eax,eax
 jnz .done
 lea rdi,[rel adapter]
 mov esi,2
 lea rdx,[rel arguments]
 mov ecx,8
 call neboc_abi_adapter_emit_call
 test eax,eax
 jnz .done
 lea rdi,[rel adapter]
 mov esi,99
 call neboc_abi_adapter_emit_return
 test eax,eax
 jnz .done
 lea rdi,[rel signature_b]
 mov esi,2
 xor edx,edx
 xor ecx,ecx
 mov r8d,NEBOC_ABI_RETURN_SCALAR
 xor r9d,r9d
 call neboc_abi_signature_init
 test eax,eax
 jnz .done
 lea rdi,[rel backend]
 mov esi,2
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .done
 lea rdi,[rel adapter]
 lea rsi,[rel signature_b]
 call neboc_abi_adapter_begin_function
 test eax,eax
 jnz .done
 lea rdi,[rel adapter]
 mov esi,44
 call neboc_abi_adapter_emit_return
 test eax,eax
 jnz .done
 lea rdi,[rel backend]
 call neboc_arch_backend_end_module
.done:
 pop rbx
 ret

fill_target_request:
 push rdi
 mov ecx,NEBOC_TARGET_REQUEST_QWORDS
 call zero_region
 pop rdi
 mov qword [rdi+NEBOC_TARGET_REQUEST_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 mov qword [rdi+NEBOC_TARGET_REQUEST_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 mov qword [rdi+NEBOC_TARGET_REQUEST_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 mov qword [rdi+NEBOC_TARGET_REQUEST_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 mov qword [rdi+NEBOC_TARGET_REQUEST_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 mov qword [rdi+NEBOC_TARGET_REQUEST_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_RUNTIME_NATIVE_LINUX_V0
 mov qword [rdi+NEBOC_TARGET_REQUEST_CONSOLE_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_CONSOLE_RUNTIME_CORE_V0
 mov qword [rdi+NEBOC_TARGET_REQUEST_TOOLCHAIN_PROFILE_OFFSET],NEBOC_TARGET_TOOLCHAIN_NASM_GNU_LD_NINJA_V0
 mov qword [rdi+NEBOC_TARGET_REQUEST_FEATURE_FLAGS_OFFSET],NEBOC_TARGET_FEATURES_V0
 mov qword [rdi+NEBOC_TARGET_REQUEST_COMPONENT_MASK_OFFSET],NEBOC_TARGET_COMPONENT_REQUIRED_MASK
 ret

fill_abi_request:
 push rdi
 mov ecx,NEBOC_ABI_REQUEST_QWORDS
 call zero_region
 pop rdi
 mov qword [rdi+NEBOC_ABI_REQUEST_INTERNAL_VERSION_OFFSET],NEBOC_INTERNAL_ABI_VERSION
 mov qword [rdi+NEBOC_ABI_REQUEST_RUNTIME_VERSION_OFFSET],NEBOC_RUNTIME_ABI_VERSION_V0
 mov qword [rdi+NEBOC_ABI_REQUEST_TARGET_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 mov qword [rdi+NEBOC_ABI_REQUEST_STACK_ALIGNMENT_OFFSET],NEBOC_ABI_STACK_ALIGNMENT
 mov qword [rdi+NEBOC_ABI_REQUEST_FLAGS_OFFSET],NEBOC_ABI_REQUEST_REQUIRED_FLAGS
 ret

writer_contains:
 mov rsi,[rdi+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov rdi,[rdi+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 jmp contains_bytes

compare_output:
 cmp qword [rdi+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_SEALED
 jne .bad
 cmp [rdi+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rdx
 jne .bad
 mov rcx,rdx
 mov rdi,[rdi+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 xchg rdi,rsi
 repe cmpsb
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

expect_diag:
 push rbx
 push r12
 push r13
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov edi,ebx
 lea rsi,[rel diag_ptr]
 lea rdx,[rel diag_len]
 call neboc_abi_diagnostic_name
 test eax,eax
 jnz .bad
 cmp [rel diag_len],r13
 jne .bad
 mov rdi,[rel diag_ptr]
 mov rsi,r12
 mov rcx,r13
 repe cmpsb
 jne .bad
 xor eax,eax
 pop r13
 pop r12
 pop rbx
 ret
.bad:
 mov eax,1
 pop r13
 pop r12
 pop rbx
 ret

contains_bytes:
 test rcx,rcx
 jz .found
 cmp rsi,rcx
 jb .not_found
 xor r8d,r8d
.outer:
 mov rax,rsi
 sub rax,rcx
 cmp r8,rax
 ja .not_found
 xor r9d,r9d
.inner:
 cmp r9,rcx
 jae .found
 mov r10,r8
 add r10,r9
 mov al,[rdi+r10]
 cmp al,[rdx+r9]
 jne .next
 inc r9
 jmp .inner
.next:
 inc r8
 jmp .outer
.found:
 mov eax,1
 ret
.not_found:
 xor eax,eax
 ret

reset_all:
 sub rsp,8
 lea rdi,[rel layout]
 mov ecx,NEBOC_DATA_LAYOUT_QWORDS
 call zero_region
 lea rdi,[rel context]
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
 call zero_region
 lea rdi,[rel target_request]
 mov ecx,NEBOC_TARGET_REQUEST_QWORDS
 call zero_region
 lea rdi,[rel writer]
 mov ecx,NEBOC_ASSEMBLY_WRITER_QWORDS
 call zero_region
 lea rdi,[rel backend]
 mov ecx,NEBOC_ARCH_BACKEND_QWORDS
 call zero_region
 lea rdi,[rel adapter]
 mov ecx,NEBOC_ABI_ADAPTER_QWORDS
 call zero_region
 lea rdi,[rel abi_request]
 mov ecx,NEBOC_ABI_REQUEST_QWORDS
 call zero_region
 lea rdi,[rel signature_a]
 mov ecx,NEBOC_ABI_SIGNATURE_QWORDS
 call zero_region
 lea rdi,[rel signature_b]
 mov ecx,NEBOC_ABI_SIGNATURE_QWORDS
 call zero_region
 lea rdi,[rel output]
 mov ecx,OUTPUT_CAPACITY/8
 call zero_region
 add rsp,8
 ret

zero_region:
 xor eax,eax
 rep stosq
 ret

test_usage:
 mov edi,2
 jmp neboc_host_process_exit
test_fail:
 mov edi,1
 jmp neboc_host_process_exit
test_pass:
 xor edi,edi
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
