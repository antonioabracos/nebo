default rel
section .text
global nebo_template_context_plan
; edi=context 0 plain/1 interpolation/2 placeholder/3 Slash,
; esi=inside Text template, edx=depth, ecx=node budget.
; eax=stable plan id, edx=status.
nebo_template_context_plan:
    cmp edi, 3
    ja .kind
    test edi, edi
    jz .limits
    cmp esi, 1
    jne .context
.limits:
    cmp edx, 64
    ja .limit
    test ecx, ecx
    jz .limit
    cmp ecx, 4096
    ja .limit
    lea eax, [rdi+142001]
    xor edx, edx
    ret
.context:
    xor eax, eax
    mov edx, 1
    ret
.kind:
    xor eax, eax
    mov edx, 2
    ret
.limit:
    xor eax, eax
    mov edx, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
