; Nebo Assembly — MF033 x86-64 ABI Adapter v0
;
; Materializes DG-005 for generated Nebo functions on the first target.
; The ArchitectureBackend owns module/function labels. This adapter consumes the
; same backend and AssemblyWriter to emit deterministic System V AMD64 function
; frames, parameter moves, calls, returns and version-guarded runtime thunks.
; No red zone, recursion, optimizer, runtime implementation or object/link driver.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/hash/fnv1a.inc"
%include "compiler/data-layout/data_layout.inc"
%include "compiler/target/target_context.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"

extern neboc_hash_fnv1a32
extern neboc_target_context_validate
extern neboc_arch_backend_validate
extern neboc_assembly_writer_validate
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal
extern neboc_assembly_writer_append_i64_decimal

section .rodata
abi_prologue: db '    push rbp',10,'    mov rbp, rsp',10
abi_prologue_length equ $-abi_prologue
abi_sub_rsp: db '    sub rsp, '
abi_sub_rsp_length equ $-abi_sub_rsp
abi_add_rsp: db '    add rsp, '
abi_add_rsp_length equ $-abi_add_rsp
abi_mov_slot_prefix: db '    mov [rbp-'
abi_mov_slot_prefix_length equ $-abi_mov_slot_prefix
abi_slot_reg_suffix: db '], '
abi_slot_reg_suffix_length equ $-abi_slot_reg_suffix
abi_mov_stack_prefix: db '    mov rax, [rbp+'
abi_mov_stack_prefix_length equ $-abi_mov_stack_prefix
abi_stack_suffix: db ']',10
abi_stack_suffix_length equ $-abi_stack_suffix
abi_slot_rax_suffix: db '], rax',10
abi_slot_rax_suffix_length equ $-abi_slot_rax_suffix
abi_mov_prefix: db '    mov '
abi_mov_prefix_length equ $-abi_mov_prefix
abi_comma_space: db ', '
abi_comma_space_length equ $-abi_comma_space
abi_mov_rax: db '    mov rax, '
abi_mov_rax_length equ $-abi_mov_rax
abi_mov_eax: db '    mov eax, '
abi_mov_eax_length equ $-abi_mov_eax
abi_push_rax: db '    push rax',10
abi_push_rax_length equ $-abi_push_rax
abi_call_prefix: db '    call nebo_fn_'
abi_call_prefix_length equ $-abi_call_prefix
abi_epilogue: db '    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
abi_epilogue_length equ $-abi_epilogue
abi_newline: db 10
abi_newline_length equ $-abi_newline

abi_text_section: db 10,'section .text',10
abi_text_section_length equ $-abi_text_section
abi_extern_version: db 'extern nebo_runtime_abi_version',10
abi_extern_version_length equ $-abi_extern_version
abi_extern_contract: db 'extern nebo_runtime_contract_'
abi_extern_contract_length equ $-abi_extern_contract
abi_global_thunk: db 'global nebo_runtime_thunk_'
abi_global_thunk_length equ $-abi_global_thunk
abi_thunk_label: db 'nebo_runtime_thunk_'
abi_thunk_label_length equ $-abi_thunk_label
abi_colon_newline: db ':',10
abi_colon_newline_length equ $-abi_colon_newline
abi_cmp_runtime: db '    cmp qword [rel nebo_runtime_abi_version], '
abi_cmp_runtime_length equ $-abi_cmp_runtime
abi_jne_mismatch: db '    jne .nebo_runtime_version_mismatch_'
abi_jne_mismatch_length equ $-abi_jne_mismatch
abi_jmp_contract: db '    jmp nebo_runtime_contract_'
abi_jmp_contract_length equ $-abi_jmp_contract
abi_mismatch_label: db '.nebo_runtime_version_mismatch_'
abi_mismatch_label_length equ $-abi_mismatch_label
abi_status_toolchain: db '    mov eax, 7',10,'    ret',10
abi_status_toolchain_length equ $-abi_status_toolchain

arg_rdi: db 'rdi'
arg_rsi: db 'rsi'
arg_rdx: db 'rdx'
arg_rcx: db 'rcx'
arg_r8: db 'r8'
arg_r9: db 'r9'
arg_name_ptrs: dq arg_rdi,arg_rsi,arg_rdx,arg_rcx,arg_r8,arg_r9
arg_name_lengths: dq 3,3,3,3,2,2

section .text

; abi_adapter_init(adapter*, target_context*, architecture_backend*, request*)
NEBOC_ABI_FUNCTION neboc_abi_adapter_init
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test rbx,rbx
 jz .invalid_return
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_EMPTY
 jne .bad_request
 test r12,r12
 jz .bad_request
 test r13,r13
 jz .bad_request
 test r14,r14
 jz .bad_request
 mov qword [r14+NEBOC_ABI_REQUEST_ERROR_CODE_OFFSET],NEBOC_ABI_ERROR_NONE
 cmp qword [r14+NEBOC_ABI_REQUEST_INTERNAL_VERSION_OFFSET],NEBOC_INTERNAL_ABI_VERSION
 jne .internal_version
 cmp qword [r14+NEBOC_ABI_REQUEST_RUNTIME_VERSION_OFFSET],NEBOC_RUNTIME_ABI_VERSION_V0
 jne .runtime_version
 cmp qword [r14+NEBOC_ABI_REQUEST_TARGET_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 jne .target
 cmp qword [r14+NEBOC_ABI_REQUEST_STACK_ALIGNMENT_OFFSET],NEBOC_ABI_STACK_ALIGNMENT
 jne .target
 cmp qword [r14+NEBOC_ABI_REQUEST_FLAGS_OFFSET],NEBOC_ABI_REQUEST_REQUIRED_FLAGS
 jne .bad_request
 mov rdi,r12
 call neboc_target_context_validate
 test eax,eax
 jnz .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 jne .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 jne .target
 mov r15,[r12+NEBOC_TARGET_CONTEXT_DATA_LAYOUT_PTR_OFFSET]
 test r15,r15
 jz .target
 cmp qword [r15+NEBOC_DATA_LAYOUT_STACK_ALIGNMENT_OFFSET],NEBOC_ABI_STACK_ALIGNMENT
 jne .target
 mov rdi,r13
 call neboc_arch_backend_validate
 test eax,eax
 jnz .backend
 cmp r12,[r13+NEBOC_ARCH_BACKEND_TARGET_CONTEXT_OFFSET]
 jne .target
 mov r10,[r13+NEBOC_ARCH_BACKEND_STATE_OFFSET]
 cmp r10,NEBOC_ARCH_BACKEND_STATE_READY
 je .backend_state_ok
 cmp r10,NEBOC_ARCH_BACKEND_STATE_MODULE
 jne .backend
.backend_state_ok:
 mov r10,[r13+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 test r10,r10
 jz .writer
 mov rdi,r10
 call neboc_assembly_writer_validate
 test eax,eax
 jnz .writer
 ; R10 is caller-saved: reload the writer pointer after validation.
 mov r10,[r13+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 cmp qword [r10+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_READY
 jne .writer
 mov [rbx+NEBOC_ABI_ADAPTER_TARGET_CONTEXT_OFFSET],r12
 mov [rbx+NEBOC_ABI_ADAPTER_DATA_LAYOUT_OFFSET],r15
 mov [rbx+NEBOC_ABI_ADAPTER_BACKEND_OFFSET],r13
 mov [rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET],r10
 mov qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_READY
 mov qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_INTERNAL_VERSION_OFFSET],NEBOC_INTERNAL_ABI_VERSION
 mov qword [rbx+NEBOC_ABI_ADAPTER_RUNTIME_VERSION_OFFSET],NEBOC_RUNTIME_ABI_VERSION_V0
 mov qword [rbx+NEBOC_ABI_ADAPTER_STACK_ALIGNMENT_OFFSET],NEBOC_ABI_STACK_ALIGNMENT
 mov qword [rbx+NEBOC_ABI_ADAPTER_CALLER_SAVED_MASK_OFFSET],NEBOC_ABI_CALLER_SAVED_MASK_V0
 mov qword [rbx+NEBOC_ABI_ADAPTER_CALLEE_SAVED_MASK_OFFSET],NEBOC_ABI_CALLEE_SAVED_MASK_V0
 mov qword [rbx+NEBOC_ABI_ADAPTER_EMITTED_FUNCTIONS_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_EMITTED_THUNKS_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 mov qword [rbx+NEBOC_ABI_ADAPTER_FLAGS_OFFSET],NEBOC_ABI_ADAPTER_REQUIRED_FLAGS
 mov qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],0
 xor eax,eax
 jmp .done
.internal_version:
 mov qword [r14+NEBOC_ABI_REQUEST_ERROR_CODE_OFFSET],NEBOC_ABI_ERROR_INTERNAL_VERSION_MISMATCH
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_INTERNAL_VERSION_MISMATCH
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.runtime_version:
 mov qword [r14+NEBOC_ABI_REQUEST_ERROR_CODE_OFFSET],NEBOC_ABI_ERROR_RUNTIME_VERSION_MISMATCH
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_RUNTIME_VERSION_MISMATCH
 mov eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jmp .done
.target:
 mov qword [r14+NEBOC_ABI_REQUEST_ERROR_CODE_OFFSET],NEBOC_ABI_ERROR_TARGET_MISMATCH
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_TARGET_MISMATCH
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jmp .done
.backend:
 mov qword [r14+NEBOC_ABI_REQUEST_ERROR_CODE_OFFSET],NEBOC_ABI_ERROR_BACKEND_NOT_READY
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BACKEND_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.writer:
 mov qword [r14+NEBOC_ABI_REQUEST_ERROR_CODE_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_request:
 test r14,r14
 jz .bad_request_store
 mov qword [r14+NEBOC_ABI_REQUEST_ERROR_CODE_OFFSET],NEBOC_ABI_ERROR_BAD_REQUEST
.bad_request_store:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_REQUEST
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_signature_init(signature*, function_id, parameter_count, local_slots,
;                    return_kind, call_count)
NEBOC_ABI_FUNCTION neboc_abi_signature_init
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp],r9
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBOC_ABI_SIGNATURE_STATE_OFFSET],NEBOC_ABI_SIGNATURE_STATE_EMPTY
 jne .invalid
 test r12,r12
 jz .invalid
 cmp r13,NEBOC_ABI_MAX_PARAMETERS
 ja .limit
 cmp r14,NEBOC_ABI_MAX_LOCAL_SLOTS
 ja .limit
 cmp r15,NEBOC_ABI_RETURN_KIND_COUNT
 jae .invalid
 cmp qword [rsp],NEBOC_ABI_MAX_RUNTIME_CALLS
 ja .limit
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_ABI_SIGNATURE_QWORDS
.zero:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .zero
 mov [rbx+NEBOC_ABI_SIGNATURE_FUNCTION_ID_OFFSET],r12
 mov [rbx+NEBOC_ABI_SIGNATURE_PARAMETER_COUNT_OFFSET],r13
 mov rax,r13
 cmp rax,NEBOC_ABI_REGISTER_PARAMETER_COUNT
 jbe .register_count_ok
 mov eax,NEBOC_ABI_REGISTER_PARAMETER_COUNT
.register_count_ok:
 mov [rbx+NEBOC_ABI_SIGNATURE_REGISTER_PARAMETER_COUNT_OFFSET],rax
 mov rdx,r13
 sub rdx,rax
 mov [rbx+NEBOC_ABI_SIGNATURE_STACK_PARAMETER_COUNT_OFFSET],rdx
 mov [rbx+NEBOC_ABI_SIGNATURE_LOCAL_SLOT_COUNT_OFFSET],r14
 mov rax,r14
 shl rax,3
 add rax,NEBOC_ABI_STACK_ALIGNMENT-1
 and rax,-NEBOC_ABI_STACK_ALIGNMENT
 mov [rbx+NEBOC_ABI_SIGNATURE_FRAME_SIZE_OFFSET],rax
 mov [rbx+NEBOC_ABI_SIGNATURE_RETURN_KIND_OFFSET],r15
 mov rax,[rsp]
 mov [rbx+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET],rax
 mov qword [rbx+NEBOC_ABI_SIGNATURE_STATE_OFFSET],NEBOC_ABI_SIGNATURE_STATE_FROZEN
 mov qword [rbx+NEBOC_ABI_SIGNATURE_FLAGS_OFFSET],NEBOC_ABI_SIGNATURE_REQUIRED_FLAGS
 mov qword [rsp+8],0
 mov rdi,rbx
 mov esi,NEBOC_ABI_SIGNATURE_HASHED_BYTES
 lea rdx,[rsp+8]
 call neboc_hash_fnv1a32
 test eax,eax
 jnz .hash
 mov rax,[rsp+8]
 mov [rbx+NEBOC_ABI_SIGNATURE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.hash:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_signature_validate(signature*)
NEBOC_ABI_FUNCTION neboc_abi_signature_validate
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBOC_ABI_SIGNATURE_STATE_OFFSET],NEBOC_ABI_SIGNATURE_STATE_FROZEN
 jne .invalid
 cmp qword [rbx+NEBOC_ABI_SIGNATURE_FLAGS_OFFSET],NEBOC_ABI_SIGNATURE_REQUIRED_FLAGS
 jne .invalid
 cmp qword [rbx+NEBOC_ABI_SIGNATURE_FUNCTION_ID_OFFSET],0
 je .invalid
 mov r12,[rbx+NEBOC_ABI_SIGNATURE_PARAMETER_COUNT_OFFSET]
 cmp r12,NEBOC_ABI_MAX_PARAMETERS
 ja .limit
 mov r13,r12
 cmp r13,NEBOC_ABI_REGISTER_PARAMETER_COUNT
 jbe .reg_ok
 mov r13,NEBOC_ABI_REGISTER_PARAMETER_COUNT
.reg_ok:
 cmp r13,[rbx+NEBOC_ABI_SIGNATURE_REGISTER_PARAMETER_COUNT_OFFSET]
 jne .invalid
 mov r14,r12
 sub r14,r13
 cmp r14,[rbx+NEBOC_ABI_SIGNATURE_STACK_PARAMETER_COUNT_OFFSET]
 jne .invalid
 mov r15,[rbx+NEBOC_ABI_SIGNATURE_LOCAL_SLOT_COUNT_OFFSET]
 cmp r15,NEBOC_ABI_MAX_LOCAL_SLOTS
 ja .limit
 mov rax,r15
 shl rax,3
 add rax,NEBOC_ABI_STACK_ALIGNMENT-1
 and rax,-NEBOC_ABI_STACK_ALIGNMENT
 cmp rax,[rbx+NEBOC_ABI_SIGNATURE_FRAME_SIZE_OFFSET]
 jne .invalid
 cmp qword [rbx+NEBOC_ABI_SIGNATURE_RETURN_KIND_OFFSET],NEBOC_ABI_RETURN_KIND_COUNT
 jae .invalid
 cmp qword [rbx+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET],NEBOC_ABI_MAX_RUNTIME_CALLS
 ja .limit
 mov qword [rsp],0
 mov rdi,rbx
 mov esi,NEBOC_ABI_SIGNATURE_HASHED_BYTES
 lea rdx,[rsp]
 call neboc_hash_fnv1a32
 test eax,eax
 jnz .invalid
 mov rax,[rsp]
 cmp rax,[rbx+NEBOC_ABI_SIGNATURE_HASH_OFFSET]
 jne .invalid
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_adapter_validate(adapter*)
NEBOC_ABI_FUNCTION neboc_abi_adapter_validate
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 mov rax,[rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET]
 cmp rax,NEBOC_ABI_ADAPTER_STATE_READY
 je .state_ok
 cmp rax,NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .state
.state_ok:
 cmp qword [rbx+NEBOC_ABI_ADAPTER_FLAGS_OFFSET],NEBOC_ABI_ADAPTER_REQUIRED_FLAGS
 jne .invalid
 cmp qword [rbx+NEBOC_ABI_ADAPTER_INTERNAL_VERSION_OFFSET],NEBOC_INTERNAL_ABI_VERSION
 jne .invalid
 cmp qword [rbx+NEBOC_ABI_ADAPTER_RUNTIME_VERSION_OFFSET],NEBOC_RUNTIME_ABI_VERSION_V0
 jne .invalid
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STACK_ALIGNMENT_OFFSET],NEBOC_ABI_STACK_ALIGNMENT
 jne .invalid
 cmp qword [rbx+NEBOC_ABI_ADAPTER_CALLER_SAVED_MASK_OFFSET],NEBOC_ABI_CALLER_SAVED_MASK_V0
 jne .invalid
 cmp qword [rbx+NEBOC_ABI_ADAPTER_CALLEE_SAVED_MASK_OFFSET],NEBOC_ABI_CALLEE_SAVED_MASK_V0
 jne .invalid
 mov r12,[rbx+NEBOC_ABI_ADAPTER_TARGET_CONTEXT_OFFSET]
 mov r13,[rbx+NEBOC_ABI_ADAPTER_DATA_LAYOUT_OFFSET]
 mov r14,[rbx+NEBOC_ABI_ADAPTER_BACKEND_OFFSET]
 mov r15,[rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 cmp r13,[r12+NEBOC_TARGET_CONTEXT_DATA_LAYOUT_PTR_OFFSET]
 jne .target
 cmp r12,[r14+NEBOC_ARCH_BACKEND_TARGET_CONTEXT_OFFSET]
 jne .target
 cmp r15,[r14+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 jne .backend
 mov rdi,r12
 call neboc_target_context_validate
 test eax,eax
 jnz .target
 mov rdi,r14
 call neboc_arch_backend_validate
 test eax,eax
 jnz .backend
 mov rdi,r15
 call neboc_assembly_writer_validate
 test eax,eax
 jnz .writer
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .ready
 mov r12,[rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 test r12,r12
 jz .signature
 mov rdi,r12
 call neboc_abi_signature_validate
 test eax,eax
 jnz .signature
 mov rax,[r12+NEBOC_ABI_SIGNATURE_FUNCTION_ID_OFFSET]
 cmp rax,[r14+NEBOC_ARCH_BACKEND_CURRENT_FUNCTION_ID_OFFSET]
 jne .function
 jmp .ok
.ready:
 cmp qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET],0
 jne .state
 cmp qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],0
 jne .state
.ok:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.target:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_TARGET_MISMATCH
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jmp .done
.backend:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BACKEND_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.signature:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_SIGNATURE_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.function:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_FUNCTION_MISMATCH
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_REQUEST
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_adapter_begin_function(adapter*, frozen_signature*)
NEBOC_ABI_FUNCTION neboc_abi_adapter_begin_function
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_READY
 jne .state
 test r12,r12
 jz .signature
 mov rdi,r12
 call neboc_abi_signature_validate
 test eax,eax
 jnz .signature
 mov r13,[rbx+NEBOC_ABI_ADAPTER_BACKEND_OFFSET]
 cmp qword [r13+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_MODULE
 jne .backend
 mov rax,[r12+NEBOC_ABI_SIGNATURE_FUNCTION_ID_OFFSET]
 cmp rax,[r13+NEBOC_ARCH_BACKEND_CURRENT_FUNCTION_ID_OFFSET]
 jne .function
 mov r15,[rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_ABI_ADAPTER_EMITTED_FUNCTIONS_OFFSET]
 mov [rsp+8],rax
 mov rdi,r15
 lea rsi,[rel abi_prologue]
 mov edx,abi_prologue_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov r14,[r12+NEBOC_ABI_SIGNATURE_FRAME_SIZE_OFFSET]
 test r14,r14
 jz .commit
 mov rdi,r15
 lea rsi,[rel abi_sub_rsp]
 mov edx,abi_sub_rsp_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r14
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
.commit:
 mov [rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET],r12
 mov qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 inc qword [rbx+NEBOC_ABI_ADAPTER_EMITTED_FUNCTIONS_OFFSET]
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov r11d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_ABI_ADAPTER_EMITTED_FUNCTIONS_OFFSET],rax
 mov eax,r11d
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_LIMIT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 jmp .done
.signature:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_SIGNATURE_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.backend:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BACKEND_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.function:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_FUNCTION_MISMATCH
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_adapter_emit_parameter_copy(adapter*, zero_based_parameter_index,
;                                 one_based_local_slot)
NEBOC_ABI_FUNCTION neboc_abi_adapter_emit_parameter_copy
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .state
 mov r14,[rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 cmp r12,[r14+NEBOC_ABI_SIGNATURE_PARAMETER_COUNT_OFFSET]
 jae .parameter
 test r13,r13
 jz .slot
 cmp r13,[r14+NEBOC_ABI_SIGNATURE_LOCAL_SLOT_COUNT_OFFSET]
 ja .slot
 mov r15,[rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov r14,r13
 shl r14,3
 cmp r12,NEBOC_ABI_REGISTER_PARAMETER_COUNT
 jae .stack_parameter
 mov rdi,r15
 lea rsi,[rel abi_mov_slot_prefix]
 mov edx,abi_mov_slot_prefix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r14
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_slot_reg_suffix]
 mov edx,abi_slot_reg_suffix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 lea rax,[rel arg_name_ptrs]
 mov rsi,[rax+r12*8]
 lea rax,[rel arg_name_lengths]
 mov rdx,[rax+r12*8]
 mov rdi,r15
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 jmp .ok
.stack_parameter:
 mov rdi,r15
 lea rsi,[rel abi_mov_stack_prefix]
 mov edx,abi_mov_stack_prefix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rax,r12
 sub rax,NEBOC_ABI_REGISTER_PARAMETER_COUNT
 shl rax,3
 add rax,16
 mov rdi,r15
 mov rsi,rax
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_stack_suffix]
 mov edx,abi_stack_suffix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_mov_slot_prefix]
 mov edx,abi_mov_slot_prefix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r14
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_slot_rax_suffix]
 mov edx,abi_slot_rax_suffix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
.ok:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov r11d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov eax,r11d
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_LIMIT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.slot:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_STACK_SLOT_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_adapter_emit_call(adapter*, callee_function_id, arguments_u64*, count)
NEBOC_ABI_FUNCTION neboc_abi_adapter_emit_call
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .state
 test r12,r12
 jz .call_invalid
 cmp r14,NEBOC_ABI_MAX_PARAMETERS
 ja .limit
 test r14,r14
 jz .args_ok
 test r13,r13
 jz .call_invalid
.args_ok:
 mov r10,[rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 cmp r12,[r10+NEBOC_ABI_SIGNATURE_FUNCTION_ID_OFFSET]
 je .call_invalid
 mov rax,[rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 cmp rax,[r10+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET]
 jae .call_invalid
 mov r15,[rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET]
 mov [rsp+8],rax
 mov rax,[rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 mov [rsp+16],rax
 mov rax,r14
 sub rax,NEBOC_ABI_REGISTER_PARAMETER_COUNT
 jnc .stack_count_ok
 xor eax,eax
.stack_count_ok:
 mov [rsp+24],rax
 mov rdx,rax
 and edx,1
 mov [rsp+32],rdx
 test rdx,rdx
 jz .stack_args
 mov rdi,r15
 lea rsi,[rel abi_sub_rsp]
 mov edx,abi_sub_rsp_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov esi,8
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
.stack_args:
 mov rax,r14
 cmp rax,NEBOC_ABI_REGISTER_PARAMETER_COUNT
 jbe .register_setup
 dec rax
 mov [rsp+40],rax
.stack_loop:
 mov r10,[rsp+40]
 cmp r10,NEBOC_ABI_REGISTER_PARAMETER_COUNT
 jb .register_setup
 mov rdi,r15
 lea rsi,[rel abi_mov_rax]
 mov edx,abi_mov_rax_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov r10,[rsp+40]
 mov rsi,[r13+r10*8]
 mov rdi,r15
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_push_rax]
 mov edx,abi_push_rax_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 dec qword [rsp+40]
 jmp .stack_loop
.register_setup:
 mov rax,r14
 cmp rax,NEBOC_ABI_REGISTER_PARAMETER_COUNT
 jbe .register_count_ok
 mov eax,NEBOC_ABI_REGISTER_PARAMETER_COUNT
.register_count_ok:
 mov [rsp+48],rax
 mov qword [rsp+56],0
.register_loop:
 mov r10,[rsp+56]
 cmp r10,[rsp+48]
 jae .emit_call
 mov rdi,r15
 lea rsi,[rel abi_mov_prefix]
 mov edx,abi_mov_prefix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 ; The writer may clobber caller-saved R10. Reload the canonical loop index.
 mov r10,[rsp+56]
 lea rax,[rel arg_name_ptrs]
 mov rsi,[rax+r10*8]
 lea rax,[rel arg_name_lengths]
 mov rdx,[rax+r10*8]
 mov rdi,r15
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_comma_space]
 mov edx,abi_comma_space_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov r10,[rsp+56]
 mov rsi,[r13+r10*8]
 mov rdi,r15
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 inc qword [rsp+56]
 jmp .register_loop
.emit_call:
 mov rdi,r15
 lea rsi,[rel abi_call_prefix]
 mov edx,abi_call_prefix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rax,[rsp+24]
 shl rax,3
 mov rdx,[rsp+32]
 shl rdx,3
 add rax,rdx
 test rax,rax
 jz .commit
 mov [rsp+56],rax
 mov rdi,r15
 lea rsi,[rel abi_add_rsp]
 mov edx,abi_add_rsp_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
.commit:
 inc qword [rbx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET]
 inc qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov r11d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET],rax
 mov rax,[rsp+16]
 mov [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],rax
 mov eax,r11d
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_LIMIT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 jmp .done
.limit:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.call_invalid:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_CALL_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_adapter_emit_return(adapter*, value)
NEBOC_ABI_FUNCTION neboc_abi_adapter_emit_return
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .state
 mov r13,[rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 mov rax,[rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 cmp rax,[r13+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET]
 jne .call_invalid
 mov r15,[rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov r14,[r13+NEBOC_ABI_SIGNATURE_RETURN_KIND_OFFSET]
 cmp r14,NEBOC_ABI_RETURN_VOID
 je .epilogue
 cmp r14,NEBOC_ABI_RETURN_SCALAR
 je .scalar
 mov rdi,r15
 lea rsi,[rel abi_mov_eax]
 mov edx,abi_mov_eax_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 jmp .value
.scalar:
 mov rdi,r15
 lea rsi,[rel abi_mov_rax]
 mov edx,abi_mov_rax_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
.value:
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
.epilogue:
 mov rdi,r15
 lea rsi,[rel abi_epilogue]
 mov edx,abi_epilogue_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_READY
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov r11d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov eax,r11d
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_LIMIT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 jmp .done
.call_invalid:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_CALL_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_adapter_emit_runtime_thunk(adapter*, runtime_contract_id,
;                                expected_runtime_version)
NEBOC_ABI_FUNCTION neboc_abi_adapter_emit_runtime_thunk
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_READY
 jne .state
 test r12,r12
 jz .call_invalid
 cmp r13,[rbx+NEBOC_ABI_ADAPTER_RUNTIME_VERSION_OFFSET]
 jne .runtime_version
 mov r15,[rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_ABI_ADAPTER_EMITTED_THUNKS_OFFSET]
 mov [rsp+8],rax
 mov rdi,r15
 lea rsi,[rel abi_text_section]
 mov edx,abi_text_section_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_extern_version]
 mov edx,abi_extern_version_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_extern_contract]
 mov edx,abi_extern_contract_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_global_thunk]
 mov edx,abi_global_thunk_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_thunk_label]
 mov edx,abi_thunk_label_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_colon_newline]
 mov edx,abi_colon_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_cmp_runtime]
 mov edx,abi_cmp_runtime_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_jne_mismatch]
 mov edx,abi_jne_mismatch_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_jmp_contract]
 mov edx,abi_jmp_contract_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_mismatch_label]
 mov edx,abi_mismatch_label_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_colon_newline]
 mov edx,abi_colon_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_status_toolchain]
 mov edx,abi_status_toolchain_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 inc qword [rbx+NEBOC_ABI_ADAPTER_EMITTED_THUNKS_OFFSET]
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov r11d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_ABI_ADAPTER_EMITTED_THUNKS_OFFSET],rax
 mov eax,r11d
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_LIMIT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 jmp .done
.runtime_version:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_RUNTIME_VERSION_MISMATCH
 mov eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jmp .done
.call_invalid:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_CALL_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret


; abi_adapter_emit_prepared_call(adapter*, callee_function_id)
; The caller has already evaluated arguments left-to-right and placed them in
; System V AMD64 argument registers. The adapter owns deterministic name
; mangling, call accounting and rollback.
NEBOC_ABI_FUNCTION neboc_abi_adapter_emit_prepared_call
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .state
 test r12,r12
 jz .call_invalid
 mov r13,[rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 cmp r12,[r13+NEBOC_ABI_SIGNATURE_FUNCTION_ID_OFFSET]
 je .call_invalid
 mov rax,[rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 cmp rax,[r13+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET]
 jae .call_invalid
 mov r15,[rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET]
 mov [rsp+8],rax
 mov rax,[rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 mov [rsp+16],rax
 mov rdi,r15
 lea rsi,[rel abi_call_prefix]
 mov edx,abi_call_prefix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel abi_newline]
 mov edx,abi_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 inc qword [rbx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET]
 inc qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov r11d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET],rax
 mov rax,[rsp+16]
 mov [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],rax
 mov eax,r11d
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_LIMIT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 jmp .done
.call_invalid:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_CALL_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; abi_adapter_emit_return_rax(adapter*)
; Preserve the dynamic scalar result already present in RAX and emit only the
; canonical frame epilogue.
NEBOC_ABI_FUNCTION neboc_abi_adapter_emit_return_rax
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .state
 mov r13,[rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 cmp qword [r13+NEBOC_ABI_SIGNATURE_RETURN_KIND_OFFSET],NEBOC_ABI_RETURN_SCALAR
 jne .return_invalid
 mov rax,[rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 cmp rax,[r13+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET]
 jne .call_invalid
 mov r15,[rbx+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rdi,r15
 lea rsi,[rel abi_epilogue]
 mov edx,abi_epilogue_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],0
 mov qword [rbx+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_READY
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov r11d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov eax,r11d
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_LIMIT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_WRITER_NOT_READY
 jmp .done
.return_invalid:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_SIGNATURE_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.call_invalid:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_CALL_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
