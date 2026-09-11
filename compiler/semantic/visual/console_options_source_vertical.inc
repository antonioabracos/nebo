; G089 token-owned ConsoleCall/ConsoleOption/RenderIntent source vertical.
; It accepts one bounded model operation followed by a source-derived return.
%define G89_FAMILY_KEY 0x5246323034473839

section .rodata
%macro G89_NAME 2
g89_n_%1: db %2
g89_n_%1_len equ $-g89_n_%1
%endmacro
G89_NAME console_call,'ConsoleCall'
G89_NAME console_option,'ConsoleOption'
G89_NAME render_intent,'RenderIntent'
G89_NAME receiver_first,'receiverFirst'
G89_NAME model,'model'
G89_NAME normalize,'normalize'
G89_NAME named,'named'
G89_NAME kind,'kind'
G89_NAME receipt,'receipt'
G89_NAME safe_plan,'safePlan'
G89_NAME budget,'budget'
G89_NAME diagnostic,'diagnostic'
G89_NAME prepare,'prepare'
%undef G89_NAME

section .text
; A nominal G089 root owns the program. Later adapter groups may install a
; more specific witness before this base-model owner without changing it.
g89_is_program:
    push r12
%macro G89_ROOT 1
    lea rsi, [rel g89_n_%1]
    mov edx, g89_n_%1_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
%endmacro
    G89_ROOT console_call
    G89_ROOT console_option
    G89_ROOT render_intent
    xor eax, eax
    jmp .done
.yes:
    mov eax, 1
.done:
    pop r12
    ret
%undef G89_ROOT

; Match the current method and require the method/root pairing owned by G089.
; EBX=root (1 call, 2 option, 3 intent). Returns EAX=mode or zero.
g89_method_mode:
%macro G89_METHOD 3
    cmp ebx, %3
    jne %%next
    lea rsi, [rel g89_n_%1]
    mov edx, g89_n_%1_len
    call ls_current_atom
    test eax, eax
    jz %%next
    mov eax, %2
    ret
%%next:
%endmacro
    G89_METHOD receiver_first,1,1
    G89_METHOD model,2,2
    G89_METHOD normalize,3,2
    G89_METHOD named,4,2
    G89_METHOD receipt,5,1
    G89_METHOD safe_plan,6,3
    G89_METHOD budget,7,2
    G89_METHOD diagnostic,8,2
    G89_METHOD prepare,9,1
    xor eax, eax
    ret
%undef G89_METHOD

; Parse the exact bounded public conformance form:
;   start() { Root.operation([kind:] seed); seed.return; }
neboc_g089_source_parse:
    push rbx
    push r12
    push r13
    mov qword [rel ls_cursor], 0
    call ls_start_header
    test eax, eax
    jz .syntax
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .syntax
    xor ebx, ebx
%macro G89_PARSE_ROOT 2
    mov rdi, [rel ls_cursor]
    lea rsi, [rel g89_n_%1]
    mov edx, g89_n_%1_len
    call ls_token_match
    test eax, eax
    jz %%next
    mov ebx, %2
    jmp .root_ready
%%next:
%endmacro
    G89_PARSE_ROOT console_call,1
    G89_PARSE_ROOT console_option,2
    G89_PARSE_ROOT render_intent,3
    jmp .syntax
.root_ready:
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax, eax
    jz .arity
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .method
    call g89_method_mode
    test eax, eax
    jz .method
    mov r13, rax
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_LPAREN
    call ls_expect_kind
    test eax, eax
    jz .arity
    cmp r13d, 4
    jne .value
    lea rsi, [rel g89_n_kind]
    mov edx, g89_n_kind_len
    call ls_expect_atom
    test eax, eax
    jz .type
    mov edi, NEBOC_TOKEN_RESERVED_COLON
    call ls_expect_kind
    test eax, eax
    jz .arity
.value:
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi, [rel ls_cursor]
    call ls_token_ptr
    mov r12, [rax + NEBOC_TOKEN_PAYLOAD_OFFSET]
    cmp r12, 255
    ja .range
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax, eax
    jz .arity
    mov edi, NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax, eax
    jz .arity
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .syntax
    mov rdi, [rel ls_cursor]
    call ls_token_ptr
    cmp [rax + NEBOC_TOKEN_PAYLOAD_OFFSET], r12
    jne .method
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax, eax
    jz .syntax
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_KW_RETURN
    jne .syntax
    inc qword [rel ls_cursor]
    call ls_finish_program
    test eax, eax
    jz .syntax
    mov rax, r13
    shl rax, 32
    mov edi, r12d
    or rdi, rax
    mov esi, NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx, G89_FAMILY_KEY
    call ls_success
    jmp .done
.method:
    mov edi, 20
    call ls_error
    jmp .done
.type:
    mov edi, 21
    call ls_error
    jmp .done
.range:
    mov edi, 22
    call ls_error
    jmp .done
.arity:
    mov edi, 25
    call ls_error
    jmp .done
.syntax:
    mov edi, 20
    call ls_error
.done:
    pop r13
    pop r12
    pop rbx
    ret
%undef G89_PARSE_ROOT
