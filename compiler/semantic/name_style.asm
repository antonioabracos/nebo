; Nebo Assembly — CONSTBINDING-POR-ALL-CAPS-E-IDENTIDADE-DE-NOMES lexical identifier-style classification
bits 64
default rel

%include "compiler/semantic/name_style.inc"

global neboc_name_style_classify
global neboc_name_is_all_caps

section .text

; const u8 *spelling in rdi, byte length in rsi
; eax = NEBOC_RF116_NAME_*; no memory is written.
neboc_name_style_classify:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBOC_NAME_MAX_BYTES
    ja .invalid

    xor ecx, ecx                    ; byte index
    xor r8d, r8d                    ; saw underscore
    xor r9d, r9d                    ; saw lowercase
    xor r10d, r10d                  ; all-caps candidate remains valid
    movzx eax, byte [rdi]
    cmp al, 'A'
    jb .first_not_upper
    cmp al, 'Z'
    ja .first_not_upper
    mov r10d, 1
    jmp .scan

.first_not_upper:
    cmp al, 'a'
    jb .first_special
    cmp al, 'z'
    jbe .first_lower
.first_special:
    cmp al, '_'
    je .first_ordinary
    cmp al, 0x80
    jae .first_ordinary
    jmp .invalid
.first_lower:
    mov r9d, 1
    jmp .scan
.first_ordinary:
    xor r10d, r10d

.scan:
    inc rcx
    cmp rcx, rsi
    jae .classify
    movzx eax, byte [rdi + rcx]
    cmp al, 'A'
    jb .not_upper
    cmp al, 'Z'
    jbe .scan
.not_upper:
    cmp al, 'a'
    jb .not_lower
    cmp al, 'z'
    jbe .lower
.not_lower:
    cmp al, '0'
    jb .not_digit
    cmp al, '9'
    jbe .scan
.not_digit:
    cmp al, '_'
    je .underscore
    cmp al, 0x80
    jae .ordinary_byte
    jmp .invalid
.lower:
    mov r9d, 1
    xor r10d, r10d
    jmp .scan
.ordinary_byte:
    xor r10d, r10d
    jmp .scan
.underscore:
    mov r8d, 1
    test r10d, r10d
    jz .scan
    ; ALL_CAPS requires exactly one separator and a non-empty following part.
    lea rax, [rcx + 1]
    cmp rax, rsi
    jae .not_all_caps
    cmp byte [rdi + rcx - 1], '_'
    je .not_all_caps
    jmp .scan
.not_all_caps:
    xor r10d, r10d
    jmp .scan

.classify:
    test r10d, r10d
    jnz .all_caps
    test r8d, r8d
    jnz .ordinary
    movzx eax, byte [rdi]
    cmp al, 'a'
    jb .maybe_pascal
    cmp al, 'z'
    jbe .camel
.maybe_pascal:
    cmp al, 'A'
    jb .ordinary
    cmp al, 'Z'
    ja .ordinary
    test r9d, r9d
    jz .ordinary
    mov eax, NEBOC_NAME_PASCAL_CASE
    ret
.camel:
    mov eax, NEBOC_NAME_CAMEL_CASE
    ret
.all_caps:
    mov eax, NEBOC_NAME_ALL_CAPS
    ret
.ordinary:
    mov eax, NEBOC_NAME_ORDINARY
    ret
.invalid:
    mov eax, NEBOC_NAME_INVALID
    ret

; Same inputs; eax = 1 only for [A-Z][A-Z0-9]*(?:_[A-Z0-9]+)*.
neboc_name_is_all_caps:
    call neboc_name_style_classify
    cmp eax, NEBOC_NAME_ALL_CAPS
    sete al
    movzx eax, al
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
