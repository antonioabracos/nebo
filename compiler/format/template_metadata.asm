default rel
section .text
global nebo_template_metadata
; rdi=escaping 0 raw/1 text/2 html/3 json, rsi=privacy 0 public/1 private/2 secret,
; rdx=fallback 0 none/1 literal/2 typed marker, rcx=out[5].
nebo_template_metadata:
    test rcx, rcx
    jz .invalid
    cmp rdi, 3
    ja .invalid
    cmp rsi, 2
    ja .invalid
    cmp rdx, 2
    ja .invalid
    cmp rsi, 2
    jne .publish
    test rdi, rdi
    jz .privacy
    test rdx, rdx
    jnz .privacy
.publish:
    mov [rcx], rdi
    mov [rcx+8], rsi
    mov [rcx+16], rdx
    mov qword [rcx+24], 4096
    mov qword [rcx+32], 0
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.privacy:
    mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
