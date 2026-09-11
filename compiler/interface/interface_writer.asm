; Deterministic Nebo compiled-interface V1 writer and fingerprint owners.
;
; neboc_interface_write_records(rdi=output, rsi=capacity, rdx=request)
; Request V1 (64 bytes): module, edition, target, exports pointer/count,
; metadata pointer/count, output-length pointer.  The output length is the
; publication token and is written only after the complete artifact validates.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/interface/interface_v1.inc"

%define NI_FNV64_OFFSET 0xcbf29ce484222325
%define NI_FNV64_PRIME  0x100000001b3

%define WRITE_DIAG_ARGUMENT 1
%define WRITE_DIAG_EDITION 2
%define WRITE_DIAG_LIMIT 3
%define WRITE_DIAG_EXPORT 4
%define WRITE_DIAG_METADATA 5

extern neboc_interface_exports_canonicalize
extern neboc_interface_metadata_canonicalize

section .text

; rax=state, rdx=qword -> rax=FNV-1a64(state,qword little-endian).
align 16
ni_writer_fnv_qword:
    mov r8, NI_FNV64_PRIME
    mov ecx, 8
.loop:
    movzx r9d, dl
    xor rax, r9
    imul rax, r8
    shr rdx, 8
    dec ecx
    jnz .loop
    ret

; rax=state, rdi=bytes, rsi=length -> rax.
align 16
ni_writer_fnv_extend:
    mov r8, NI_FNV64_PRIME
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .done
    movzx edx, byte [rdi + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .loop
.done:
    ret

; rdi=bytes, rsi=length -> rax.
align 16
ni_writer_fnv_bytes:
    mov rax, NI_FNV64_OFFSET
    jmp ni_writer_fnv_extend

; Hash only source-semantic public inputs.  Layout, documentation and
; dependency ABI are deliberately excluded from the API fingerprint.
; rdi=exports, rsi=export count, rdx=metadata, rcx=metadata count -> rax.
NEBOC_ABI_FUNCTION neboc_interface_api_fingerprint
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    cmp r13, NEBOC_NI_MAX_RECORDS
    ja .invalid
    cmp r15, NEBOC_NI_MAX_RECORDS
    ja .invalid
    test r13, r13
    jz .metadata
    test r12, r12
    jz .invalid
    test r12, 7
    jnz .invalid
    mov rbx, NI_FNV64_OFFSET
    xor ebp, ebp
.export_loop:
    cmp rbp, r13
    jae .metadata
    mov r10, rbp
    shl r10, 6
    add r10, r12
%macro API_HASH_FIELD 1
    mov rax, rbx
    mov rdx, qword [r10 + %1]
    call ni_writer_fnv_qword
    mov rbx, rax
%endmacro
    API_HASH_FIELD 0
    API_HASH_FIELD 8
    API_HASH_FIELD 16
    API_HASH_FIELD 24
    API_HASH_FIELD 32
    API_HASH_FIELD 48
    mov rax, rbx
    mov rdx, qword [r10 + 56]
    and rdx, ~2                         ; target layout presence is ABI-only
    call ni_writer_fnv_qword
    mov rbx, rax
    inc rbp
    jmp .export_loop
%undef API_HASH_FIELD
.metadata:
    test r15, r15
    jz .done
    test r14, r14
    jz .invalid
    test r14, 7
    jnz .invalid
    test r13, r13
    jnz .metadata_start
    mov rbx, NI_FNV64_OFFSET
.metadata_start:
    xor ebp, ebp
.metadata_loop:
    cmp rbp, r15
    jae .done
    mov r10, rbp
    shl r10, 6
    add r10, r14
%macro API_META_FIELD 1
    mov rax, rbx
    mov rdx, qword [r10 + %1]
    call ni_writer_fnv_qword
    mov rbx, rax
%endmacro
    API_META_FIELD 0
    API_META_FIELD 8
    API_META_FIELD 16
    mov rax, rbx
    mov edx, dword [r10 + 24]
    mov ecx, dword [r10 + 28]
    and ecx, ~1                         ; doc presence is not API identity
    shl rcx, 32
    or rdx, rcx
    call ni_writer_fnv_qword
    mov rbx, rax
    API_META_FIELD 40
    API_META_FIELD 48
    inc rbp
    jmp .metadata_loop
%undef API_META_FIELD
.done:
    test r13, r13
    jnz .nonzero
    test r15, r15
    jnz .nonzero
    mov rbx, NI_FNV64_OFFSET
.nonzero:
    mov rax, rbx
    test rax, rax
    jnz .return
    mov eax, 1
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.invalid:
    xor eax, eax
    jmp .return

; rdi=exports, rsi=export count, rdx=metadata, rcx=metadata count,
; r8=target digest -> rax.  Only target/layout/type/dependency ABI inputs enter.
NEBOC_ABI_FUNCTION neboc_interface_abi_fingerprint
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    test r8, r8
    jz .invalid
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    cmp r13, NEBOC_NI_MAX_RECORDS
    ja .invalid
    cmp r15, NEBOC_NI_MAX_RECORDS
    ja .invalid
    mov rax, NI_FNV64_OFFSET
    mov rdx, r8
    call ni_writer_fnv_qword
    mov rbx, rax
    test r13, r13
    jz .metadata
    test r12, r12
    jz .invalid
    xor ebp, ebp
.export_loop:
    cmp rbp, r13
    jae .metadata
    mov r10, rbp
    shl r10, 6
    add r10, r12
%macro ABI_EXPORT_FIELD 1
    mov rax, rbx
    mov rdx, qword [r10 + %1]
    call ni_writer_fnv_qword
    mov rbx, rax
%endmacro
    ABI_EXPORT_FIELD 0
    ABI_EXPORT_FIELD 16
    ABI_EXPORT_FIELD 24
    ABI_EXPORT_FIELD 40
    inc rbp
    jmp .export_loop
%undef ABI_EXPORT_FIELD
.metadata:
    test r15, r15
    jz .done
    test r14, r14
    jz .invalid
    xor ebp, ebp
.metadata_loop:
    cmp rbp, r15
    jae .done
    mov r10, rbp
    shl r10, 6
    add r10, r14
    mov rax, rbx
    mov rdx, qword [r10]
    call ni_writer_fnv_qword
    mov rbx, rax
    mov rax, rbx
    mov rdx, qword [r10 + 56]
    call ni_writer_fnv_qword
    mov rbx, rax
    inc rbp
    jmp .metadata_loop
.done:
    mov rax, rbx
    test rax, rax
    jnz .return
    mov eax, 1
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.invalid:
    xor eax, eax
    jmp .return

NEBOC_ABI_FUNCTION neboc_interface_write_records
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 72
    mov r12, rdi                         ; output
    mov r13, rsi                         ; capacity
    mov r14, rdx                         ; request
    test r12, r12
    jz .argument
    test r14, r14
    jz .argument
    test r12, 7
    jnz .argument
    test r14, 7
    jnz .argument
    cmp qword [r14], 0                   ; ModuleId
    je .argument
    cmp qword [r14 + 8], NEBOC_NI_EDITION
    jne .edition
    cmp qword [r14 + 16], 0              ; target
    je .argument
    mov rax, qword [r14 + 56]
    test rax, rax
    jz .argument
    test rax, 7
    jnz .argument

    mov rbx, qword [r14 + 32]            ; export count
    mov rbp, qword [r14 + 48]            ; metadata count
    cmp rbx, NEBOC_NI_MAX_RECORDS
    ja .limit
    cmp rbp, NEBOC_NI_MAX_RECORDS
    ja .limit
    test rbx, rbx
    jz .export_ptr_ok
    cmp qword [r14 + 24], 0
    je .argument
.export_ptr_ok:
    test rbp, rbp
    jz .metadata_ptr_ok
    cmp qword [r14 + 40], 0
    je .argument
.metadata_ptr_ok:

    xor r15d, r15d                       ; section count
    test rbx, rbx
    setnz r15b
    xor eax, eax
    test rbp, rbp
    setnz al
    add r15, rax
    mov r10, r15
    shl r10, 5
    add r10, NEBOC_NI_HEADER_SIZE        ; first payload offset
    mov r11, rbx
    add r11, rbp
    shl r11, 6
    add r11, r10                         ; total size
    jc .limit
    cmp r11, NEBOC_NI_MAX_BYTES
    ja .limit
    cmp r11, r13
    ja .limit
    mov qword [rsp], r10                 ; payload cursor
    mov qword [rsp + 8], r11             ; total size
    mov qword [rsp + 16], 0              ; export payload pointer
    mov qword [rsp + 24], 0              ; metadata payload pointer

    test rbx, rbx
    jz .write_metadata
    mov rdi, qword [r14 + 24]
    mov rsi, rbx
    lea rdx, [r12 + r10]
    mov rcx, rbx
    call neboc_interface_exports_canonicalize
    test eax, eax
    jnz .export_failure
    mov r10, qword [rsp]
    lea rax, [r12 + r10]
    mov qword [rsp + 16], rax
    mov rax, rbx
    shl rax, 6
    add qword [rsp], rax

.write_metadata:
    test rbp, rbp
    jz .fingerprints
    mov rdi, qword [r14 + 40]
    mov rsi, rbp
    mov r10, qword [rsp]
    lea rdx, [r12 + r10]
    mov rcx, rbp
    call neboc_interface_metadata_canonicalize
    test eax, eax
    jnz .metadata_failure
    mov r10, qword [rsp]
    lea rax, [r12 + r10]
    mov qword [rsp + 24], rax

.fingerprints:
    mov rdi, qword [rsp + 16]
    mov rsi, rbx
    mov rdx, qword [rsp + 24]
    mov rcx, rbp
    call neboc_interface_api_fingerprint
    test rax, rax
    jz .argument
    mov qword [rsp + 32], rax
    mov rdi, qword [rsp + 16]
    mov rsi, rbx
    mov rdx, qword [rsp + 24]
    mov rcx, rbp
    mov r8, qword [r14 + 16]
    call neboc_interface_abi_fingerprint
    test rax, rax
    jz .argument
    mov qword [rsp + 40], rax

    ; Directory order is fixed: exports then metadata.
    mov r10, NEBOC_NI_HEADER_SIZE
    mov r11, NEBOC_NI_HEADER_SIZE
    mov rax, r15
    shl rax, 5
    add r11, rax
    test rbx, rbx
    jz .directory_metadata
    mov dword [r12 + r10], NEBOC_NI_SECTION_EXPORTS
    mov dword [r12 + r10 + 4], 0
    mov qword [r12 + r10 + 8], r11
    mov rax, rbx
    shl rax, 6
    mov qword [r12 + r10 + 16], rax
    mov rdi, qword [rsp + 16]
    mov rsi, rax
    call ni_writer_fnv_bytes
    mov qword [r12 + r10 + 24], rax
    add r11, rsi
    add r10, NEBOC_NI_SECTION_SIZE
.directory_metadata:
    test rbp, rbp
    jz .root_digest
    mov dword [r12 + r10], NEBOC_NI_SECTION_METADATA
    mov dword [r12 + r10 + 4], 0
    mov qword [r12 + r10 + 8], r11
    mov rax, rbp
    shl rax, 6
    mov qword [r12 + r10 + 16], rax
    mov rdi, qword [rsp + 24]
    mov rsi, rax
    call ni_writer_fnv_bytes
    mov qword [r12 + r10 + 24], rax

.root_digest:
    ; Header semantics and all section bytes share one authenticated digest.
    ; The digest field itself (+56..+63) is the only excluded range.
    mov rax, NEBOC_NI_MAGIC
    mov qword [r12], rax
    mov word [r12 + 8], NEBOC_NI_VERSION
    mov word [r12 + 10], NEBOC_NI_HEADER_SIZE
    mov dword [r12 + 12], NEBOC_NI_EDITION
    mov rax, qword [r14 + 16]
    mov qword [r12 + 16], rax
    mov rax, qword [r14]
    mov qword [r12 + 24], rax
    mov rax, qword [rsp + 32]
    mov qword [r12 + 32], rax
    mov rax, qword [rsp + 40]
    mov qword [r12 + 40], rax
    mov dword [r12 + 48], r15d
    mov rax, qword [rsp + 8]
    mov dword [r12 + 52], eax
    mov qword [r12 + 56], 0
    mov rdi, r12
    mov esi, 56
    call ni_writer_fnv_bytes
    lea rdi, [r12 + NEBOC_NI_HEADER_SIZE]
    mov rsi, qword [rsp + 8]
    sub rsi, NEBOC_NI_HEADER_SIZE
    call ni_writer_fnv_extend
    mov qword [r12 + 56], rax
    mov rax, qword [r14 + 56]
    mov rdx, qword [rsp + 8]
    mov qword [rax], rdx                 ; atomic publication token
    xor eax, eax
    xor edx, edx
    jmp .return

.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, WRITE_DIAG_ARGUMENT
    jmp .return
.edition:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, WRITE_DIAG_EDITION
    jmp .return
.limit:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    mov edx, WRITE_DIAG_LIMIT
    jmp .return
.export_failure:
    mov edx, WRITE_DIAG_EXPORT
    jmp .return
.metadata_failure:
    mov edx, WRITE_DIAG_METADATA
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

; Compatibility entry point retained for callers that need an empty header.
NEBOC_ABI_FUNCTION neboc_interface_write
    push rbx
    mov rbx, rdi
    test rdi, rdi
    jz .argument
    cmp rsi, NEBOC_NI_HEADER_SIZE
    jb .limit
    test rdx, rdx
    jz .argument
    test rcx, rcx
    jz .argument
    test r8, r8
    jz .argument
    test r9, r9
    jnz .argument
    mov rax, NEBOC_NI_MAGIC
    mov qword [rbx], rax
    mov word [rbx + 8], NEBOC_NI_VERSION
    mov word [rbx + 10], NEBOC_NI_HEADER_SIZE
    mov dword [rbx + 12], NEBOC_NI_EDITION
    mov rax, NEBOC_NI_TARGET_X86_64
    mov qword [rbx + 16], rax
    mov qword [rbx + 24], rdx
    xor edi, edi
    xor esi, esi
    xor edx, edx
    xor ecx, ecx
    call neboc_interface_api_fingerprint
    mov qword [rbx + 32], rax
    xor edi, edi
    xor esi, esi
    xor edx, edx
    xor ecx, ecx
    mov r8, NEBOC_NI_TARGET_X86_64
    call neboc_interface_abi_fingerprint
    mov qword [rbx + 40], rax
    mov dword [rbx + 48], 0
    mov dword [rbx + 52], NEBOC_NI_HEADER_SIZE
    mov qword [rbx + 56], 0
    mov rdi, rbx
    mov esi, 56
    call ni_writer_fnv_bytes
    mov qword [rbx + 56], rax
    xor eax, eax
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, WRITE_DIAG_ARGUMENT
    jmp .return
.limit:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    mov edx, WRITE_DIAG_LIMIT
.return:
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
