; Nebo Assembly — MF031 first target tuple and TargetContext
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/data-layout/data_layout.inc"
%include "compiler/target/target_context.inc"

extern neboc_hash_fnv1a32
extern neboc_data_layout_validate

section .text

; target_context_init(context*, data_layout*, request*)
NEBOC_ABI_FUNCTION neboc_target_context_init
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r14,r14
 jz .bad_request_no_record
 mov qword [r14+NEBOC_TARGET_REQUEST_OUT_TARGET_ID_OFFSET],0
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_NONE
 test r12,r12
 jz .bad_request
 test r13,r13
 jz .bad_request
 cmp qword [r14+NEBOC_TARGET_REQUEST_COMPONENT_MASK_OFFSET],NEBOC_TARGET_COMPONENT_REQUIRED_MASK
 jne .incomplete
 cmp qword [r14+NEBOC_TARGET_REQUEST_INSTRUCTION_SET_OFFSET],0
 je .incomplete
 cmp qword [r14+NEBOC_TARGET_REQUEST_ABI_ID_OFFSET],0
 je .incomplete
 cmp qword [r14+NEBOC_TARGET_REQUEST_OBJECT_FORMAT_OFFSET],0
 je .incomplete
 cmp qword [r14+NEBOC_TARGET_REQUEST_OPERATING_ENVIRONMENT_OFFSET],0
 je .incomplete
 cmp qword [r14+NEBOC_TARGET_REQUEST_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 jne .unsupported_target_id
 cmp qword [r14+NEBOC_TARGET_REQUEST_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 jne .unsupported_isa
 cmp qword [r14+NEBOC_TARGET_REQUEST_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 jne .unsupported_abi
 cmp qword [r14+NEBOC_TARGET_REQUEST_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 jne .unsupported_format
 cmp qword [r14+NEBOC_TARGET_REQUEST_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 jne .unsupported_environment
 cmp qword [r14+NEBOC_TARGET_REQUEST_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_RUNTIME_NATIVE_LINUX_V0
 jne .unsupported_runtime
 cmp qword [r14+NEBOC_TARGET_REQUEST_CONSOLE_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_CONSOLE_RUNTIME_CORE_V0
 jne .unsupported_console_runtime
 cmp qword [r14+NEBOC_TARGET_REQUEST_TOOLCHAIN_PROFILE_OFFSET],NEBOC_TARGET_TOOLCHAIN_NASM_GNU_LD_NINJA_V0
 jne .unsupported_toolchain
 cmp qword [r14+NEBOC_TARGET_REQUEST_FEATURE_FLAGS_OFFSET],NEBOC_TARGET_FEATURES_V0
 jne .unsupported_features
 mov rdi,r13
 call neboc_data_layout_validate
 test eax,eax
 jnz .invalid_layout
 mov rdi,r12
 xor eax,eax
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
.zero_context:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .zero_context
 mov qword [r12+NEBOC_TARGET_CONTEXT_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 mov qword [r12+NEBOC_TARGET_CONTEXT_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 mov qword [r12+NEBOC_TARGET_CONTEXT_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 mov qword [r12+NEBOC_TARGET_CONTEXT_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 mov qword [r12+NEBOC_TARGET_CONTEXT_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 mov [r12+NEBOC_TARGET_CONTEXT_DATA_LAYOUT_PTR_OFFSET],r13
 mov qword [r12+NEBOC_TARGET_CONTEXT_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_RUNTIME_NATIVE_LINUX_V0
 mov qword [r12+NEBOC_TARGET_CONTEXT_CONSOLE_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_CONSOLE_RUNTIME_CORE_V0
 mov qword [r12+NEBOC_TARGET_CONTEXT_TOOLCHAIN_PROFILE_OFFSET],NEBOC_TARGET_TOOLCHAIN_NASM_GNU_LD_NINJA_V0
 mov qword [r12+NEBOC_TARGET_CONTEXT_FEATURE_FLAGS_OFFSET],NEBOC_TARGET_FEATURES_V0
 mov qword [r12+NEBOC_TARGET_CONTEXT_CAPABILITY_FLAGS_OFFSET],NEBOC_TARGET_CAPABILITIES_V0
 mov rax,[r13+NEBOC_DATA_LAYOUT_HASH_OFFSET]
 mov [r12+NEBOC_TARGET_CONTEXT_LAYOUT_HASH_OFFSET],rax
 mov qword [r12+NEBOC_TARGET_CONTEXT_TUPLE_VERSION_OFFSET],NEBOC_TARGET_TUPLE_VERSION
 mov rdi,r12
 mov esi,NEBOC_TARGET_CONTEXT_TUPLE_HASHED_BYTES
 lea rdx,[r12+NEBOC_TARGET_CONTEXT_TUPLE_HASH_OFFSET]
 call neboc_hash_fnv1a32
 test eax,eax
 jnz .hash_failure
 mov qword [r12+NEBOC_TARGET_CONTEXT_STATE_OFFSET],NEBOC_TARGET_CONTEXT_STATE_FROZEN
 mov qword [r12+NEBOC_TARGET_CONTEXT_LAST_ERROR_OFFSET],NEBOC_TARGET_ERROR_NONE
 mov qword [r14+NEBOC_TARGET_REQUEST_OUT_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_NONE
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.hash_failure:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_BAD_REQUEST
 jmp .internal_error
.bad_request:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_BAD_REQUEST
 jmp .invalid_argument
.incomplete:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_INCOMPLETE_TUPLE
 jmp .unsupported
.unsupported_target_id:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_TARGET_ID
 jmp .unsupported
.unsupported_isa:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_ISA
 jmp .unsupported
.unsupported_abi:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_ABI
 jmp .unsupported
.unsupported_format:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_FORMAT
 jmp .unsupported
.unsupported_environment:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_ENVIRONMENT
 jmp .unsupported
.unsupported_runtime:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_RUNTIME
 jmp .unsupported
.unsupported_console_runtime:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_CONSOLE_RUNTIME
 jmp .unsupported
.unsupported_toolchain:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_TOOLCHAIN
 jmp .unsupported
.unsupported_features:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_UNSUPPORTED_FEATURES
 jmp .unsupported
.invalid_layout:
 mov qword [r14+NEBOC_TARGET_REQUEST_ERROR_CODE_OFFSET],NEBOC_TARGET_ERROR_INVALID_DATA_LAYOUT
 jmp .unsupported
.bad_request_no_record:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.invalid_argument:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.unsupported:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_UNSUPPORTED_TARGET
.internal_error:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INTERNAL_ERROR

; target_context_validate(context*)
NEBOC_ABI_FUNCTION neboc_target_context_validate
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_STATE_OFFSET],NEBOC_TARGET_CONTEXT_STATE_FROZEN
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_RUNTIME_NATIVE_LINUX_V0
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_CONSOLE_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_CONSOLE_RUNTIME_CORE_V0
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_TOOLCHAIN_PROFILE_OFFSET],NEBOC_TARGET_TOOLCHAIN_NASM_GNU_LD_NINJA_V0
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_FEATURE_FLAGS_OFFSET],NEBOC_TARGET_FEATURES_V0
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_CAPABILITY_FLAGS_OFFSET],NEBOC_TARGET_CAPABILITIES_V0
 jne .unsupported
 cmp qword [rbx+NEBOC_TARGET_CONTEXT_TUPLE_HASH_OFFSET],0
 je .unsupported
 mov qword [rsp],0
 mov rdi,rbx
 mov esi,NEBOC_TARGET_CONTEXT_TUPLE_HASHED_BYTES
 lea rdx,[rsp]
 call neboc_hash_fnv1a32
 test eax,eax
 jnz .internal_error
 mov rax,[rsp]
 cmp rax,[rbx+NEBOC_TARGET_CONTEXT_TUPLE_HASH_OFFSET]
 jne .unsupported
 mov rax,[rbx+NEBOC_TARGET_CONTEXT_DATA_LAYOUT_PTR_OFFSET]
 test rax,rax
 jz .unsupported
 mov r12,rax
 mov rdi,r12
 call neboc_data_layout_validate
 test eax,eax
 jnz .unsupported
 mov rax,[r12+NEBOC_DATA_LAYOUT_HASH_OFFSET]
 cmp rax,[rbx+NEBOC_TARGET_CONTEXT_LAYOUT_HASH_OFFSET]
 jne .unsupported
 add rsp,16
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.unsupported:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_UNSUPPORTED_TARGET
.invalid:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.internal_error:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INTERNAL_ERROR

section .note.GNU-stack noalloc noexec nowrite progbits
