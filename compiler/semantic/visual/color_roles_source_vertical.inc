; G088 token-owned color-role vertical. Public syntax is classified from lexer
; tokens and lowered to one bounded semantic/runtime proof family.
%define G88_FAMILY_KEY 0x5246323034473838

%define G88_SEEN_FG        0x0001
%define G88_SEEN_BG        0x0002
%define G88_SEEN_ACCENT    0x0004
%define G88_SEEN_BORDER    0x0008
%define G88_SEEN_SELECTION 0x0010
%define G88_SEEN_SERIES    0x0020
%define G88_SEEN_PALETTE   0x0040
%define G88_SEEN_THEME     0x0080
%define G88_SEEN_COLORMAP  0x0100
%define G88_SEEN_CONTRAST  0x0200
%define G88_SEEN_SPACE     0x0400
%define G88_SEEN_TARGET    0x0800
%define G88_SEEN_CONSOLE   0x1000

section .rodata
%macro G88_NAME 2
g88_n_%1: db %2
g88_n_%1_len equ $-g88_n_%1
%endmacro
G88_NAME color,'Color'
G88_NAME color_space,'ColorSpace'
G88_NAME palette,'Palette'
G88_NAME console_type,'Console'
G88_NAME fg,'fg'
G88_NAME bg,'bg'
G88_NAME accent,'accent'
G88_NAME border,'border'
G88_NAME selection,'selection'
G88_NAME series,'series'
G88_NAME named,'named'
G88_NAME lookup,'lookup'
G88_NAME theme,'theme'
G88_NAME colormap,'colormap'
G88_NAME color_by,'colorBy'
G88_NAME contrast,'contrast'
G88_NAME accessible,'accessible'
G88_NAME srgb8,'srgb8'
G88_NAME gray8,'gray8'
G88_NAME linear_srgb16,'linearSrgb16'
G88_NAME target,'target'
G88_NAME rgb,'rgb'
G88_NAME rgba,'rgba'
G88_NAME console,'console'
G88_NAME is_opaque,'isOpaque'
G88_NAME red,'red'
G88_NAME hash,'hash'
G88_NAME equals,'equals'
%undef G88_NAME

section .bss align=16
g88_mode: resq 1
g88_seed: resq 1
g88_seed_seen: resq 1
g88_seen: resq 1

section .text
; A G088 model root plus a color-role witness owns the program. Console is
; also a root only when a role method is present. A model root plus `.console`
; is retained solely to reject the contract's ambiguous bare-Color argument.
g88_is_program:
    push r12
    xor r12d, r12d
%macro G88_ROOT 2
    lea rsi, [rel g88_n_%1]
    mov edx, g88_n_%1_len
    call ls_contains_atom
    test eax, eax
    jz %%next
    or r12d, %2
%%next:
%endmacro
    G88_ROOT color,1
    G88_ROOT color_space,2
    G88_ROOT palette,4
    G88_ROOT console_type,8
.roots_ready:
    test r12d, r12d
    jz .no
%macro G88_WITNESS 2
    test r12d, %2
    jz %%next
    lea rsi, [rel g88_n_%1]
    mov edx, g88_n_%1_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
%%next:
%endmacro
    G88_WITNESS fg,9
    G88_WITNESS bg,9
    G88_WITNESS accent,9
    G88_WITNESS border,9
    G88_WITNESS selection,9
    G88_WITNESS series,9
    G88_WITNESS theme,9
    G88_WITNESS contrast,1
    G88_WITNESS accessible,1
    G88_WITNESS target,1
    G88_WITNESS named,4
    G88_WITNESS lookup,4
    G88_WITNESS colormap,4
    G88_WITNESS color_by,4
    G88_WITNESS srgb8,2
    G88_WITNESS gray8,2
    G88_WITNESS linear_srgb16,2
    G88_WITNESS console,1
.no:
    xor eax, eax
    jmp .root_done
.yes:
    mov eax, 1
.root_done:
    pop r12
    ret
%undef G88_WITNESS
%undef G88_ROOT

; RDI token index -> EAX=0 and checked literal, else shared diagnostic 21/22.
g88_expect_u8:
    push rbx
    mov rbx, rdi
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi, rbx
    call ls_token_ptr
    mov rax, [rax + NEBOC_TOKEN_PAYLOAD_OFFSET]
    cmp rax, 255
    ja .range
    cmp qword [rel g88_seed_seen], 0
    jne .ok
    mov [rel g88_seed], rax
    mov qword [rel g88_seed_seen], 1
.ok:
    xor eax, eax
    jmp .done
.type:
    mov eax, 21
    jmp .done
.range:
    mov eax, 22
.done:
    pop rbx
    ret

g88_expect_u16:
    push rbx
    mov rbx, rdi
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi, rbx
    call ls_token_ptr
    mov rax, [rax + NEBOC_TOKEN_PAYLOAD_OFFSET]
    cmp rax, 65535
    ja .range
    cmp qword [rel g88_seed_seen], 0
    jne .ok
    movzx eax, al
    mov [rel g88_seed], rax
    mov qword [rel g88_seed_seen], 1
.ok:
    xor eax, eax
    jmp .done
.type:
    mov eax, 21
    jmp .done
.range:
    mov eax, 22
.done:
    pop rbx
    ret

; Validate three or four comma-separated channel literals after method token.
; RDI=method token, ESI=arity.
g88_validate_channels:
    push rbx
    push r12
    mov rbx, rdi
    mov r12d, esi
    lea rdi, [rbx + 2]
    call g88_expect_u8
    test eax, eax
    jnz .done
    lea rdi, [rbx + 3]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 4]
    call g88_expect_u8
    test eax, eax
    jnz .done
    lea rdi, [rbx + 5]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 6]
    call g88_expect_u8
    test eax, eax
    jnz .done
    cmp r12d, 3
    je .close3
    lea rdi, [rbx + 7]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 8]
    call g88_expect_u8
    test eax, eax
    jnz .done
    lea rdi, [rbx + 9]
    jmp .close
.close3:
    lea rdi, [rbx + 7]
.close:
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    jne .arity
    xor eax, eax
    jmp .done
.arity:
    mov eax, 25
.done:
    pop r12
    pop rbx
    ret

; RDI=method token. Typed roles accept one Color expression/identifier, while
; fg/bg also preserve the historical three-u8 overload.
; RDI=argument token -> EAX boolean for Color.rgb/rgba or an earlier `: Color`
; binding with the same lexeme. This is a bounded nominal check, not a generic
; identifier-shaped acceptance.
g88_is_color_expression:
    push rbx
    push r12
    mov r12, rdi
    lea rsi, [rel g88_n_color]
    mov edx, g88_n_color_len
    call ls_token_match
    test eax, eax
    jz .binding
    lea rdi, [r12 + 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_DOT
    jne .no
    lea rdi, [r12 + 2]
    lea rsi, [rel g88_n_rgb]
    mov edx, g88_n_rgb_len
    call ls_token_match
    test eax, eax
    jnz .yes
    lea rdi, [r12 + 2]
    lea rsi, [rel g88_n_rgba]
    mov edx, g88_n_rgba_len
    call ls_token_match
    test eax, eax
    jnz .yes
    jmp .no
.binding:
    xor ebx, ebx
.binding_loop:
    cmp rbx, r12
    jae .no
    mov rdi, rbx
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .binding_next
    mov rdi, rbx
    mov rsi, r12
    call ls_name_equal
    test eax, eax
    jz .binding_next
    lea rdi, [rbx + 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RESERVED_COLON
    jne .binding_next
    lea rdi, [rbx + 2]
    lea rsi, [rel g88_n_color]
    mov edx, g88_n_color_len
    call ls_token_match
    test eax, eax
    jnz .yes
.binding_next:
    inc rbx
    jmp .binding_loop
.yes:
    mov eax, 1
    jmp .done
.no:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

; RDI=method token -> EAX=0 only for one Color expression.
g88_validate_single_color:
    push rbx
    push r12
    push r13
    mov rbx, rdi
    lea rdi, [rbx + 2]
    call g88_is_color_expression
    test eax, eax
    jz .type
    lea r12, [rbx + 2]
    xor r13d, r13d
.scan:
    mov rdi, r12
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_LPAREN
    je .open
    cmp eax, NEBOC_TOKEN_RPAREN
    je .close
    cmp eax, NEBOC_TOKEN_COMMA
    jne .next
    test r13d, r13d
    jz .arity
    jmp .next
.open:
    inc r13d
    jmp .next
.close:
    test r13d, r13d
    jz .ok
    dec r13d
.next:
    inc r12
    cmp r12, [rel ls_token_count]
    jb .scan
.arity:
    mov eax, 25
    jmp .single_done
.type:
    mov eax, 21
    jmp .single_done
.ok:
    xor eax, eax
.single_done:
    pop r13
    pop r12
    pop rbx
    ret

; RDI=method token -> EAX=0 only for Color expression plus u8 threshold.
g88_validate_contrast:
    push rbx
    push r12
    push r13
    mov rbx, rdi
    lea rdi, [rbx + 2]
    call g88_is_color_expression
    test eax, eax
    jz .type
    lea r12, [rbx + 2]
    xor r13d, r13d
.scan:
    mov rdi, r12
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_LPAREN
    je .open
    cmp eax, NEBOC_TOKEN_RPAREN
    je .close
    cmp eax, NEBOC_TOKEN_COMMA
    jne .next
    test r13d, r13d
    jnz .next
    lea rdi, [r12 + 1]
    call g88_expect_u8
    test eax, eax
    jnz .contrast_done
    lea rdi, [r12 + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    jne .arity
    xor eax, eax
    jmp .contrast_done
.open:
    inc r13d
    jmp .next
.close:
    test r13d, r13d
    jz .arity
    dec r13d
.next:
    inc r12
    cmp r12, [rel ls_token_count]
    jb .scan
.arity:
    mov eax, 25
    jmp .contrast_done
.type:
    mov eax, 21
.contrast_done:
    pop r13
    pop r12
    pop rbx
    ret

g88_validate_role:
    push rbx
    mov rbx, rdi
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .typed
    mov rdi, rbx
    mov esi, 3
    call g88_validate_channels
    jmp .done
.typed:
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .type
    lea rdi, [rbx + 2]
    call g88_is_color_expression
    test eax, eax
    jz .type
    xor eax, eax
    jmp .done
.type:
    mov eax, 21
.done:
    pop rbx
    ret

; RDI method token -> EAX=0 or stable shared diagnostic 20..25.
g88_validate_method:
    push rbx
    push r12
    mov rbx, rdi
    lea rdi, [rbx + 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_LPAREN
    jne .syntax
%macro G88_METHOD 2
    mov rdi, rbx
    lea rsi, [rel g88_n_%1]
    mov edx, g88_n_%1_len
    call ls_token_match
    test eax, eax
    jnz %2
%endmacro
    G88_METHOD fg,.fg
    G88_METHOD bg,.bg
    G88_METHOD accent,.accent
    G88_METHOD border,.border
    G88_METHOD selection,.selection
    G88_METHOD series,.series
    G88_METHOD named,.named
    G88_METHOD lookup,.text
    G88_METHOD theme,.theme
    G88_METHOD colormap,.colormap
    G88_METHOD color_by,.color_by
    G88_METHOD contrast,.contrast
    G88_METHOD accessible,.accessible
    G88_METHOD srgb8,.srgb8
    G88_METHOD gray8,.gray8
    G88_METHOD linear_srgb16,.linear
    G88_METHOD target,.target
    G88_METHOD rgb,.rgb
    G88_METHOD rgba,.rgba
    G88_METHOD console,.console
    G88_METHOD is_opaque,.empty
    G88_METHOD red,.empty
    G88_METHOD hash,.empty
    G88_METHOD equals,.one_expression
    mov eax, 24
    jmp .done
.fg:
    or qword [rel g88_seen], G88_SEEN_FG
    mov rdi, rbx
    call g88_validate_role
    jmp .done
.bg:
    or qword [rel g88_seen], G88_SEEN_BG
    mov rdi, rbx
    call g88_validate_role
    jmp .done
.accent:
    or qword [rel g88_seen], G88_SEEN_ACCENT
    jmp .typed_role
.border:
    or qword [rel g88_seen], G88_SEEN_BORDER
    jmp .typed_role
.selection:
    or qword [rel g88_seen], G88_SEEN_SELECTION
    jmp .typed_role
.series:
    or qword [rel g88_seen], G88_SEEN_SERIES
.typed_role:
    mov rdi, rbx
    call g88_validate_role
    jmp .done
.named:
    or qword [rel g88_seen], G88_SEEN_PALETTE
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_TEXT
    jne .type
    lea rdi, [rbx + 3]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 4]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .type
    lea rdi, [rbx + 4]
    call g88_is_color_expression
    test eax, eax
    jz .type
    xor eax, eax
    jmp .done
.theme:
    or qword [rel g88_seen], G88_SEEN_THEME
    jmp .text
.colormap:
    or qword [rel g88_seen], G88_SEEN_COLORMAP
    jmp .text
.color_by:
    or qword [rel g88_seen], G88_SEEN_COLORMAP
    jmp .text
.target:
    or qword [rel g88_seen], G88_SEEN_TARGET
.text:
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_TEXT
    jne .type
    lea rdi, [rbx + 3]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    jne .arity
    xor eax, eax
    jmp .done
.contrast:
    or qword [rel g88_seen], G88_SEEN_CONTRAST
    mov rdi, rbx
    call g88_validate_contrast
    jmp .done
.accessible:
    or qword [rel g88_seen], G88_SEEN_CONTRAST
    mov rdi, rbx
    call g88_validate_single_color
    jmp .done
.srgb8:
    or qword [rel g88_seen], G88_SEEN_SPACE
    mov rdi, rbx
    mov esi, 4
    call g88_validate_channels
    jmp .done
.rgb:
    mov rdi, rbx
    mov esi, 3
    call g88_validate_channels
    jmp .done
.rgba:
    mov rdi, rbx
    mov esi, 4
    call g88_validate_channels
    jmp .done
.gray8:
    or qword [rel g88_seen], G88_SEEN_SPACE
    lea rdi, [rbx + 2]
    call g88_expect_u8
    test eax, eax
    jnz .done
    lea rdi, [rbx + 3]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 4]
    call g88_expect_u8
    test eax, eax
    jnz .done
    lea rdi, [rbx + 5]
    jmp .close_one
.linear:
    or qword [rel g88_seen], G88_SEEN_SPACE
    mov r12d, 0
.linear_arg:
    lea rdi, [rbx + 2]
    mov eax, r12d
    shl eax, 1
    add rdi, rax
    call g88_expect_u16
    test eax, eax
    jnz .done
    inc r12d
    cmp r12d, 4
    jae .linear_close
    lea rdi, [rbx + 1]
    mov eax, r12d
    shl eax, 1
    add rdi, rax
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    jmp .linear_arg
.linear_close:
    lea rdi, [rbx + 9]
.close_one:
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    jne .arity
    xor eax, eax
    jmp .done
.console:
    or qword [rel g88_seen], G88_SEEN_CONSOLE
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .console_ok
    lea rsi, [rel g88_n_color]
    mov edx, g88_n_color_len
    lea rdi, [rbx + 2]
    call ls_token_match
    test eax, eax
    jnz .bare
.console_ok:
    xor eax, eax
    jmp .done
.empty:
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    jne .arity
    xor eax, eax
    jmp .done
.one_expression:
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    je .arity
    xor eax, eax
    jmp .done
.bare:
    mov eax, 24
    jmp .done
.type:
    mov eax, 21
    jmp .done
.arity:
    mov eax, 25
    jmp .done
.syntax:
    mov eax, 20
.done:
%undef G88_METHOD
    pop r12
    pop rbx
    ret

g88_select_mode:
%macro G88_MODE 2
    mov rax, [rel g88_seen]
    and rax, %1
    cmp rax, %1
    jne %%next
    mov eax, %2
    ret
%%next:
%endmacro
    G88_MODE (G88_SEEN_CONSOLE|G88_SEEN_THEME|G88_SEEN_ACCENT|G88_SEEN_FG),9
    G88_MODE G88_SEEN_TARGET,8
    G88_MODE G88_SEEN_SPACE,7
    G88_MODE G88_SEEN_CONTRAST,6
    G88_MODE G88_SEEN_COLORMAP,5
    G88_MODE G88_SEEN_THEME,4
    G88_MODE G88_SEEN_PALETTE,3
    G88_MODE (G88_SEEN_ACCENT|G88_SEEN_BORDER|G88_SEEN_SELECTION|G88_SEEN_SERIES),2
    G88_MODE (G88_SEEN_FG|G88_SEEN_BG),1
    xor eax, eax
    ret
%undef G88_MODE

g88_scan_program:
    push rbx
    xor ebx, ebx
.scan:
    cmp rbx, [rel ls_token_count]
    jae .finish
    mov rdi, rbx
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_EOF
    je .finish
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .identifier
    cmp qword [rel g88_seed_seen], 0
    jne .next
    mov rdi, rbx
    call ls_token_ptr
    mov rax, [rax + NEBOC_TOKEN_PAYLOAD_OFFSET]
    cmp rax, 255
    ja .next
    mov [rel g88_seed], rax
    mov qword [rel g88_seed_seen], 1
    jmp .next
.identifier:
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .dot
    mov rdi, rbx
    lea rsi, [rel g88_n_color]
    mov edx, g88_n_color_len
    call ls_token_match
    test eax, eax
    jz .next
    test rbx, rbx
    jz .next
    lea rdi, [rbx - 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_DOT
    jne .next
    lea rdi, [rbx + 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_LPAREN
    je .syntax
    jmp .next
.dot:
    cmp eax, NEBOC_TOKEN_DOT
    jne .next
    lea rdi, [rbx + 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .next
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_LPAREN
    jne .next
    lea rdi, [rbx + 1]
    call g88_validate_method
    test eax, eax
    jnz .done
.next:
    inc rbx
    jmp .scan
.finish:
    test rbx, rbx
    jz .syntax
    lea rdi, [rbx - 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RBRACE
    jne .syntax
    cmp qword [rel g88_seed_seen], 1
    jne .syntax
    call g88_select_mode
    test eax, eax
    jz .syntax
    mov [rel g88_mode], rax
    xor eax, eax
    jmp .done
.syntax:
    mov eax, 20
.done:
    pop rbx
    ret

neboc_g088_source_parse:
    mov qword [rel g88_mode], 0
    mov qword [rel g88_seed], 0
    mov qword [rel g88_seed_seen], 0
    mov qword [rel g88_seen], 0
    mov qword [rel ls_cursor], 0
    call ls_start_header
    test eax, eax
    jz .syntax
    call g88_scan_program
    test eax, eax
    jnz .diagnostic
    mov rax, [rel g88_mode]
    shl rax, 32
    mov edi, dword [rel g88_seed]
    or rdi, rax
    mov esi, NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx, G88_FAMILY_KEY
    call ls_success
    ret
.syntax:
    mov edi, 20
    call ls_error
    ret
.diagnostic:
    mov edi, eax
    call ls_error
    ret
