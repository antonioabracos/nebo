; Nebo compiled-interface V1 bounded reader.
;
; rdi = complete .ni byte buffer
; rsi = byte length
; rdx = caller-owned 64-byte summary, 8-byte aligned
;
; On success the summary contains section_count, total_size, module_id,
; api_fingerprint, abi_fingerprint, target_digest, content_digest and the
; number of accepted unknown optional sections.  No output byte is written
; before every header, directory and payload check succeeds.
;
; eax = NEBOC_STATUS_*, edx = stable rejection reason (zero on success).

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/interface/interface_v1.inc"

%define NI_MAX_BYTES             0x01000000
%define NI_SECTION_SIZE          32
%define NI_SECTION_OPTIONAL      1
%define NI_SECTION_UTF8          2
%define NI_SECTION_FLAG_MASK     3
%define NI_LAST_KNOWN_SECTION    7
%define NI_FNV64_OFFSET          0xcbf29ce484222325
%define NI_FNV64_PRIME           0x100000001b3

%define NI_DIAG_ARGUMENT         1
%define NI_DIAG_FILE_LIMIT       2
%define NI_DIAG_TRUNCATED_HEADER 3
%define NI_DIAG_MAGIC            4
%define NI_DIAG_VERSION          5
%define NI_DIAG_HEADER_SIZE      6
%define NI_DIAG_HEADER_FLAGS     7
%define NI_DIAG_DECLARED_SIZE    8
%define NI_DIAG_SECTION_COUNT    9
%define NI_DIAG_DIRECTORY_RANGE  10
%define NI_DIAG_SECTION_KIND     11
%define NI_DIAG_SECTION_FLAGS    12
%define NI_DIAG_UNKNOWN_REQUIRED 13
%define NI_DIAG_DUPLICATE        14
%define NI_DIAG_SECTION_RANGE    15
%define NI_DIAG_OVERLAP          16
%define NI_DIAG_UTF8             17
%define NI_DIAG_SECTION_DIGEST   18
%define NI_DIAG_CONTENT_DIGEST   19

extern neboc_utf8_validate

section .text

; Internal FNV-1a64: rdi=bytes, rsi=length -> rax=digest.
; The caller has already proved the complete half-open range.
align 16
.fnv1a64:
    mov rax, NI_FNV64_OFFSET
    mov r8, NI_FNV64_PRIME
    xor ecx, ecx
.fnv_next:
    cmp rcx, rsi
    jae .fnv_done
    movzx edx, byte [rdi + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .fnv_next
.fnv_done:
    ret

NEBOC_ABI_FUNCTION neboc_interface_read
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 72

    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r12, r12
    jz .argument
    test r14, r14
    jz .argument
    test r14, 7
    jnz .argument
    test r13, r13
    jz .truncated_header
    lea rax, [r12 + r13]
    cmp rax, r12
    jb .argument
    cmp r13, NI_MAX_BYTES
    ja .file_limit
    cmp r13, NEBOC_NI_HEADER_SIZE
    jb .truncated_header

    mov rax, NEBOC_NI_MAGIC
    cmp qword [r12], rax
    jne .magic
    cmp word [r12 + 8], NEBOC_NI_VERSION
    jne .version
    cmp word [r12 + 10], NEBOC_NI_HEADER_SIZE
    jne .header_size
    cmp dword [r12 + 12], 0
    jne .header_flags
    mov eax, dword [r12 + 52]
    cmp rax, r13
    jne .declared_size

    mov r15d, dword [r12 + 48]
    cmp r15, NEBOC_NI_MAX_SECTIONS
    ja .section_count
    mov rbx, r15
    shl rbx, 5
    add rbx, NEBOC_NI_HEADER_SIZE
    jc .directory_range
    cmp rbx, r13
    ja .directory_range

    mov qword [rsp], 0                 ; seen known-section bitmap
    mov qword [rsp + 8], 0             ; accepted unknown optional count
    test r15, r15
    jnz .sections_begin
    cmp r13, NEBOC_NI_HEADER_SIZE
    jne .directory_range
    cmp qword [r12 + 56], 0
    jne .content_digest
    jmp .publish

.sections_begin:
    xor ebp, ebp
.section_loop:
    cmp rbp, r15
    jae .validate_root_digest
    mov r10, rbp
    shl r10, 5
    lea r10, [r12 + r10 + NEBOC_NI_HEADER_SIZE]

    mov edx, dword [r10]
    test edx, edx
    jz .section_kind
    mov ecx, dword [r10 + 4]
    mov eax, ecx
    and eax, ~NI_SECTION_FLAG_MASK
    jnz .section_flags

    cmp edx, NI_LAST_KNOWN_SECTION
    ja .unknown_section
    mov rax, 1
    mov ecx, edx
    shl rax, cl
    test qword [rsp], rax
    jnz .duplicate
    or qword [rsp], rax
    jmp .section_identity_done

.unknown_section:
    test ecx, NI_SECTION_OPTIONAL
    jz .unknown_required
    inc qword [rsp + 8]

.section_identity_done:
    mov rax, qword [r10 + 8]
    mov rdx, qword [r10 + 16]
    test rax, 7
    jnz .section_range
    cmp rax, rbx
    jb .section_range
    test rdx, rdx
    jz .section_range
    mov rcx, rax
    add rcx, rdx
    jc .section_range
    cmp rcx, r13
    ja .section_range
    mov qword [rsp + 32], rax           ; current start
    mov qword [rsp + 40], rdx           ; current length
    mov qword [rsp + 48], rcx           ; current end
    mov rax, qword [r10 + 24]
    mov qword [rsp + 56], rax           ; expected section digest
    mov eax, dword [r10 + 4]
    mov dword [rsp + 64], eax           ; flags survive helper calls

    xor r9d, r9d
.overlap_loop:
    cmp r9, rbp
    jae .overlap_done
    mov r10, r9
    shl r10, 5
    lea r10, [r12 + r10 + NEBOC_NI_HEADER_SIZE]
    mov rax, qword [r10 + 8]
    mov rdx, qword [r10 + 16]
    add rdx, rax                        ; prior range was already proved
    cmp qword [rsp + 32], rdx
    jae .overlap_next
    cmp rax, qword [rsp + 48]
    jb .overlap
.overlap_next:
    inc r9
    jmp .overlap_loop

.overlap_done:
    mov rdi, r12
    add rdi, qword [rsp + 32]
    mov rsi, qword [rsp + 40]
    call .fnv1a64
    cmp rax, qword [rsp + 56]
    jne .section_digest

    test dword [rsp + 64], NI_SECTION_UTF8
    jz .section_valid
    mov rdi, r12
    add rdi, qword [rsp + 32]
    mov rsi, qword [rsp + 40]
    lea rdx, [rsp + 24]
    call neboc_utf8_validate
    test eax, eax
    jnz .utf8

.section_valid:
    inc rbp
    jmp .section_loop

.validate_root_digest:
    lea rdi, [r12 + NEBOC_NI_HEADER_SIZE]
    mov rsi, r13
    sub rsi, NEBOC_NI_HEADER_SIZE
    call .fnv1a64
    cmp rax, qword [r12 + 56]
    jne .content_digest

.publish:
    mov qword [r14], r15
    mov qword [r14 + 8], r13
    mov rax, qword [r12 + 24]
    mov qword [r14 + 16], rax
    mov rax, qword [r12 + 32]
    mov qword [r14 + 24], rax
    mov rax, qword [r12 + 40]
    mov qword [r14 + 32], rax
    mov rax, qword [r12 + 16]
    mov qword [r14 + 40], rax
    mov rax, qword [r12 + 56]
    mov qword [r14 + 48], rax
    mov rax, qword [rsp + 8]
    mov qword [r14 + 56], rax
    xor eax, eax
    xor edx, edx
    jmp .return

.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, NI_DIAG_ARGUMENT
    jmp .return
.file_limit:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    mov edx, NI_DIAG_FILE_LIMIT
    jmp .return
.truncated_header:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_TRUNCATED_HEADER
    jmp .return
.magic:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_MAGIC
    jmp .return
.version:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_VERSION
    jmp .return
.header_size:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_HEADER_SIZE
    jmp .return
.header_flags:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_HEADER_FLAGS
    jmp .return
.declared_size:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_DECLARED_SIZE
    jmp .return
.section_count:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    mov edx, NI_DIAG_SECTION_COUNT
    jmp .return
.directory_range:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_DIRECTORY_RANGE
    jmp .return
.section_kind:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_SECTION_KIND
    jmp .return
.section_flags:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_SECTION_FLAGS
    jmp .return
.unknown_required:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_UNKNOWN_REQUIRED
    jmp .return
.duplicate:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_DUPLICATE
    jmp .return
.section_range:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_SECTION_RANGE
    jmp .return
.overlap:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_OVERLAP
    jmp .return
.utf8:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_UTF8
    jmp .return
.section_digest:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_SECTION_DIGEST
    jmp .return
.content_digest:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, NI_DIAG_CONTENT_DIGEST

.return:
    add rsp, 72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
