; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F02 bounded multi-unit SourceMap and provenance.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"

section .rodata
redacted_path: db "<redacted>"
redacted_path_len equ $-redacted_path

section .text
; source_map_new(map*, entries*, capacity, path_policy)
NEBOC_ABI_FUNCTION neboc_source_map_new
 test rdi,rdi
 jz .new_invalid
 test rsi,rsi
 jz .new_invalid
 test rdx,rdx
 jz .new_invalid
 cmp rdx,NEBOC_SOURCE_MAP_MAX_FILES
 ja .new_limit
 cmp rcx,NEBOC_PATH_POLICY_RELATIVE
 jb .new_invalid
 cmp rcx,NEBOC_PATH_POLICY_REDACT
 ja .new_invalid
 mov r9,rcx
 push rdi
 xor eax,eax
 mov r8,rdx
 shl r8,3
 mov rcx,r8
 rep stosq
 pop rdi
 mov [rdi+NEBOC_SOURCE_MAP_ENTRIES_OFFSET],rsi
 mov [rdi+NEBOC_SOURCE_MAP_CAPACITY_OFFSET],rdx
 mov [rdi+NEBOC_SOURCE_MAP_PATH_POLICY_OFFSET],r9
 mov qword [rdi+NEBOC_SOURCE_MAP_GENERATION_OFFSET],1
 mov qword [rdi+NEBOC_SOURCE_MAP_ACTIVE_OFFSET],1
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.new_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.new_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Internal: map in rdi, id in rsi; entry in rax or zero.
find_entry:
 test rdi,rdi
 jz .find_none
 cmp qword [rdi+NEBOC_SOURCE_MAP_ACTIVE_OFFSET],1
 jne .find_none
 test rsi,rsi
 jz .find_none
 mov rcx,[rdi+NEBOC_SOURCE_MAP_COUNT_OFFSET]
 cmp rsi,rcx
 ja .find_none
 dec rsi
 imul rsi,NEBOC_SOURCE_ENTRY_SIZE
 mov rax,[rdi+NEBOC_SOURCE_MAP_ENTRIES_OFFSET]
 add rax,rsi
 cmp qword [rax+NEBOC_SOURCE_ENTRY_ACTIVE_OFFSET],1
 jne .find_none
 ret
.find_none:
 xor eax,eax
 ret

; source_map_add_file(map*, AddFileRequest*, out_file_id*)
NEBOC_ABI_FUNCTION neboc_source_map_add_file
 test rdi,rdi
 jz .add_invalid
 test rsi,rsi
 jz .add_invalid
 test rdx,rdx
 jz .add_invalid
 cmp qword [rdi+NEBOC_SOURCE_MAP_ACTIVE_OFFSET],1
 jne .add_invalid
 mov r8,[rsi+NEBOC_ADD_FILE_PATH_LENGTH_OFFSET]
 test r8,r8
 jz .add_invalid
 cmp r8,NEBOC_SOURCE_MAP_MAX_PATH
 ja .add_limit
 mov r9,[rsi+NEBOC_ADD_FILE_PATH_OFFSET]
 test r9,r9
 jz .add_invalid
 mov r10,[rsi+NEBOC_ADD_FILE_BYTES_LENGTH_OFFSET]
 cmp r10,NEBOC_SOURCE_MAP_MAX_BYTES
 ja .add_limit
 test r10,r10
 jz .add_bytes_ok
 cmp qword [rsi+NEBOC_ADD_FILE_BYTES_OFFSET],0
 je .add_invalid
.add_bytes_ok:
 cmp qword [rsi+NEBOC_ADD_FILE_DIGEST_OFFSET],0
 je .add_invalid
 cmp qword [rdi+NEBOC_SOURCE_MAP_PATH_POLICY_OFFSET],NEBOC_PATH_POLICY_RELATIVE
 jne .add_path_scan
 cmp byte [r9],'/'
 je .add_invalid
.add_path_scan:
 xor ecx,ecx
.add_path_loop:
 cmp rcx,r8
 jae .add_capacity
 cmp byte [r9+rcx],0
 je .add_invalid
 cmp byte [r9+rcx],92
 je .add_invalid
 cmp qword [rdi+NEBOC_SOURCE_MAP_PATH_POLICY_OFFSET],NEBOC_PATH_POLICY_RELATIVE
 jne .add_path_next
 cmp byte [r9+rcx],':'
 je .add_invalid
.add_path_next:
 inc rcx
 jmp .add_path_loop
.add_capacity:
 mov rcx,[rdi+NEBOC_SOURCE_MAP_COUNT_OFFSET]
 cmp rcx,[rdi+NEBOC_SOURCE_MAP_CAPACITY_OFFSET]
 jae .add_limit
 mov rax,rcx
 imul rax,NEBOC_SOURCE_ENTRY_SIZE
 add rax,[rdi+NEBOC_SOURCE_MAP_ENTRIES_OFFSET]
 inc rcx
 mov [rax+NEBOC_SOURCE_ENTRY_ID_OFFSET],rcx
 mov r8,[rsi+NEBOC_ADD_FILE_PATH_OFFSET]
 mov [rax+NEBOC_SOURCE_ENTRY_PATH_OFFSET],r8
 mov r8,[rsi+NEBOC_ADD_FILE_PATH_LENGTH_OFFSET]
 mov [rax+NEBOC_SOURCE_ENTRY_PATH_LENGTH_OFFSET],r8
 mov r8,[rsi+NEBOC_ADD_FILE_BYTES_OFFSET]
 mov [rax+NEBOC_SOURCE_ENTRY_BYTES_OFFSET],r8
 mov r8,[rsi+NEBOC_ADD_FILE_BYTES_LENGTH_OFFSET]
 mov [rax+NEBOC_SOURCE_ENTRY_BYTES_LENGTH_OFFSET],r8
 mov r8,[rsi+NEBOC_ADD_FILE_DIGEST_OFFSET]
 mov [rax+NEBOC_SOURCE_ENTRY_DIGEST_OFFSET],r8
 mov r8,[rdi+NEBOC_SOURCE_MAP_GENERATION_OFFSET]
 mov [rax+NEBOC_SOURCE_ENTRY_GENERATION_OFFSET],r8
 mov qword [rax+NEBOC_SOURCE_ENTRY_ACTIVE_OFFSET],1
 mov [rdi+NEBOC_SOURCE_MAP_COUNT_OFFSET],rcx
 mov [rdx],rcx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.add_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.add_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Internal location(map*, id, byte_offset, out*).
source_location:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rcx
 mov r12,rdx
 call find_entry
 test rax,rax
 jz .location_invalid
 mov r13,rax
 cmp r12,[r13+NEBOC_SOURCE_ENTRY_BYTES_LENGTH_OFFSET]
 ja .location_invalid
 cmp r12,[r13+NEBOC_SOURCE_ENTRY_BYTES_LENGTH_OFFSET]
 jae .location_boundary
 mov r14,[r13+NEBOC_SOURCE_ENTRY_BYTES_OFFSET]
 mov al,[r14+r12]
 and al,0xc0
 cmp al,0x80
 je .location_invalid
.location_boundary:
 mov r14,[r13+NEBOC_SOURCE_ENTRY_BYTES_OFFSET]
 xor r15d,r15d
 mov r8d,1
 xor r9d,r9d
.line_scan:
 cmp r15,r12
 jae .line_ready
 cmp byte [r14+r15],10
 jne .line_next
 inc r8
 lea r9,[r15+1]
.line_next:
 inc r15
 jmp .line_scan
.line_ready:
 mov rax,[r13+NEBOC_SOURCE_ENTRY_ID_OFFSET]
 mov [rbx+NEBOC_SOURCE_LOCATION_FILE_ID_OFFSET],rax
 mov [rbx+NEBOC_SOURCE_MAP_SOURCE_LOCATION_BYTE_OFFSET],r12
 mov [rbx+NEBOC_MACHINE_SOURCE_LOCATION_LINE_OFFSET],r8
 mov rax,r12
 sub rax,r9
 inc rax
 mov [rbx+NEBOC_SOURCE_LOCATION_BYTE_COLUMN_OFFSET],rax
 mov r10d,1
 mov r11d,1
 mov r15,r9
.column_scan:
 cmp r15,r12
 jae .column_done
 movzx eax,byte [r14+r15]
 cmp eax,9
 jne .decode
 mov rax,r11
 dec rax
 shr rax,2
 inc rax
 shl rax,2
 inc rax
 mov r11,rax
 inc r10
 inc r15
 jmp .column_scan
.decode:
 cmp eax,0x80
 jb .ascii
 cmp eax,0xe0
 jb .two
 cmp eax,0xf0
 jb .three
 mov edx,eax
 and edx,7
 shl edx,18
 movzx eax,byte [r14+r15+1]
 and eax,0x3f
 shl eax,12
 or edx,eax
 movzx eax,byte [r14+r15+2]
 and eax,0x3f
 shl eax,6
 or edx,eax
 movzx eax,byte [r14+r15+3]
 and eax,0x3f
 or edx,eax
 add r15,4
 jmp .width
.three:
 mov edx,eax
 and edx,15
 shl edx,12
 movzx eax,byte [r14+r15+1]
 and eax,0x3f
 shl eax,6
 or edx,eax
 movzx eax,byte [r14+r15+2]
 and eax,0x3f
 or edx,eax
 add r15,3
 jmp .width
.two:
 mov edx,eax
 and edx,31
 shl edx,6
 movzx eax,byte [r14+r15+1]
 and eax,0x3f
 or edx,eax
 add r15,2
 jmp .width
.ascii:
 mov edx,eax
 inc r15
.width:
 inc r10
 cmp edx,0x300
 jb .width_check_wide
 cmp edx,0x36f
 jbe .column_scan
.width_check_wide:
 mov eax,1
 cmp edx,0x1100
 jb .width_emoji
 cmp edx,0x115f
 jbe .wide
 cmp edx,0x2e80
 jb .width_emoji
 cmp edx,0xd7a3
 jbe .wide
 cmp edx,0xf900
 jb .width_emoji
 cmp edx,0xfaff
 jbe .wide
.width_emoji:
 cmp edx,0x1f300
 jb .store_width
 cmp edx,0x1faff
 ja .store_width
.wide:
 mov eax,2
.store_width:
 add r11,rax
 jmp .column_scan
.column_done:
 mov [rbx+NEBOC_SOURCE_LOCATION_SCALAR_COLUMN_OFFSET],r10
 mov [rbx+NEBOC_SOURCE_LOCATION_DISPLAY_COLUMN_OFFSET],r11
 xor eax,eax
 jmp .location_finish
.location_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.location_finish:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; source_map_line_column(map*, file_id, byte_offset, out_location*)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_source_map_line_column
 test rcx,rcx
 jz .line_column_invalid
 call source_location
 ret
.line_column_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_map_resolve(map*, RF52Span*, out_resolved*)
%undef call
NEBOC_ABI_FUNCTION neboc_source_map_resolve
 test rdi,rdi
 jz .resolve_invalid
 test rsi,rsi
 jz .resolve_invalid
 test rdx,rdx
 jz .resolve_invalid
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rsi,[r12+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 call find_entry
 test rax,rax
 jz .resolve_invalid_local
 mov rcx,[r12+NEBOC_SPAN_DIGEST_OFFSET]
 cmp rcx,[rax+NEBOC_SOURCE_ENTRY_DIGEST_OFFSET]
 jne .resolve_invalid_local
 mov rcx,[r12+NEBOC_SPAN_GENERATION_OFFSET]
 cmp rcx,[rax+NEBOC_SOURCE_ENTRY_GENERATION_OFFSET]
 jne .resolve_invalid_local
 mov rcx,[r12+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET]
 cmp rcx,[rax+NEBOC_SOURCE_ENTRY_BYTES_LENGTH_OFFSET]
 jne .resolve_invalid_local
 mov rcx,[r12+NEBOC_SOURCE_SPAN_START_OFFSET]
 cmp rcx,[r12+NEBOC_SOURCE_SPAN_END_OFFSET]
 ja .resolve_invalid_local
 mov rdi,rbx
 mov rsi,[r12+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 mov rdx,[r12+NEBOC_SOURCE_SPAN_START_OFFSET]
 mov rcx,r13
 call source_location
 test eax,eax
 jne .resolve_finish
 mov rdi,rbx
 mov rsi,[r12+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 mov rdx,[r12+NEBOC_SOURCE_SPAN_END_OFFSET]
 lea rcx,[r13+NEBOC_RESOLVED_END_OFFSET]
 call source_location
 jmp .resolve_finish
.resolve_invalid_local:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.resolve_finish:
 pop r13
 pop r12
 pop rbx
 ret
.resolve_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_map_snippet(map*, span*, context_lines, out_snippet*)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_source_map_snippet
 test rdi,rdi
 jz .snippet_invalid
 test rsi,rsi
 jz .snippet_invalid
 test rcx,rcx
 jz .snippet_invalid
 cmp rdx,NEBOC_SNIPPET_MAX_CONTEXT_LINES
 ja .snippet_limit
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rsi
 mov r12,rdx
 mov r13,rcx
 mov rsi,[rbx+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 call find_entry
 test rax,rax
 jz .snippet_invalid_local
 mov r14,rax
 mov rdx,[rbx+NEBOC_SPAN_DIGEST_OFFSET]
 cmp rdx,[r14+NEBOC_SOURCE_ENTRY_DIGEST_OFFSET]
 jne .snippet_invalid_local
 mov r8,[rbx+NEBOC_SOURCE_SPAN_START_OFFSET]
 mov r9,[rbx+NEBOC_SOURCE_SPAN_END_OFFSET]
 cmp r8,r9
 ja .snippet_invalid_local
 cmp r9,[r14+NEBOC_SOURCE_ENTRY_BYTES_LENGTH_OFFSET]
 ja .snippet_invalid_local
 mov r10,r8
 mov rcx,r12
 mov r11,[r14+NEBOC_SOURCE_ENTRY_BYTES_OFFSET]
.snippet_back:
 test r10,r10
 jz .snippet_forward_setup
 test rcx,rcx
 jz .snippet_forward_setup
 dec r10
 cmp byte [r11+r10],10
 jne .snippet_back
 dec rcx
 test rcx,rcx
 jz .snippet_forward_setup
 jmp .snippet_back
.snippet_forward_setup:
 mov rax,r9
 mov rcx,r12
 mov rdx,[r14+NEBOC_SOURCE_ENTRY_BYTES_LENGTH_OFFSET]
.snippet_forward:
 cmp rax,rdx
 jae .snippet_window
 cmp byte [r11+rax],10
 jne .snippet_forward_next
 dec rcx
 js .snippet_window
.snippet_forward_next:
 inc rax
 mov rsi,rax
 sub rsi,r10
 cmp rsi,NEBOC_SNIPPET_MAX_BYTES
 ja .snippet_limit_local
 jmp .snippet_forward
.snippet_window:
 mov rsi,rax
 sub rsi,r10
 cmp rsi,NEBOC_SNIPPET_MAX_BYTES
 ja .snippet_limit_local
 add r11,r10
 mov [r13+NEBOC_SOURCE_MAP_SNIPPET_BYTES_OFFSET],r11
 mov [r13+NEBOC_SNIPPET_LENGTH_OFFSET],rsi
 mov [r13+NEBOC_SOURCE_MAP_SNIPPET_WINDOW_START_OFFSET],r10
 sub r8,r10
 sub r9,r10
 mov [r13+NEBOC_SOURCE_MAP_SNIPPET_HIGHLIGHT_START_OFFSET],r8
 mov [r13+NEBOC_SOURCE_MAP_SNIPPET_HIGHLIGHT_END_OFFSET],r9
 xor eax,eax
 jmp .snippet_finish
.snippet_limit_local:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .snippet_finish
.snippet_invalid_local:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.snippet_finish:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.snippet_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.snippet_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_map_display_path(map*, file_id, style, out_slice*)
%undef call
NEBOC_ABI_FUNCTION neboc_source_map_display_path
 test rcx,rcx
 jz .path_invalid
 cmp rdx,NEBOC_PATH_STYLE_RELATIVE
 jb .path_invalid
 cmp rdx,NEBOC_PATH_STYLE_REDACTED
 ja .path_invalid
 push rbx
 mov rbx,rcx
 call find_entry
 test rax,rax
 jz .path_invalid_local
 cmp qword [rdi+NEBOC_SOURCE_MAP_PATH_POLICY_OFFSET],NEBOC_PATH_POLICY_REDACT
 je .path_redacted
 cmp rdx,NEBOC_PATH_STYLE_REDACTED
 je .path_redacted
 mov r8,[rax+NEBOC_SOURCE_ENTRY_PATH_OFFSET]
 mov r9,[rax+NEBOC_SOURCE_ENTRY_PATH_LENGTH_OFFSET]
 cmp rdx,NEBOC_PATH_STYLE_BASENAME
 jne .path_store
 mov rcx,r9
.path_basename:
 test rcx,rcx
 jz .path_store
 dec rcx
 cmp byte [r8+rcx],'/'
 jne .path_basename
 inc rcx
 add r8,rcx
 sub r9,rcx
 jmp .path_store
.path_redacted:
 lea r8,[rel redacted_path]
 mov r9d,redacted_path_len
.path_store:
 mov [rbx+NEBOC_SOURCE_MAP_SLICE_POINTER_OFFSET],r8
 mov [rbx+neboc_recovery_SLICE_LENGTH_OFFSET],r9
 xor eax,eax
 pop rbx
 ret
.path_invalid_local:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 pop rbx
 ret
.path_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; span_merge(out*, first*, last*)
NEBOC_ABI_FUNCTION neboc_span_merge
 test rdi,rdi
 jz .merge_invalid
 test rsi,rsi
 jz .merge_invalid
 test rdx,rdx
 jz .merge_invalid
 mov r11,[rsi+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 cmp r11,[rdx+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 jne .merge_invalid
 mov rcx,[rsi+NEBOC_SPAN_DIGEST_OFFSET]
 cmp rcx,[rdx+NEBOC_SPAN_DIGEST_OFFSET]
 jne .merge_invalid
 mov r8,[rsi+NEBOC_SPAN_GENERATION_OFFSET]
 cmp r8,[rdx+NEBOC_SPAN_GENERATION_OFFSET]
 jne .merge_invalid
 mov r9,[rsi+NEBOC_SOURCE_SPAN_START_OFFSET]
 mov r10,[rdx+NEBOC_SOURCE_SPAN_END_OFFSET]
 cmp r9,r10
 ja .merge_invalid
 push rbx
 mov rbx,rcx
 push rdi
 xor eax,eax
 mov ecx,NEBOC_SPAN_SIZE/8
 rep stosq
 pop rdi
 mov [rdi+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],r11
 mov [rdi+NEBOC_SOURCE_SPAN_START_OFFSET],r9
 mov [rdi+NEBOC_SOURCE_SPAN_END_OFFSET],r10
 mov rax,[rsi+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET]
 mov [rdi+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET],rax
 mov [rdi+NEBOC_SPAN_DIGEST_OFFSET],rbx
 mov [rdi+NEBOC_SPAN_GENERATION_OFFSET],r8
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.merge_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; span_related_location(span*, kind, other_span*)
NEBOC_ABI_FUNCTION neboc_span_related_location
 test rdi,rdi
 jz .related_invalid
 test rdx,rdx
 jz .related_invalid
 cmp rsi,NEBOC_RELATED_DECLARATION
 jb .related_invalid
 cmp rsi,NEBOC_RELATED_GENERATED
 ja .related_invalid
 mov rcx,[rdi+NEBOC_SPAN_RELATED_COUNT_OFFSET]
 cmp rcx,NEBOC_SPAN_MAX_RELATED
 jae .related_limit
 mov r8,rcx
 imul r8,NEBOC_RELATED_SIZE
 add r8,rdi
 add r8,NEBOC_SPAN_RELATED_OFFSET
 mov [r8+NEBOC_RELATED_KIND_OFFSET],rsi
 push rdi
 mov rdi,r8
 add rdi,NEBOC_RELATED_SPAN_OFFSET
 mov rsi,rdx
 mov ecx,NEBOC_SOURCE_SPAN_QWORDS
 rep movsq
 pop rdi
 inc qword [rdi+NEBOC_SPAN_RELATED_COUNT_OFFSET]
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.related_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.related_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; span_add_expansion(span*, kind, other_span*)
NEBOC_ABI_FUNCTION neboc_span_add_expansion
 test rdi,rdi
 jz .expansion_invalid
 test rdx,rdx
 jz .expansion_invalid
 cmp rsi,NEBOC_RELATED_EXPANSION
 jb .expansion_invalid
 cmp rsi,NEBOC_RELATED_GENERATED
 ja .expansion_invalid
 mov rcx,[rdi+NEBOC_SPAN_EXPANSION_COUNT_OFFSET]
 cmp rcx,NEBOC_SPAN_MAX_EXPANSIONS
 jae .expansion_limit
 mov r8,rcx
 imul r8,NEBOC_RELATED_SIZE
 add r8,rdi
 add r8,NEBOC_SPAN_EXPANSIONS_OFFSET
 mov [r8],rsi
 push rdi
 lea rdi,[r8+NEBOC_RELATED_SPAN_OFFSET]
 mov rsi,rdx
 mov ecx,NEBOC_SOURCE_SPAN_QWORDS
 rep movsq
 pop rdi
 inc qword [rdi+NEBOC_SPAN_EXPANSION_COUNT_OFFSET]
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.expansion_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.expansion_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; span_expansion_trace(span*, out_slice*)
NEBOC_ABI_FUNCTION neboc_span_expansion_trace
 test rdi,rdi
 jz .trace_invalid
 test rsi,rsi
 jz .trace_invalid
 lea rax,[rdi+NEBOC_SPAN_EXPANSIONS_OFFSET]
 mov [rsi+NEBOC_SOURCE_MAP_SLICE_POINTER_OFFSET],rax
 mov rax,[rdi+NEBOC_SPAN_EXPANSION_COUNT_OFFSET]
 mov [rsi+neboc_recovery_SLICE_LENGTH_OFFSET],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.trace_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; span_source_digest(span*, out_u64*)
NEBOC_ABI_FUNCTION neboc_span_source_digest
 test rdi,rdi
 jz .digest_invalid
 test rsi,rsi
 jz .digest_invalid
 mov rax,[rdi+NEBOC_SPAN_DIGEST_OFFSET]
 test rax,rax
 jz .digest_invalid
 mov [rsi],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.digest_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_map_invalidate(map*, file_id, new_digest)
NEBOC_ABI_FUNCTION neboc_source_map_invalidate
 test rdx,rdx
 jz .invalidate_invalid
 push rbx
 mov rbx,rdi
 call find_entry
 test rax,rax
 jz .invalidate_invalid_local
 mov [rax+NEBOC_SOURCE_ENTRY_DIGEST_OFFSET],rdx
 inc qword [rax+NEBOC_SOURCE_ENTRY_GENERATION_OFFSET]
 inc qword [rbx+NEBOC_SOURCE_MAP_GENERATION_OFFSET]
 xor eax,eax
 pop rbx
 ret
.invalidate_invalid_local:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 pop rbx
 ret
.invalidate_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
