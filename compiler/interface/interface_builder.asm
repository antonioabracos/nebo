; Bounded public builder surface for NeboInterface and InterfaceWriter.
; The V1 builder owns one canonical public symbol plus its semantic metadata;
; the container writer remains the only serialization/fingerprint owner.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/interface/interface_v1.inc"

%define BUILDER_BYTES 192
%define BUILDER_FLAG_SEALED 1
%define BUILDER_EXPORT_OFFSET 64
%define BUILDER_METADATA_OFFSET 128
%define BUILDER_EXPORT_COUNT_OFFSET 32
%define BUILDER_METADATA_COUNT_OFFSET 40

%define BUILDER_DIAG_ARGUMENT 1
%define BUILDER_DIAG_STATE 2
%define BUILDER_DIAG_SYMBOL 3
%define BUILDER_DIAG_VALUE 4

extern neboc_interface_exports_canonicalize
extern neboc_interface_write_records

section .text

; NeboInterface.new(moduleId, edition, target).
; rdi=builder, rsi=ModuleId, rdx=edition, rcx=target digest.
NEBOC_ABI_FUNCTION neboc_interface_new
    test rdi, rdi
    jz .argument
    test rdi, 7
    jnz .argument
    test rsi, rsi
    jz .argument
    cmp rdx, NEBOC_NI_EDITION
    jne .argument
    test rcx, rcx
    jz .argument
    mov r8, rdi
    mov r9, rsi
    mov r10, rdx
    mov r11, rcx
    xor eax, eax
    mov ecx, BUILDER_BYTES / 8
    rep stosq
    mov qword [r8], r9
    mov qword [r8 + 8], r10
    mov qword [r8 + 16], r11
    xor eax, eax
    xor edx, edx
    ret
.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, BUILDER_DIAG_ARGUMENT
    ret

; interfaceWriter.addExport(symbol).
; rdi=builder, rsi=64-byte InterfaceSymbolRecord.
NEBOC_ABI_FUNCTION neboc_interface_writer_add_export
    push r12
    mov r12, rdi
    test r12, r12
    jz .argument
    test r12, 7
    jnz .argument
    test rsi, rsi
    jz .argument
    test qword [r12 + 24], BUILDER_FLAG_SEALED
    jnz .state
    cmp qword [r12 + BUILDER_EXPORT_COUNT_OFFSET], 0
    jne .state
    mov rdi, rsi
    mov esi, 1
    lea rdx, [r12 + BUILDER_EXPORT_OFFSET]
    mov ecx, 1
    call neboc_interface_exports_canonicalize
    test eax, eax
    jnz .return
    mov qword [r12 + BUILDER_EXPORT_COUNT_OFFSET], 1
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, BUILDER_DIAG_ARGUMENT
    jmp .return
.state:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_STATE
.return:
    pop r12
    ret

; interfaceWriter.addType(typeRecord).
; rdi=builder, rsi=SymbolId, rdx=type digest, rcx=generic digest or zero.
NEBOC_ABI_FUNCTION neboc_interface_writer_add_type
    test rdi, rdi
    jz .argument
    test rdi, 7
    jnz .argument
    test qword [rdi + 24], BUILDER_FLAG_SEALED
    jnz .state
    cmp qword [rdi + BUILDER_EXPORT_COUNT_OFFSET], 1
    jne .state
    cmp qword [rdi + BUILDER_EXPORT_OFFSET], rsi
    jne .symbol
    test rdx, rdx
    jz .value
    mov qword [rdi + BUILDER_EXPORT_OFFSET + 24], rdx
    test rcx, rcx
    jz .without_generic
    mov qword [rdi + BUILDER_EXPORT_OFFSET + 32], rcx
    or qword [rdi + BUILDER_EXPORT_OFFSET + 56], 1
    jmp .success
.without_generic:
    mov qword [rdi + BUILDER_EXPORT_OFFSET + 32], 0
    and qword [rdi + BUILDER_EXPORT_OFFSET + 56], ~1
.success:
    xor eax, eax
    xor edx, edx
    ret
.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, BUILDER_DIAG_ARGUMENT
    ret
.state:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_STATE
    ret
.symbol:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_SYMBOL
    ret
.value:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_VALUE
    ret

; interfaceWriter.addLayout(layoutRecord).
; rdi=builder, rsi=SymbolId, rdx=target layout digest.
NEBOC_ABI_FUNCTION neboc_interface_writer_add_layout
    test rdi, rdi
    jz .argument
    test rdi, 7
    jnz .argument
    test qword [rdi + 24], BUILDER_FLAG_SEALED
    jnz .state
    cmp qword [rdi + BUILDER_EXPORT_COUNT_OFFSET], 1
    jne .state
    cmp qword [rdi + BUILDER_EXPORT_OFFSET], rsi
    jne .symbol
    test rdx, rdx
    jz .value
    mov qword [rdi + BUILDER_EXPORT_OFFSET + 40], rdx
    or qword [rdi + BUILDER_EXPORT_OFFSET + 56], 2
    xor eax, eax
    xor edx, edx
    ret
.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, BUILDER_DIAG_ARGUMENT
    ret
.state:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_STATE
    ret
.symbol:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_SYMBOL
    ret
.value:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_VALUE
    ret

; Internal bounded metadata allocator. rdi=builder, rsi=SymbolId -> rax=record.
; Zero means the builder state/symbol is invalid.
ni_builder_metadata_for_symbol:
    test rdi, rdi
    jz .invalid
    test rdi, 7
    jnz .invalid
    test qword [rdi + 24], BUILDER_FLAG_SEALED
    jnz .invalid
    cmp qword [rdi + BUILDER_EXPORT_COUNT_OFFSET], 1
    jne .invalid
    cmp qword [rdi + BUILDER_EXPORT_OFFSET], rsi
    jne .invalid
    cmp qword [rdi + BUILDER_METADATA_COUNT_OFFSET], 0
    jne .existing
    lea rax, [rdi + BUILDER_METADATA_OFFSET]
    mov r8, rdi
    mov r9, rsi
    mov rdi, rax
    xor eax, eax
    mov ecx, NEBOC_NI_METADATA_RECORD_SIZE / 8
    rep stosq
    lea rax, [r8 + BUILDER_METADATA_OFFSET]
    mov qword [rax], r9
    mov dword [rax + 24], 1              ; conservative owned contract
    mov qword [r8 + BUILDER_METADATA_COUNT_OFFSET], 1
    ret
.existing:
    cmp qword [rdi + BUILDER_METADATA_COUNT_OFFSET], 1
    jne .invalid
    lea rax, [rdi + BUILDER_METADATA_OFFSET]
    cmp qword [rax], rsi
    jne .invalid
    ret
.invalid:
    xor eax, eax
    ret

; interfaceWriter.addEffects(symbolId, effects).
NEBOC_ABI_FUNCTION neboc_interface_writer_add_effects
    cmp rdx, 0xff
    ja .value
    push rdx
    call ni_builder_metadata_for_symbol
    pop rdx
    test rax, rax
    jz .state
    mov qword [rax + 8], rdx
    xor eax, eax
    xor edx, edx
    ret
.state:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_STATE
    ret
.value:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_VALUE
    ret

; interfaceWriter.addCapabilities(symbolId, capabilities).
NEBOC_ABI_FUNCTION neboc_interface_writer_add_capabilities
    cmp rdx, 0xffff
    ja .value
    push rdx
    call ni_builder_metadata_for_symbol
    pop rdx
    test rax, rax
    jz .state
    mov qword [rax + 16], rdx
    xor eax, eax
    xor edx, edx
    ret
.state:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_STATE
    ret
.value:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_VALUE
    ret

; interfaceWriter.addDocRecord(docRecord).
; rdi=builder, rsi=SymbolId, rdx=semantic DocRecord digest.
NEBOC_ABI_FUNCTION neboc_interface_writer_add_doc_record
    test rdx, rdx
    jz .value
    push rdx
    call ni_builder_metadata_for_symbol
    pop rdx
    test rax, rax
    jz .state
    mov qword [rax + 32], rdx
    or dword [rax + 28], 1
    xor eax, eax
    xor edx, edx
    ret
.state:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_STATE
    ret
.value:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_VALUE
    ret

; Internal/public dependency identity attachment used by interface emission.
; rdi=builder, rsi=SymbolId, rdx=ModuleId, rcx=API fp, r8=ABI fp.
NEBOC_ABI_FUNCTION neboc_interface_writer_add_dependency
    test rdx, rdx
    jz .value
    test rcx, rcx
    jz .value
    test r8, r8
    jz .value
    push rdx
    push rcx
    push r8
    call ni_builder_metadata_for_symbol
    pop r8
    pop rcx
    pop rdx
    test rax, rax
    jz .state
    mov qword [rax + 40], rdx
    mov qword [rax + 48], rcx
    mov qword [rax + 56], r8
    or dword [rax + 28], 2
    xor eax, eax
    xor edx, edx
    ret
.state:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_STATE
    ret
.value:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_VALUE
    ret

; interfaceWriter.finalize().
; rdi=builder, rsi=output, rdx=capacity, rcx=output length pointer.
NEBOC_ABI_FUNCTION neboc_interface_writer_finalize
    push r12
    push r13
    push r14
    push r15
    sub rsp, 72
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r12, r12
    jz .argument
    test r12, 7
    jnz .argument
    test qword [r12 + 24], BUILDER_FLAG_SEALED
    jnz .state
    cmp qword [r12 + BUILDER_EXPORT_COUNT_OFFSET], 1
    jne .state
    mov rax, qword [r12]
    mov qword [rsp], rax
    mov rax, qword [r12 + 8]
    mov qword [rsp + 8], rax
    mov rax, qword [r12 + 16]
    mov qword [rsp + 16], rax
    lea rax, [r12 + BUILDER_EXPORT_OFFSET]
    mov qword [rsp + 24], rax
    mov rax, qword [r12 + BUILDER_EXPORT_COUNT_OFFSET]
    mov qword [rsp + 32], rax
    lea rax, [r12 + BUILDER_METADATA_OFFSET]
    cmp qword [r12 + BUILDER_METADATA_COUNT_OFFSET], 0
    jne .metadata_ptr
    xor eax, eax
.metadata_ptr:
    mov qword [rsp + 40], rax
    mov rax, qword [r12 + BUILDER_METADATA_COUNT_OFFSET]
    mov qword [rsp + 48], rax
    mov qword [rsp + 56], r15
    mov rdi, r13
    mov rsi, r14
    mov rdx, rsp
    call neboc_interface_write_records
    test eax, eax
    jnz .return
    or qword [r12 + 24], BUILDER_FLAG_SEALED
    jmp .return
.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, BUILDER_DIAG_ARGUMENT
    jmp .return
.state:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, BUILDER_DIAG_STATE
.return:
    add rsp, 72
    pop r15
    pop r14
    pop r13
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
