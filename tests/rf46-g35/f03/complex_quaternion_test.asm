bits 64
default rel
%include "runtime/numeric/complex/complex_quaternion.inc"
extern nebo_complex_mul_f64
extern nebo_complex_conjugate_f64
extern nebo_complex_norm2_f64
extern nebo_quaternion_mul_f64
extern nebo_quaternion_normalize_f64
section .data
ca dq 1.0,2.0
cb dq 3.0,4.0
qa dq 1.0,2.0,3.0,4.0
qb dq 5.0,6.0,7.0,8.0
qscale dq 2.0,0.0,0.0,0.0
qzero dq 0.0,0.0,0.0,0.0
minus5 dq -5.0
ten dq 10.0
five dq 5.0
minus2 dq -2.0
qexpected dq -60.0,12.0,30.0,24.0
one dq 1.0
section .bss
co resq 2
qo resq 4
scalar resq 1
section .text
global _start
_start:
    lea rdi,[co]
    lea rsi,[ca]
    lea rdx,[cb]
    call nebo_complex_mul_f64
    test eax,eax
    jnz fail
    mov rax,[minus5]
    cmp [co],rax
    jne fail
    mov rax,[ten]
    cmp [co+8],rax
    jne fail
    lea rdi,[co]
    lea rsi,[ca]
    call nebo_complex_conjugate_f64
    mov rax,[minus2]
    cmp [co+8],rax
    jne fail
    lea rdi,[ca]
    lea rsi,[scalar]
    call nebo_complex_norm2_f64
    mov rax,[five]
    cmp [scalar],rax
    jne fail
    lea rdi,[qo]
    lea rsi,[qa]
    lea rdx,[qb]
    call nebo_quaternion_mul_f64
    test eax,eax
    jnz fail
    xor ecx,ecx
.check_q:
    mov rax,[qexpected+rcx*8]
    cmp [qo+rcx*8],rax
    jne fail
    inc ecx
    cmp ecx,4
    jb .check_q
    lea rdi,[qo]
    lea rsi,[qscale]
    call nebo_quaternion_normalize_f64
    test eax,eax
    jnz fail
    mov rax,[one]
    cmp [qo],rax
    jne fail
    mov qword [qo],0x1234
    lea rdi,[qo]
    lea rsi,[qzero]
    call nebo_quaternion_normalize_f64
    cmp eax,NEBO_COMPLEX_INVALID
    jne fail
    cmp qword [qo],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
