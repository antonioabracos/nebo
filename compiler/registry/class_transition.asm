; G146 Registry class/state change control.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/registry/lifecycle.inc"

section .text

; RegistryTransition(request*, out*).  Failed policy checks preserve out.
NEBOC_ABI_FUNCTION neboc_registry_transition_validate
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdi,7
    jnz .invalid
    test rsi,7
    jnz .invalid
    ; Exact in-place publication is valid, but a partial overlap could corrupt
    ; the request while rep movsq is still consuming it.
    cmp rdi,rsi
    je .buffers_valid
    mov rax,rdi
    add rax,NEBOC_REGISTRY_TRANSITION_SIZE
    jc .invalid
    cmp rsi,rax
    jae .buffers_valid
    mov rax,rsi
    add rax,NEBOC_REGISTRY_TRANSITION_SIZE
    jc .invalid
    cmp rdi,rax
    jb .invalid
.buffers_valid:
    mov r8,[rdi+NEBOC_REGISTRY_TRANSITION_FROM_CLASS_OFFSET]
    mov r9,[rdi+NEBOC_REGISTRY_TRANSITION_TO_CLASS_OFFSET]
    cmp r8,NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON
    jb .invalid
    cmp r8,NEBOC_OPERATOR_CLASS_REJECTED
    ja .invalid
    cmp r9,NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON
    jb .invalid
    cmp r9,NEBOC_OPERATOR_CLASS_REJECTED
    ja .invalid
    mov r10,[rdi+NEBOC_REGISTRY_TRANSITION_FROM_STATE_OFFSET]
    mov r11,[rdi+NEBOC_REGISTRY_TRANSITION_TO_STATE_OFFSET]
    cmp r10,NEBOC_OPERATOR_STATE_ACTIVE_CURRENT
    jb .invalid
    cmp r10,NEBOC_OPERATOR_STATE_REJECTED_OUTSIDE_TEMPLATE
    ja .invalid
    cmp r11,NEBOC_OPERATOR_STATE_ACTIVE_CURRENT
    jb .invalid
    cmp r11,NEBOC_OPERATOR_STATE_REJECTED_OUTSIDE_TEMPLATE
    ja .invalid
    mov rcx,[rdi+NEBOC_REGISTRY_TRANSITION_FROM_VERSION_OFFSET]
    mov rdx,[rdi+NEBOC_REGISTRY_TRANSITION_TO_VERSION_OFFSET]
    test rcx,rcx
    jz .invalid
    mov rax,[rdi+NEBOC_REGISTRY_TRANSITION_FLAGS_OFFSET]
    test rax,~NEBOC_REGISTRY_TRANSITION_FLAG_ALL
    jnz .invalid
    cmp rdx,rcx
    jb .denied
    je .version_bounded
    mov rax,rcx
    add rax,1
    jc .denied
    cmp rdx,rax
    ja .denied
.version_bounded:
    ; RESERVED cannot become executable without an explicit class change.
    cmp r9,NEBOC_OPERATOR_CLASS_RESERVED
    jne .check_rejected_target
    cmp r11,NEBOC_OPERATOR_STATE_ACTIVE_CURRENT
    je .denied
    cmp r11,NEBOC_OPERATOR_STATE_PARTIAL_ACTIVE_CURRENT
    je .denied
.check_rejected_target:
    cmp r9,NEBOC_OPERATOR_CLASS_REJECTED
    jne .check_non_rejected_target
    cmp r11,NEBOC_OPERATOR_STATE_REJECTED_PERMANENT
    jb .denied
    jmp .terminal_source
.check_non_rejected_target:
    cmp r11,NEBOC_OPERATOR_STATE_REJECTED_PERMANENT
    jae .denied
.terminal_source:
    ; REJECTED class/state is terminal and cannot be silently rehabilitated.
    cmp r8,NEBOC_OPERATOR_CLASS_REJECTED
    je .require_noop
    cmp r10,NEBOC_OPERATOR_STATE_REJECTED_PERMANENT
    jae .require_noop
    jmp .change_control
.require_noop:
    cmp r8,r9
    jne .denied
    cmp r10,r11
    jne .denied
.change_control:
    cmp r8,r9
    jne .changed
    cmp r10,r11
    jne .changed
    cmp rdx,rcx
    jne .changed
    jmp .publish
.changed:
    mov rax,[rdi+NEBOC_REGISTRY_TRANSITION_APPROVAL_OFFSET]
    test rax,rax
    jz .denied
    mov rax,[rdi+NEBOC_REGISTRY_TRANSITION_FLAGS_OFFSET]
    and eax,NEBOC_REGISTRY_TRANSITION_FLAG_ALL
    cmp eax,NEBOC_REGISTRY_TRANSITION_FLAG_ALL
    jne .denied
    mov rax,rcx
    add rax,1
    jc .denied
    cmp rdx,rax
    jne .denied
.publish:
    mov rdx,rsi
    mov rsi,rdi
    mov rdi,rdx
    mov rcx,NEBOC_REGISTRY_TRANSITION_SIZE/8
    rep movsq
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Bounded compatibility wrapper retained for existing internal callers.
NEBOC_ABI_FUNCTION nebo_registry_class_transition
    cmp edi,NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON
    jb .legacy_invalid
    cmp edi,NEBOC_OPERATOR_CLASS_REJECTED
    ja .legacy_invalid
    cmp esi,NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON
    jb .legacy_invalid
    cmp esi,NEBOC_OPERATOR_CLASS_REJECTED
    ja .legacy_invalid
    cmp edi,esi
    je .legacy_ok
    cmp edi,NEBOC_OPERATOR_CLASS_REJECTED
    je .legacy_denied
    cmp edx,1
    jne .legacy_denied
.legacy_ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.legacy_denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.legacy_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
