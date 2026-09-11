; Nebo Assembly — MF031 TargetContext/DataLayout scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/data-layout/data_layout.inc"
%include "compiler/target/target_context.inc"
%include "compiler/target/target_diagnostics.inc"

extern neboc_data_layout_init_first_target
extern neboc_data_layout_validate
extern neboc_target_context_init
extern neboc_target_context_validate
extern neboc_target_diagnostic_name
extern neboc_host_process_exit

global _start

section .rodata
expected_incomplete: db 'incomplete-target-tuple'

section .bss align=16
layout_a: resb NEBOC_DATA_LAYOUT_SIZE
layout_b: resb NEBOC_DATA_LAYOUT_SIZE
context_a: resb NEBOC_TARGET_CONTEXT_SIZE
context_b: resb NEBOC_TARGET_CONTEXT_SIZE
request: resb NEBOC_TARGET_REQUEST_SIZE
diag_ptr: resq 1
diag_len: resq 1

section .text
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rax,[rsp+16]
 cmp byte [rax+1],0
 jne test_usage
 movzx eax,byte [rax]
 cmp al,'A'
 je scenario_A
 cmp al,'B'
 je scenario_B
 cmp al,'C'
 je scenario_C
 sub eax,'0'
 cmp eax,1
 jb test_usage
 cmp eax,9
 ja test_usage
 mov r12d,eax
 cmp r12d,1
 je scenario_1
 cmp r12d,2
 je scenario_2
 cmp r12d,3
 je scenario_3
 cmp r12d,4
 je scenario_4
 cmp r12d,5
 je scenario_5
 cmp r12d,6
 je scenario_6
 cmp r12d,7
 je scenario_7
 cmp r12d,8
 je scenario_8
 jmp scenario_9

; DataLayout freezes the exact first-target physical values.
scenario_1:
 call reset_all
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 lea rdi,[rel layout_a]
 call neboc_data_layout_validate
 test eax,eax
 jnz test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_POINTER_SIZE_OFFSET],8
 jne test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_INT_SIZE_OFFSET],8
 jne test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_BOOL_REPRESENTATION_OFFSET],NEBOC_DATA_LAYOUT_BOOL_ZERO_ONE
 jne test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_SLICE_SIZE_OFFSET],16
 jne test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_CONSOLE_HANDLE_SIZE_OFFSET],8
 jne test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_PENDING_HANDLE_SIZE_OFFSET],8
 jne test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_STACK_ALIGNMENT_OFFSET],16
 jne test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_ENDIANNESS_OFFSET],NEBOC_DATA_LAYOUT_ENDIAN_LITTLE
 jne test_fail
 cmp qword [rel layout_a+NEBOC_DATA_LAYOUT_HASH_OFFSET],0
 je test_fail
 jmp test_pass

; The approved tuple initializes one frozen TargetContext.
scenario_2:
 call reset_all
 call init_valid_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 call neboc_target_context_validate
 test eax,eax
 jnz test_fail
 cmp qword [rel context_a+NEBOC_TARGET_CONTEXT_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 jne test_fail
 cmp qword [rel context_a+NEBOC_TARGET_CONTEXT_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 jne test_fail
 cmp qword [rel context_a+NEBOC_TARGET_CONTEXT_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 jne test_fail
 cmp qword [rel context_a+NEBOC_TARGET_CONTEXT_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 jne test_fail
 cmp qword [rel context_a+NEBOC_TARGET_CONTEXT_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 jne test_fail
 cmp qword [rel context_a+NEBOC_TARGET_CONTEXT_FEATURE_FLAGS_OFFSET],NEBOC_TARGET_FEATURES_V0
 jne test_fail
 cmp qword [rel context_a+NEBOC_TARGET_CONTEXT_CAPABILITY_FLAGS_OFFSET],NEBOC_TARGET_CAPABILITIES_V0
 jne test_fail
 cmp qword [rel context_a+NEBOC_TARGET_CONTEXT_TUPLE_HASH_OFFSET],0
 je test_fail
 jmp test_pass

; Repeated initialization is pointer-free and deterministic.
scenario_3:
 call reset_all
 call init_valid_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel layout_b]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 call fill_valid_request
 lea rdi,[rel context_b]
 lea rsi,[rel layout_b]
 lea rdx,[rel request]
 call neboc_target_context_init
 test eax,eax
 jnz test_fail
 mov rax,[rel layout_a+NEBOC_DATA_LAYOUT_HASH_OFFSET]
 cmp rax,[rel layout_b+NEBOC_DATA_LAYOUT_HASH_OFFSET]
 jne test_fail
 mov rax,[rel context_a+NEBOC_TARGET_CONTEXT_TUPLE_HASH_OFFSET]
 cmp rax,[rel context_b+NEBOC_TARGET_CONTEXT_TUPLE_HASH_OFFSET]
 jne test_fail
 mov rax,[rel context_a+NEBOC_TARGET_CONTEXT_LAYOUT_HASH_OFFSET]
 cmp rax,[rel context_b+NEBOC_TARGET_CONTEXT_LAYOUT_HASH_OFFSET]
 jne test_fail
 mov rax,[rel context_a+NEBOC_TARGET_CONTEXT_CAPABILITY_FLAGS_OFFSET]
 cmp rax,[rel context_b+NEBOC_TARGET_CONTEXT_CAPABILITY_FLAGS_OFFSET]
 jne test_fail
 jmp test_pass

; NEBO-ABI-NEG-007 — incomplete tuple fails with a stable diagnostic.
scenario_4:
 call reset_all
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 call fill_valid_request
 mov qword [rel request+NEBOC_TARGET_REQUEST_OBJECT_FORMAT_OFFSET],0
 mov qword [rel request+NEBOC_TARGET_REQUEST_COMPONENT_MASK_OFFSET],11
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_INCOMPLETE_TUPLE
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_OUT_TARGET_ID_OFFSET],0
 jne test_fail
 lea rdi,[rel context_a]
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
 call region_is_zero
 test eax,eax
 jnz test_fail
 mov edi,NEBOC_TARGET_ERROR_INCOMPLETE_TUPLE
 lea rsi,[rel expected_incomplete]
 mov edx,NEBOC_TARGET_DIAG_INCOMPLETE_TUPLE_LENGTH
 call expect_diag
 test eax,eax
 jnz test_fail
 jmp test_pass

; A second/unknown ISA is rejected rather than creating another semantic fork.
scenario_5:
 call reset_all
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 call fill_valid_request
 mov qword [rel request+NEBOC_TARGET_REQUEST_INSTRUCTION_SET_OFFSET],2
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_ISA
 jne test_fail
 call fill_valid_request
 mov qword [rel request+NEBOC_TARGET_REQUEST_TARGET_ID_OFFSET],2
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_TARGET_ID
 jne test_fail
 jmp test_pass

; ABI and object format remain independent tuple components.
scenario_6:
 call reset_all
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 call fill_valid_request
 mov qword [rel request+NEBOC_TARGET_REQUEST_ABI_ID_OFFSET],2
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_ABI
 jne test_fail
 call fill_valid_request
 mov qword [rel request+NEBOC_TARGET_REQUEST_OBJECT_FORMAT_OFFSET],2
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_FORMAT
 jne test_fail
 jmp test_pass

; Runtime and toolchain profiles are validated explicitly.
scenario_7:
 call reset_all
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 call fill_valid_request
 mov qword [rel request+NEBOC_TARGET_REQUEST_RUNTIME_PROFILE_OFFSET],2
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_RUNTIME
 jne test_fail
 call fill_valid_request
 mov qword [rel request+NEBOC_TARGET_REQUEST_TOOLCHAIN_PROFILE_OFFSET],2
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_TOOLCHAIN
 jne test_fail
 jmp test_pass

; Unknown feature combinations fail before context materialization.
scenario_8:
 call reset_all
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 call fill_valid_request
 mov qword [rel request+NEBOC_TARGET_REQUEST_FEATURE_FLAGS_OFFSET],63
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_FEATURES
 jne test_fail
 jmp test_pass

; A tampered DataLayout cannot be paired with the approved tuple.
scenario_9:
 call reset_all
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 mov qword [rel layout_a+NEBOC_DATA_LAYOUT_POINTER_SIZE_OFFSET],4
 call fill_valid_request
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_INVALID_DATA_LAYOUT
 jne test_fail
 jmp test_pass


; MF031-R1 A — a non-zero but corrupted DataLayout hash is rejected.
scenario_A:
 call reset_all
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz test_fail
 lea rdi,[rel layout_a]
 call neboc_data_layout_validate
 test eax,eax
 jnz test_fail
 mov rax,[rel layout_a+NEBOC_DATA_LAYOUT_HASH_OFFSET]
 inc rax
 mov [rel layout_a+NEBOC_DATA_LAYOUT_HASH_OFFSET],rax
 lea rdi,[rel layout_a]
 call neboc_data_layout_validate
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 call fill_valid_request
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_INVALID_DATA_LAYOUT
 jne test_fail
 cmp qword [rel request+NEBOC_TARGET_REQUEST_OUT_TARGET_ID_OFFSET],0
 jne test_fail
 lea rdi,[rel context_a]
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
 call region_is_zero
 test eax,eax
 jnz test_fail
 jmp test_pass

; MF031-R1 B — a non-zero but corrupted target tuple hash is rejected.
scenario_B:
 call reset_all
 call init_valid_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 call neboc_target_context_validate
 test eax,eax
 jnz test_fail
 mov rax,[rel context_a+NEBOC_TARGET_CONTEXT_TUPLE_HASH_OFFSET]
 inc rax
 mov [rel context_a+NEBOC_TARGET_CONTEXT_TUPLE_HASH_OFFSET],rax
 lea rdi,[rel context_a]
 call neboc_target_context_validate
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 jmp test_pass

; MF031-R1 C — mirrored corruption cannot bypass canonical layout validation.
scenario_C:
 call reset_all
 call init_valid_a
 test eax,eax
 jnz test_fail
 mov rax,[rel layout_a+NEBOC_DATA_LAYOUT_HASH_OFFSET]
 inc rax
 mov [rel layout_a+NEBOC_DATA_LAYOUT_HASH_OFFSET],rax
 mov [rel context_a+NEBOC_TARGET_CONTEXT_LAYOUT_HASH_OFFSET],rax
 lea rdi,[rel context_a]
 call neboc_target_context_validate
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 jmp test_pass

init_valid_a:
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz .done
 call fill_valid_request
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel request]
 call neboc_target_context_init
.done:
 ret

fill_valid_request:
 lea rdi,[rel request]
 mov ecx,NEBOC_TARGET_REQUEST_QWORDS
 call zero_region
 mov qword [rel request+NEBOC_TARGET_REQUEST_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 mov qword [rel request+NEBOC_TARGET_REQUEST_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 mov qword [rel request+NEBOC_TARGET_REQUEST_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 mov qword [rel request+NEBOC_TARGET_REQUEST_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 mov qword [rel request+NEBOC_TARGET_REQUEST_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 mov qword [rel request+NEBOC_TARGET_REQUEST_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_RUNTIME_NATIVE_LINUX_V0
 mov qword [rel request+NEBOC_TARGET_REQUEST_CONSOLE_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_CONSOLE_RUNTIME_CORE_V0
 mov qword [rel request+NEBOC_TARGET_REQUEST_TOOLCHAIN_PROFILE_OFFSET],NEBOC_TARGET_TOOLCHAIN_NASM_GNU_LD_NINJA_V0
 mov qword [rel request+NEBOC_TARGET_REQUEST_FEATURE_FLAGS_OFFSET],NEBOC_TARGET_FEATURES_V0
 mov qword [rel request+NEBOC_TARGET_REQUEST_COMPONENT_MASK_OFFSET],NEBOC_TARGET_COMPONENT_REQUIRED_MASK
 ret

reset_all:
 lea rdi,[rel layout_a]
 mov ecx,NEBOC_DATA_LAYOUT_QWORDS
 call zero_region
 lea rdi,[rel layout_b]
 mov ecx,NEBOC_DATA_LAYOUT_QWORDS
 call zero_region
 lea rdi,[rel context_a]
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
 call zero_region
 lea rdi,[rel context_b]
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
 call zero_region
 lea rdi,[rel request]
 mov ecx,NEBOC_TARGET_REQUEST_QWORDS
 call zero_region
 mov qword [rel diag_ptr],0
 mov qword [rel diag_len],0
 ret

zero_region:
 xor eax,eax
.zero_loop:
 test ecx,ecx
 jz .zero_done
 mov [rdi],rax
 add rdi,8
 dec ecx
 jmp .zero_loop
.zero_done:
 ret

region_is_zero:
 xor eax,eax
.zero_check:
 test ecx,ecx
 jz .zero_ok
 cmp qword [rdi],0
 jne .zero_bad
 add rdi,8
 dec ecx
 jmp .zero_check
.zero_ok:
 xor eax,eax
 ret
.zero_bad:
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
 call neboc_target_diagnostic_name
 test eax,eax
 jnz .bad
 cmp [rel diag_len],r13
 jne .bad
 mov rdi,[rel diag_ptr]
 mov rsi,r12
 mov rcx,r13
.compare:
 test rcx,rcx
 jz .ok
 mov al,[rdi]
 cmp al,[rsi]
 jne .bad
 inc rdi
 inc rsi
 dec rcx
 jmp .compare
.ok:
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

test_pass:
 xor edi,edi
 call neboc_host_process_exit
 hlt

test_fail:
 mov edi,1
 call neboc_host_process_exit
 hlt

test_usage:
 mov edi,2
 call neboc_host_process_exit
 hlt

section .note.GNU-stack noalloc noexec nowrite progbits
