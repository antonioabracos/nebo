; Nebo Assembly — TEXT-STYLES-SEMANTIC-STATUS-FONTS-E-FALLBACK target-independent style tokens and fallbacks
bits 64
default rel
%include "runtime/style_tokens.inc"
%include "runtime/color_roles.inc"
%include "runtime/color_target.inc"
global nebo_style_core_decorations
global nebo_style_optional_effects
global nebo_style_registry_validate
global nebo_style_status_validate
global nebo_style_colors_validate
global nebo_style_font_resolve
global nebo_style_fallback_resolve
global nebo_style_accessibility_validate
global nebo_style_plan_validate
section .text
; rdi=bold|italic|underline mask, rsi=normalized fragment.
nebo_style_core_decorations:
    test rsi, rsi
    jz .core_invalid
    mov rax, rdi
    and rax, ~NEBO_STYLE_CORE_ALL
    jnz .core_invalid
    mov [rsi + NEBO_STYLE_FRAGMENT_VALUE_OFFSET], rdi
    mov qword [rsi + NEBO_STYLE_FRAGMENT_AUX_OFFSET], 0
    mov qword [rsi + NEBO_STYLE_FRAGMENT_STATE_OFFSET], NEBO_STYLE_FRAGMENT_READY
    xor eax, eax
    ret
.core_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; rdi=optional style mask, rsi=target capability mask, rdx=fragment.
; Unsupported effects are recorded as explicit fallback bits, never overclaimed.
nebo_style_optional_effects:
    test rdx, rdx
    jz .optional_invalid
    mov rax, rdi
    and rax, ~NEBO_STYLE_OPTIONAL_ALL
    jnz .optional_invalid
    mov r8, rsi
    and r8, ~7
    jnz .optional_invalid
    xor r8d, r8d
    test rsi, NEBO_STYLE_CAP_DIM
    jz .optional_inverse
    or r8, NEBO_STYLE_DIM
.optional_inverse:
    test rsi, NEBO_STYLE_CAP_INVERSE
    jz .optional_blink
    or r8, NEBO_STYLE_INVERSE
.optional_blink:
    test rsi, NEBO_STYLE_CAP_BLINK
    jz .optional_masks
    or r8, NEBO_STYLE_BLINK
.optional_masks:
    and r8, rdi
    mov r9, rdi
    xor r9, r8
    mov [rdx + NEBO_STYLE_FRAGMENT_VALUE_OFFSET], r8
    mov [rdx + NEBO_STYLE_FRAGMENT_AUX_OFFSET], r9
    mov qword [rdx + NEBO_STYLE_FRAGMENT_STATE_OFFSET], NEBO_STYLE_FRAGMENT_READY
    xor eax, eax
    ret
.optional_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; Stable sorted token registry; tokens carry semantics, never target escape bytes.
nebo_style_registry_validate:
    test rdi, rdi
    jz .token_invalid
    test rsi, rsi
    jz .token_invalid
    mov rcx, [rdi + NEBO_STYLE_REGISTRY_COUNT_OFFSET]
    test rcx, rcx
    jz .token_invalid
    cmp rcx, NEBO_STYLE_MAX_TOKEN_ID
    ja .token_limit
    mov rdx, [rdi + NEBO_STYLE_REGISTRY_ENTRIES_OFFSET]
    test rdx, rdx
    jz .token_invalid
    mov rax, 0xcbf29ce484222325
    mov r11, 0x100000001b3
    xor r8d, r8d
    xor r9d, r9d
.token_loop:
    cmp r8, rcx
    jae .token_commit
    mov r10, r8
    shl r10, 5
    add r10, rdx
    mov rdi, [r10 + NEBO_STYLE_TOKEN_ID_OFFSET]
    test rdi, rdi
    jz .token_invalid
    cmp rdi, NEBO_STYLE_MAX_TOKEN_ID
    ja .token_limit
    cmp rdi, r9
    jbe .token_conflict
    mov r9, rdi
    mov rdi, [r10 + NEBO_STYLE_TOKEN_DECORATIONS_OFFSET]
    test rdi, ~NEBO_STYLE_CORE_ALL
    jnz .token_invalid
    mov rdi, [r10 + NEBO_STYLE_TOKEN_EFFECTS_OFFSET]
    test rdi, ~NEBO_STYLE_OPTIONAL_ALL
    jnz .token_invalid
    mov rdi, [r10 + NEBO_STYLE_TOKEN_ROLE_OFFSET]
    cmp rdi, NEBO_ROLE_FOREGROUND
    jb .token_invalid
    cmp rdi, NEBO_ROLE_MAX
    ja .token_invalid
    xor rax, r9
    imul rax, r11
    xor rax, [r10 + NEBO_STYLE_TOKEN_DECORATIONS_OFFSET]
    imul rax, r11
    xor rax, [r10 + NEBO_STYLE_TOKEN_EFFECTS_OFFSET]
    imul rax, r11
    xor rax, [r10 + NEBO_STYLE_TOKEN_ROLE_OFFSET]
    imul rax, r11
    inc r8
    jmp .token_loop
.token_commit:
    mov [rsi + NEBO_STYLE_REGISTRY_RECEIPT_COUNT_OFFSET], rcx
    mov [rsi + NEBO_STYLE_REGISTRY_RECEIPT_DIGEST_OFFSET], rax
    mov qword [rsi + NEBO_STYLE_REGISTRY_RECEIPT_STATE_OFFSET], NEBO_STYLE_REGISTRY_READY
    xor eax, eax
    ret
.token_conflict:
    mov eax, NEBO_STYLE_CONFLICT
    ret
.token_limit:
    mov eax, NEBO_STYLE_LIMIT
    ret
.token_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; Status always carries text plus an ASCII fallback; color is supplemental.
nebo_style_status_validate:
    test rdi, rdi
    jz .status_invalid
    test rsi, rsi
    jz .status_invalid
    mov rcx, [rdi + NEBO_STATUS_KIND_OFFSET]
    cmp rcx, NEBO_STATUS_SUCCESS
    jb .status_invalid
    cmp rcx, NEBO_STATUS_DEBUG
    ja .status_invalid
    mov rdx, [rdi + NEBO_STATUS_LABEL_LENGTH_OFFSET]
    test rdx, rdx
    jz .status_accessibility
    cmp rdx, NEBO_STYLE_MAX_LABEL_BYTES
    ja .status_limit
    cmp qword [rdi + NEBO_STATUS_LABEL_OFFSET], 0
    je .status_invalid
    mov r8, [rdi + NEBO_STATUS_FALLBACK_CHAR_OFFSET]
    cmp r8, 33
    jb .status_accessibility
    cmp r8, 126
    ja .status_accessibility
    mov r9, [rdi + NEBO_STATUS_COLOR_ROLE_OFFSET]
    cmp r9, NEBO_ROLE_FOREGROUND
    jb .status_invalid
    cmp r9, NEBO_ROLE_MAX
    ja .status_invalid
    mov [rsi + NEBO_STATUS_KIND_OFFSET], rcx
    mov rax, [rdi + NEBO_STATUS_LABEL_OFFSET]
    mov [rsi + NEBO_STATUS_LABEL_OFFSET], rax
    mov [rsi + NEBO_STATUS_LABEL_LENGTH_OFFSET], rdx
    mov [rsi + NEBO_STATUS_FALLBACK_CHAR_OFFSET], r8
    mov [rsi + NEBO_STATUS_COLOR_ROLE_OFFSET], r9
    mov qword [rsi + NEBO_STATUS_STATE_OFFSET], NEBO_STATUS_READY
    xor eax, eax
    ret
.status_accessibility:
    mov eax, NEBO_STYLE_ACCESSIBILITY
    ret
.status_limit:
    mov eax, NEBO_STYLE_LIMIT
    ret
.status_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; Foreground/background/accent remain typed RGBA8 values from P01.
nebo_style_colors_validate:
    test rdi, rdi
    jz .colors_invalid
    test rsi, rsi
    jz .colors_invalid
    mov rcx, [rdi + NEBO_STYLE_COLORS_PRESENT_OFFSET]
    test rcx, rcx
    jz .colors_invalid
    test rcx, ~7
    jnz .colors_invalid
    mov r8, [rdi + NEBO_STYLE_COLORS_TARGET_OFFSET]
    cmp r8, NEBO_COLOR_TARGET_HEADLESS
    jb .colors_target
    cmp r8, NEBO_COLOR_TARGET_LIVE
    ja .colors_target
    mov rax, [rdi + NEBO_STYLE_COLORS_CAPABILITIES_OFFSET]
    test rax, ~(NEBO_COLOR_CAP_ALPHA | NEBO_COLOR_CAP_BLEND | NEBO_COLOR_CAP_TRUECOLOR)
    jnz .colors_invalid
    xor r9d, r9d
.colors_loop:
    cmp r9, 3
    jae .colors_commit
    mov rax, 1
    mov ecx, r9d
    shl rax, cl
    test [rdi + NEBO_STYLE_COLORS_PRESENT_OFFSET], rax
    jz .colors_next
    mov rax, [rdi + r9 * 8]
    mov edx, eax
    cmp rax, rdx
    jne .colors_invalid
    cmp dl, 255
    je .colors_next
    test qword [rdi + NEBO_STYLE_COLORS_CAPABILITIES_OFFSET], NEBO_COLOR_CAP_ALPHA
    jz .colors_target
.colors_next:
    inc r9
    jmp .colors_loop
.colors_commit:
    mov rax, [rdi + NEBO_STYLE_COLORS_FOREGROUND_OFFSET]
    mov [rsi + NEBO_STYLE_COLORS_FOREGROUND_OFFSET], rax
    mov rax, [rdi + NEBO_STYLE_COLORS_BACKGROUND_OFFSET]
    mov [rsi + NEBO_STYLE_COLORS_BACKGROUND_OFFSET], rax
    mov rax, [rdi + NEBO_STYLE_COLORS_ACCENT_OFFSET]
    mov [rsi + NEBO_STYLE_COLORS_ACCENT_OFFSET], rax
    mov rax, [rdi + NEBO_STYLE_COLORS_PRESENT_OFFSET]
    mov [rsi + NEBO_STYLE_COLORS_PRESENT_OFFSET], rax
    mov [rsi + NEBO_STYLE_COLORS_TARGET_OFFSET], r8
    mov rax, [rdi + NEBO_STYLE_COLORS_CAPABILITIES_OFFSET]
    mov [rsi + NEBO_STYLE_COLORS_CAPABILITIES_OFFSET], rax
    mov qword [rsi + NEBO_STYLE_COLORS_STATE_OFFSET], NEBO_STYLE_COLORS_READY
    xor eax, eax
    ret
.colors_target:
    mov eax, NEBO_STYLE_TARGET
    ret
.colors_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; Fonts are target-sensitive: headless/ANSI use an explicit target default.
nebo_style_font_resolve:
    test rdi, rdi
    jz .font_invalid
    test rsi, rsi
    jz .font_invalid
    mov rcx, [rdi + NEBO_FONT_ID_OFFSET]
    test rcx, rcx
    jz .font_invalid
    cmp rcx, NEBO_FONT_MAX_ID
    ja .font_limit
    mov rdx, [rdi + NEBO_FONT_SIZE_OFFSET]
    test rdx, rdx
    jle .font_invalid
    movsxd r8, edx
    cmp r8, rdx
    jne .font_limit
    cmp rdx, NEBO_FONT_MAX_SIZE
    ja .font_limit
    mov rax, [rdi + NEBO_FONT_CAPABILITIES_OFFSET]
    test rax, ~NEBO_FONT_CAP_CUSTOM
    jnz .font_invalid
    mov r8, [rdi + NEBO_FONT_TARGET_OFFSET]
    cmp r8, NEBO_COLOR_TARGET_HEADLESS
    jb .font_target
    cmp r8, NEBO_COLOR_TARGET_LIVE
    ja .font_target
    cmp r8, NEBO_COLOR_TARGET_LIVE
    je .font_live
    xor r9d, r9d
    xor r10d, r10d
    mov r11, NEBO_FONT_FALLBACK_TARGET_DEFAULT
    jmp .font_commit
.font_live:
    test qword [rdi + NEBO_FONT_CAPABILITIES_OFFSET], NEBO_FONT_CAP_CUSTOM
    jz .font_target
    mov r9, rcx
    mov r10, rdx
    xor r11d, r11d
.font_commit:
    mov rax, [rdi + NEBO_FONT_ID_OFFSET]
    mov [rsi + NEBO_FONT_ID_OFFSET], rax
    mov rax, [rdi + NEBO_FONT_SIZE_OFFSET]
    mov [rsi + NEBO_FONT_SIZE_OFFSET], rax
    mov [rsi + NEBO_FONT_TARGET_OFFSET], r8
    mov rax, [rdi + NEBO_FONT_CAPABILITIES_OFFSET]
    mov [rsi + NEBO_FONT_CAPABILITIES_OFFSET], rax
    mov [rsi + NEBO_FONT_APPLIED_ID_OFFSET], r9
    mov [rsi + NEBO_FONT_APPLIED_SIZE_OFFSET], r10
    mov [rsi + NEBO_FONT_FALLBACK_OFFSET], r11
    mov qword [rsi + NEBO_FONT_STATE_OFFSET], NEBO_FONT_READY
    xor eax, eax
    ret
.font_limit:
    mov eax, NEBO_STYLE_LIMIT
    ret
.font_target:
    mov eax, NEBO_STYLE_TARGET
    ret
.font_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; Resolves noColor/highContrast/ascii without pretending unsupported features.
nebo_style_fallback_resolve:
    test rdi, rdi
    jz .fallback_invalid
    test rsi, rsi
    jz .fallback_invalid
    mov rcx, [rdi + NEBO_FALLBACK_PROFILE_OFFSET]
    test rcx, ~NEBO_PROFILE_ALL
    jnz .fallback_invalid
    mov rdx, [rdi + NEBO_FALLBACK_EFFECTS_OFFSET]
    test rdx, ~NEBO_STYLE_OPTIONAL_ALL
    jnz .fallback_invalid
    mov r8, [rdi + NEBO_FALLBACK_COLOR_PRESENT_OFFSET]
    cmp r8, 1
    ja .fallback_invalid
    mov rax, [rdi + NEBO_FALLBACK_CAPABILITIES_OFFSET]
    test rax, ~NEBO_PROFILE_CAP_ALL
    jnz .fallback_invalid
    mov r9, rcx
    test rcx, NEBO_PROFILE_HIGH_CONTRAST
    jz .fallback_ascii
    test qword [rdi + NEBO_FALLBACK_CAPABILITIES_OFFSET], NEBO_PROFILE_CAP_HIGH_CONTRAST
    jnz .fallback_ascii
    and r9, ~NEBO_PROFILE_HIGH_CONTRAST
    or r9, NEBO_PROFILE_ASCII
.fallback_ascii:
    mov r10, rdx
    xor r11d, r11d
    test r9, NEBO_PROFILE_ASCII
    jz .fallback_color
    mov r11, rdx
    xor r10d, r10d
.fallback_color:
    test r9, NEBO_PROFILE_NO_COLOR | NEBO_PROFILE_ASCII
    jz .fallback_commit
    xor r8d, r8d
.fallback_commit:
    mov rax, [rdi + NEBO_FALLBACK_PROFILE_OFFSET]
    mov [rsi + NEBO_FALLBACK_PROFILE_OFFSET], rax
    mov rax, [rdi + NEBO_FALLBACK_EFFECTS_OFFSET]
    mov [rsi + NEBO_FALLBACK_EFFECTS_OFFSET], rax
    mov rax, [rdi + NEBO_FALLBACK_COLOR_PRESENT_OFFSET]
    mov [rsi + NEBO_FALLBACK_COLOR_PRESENT_OFFSET], rax
    mov rax, [rdi + NEBO_FALLBACK_CAPABILITIES_OFFSET]
    mov [rsi + NEBO_FALLBACK_CAPABILITIES_OFFSET], rax
    mov [rsi + NEBO_FALLBACK_APPLIED_PROFILE_OFFSET], r9
    mov [rsi + NEBO_FALLBACK_APPLIED_EFFECTS_OFFSET], r10
    mov [rsi + NEBO_FALLBACK_EFFECT_MASK_OFFSET], r11
    mov [rsi + NEBO_FALLBACK_COLOR_ENABLED_OFFSET], r8
    mov qword [rsi + NEBO_FALLBACK_STATE_OFFSET], NEBO_FALLBACK_READY
    xor eax, eax
    ret
.fallback_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; Screen-reader role/name/description are semantic data in the RenderPlan.
nebo_style_accessibility_validate:
    test rdi, rdi
    jz .a11y_invalid
    test rsi, rsi
    jz .a11y_invalid
    mov rax, [rdi + NEBO_A11Y_FLAGS_OFFSET]
    test rax, ~NEBO_A11Y_SENSITIVE
    jnz .a11y_invalid
    test rax, NEBO_A11Y_SENSITIVE
    jnz .a11y_privacy
    mov rcx, [rdi + NEBO_A11Y_ROLE_OFFSET]
    cmp rcx, NEBO_A11Y_ROLE_MIN
    jb .a11y_invalid
    cmp rcx, NEBO_A11Y_ROLE_MAX
    ja .a11y_invalid
    mov rdx, [rdi + NEBO_A11Y_NAME_LENGTH_OFFSET]
    test rdx, rdx
    jz .a11y_accessibility
    cmp qword [rdi + NEBO_A11Y_NAME_OFFSET], 0
    je .a11y_invalid
    mov r8, [rdi + NEBO_A11Y_DESCRIPTION_LENGTH_OFFSET]
    test r8, r8
    jz .a11y_total
    cmp qword [rdi + NEBO_A11Y_DESCRIPTION_OFFSET], 0
    je .a11y_invalid
.a11y_total:
    mov rax, rdx
    add rax, r8
    jc .a11y_limit
    cmp rax, NEBO_STYLE_MAX_LABEL_BYTES
    ja .a11y_limit
    mov r9, [rdi + NEBO_A11Y_LIVE_MODE_OFFSET]
    cmp r9, NEBO_A11Y_LIVE_ASSERTIVE
    ja .a11y_invalid
    mov [rsi + NEBO_A11Y_ROLE_OFFSET], rcx
    mov rax, [rdi + NEBO_A11Y_NAME_OFFSET]
    mov [rsi + NEBO_A11Y_NAME_OFFSET], rax
    mov [rsi + NEBO_A11Y_NAME_LENGTH_OFFSET], rdx
    mov rax, [rdi + NEBO_A11Y_DESCRIPTION_OFFSET]
    mov [rsi + NEBO_A11Y_DESCRIPTION_OFFSET], rax
    mov [rsi + NEBO_A11Y_DESCRIPTION_LENGTH_OFFSET], r8
    mov [rsi + NEBO_A11Y_LIVE_MODE_OFFSET], r9
    mov qword [rsi + NEBO_A11Y_FLAGS_OFFSET], 0
    mov qword [rsi + NEBO_A11Y_STATE_OFFSET], NEBO_A11Y_READY
    xor eax, eax
    ret
.a11y_privacy:
    mov eax, NEBO_STYLE_PRIVACY
    ret
.a11y_accessibility:
    mov eax, NEBO_STYLE_ACCESSIBILITY
    ret
.a11y_limit:
    mov eax, NEBO_STYLE_LIMIT
    ret
.a11y_invalid:
    mov eax, NEBO_STYLE_INVALID
    ret

; Closes one target-independent StylePlan from validated semantic fragments.
nebo_style_plan_validate:
    test rdi, rdi
    jz .plan_invalid_pre
    test rsi, rsi
    jz .plan_invalid_pre
    push rbx
    push r12
    mov rbx, rsi
    mov r12, rdi
    mov rdx, [r12 + NEBO_STYLE_PLAN_CORE_OFFSET]
    mov r8, [r12 + NEBO_STYLE_PLAN_OPTIONAL_OFFSET]
    mov r9, [r12 + NEBO_STYLE_PLAN_STATUS_OFFSET]
    mov r10, [r12 + NEBO_STYLE_PLAN_COLORS_OFFSET]
    mov r11, [r12 + NEBO_STYLE_PLAN_FONT_OFFSET]
    test rdx, rdx
    jz .plan_invalid
    test r8, r8
    jz .plan_invalid
    test r9, r9
    jz .plan_accessibility
    test r10, r10
    jz .plan_invalid
    test r11, r11
    jz .plan_invalid
    cmp qword [rdx + NEBO_STYLE_FRAGMENT_STATE_OFFSET], NEBO_STYLE_FRAGMENT_READY
    jne .plan_invalid
    cmp qword [r8 + NEBO_STYLE_FRAGMENT_STATE_OFFSET], NEBO_STYLE_FRAGMENT_READY
    jne .plan_invalid
    cmp qword [r9 + NEBO_STATUS_STATE_OFFSET], NEBO_STATUS_READY
    jne .plan_accessibility
    cmp qword [r10 + NEBO_STYLE_COLORS_STATE_OFFSET], NEBO_STYLE_COLORS_READY
    jne .plan_invalid
    cmp qword [r11 + NEBO_FONT_STATE_OFFSET], NEBO_FONT_READY
    jne .plan_target
    mov rcx, [r12 + NEBO_STYLE_PLAN_FALLBACK_OFFSET]
    mov rsi, [r12 + NEBO_STYLE_PLAN_A11Y_OFFSET]
    test rcx, rcx
    jz .plan_accessibility
    test rsi, rsi
    jz .plan_accessibility
    cmp qword [rcx + NEBO_FALLBACK_STATE_OFFSET], NEBO_FALLBACK_READY
    jne .plan_accessibility
    cmp qword [rsi + NEBO_A11Y_STATE_OFFSET], NEBO_A11Y_READY
    jne .plan_accessibility
    mov rdi, [r12 + NEBO_STYLE_PLAN_TARGET_OFFSET]
    cmp rdi, NEBO_COLOR_TARGET_HEADLESS
    jb .plan_target
    cmp rdi, NEBO_COLOR_TARGET_LIVE
    ja .plan_target
    cmp [r10 + NEBO_STYLE_COLORS_TARGET_OFFSET], rdi
    jne .plan_target
    cmp [r11 + NEBO_FONT_TARGET_OFFSET], rdi
    jne .plan_target
    mov rax, 0xcbf29ce484222325
    mov r12, 0x100000001b3
    xor rax, [rdx + NEBO_STYLE_FRAGMENT_VALUE_OFFSET]
    imul rax, r12
    xor rax, [r8 + NEBO_STYLE_FRAGMENT_VALUE_OFFSET]
    imul rax, r12
    xor rax, [r8 + NEBO_STYLE_FRAGMENT_AUX_OFFSET]
    imul rax, r12
    xor rax, [r9 + NEBO_STATUS_KIND_OFFSET]
    imul rax, r12
    xor rax, [r9 + NEBO_STATUS_FALLBACK_CHAR_OFFSET]
    imul rax, r12
    xor rax, [r10 + NEBO_STYLE_COLORS_FOREGROUND_OFFSET]
    imul rax, r12
    xor rax, [r11 + NEBO_FONT_APPLIED_ID_OFFSET]
    imul rax, r12
    xor rax, [rcx + NEBO_FALLBACK_APPLIED_PROFILE_OFFSET]
    imul rax, r12
    xor rax, [rsi + NEBO_A11Y_ROLE_OFFSET]
    imul rax, r12
    xor rax, [rsi + NEBO_A11Y_NAME_LENGTH_OFFSET]
    imul rax, r12
    mov [rbx + NEBO_STYLE_RECEIPT_DIGEST_OFFSET], rax
    mov [rbx + NEBO_STYLE_RECEIPT_TARGET_OFFSET], rdi
    mov qword [rbx + NEBO_STYLE_RECEIPT_ACCESSIBLE_OFFSET], 1
    mov qword [rbx + NEBO_STYLE_RECEIPT_STATE_OFFSET], NEBO_STYLE_PLAN_READY
    xor eax, eax
    jmp .plan_done
.plan_accessibility:
    mov eax, NEBO_STYLE_ACCESSIBILITY
    jmp .plan_done
.plan_target:
    mov eax, NEBO_STYLE_TARGET
    jmp .plan_done
.plan_invalid:
    mov eax, NEBO_STYLE_INVALID
.plan_done:
    pop r12
    pop rbx
    ret
.plan_invalid_pre:
    mov eax, NEBO_STYLE_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
