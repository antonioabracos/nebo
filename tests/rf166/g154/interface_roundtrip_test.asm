; RF166 P01 compiled-interface integration and public native example.
bits 64
default rel

%include "compiler/interface/interface_v1.inc"

global _start
extern neboc_interface_write
extern neboc_interface_read
extern neboc_interface_reader_open
extern neboc_interface_reader_exports
extern neboc_interface_api_fingerprint_from_bytes
extern neboc_interface_abi_fingerprint_from_bytes
extern neboc_interface_new
extern neboc_interface_writer_add_export
extern neboc_interface_writer_add_type
extern neboc_interface_writer_add_layout
extern neboc_interface_writer_add_effects
extern neboc_interface_writer_add_capabilities
extern neboc_interface_writer_add_doc_record
extern neboc_interface_writer_add_dependency
extern neboc_interface_writer_finalize
extern neboc_interface_exports_canonicalize
extern neboc_interface_metadata_canonicalize
extern neboc_interface_compatibility
extern neboc_interface_cache_lookup

%define FNV_OFFSET 0xcbf29ce484222325
%define FNV_PRIME 0x100000001b3
%define SENTINEL 0xa5a5a5a5a5a5a5a5

section .text

fnv64:
    mov rax, FNV_OFFSET
    mov r8, FNV_PRIME
    xor ecx, ecx
.loop:
    cmp ecx, 64
    jae .done
    movzx edx, byte [rdi + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .loop
.done:
    ret

clear_summary:
    lea rdi, [rel summary]
    mov rax, SENTINEL
    mov ecx, 8
    rep stosq
    ret

check_summary_untouched:
    lea rdi, [rel summary]
    mov rax, SENTINEL
    mov ecx, 8
.loop:
    cmp qword [rdi], rax
    jne fail
    add rdi, 8
    loop .loop
    ret

_start:
    ; Exercise every public builder spelling before the lower-level codec.
    mov r12d, 1
    lea rdi, [rel builder]
    mov esi, 101
    mov edx, NEBOC_NI_EDITION
    mov rcx, NEBOC_NI_TARGET_X86_64
    call neboc_interface_new
    test eax, eax
    jnz fail
    lea rdi, [rel builder_export]
    xor eax, eax
    mov ecx, 8
    rep stosq
    mov qword [rel builder_export], 103
    mov qword [rel builder_export + 8], 107
    mov dword [rel builder_export + 16], 1
    mov dword [rel builder_export + 20], 1
    mov qword [rel builder_export + 24], 109
    lea rdi, [rel builder]
    lea rsi, [rel builder_export]
    call neboc_interface_writer_add_export
    test eax, eax
    jnz fail
    lea rdi, [rel builder]
    mov esi, 103
    mov edx, 113
    mov ecx, 127
    call neboc_interface_writer_add_type
    test eax, eax
    jnz fail
    lea rdi, [rel builder]
    mov esi, 103
    mov edx, 131
    call neboc_interface_writer_add_layout
    test eax, eax
    jnz fail
    lea rdi, [rel builder]
    mov esi, 103
    mov edx, 3
    call neboc_interface_writer_add_effects
    test eax, eax
    jnz fail
    lea rdi, [rel builder]
    mov esi, 103
    mov edx, 5
    call neboc_interface_writer_add_capabilities
    test eax, eax
    jnz fail
    lea rdi, [rel builder]
    mov esi, 103
    mov edx, 137
    call neboc_interface_writer_add_doc_record
    test eax, eax
    jnz fail
    lea rdi, [rel builder]
    mov esi, 103
    mov edx, 139
    mov ecx, 149
    mov r8d, 151
    call neboc_interface_writer_add_dependency
    test eax, eax
    jnz fail
    mov rax, SENTINEL
    mov qword [rel builder_length], rax
    lea rdi, [rel builder]
    lea rsi, [rel builder_interface]
    mov edx, 512
    lea rcx, [rel builder_length]
    call neboc_interface_writer_finalize
    test eax, eax
    jnz fail
    cmp qword [rel builder_length], 256
    jne fail

    ; Reader.open and reader.exports publish only after full validation.
    call clear_summary
    lea rdi, [rel builder_interface]
    mov rsi, qword [rel builder_length]
    lea rdx, [rel summary]
    call neboc_interface_reader_open
    test eax, eax
    jnz fail
    cmp qword [rel summary], 2
    jne fail
    cmp qword [rel summary + 16], 101
    jne fail
    mov rax, NEBOC_NI_TARGET_X86_64
    cmp qword [rel summary + 40], rax
    jne fail
    mov rax, SENTINEL
    mov qword [rel builder_export_count], rax
    lea rdi, [rel builder_interface]
    mov rsi, qword [rel builder_length]
    lea rdx, [rel builder_export_copy]
    mov ecx, 1
    lea r8, [rel builder_export_count]
    call neboc_interface_reader_exports
    test eax, eax
    jnz fail
    cmp qword [rel builder_export_count], 1
    jne fail
    cmp qword [rel builder_export_copy], 103
    jne fail
    cmp qword [rel builder_export_copy + 24], 113
    jne fail
    cmp qword [rel builder_export_copy + 32], 127
    jne fail
    cmp qword [rel builder_export_copy + 40], 131
    jne fail

    lea rdi, [rel builder_interface]
    mov rsi, qword [rel builder_length]
    lea rdx, [rel builder_api]
    call neboc_interface_api_fingerprint_from_bytes
    test eax, eax
    jnz fail
    mov rax, qword [rel builder_api]
    cmp rax, qword [rel summary + 24]
    jne fail
    lea rdi, [rel builder_interface]
    mov rsi, qword [rel builder_length]
    mov rdx, NEBOC_NI_TARGET_X86_64
    lea rcx, [rel builder_abi]
    call neboc_interface_abi_fingerprint_from_bytes
    test eax, eax
    jnz fail
    mov rax, qword [rel builder_abi]
    cmp rax, qword [rel summary + 32]
    jne fail

    ; A sealed builder rejects mutation/finalization without publishing length.
    lea rdi, [rel builder]
    mov esi, 103
    mov edx, 7
    call neboc_interface_writer_add_effects
    test eax, eax
    jz fail
    mov rax, SENTINEL
    mov qword [rel builder_second_length], rax
    lea rdi, [rel builder]
    lea rsi, [rel builder_interface_second]
    mov edx, 512
    lea rcx, [rel builder_second_length]
    call neboc_interface_writer_finalize
    test eax, eax
    jz fail
    mov rax, SENTINEL
    cmp qword [rel builder_second_length], rax
    jne fail

    ; Writer -> reader -> writer is byte-identical for the canonical empty V1.
    mov r12d, 1
    lea rdi, [rel interface_a]
    xor eax, eax
    mov ecx, 8
    rep stosq
    lea rdi, [rel interface_a]
    mov esi, 64
    mov edx, 11
    mov ecx, 22
    mov r8d, 33
    xor r9d, r9d
    call neboc_interface_write
    test eax, eax
    jnz fail

    mov r12d, 2
    call clear_summary
    lea rdi, [rel interface_a]
    mov esi, 64
    lea rdx, [rel summary]
    call neboc_interface_read
    test eax, eax
    jnz fail
    test edx, edx
    jnz fail
    cmp qword [rel summary], 0
    jne fail
    cmp qword [rel summary + 8], 64
    jne fail
    cmp qword [rel summary + 16], 11
    jne fail
    cmp qword [rel summary + 24], 0
    je fail
    cmp qword [rel summary + 32], 0
    je fail

    mov r12d, 3
    lea rdi, [rel interface_b]
    xor eax, eax
    mov ecx, 8
    rep stosq
    lea rdi, [rel interface_b]
    mov esi, 64
    mov rdx, qword [rel summary + 16]
    mov rcx, qword [rel summary + 24]
    mov r8, qword [rel summary + 32]
    xor r9d, r9d
    call neboc_interface_write
    test eax, eax
    jnz fail
    lea rsi, [rel interface_a]
    lea rdi, [rel interface_b]
    mov ecx, 64
    repe cmpsb
    jne fail

    ; Deterministic corruption sweep over every validated empty-header byte.
    mov r12d, 4
    xor r13d, r13d
    lea r15, [rel corrupt_offsets]
.corruption_loop:
    cmp r13d, corrupt_offset_count
    jae .exports_example
    lea rbx, [rel interface_a]
    movzx r14d, byte [r15 + r13]
    xor byte [rbx + r14], 1
    call clear_summary
    mov rdi, rbx
    mov esi, 64
    lea rdx, [rel summary]
    call neboc_interface_read
    test eax, eax
    jz fail
    call check_summary_untouched
    xor byte [rbx + r14], 1
    inc r13
    jmp .corruption_loop

.exports_example:
    mov r12d, 5
    ; Two public records are canonicalized by SymbolId, independent of input order.
    lea rdi, [rel export_input]
    xor eax, eax
    mov ecx, 32
    rep stosq
    lea rbx, [rel export_input]
    mov qword [rbx], 2
    mov qword [rbx + 8], 200
    mov dword [rbx + 16], 1
    mov dword [rbx + 20], 1
    mov qword [rbx + 24], 201
    mov qword [rbx + 64], 1
    mov qword [rbx + 72], 100
    mov dword [rbx + 80], 5
    mov dword [rbx + 84], 1
    lea rdi, [rel export_input]
    mov esi, 2
    lea rdx, [rel export_output]
    mov ecx, 2
    call neboc_interface_exports_canonicalize
    test eax, eax
    jnz fail
    cmp qword [rel export_output], 1
    jne fail
    cmp qword [rel export_output + 64], 2
    jne fail

    mov r12d, 6
    ; Effects/capabilities/docs/dependency identity use the same SymbolId order.
    lea rdi, [rel metadata_input]
    xor eax, eax
    mov ecx, 32
    rep stosq
    lea rbx, [rel metadata_input]
    mov qword [rbx], 2
    mov qword [rbx + 8], 3
    mov qword [rbx + 16], 5
    mov dword [rbx + 24], 2
    mov dword [rbx + 28], 3
    mov qword [rbx + 32], 210
    mov qword [rbx + 40], 211
    mov qword [rbx + 48], 212
    mov qword [rbx + 56], 213
    mov qword [rbx + 64], 1
    mov dword [rbx + 88], 1
    lea rdi, [rel metadata_input]
    mov esi, 2
    lea rdx, [rel metadata_output]
    mov ecx, 2
    call neboc_interface_metadata_canonicalize
    test eax, eax
    jnz fail
    cmp qword [rel metadata_output], 1
    jne fail
    cmp qword [rel metadata_output + 64], 2
    jne fail
    cmp qword [rel metadata_output + 80], 5
    jne fail

    mov r12d, 7
    ; Compatibility keeps source and target projections separate.
    lea rbx, [rel compat_request]
    mov qword [rbx], 10
    mov qword [rbx + 8], 10
    mov qword [rbx + 16], 20
    mov qword [rbx + 24], 20
    mov qword [rbx + 32], 30
    mov qword [rbx + 40], 30
    mov qword [rbx + 48], 40
    mov qword [rbx + 56], 40
    mov qword [rbx + 64], 0
    mov rdi, rbx
    lea rsi, [rel compat_result]
    call neboc_interface_compatibility
    test eax, eax
    jnz fail
    cmp qword [rel compat_result], 1
    jne fail
    mov qword [rel compat_request + 8], 11
    mov qword [rel compat_request + 64], 1
    mov rdi, rbx
    lea rsi, [rel compat_result]
    call neboc_interface_compatibility
    test eax, eax
    jnz fail
    cmp qword [rel compat_result], 2
    jne fail

    ; ABI-only drift requires recompilation without claiming an API break.
    mov qword [rel compat_request], 10
    mov qword [rel compat_request + 8], 10
    mov qword [rel compat_request + 16], 20
    mov qword [rel compat_request + 24], 21
    mov qword [rel compat_request + 32], 30
    mov qword [rel compat_request + 40], 30
    mov qword [rel compat_request + 64], 0
    mov rdi, rbx
    lea rsi, [rel compat_result]
    call neboc_interface_compatibility
    test eax, eax
    jnz fail
    cmp qword [rel compat_result], 3
    jne fail
    cmp qword [rel compat_result + 8], 0
    jne fail
    cmp qword [rel compat_result + 16], 1
    jne fail

    ; Effect/capability/ownership drift is breaking without a doc-only proof.
    mov qword [rel compat_request + 24], 20
    mov qword [rel compat_request + 40], 31
    mov rdi, rbx
    lea rsi, [rel compat_result]
    call neboc_interface_compatibility
    test eax, eax
    jnz fail
    cmp qword [rel compat_result], 4
    jne fail
    cmp qword [rel compat_result + 24], 1
    jne fail

    ; Cross-target comparisons fail without publishing a result.
    mov rax, SENTINEL
    lea rdi, [rel compat_result]
    mov ecx, 6
    rep stosq
    mov qword [rel compat_request + 56], 41
    mov rdi, rbx
    lea rsi, [rel compat_result]
    call neboc_interface_compatibility
    test eax, eax
    jz fail
    lea rdi, [rel compat_result]
    mov rax, SENTINEL
    mov ecx, 6
.compat_atomic_loop:
    cmp qword [rdi], rax
    jne fail
    add rdi, 8
    loop .compat_atomic_loop

    mov r12d, 8
    ; Full-key cache hit followed by source-digest invalidation.
    lea rbx, [rel cache_request]
    mov qword [rbx], 11
    mov qword [rbx + 8], 22
    mov qword [rbx + 16], 33
    mov qword [rbx + 24], 44
    mov qword [rbx + 32], 55
    mov qword [rbx + 40], 66
    mov qword [rbx + 48], 77
    lea rdi, [rel cache_entry]
    mov rsi, rbx
    mov ecx, 7
    rep movsq
    mov qword [rel cache_entry + 56], 88
    lea rdi, [rel cache_entry]
    call fnv64
    mov qword [rel cache_entry + 64], rax
    lea rdi, [rel cache_request]
    lea rsi, [rel cache_entry]
    lea rdx, [rel cache_result]
    call neboc_interface_cache_lookup
    test eax, eax
    jnz fail
    cmp qword [rel cache_result], 1
    jne fail
    cmp qword [rel cache_result + 8], 88
    jne fail
    xor qword [rel cache_request + 32], 1
    lea rdi, [rel cache_request]
    lea rsi, [rel cache_entry]
    lea rdx, [rel cache_result]
    call neboc_interface_cache_lookup
    test eax, eax
    jnz fail
    cmp qword [rel cache_result], 2
    jne fail
    cmp qword [rel cache_result + 8], 0
    jne fail
    cmp qword [rel cache_result + 16], 16
    jne fail

    ; Corrupt cache authentication fails atomically and can never become a hit.
    xor qword [rel cache_entry + 64], 1
    lea rdi, [rel cache_result]
    mov rax, SENTINEL
    mov ecx, 4
    rep stosq
    lea rdi, [rel cache_request]
    lea rsi, [rel cache_entry]
    lea rdx, [rel cache_result]
    call neboc_interface_cache_lookup
    test eax, eax
    jz fail
    lea rdi, [rel cache_result]
    mov rax, SENTINEL
    mov ecx, 4
.cache_atomic_loop:
    cmp qword [rdi], rax
    jne fail
    add rdi, 8
    loop .cache_atomic_loop

    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, r12d
    syscall

section .rodata
corrupt_offsets: db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
                 db 48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
corrupt_offset_count equ $-corrupt_offsets

section .bss
align 16
builder: resb 192
builder_export: resb 64
builder_interface: resb 512
builder_interface_second: resb 512
builder_length: resq 1
builder_second_length: resq 1
builder_export_copy: resb 64
builder_export_count: resq 1
builder_api: resq 1
builder_abi: resq 1
interface_a: resb 64
interface_b: resb 64
summary: resb 64
export_input: resb 256
export_output: resb 256
metadata_input: resb 256
metadata_output: resb 256
compat_request: resb 80
compat_result: resb 48
cache_request: resb 64
cache_entry: resb 80
cache_result: resb 32

section .note.GNU-stack noalloc noexec nowrite progbits
