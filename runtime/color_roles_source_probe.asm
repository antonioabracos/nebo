; G088 public-source proof for typed roles, palette/theme policy, accessibility
; and factual target mapping. Every mode returns a value read from real owners.
bits 64
default rel
%define NEBO_G088_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/color_roles_source_probe.inc"
%include "runtime/color.inc"
%include "compiler/semantic/color.inc"
%include "compiler/semantic/color_options.inc"
%include "runtime/color_options.inc"
%include "runtime/color_roles.inc"
%include "runtime/color_palette.inc"
%include "runtime/color_theme.inc"
%include "runtime/colormap.inc"
%include "runtime/color_accessibility.inc"
%include "runtime/color_space.inc"
%include "runtime/color_target.inc"

extern nebo_color_rgb_lowering
extern nebo_color_red
extern neboc_color_option_typecheck
extern nebo_color_option_materialize
extern nebo_color_role_define
extern nebo_palette_validate
extern nebo_palette_lookup
extern nebo_theme_resolve
extern nebo_colormap_normalize
extern nebo_color_contrast_check
extern nebo_color_pick_accessible
extern nebo_color_space_normalize
extern nebo_color_target_map

global nebo_g088_source_probe
global nebo_g088_negative_probe

section .rodata
g88_ocean: db "ocean"
g88_ocean_len equ $-g88_ocean
g88_ember: db "ember"
g88_ember_len equ $-g88_ember

section .bss align=16
g88_color_a: resd 1
g88_color_b: resd 1
g88_typed: resb NEBOC_COLOR_OPTION_SIZE
g88_option: resb NEBO_COLOR_RUNTIME_OPTION_SIZE
g88_role: resb NEBO_ROLE_DESC_SIZE
g88_palette: resb NEBO_PALETTE_ENTRY_SIZE * 2
g88_theme: resb NEBO_THEME_SIZE
g88_stops: resb NEBO_COLORMAP_STOP_SIZE * 3
g88_colormap: resb NEBO_COLORMAP_DESC_SIZE
g88_space: resb NEBO_SPACE_DESC_SIZE
g88_target: resb NEBO_COLOR_TARGET_SIZE

section .text
; EDI=mode 1..9, ESI=source-derived red channel -> EAX=observed red.
nebo_g088_source_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    mov ebx, esi
    cmp ebx, 255
    ja .failure
    cmp r12d, 1
    je .mode1
    cmp r12d, 2
    je .mode2
    cmp r12d, 3
    je .mode3
    cmp r12d, 4
    je .mode4
    cmp r12d, 5
    je .mode5
    cmp r12d, 6
    je .mode6
    cmp r12d, 7
    je .mode7
    cmp r12d, 8
    je .mode8
    cmp r12d, 9
    je .mode9
    jmp .failure

.mode1:
    call g88_make_seed_color
    test eax, eax
    jnz .failure
    mov edi, NEBOC_COLOR_ROLE_FOREGROUND
    mov esi, NEBOC_COLOR_TYPE_ID
    mov edx, [rel g88_color_a]
    lea rcx, [rel g88_typed]
    call neboc_color_option_typecheck
    test eax, eax
    jnz .failure
    lea rdi, [rel g88_typed]
    lea rsi, [rel g88_option]
    call nebo_color_option_materialize
    test eax, eax
    jnz .failure
    cmp qword [rel g88_option + NEBO_COLOR_RUNTIME_OPTION_ROLE_OFFSET], NEBOC_COLOR_ROLE_FOREGROUND
    jne .failure
    ; The background typed overload and the historical RGB spelling normalize
    ; through the same Color/typecheck/materialization pipeline.
    mov edi, NEBOC_COLOR_ROLE_BACKGROUND
    mov esi, NEBOC_COLOR_TYPE_ID
    mov edx, [rel g88_color_a]
    lea rcx, [rel g88_typed]
    call neboc_color_option_typecheck
    test eax, eax
    jnz .failure
    lea rdi, [rel g88_typed]
    lea rsi, [rel g88_option]
    call nebo_color_option_materialize
    test eax, eax
    jnz .failure
    cmp qword [rel g88_option + NEBO_COLOR_RUNTIME_OPTION_ROLE_OFFSET], NEBOC_COLOR_ROLE_BACKGROUND
    jne .failure
    mov edi, [rel g88_option + NEBO_COLOR_RUNTIME_OPTION_VALUE_OFFSET]
    jmp .observe

.mode2:
    call g88_make_seed_color
    test eax, eax
    jnz .failure
    mov r12d, NEBO_ROLE_FOREGROUND
.role_loop:
    mov edi, r12d
    mov esi, [rel g88_color_a]
    lea rdx, [rel g88_role]
    call nebo_color_role_define
    test eax, eax
    jnz .failure
    cmp [rel g88_role + NEBO_ROLE_DESC_KIND_OFFSET], r12
    jne .failure
    inc r12d
    cmp r12d, NEBO_ROLE_MAX
    jbe .role_loop
    mov edi, [rel g88_role + NEBO_ROLE_DESC_COLOR_OFFSET]
    jmp .observe

.mode3:
    call g88_make_seed_color
    test eax, eax
    jnz .failure
    lea rax, [rel g88_ocean]
    mov [rel g88_palette + NEBO_PALETTE_ENTRY_NAME_OFFSET], rax
    mov qword [rel g88_palette + NEBO_PALETTE_ENTRY_NAME_LEN_OFFSET], g88_ocean_len
    mov eax, [rel g88_color_a]
    mov [rel g88_palette + NEBO_PALETTE_ENTRY_COLOR_OFFSET], eax
    lea rax, [rel g88_ember]
    mov [rel g88_palette + NEBO_PALETTE_ENTRY_SIZE + NEBO_PALETTE_ENTRY_NAME_OFFSET], rax
    mov qword [rel g88_palette + NEBO_PALETTE_ENTRY_SIZE + NEBO_PALETTE_ENTRY_NAME_LEN_OFFSET], g88_ember_len
    mov dword [rel g88_palette + NEBO_PALETTE_ENTRY_SIZE + NEBO_PALETTE_ENTRY_COLOR_OFFSET], 0xe04422ff
    lea rdi, [rel g88_palette]
    mov esi, 2
    call nebo_palette_validate
    test eax, eax
    jnz .failure
    lea rdi, [rel g88_palette]
    mov esi, 2
    lea rdx, [rel g88_ocean]
    mov ecx, g88_ocean_len
    lea r8, [rel g88_color_b]
    call nebo_palette_lookup
    test eax, eax
    jnz .failure
    mov edi, [rel g88_color_b]
    jmp .observe

.mode4:
    call g88_fill_theme
    lea rdi, [rel g88_theme]
    mov esi, NEBO_THEME_TOKEN_ACCENT
    lea rdx, [rel g88_color_b]
    call nebo_theme_resolve
    test eax, eax
    jnz .failure
    mov edi, [rel g88_color_b]
    jmp .observe

.mode5:
    call g88_make_seed_color
    test eax, eax
    jnz .failure
    mov dword [rel g88_stops + NEBO_COLORMAP_STOP_POSITION_OFFSET], 0
    mov eax, [rel g88_color_a]
    mov [rel g88_stops + NEBO_COLORMAP_STOP_COLOR_OFFSET], eax
    mov dword [rel g88_stops + NEBO_COLORMAP_STOP_SIZE + NEBO_COLORMAP_STOP_POSITION_OFFSET], 32768
    mov dword [rel g88_stops + NEBO_COLORMAP_STOP_SIZE + NEBO_COLORMAP_STOP_COLOR_OFFSET], 0x808080ff
    mov dword [rel g88_stops + NEBO_COLORMAP_STOP_SIZE * 2 + NEBO_COLORMAP_STOP_POSITION_OFFSET], 65535
    mov dword [rel g88_stops + NEBO_COLORMAP_STOP_SIZE * 2 + NEBO_COLORMAP_STOP_COLOR_OFFSET], 0xffffffff
    lea rdi, [rel g88_stops]
    mov esi, 3
    mov edx, NEBO_COLOR_BY_VALUE
    lea rcx, [rel g88_colormap]
    call nebo_colormap_normalize
    test eax, eax
    jnz .failure
    cmp qword [rel g88_colormap + NEBO_COLORMAP_DESC_COLOR_BY_OFFSET], NEBO_COLOR_BY_VALUE
    jne .failure
    mov edi, [rel g88_stops + NEBO_COLORMAP_STOP_COLOR_OFFSET]
    jmp .observe

.mode6:
    call g88_make_seed_color
    test eax, eax
    jnz .failure
    mov edi, [rel g88_color_a]
    mov esi, 0xffffffff
    mov edx, NEBO_CONTRAST_DEFAULT_DELTA
    call nebo_color_contrast_check
    test eax, eax
    jnz .failure
    mov edi, [rel g88_color_a]
    mov esi, 0x000000ff
    mov edx, 0xffffffff
    mov ecx, NEBO_CONTRAST_DEFAULT_DELTA
    lea r8, [rel g88_color_b]
    call nebo_color_pick_accessible
    test eax, eax
    jnz .failure
    mov edi, [rel g88_color_b]
    jmp .observe

.mode7:
    mov edi, NEBO_SPACE_SRGB8
    mov esi, ebx
    mov edx, 42
    mov ecx, 108
    mov r8d, 255
    lea r9, [rel g88_space]
    call nebo_color_space_normalize
    test eax, eax
    jnz .failure
    cmp qword [rel g88_space + NEBO_SPACE_DESC_STATE_OFFSET], NEBO_SPACE_READY
    jne .failure
    mov eax, [rel g88_space + NEBO_SPACE_DESC_C1_OFFSET]
    cmp eax, ebx
    jne .failure
    jmp .success_value

.mode8:
    call g88_make_seed_color
    test eax, eax
    jnz .failure
    mov edi, [rel g88_color_a]
    mov esi, NEBO_COLOR_TARGET_ANSI
    mov edx, NEBO_COLOR_CAP_TRUECOLOR
    lea rcx, [rel g88_target]
    call nebo_color_target_map
    test eax, eax
    jnz .failure
    cmp qword [rel g88_target + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_ANSI_TRUECOLOR
    jne .failure
    mov eax, [rel g88_target + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET]
    shr eax, 16
    and eax, 0xff
    jmp .success_value

.mode9:
    call g88_fill_theme
    lea rdi, [rel g88_theme]
    mov esi, NEBO_THEME_TOKEN_ACCENT
    lea rdx, [rel g88_color_a]
    call nebo_theme_resolve
    test eax, eax
    jnz .failure
    mov edi, [rel g88_color_a]
    mov esi, 0x000000ff
    mov edx, 0xffffffff
    mov ecx, NEBO_CONTRAST_DEFAULT_DELTA
    lea r8, [rel g88_color_b]
    call nebo_color_pick_accessible
    test eax, eax
    jnz .failure
    mov edi, [rel g88_color_b]
    mov esi, NEBO_COLOR_TARGET_HEADLESS
    mov edx, NEBO_COLOR_CAP_ALPHA | NEBO_COLOR_CAP_TRUECOLOR
    lea rcx, [rel g88_target]
    call nebo_color_target_map
    test eax, eax
    jnz .failure
    cmp qword [rel g88_target + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_HEADLESS_RGBA
    jne .failure
    mov edi, [rel g88_target + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET]
    jmp .observe

.observe:
    call nebo_color_red
.success_value:
    cmp eax, ebx
    jne .failure
    jmp .done
.failure:
    mov eax, 188
.done:
    add rsp, 8
    pop r12
    pop rbx
    ret

g88_make_seed_color:
    mov edi, ebx
    mov esi, 42
    mov edx, 108
    lea rcx, [rel g88_color_a]
    jmp nebo_color_rgb_lowering

g88_fill_theme:
    call g88_make_seed_color
    mov eax, [rel g88_color_a]
    mov [rel g88_theme + NEBO_THEME_COLORS_OFFSET], eax
    mov dword [rel g88_theme + NEBO_THEME_COLORS_OFFSET + 4], 0xffffffff
    mov [rel g88_theme + NEBO_THEME_COLORS_OFFSET + 8], eax
    mov dword [rel g88_theme + NEBO_THEME_COLORS_OFFSET + 12], 0x667788ff
    mov dword [rel g88_theme + NEBO_THEME_COLORS_OFFSET + 16], 0x334455ff
    mov dword [rel g88_theme + NEBO_THEME_COLORS_OFFSET + 20], 0x22aa77ff
    mov qword [rel g88_theme + NEBO_THEME_ACCENT_PRESENT_OFFSET], 0
    mov qword [rel g88_theme + NEBO_THEME_STATE_OFFSET], NEBO_THEME_VALID
    ret

; Independent fail-closed checks used by the native group runner.
nebo_g088_negative_probe:
    push rbx
    mov ebx, 1
    xor edi, edi
    mov esi, NEBOC_COLOR_TYPE_ID
    mov edx, 0x112233ff
    lea rcx, [rel g88_typed]
    mov rax, 0xaaaaaaaaaaaaaaaa
    mov [rel g88_typed], rax
    call neboc_color_option_typecheck
    cmp eax, NEBOC_COLOR_OPTION_BARE_COLOR
    jne .bad
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel g88_typed], rax
    jne .bad
    mov ebx, 2
    mov edi, NEBO_ROLE_MAX + 1
    xor esi, esi
    lea rdx, [rel g88_role]
    mov qword [rel g88_role], rax
    call nebo_color_role_define
    cmp eax, NEBO_COLOR_INVALID
    jne .bad
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel g88_role], rax
    jne .bad
    mov ebx, 3
    mov edi, 0x112233ff
    mov esi, 0xffffffff
    mov edx, NEBO_CONTRAST_MAX_DELTA + 1
    call nebo_color_contrast_check
    cmp eax, NEBO_COLOR_INVALID
    jne .bad
    mov ebx, 4
    mov dword [rel g88_color_b], 0xaaaaaaaa
    mov edi, 0x707070ff
    mov esi, 0x808080ff
    mov edx, 0x777777ff
    mov ecx, NEBO_CONTRAST_DEFAULT_DELTA
    lea r8, [rel g88_color_b]
    call nebo_color_pick_accessible
    cmp eax, NEBO_CONTRAST_NO_FALLBACK
    jne .bad
    cmp dword [rel g88_color_b], 0xaaaaaaaa
    jne .bad
    mov ebx, 5
    mov dword [rel g88_stops + NEBO_COLORMAP_STOP_POSITION_OFFSET], 200
    mov dword [rel g88_stops + NEBO_COLORMAP_STOP_SIZE + NEBO_COLORMAP_STOP_POSITION_OFFSET], 100
    lea rdi, [rel g88_stops]
    mov esi, 2
    mov edx, NEBO_COLOR_BY_INDEX
    lea rcx, [rel g88_colormap]
    mov rax, 0xaaaaaaaaaaaaaaaa
    mov qword [rel g88_colormap], rax
    call nebo_colormap_normalize
    cmp eax, NEBO_COLORMAP_ORDER
    jne .bad
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel g88_colormap], rax
    jne .bad
    mov ebx, 6
    mov edi, NEBO_SPACE_GRAY8
    mov esi, 256
    xor edx, edx
    xor ecx, ecx
    mov r8d, 255
    lea r9, [rel g88_space]
    mov qword [rel g88_space], rax
    call nebo_color_space_normalize
    cmp eax, NEBO_SPACE_BOUNDARY
    jne .bad
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel g88_space], rax
    jne .bad
    mov ebx, 7
    mov edi, 0x11223380
    mov esi, NEBO_COLOR_TARGET_ANSI
    xor edx, edx
    lea rcx, [rel g88_target]
    mov qword [rel g88_target], rax
    call nebo_color_target_map
    cmp eax, NEBO_COLOR_ALPHA_UNSUPPORTED
    jne .bad
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel g88_target], rax
    jne .bad
    xor eax, eax
    jmp .negative_done
.bad:
    mov eax, ebx
.negative_done:
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
