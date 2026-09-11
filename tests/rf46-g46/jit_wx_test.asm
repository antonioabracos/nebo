bits 64
default rel

extern nebo_jit_new
extern nebo_jit_set_budget
extern nebo_jit_compile_i64_v0
extern nebo_jit_call_i64_v0
extern nebo_jit_address_privileged
extern nebo_jit_invalidate
extern nebo_jit_code_cache
extern nebo_jit_collect
extern nebo_jit_security_report

section .bss align=16
session: resb 48

section .text
global _start
_start:
    lea rdi,[rel session]
    xor esi,esi
    call nebo_jit_new
    cmp rax,-4602
    jne .fail
    cmp qword [rel session+24],0
    jne .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_new
    test rax,rax
    jnz .fail
    lea rdi,[rel session]
    mov esi,4096
    mov edx,1
    mov ecx,1000
    call nebo_jit_set_budget
    test rax,rax
    jnz .fail
    lea rdi,[rel session]
    mov esi,0x9999
    mov edx,42
    call nebo_jit_compile_i64_v0
    cmp rax,-4602
    jne .fail
    cmp qword [rel session],0
    jne .fail
    lea rdi,[rel session]
    mov esi,0x4634
    mov edx,42
    call nebo_jit_compile_i64_v0
    test rax,rax
    jnz .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_address_privileged
    test rax,rax
    jle .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_code_cache
    test rax,rax
    jle .fail
    cmp rdx,11
    jne .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_call_i64_v0
    cmp rax,42
    jne .fail
    lea rdi,[rel session]
    call nebo_jit_security_report
    cmp rax,2
    jne .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_invalidate
    test rax,rax
    jnz .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_call_i64_v0
    cmp rax,-4603
    jne .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_collect
    test rax,rax
    jnz .fail
    cmp qword [rel session],0
    jne .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_collect
    cmp rax,-4603
    jne .fail
    xor edi,edi
    jmp .exit
.fail:
    mov edi,1
.exit:
    mov eax,60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
