default rel
section .text
global nebo_divergence_i64, nebo_curl3_i64
nebo_divergence_i64:
    test rdi, rdi
    jz .div_invalid
    test rsi, rsi
    jz .div_invalid
    cmp rsi, 16
    ja .div_invalid
    xor eax, eax
    xor ecx, ecx
.div_loop:
    add rax, [rdi+rcx*8]
    jo .div_overflow
    inc rcx
    cmp rcx, rsi
    jb .div_loop
    xor edx, edx
    ret
.div_invalid: xor eax, eax
    mov edx, 1
    ret
.div_overflow: xor eax, eax
    mov edx, 2
    ret
; rdi=3x3 Jacobian row-major, rsi=caller-owned out[3].
nebo_curl3_i64:
    test rdi, rdi
    jz .curl_invalid
    test rsi, rsi
    jz .curl_invalid
    mov rax, [rdi+56]
    sub rax, [rdi+40]
    jo .curl_invalid
    mov rdx, [rdi+16]
    sub rdx, [rdi+48]
    jo .curl_invalid
    mov rcx, [rdi+24]
    sub rcx, [rdi+8]
    jo .curl_invalid
    mov [rsi], rax
    mov [rsi+8], rdx
    mov [rsi+16], rcx
    xor eax, eax
    ret
.curl_invalid: mov eax, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
