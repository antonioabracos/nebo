; OPERADORES-DE-CONJUNTOS-E-RELACOES-FECHAR-SET-LAWS-DETERMINISTIC-ITERATION-PROPERTY-TESTS-E-PERFORMANCE-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F07 — canonicality and deterministic content fingerprint.
bits 64
default rel

section .text
global set_validate_canonical_i64
global set_fingerprint_i64

; rdi=elements,rsi=count -> rax=1 iff strictly ascending (empty is canonical).
set_validate_canonical_i64:
    mov eax, 1
    cmp rsi, 1
    jbe .valid
    mov rdx, [rdi]
    mov ecx, 1
.scan:
    mov r8, [rdi + rcx * 8]
    cmp rdx, r8
    jge .invalid
    mov rdx, r8
    inc rcx
    cmp rcx, rsi
    jb .scan
.valid:
    ret
.invalid:
    xor eax, eax
    ret

; Stable FNV-1a over count and eight bytes of each element.
; rdi=elements,rsi=count -> rax=fingerprint.
set_fingerprint_i64:
    mov rax, 0xcbf29ce484222325
    mov r8, 0x100000001b3
    mov rdx, rsi
    mov ecx, 8
.count_bytes:
    xor al, dl
    imul rax, r8
    shr rdx, 8
    dec ecx
    jnz .count_bytes
    xor r9d, r9d
.element:
    cmp r9, rsi
    jae .done
    mov rdx, [rdi + r9 * 8]
    mov ecx, 8
.bytes:
    xor al, dl
    imul rax, r8
    shr rdx, 8
    dec ecx
    jnz .bytes
    inc r9
    jmp .element
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
