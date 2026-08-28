; C03-F05 stable entrypoint diagnostic mapping.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/semantic/modules/entrypoint_resolver.inc"
%include "compiler/semantic/modules/entrypoint_diagnostic.inc"

extern neboc_diagnostic_catalog_lookup

section .rodata
note_missing: db 'selected executable or example target requires exactly one start()'
note_missing_len equ $-note_missing
note_duplicate: db 'the first start() declaration is the related location'
note_duplicate_len equ $-note_duplicate
note_invalid: db 'start() permits no parameters or modifiers; status terminals require Int, Bool or Char'
note_invalid_len equ $-note_invalid
note_ambiguous: db 'entrypoint identity is resolved by target membership, never file or linker order'
note_ambiguous_len equ $-note_ambiguous
note_forbidden: db 'only executable and example targets own an entrypoint'
note_forbidden_len equ $-note_forbidden
label_duplicate: db 'first start() declaration'
label_duplicate_len equ $-label_duplicate
label_ambiguous: db 'other resolved start() candidate'
label_ambiguous_len equ $-label_ambiguous

section .text
; entrypoint_diagnostic_prepare(result*, fallback_source_id, fallback_start,
;   fallback_end, source_length, diagnostic*) -> status
;
; The fallback span is the selected target/invocation span and is used only
; for MISSING, where fabricating a source declaration would be incorrect.
NEBOC_ABI_FUNCTION neboc_entrypoint_diagnostic_prepare
 test rdi,rdi
 jz .invalid_fast
 test r9,r9
 jz .invalid_fast
 test r9,7
 jnz .invalid_fast
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,56
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rbx,r9

 ; Failure atomicity: clear the complete destination before classification.
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_DIAGNOSTIC_QWORDS
 rep stosq

 mov rax,[r12+NEBOC_ENTRYPOINT_RESULT_OUTCOME]
 cmp rax,NEBOC_ENTRYPOINT_OUTCOME_MISSING
 je .missing
 cmp rax,NEBOC_ENTRYPOINT_OUTCOME_DUPLICATE
 je .duplicate
 cmp rax,NEBOC_ENTRYPOINT_OUTCOME_INVALID_SIGNATURE
 je .invalid_signature
 cmp rax,NEBOC_ENTRYPOINT_OUTCOME_AMBIGUOUS
 je .ambiguous
 cmp rax,NEBOC_ENTRYPOINT_OUTCOME_FORBIDDEN_FOR_TARGET
 je .forbidden
 jmp .invalid

.missing:
 test r13,r13
 jz .invalid
 cmp r14,r15
 ja .invalid
 cmp r15,rbp
 ja .invalid
 mov r10d,NEBOC_DIAG_ENTRYPOINT_MISSING
 lea r11,[rel note_missing]
 mov ecx,note_missing_len
 mov rdx,r13
 mov rsi,r14
 mov rdi,r15
 jmp .primary_ready

.duplicate:
 ; F03 freezes later declaration as primary and first declaration as related.
 ; The F04 result stores the two deterministic minima in primary/related
 ; order, so diagnostic projection deliberately swaps them here.
 mov r10d,NEBOC_DIAG_ENTRYPOINT_DUPLICATE
 lea r11,[rel note_duplicate]
 mov ecx,note_duplicate_len
 mov rdx,[r12+NEBOC_ENTRYPOINT_RESULT_RELATED_SOURCE_UNIT_ID]
 mov rsi,[r12+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_START]
 mov rdi,[r12+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_END]
 test rdx,rdx
 jz .invalid
 mov rax,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID]
 mov [rsp+48],rax
 mov rax,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START]
 mov [rsp+32],rax
 mov rax,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END]
 mov [rsp+40],rax
 lea rax,[rel label_duplicate]
 mov [rsp+16],rax
 mov qword [rsp+24],label_duplicate_len
 jmp .primary_with_related

.invalid_signature:
 mov r10d,NEBOC_DIAG_ENTRYPOINT_INVALID_SIGNATURE
 lea r11,[rel note_invalid]
 mov ecx,note_invalid_len
 jmp .resolver_primary
.ambiguous:
 mov r10d,NEBOC_DIAG_ENTRYPOINT_AMBIGUOUS
 lea r11,[rel note_ambiguous]
 mov ecx,note_ambiguous_len
 mov rax,[r12+NEBOC_ENTRYPOINT_RESULT_RELATED_SOURCE_UNIT_ID]
 mov [rsp+48],rax
 mov rax,[r12+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_START]
 mov [rsp+32],rax
 mov rax,[r12+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_END]
 mov [rsp+40],rax
 lea rax,[rel label_ambiguous]
 mov [rsp+16],rax
 mov qword [rsp+24],label_ambiguous_len
 jmp .resolver_primary_with_related
.forbidden:
 mov r10d,NEBOC_DIAG_ENTRYPOINT_FORBIDDEN_FOR_TARGET
 lea r11,[rel note_forbidden]
 mov ecx,note_forbidden_len
.resolver_primary:
 mov rdx,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID]
 mov rsi,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START]
 mov rdi,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END]
 jmp .primary_ready
.resolver_primary_with_related:
 mov rdx,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID]
 mov rsi,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START]
 mov rdi,[r12+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END]
.primary_with_related:
 mov rax,[rsp+48]
 test rax,rax
 jz .invalid
 mov r9,[rsp+32]
 cmp r9,[rsp+40]
 jae .invalid
 cmp qword [rsp+40],rbp
 ja .invalid
 or qword [rbx+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_SECONDARY
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],rax
 mov rax,[rsp+32]
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],rax
 mov rax,[rsp+40]
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET],rax
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET],rbp
 mov rax,[rsp+16]
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_LABEL_OFFSET],rax
 mov rax,[rsp+24]
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_LABEL_LENGTH_OFFSET],rax
.primary_ready:
 test rdx,rdx
 jz .invalid
 cmp rsi,rdi
 ja .invalid
 cmp rdi,rbp
 ja .invalid
 mov [rsp],r10
 mov [rsp+8],r11
 mov [rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],rdx
 mov [rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],rsi
 mov [rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET],rdi
 mov [rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET],rbp
 mov qword [rbx+NEBOC_DIAGNOSTIC_ID_OFFSET],1
 mov [rbx+NEBOC_DIAGNOSTIC_CODE_OFFSET],r10
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_SYNTAX
 cmp r10,NEBOC_DIAG_ENTRYPOINT_INVALID_SIGNATURE
 jne .category_ready
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_TYPE
.category_ready:
 mov qword [rbx+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 mov qword [rbx+NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET],NEBOC_DIAGNOSTIC_EXIT_USER_ERROR
 mov qword [rbx+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 mov qword [rbx+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_NOTE
 cmp qword [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],0
 je .flags_ready
 or qword [rbx+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_SECONDARY
.flags_ready:
 mov rax,[rsp+8]
 mov [rbx+NEBOC_DIAGNOSTIC_NOTE_OFFSET],rax
 mov [rbx+NEBOC_DIAGNOSTIC_NOTE_LENGTH_OFFSET],rcx
 mov rdi,[rsp]
 lea rsi,[rsp]
 call neboc_diagnostic_catalog_lookup
 test eax,eax
 jnz .invalid
 mov rax,[rsp+NEBOC_DIAG_ENTRY_NAME_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],rax
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET],rax
 mov rax,[rsp+NEBOC_DIAG_ENTRY_NAME_LENGTH_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET],rax
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET],rax
 mov rax,[rsp+NEBOC_DIAG_ENTRY_SEVERITY_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],rax
 mov rax,[rsp+NEBOC_DIAG_ENTRY_PHASE_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid:
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_DIAGNOSTIC_QWORDS
 rep stosq
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,56
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.invalid_fast:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
