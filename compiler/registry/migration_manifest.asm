; G146 bounded migration manifest, source transform, and restore owners.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/lifecycle.inc"

section .text

; generateOperatorMigrationManifest(rows*, count, out*, capacity, out-count*).
; The entire source is validated before either output is modified.
NEBOC_ABI_FUNCTION neboc_registry_generate_migration_manifest
    test rdi,rdi
    jz .manifest_invalid
    test rdx,rdx
    jz .manifest_invalid
    test r8,r8
    jz .manifest_invalid
    test rdi,7
    jnz .manifest_invalid
    test rdx,7
    jnz .manifest_invalid
    test r8,7
    jnz .manifest_invalid
    test rsi,rsi
    jz .manifest_invalid
    cmp rsi,NEBOC_REGISTRY_MAX_MIGRATION_ROWS
    ja .manifest_limit
    cmp rsi,rcx
    ja .manifest_limit
    ; The count publication is an independent qword and may not alias either
    ; the immutable rows or the manifest destination.
    mov rax,rsi
    shl rax,5
    mov r9,rdi
    add r9,rax
    jc .manifest_invalid
    mov r10,r8
    add r10,8
    jc .manifest_invalid
    cmp r8,r9
    jae .count_rows_disjoint
    cmp rdi,r10
    jb .manifest_invalid
.count_rows_disjoint:
    mov r11,rdx
    add r11,rax
    jc .manifest_invalid
    cmp r8,r11
    jae .count_output_disjoint
    cmp rdx,r10
    jb .manifest_invalid
.count_output_disjoint:
    mov r9,rdi
    mov r10,rsi
.manifest_validate:
    cmp qword [r9+NEBOC_REGISTRY_MIGRATION_ROW_ID_OFFSET],0
    je .manifest_denied
    mov rax,[r9+NEBOC_REGISTRY_MIGRATION_ROW_FROM_TOKEN_OFFSET]
    test rax,rax
    jz .manifest_denied
    mov r11,[r9+NEBOC_REGISTRY_MIGRATION_ROW_TO_TOKEN_OFFSET]
    test r11,r11
    jz .manifest_denied
    cmp rax,r11
    je .manifest_denied
    mov rax,[r9+NEBOC_REGISTRY_MIGRATION_ROW_FLAGS_OFFSET]
    test rax,~NEBOC_REGISTRY_MIGRATION_FLAG_ALL
    jnz .manifest_invalid
    test rax,NEBOC_REGISTRY_MIGRATION_FLAG_MANUAL_REVIEW
    jnz .manifest_next
    mov r11,rax
    and r11,NEBOC_REGISTRY_MIGRATION_FLAG_SAFE | NEBOC_REGISTRY_MIGRATION_FLAG_REVERSIBLE
    cmp r11,NEBOC_REGISTRY_MIGRATION_FLAG_SAFE | NEBOC_REGISTRY_MIGRATION_FLAG_REVERSIBLE
    jne .manifest_denied
.manifest_next:
    add r9,NEBOC_REGISTRY_MIGRATION_ROW_SIZE
    dec r10
    jnz .manifest_validate
    ; Reject overlapping buffers so copy direction cannot alter the manifest.
    mov rax,rsi
    shl rax,5
    lea r9,[rdi+rax]
    cmp rdx,rdi
    jb .manifest_nonoverlap_below
    cmp rdx,r9
    jb .manifest_invalid
    jmp .manifest_copy
.manifest_nonoverlap_below:
    lea r9,[rdx+rax]
    cmp r9,rdi
    ja .manifest_invalid
.manifest_copy:
    mov r9,rsi
    mov rsi,rdi
    mov rdi,rdx
    mov rcx,r9
    shl rcx,2
    rep movsq
    mov [r8],r9
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.manifest_limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.manifest_denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.manifest_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Apply one exact, position-bound source replacement.  Passing old/new in the
; opposite direction restores the original bytes through the same owner.
NEBOC_ABI_FUNCTION neboc_registry_migration_transform
    test rdi,rdi
    jz .transform_invalid
    test rdi,7
    jnz .transform_invalid
    push rbx
    push r12
    mov r8,[rdi+NEBOC_REGISTRY_TRANSFORM_SOURCE_OFFSET]
    mov r9,[rdi+NEBOC_REGISTRY_TRANSFORM_SOURCE_LENGTH_OFFSET]
    mov r10,[rdi+NEBOC_REGISTRY_TRANSFORM_REPLACE_OFFSET]
    mov r11,[rdi+NEBOC_REGISTRY_TRANSFORM_OLD_OFFSET]
    mov rcx,[rdi+NEBOC_REGISTRY_TRANSFORM_OLD_LENGTH_OFFSET]
    mov rdx,[rdi+NEBOC_REGISTRY_TRANSFORM_NEW_OFFSET]
    mov rsi,[rdi+NEBOC_REGISTRY_TRANSFORM_NEW_LENGTH_OFFSET]
    test r8,r8
    jz .transform_invalid_saved
    test r11,r11
    jz .transform_invalid_saved
    test rdx,rdx
    jz .transform_invalid_saved
    test rcx,rcx
    jz .transform_invalid_saved
    test rsi,rsi
    jz .transform_invalid_saved
    cmp r9,NEBOC_REGISTRY_MAX_MATERIAL_BYTES
    ja .transform_limit_saved
    cmp rsi,NEBOC_REGISTRY_MAX_MATERIAL_BYTES
    ja .transform_limit_saved
    mov rax,r10
    add rax,rcx
    jc .transform_invalid_saved
    cmp rax,r9
    ja .transform_denied_saved
    mov rax,r9
    sub rax,rcx
    add rax,rsi
    jc .transform_limit_saved
    cmp rax,NEBOC_REGISTRY_MAX_MATERIAL_BYTES
    ja .transform_limit_saved
    mov rsi,[rdi+NEBOC_REGISTRY_TRANSFORM_OUTPUT_OFFSET]
    test rsi,rsi
    jz .transform_invalid_saved
    mov r12,[rdi+NEBOC_REGISTRY_TRANSFORM_OUTPUT_LENGTH_OFFSET]
    test r12,r12
    jz .transform_invalid_saved
    test r12,7
    jnz .transform_invalid_saved
    cmp rax,[rdi+NEBOC_REGISTRY_TRANSFORM_CAPACITY_OFFSET]
    ja .transform_limit_saved
    ; Output must be wholly disjoint from source and replacement spellings.
    mov rbx,rsi
    add rbx,rax
    jc .transform_invalid_saved
    ; The byte result, result length and all immutable inputs are disjoint.
    mov rax,rdi
    add rax,NEBOC_REGISTRY_TRANSFORM_SIZE
    jc .transform_invalid_saved
    cmp rsi,rax
    jae .check_output_length_overlap
    cmp rdi,rbx
    jb .transform_invalid_saved
.check_output_length_overlap:
    mov rax,r12
    add rax,8
    jc .transform_invalid_saved
    cmp r12,rbx
    jae .check_length_request_overlap
    cmp rsi,rax
    jb .transform_invalid_saved
.check_length_request_overlap:
    mov rax,rdi
    add rax,NEBOC_REGISTRY_TRANSFORM_SIZE
    jc .transform_invalid_saved
    cmp r12,rax
    jae .check_length_source_overlap
    mov rax,r12
    add rax,8
    jc .transform_invalid_saved
    cmp rdi,rax
    jb .transform_invalid_saved
.check_length_source_overlap:
    mov rax,r8
    add rax,r9
    jc .transform_invalid_saved
    cmp r12,rax
    jae .check_length_old_overlap
    mov rax,r12
    add rax,8
    jc .transform_invalid_saved
    cmp r8,rax
    jb .transform_invalid_saved
.check_length_old_overlap:
    mov rax,r11
    add rax,rcx
    jc .transform_invalid_saved
    cmp r12,rax
    jae .check_length_new_overlap
    mov rax,r12
    add rax,8
    jc .transform_invalid_saved
    cmp r11,rax
    jb .transform_invalid_saved
.check_length_new_overlap:
    mov rax,rdx
    add rax,[rdi+NEBOC_REGISTRY_TRANSFORM_NEW_LENGTH_OFFSET]
    jc .transform_invalid_saved
    cmp r12,rax
    jae .check_source_overlap
    mov rax,r12
    add rax,8
    jc .transform_invalid_saved
    cmp rdx,rax
    jb .transform_invalid_saved
.check_source_overlap:
    mov rax,r8
    add rax,r9
    jc .transform_invalid_saved
    cmp rsi,rax
    jae .check_old_overlap
    cmp r8,rbx
    jb .transform_invalid_saved
.check_old_overlap:
    mov rax,r11
    add rax,rcx
    jc .transform_invalid_saved
    cmp rsi,rax
    jae .check_new_overlap
    cmp r11,rbx
    jb .transform_invalid_saved
.check_new_overlap:
    mov rax,[rdi+NEBOC_REGISTRY_TRANSFORM_NEW_LENGTH_OFFSET]
    add rax,rdx
    jc .transform_invalid_saved
    cmp rsi,rax
    jae .transform_prevalidated
    cmp rdx,rbx
    jb .transform_invalid_saved
.transform_prevalidated:
    ; Validate the complete old spelling before any destination byte changes.
    xor eax,eax
.transform_compare:
    cmp rax,rcx
    jae .transform_copy_prefix
    mov bl,[r8+r10]
    cmp bl,[r11+rax]
    jne .transform_denied_saved
    inc r10
    inc rax
    jmp .transform_compare
.transform_copy_prefix:
    sub r10,rcx
    xor eax,eax
.prefix_loop:
    cmp rax,r10
    jae .new_loop_start
    mov bl,[r8+rax]
    mov [rsi+rax],bl
    inc rax
    jmp .prefix_loop
.new_loop_start:
    xor eax,eax
    mov rcx,[rdi+NEBOC_REGISTRY_TRANSFORM_NEW_LENGTH_OFFSET]
.new_loop:
    cmp rax,rcx
    jae .suffix_start
    mov bl,[rdx+rax]
    mov [rsi+r10],bl
    inc r10
    inc rax
    jmp .new_loop
.suffix_start:
    mov rax,[rdi+NEBOC_REGISTRY_TRANSFORM_REPLACE_OFFSET]
    add rax,[rdi+NEBOC_REGISTRY_TRANSFORM_OLD_LENGTH_OFFSET]
.suffix_loop:
    cmp rax,r9
    jae .transform_publish_length
    mov bl,[r8+rax]
    mov [rsi+r10],bl
    inc rax
    inc r10
    jmp .suffix_loop
.transform_publish_length:
    mov [r12],r10
    pop r12
    pop rbx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.transform_limit_saved:
    pop r12
    pop rbx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.transform_denied_saved:
    pop r12
    pop rbx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.transform_invalid_saved:
    pop r12
    pop rbx
.transform_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Original qword restore ABI retained with common statuses and atomic capacity
; checks.  Zero-count restores are valid only with non-null, aligned buffers.
NEBOC_ABI_FUNCTION nebo_registry_migration_restore
    test rdi,rdi
    jz .restore_invalid
    test rdx,rdx
    jz .restore_invalid
    test rdi,7
    jnz .restore_invalid
    test rdx,7
    jnz .restore_invalid
    cmp rsi,rcx
    ja .restore_limit
    cmp rsi,NEBOC_REGISTRY_MAX_MIGRATION_ROWS
    ja .restore_limit
    mov rcx,rsi
    rep movsq
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.restore_limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.restore_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
