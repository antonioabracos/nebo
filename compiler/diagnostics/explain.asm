; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F07 bounded fix-it previews and versioned offline explanations.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/explain.inc"

%define CATALOG_TAGS_OFFSET 120
%define CATALOG_TAGS_LENGTH_OFFSET 128
%define CATALOG_ENTRY_SIZE 136

section .rodata
preview_old: db '--- '
preview_old_len equ $-preview_old
preview_new: db '+++ '
preview_new_len equ $-preview_new
preview_hunk: db '@@ bytes '
preview_hunk_len equ $-preview_hunk
preview_range: db '..'
preview_range_len equ $-preview_range
preview_hunk_close: db ' @@',10
preview_hunk_close_len equ $-preview_hunk_close
preview_minus: db '-'
preview_plus: db '+'
newline: db 10
redacted_path: db '<redacted>'
redacted_path_len equ $-redacted_path

render_colon: db ': '
render_colon_len equ $-render_colon
render_causes: db 'causes: '
render_causes_len equ $-render_causes
render_solutions: db 'solutions: '
render_solutions_len equ $-render_solutions
render_positive: db 'positive: '
render_positive_len equ $-render_positive
render_negative: db 'negative: '
render_negative_len equ $-render_negative
render_related: db 'related: '
render_related_len equ $-render_related
search_empty: db 'no diagnostics matched',10
search_empty_len equ $-search_empty

code_e0001: db 'NEBO-E0001'
code_e0001_len equ $-code_e0001
title_e0001: db 'invalid diagnostic or source contract'
title_e0001_len equ $-title_e0001
cause_e0001: db 'A required source or diagnostic invariant was not satisfied.'
cause_e0001_len equ $-cause_e0001
solution_e0001: db 'Inspect the primary span and use the canonical syntax or schema.'
solution_e0001_len equ $-solution_e0001
positive_e0001: db 'fn main() { return 0 }'
positive_e0001_len equ $-positive_e0001
negative_e0001: db 'fn main( {'
negative_e0001_len equ $-negative_e0001
related_e0001: db 'NEBO-H0001'
related_e0001_len equ $-related_e0001
tags_e0001: db 'syntax tooling parser source schema'
tags_e0001_len equ $-tags_e0001

code_e0002: db 'NEBO-E0002'
code_e0002_len equ $-code_e0002
title_e0002: db 'bounded diagnostic limit exceeded'
title_e0002_len equ $-title_e0002
cause_e0002: db 'The configured diagnostic or recovery budget was exhausted.'
cause_e0002_len equ $-cause_e0002
solution_e0002: db 'Fix the earliest root cause or select a bounded max-errors value.'
solution_e0002_len equ $-solution_e0002
positive_e0002: db 'neboc check main.no --max-errors 8'
positive_e0002_len equ $-positive_e0002
negative_e0002: db 'neboc check main.no --max-errors 0'
negative_e0002_len equ $-negative_e0002
related_e0002: db 'NEBO-E0001'
related_e0002_len equ $-related_e0002
tags_e0002: db 'tooling recovery limits cascade'
tags_e0002_len equ $-tags_e0002

code_w0001: db 'NEBO-W0001'
code_w0001_len equ $-code_w0001
title_w0001: db 'compatibility warning'
title_w0001_len equ $-title_w0001
cause_w0001: db 'The construct is valid but has a bounded compatibility concern.'
cause_w0001_len equ $-cause_w0001
solution_w0001: db 'Review the warning group and choose an explicit policy.'
solution_w0001_len equ $-solution_w0001
positive_w0001: db 'neboc check main.no --warn portability'
positive_w0001_len equ $-positive_w0001
negative_w0001: db 'neboc check main.no --forbid portability --allow portability'
negative_w0001_len equ $-negative_w0001
related_w0001: db 'NEBO-H0001'
related_w0001_len equ $-related_w0001
tags_w0001: db 'warning tooling compatibility portability'
tags_w0001_len equ $-tags_w0001

code_n0001: db 'NEBO-N0001'
code_n0001_len equ $-code_n0001
title_n0001: db 'diagnostic context note'
title_n0001_len equ $-title_n0001
cause_n0001: db 'Additional local context is attached to a primary diagnostic.'
cause_n0001_len equ $-cause_n0001
solution_n0001: db 'Read the primary diagnostic before acting on this note.'
solution_n0001_len equ $-solution_n0001
positive_n0001: db 'primary error followed by a related context note'
positive_n0001_len equ $-positive_n0001
negative_n0001: db 'context note used as an independent root cause'
negative_n0001_len equ $-negative_n0001
related_n0001: db 'NEBO-E0001'
related_n0001_len equ $-related_n0001
tags_n0001: db 'note tooling context related'
tags_n0001_len equ $-tags_n0001

code_h0001: db 'NEBO-H0001'
code_h0001_len equ $-code_h0001
title_h0001: db 'diagnostic action help'
title_h0001_len equ $-title_h0001
cause_h0001: db 'A local corrective action is available for the parent diagnostic.'
cause_h0001_len equ $-cause_h0001
solution_h0001: db 'Preview the classified fix-it; source application is never implicit.'
solution_h0001_len equ $-solution_h0001
positive_h0001: db 'neboc check main.no --show-fixes'
positive_h0001_len equ $-positive_h0001
negative_h0001: db 'assuming a preview modified the source file'
negative_h0001_len equ $-negative_h0001
related_h0001: db 'NEBO-E0001'
related_h0001_len equ $-related_h0001
tags_h0001: db 'help tooling fix-it preview'
tags_h0001_len equ $-tags_h0001

code_ice0001: db 'NEBO-ICE-0001'
code_ice0001_len equ $-code_ice0001
title_ice0001: db 'internal compiler invariant failure'
title_ice0001_len equ $-title_ice0001
cause_ice0001: db 'The compiler detected an internal state that source diagnostics cannot explain.'
cause_ice0001_len equ $-cause_ice0001
solution_ice0001: db 'Preserve the local redacted bundle and report the compiler version.'
solution_ice0001_len equ $-solution_ice0001
positive_ice0001: db 'redacted local bundle with deterministic manifest'
positive_ice0001_len equ $-positive_ice0001
negative_ice0001: db 'automatic upload of source or environment secrets'
negative_ice0001_len equ $-negative_ice0001
related_ice0001: db 'NEBO-E0001'
related_ice0001_len equ $-related_ice0001
tags_ice0001: db 'internal ICE compiler tooling bundle'
tags_ice0001_len equ $-tags_ice0001

align 8
catalog:
 dq code_e0001,code_e0001_len,title_e0001,title_e0001_len,cause_e0001,cause_e0001_len,solution_e0001,solution_e0001_len,positive_e0001,positive_e0001_len,negative_e0001,negative_e0001_len,related_e0001,related_e0001_len,NEBOC_EXPLANATION_VERSION_V1,tags_e0001,tags_e0001_len
 dq code_e0002,code_e0002_len,title_e0002,title_e0002_len,cause_e0002,cause_e0002_len,solution_e0002,solution_e0002_len,positive_e0002,positive_e0002_len,negative_e0002,negative_e0002_len,related_e0002,related_e0002_len,NEBOC_EXPLANATION_VERSION_V1,tags_e0002,tags_e0002_len
 dq code_w0001,code_w0001_len,title_w0001,title_w0001_len,cause_w0001,cause_w0001_len,solution_w0001,solution_w0001_len,positive_w0001,positive_w0001_len,negative_w0001,negative_w0001_len,related_w0001,related_w0001_len,NEBOC_EXPLANATION_VERSION_V1,tags_w0001,tags_w0001_len
 dq code_n0001,code_n0001_len,title_n0001,title_n0001_len,cause_n0001,cause_n0001_len,solution_n0001,solution_n0001_len,positive_n0001,positive_n0001_len,negative_n0001,negative_n0001_len,related_n0001,related_n0001_len,NEBOC_EXPLANATION_VERSION_V1,tags_n0001,tags_n0001_len
 dq code_h0001,code_h0001_len,title_h0001,title_h0001_len,cause_h0001,cause_h0001_len,solution_h0001,solution_h0001_len,positive_h0001,positive_h0001_len,negative_h0001,negative_h0001_len,related_h0001,related_h0001_len,NEBOC_EXPLANATION_VERSION_V1,tags_h0001,tags_h0001_len
 dq code_ice0001,code_ice0001_len,title_ice0001,title_ice0001_len,cause_ice0001,cause_ice0001_len,solution_ice0001,solution_ice0001_len,positive_ice0001,positive_ice0001_len,negative_ice0001,negative_ice0001_len,related_ice0001,related_ice0001_len,NEBOC_EXPLANATION_VERSION_V1,tags_ice0001,tags_ice0001_len

section .text
; append(writer*, bytes*, length) with failure-atomic length ownership by caller.
explain_append:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .ok
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+NEBOC_WRITER_LENGTH_OFFSET]
 mov r9,r8
 add r9,rdx
 jc .limit
 cmp r9,[rdi+NEBOC_WRITER_CAPACITY_OFFSET]
 ja .limit
 mov r10,[rdi+NEBOC_WRITER_BYTES_OFFSET]
 test r10,r10
 jz .invalid
 add r10,r8
 xor ecx,ecx
.copy:
 cmp rcx,rdx
 jae .store
 mov al,[rsi+rcx]
 mov [r10+rcx],al
 inc rcx
 jmp .copy
.store:
 mov [rdi+NEBOC_WRITER_LENGTH_OFFSET],r9
.ok:
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

explain_append_u64:
 push rbx
 sub rsp,32
 mov rbx,rdi
 mov rax,rsi
 lea rsi,[rsp+32]
 xor ecx,ecx
 test rax,rax
 jnz .digits
 dec rsi
 mov byte [rsi],'0'
 mov ecx,1
 jmp .emit
.digits:
 mov r8d,10
.loop:
 xor edx,edx
 div r8
 add dl,'0'
 dec rsi
 mov [rsi],dl
 inc ecx
 test rax,rax
 jnz .loop
.emit:
 mov rdi,rbx
 mov edx,ecx
 call explain_append
 add rsp,32
 pop rbx
 ret

validate_writer:
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_WRITER_BYTES_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[rdi+NEBOC_WRITER_CAPACITY_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_EXPLANATION_MAX_OUTPUT_BYTES
 ja .invalid
 cmp qword [rdi+NEBOC_WRITER_LENGTH_OFFSET],rax
 ja .invalid
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; exact_equal(left*, left_len, right*, right_len) -> 1/0
exact_equal:
 cmp rsi,rcx
 jne .no
 xor eax,eax
.loop:
 cmp rax,rsi
 jae .yes
 mov r8b,[rdi+rax]
 cmp r8b,[rdx+rax]
 jne .no
 inc rax
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; contains(haystack*, hay_len, needle*, needle_len) -> 1/0
contains:
 test rcx,rcx
 jz .no
 cmp rcx,rsi
 ja .no
 xor r8d,r8d
.outer:
 mov rax,r8
 add rax,rcx
 cmp rax,rsi
 ja .no
 xor r9d,r9d
.inner:
 cmp r9,rcx
 jae .yes
 mov al,[rdi+r8]
 add r8,r9
 mov al,[rdi+r8]
 sub r8,r9
 cmp al,[rdx+r9]
 jne .next
 inc r9
 jmp .inner
.next:
 inc r8
 jmp .outer
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; FixIt.new(out*, description*, length, applicability, edit_storage*, capacity)
NEBOC_ABI_FUNCTION neboc_fix_it_new
 test rdi,rdi
 jz .new_invalid
 test rsi,rsi
 jz .new_invalid
 test rdx,rdx
 jz .new_invalid
 cmp rdx,NEBOC_FIXIT_MAX_DESCRIPTION_BYTES
 ja .new_limit
 cmp rcx,NEBOC_FIXIT_MACHINE_APPLICABLE
 jb .new_invalid
 cmp rcx,NEBOC_FIXIT_MANUAL_ONLY
 ja .new_invalid
 test r8,r8
 jz .new_invalid
 test r9,r9
 jz .new_invalid
 cmp r9,NEBOC_FIXIT_MAX_EDITS
 ja .new_limit
 mov [rdi+NEBOC_FIXIT_DESCRIPTION_OFFSET],rsi
 mov [rdi+NEBOC_FIXIT_DESCRIPTION_LENGTH_OFFSET],rdx
 mov [rdi+NEBOC_FIXIT_APPLICABILITY_OFFSET],rcx
 mov [rdi+NEBOC_FIXIT_EDITS_OFFSET],r8
 mov [rdi+NEBOC_FIXIT_EDIT_CAPACITY_OFFSET],r9
 mov qword [rdi+NEBOC_FIXIT_EDIT_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_FIXIT_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.new_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.new_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; fixIt.addEdit(fix*, file_id, span*, replacement*, replacement_len, digest)
NEBOC_ABI_FUNCTION neboc_fix_it_add_edit
 test rdi,rdi
 jz .add_invalid
 cmp qword [rdi+NEBOC_FIXIT_ACTIVE_OFFSET],1
 jne .add_invalid
 test rsi,rsi
 jz .add_invalid
 test rdx,rdx
 jz .add_invalid
 cmp [rdx+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],rsi
 jne .add_invalid
 mov rax,[rdx+NEBOC_SOURCE_SPAN_START_OFFSET]
 cmp rax,[rdx+NEBOC_SOURCE_SPAN_END_OFFSET]
 ja .add_invalid
 mov r10,[rdx+NEBOC_SOURCE_SPAN_END_OFFSET]
 cmp r10,[rdx+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET]
 ja .add_invalid
 test r9,r9
 jz .add_invalid
 cmp [rdx+NEBOC_SPAN_DIGEST_OFFSET],r9
 jne .add_invalid
 cmp qword [rdx+NEBOC_SPAN_GENERATION_OFFSET],0
 je .add_invalid
 test r8,r8
 jz .replacement_ok
 test rcx,rcx
 jz .add_invalid
.replacement_ok:
 cmp r8,NEBOC_FIXIT_MAX_REPLACEMENT_BYTES
 ja .add_limit
 mov rax,[rdi+NEBOC_FIXIT_EDIT_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_FIXIT_EDIT_CAPACITY_OFFSET]
 jae .add_limit
 imul rax,NEBOC_FIXIT_EDIT_SIZE
 add rax,[rdi+NEBOC_FIXIT_EDITS_OFFSET]
 mov [rax+NEBOC_FIXIT_EDIT_FILE_ID_OFFSET],rsi
 lea r10,[rax+NEBOC_FIXIT_EDIT_SPAN_OFFSET]
 mov r11,[rdx]
 mov [r10],r11
 mov r11,[rdx+8]
 mov [r10+8],r11
 mov r11,[rdx+16]
 mov [r10+16],r11
 mov r11,[rdx+24]
 mov [r10+24],r11
 mov r11,[rdx+32]
 mov [r10+32],r11
 mov r11,[rdx+40]
 mov [r10+40],r11
 mov [rax+NEBOC_FIXIT_EDIT_REPLACEMENT_OFFSET],rcx
 mov [rax+NEBOC_FIXIT_EDIT_REPLACEMENT_LENGTH_OFFSET],r8
 mov [rax+NEBOC_FIXIT_EDIT_SNAPSHOT_DIGEST_OFFSET],r9
 inc qword [rdi+NEBOC_FIXIT_EDIT_COUNT_OFFSET]
 xor eax,eax
 ret
.add_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.add_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; fixIt.conflicts(other, out_bool) as (fix*, other*, out_bool*).
NEBOC_ABI_FUNCTION neboc_fix_it_conflicts
 test rdi,rdi
 jz .conflict_invalid
 test rsi,rsi
 jz .conflict_invalid
 test rdx,rdx
 jz .conflict_invalid
 cmp qword [rdi+NEBOC_FIXIT_ACTIVE_OFFSET],1
 jne .conflict_invalid
 cmp qword [rsi+NEBOC_FIXIT_ACTIVE_OFFSET],1
 jne .conflict_invalid
 mov qword [rdx],0
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 xor ebx,ebx
.outer:
 cmp rbx,[r12+NEBOC_FIXIT_EDIT_COUNT_OFFSET]
 jae .conflict_none
 mov r8,rbx
 imul r8,NEBOC_FIXIT_EDIT_SIZE
 add r8,[r12+NEBOC_FIXIT_EDITS_OFFSET]
 xor r15d,r15d
.inner:
 cmp r15,[r13+NEBOC_FIXIT_EDIT_COUNT_OFFSET]
 jae .next_outer
 mov r9,r15
 imul r9,NEBOC_FIXIT_EDIT_SIZE
 add r9,[r13+NEBOC_FIXIT_EDITS_OFFSET]
 mov rax,[r8+NEBOC_FIXIT_EDIT_FILE_ID_OFFSET]
 cmp rax,[r9+NEBOC_FIXIT_EDIT_FILE_ID_OFFSET]
 jne .next_inner
 mov rax,[r8+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 mov rcx,[r8+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 mov r10,[r9+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 mov r11,[r9+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 cmp rax,rcx
 jne .normal_overlap
 cmp r10,r11
 jne .normal_overlap
 cmp rax,r10
 je .conflict_yes
 jmp .next_inner
.normal_overlap:
 cmp rax,r11
 jae .next_inner
 cmp r10,rcx
 jae .next_inner
.conflict_yes:
 mov qword [r14],1
 jmp .conflict_done
.next_inner:
 inc r15
 jmp .inner
.next_outer:
 inc rbx
 jmp .outer
.conflict_none:
 xor eax,eax
.conflict_done:
 xor eax,eax
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.conflict_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%macro PREVIEW_APPEND 2
 mov rdi,r14
 lea rsi,[rel %1]
 mov edx,%2
 call explain_append
 test eax,eax
 jnz .preview_rollback
%endmacro

; fixIt.preview(sourceMap, writer) as (fix*, source_map*, writer*).
NEBOC_ABI_FUNCTION neboc_fix_it_preview
 test rdi,rdi
 jz .preview_invalid
 test rsi,rsi
 jz .preview_invalid
 test rdx,rdx
 jz .preview_invalid
 cmp qword [rdi+NEBOC_FIXIT_ACTIVE_OFFSET],1
 jne .preview_invalid
 cmp qword [rsi+NEBOC_SOURCE_MAP_ACTIVE_OFFSET],1
 jne .preview_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r14
 call validate_writer
 test eax,eax
 jnz .preview_finish
 mov rax,[r14+NEBOC_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 xor ebx,ebx
.preview_loop:
 cmp rbx,[r12+NEBOC_FIXIT_EDIT_COUNT_OFFSET]
 jae .preview_ok
 mov r15,rbx
 imul r15,NEBOC_FIXIT_EDIT_SIZE
 add r15,[r12+NEBOC_FIXIT_EDITS_OFFSET]
 mov rax,[r15+NEBOC_FIXIT_EDIT_FILE_ID_OFFSET]
 test rax,rax
 jz .preview_invalid_local
 cmp rax,[r13+NEBOC_SOURCE_MAP_COUNT_OFFSET]
 ja .preview_invalid_local
 dec rax
 imul rax,NEBOC_SOURCE_ENTRY_SIZE
 add rax,[r13+NEBOC_SOURCE_MAP_ENTRIES_OFFSET]
 mov [rsp+8],rax
 cmp qword [rax+NEBOC_SOURCE_ENTRY_ACTIVE_OFFSET],1
 jne .preview_invalid_local
 mov r8,[r15+NEBOC_FIXIT_EDIT_SNAPSHOT_DIGEST_OFFSET]
 cmp r8,[rax+NEBOC_SOURCE_ENTRY_DIGEST_OFFSET]
 jne .preview_invalid_local
 mov r8,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SPAN_GENERATION_OFFSET]
 cmp r8,[rax+NEBOC_SOURCE_ENTRY_GENERATION_OFFSET]
 jne .preview_invalid_local
 mov r8,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET]
 cmp r8,[rax+NEBOC_SOURCE_ENTRY_BYTES_LENGTH_OFFSET]
 jne .preview_invalid_local
 mov r8,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 mov r9,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 cmp r8,r9
 ja .preview_invalid_local
 cmp r9,[rax+NEBOC_SOURCE_ENTRY_BYTES_LENGTH_OFFSET]
 ja .preview_invalid_local
 PREVIEW_APPEND preview_old,preview_old_len
 mov rax,[rsp+8]
 cmp qword [r13+NEBOC_SOURCE_MAP_PATH_POLICY_OFFSET],NEBOC_PATH_POLICY_REDACT
 jne .old_path
 mov rdi,r14
 lea rsi,[rel redacted_path]
 mov edx,redacted_path_len
 jmp .append_old_path
.old_path:
 mov rdi,r14
 mov rsi,[rax+NEBOC_SOURCE_ENTRY_PATH_OFFSET]
 mov rdx,[rax+NEBOC_SOURCE_ENTRY_PATH_LENGTH_OFFSET]
.append_old_path:
 call explain_append
 test eax,eax
 jnz .preview_rollback
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .preview_rollback
 PREVIEW_APPEND preview_new,preview_new_len
 mov rax,[rsp+8]
 cmp qword [r13+NEBOC_SOURCE_MAP_PATH_POLICY_OFFSET],NEBOC_PATH_POLICY_REDACT
 jne .new_path
 mov rdi,r14
 lea rsi,[rel redacted_path]
 mov edx,redacted_path_len
 jmp .append_new_path
.new_path:
 mov rdi,r14
 mov rsi,[rax+NEBOC_SOURCE_ENTRY_PATH_OFFSET]
 mov rdx,[rax+NEBOC_SOURCE_ENTRY_PATH_LENGTH_OFFSET]
.append_new_path:
 call explain_append
 test eax,eax
 jnz .preview_rollback
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .preview_rollback
 PREVIEW_APPEND preview_hunk,preview_hunk_len
 mov rdi,r14
 mov rsi,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 call explain_append_u64
 test eax,eax
 jnz .preview_rollback
 PREVIEW_APPEND preview_range,preview_range_len
 mov rdi,r14
 mov rsi,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 call explain_append_u64
 test eax,eax
 jnz .preview_rollback
 PREVIEW_APPEND preview_hunk_close,preview_hunk_close_len
 mov rdi,r14
 lea rsi,[rel preview_minus]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .preview_rollback
 mov rax,[rsp+8]
 mov rdi,r14
 mov rsi,[rax+NEBOC_SOURCE_ENTRY_BYTES_OFFSET]
 add rsi,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 mov rdx,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 sub rdx,[r15+NEBOC_FIXIT_EDIT_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 call explain_append
 test eax,eax
 jnz .preview_rollback
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .preview_rollback
 mov rdi,r14
 lea rsi,[rel preview_plus]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .preview_rollback
 mov rdi,r14
 mov rsi,[r15+NEBOC_FIXIT_EDIT_REPLACEMENT_OFFSET]
 mov rdx,[r15+NEBOC_FIXIT_EDIT_REPLACEMENT_LENGTH_OFFSET]
 call explain_append
 test eax,eax
 jnz .preview_rollback
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .preview_rollback
 inc rbx
 jmp .preview_loop
.preview_invalid_local:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .preview_rollback
.preview_ok:
 xor eax,eax
 jmp .preview_finish
.preview_rollback:
 mov rcx,[rsp]
 mov [r14+NEBOC_WRITER_LENGTH_OFFSET],rcx
.preview_finish:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.preview_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; DiagnosticExplanation.load(code, out) as (code*, length, out*).
NEBOC_ABI_FUNCTION neboc_diagnostic_explanation_load
 test rdi,rdi
 jz .load_invalid
 test rsi,rsi
 jz .load_invalid
 test rdx,rdx
 jz .load_invalid
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 lea r10,[rel catalog]
 xor r11d,r11d
.load_loop:
 cmp r11d,NEBOC_EXPLANATION_COUNT
 jae .load_not_found
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r10+NEBOC_EXPLANATION_CODE_OFFSET]
 mov rcx,[r10+NEBOC_EXPLANATION_CODE_LENGTH_OFFSET]
 call exact_equal
 test eax,eax
 jnz .load_found
 add r10,CATALOG_ENTRY_SIZE
 inc r11d
 jmp .load_loop
.load_found:
 mov rdi,rbx
 mov rsi,r10
 mov ecx,NEBOC_EXPLANATION_SIZE/8
 rep movsq
 xor eax,eax
 jmp .load_done
.load_not_found:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.load_done:
 pop r13
 pop r12
 pop rbx
 ret
.load_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; explanation.examples(out_positive_slice*, out_negative_slice*).
NEBOC_ABI_FUNCTION neboc_diagnostic_explanation_examples
 test rdi,rdi
 jz .examples_invalid
 test rsi,rsi
 jz .examples_invalid
 test rdx,rdx
 jz .examples_invalid
 cmp qword [rdi+NEBOC_EXPLANATION_VERSION_OFFSET],NEBOC_EXPLANATION_VERSION_V1
 jne .examples_invalid
 mov rax,[rdi+NEBOC_EXPLANATION_POSITIVE_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_EXPLANATION_POSITIVE_LENGTH_OFFSET]
 mov [rsi+8],rax
 mov rax,[rdi+NEBOC_EXPLANATION_NEGATIVE_OFFSET]
 mov [rdx],rax
 mov rax,[rdi+NEBOC_EXPLANATION_NEGATIVE_LENGTH_OFFSET]
 mov [rdx+8],rax
 xor eax,eax
 ret
.examples_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; explanation.relatedCodes(out_slice*).
NEBOC_ABI_FUNCTION neboc_diagnostic_explanation_related_codes
 test rdi,rdi
 jz .related_invalid
 test rsi,rsi
 jz .related_invalid
 cmp qword [rdi+NEBOC_EXPLANATION_VERSION_OFFSET],NEBOC_EXPLANATION_VERSION_V1
 jne .related_invalid
 mov rax,[rdi+NEBOC_EXPLANATION_RELATED_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_EXPLANATION_RELATED_LENGTH_OFFSET]
 mov [rsi+8],rax
 xor eax,eax
 ret
.related_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%macro RENDER_FIELD 4
 mov rdi,r12
 lea rsi,[rel %1]
 mov edx,%2
 call explain_append
 test eax,eax
 jnz .render_rollback
 mov rdi,r12
 mov rsi,[rbx+%3]
 mov rdx,[rbx+%4]
 call explain_append
 test eax,eax
 jnz .render_rollback
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .render_rollback
%endmacro

; Render a loaded explanation into a bounded writer.
NEBOC_ABI_FUNCTION neboc_diagnostic_explanation_render
 test rdi,rdi
 jz .render_invalid
 test rsi,rsi
 jz .render_invalid
 cmp qword [rdi+NEBOC_EXPLANATION_VERSION_OFFSET],NEBOC_EXPLANATION_VERSION_V1
 jne .render_invalid
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,r12
 call validate_writer
 test eax,eax
 jnz .render_done
 mov rax,[r12+NEBOC_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rdi,r12
 mov rsi,[rbx+NEBOC_EXPLANATION_CODE_OFFSET]
 mov rdx,[rbx+NEBOC_EXPLANATION_CODE_LENGTH_OFFSET]
 call explain_append
 test eax,eax
 jnz .render_rollback
 mov rdi,r12
 lea rsi,[rel render_colon]
 mov edx,render_colon_len
 call explain_append
 test eax,eax
 jnz .render_rollback
 mov rdi,r12
 mov rsi,[rbx+NEBOC_EXPLANATION_TITLE_OFFSET]
 mov rdx,[rbx+NEBOC_EXPLANATION_TITLE_LENGTH_OFFSET]
 call explain_append
 test eax,eax
 jnz .render_rollback
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .render_rollback
 RENDER_FIELD render_causes,render_causes_len,NEBOC_EXPLANATION_CAUSE_OFFSET,NEBOC_EXPLANATION_CAUSE_LENGTH_OFFSET
 RENDER_FIELD render_solutions,render_solutions_len,NEBOC_EXPLANATION_SOLUTION_OFFSET,NEBOC_EXPLANATION_SOLUTION_LENGTH_OFFSET
 RENDER_FIELD render_positive,render_positive_len,NEBOC_EXPLANATION_POSITIVE_OFFSET,NEBOC_EXPLANATION_POSITIVE_LENGTH_OFFSET
 RENDER_FIELD render_negative,render_negative_len,NEBOC_EXPLANATION_NEGATIVE_OFFSET,NEBOC_EXPLANATION_NEGATIVE_LENGTH_OFFSET
 RENDER_FIELD render_related,render_related_len,NEBOC_EXPLANATION_RELATED_OFFSET,NEBOC_EXPLANATION_RELATED_LENGTH_OFFSET
 xor eax,eax
 jmp .render_done
.render_rollback:
 mov rcx,[rsp]
 mov [r12+NEBOC_WRITER_LENGTH_OFFSET],rcx
.render_done:
 add rsp,8
 pop r12
 pop rbx
 ret
.render_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Search the local catalog by exact byte substring across code/title/tags.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_diagnostic_explanation_search
 test rdi,rdi
 jz .search_invalid
 test rsi,rsi
 jz .search_invalid
 cmp rsi,NEBOC_EXPLANATION_MAX_QUERY_BYTES
 ja .search_limit
 test rdx,rdx
 jz .search_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r14
 call validate_writer
 test eax,eax
 jnz .search_done
 mov rax,[r14+NEBOC_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 lea rbx,[rel catalog]
 xor r15d,r15d
 xor r11d,r11d
.search_loop:
 cmp r15d,NEBOC_EXPLANATION_COUNT
 jae .search_finish
 mov rdi,[rbx+NEBOC_EXPLANATION_CODE_OFFSET]
 mov rsi,[rbx+NEBOC_EXPLANATION_CODE_LENGTH_OFFSET]
 mov rdx,r12
 mov rcx,r13
 call contains
 test eax,eax
 jnz .search_match
 mov rdi,[rbx+NEBOC_EXPLANATION_TITLE_OFFSET]
 mov rsi,[rbx+NEBOC_EXPLANATION_TITLE_LENGTH_OFFSET]
 mov rdx,r12
 mov rcx,r13
 call contains
 test eax,eax
 jnz .search_match
 mov rdi,[rbx+CATALOG_TAGS_OFFSET]
 mov rsi,[rbx+CATALOG_TAGS_LENGTH_OFFSET]
 mov rdx,r12
 mov rcx,r13
 call contains
 test eax,eax
 jz .search_next
.search_match:
 mov rdi,r14
 mov rsi,[rbx+NEBOC_EXPLANATION_CODE_OFFSET]
 mov rdx,[rbx+NEBOC_EXPLANATION_CODE_LENGTH_OFFSET]
 call explain_append
 test eax,eax
 jnz .search_rollback
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,1
 call explain_append
 test eax,eax
 jnz .search_rollback
 inc r11d
.search_next:
 add rbx,CATALOG_ENTRY_SIZE
 inc r15d
 jmp .search_loop
.search_finish:
 test r11d,r11d
 jnz .search_ok
 mov rdi,r14
 lea rsi,[rel search_empty]
 mov edx,search_empty_len
 call explain_append
 test eax,eax
 jnz .search_rollback
.search_ok:
 xor eax,eax
 jmp .search_done
.search_rollback:
 mov rcx,[rsp]
 mov [r14+NEBOC_WRITER_LENGTH_OFFSET],rcx
.search_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.search_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.search_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
