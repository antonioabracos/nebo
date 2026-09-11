; Nebo Assembly — CONSOLECALL-CONSOLEOPTION-REGISTRY-E-NORMALIZACAO safe single-engine RenderIntent plan
bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "runtime/color_target.inc"
%include "runtime/console_options.inc"
%include "runtime/console_call.inc"
%include "runtime/render_intent.inc"
global nebo_render_intent_build
global nebo_console_render_plan_is_safe
section .text
; rdi=RenderPlan. A safe plan is ready, bounded, target-valid, normalized by
; strictly increasing option kind, and capability-authorized. The current
; scalar option profile cannot carry secret-bearing payload metadata.
nebo_console_render_plan_is_safe:
    test rdi, rdi
    jz .safe_invalid
    cmp qword [rdi + NEBO_RENDER_PLAN_STATE_OFFSET], NEBO_RENDER_PLAN_READY
    jne .safe_invalid
    mov rcx, [rdi + NEBO_RENDER_PLAN_COUNT_OFFSET]
    cmp rcx, NEBOC_MAX_CONSOLE_OPTIONS
    ja .safe_budget
    mov rdx, [rdi + NEBO_RENDER_PLAN_OPTIONS_OFFSET]
    test rcx, rcx
    jz .safe_target
    test rdx, rdx
    jz .safe_invalid
.safe_target:
    mov r8, [rdi + NEBO_RENDER_PLAN_TARGET_OFFSET]
    cmp r8, NEBO_COLOR_TARGET_HEADLESS
    jb .safe_invalid
    cmp r8, NEBO_COLOR_TARGET_LIVE
    ja .safe_invalid
    mov r8, [rdi + NEBO_RENDER_PLAN_EFFECTS_OFFSET]
    mov r9, r8
    and r9, ~NEBO_CONSOLE_EFFECT_ALL
    jnz .safe_effect
    mov r10, [rdi + NEBO_RENDER_PLAN_CAPABILITIES_OFFSET]
    not r10
    test r8, r10
    jnz .safe_effect
    xor r8d, r8d
    xor r9d, r9d
.safe_option:
    cmp r8, rcx
    jae .safe_ok
    imul r10, r8, NEBO_OPTION_VALUE_SIZE
    mov r11, [rdx + r10 + NEBO_OPTION_VALUE_KIND_OFFSET]
    cmp r11, 1
    jb .safe_invalid
    cmp r11, 32
    ja .safe_invalid
    cmp r11, r9
    jbe .safe_order
    mov r9, r11
    inc r8
    jmp .safe_option
.safe_ok:
    xor eax, eax
    ret
.safe_order:
    mov eax, NEBO_RENDER_INTENT_ORDER
    ret
.safe_effect:
    mov eax, NEBO_RENDER_INTENT_EFFECT
    ret
.safe_budget:
    mov eax, NEBO_OPTIONS_BUDGET
    ret
.safe_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret

; rdi=intent, rsi=out RenderPlan. Semantic digest covers normalized options.
nebo_render_intent_build:
    push rbx
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rbx, rdi
    mov rcx, [rdi + NEBO_RENDER_INTENT_COUNT_OFFSET]
    cmp rcx, NEBOC_MAX_CONSOLE_OPTIONS
    ja .budget
    mov rdx, [rdi + NEBO_RENDER_INTENT_OPTIONS_OFFSET]
    test rcx, rcx
    jz .target
    test rdx, rdx
    jz .invalid
.target:
    mov r8, [rdi + NEBO_RENDER_INTENT_TARGET_OFFSET]
    cmp r8, NEBO_COLOR_TARGET_HEADLESS
    jb .invalid
    cmp r8, NEBO_COLOR_TARGET_LIVE
    ja .invalid
    mov r9, [rdi + NEBO_RENDER_INTENT_EFFECTS_OFFSET]
    mov r10, r9
    and r10, ~NEBO_CONSOLE_EFFECT_ALL
    jnz .effect
    mov r10, [rdi + NEBO_RENDER_INTENT_CAPABILITIES_OFFSET]
    mov rax, r10
    not rax
    test r9, rax
    jnz .effect
    mov rax, 0xcbf29ce484222325
    mov r11, 0x100000001b3
    xor r8d, r8d
    xor r9d, r9d
.digest:
    cmp r8, rcx
    jae .commit
    imul r10, r8, NEBO_OPTION_VALUE_SIZE
    add r10, rdx
    mov rdi, [r10 + NEBO_OPTION_VALUE_KIND_OFFSET]
    cmp rdi, 1
    jb .invalid
    cmp rdi, 32
    ja .invalid
    cmp rdi, r9
    jbe .order
    mov r9, rdi
    xor rax, rdi
    imul rax, r11
    xor rax, [r10 + NEBO_OPTION_VALUE_PAYLOAD_OFFSET]
    imul rax, r11
    xor rax, [r10 + NEBO_OPTION_VALUE_CONFLICT_MASK_OFFSET]
    imul rax, r11
    inc r8
    jmp .digest
.commit:
    mov rdx, [rbx + NEBO_RENDER_INTENT_OPTIONS_OFFSET]
    mov [rsi + NEBO_RENDER_PLAN_OPTIONS_OFFSET], rdx
    mov rdx, [rbx + NEBO_RENDER_INTENT_COUNT_OFFSET]
    mov [rsi + NEBO_RENDER_PLAN_COUNT_OFFSET], rdx
    mov rdx, [rbx + NEBO_RENDER_INTENT_TARGET_OFFSET]
    mov [rsi + NEBO_RENDER_PLAN_TARGET_OFFSET], rdx
    mov rdx, [rbx + NEBO_RENDER_INTENT_CAPABILITIES_OFFSET]
    mov [rsi + NEBO_RENDER_PLAN_CAPABILITIES_OFFSET], rdx
    mov rdx, [rbx + NEBO_RENDER_INTENT_EFFECTS_OFFSET]
    mov [rsi + NEBO_RENDER_PLAN_EFFECTS_OFFSET], rdx
    mov [rsi + NEBO_RENDER_PLAN_SEMANTIC_DIGEST_OFFSET], rax
    mov qword [rsi + NEBO_RENDER_PLAN_STATE_OFFSET], NEBO_RENDER_PLAN_READY
    xor eax, eax
    jmp .done
.order:
    mov eax, NEBO_RENDER_INTENT_ORDER
    jmp .done
.effect:
    mov eax, NEBO_RENDER_INTENT_EFFECT
    jmp .done
.budget:
    mov eax, NEBO_OPTIONS_BUDGET
    jmp .done
.invalid:
    mov eax, NEBO_OPTIONS_INVALID
.done:
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
