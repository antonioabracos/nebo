; Native stdin/stdout adapter for the canonical G154 Assembly owners.
; It performs no parsing of Nebo source and uses no C or libc.

bits 64
default rel

%include "compiler/interface/interface_v1.inc"

global _start
extern neboc_interface_write_records
extern neboc_interface_read
extern neboc_interface_module_decode
extern neboc_interface_compatibility
extern neboc_interface_cache_lookup

section .text

arg_equals:
    xor eax, eax
.loop:
    mov dl, byte [rdi]
    cmp dl, byte [rsi]
    jne .no
    test dl, dl
    jz .yes
    inc rdi
    inc rsi
    jmp .loop
.yes:
    mov eax, 1
.no:
    ret

; rdi=buffer, rsi=exact length -> eax=0/1.
read_exact:
    mov r8, rdi
    mov r9, rsi
.loop:
    test r9, r9
    jz .success
    xor eax, eax
    xor edi, edi
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    jle .failure
    add r8, rax
    sub r9, rax
    jmp .loop
.success:
    xor eax, eax
    ret
.failure:
    mov eax, 1
    ret

; rdi=buffer, rsi=capacity -> rax=length, or -1.
read_bounded:
    mov r8, rdi
    mov r9, rsi
    xor r10d, r10d
.loop:
    test r9, r9
    jz .done
    xor eax, eax
    xor edi, edi
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    js .failure
    jz .done
    add r8, rax
    add r10, rax
    sub r9, rax
    jmp .loop
.done:
    mov rax, r10
    ret
.failure:
    mov rax, -1
    ret

; rdi=bytes, rsi=length -> eax=0/1.
write_all:
    mov r8, rdi
    mov r9, rsi
.loop:
    test r9, r9
    jz .success
    mov eax, 1
    mov edi, 1
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    jle .failure
    add r8, rax
    sub r9, rax
    jmp .loop
.success:
    xor eax, eax
    ret
.failure:
    mov eax, 1
    ret

_start:
    cmp qword [rsp], 2
    jne usage
    mov rdi, qword [rsp + 16]
    lea rsi, [rel arg_emit]
    call arg_equals
    test eax, eax
    jnz mode_emit
    mov rdi, qword [rsp + 16]
    lea rsi, [rel arg_inspect]
    call arg_equals
    test eax, eax
    jnz mode_inspect
    mov rdi, qword [rsp + 16]
    lea rsi, [rel arg_compat]
    call arg_equals
    test eax, eax
    jnz mode_compat
    mov rdi, qword [rsp + 16]
    lea rsi, [rel arg_cache]
    call arg_equals
    test eax, eax
    jnz mode_cache
    mov rdi, qword [rsp + 16]
    lea rsi, [rel arg_module]
    call arg_equals
    test eax,eax
    jnz mode_module
    jmp usage

mode_module:
    lea rdi,[rel interface_bytes]
    mov esi,NEBOC_NI_MAX_BYTES+1
    call read_bounded
    cmp rax,-1
    je io_failure
    mov rsi,rax
    lea rdi,[rel interface_bytes]
    lea rdx,[rel native_result+16]
    call neboc_interface_module_decode
    mov dword [rel native_result],eax
    mov dword [rel native_result+8],edx
    lea rdi,[rel native_result]
    mov esi,144
    call write_all
    test eax,eax
    jnz io_failure
    jmp success

mode_emit:
    lea rdi, [rel emit_input]
    mov esi, 152
    call read_exact
    test eax, eax
    jnz io_failure
    mov rax, qword [rel emit_input]
    mov qword [rel write_request], rax
    mov rax, qword [rel emit_input + 8]
    mov qword [rel write_request + 8], rax
    mov rax, qword [rel emit_input + 16]
    mov qword [rel write_request + 16], rax
    ; The native module owner supplies visibility in the export record.  Only
    ; public records cross the compiled-interface boundary; private/internal
    ; declarations produce an authenticated empty public surface.
    cmp dword [rel emit_input + 44], 1
    jne .emit_private_surface
    lea rax, [rel emit_input + 24]
    mov qword [rel write_request + 24], rax
    mov qword [rel write_request + 32], 1
    lea rax, [rel emit_input + 88]
    mov qword [rel write_request + 40], rax
    mov qword [rel write_request + 48], 1
    jmp .emit_surface_ready
.emit_private_surface:
    mov qword [rel write_request + 24], 0
    mov qword [rel write_request + 32], 0
    mov qword [rel write_request + 40], 0
    mov qword [rel write_request + 48], 0
.emit_surface_ready:
    lea rax, [rel emitted_length]
    mov qword [rel write_request + 56], rax
    lea rdi, [rel interface_bytes]
    mov esi, 512
    lea rdx, [rel write_request]
    call neboc_interface_write_records
    test eax, eax
    jnz semantic_failure
    lea rdi, [rel interface_bytes]
    mov rsi, qword [rel emitted_length]
    call write_all
    test eax, eax
    jnz io_failure
    jmp success

mode_inspect:
    lea rdi, [rel interface_bytes]
    mov esi, NEBOC_NI_MAX_BYTES + 1
    call read_bounded
    cmp rax, -1
    je io_failure
    mov rsi, rax
    lea rdi, [rel interface_bytes]
    lea rdx, [rel native_result + 16]
    call neboc_interface_read
    mov dword [rel native_result], eax
    mov dword [rel native_result + 8], edx
    lea rdi, [rel native_result]
    mov esi, 80
    call write_all
    test eax, eax
    jnz io_failure
    jmp success

mode_compat:
    lea rdi, [rel compat_input]
    mov esi, 72
    call read_exact
    test eax, eax
    jnz io_failure
    lea rdi, [rel compat_input]
    lea rsi, [rel native_result + 16]
    call neboc_interface_compatibility
    mov dword [rel native_result], eax
    mov dword [rel native_result + 8], edx
    lea rdi, [rel native_result]
    mov esi, 56
    call write_all
    test eax, eax
    jnz io_failure
    jmp success

mode_cache:
    lea rdi, [rel cache_input]
    mov esi, 128
    call read_exact
    test eax, eax
    jnz io_failure
    lea rdi, [rel cache_input]
    lea rsi, [rel cache_input + 56]
    lea rdx, [rel native_result + 16]
    call neboc_interface_cache_lookup
    mov dword [rel native_result], eax
    mov dword [rel native_result + 8], edx
    lea rdi, [rel native_result]
    mov esi, 48
    call write_all
    test eax, eax
    jnz io_failure

success:
    mov eax, 60
    xor edi, edi
    syscall
usage:
    mov eax, 60
    mov edi, 2
    syscall
io_failure:
    mov eax, 60
    mov edi, 3
    syscall
semantic_failure:
    mov eax, 60
    mov edi, 1
    syscall

section .rodata
arg_module: db '--module',0
arg_emit: db '--emit',0
arg_inspect: db '--inspect',0
arg_compat: db '--compat',0
arg_cache: db '--cache',0

section .bss
align 16
emit_input: resb 152
write_request: resb 64
emitted_length: resq 1
compat_input: resb 72
cache_input: resb 128
native_result: resb 144
interface_bytes: resb NEBOC_NI_MAX_BYTES + 1

section .note.GNU-stack noalloc noexec nowrite progbits
