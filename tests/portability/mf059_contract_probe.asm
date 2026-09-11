; Nebo Assembly — MF059 portability contract probe
; Linux-hosted proof fixture only. It does not emit or execute Win64/PECOFF code.
bits 64
default rel

%include "compiler/target/target_context.inc"
%include "compiler/target/proofs/x86_64-win64-pecoff-windows/target_proof.inc"
%include "runtime/console/platform/adapter_contract.inc"
%include "runtime/console/platform/win32-contract-proof/win32_adapter_proof.inc"

extern nebo_platform_window_handle_make
extern nebo_platform_window_handle_validate
extern neboc_host_process_exit

global _start

%if NEBO_MF059_PROOF_CONTRACT_SKELETON_ONLY != 1
    %error "MF059 proof must remain contract-skeleton only"
%endif
%if NEBO_MF059_PROOF_NATIVE_EXECUTION_PRESENT != 0
    %error "MF059 cannot claim native Win64 execution"
%endif
%if NEBO_MF059_PROOF_TARGET_SUPPORT_CERTIFIED != 0
    %error "MF059 cannot certify Win64 target support"
%endif
%if NEBO_MF059_PROOF_BUILD_INTEGRATION_PRESENT != 0
    %error "MF059 proof cannot enter the product build"
%endif
%if NEBO_MF059_PROOF_EXTERNAL_ABI_WIN64 = NEBOC_TARGET_ABI_SYSTEMV_AMD64
    %error "Win64 proof ABI must remain distinct from System V"
%endif
%if NEBO_MF059_PROOF_OBJECT_FORMAT_PECOFF = NEBOC_TARGET_FORMAT_ELF64
    %error "PECOFF proof format must remain distinct from ELF64"
%endif
%if NEBO_MF059_PROOF_ENVIRONMENT_WINDOWS = NEBOC_TARGET_ENV_LINUX
    %error "Windows proof environment must remain distinct from Linux"
%endif
%if NEBO_MF059_PROOF_POINTER_SIZE != 8
    %error "Win64 proof pointer size"
%endif
%if NEBO_MF059_PROOF_STACK_ALIGNMENT != 16
    %error "Win64 proof stack alignment"
%endif
%if NEBO_MF059_PROOF_REGISTER_PARAMETER_COUNT != 4
    %error "Win64 proof register parameter count"
%endif
%if NEBO_MF059_PROOF_SHADOW_SPACE_BYTES != 32
    %error "Win64 proof shadow space"
%endif
%if NEBO_MF059_PROOF_RED_ZONE_BYTES != 0
    %error "Win64 proof red zone"
%endif
%if NEBO_WIN32_PROOF_PLATFORM_ABI_VERSION != NEBO_PLATFORM_ADAPTER_ABI_VERSION
    %error "Win32 proof must consume common adapter ABI"
%endif
%if NEBO_WIN32_PROOF_REQUIRED_CAPABILITIES != NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    %error "Win32 proof capability contract diverged"
%endif
%if NEBO_WIN32_PROOF_NATIVE_IMPLEMENTATION_PRESENT != 0
    %error "Win32 native implementation is outside MF059"
%endif
%if NEBO_WIN32_PROOF_SUPPORT_CERTIFIED != 0
    %error "Win32 support is not certified"
%endif
%if NEBO_WIN32_PROOF_HANDLE_GENERATION_SHIFT != NEBO_PLATFORM_WINDOW_HANDLE_GENERATION_SHIFT
    %error "Win32 proof handle generation shape diverged"
%endif
%if NEBO_WIN32_PROOF_EVENT_WINDOW_MOUNTED != NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    %error "Win32 mounted event semantic fork"
%endif
%if NEBO_WIN32_PROOF_EVENT_WINDOW_RESIZED != NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    %error "Win32 resize event semantic fork"
%endif
%if NEBO_WIN32_PROOF_EVENT_WINDOW_ACTIVATED != NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
    %error "Win32 activation event semantic fork"
%endif
%if NEBO_WIN32_PROOF_EVENT_WINDOW_CLOSE_REQUESTED != NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    %error "Win32 close event semantic fork"
%endif
%if NEBO_WIN32_PROOF_EVENT_POINTER_MOVE != NEBO_CONSOLE_EVENT_POINTER_MOVE
    %error "Win32 pointer event semantic fork"
%endif
%if NEBO_WIN32_PROOF_EVENT_KEY_DOWN != NEBO_CONSOLE_EVENT_KEY_DOWN
    %error "Win32 key event semantic fork"
%endif
%if NEBO_WIN32_PROOF_EVENT_TEXT_INPUT != NEBO_CONSOLE_EVENT_TEXT_INPUT
    %error "Win32 text event semantic fork"
%endif

section .bss align=16
proof_handle: resq 1
proof_slot: resd 1
proof_generation: resd 1

section .text
_start:
    cmp qword [rsp], 2
    jne test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_usage
    cmp byte [rbx], '1'
    je scenario_abi_contract
    cmp byte [rbx], '2'
    je scenario_platform_contract
    cmp byte [rbx], '3'
    je scenario_semantic_equivalence
    cmp byte [rbx], '4'
    je scenario_generation_shape
    jmp test_usage

scenario_abi_contract:
    mov eax, NEBO_MF059_PROOF_STATE_PLAN_ONLY
    cmp eax, 1
    jne test_fail
    mov eax, NEBO_MF059_PROOF_POINTER_SIZE
    cmp eax, 8
    jne test_fail
    mov eax, NEBO_MF059_PROOF_INT_SIZE
    cmp eax, 8
    jne test_fail
    mov eax, NEBO_MF059_PROOF_BOOL_SIZE
    cmp eax, 1
    jne test_fail
    mov eax, NEBO_MF059_PROOF_STACK_ALIGNMENT
    cmp eax, 16
    jne test_fail
    mov eax, NEBO_MF059_PROOF_SHADOW_SPACE_BYTES
    cmp eax, 32
    jne test_fail
    jmp test_pass

scenario_platform_contract:
    mov rax, NEBO_WIN32_PROOF_ADAPTER_ID_HASH
    test rax, rax
    jz test_fail
    mov eax, NEBO_WIN32_PROOF_REQUIRED_CAPABILITIES
    cmp eax, NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    jne test_fail
    mov eax, NEBO_WIN32_PROOF_NATIVE_HANDLE_PUBLIC_LEAKS
    test eax, eax
    jnz test_fail
    mov eax, NEBO_WIN32_PROOF_NATIVE_VALIDATION_PERFORMED
    test eax, eax
    jnz test_fail
    mov eax, NEBO_WIN32_PROOF_SUPPORT_CERTIFIED
    test eax, eax
    jnz test_fail
    jmp test_pass

scenario_semantic_equivalence:
    mov eax, NEBO_WIN32_PROOF_EVENT_NORMALIZATION_COUNT
    cmp eax, 10
    jne test_fail
    mov eax, NEBO_WIN32_PROOF_EVENT_WINDOW_CLOSE_REQUESTED
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    jne test_fail
    mov eax, NEBO_WIN32_PROOF_EVENT_POINTER_DOWN
    cmp eax, NEBO_CONSOLE_EVENT_POINTER_DOWN
    jne test_fail
    mov eax, NEBO_WIN32_PROOF_EVENT_KEY_UP
    cmp eax, NEBO_CONSOLE_EVENT_KEY_UP
    jne test_fail
    mov eax, NEBO_WIN32_PROOF_EVENT_TEXT_INPUT
    cmp eax, NEBO_CONSOLE_EVENT_TEXT_INPUT
    jne test_fail
    jmp test_pass

scenario_generation_shape:
    mov edi, 7
    mov esi, 3
    lea rdx, [rel proof_handle]
    call nebo_platform_window_handle_make
    test eax, eax
    jnz test_fail
    mov rdi, [rel proof_handle]
    lea rsi, [rel proof_slot]
    lea rdx, [rel proof_generation]
    call nebo_platform_window_handle_validate
    test eax, eax
    jnz test_fail
    cmp dword [rel proof_slot], 7
    jne test_fail
    cmp dword [rel proof_generation], 3
    jne test_fail
    mov rax, [rel proof_handle]
    shr rax, NEBO_PLATFORM_WINDOW_HANDLE_GENERATION_SHIFT
    cmp eax, 3
    jne test_fail
    jmp test_pass

test_usage:
    mov edi, 2
    call neboc_host_process_exit

test_fail:
    mov edi, 1
    call neboc_host_process_exit

test_pass:
    xor edi, edi
    call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
