; Nebo Console native normalized input bridge — MF053
bits 64
default rel

%include "runtime/console/platform/input/native_input_bridge.inc"

extern nebo_focus_manager_validate
extern nebo_focus_manager_set_window_active
extern nebo_focus_manager_pointer_down
extern nebo_focus_manager_text_input
extern nebo_focus_manager_key
extern nebo_input_submission_validate
extern nebo_input_submission_key

global nebo_native_input_bridge_init
global nebo_native_input_bridge_validate
global nebo_native_input_bridge_dispatch
global nebo_native_input_bridge_state_hash

section .text

native_input_set_result_internal:
    test rdi, rdi
    jz .result_done
    mov [rdi+NEBO_NATIVE_INPUT_BRIDGE_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_NATIVE_INPUT_BRIDGE_LAST_ERROR_OFFSET], rdx
.result_done:
    mov eax, esi
    ret

; init(bridge*, focus_manager*, submission_context*, scale26.6) -> status
nebo_native_input_bridge_init:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rbx, rcx
    test r12, r12
    jz .init_invalid_direct
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_NATIVE_INPUT_BRIDGE_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .init_invalid
    test r14, r14
    jz .init_invalid
    cmp rbx, 32
    jb .init_invalid
    cmp rbx, 256
    ja .init_invalid
    mov rdi, r13
    call nebo_focus_manager_validate
    test eax, eax
    jnz .init_state
    mov rdi, r14
    call nebo_input_submission_validate
    test eax, eax
    jnz .init_state
    mov [r12+NEBO_NATIVE_INPUT_BRIDGE_FOCUS_MANAGER_PTR_OFFSET], r13
    mov [r12+NEBO_NATIVE_INPUT_BRIDGE_SUBMISSION_PTR_OFFSET], r14
    mov [r12+NEBO_NATIVE_INPUT_BRIDGE_SCALE_FACTOR_OFFSET], rbx
    mov qword [r12+NEBO_NATIVE_INPUT_BRIDGE_FLAGS_OFFSET], NEBO_NATIVE_INPUT_BRIDGE_REQUIRED_FLAGS
    mov eax, NEBO_NATIVE_INPUT_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_NATIVE_INPUT_BRIDGE_STATE_HASH_OFFSET], rax
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    call native_input_set_result_internal
    jmp .init_done
.init_state:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_NATIVE_INPUT_ERROR_BAD_STATE
    call native_input_set_result_internal
    jmp .init_done
.init_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_NATIVE_INPUT_ERROR_BAD_ARGUMENT
    call native_input_set_result_internal
    jmp .init_done
.init_invalid_direct:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.init_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_native_input_bridge_validate:
    push r12
    mov r12, rdi
    test r12, r12
    jz .validate_invalid
    cmp qword [r12+NEBO_NATIVE_INPUT_BRIDGE_FOCUS_MANAGER_PTR_OFFSET], 0
    je .validate_state
    cmp qword [r12+NEBO_NATIVE_INPUT_BRIDGE_SUBMISSION_PTR_OFFSET], 0
    je .validate_state
    mov rax, [r12+NEBO_NATIVE_INPUT_BRIDGE_SCALE_FACTOR_OFFSET]
    cmp rax, 32
    jb .validate_state
    cmp rax, 256
    ja .validate_state
    mov rax, [r12+NEBO_NATIVE_INPUT_BRIDGE_FLAGS_OFFSET]
    and eax, NEBO_NATIVE_INPUT_BRIDGE_REQUIRED_FLAGS
    cmp eax, NEBO_NATIVE_INPUT_BRIDGE_REQUIRED_FLAGS
    jne .validate_state
    mov rdi, [r12+NEBO_NATIVE_INPUT_BRIDGE_FOCUS_MANAGER_PTR_OFFSET]
    call nebo_focus_manager_validate
    test eax, eax
    jnz .validate_state
    mov rdi, [r12+NEBO_NATIVE_INPUT_BRIDGE_SUBMISSION_PTR_OFFSET]
    call nebo_input_submission_validate
    test eax, eax
    jnz .validate_state
    xor eax, eax
    jmp .validate_done
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .validate_done
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.validate_done:
    pop r12
    ret

; Scale a signed physical 26.6 coordinate to logical 26.6.
; RAX=value, RCX=scale factor -> RAX=logical value.
native_input_scale_coordinate_internal:
    imul rax, NEBO_PLATFORM_SCALE_ONE
    cqo
    idiv rcx
    ret

; dispatch(bridge*, PlatformEventDescriptor*, submission_result*) -> status
nebo_native_input_bridge_dispatch:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 24
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_native_input_bridge_validate
    test eax, eax
    jnz .dispatch_done
    test r13, r13
    jz .dispatch_invalid
    mov ebx, [r13+NEBO_CONSOLE_EVENT_KIND_OFFSET]
    cmp ebx, NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
    je .dispatch_activated
    cmp ebx, NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
    je .dispatch_deactivated
    cmp ebx, NEBO_CONSOLE_EVENT_POINTER_DOWN
    je .dispatch_pointer_down
    cmp ebx, NEBO_CONSOLE_EVENT_POINTER_MOVE
    je .dispatch_observe_pointer
    cmp ebx, NEBO_CONSOLE_EVENT_POINTER_UP
    je .dispatch_observe_pointer
    cmp ebx, NEBO_CONSOLE_EVENT_KEY_DOWN
    je .dispatch_key_down
    cmp ebx, NEBO_CONSOLE_EVENT_KEY_UP
    je .dispatch_observe_key
    cmp ebx, NEBO_CONSOLE_EVENT_TEXT_INPUT
    je .dispatch_text
    mov eax, NEBO_CONSOLE_STATUS_NO_PROGRESS
    mov edx, NEBO_NATIVE_INPUT_ERROR_EVENT_KIND
    jmp .dispatch_publish
.dispatch_activated:
    mov rdi, [r12+NEBO_NATIVE_INPUT_BRIDGE_FOCUS_MANAGER_PTR_OFFSET]
    mov esi, 1
    call nebo_focus_manager_set_window_active
    jmp .dispatch_after_call
.dispatch_deactivated:
    mov rdi, [r12+NEBO_NATIVE_INPUT_BRIDGE_FOCUS_MANAGER_PTR_OFFSET]
    xor esi, esi
    call nebo_focus_manager_set_window_active
    jmp .dispatch_after_call
.dispatch_pointer_down:
    mov rax, [r13+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
    movzx edx, ax
    cmp edx, NEBO_PLATFORM_POINTER_BUTTON_PRIMARY
    jne .dispatch_pointer_button
    mov rax, [r13+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    movsxd r15, eax
    sar rax, 32
    mov rbp, rax
    mov rcx, [r12+NEBO_NATIVE_INPUT_BRIDGE_SCALE_FACTOR_OFFSET]
    mov rax, r15
    call native_input_scale_coordinate_internal
    mov r15, rax
    mov rcx, [r12+NEBO_NATIVE_INPUT_BRIDGE_SCALE_FACTOR_OFFSET]
    mov rax, rbp
    call native_input_scale_coordinate_internal
    mov rdx, rax
    mov rsi, r15
    mov rdi, [r12+NEBO_NATIVE_INPUT_BRIDGE_FOCUS_MANAGER_PTR_OFFSET]
    call nebo_focus_manager_pointer_down
    test eax, eax
    jnz .dispatch_after_call
    inc qword [r12+NEBO_NATIVE_INPUT_BRIDGE_POINTER_COUNT_OFFSET]
    jmp .dispatch_success
.dispatch_pointer_button:
    mov eax, NEBO_CONSOLE_STATUS_NO_PROGRESS
    mov edx, NEBO_NATIVE_INPUT_ERROR_POINTER_BUTTON
    jmp .dispatch_publish
.dispatch_observe_pointer:
    inc qword [r12+NEBO_NATIVE_INPUT_BRIDGE_POINTER_COUNT_OFFSET]
    jmp .dispatch_success
.dispatch_key_down:
    mov eax, [r13+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    mov ebp, eax
    mov eax, [r13+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
    mov r15d, eax
    cmp ebp, NEBO_PLATFORM_KEY_UNMAPPED
    je .dispatch_observe_key
    cmp ebp, NEBO_PLATFORM_KEY_TAB
    jne .dispatch_key_enter
    mov esi, NEBO_FOCUS_KEY_TAB
    test r15d, NEBO_PLATFORM_MOD_SHIFT
    jz .dispatch_focus_key
    mov esi, NEBO_FOCUS_KEY_SHIFT_TAB
    jmp .dispatch_focus_key
.dispatch_key_enter:
    cmp ebp, NEBO_PLATFORM_KEY_ENTER
    jne .dispatch_key_edit
    test r14, r14
    jz .dispatch_invalid
    mov rdi, [r12+NEBO_NATIVE_INPUT_BRIDGE_SUBMISSION_PTR_OFFSET]
    mov esi, NEBO_FOCUS_KEY_ENTER
    mov rdx, r14
    call nebo_input_submission_key
    test eax, eax
    jnz .dispatch_after_call
    inc qword [r12+NEBO_NATIVE_INPUT_BRIDGE_ENTER_COUNT_OFFSET]
    jmp .dispatch_observe_key
.dispatch_key_edit:
    cmp ebp, NEBO_PLATFORM_KEY_DELETE
    ja .dispatch_observe_key
    mov esi, ebp
.dispatch_focus_key:
    mov rdi, [r12+NEBO_NATIVE_INPUT_BRIDGE_FOCUS_MANAGER_PTR_OFFSET]
    call nebo_focus_manager_key
    test eax, eax
    jnz .dispatch_after_call
.dispatch_observe_key:
    inc qword [r12+NEBO_NATIVE_INPUT_BRIDGE_KEY_COUNT_OFFSET]
    jmp .dispatch_success
.dispatch_text:
    mov rdx, [r13+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
    test rdx, rdx
    jz .dispatch_text_length
    cmp rdx, 4
    ja .dispatch_text_length
    mov rax, [r13+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    mov [rsp], rax
    lea rsi, [rsp]
    mov rdi, [r12+NEBO_NATIVE_INPUT_BRIDGE_FOCUS_MANAGER_PTR_OFFSET]
    call nebo_focus_manager_text_input
    test eax, eax
    jnz .dispatch_after_call
    inc qword [r12+NEBO_NATIVE_INPUT_BRIDGE_TEXT_COUNT_OFFSET]
    jmp .dispatch_success
.dispatch_text_length:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_NATIVE_INPUT_ERROR_TEXT_LENGTH
    jmp .dispatch_publish
.dispatch_after_call:
    test eax, eax
    jz .dispatch_success
    mov edx, NEBO_NATIVE_INPUT_ERROR_DISPATCH
    jmp .dispatch_publish
.dispatch_success:
    inc qword [r12+NEBO_NATIVE_INPUT_BRIDGE_EVENT_COUNT_OFFSET]
    mov rdi, r12
    lea rsi, [r12+NEBO_NATIVE_INPUT_BRIDGE_STATE_HASH_OFFSET]
    call nebo_native_input_bridge_state_hash
    xor eax, eax
    xor edx, edx
.dispatch_publish:
    mov rdi, r12
    mov esi, eax
    call native_input_set_result_internal
    jmp .dispatch_done
.dispatch_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_NATIVE_INPUT_ERROR_BAD_ARGUMENT
    call native_input_set_result_internal
.dispatch_done:
    add rsp, 24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

nebo_native_input_bridge_state_hash:
    test rdi, rdi
    jz .hash_invalid
    test rsi, rsi
    jz .hash_invalid
    sub rsp, 8
    mov eax, NEBO_NATIVE_INPUT_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [rdi+NEBO_NATIVE_INPUT_BRIDGE_EVENT_COUNT_OFFSET]
    call .mix
    mov rdx, [rdi+NEBO_NATIVE_INPUT_BRIDGE_POINTER_COUNT_OFFSET]
    call .mix
    mov rdx, [rdi+NEBO_NATIVE_INPUT_BRIDGE_KEY_COUNT_OFFSET]
    call .mix
    mov rdx, [rdi+NEBO_NATIVE_INPUT_BRIDGE_TEXT_COUNT_OFFSET]
    call .mix
    mov rdx, [rdi+NEBO_NATIVE_INPUT_BRIDGE_ENTER_COUNT_OFFSET]
    call .mix
    mov [rsi], rax
    mov [rdi+NEBO_NATIVE_INPUT_BRIDGE_STATE_HASH_OFFSET], rax
    xor eax, eax
    add rsp, 8
    ret
.hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret
.mix:
    push rcx
    mov ecx, 8
.mix_byte:
    xor al, dl
    imul eax, eax, NEBO_NATIVE_INPUT_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
