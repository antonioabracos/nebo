; RF166-G165-F02: Interface round-trip, corruption, cache e compatibility corpus
; Bounded RF166 conformance-record validator.  This is an internal native test
; probe, not a public source/CLI surface.  rdi=record, rsi=bytes,
; rdx=caller-owned aligned 32-byte result.  Publication is failure atomic.
bits 64
default rel
global neboc_rf166_interface_fuzz_conformance

%define RF166_RECORD_MAGIC 0x34434652
%define RF166_RECORD_MAX_BYTES 4096
%define RF166_RECORD_MAX_CASES 256
%define RF166_RECORD_TAG 2
%define hover_FNV_OFFSET 0xcbf29ce484222325
%define hover_FNV_PRIME  0x100000001b3

section .text
align 16
neboc_rf166_interface_fuzz_conformance:
    test rdi, rdi
    jz .argument
    test rdx, rdx
    jz .argument
    test rdx, 7
    jnz .argument
    cmp rsi, 17
    jb .length
    cmp rsi, RF166_RECORD_MAX_BYTES
    ja .length
    lea rax, [rdi + rsi]
    cmp rax, rdi
    jb .length
    cmp dword [rdi], RF166_RECORD_MAGIC
    jne .schema
    cmp byte [rdi + 4], 1
    jne .schema
    cmp byte [rdi + 5], RF166_RECORD_TAG
    jne .domain
    movzx eax, word [rdi + 6]
    test eax, 0xfff0
    jnz .domain
    mov eax, dword [rdi + 8]
    mov rcx, rsi
    sub rcx, 16
    cmp rax, rcx
    jne .budget
    mov r10d, dword [rdi + 12]
    test r10d, r10d
    jz .budget
    cmp r10d, RF166_RECORD_MAX_CASES
    ja .budget
    cmp r10, rcx
    ja .budget
    mov rax, hover_FNV_OFFSET
    mov r8, hover_FNV_PRIME
    mov ecx, 16
.scan:
    cmp rcx, rsi
    jae .publish
    movzx r9d, byte [rdi + rcx]
    cmp r9b, 0x20
    jb .encoding
    cmp r9b, 0x7e
    ja .encoding
    xor rax, r9
    imul rax, r8
    inc rcx
    jmp .scan
.publish:
    xor rax, RF166_RECORD_TAG
    mov qword [rdx], rax
    mov qword [rdx + 8], rsi
    mov qword [rdx + 16], RF166_RECORD_TAG
    mov qword [rdx + 24], r10
    xor eax, eax
    xor edx, edx
    ret
.argument:
    mov eax, 1
    mov edx, 1
    ret
.length:
    mov eax, 2
    mov edx, 2
    ret
.schema:
    mov eax, 3
    mov edx, 3
    ret
.domain:
    mov eax, 4
    mov edx, 4
    ret
.budget:
    mov eax, 5
    mov edx, 5
    ret
.encoding:
    mov eax, 6
    mov edx, 6
    ret
