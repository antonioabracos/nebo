; OPERADORES-DE-CONJUNTOS-E-RELACOES-FECHAR-EMPTY-SET-LITERAL-E-TYPE-INFERENCE-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F06 — typed empty-set descriptor.
bits 64
default rel

section .text
global empty_set_init
global set_element_types_match

; Descriptor: +0 element-type tag, +8 data pointer, +16 element count.
; rdi=descriptor, rsi=nonzero type tag -> rax=0 or -2; invalid input writes nothing.
empty_set_init:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov [rdi], rsi
    mov qword [rdi + 8], 0
    mov qword [rdi + 16], 0
    xor eax, eax
    ret
.invalid:
    mov rax, -2
    ret

; rdi=left descriptor,rsi=right descriptor -> rax boolean.
set_element_types_match:
    xor eax, eax
    test rdi, rdi
    jz .done
    test rsi, rsi
    jz .done
    mov rdx, [rdi]
    cmp rdx, [rsi]
    sete al
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
