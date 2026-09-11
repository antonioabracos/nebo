; G092 source-to-effect probes over target-independent style token owners.
bits 64
default rel
%define NEBO_G092_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/text_style_source_probe.inc"
%include "runtime/style_tokens.inc"
%include "runtime/color_roles.inc"
%include "runtime/color_target.inc"

extern nebo_style_core_decorations
extern nebo_style_optional_effects
extern nebo_style_registry_validate
extern nebo_style_status_validate
extern nebo_style_colors_validate
extern nebo_style_font_resolve
extern nebo_style_fallback_resolve
extern nebo_style_accessibility_validate
extern nebo_style_plan_validate

global nebo_g092_source_probe
global nebo_g092_negative_probe

section .rodata
g92_label: times 255 db 'S'
g92_description: db 'state'

section .bss align=16
g92_request: resb 128
g92_result: resb 128
g92_tokens: resb NEBO_STYLE_MAX_TOKEN_ID * NEBO_STYLE_TOKEN_SIZE
g92_core: resb NEBO_STYLE_FRAGMENT_SIZE
g92_optional: resb NEBO_STYLE_FRAGMENT_SIZE
g92_status: resb NEBO_STATUS_SIZE
g92_colors: resb NEBO_STYLE_COLORS_SIZE
g92_font: resb NEBO_FONT_SIZE
g92_fallback: resb NEBO_FALLBACK_SIZE
g92_a11y: resb NEBO_A11Y_SIZE
g92_plan: resb NEBO_STYLE_PLAN_SIZE
g92_receipt: resb NEBO_STYLE_RECEIPT_SIZE

section .text
; EDI=mode 1..9, ESI=source-derived value -> EAX=owner-published observation.
nebo_g092_source_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    mov ebx, esi
    test ebx, ebx
    jz .failure
    cmp ebx, 255
    ja .failure
    lea rdi, [rel g92_request]
    mov ecx, 16
    xor eax, eax
    cld
    rep stosq
    lea rdi, [rel g92_result]
    mov ecx, 16
    xor eax, eax
    rep stosq
    cmp r12d, 1
    je .core_mode
    cmp r12d, 2
    je .optional_mode
    cmp r12d, 3
    je .registry_mode
    cmp r12d, 4
    je .status_mode
    cmp r12d, 5
    je .colors_mode
    cmp r12d, 6
    je .font_mode
    cmp r12d, 7
    je .fallback_mode
    cmp r12d, 8
    je .a11y_mode
    cmp r12d, 9
    je .plan_mode
    jmp .failure

.core_mode:
    mov edi, ebx
    lea rsi, [rel g92_result]
    call nebo_style_core_decorations
    test eax, eax
    jnz .failure
    mov eax, [rel g92_result + NEBO_STYLE_FRAGMENT_VALUE_OFFSET]
    jmp .verify

.optional_mode:
    mov edi, ebx
    mov esi, NEBO_STYLE_CAP_DIM
    lea rdx, [rel g92_result]
    call nebo_style_optional_effects
    test eax, eax
    jnz .failure
    mov eax, [rel g92_result + NEBO_STYLE_FRAGMENT_VALUE_OFFSET]
    or eax, [rel g92_result + NEBO_STYLE_FRAGMENT_AUX_OFFSET]
    jmp .verify

.registry_mode:
    cmp ebx, NEBO_STYLE_MAX_TOKEN_ID
    ja .failure
    lea rdi, [rel g92_tokens]
    mov ecx, NEBO_STYLE_MAX_TOKEN_ID * NEBO_STYLE_TOKEN_SIZE / 8
    xor eax, eax
    rep stosq
    xor ecx, ecx
.registry_fill:
    cmp ecx, ebx
    jae .registry_ready
    mov eax, ecx
    shl rax, 5
    lea rdi, [rel g92_tokens]
    add rdi, rax
    mov eax, ecx
    inc eax
    mov [rdi + NEBO_STYLE_TOKEN_ID_OFFSET], rax
    mov qword [rdi + NEBO_STYLE_TOKEN_DECORATIONS_OFFSET], NEBO_STYLE_BOLD
    mov qword [rdi + NEBO_STYLE_TOKEN_EFFECTS_OFFSET], 0
    mov qword [rdi + NEBO_STYLE_TOKEN_ROLE_OFFSET], NEBO_ROLE_FOREGROUND
    inc ecx
    jmp .registry_fill
.registry_ready:
    lea rax, [rel g92_tokens]
    mov [rel g92_request + NEBO_STYLE_REGISTRY_ENTRIES_OFFSET], rax
    mov [rel g92_request + NEBO_STYLE_REGISTRY_COUNT_OFFSET], rbx
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_registry_validate
    test eax, eax
    jnz .failure
    mov eax, [rel g92_result + NEBO_STYLE_REGISTRY_RECEIPT_COUNT_OFFSET]
    jmp .verify

.status_mode:
    mov qword [rel g92_request + NEBO_STATUS_KIND_OFFSET], NEBO_STATUS_INFO
    lea rax, [rel g92_label]
    mov [rel g92_request + NEBO_STATUS_LABEL_OFFSET], rax
    mov qword [rel g92_request + NEBO_STATUS_LABEL_LENGTH_OFFSET], 1
    mov [rel g92_request + NEBO_STATUS_FALLBACK_CHAR_OFFSET], rbx
    mov qword [rel g92_request + NEBO_STATUS_COLOR_ROLE_OFFSET], NEBO_ROLE_ACCENT
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_status_validate
    test eax, eax
    jnz .failure
    mov eax, [rel g92_result + NEBO_STATUS_FALLBACK_CHAR_OFFSET]
    jmp .verify

.colors_mode:
    mov eax, ebx
    or rax, 0x10203000
    mov [rel g92_request + NEBO_STYLE_COLORS_FOREGROUND_OFFSET], rax
    mov qword [rel g92_request + NEBO_STYLE_COLORS_PRESENT_OFFSET], NEBO_STYLE_COLOR_FOREGROUND
    mov qword [rel g92_request + NEBO_STYLE_COLORS_TARGET_OFFSET], NEBO_COLOR_TARGET_ANSI
    mov qword [rel g92_request + NEBO_STYLE_COLORS_CAPABILITIES_OFFSET], NEBO_COLOR_CAP_ALPHA | NEBO_COLOR_CAP_TRUECOLOR
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_colors_validate
    test eax, eax
    jnz .failure
    mov eax, [rel g92_result + NEBO_STYLE_COLORS_FOREGROUND_OFFSET]
    and eax, 255
    jmp .verify

.font_mode:
    mov qword [rel g92_request + NEBO_FONT_ID_OFFSET], 7
    mov [rel g92_request + NEBO_FONT_SIZE_OFFSET], rbx
    mov qword [rel g92_request + NEBO_FONT_TARGET_OFFSET], NEBO_COLOR_TARGET_HEADLESS
    mov qword [rel g92_request + NEBO_FONT_CAPABILITIES_OFFSET], 0
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_font_resolve
    test eax, eax
    jnz .failure
    cmp qword [rel g92_result + NEBO_FONT_FALLBACK_OFFSET], NEBO_FONT_FALLBACK_TARGET_DEFAULT
    jne .failure
    mov eax, [rel g92_result + NEBO_FONT_SIZE_OFFSET]
    jmp .verify

.fallback_mode:
    mov [rel g92_request + NEBO_FALLBACK_PROFILE_OFFSET], rbx
    mov qword [rel g92_request + NEBO_FALLBACK_EFFECTS_OFFSET], NEBO_STYLE_DIM | NEBO_STYLE_BLINK
    mov qword [rel g92_request + NEBO_FALLBACK_COLOR_PRESENT_OFFSET], 1
    mov qword [rel g92_request + NEBO_FALLBACK_CAPABILITIES_OFFSET], 0
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_fallback_resolve
    test eax, eax
    jnz .failure
    cmp qword [rel g92_result + NEBO_FALLBACK_COLOR_ENABLED_OFFSET], 0
    jne .failure
    mov eax, [rel g92_result + NEBO_FALLBACK_APPLIED_PROFILE_OFFSET]
    jmp .verify

.a11y_mode:
    mov qword [rel g92_request + NEBO_A11Y_ROLE_OFFSET], 3
    lea rax, [rel g92_label]
    mov [rel g92_request + NEBO_A11Y_NAME_OFFSET], rax
    mov [rel g92_request + NEBO_A11Y_NAME_LENGTH_OFFSET], rbx
    lea rax, [rel g92_description]
    mov [rel g92_request + NEBO_A11Y_DESCRIPTION_OFFSET], rax
    mov qword [rel g92_request + NEBO_A11Y_DESCRIPTION_LENGTH_OFFSET], 5
    mov qword [rel g92_request + NEBO_A11Y_LIVE_MODE_OFFSET], 1
    mov qword [rel g92_request + NEBO_A11Y_FLAGS_OFFSET], 0
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_accessibility_validate
    test eax, eax
    jnz .failure
    mov eax, [rel g92_result + NEBO_A11Y_NAME_LENGTH_OFFSET]
    jmp .verify

.plan_mode:
    call g92_prepare_plan
    test eax, eax
    jnz .failure
    mov eax, [rel g92_status + NEBO_STATUS_FALLBACK_CHAR_OFFSET]
.verify:
    cmp eax, ebx
    jne .failure
    jmp .done
.failure:
    mov eax, 255
.done:
    add rsp, 8
    pop r12
    pop rbx
    ret

; EBX supplies the semantic-status ASCII witness composed into the plan.
g92_prepare_plan:
    mov edi, NEBO_STYLE_BOLD | NEBO_STYLE_UNDERLINE
    lea rsi, [rel g92_core]
    call nebo_style_core_decorations
    test eax, eax
    jnz .prepare_done
    mov edi, NEBO_STYLE_DIM | NEBO_STYLE_BLINK
    mov esi, NEBO_STYLE_CAP_DIM
    lea rdx, [rel g92_optional]
    call nebo_style_optional_effects
    test eax, eax
    jnz .prepare_done
    lea rdi, [rel g92_request]
    mov ecx, 16
    xor eax, eax
    rep stosq
    mov qword [rel g92_request + NEBO_STATUS_KIND_OFFSET], NEBO_STATUS_SUCCESS
    lea rax, [rel g92_label]
    mov [rel g92_request + NEBO_STATUS_LABEL_OFFSET], rax
    mov qword [rel g92_request + NEBO_STATUS_LABEL_LENGTH_OFFSET], 6
    mov [rel g92_request + NEBO_STATUS_FALLBACK_CHAR_OFFSET], rbx
    mov qword [rel g92_request + NEBO_STATUS_COLOR_ROLE_OFFSET], NEBO_ROLE_ACCENT
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_status]
    call nebo_style_status_validate
    test eax, eax
    jnz .prepare_done
    lea rdi, [rel g92_request]
    mov ecx, 16
    xor eax, eax
    rep stosq
    mov eax, 0xffffffff
    mov [rel g92_request + NEBO_STYLE_COLORS_FOREGROUND_OFFSET], rax
    mov qword [rel g92_request + NEBO_STYLE_COLORS_BACKGROUND_OFFSET], 0x101820ff
    mov qword [rel g92_request + NEBO_STYLE_COLORS_ACCENT_OFFSET], 0x00ff00ff
    mov qword [rel g92_request + NEBO_STYLE_COLORS_PRESENT_OFFSET], 7
    mov qword [rel g92_request + NEBO_STYLE_COLORS_TARGET_OFFSET], NEBO_COLOR_TARGET_ANSI
    mov qword [rel g92_request + NEBO_STYLE_COLORS_CAPABILITIES_OFFSET], NEBO_COLOR_CAP_TRUECOLOR
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_colors]
    call nebo_style_colors_validate
    test eax, eax
    jnz .prepare_done
    lea rdi, [rel g92_request]
    mov ecx, 16
    xor eax, eax
    rep stosq
    mov qword [rel g92_request + NEBO_FONT_ID_OFFSET], 1
    mov qword [rel g92_request + NEBO_FONT_SIZE_OFFSET], 16
    mov qword [rel g92_request + NEBO_FONT_TARGET_OFFSET], NEBO_COLOR_TARGET_ANSI
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_font]
    call nebo_style_font_resolve
    test eax, eax
    jnz .prepare_done
    lea rdi, [rel g92_request]
    mov ecx, 16
    xor eax, eax
    rep stosq
    mov qword [rel g92_request + NEBO_FALLBACK_PROFILE_OFFSET], NEBO_PROFILE_NO_COLOR
    mov qword [rel g92_request + NEBO_FALLBACK_COLOR_PRESENT_OFFSET], 1
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_fallback]
    call nebo_style_fallback_resolve
    test eax, eax
    jnz .prepare_done
    lea rdi, [rel g92_request]
    mov ecx, 16
    xor eax, eax
    rep stosq
    mov qword [rel g92_request + NEBO_A11Y_ROLE_OFFSET], 3
    lea rax, [rel g92_label]
    mov [rel g92_request + NEBO_A11Y_NAME_OFFSET], rax
    mov qword [rel g92_request + NEBO_A11Y_NAME_LENGTH_OFFSET], 6
    mov qword [rel g92_request + NEBO_A11Y_LIVE_MODE_OFFSET], 1
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_a11y]
    call nebo_style_accessibility_validate
    test eax, eax
    jnz .prepare_done
    lea rdi, [rel g92_plan]
    mov ecx, NEBO_STYLE_PLAN_SIZE / 8
    xor eax, eax
    rep stosq
    lea rax, [rel g92_core]
    mov [rel g92_plan + NEBO_STYLE_PLAN_CORE_OFFSET], rax
    lea rax, [rel g92_optional]
    mov [rel g92_plan + NEBO_STYLE_PLAN_OPTIONAL_OFFSET], rax
    lea rax, [rel g92_status]
    mov [rel g92_plan + NEBO_STYLE_PLAN_STATUS_OFFSET], rax
    lea rax, [rel g92_colors]
    mov [rel g92_plan + NEBO_STYLE_PLAN_COLORS_OFFSET], rax
    lea rax, [rel g92_font]
    mov [rel g92_plan + NEBO_STYLE_PLAN_FONT_OFFSET], rax
    lea rax, [rel g92_fallback]
    mov [rel g92_plan + NEBO_STYLE_PLAN_FALLBACK_OFFSET], rax
    lea rax, [rel g92_a11y]
    mov [rel g92_plan + NEBO_STYLE_PLAN_A11Y_OFFSET], rax
    mov qword [rel g92_plan + NEBO_STYLE_PLAN_TARGET_OFFSET], NEBO_COLOR_TARGET_ANSI
    lea rdi, [rel g92_plan]
    lea rsi, [rel g92_receipt]
    call nebo_style_plan_validate
    test eax, eax
    jnz .prepare_done
    cmp qword [rel g92_receipt + NEBO_STYLE_RECEIPT_ACCESSIBLE_OFFSET], 1
    jne .prepare_invalid
    xor eax, eax
.prepare_done:
    ret
.prepare_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; EDI=case 1..8 -> canonical error; all failed destinations stay untouched.
nebo_g092_negative_probe:
    push rbx
    mov ebx, edi
    lea rdi, [rel g92_request]
    mov ecx, 16
    xor eax, eax
    rep stosq
    lea rdi, [rel g92_result]
    mov ecx, 16
    mov rax, 0xaaaaaaaaaaaaaaaa
    rep stosq
    cmp ebx, 1
    je .negative_role
    cmp ebx, 2
    je .negative_color_cap
    cmp ebx, 3
    je .negative_font_id
    cmp ebx, 4
    je .negative_font_size
    cmp ebx, 5
    je .negative_font_cap
    cmp ebx, 6
    je .negative_fallback_cap
    cmp ebx, 7
    je .negative_a11y_flag
    jmp .negative_private
.negative_role:
    mov qword [rel g92_tokens + NEBO_STYLE_TOKEN_ID_OFFSET], 1
    mov qword [rel g92_tokens + NEBO_STYLE_TOKEN_DECORATIONS_OFFSET], NEBO_STYLE_BOLD
    mov qword [rel g92_tokens + NEBO_STYLE_TOKEN_EFFECTS_OFFSET], 0
    mov qword [rel g92_tokens + NEBO_STYLE_TOKEN_ROLE_OFFSET], NEBO_ROLE_MAX + 1
    lea rax, [rel g92_tokens]
    mov [rel g92_request + NEBO_STYLE_REGISTRY_ENTRIES_OFFSET], rax
    mov qword [rel g92_request + NEBO_STYLE_REGISTRY_COUNT_OFFSET], 1
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_registry_validate
    jmp .negative_verify
.negative_color_cap:
    mov eax, 0xffffffff
    mov [rel g92_request + NEBO_STYLE_COLORS_FOREGROUND_OFFSET], rax
    mov qword [rel g92_request + NEBO_STYLE_COLORS_PRESENT_OFFSET], NEBO_STYLE_COLOR_FOREGROUND
    mov qword [rel g92_request + NEBO_STYLE_COLORS_TARGET_OFFSET], NEBO_COLOR_TARGET_ANSI
    mov qword [rel g92_request + NEBO_STYLE_COLORS_CAPABILITIES_OFFSET], 8
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_colors_validate
    jmp .negative_verify
.negative_font_id:
    mov qword [rel g92_request + NEBO_FONT_ID_OFFSET], NEBO_FONT_MAX_ID + 1
    mov qword [rel g92_request + NEBO_FONT_SIZE_OFFSET], 16
    mov qword [rel g92_request + NEBO_FONT_TARGET_OFFSET], NEBO_COLOR_TARGET_HEADLESS
    jmp .negative_font_call
.negative_font_size:
    mov qword [rel g92_request + NEBO_FONT_ID_OFFSET], 1
    mov qword [rel g92_request + NEBO_FONT_SIZE_OFFSET], NEBO_FONT_MAX_SIZE + 1
    mov qword [rel g92_request + NEBO_FONT_TARGET_OFFSET], NEBO_COLOR_TARGET_HEADLESS
    jmp .negative_font_call
.negative_font_cap:
    mov qword [rel g92_request + NEBO_FONT_ID_OFFSET], 1
    mov qword [rel g92_request + NEBO_FONT_SIZE_OFFSET], 16
    mov qword [rel g92_request + NEBO_FONT_TARGET_OFFSET], NEBO_COLOR_TARGET_HEADLESS
    mov qword [rel g92_request + NEBO_FONT_CAPABILITIES_OFFSET], 2
.negative_font_call:
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_font_resolve
    jmp .negative_verify
.negative_fallback_cap:
    mov qword [rel g92_request + NEBO_FALLBACK_PROFILE_OFFSET], NEBO_PROFILE_NO_COLOR
    mov qword [rel g92_request + NEBO_FALLBACK_CAPABILITIES_OFFSET], 1
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_fallback_resolve
    jmp .negative_verify
.negative_a11y_flag:
    mov qword [rel g92_request + NEBO_A11Y_FLAGS_OFFSET], 2
    jmp .negative_a11y_call
.negative_private:
    mov qword [rel g92_request + NEBO_A11Y_FLAGS_OFFSET], NEBO_A11Y_SENSITIVE
.negative_a11y_call:
    mov qword [rel g92_request + NEBO_A11Y_ROLE_OFFSET], 3
    lea rax, [rel g92_label]
    mov [rel g92_request + NEBO_A11Y_NAME_OFFSET], rax
    mov qword [rel g92_request + NEBO_A11Y_NAME_LENGTH_OFFSET], 1
    lea rdi, [rel g92_request]
    lea rsi, [rel g92_result]
    call nebo_style_accessibility_validate
.negative_verify:
    mov r8d, eax
    lea rdi, [rel g92_result]
    mov rax, 0xaaaaaaaaaaaaaaaa
    mov ecx, 16
.negative_scan:
    cmp [rdi], rax
    jne .negative_corrupt
    add rdi, 8
    loop .negative_scan
    mov eax, r8d
    jmp .negative_done
.negative_corrupt:
    mov eax, 99
.negative_done:
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
