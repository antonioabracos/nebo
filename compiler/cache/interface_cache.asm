; Full-key compiled-interface cache validation and lookup.
;
; Requested key V1 (56 bytes): ModuleId, compiler, edition, target, source,
; dependency-set and prelude digests (seven nonzero qwords).
; Cached entry V1 (72 bytes): the same key, interface artifact digest, then an
; FNV-1a64 checksum over the first 64 bytes.
;
; rdi=requested key, rsi=cached entry, rdx=caller-owned 32-byte result.
; Result: state (1=HIT, 2=STALE_MISS), artifact digest or zero, seven-bit
; invalidation mask, verified entry checksum or zero. Corruption is an error
; and leaves the complete result untouched. No allocation or I/O occurs.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

%define CACHE_KEY_QWORDS       7
%define CACHE_KEY_BYTES        56
%define CACHE_AUTH_BYTES       64
%define CACHE_STATE_HIT        1
%define CACHE_STATE_STALE_MISS 2
%define CACHE_FNV64_OFFSET     0xcbf29ce484222325
%define CACHE_FNV64_PRIME      0x100000001b3

%define CACHE_DIAG_ARGUMENT    1
%define CACHE_DIAG_REQUEST_KEY 2
%define CACHE_DIAG_ENTRY       3
%define CACHE_DIAG_CORRUPTION  4

section .text

align 16
.fnv1a64:
    mov rax, CACHE_FNV64_OFFSET
    mov r8, CACHE_FNV64_PRIME
    xor ecx, ecx
.fnv_loop:
    cmp rcx, CACHE_AUTH_BYTES
    jae .fnv_done
    movzx edx, byte [rdi + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .fnv_loop
.fnv_done:
    ret

NEBOC_ABI_FUNCTION neboc_interface_cache_lookup
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r12, r12
    jz .argument
    test r13, r13
    jz .argument
    test r14, r14
    jz .argument
    test r12, 7
    jnz .argument
    test r13, 7
    jnz .argument
    test r14, 7
    jnz .argument

    xor ecx, ecx
.request_loop:
    cmp ecx, CACHE_KEY_QWORDS
    jae .entry_validate
    cmp qword [r12 + rcx * 8], 0
    je .request_key
    inc ecx
    jmp .request_loop

.entry_validate:
    xor ecx, ecx
.entry_key_loop:
    cmp ecx, CACHE_KEY_QWORDS
    jae .entry_artifact
    cmp qword [r13 + rcx * 8], 0
    je .entry
    inc ecx
    jmp .entry_key_loop
.entry_artifact:
    cmp qword [r13 + CACHE_KEY_BYTES], 0
    je .entry
    mov rdi, r13
    call .fnv1a64
    cmp rax, qword [r13 + CACHE_AUTH_BYTES]
    jne .corruption

    xor r9d, r9d
    xor ecx, ecx
.compare_loop:
    cmp ecx, CACHE_KEY_QWORDS
    jae .publish
    mov rax, qword [r12 + rcx * 8]
    cmp rax, qword [r13 + rcx * 8]
    je .compare_next
    bts r9, rcx
.compare_next:
    inc ecx
    jmp .compare_loop

.publish:
    test r9, r9
    jnz .publish_stale
    mov qword [r14], CACHE_STATE_HIT
    mov rax, qword [r13 + CACHE_KEY_BYTES]
    mov qword [r14 + 8], rax
    mov qword [r14 + 16], 0
    mov rax, qword [r13 + CACHE_AUTH_BYTES]
    mov qword [r14 + 24], rax
    jmp .success
.publish_stale:
    mov qword [r14], CACHE_STATE_STALE_MISS
    mov qword [r14 + 8], 0
    mov qword [r14 + 16], r9
    mov qword [r14 + 24], 0
.success:
    xor eax, eax
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, CACHE_DIAG_ARGUMENT
    jmp .return
.request_key:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, CACHE_DIAG_REQUEST_KEY
    jmp .return
.entry:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, CACHE_DIAG_ENTRY
    jmp .return
.corruption:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, CACHE_DIAG_CORRUPTION
.return:
    pop r14
    pop r13
    pop r12
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
