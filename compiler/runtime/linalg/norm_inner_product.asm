; POSTFIXOS-MATRICIAIS-INVERSA-NORMAS-E-INNER-PRODUCTS-FECHAR-NORM-X-E-INNER-PRODUCT-U-V-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F05 — exact checked inner product and squared Euclidean norm.
bits 64
default rel

extern dot_i64_checked
section .text
global inner_product_i64_checked
global norm_squared_i64_checked

; rdi=left,rsi=right,rdx=count,rcx=result -> status.
inner_product_i64_checked:
    jmp dot_i64_checked

; rdi=vector,rsi=count,rdx=result -> status; squared norm avoids irrational coercion.
norm_squared_i64_checked:
    mov rcx, rdx
    mov rdx, rsi
    mov rsi, rdi
    jmp dot_i64_checked

section .note.GNU-stack noalloc noexec nowrite progbits
