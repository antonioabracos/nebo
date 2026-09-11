; G087 token-owned public Color vertical. It validates constructor shapes,
; checked channel bounds and compile-time hex literals without fixture paths.
%define G87_FAMILY_KEY 0x5246323034473837

%define G87_SEEN_RGB        0x0001
%define G87_SEEN_RGBA       0x0002
%define G87_SEEN_HEX        0x0004
%define G87_SEEN_PARSE      0x0008
%define G87_SEEN_RED        0x0010
%define G87_SEEN_GREEN      0x0020
%define G87_SEEN_BLUE       0x0040
%define G87_SEEN_ALPHA      0x0080
%define G87_SEEN_WITH_ALPHA 0x0100
%define G87_SEEN_OPAQUE     0x0200
%define G87_SEEN_TO_HEX     0x0400
%define G87_SEEN_TO_HEX_A   0x0800
%define G87_SEEN_HASH       0x1000
%define G87_SEEN_DIRECT     0x2000

section .rodata
%macro G87_NAME 2
g87_n_%1: db %2
g87_n_%1_len equ $-g87_n_%1
%endmacro
G87_NAME color,'Color'
G87_NAME rgb,'rgb'
G87_NAME rgba,'rgba'
G87_NAME hex,'hex'
G87_NAME parse_hex,'parseHex'
G87_NAME red,'red'
G87_NAME green,'green'
G87_NAME blue,'blue'
G87_NAME alpha,'alpha'
G87_NAME with_alpha,'withAlpha'
G87_NAME is_opaque,'isOpaque'
G87_NAME to_hex,'toHex'
G87_NAME to_hex_alpha,'toHexWithAlpha'
G87_NAME equals,'equals'
G87_NAME hash,'hash'
G87_NAME is_ok,'isOk'
%undef G87_NAME

section .bss align=16
g87_mode: resq 1
g87_seed: resq 1
g87_seed_seen: resq 1
g87_seen: resq 1

section .text
; A Color root plus a G087-specific member owns the program. This excludes the
; older G019 media vertical, whose Color programs require media-only witnesses.
g87_is_program:
    lea rsi, [rel g87_n_color]
    mov edx, g87_n_color_len
    call ls_contains_atom
    test eax, eax
    jz .no
%macro G87_WITNESS 1
    lea rsi, [rel g87_n_%1]
    mov edx, g87_n_%1_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
%endmacro
    G87_WITNESS parse_hex
    G87_WITNESS red
    G87_WITNESS green
    G87_WITNESS blue
    G87_WITNESS alpha
    G87_WITNESS with_alpha
    G87_WITNESS is_opaque
    G87_WITNESS to_hex
    G87_WITNESS to_hex_alpha
    G87_WITNESS equals
    G87_WITNESS hash
.no:
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret
%undef G87_WITNESS

; RDI token index -> EAX boolean.
g87_token_is_color:
    lea rsi, [rel g87_n_color]
    mov edx, g87_n_color_len
    jmp ls_token_match

; AL=validated hexadecimal digit -> EAX=nibble.
g87_hex_nibble_unchecked:
    cmp al, '9'
    jbe .decimal
    or al, 0x20
    sub al, 'a' - 10
    movzx eax, al
    ret
.decimal:
    sub al, '0'
    movzx eax, al
    ret

; RDI TEXT token index -> EAX=0 valid canonical #RRGGBB/#RRGGBBAA, else 22.
; The first valid literal also supplies its red byte as the source-effect seed,
; so literal and Text inputs govern emitted code rather than merely validating.
g87_validate_hex_literal:
    push rbx
    push r12
    push r13
    push r14
    mov r14, rdi
    call ls_token_ptr
    test rax, rax
    jz .bad
    mov r12, [rax + NEBOC_TOKEN_START_OFFSET]
    mov r13, [rax + NEBOC_TOKEN_END_OFFSET]
    sub r13, r12
    cmp r13, 9
    je .length_ok
    cmp r13, 11
    jne .bad
.length_ok:
    mov rbx, [rel ls_source]
    add rbx, r12
    cmp byte [rbx], '"'
    jne .bad
    cmp byte [rbx + 1], '#'
    jne .bad
    mov rax, r13
    dec rax
    cmp byte [rbx + rax], '"'
    jne .bad
    mov ecx, 2
.digit:
    mov eax, r13d
    dec eax
    cmp ecx, eax
    jae .ok
    mov al, [rbx + rcx]
    cmp al, '0'
    jb .bad
    cmp al, '9'
    jbe .next
    or al, 0x20
    cmp al, 'a'
    jb .bad
    cmp al, 'f'
    ja .bad
.next:
    inc ecx
    jmp .digit
.ok:
    cmp qword [rel g87_seed_seen], 0
    jne .valid
    mov al, [rbx + 2]
    call g87_hex_nibble_unchecked
    shl eax, 4
    mov r12d, eax
    mov al, [rbx + 3]
    call g87_hex_nibble_unchecked
    or eax, r12d
    mov [rel g87_seed], rax
    mov qword [rel g87_seed_seen], 1
.valid:
    xor eax, eax
    jmp .done
.bad:
    mov eax, 22
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI token index -> EAX=0 and checked u8 token, else 21/22.
g87_expect_u8_token:
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

; RDI method token -> EAX=0 or stable legacy diagnostic 20..24.
g87_validate_method_call:
    push rbx
    push r12
    mov rbx, rdi
    lea rdi, [rbx + 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_LPAREN
    jne .syntax
%macro G87_METHOD 3
    mov rdi, rbx
    lea rsi, [rel g87_n_%1]
    mov edx, g87_n_%1_len
    call ls_token_match
    test eax, eax
    jnz %2
%endmacro
    G87_METHOD rgb,.rgb,G87_SEEN_RGB
    G87_METHOD rgba,.rgba,G87_SEEN_RGBA
    G87_METHOD hex,.hex,G87_SEEN_HEX
    G87_METHOD parse_hex,.parse,G87_SEEN_PARSE
    G87_METHOD red,.red,G87_SEEN_RED
    G87_METHOD green,.green,G87_SEEN_GREEN
    G87_METHOD blue,.blue,G87_SEEN_BLUE
    G87_METHOD alpha,.alpha,G87_SEEN_ALPHA
    G87_METHOD with_alpha,.with_alpha,G87_SEEN_WITH_ALPHA
    G87_METHOD is_opaque,.opaque,G87_SEEN_OPAQUE
    G87_METHOD to_hex,.to_hex,G87_SEEN_TO_HEX
    G87_METHOD to_hex_alpha,.to_hex_alpha,G87_SEEN_TO_HEX_A
    G87_METHOD equals,.equals,G87_SEEN_DIRECT
    G87_METHOD hash,.hash,G87_SEEN_HASH
    G87_METHOD is_ok,.is_ok,G87_SEEN_DIRECT
    mov eax, 24
    jmp .done
.rgb:
    or qword [rel g87_seen], G87_SEEN_RGB
    mov r12d, 3
    jmp .numeric
.rgba:
    or qword [rel g87_seen], G87_SEEN_RGBA
    mov r12d, 4
.numeric:
    lea rdi, [rbx + 2]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    lea rdi, [rbx + 3]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 4]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    lea rdi, [rbx + 5]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 6]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    cmp r12d, 3
    je .numeric_close_3
    lea rdi, [rbx + 7]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 8]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    lea rdi, [rbx + 9]
    jmp .expect_close
.numeric_close_3:
    lea rdi, [rbx + 7]
    jmp .expect_close
.hex:
    or qword [rel g87_seen], G87_SEEN_HEX
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_TEXT
    jne .type
    lea rdi, [rbx + 2]
    call g87_validate_hex_literal
    test eax, eax
    jnz .done
    lea rdi, [rbx + 3]
    jmp .expect_close
.parse:
    or qword [rel g87_seen], G87_SEEN_PARSE
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_TEXT
    je .parse_arg
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .type
.parse_arg:
    lea rdi, [rbx + 3]
    jmp .expect_close
.red:
    or qword [rel g87_seen], G87_SEEN_RED
    jmp .empty
.green:
    or qword [rel g87_seen], G87_SEEN_GREEN
    jmp .empty
.blue:
    or qword [rel g87_seen], G87_SEEN_BLUE
    jmp .empty
.alpha:
    or qword [rel g87_seen], G87_SEEN_ALPHA
    jmp .empty
.opaque:
    or qword [rel g87_seen], G87_SEEN_OPAQUE
    jmp .empty
.to_hex:
    or qword [rel g87_seen], G87_SEEN_TO_HEX
    jmp .empty
.to_hex_alpha:
    or qword [rel g87_seen], G87_SEEN_TO_HEX_A
    jmp .empty
.hash:
    or qword [rel g87_seen], G87_SEEN_HASH
.is_ok:
.empty:
    lea rdi, [rbx + 2]
    jmp .expect_close
.with_alpha:
    or qword [rel g87_seen], G87_SEEN_WITH_ALPHA
    lea rdi, [rbx + 2]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    lea rdi, [rbx + 3]
    jmp .expect_close
.equals:
    ; Equality accepts one nested Color expression. Its complete expression
    ; shape is bounded by the outer source scan and native equality owner.
    mov rdi, rbx
    add rdi, 2
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    je .arity
    xor eax, eax
    jmp .done
.expect_close:
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    jne .arity
    xor eax, eax
    jmp .done
.arity:
    mov eax, 25
    jmp .done
.type:
    mov eax, 21
    jmp .done
.syntax:
    mov eax, 20
.done:
%undef G87_METHOD
    pop r12
    pop rbx
    ret

; RDI Color token -> validate direct Color(r,g,b), Color(r,g,b,a) or
; Color(TextLiteral) sugar and mark its source-facing lowering route.
g87_validate_direct:
    push rbx
    mov rbx, rdi
    or qword [rel g87_seen], G87_SEEN_DIRECT
    lea rdi, [rbx + 2]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_TEXT
    je .text
    lea rdi, [rbx + 2]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    lea rdi, [rbx + 3]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 4]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    lea rdi, [rbx + 5]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 6]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    lea rdi, [rbx + 7]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    je .ok
    cmp eax, NEBOC_TOKEN_COMMA
    jne .arity
    lea rdi, [rbx + 8]
    call g87_expect_u8_token
    test eax, eax
    jnz .done
    lea rdi, [rbx + 9]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    jne .arity
    jmp .ok
.text:
    lea rdi, [rbx + 2]
    call g87_validate_hex_literal
    test eax, eax
    jnz .done
    lea rdi, [rbx + 3]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_RPAREN
    jne .arity
.ok:
    xor eax, eax
    jmp .done
.arity:
    mov eax, 25
.done:
    pop rbx
    ret

g87_select_mode:
%macro G87_MODE 2
    mov rax, [rel g87_seen]
    and rax, %1
    cmp rax, %1
    jne %%next
    mov eax, %2
    ret
%%next:
%endmacro
    G87_MODE (G87_SEEN_PARSE|G87_SEEN_WITH_ALPHA|G87_SEEN_TO_HEX_A|G87_SEEN_HASH),10
    G87_MODE (G87_SEEN_PARSE|G87_SEEN_TO_HEX_A|G87_SEEN_HASH),9
    G87_MODE (G87_SEEN_TO_HEX|G87_SEEN_TO_HEX_A),8
    G87_MODE (G87_SEEN_WITH_ALPHA|G87_SEEN_OPAQUE),7
    G87_MODE (G87_SEEN_RED|G87_SEEN_GREEN|G87_SEEN_BLUE|G87_SEEN_ALPHA|G87_SEEN_HASH),6
    G87_MODE (G87_SEEN_DIRECT|G87_SEEN_TO_HEX),5
    G87_MODE G87_SEEN_PARSE,4
    G87_MODE G87_SEEN_HEX,3
    G87_MODE (G87_SEEN_RGB|G87_SEEN_RGBA),2
    G87_MODE G87_SEEN_OPAQUE,1
    xor eax, eax
    ret
%undef G87_MODE

g87_scan_program:
    push rbx
    xor ebx, ebx
.scan:
    cmp rbx, [rel ls_token_count]
    jae .finish
    mov rdi, rbx
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_EOF
    je .finish
    cmp eax, NEBOC_TOKEN_TEXT
    jne .integer
    mov rdi, rbx
    call g87_validate_hex_literal
    ; An arbitrary Text is legal outside Color.hex. Only a canonical Color
    ; spelling contributes a seed; the actual method validator owns rejection.
    jmp .next
.integer:
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .minus
    mov rdi, rbx
    call ls_token_ptr
    mov rdx, [rax + NEBOC_TOKEN_PAYLOAD_OFFSET]
    cmp rdx, 255
    ja .range
    cmp qword [rel g87_seed_seen], 0
    jne .next
    mov qword [rel g87_seed_seen], 1
    mov [rel g87_seed], rdx
    jmp .next
.minus:
    cmp eax, NEBOC_TOKEN_MINUS
    jne .identifier
    lea rdi, [rbx + 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_INTEGER
    je .range
    jmp .next
.identifier:
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .dot
    mov rdi, rbx
    call g87_token_is_color
    test eax, eax
    jz .next
    lea rdi, [rbx + 1]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_LPAREN
    jne .next
    mov rdi, rbx
    call g87_validate_direct
    test eax, eax
    jnz .done
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
    call g87_validate_method_call
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
    cmp qword [rel g87_seed_seen], 1
    jne .syntax
    call g87_select_mode
    test eax, eax
    jz .syntax
    mov [rel g87_mode], rax
    xor eax, eax
    jmp .done
.range:
    mov eax, 22
    jmp .done
.syntax:
    mov eax, 20
.done:
    pop rbx
    ret

neboc_g087_source_parse:
    mov qword [rel g87_mode], 0
    mov qword [rel g87_seed], 0
    mov qword [rel g87_seed_seen], 0
    mov qword [rel g87_seen], 0
    mov qword [rel ls_cursor], 0
    call ls_start_header
    test eax, eax
    jz .syntax
    call g87_scan_program
    test eax, eax
    jnz .diagnostic
    mov rax, [rel g87_mode]
    shl rax, 32
    mov edi, dword [rel g87_seed]
    or rdi, rax
    mov esi, NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx, G87_FAMILY_KEY
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
