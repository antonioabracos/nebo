; IA-ASSISTIDA-LLM-TOOLS-E-GERACAO-SEGURA-F04 explicit dimension vectors and rational quantity conversion.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/numeric/units/units.inc"
section .text

; rdi=out[16] i8 exponents, rsi=a, rdx=b, ecx=mul/add or div/subtract.
NEBOC_ABI_FUNCTION nebo_dimension_combine_i8
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp ecx,NEBO_UNIT_COMBINE_DIV
    ja .invalid
    xor r10d,r10d
.validate:
    movsx eax,byte [rsi+r10]
    movsx r8d,byte [rdx+r10]
    test ecx,ecx
    jnz .subtract
    add eax,r8d
    jmp .check
.subtract:
    sub eax,r8d
.check:
    cmp eax,127
    jg .overflow
    cmp eax,-128
    jl .overflow
    inc r10d
    cmp r10d,NEBO_UNIT_DIMENSIONS
    jb .validate
    xor r10d,r10d
.write:
    movsx eax,byte [rsi+r10]
    movsx r8d,byte [rdx+r10]
    test ecx,ecx
    jnz .write_sub
    add eax,r8d
    jmp .store
.write_sub:
    sub eax,r8d
.store:
    mov [rdi+r10],al
    inc r10d
    cmp r10d,NEBO_UNIT_DIMENSIONS
    jb .write
    xor eax,eax
    ret
.invalid: mov eax,NEBO_UNIT_INVALID
    ret
.overflow: mov eax,NEBO_UNIT_OVERFLOW
    ret

; rdi=a dims, rsi=b dims.
NEBOC_ABI_FUNCTION nebo_dimension_equal_i8
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    xor ecx,ecx
.loop:
    mov al,[rdi+rcx]
    cmp al,[rsi+rcx]
    jne .mismatch
    inc ecx
    cmp ecx,NEBO_UNIT_DIMENSIONS
    jb .loop
    xor eax,eax
    ret
.mismatch: mov eax,NEBO_UNIT_MISMATCH
    ret
.invalid: mov eax,NEBO_UNIT_INVALID
    ret

; rdi=out rational, rsi=value num, rdx=value den, rcx=scale num, r8=scale den.
NEBOC_ABI_FUNCTION nebo_quantity_convert_i64
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test r8,r8
    jz .invalid
    mov rax,rsi
    imul rax,rcx
    jo .overflow
    mov r9,rax
    mov rax,rdx
    imul rax,r8
    jo .overflow
    test rax,rax
    jle .invalid
    mov r10,rax
    mov rax,r9
    test rax,rax
    jns .abs_ready
    neg rax
    jo .overflow
.abs_ready:
    mov rcx,r10
.gcd:
    test rcx,rcx
    jz .reduce
    xor edx,edx
    div rcx
    mov rax,rcx
    mov rcx,rdx
    jmp .gcd
.reduce:
    mov rcx,rax
    mov rax,r9
    cqo
    idiv rcx
    mov [rdi],rax
    mov rax,r10
    xor edx,edx
    div rcx
    mov [rdi+8],rax
    xor eax,eax
    ret
.invalid: mov eax,NEBO_UNIT_INVALID
    ret
.overflow: mov eax,NEBO_UNIT_OVERFLOW
    ret

; edi=unit kind, esi=operation (1 multiply/divide absolute).
NEBOC_ABI_FUNCTION nebo_unit_affine_guard
    cmp edi,NEBO_UNIT_AFFINE_DELTA
    ja .invalid
    cmp edi,NEBO_UNIT_AFFINE_ABSOLUTE
    jne .ok
    test esi,esi
    jnz .misuse
.ok: xor eax,eax
    ret
.invalid: mov eax,NEBO_UNIT_INVALID
    ret
.misuse: mov eax,NEBO_UNIT_AFFINE_MISUSE
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
