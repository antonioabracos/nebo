; Nebo Platform Adapter common contract — MF051
bits 64
default rel

%include "runtime/console/platform/adapter_contract.inc"

global nebo_platform_capabilities_certify
global nebo_platform_window_handle_make
global nebo_platform_window_handle_validate
global nebo_platform_report_init
global nebo_platform_report_certify

section .text

; certify(capabilities, required, out_missing*) -> platform status
nebo_platform_capabilities_certify:
    test rdx, rdx
    jz .cap_invalid
    mov rax, rsi
    not rdi
    and rax, rdi
    mov [rdx], rax
    test rax, rax
    jnz .cap_missing
    mov eax, NEBO_PLATFORM_STATUS_OK
    ret
.cap_missing:
    mov eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    ret
.cap_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    ret

; make(slot:u32, generation:u32, out_handle*) -> platform status
nebo_platform_window_handle_make:
    test rdx, rdx
    jz .handle_invalid
    mov qword [rdx], NEBO_PLATFORM_WINDOW_HANDLE_INVALID
    test edi, edi
    jz .handle_invalid
    test esi, esi
    jz .handle_invalid
    mov eax, edi
    mov ecx, esi
    shl rcx, NEBO_PLATFORM_WINDOW_HANDLE_GENERATION_SHIFT
    or rax, rcx
    mov [rdx], rax
    mov eax, NEBO_PLATFORM_STATUS_OK
    ret
.handle_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    ret

; validate(handle, out_slot*, out_generation*) -> platform status
nebo_platform_window_handle_validate:
    test rsi, rsi
    jz .validate_invalid
    test rdx, rdx
    jz .validate_invalid
    mov dword [rsi], 0
    mov dword [rdx], 0
    test rdi, rdi
    jz .validate_invalid
    mov eax, edi
    test eax, eax
    jz .validate_invalid
    mov [rsi], eax
    mov rax, rdi
    shr rax, NEBO_PLATFORM_WINDOW_HANDLE_GENERATION_SHIFT
    test eax, eax
    jz .validate_invalid
    mov [rdx], eax
    mov eax, NEBO_PLATFORM_STATUS_OK
    ret
.validate_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    ret

; report_init(report*, adapter_id_hash, capabilities, scale_26_6, flags)
nebo_platform_report_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    test r12, r12
    jz .report_init_invalid
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_PLATFORM_REPORT_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .report_init_invalid_after_zero
    test r14, r14
    jz .report_init_invalid_after_zero
    test r15, r15
    jz .report_init_invalid_after_zero
    mov [r12+NEBO_PLATFORM_REPORT_ADAPTER_ID_HASH_OFFSET], r13
    mov dword [r12+NEBO_PLATFORM_REPORT_ABI_VERSION_OFFSET], NEBO_PLATFORM_ADAPTER_ABI_VERSION
    mov dword [r12+NEBO_PLATFORM_REPORT_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    mov [r12+NEBO_PLATFORM_REPORT_CAPABILITIES_OFFSET], r14
    mov qword [r12+NEBO_PLATFORM_REPORT_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov qword [r12+NEBO_PLATFORM_REPORT_MISSING_CAPABILITIES_OFFSET], 0
    mov [r12+NEBO_PLATFORM_REPORT_SCALE_FACTOR_OFFSET], r15
    mov [r12+NEBO_PLATFORM_REPORT_FLAGS_OFFSET], rbx
    mov qword [r12+NEBO_PLATFORM_REPORT_NATIVE_HANDLE_LEAKS_OFFSET], 0
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .report_init_done
.report_init_invalid_after_zero:
.report_init_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.report_init_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; report_certify(report*) -> platform status
nebo_platform_report_certify:
    push r12
    mov r12, rdi
    test r12, r12
    jz .report_invalid
    cmp dword [r12+NEBO_PLATFORM_REPORT_ABI_VERSION_OFFSET], NEBO_PLATFORM_ADAPTER_ABI_VERSION
    jne .report_state
    cmp dword [r12+NEBO_PLATFORM_REPORT_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    jne .report_state
    cmp qword [r12+NEBO_PLATFORM_REPORT_ADAPTER_ID_HASH_OFFSET], 0
    je .report_state
    cmp qword [r12+NEBO_PLATFORM_REPORT_SCALE_FACTOR_OFFSET], 0
    je .report_state
    cmp qword [r12+NEBO_PLATFORM_REPORT_NATIVE_HANDLE_LEAKS_OFFSET], 0
    jne .report_state
    mov rax, [r12+NEBO_PLATFORM_REPORT_FLAGS_OFFSET]
    and rax, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    cmp rax, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    jne .report_state
    mov rdi, [r12+NEBO_PLATFORM_REPORT_CAPABILITIES_OFFSET]
    mov rsi, [r12+NEBO_PLATFORM_REPORT_REQUIRED_CAPABILITIES_OFFSET]
    lea rdx, [r12+NEBO_PLATFORM_REPORT_MISSING_CAPABILITIES_OFFSET]
    call nebo_platform_capabilities_certify
    jmp .report_done
.report_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .report_done
.report_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.report_done:
    pop r12
    ret
