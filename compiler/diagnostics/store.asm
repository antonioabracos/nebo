; Nebo Assembly — bounded deterministic DiagnosticStore v0
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/registry.inc"

extern neboc_diagnostic_code_registry_lookup

section .text
; diagnostic_init(diag*, code, severity, phase, primary_span*)
NEBOC_ABI_FUNCTION neboc_diagnostic_init
 test rdi,rdi
 jz .invalid_fast
 test rsi,rsi
 jz .invalid_fast
 test r8,r8
 jz .invalid_fast
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 xor eax,eax
 mov ecx,NEBOC_DIAGNOSTIC_QWORDS
 rep stosq
 mov [rbx+NEBOC_DIAGNOSTIC_CODE_OFFSET],r12
 mov [rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],r13
 mov [rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET],r14
 mov rax,[r15]
 mov [rbx+32],rax
 mov rax,[r15+8]
 mov [rbx+40],rax
 mov rax,[r15+16]
 mov [rbx+48],rax
 mov rax,[r15+24]
 mov [rbx+56],rax
 mov qword [rbx+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 mov qword [rbx+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 cmp r14,NEBOC_DIAGNOSTIC_PHASE_LEX
 je .legacy_syntax
 cmp r14,NEBOC_DIAGNOSTIC_PHASE_PARSE
 je .legacy_syntax
 cmp r14,NEBOC_DIAGNOSTIC_PHASE_NAME
 je .legacy_type
 cmp r14,NEBOC_DIAGNOSTIC_PHASE_TYPE
 je .legacy_type
 cmp r14,NEBOC_DIAGNOSTIC_PHASE_INTERNAL
 jne .legacy_exit
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_INTERNAL
 jmp .legacy_exit
.legacy_syntax:
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_SYNTAX
 jmp .legacy_exit
.legacy_type:
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_TYPE
.legacy_exit:
 mov qword [rbx+NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET],NEBOC_DIAGNOSTIC_EXIT_USER_ERROR
 cmp r13,NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 je .legacy_success
 cmp r13,NEBOC_DIAGNOSTIC_SEVERITY_NOTE
 jne .legacy_done
.legacy_success:
 mov qword [rbx+NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET],NEBOC_DIAGNOSTIC_EXIT_SUCCESS
.legacy_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_fast:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; diagnostic_set_phase(diag*, phase) -- explicit because init zeroes RCX.
NEBOC_ABI_FUNCTION neboc_diagnostic_set_phase
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov [rdi+NEBOC_DIAGNOSTIC_PHASE_OFFSET],rsi
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; diagnostic_set_args(diag*, arg0*, len0, arg1*, len1)
NEBOC_ABI_FUNCTION neboc_diagnostic_set_args
 test rdi,rdi
 jz .invalid_args
 test rdx,rdx
 jz .arg0_ok
 test rsi,rsi
 jz .invalid_args
.arg0_ok:
 test r8,r8
 jz .arg1_ok
 test rcx,rcx
 jz .invalid_args
.arg1_ok:
 mov [rdi+112],rsi
 mov [rdi+120],rdx
 mov [rdi+128],rcx
 mov [rdi+136],r8
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_args: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; diagnostic_set_note_suggestion(diag*, note*, note_len, suggestion*, suggestion_len)
NEBOC_ABI_FUNCTION neboc_diagnostic_set_note_suggestion
 test rdi,rdi
 jz .invalid_ns
 test rdx,rdx
 jz .note_ok
 test rsi,rsi
 jz .invalid_ns
.note_ok:
 test r8,r8
 jz .suggest_ok
 test rcx,rcx
 jz .invalid_ns
.suggest_ok:
 mov [rdi+144],rsi
 mov [rdi+152],rdx
 mov [rdi+160],rcx
 mov [rdi+168],r8
 xor eax,eax
 test rdx,rdx
 jz .no_note
 or eax,NEBOC_DIAGNOSTIC_FLAG_HAS_NOTE
.no_note:
 test r8,r8
 jz .flags
 or eax,NEBOC_DIAGNOSTIC_FLAG_HAS_SUGGESTION
.flags:
 mov [rdi+184],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_ns: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; diagnostic_set_secondary(diag*, span*, label*, label_len)
NEBOC_ABI_FUNCTION neboc_diagnostic_set_secondary
 test rdi,rdi
 jz .invalid_sec
 test rsi,rsi
 jz .invalid_sec
 test rcx,rcx
 jz .label_ok
 test rdx,rdx
 jz .invalid_sec
.label_ok:
 mov rax,[rsi]
 mov [rdi+64],rax
 mov rax,[rsi+8]
 mov [rdi+72],rax
 mov rax,[rsi+16]
 mov [rdi+80],rax
 mov rax,[rsi+24]
 mov [rdi+88],rax
 mov [rdi+96],rdx
 mov [rdi+104],rcx
 or qword [rdi+184],NEBOC_DIAGNOSTIC_FLAG_HAS_SECONDARY
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_sec: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; store_init(store*, entries*, capacity, limit)
NEBOC_ABI_FUNCTION neboc_diagnostic_store_init
 test rdi,rdi
 jz .invalid_si
 test rsi,rsi
 jz .invalid_si
 test rdx,rdx
 jz .invalid_si
 test rcx,rcx
 jz .invalid_si
 cmp rcx,rdx
 ja .invalid_si
 cmp rcx,NEBOC_DIAGNOSTIC_MAX_COUNT
 ja .invalid_si
 mov [rdi],rsi
 mov qword [rdi+8],0
 mov [rdi+16],rdx
 mov [rdi+24],rcx
 mov qword [rdi+32],1
 mov qword [rdi+40],0
 mov qword [rdi+48],0
 mov qword [rdi+56],1
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_si: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; store_push(store*, diagnostic*)
NEBOC_ABI_FUNCTION neboc_diagnostic_store_push
 test rdi,rdi
 jz .invalid_sp
 test rsi,rsi
 jz .invalid_sp
 cmp qword [rdi+56],1
 jne .invalid_sp
 cmp qword [rdi+40],0
 jne .invalid_sp
 mov r8,[rdi+8]
 cmp r8,[rdi+24]
 jae .limit
 cmp r8,[rdi+16]
 jae .limit
 imul r8,NEBOC_DIAGNOSTIC_SIZE
 add r8,[rdi]
 push rbx
 mov rbx,rdi
 mov rdi,r8
 mov rcx,NEBOC_DIAGNOSTIC_QWORDS
 rep movsq
 mov rax,[rbx+32]
 mov [r8],rax
 mov [r8+176],rax
 inc qword [rbx+32]
 inc qword [rbx+8]
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.limit:
 inc qword [rdi+48]
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.invalid_sp: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; compare diagnostic at rdi with rsi: CF-like result in eax (1 if left > right)
compare_entries:
 mov rax,[rdi+32]
 cmp rax,[rsi+32]
 ja .greater
 jb .not_greater
 mov rax,[rdi+40]
 cmp rax,[rsi+40]
 ja .greater
 jb .not_greater
 mov rax,[rdi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 cmp rax,[rsi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 ja .greater
 jb .not_greater
 mov r8,[rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov r9,[rsi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 test r8,r8
 jz .left_legacy_code
 test r9,r9
 jz .greater
 mov rax,[rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov rdx,[rsi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov rcx,rax
 cmp rcx,rdx
 cmova rcx,rdx
 xor r10d,r10d
.compare_public_code:
 cmp r10,rcx
 jae .compare_public_length
 mov al,[r8+r10]
 cmp al,[r9+r10]
 ja .greater
 jb .not_greater
 inc r10
 jmp .compare_public_code
.compare_public_length:
 mov rax,[rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 cmp rax,[rsi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 ja .greater
 jb .not_greater
 jmp .compare_ordinal
.left_legacy_code:
 test r9,r9
 jnz .not_greater
 mov rax,[rdi+8]
 cmp rax,[rsi+8]
 ja .greater
 jb .not_greater
.compare_ordinal:
 mov rax,[rdi+176]
 cmp rax,[rsi+176]
 ja .greater
.not_greater: xor eax,eax
ret
.greater: mov eax,1
ret

swap_entries:
 push rcx
 xor ecx,ecx
.swap_loop:
 cmp ecx,NEBOC_DIAGNOSTIC_QWORDS
 jae .swap_done
 mov rax,[rdi+rcx*8]
 mov rdx,[rsi+rcx*8]
 mov [rdi+rcx*8],rdx
 mov [rsi+rcx*8],rax
 inc ecx
 jmp .swap_loop
.swap_done: pop rcx
ret

; store_finalize(store*)
NEBOC_ABI_FUNCTION neboc_diagnostic_store_finalize
 test rdi,rdi
 jz .invalid_sf
 cmp qword [rdi+56],1
 jne .invalid_sf
 cmp qword [rdi+40],0
 jne .done_sf
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,[rbx+8]
 xor r13d,r13d
.outer:
 cmp r13,r12
 jae .sorted
 xor r14d,r14d
 mov r15,r12
 sub r15,r13
 dec r15
.inner:
 cmp r14,r15
 jae .next_outer
 mov rdi,r14
 imul rdi,NEBOC_DIAGNOSTIC_SIZE
 add rdi,[rbx]
 lea rsi,[rdi+NEBOC_DIAGNOSTIC_SIZE]
 push rdi
 push rsi
 call compare_entries
 pop rsi
 pop rdi
 test eax,eax
 jz .no_swap
 call swap_entries
.no_swap:
 inc r14
 jmp .inner
.next_outer:
 inc r13
 jmp .outer
.sorted:
 mov qword [rbx+40],1
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
.done_sf: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_sf: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; diagnostic_new(diag*, DiagnosticNewRequest*)
; Construction validates every borrowed slice before clearing the destination.
NEBOC_ABI_FUNCTION neboc_diagnostic_new
 test rdi,rdi
 jz .new_invalid
 test rsi,rsi
 jz .new_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov rdi,[r12+NEBOC_DIAGNOSTIC_NEW_CODE_OFFSET]
 mov rsi,[r12+NEBOC_DIAGNOSTIC_NEW_CODE_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_diagnostic_code_registry_lookup
 test eax,eax
 jne .new_finish
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_SEVERITY_OFFSET]
 cmp rax,[rsp+NEBOC_DIAGNOSTIC_CODE_ENTRY_SEVERITY_OFFSET]
 jne .new_invalid_local
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_CATEGORY_OFFSET]
 cmp rax,[rsp+NEBOC_DIAGNOSTIC_CODE_ENTRY_CATEGORY_OFFSET]
 jne .new_invalid_local
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_PHASE_OFFSET]
 cmp rax,[rsp+NEBOC_DIAGNOSTIC_CODE_ENTRY_PHASE_OFFSET]
 jne .new_invalid_local
 mov r13,[r12+NEBOC_DIAGNOSTIC_NEW_MESSAGE_KEY_LENGTH_OFFSET]
 cmp r13,[rsp+NEBOC_DIAGNOSTIC_CODE_ENTRY_MESSAGE_KEY_LENGTH_OFFSET]
 jne .new_invalid_local
 mov r14,[r12+NEBOC_DIAGNOSTIC_NEW_MESSAGE_KEY_OFFSET]
 test r14,r14
 jz .new_invalid_local
 mov r15,[rsp+NEBOC_DIAGNOSTIC_CODE_ENTRY_MESSAGE_KEY_OFFSET]
 xor ecx,ecx
.new_key_compare:
 cmp rcx,r13
 jae .new_key_ok
 mov al,[r14+rcx]
 cmp al,[r15+rcx]
 jne .new_invalid_local
 inc rcx
 jmp .new_key_compare
.new_key_ok:
 mov r15,[r12+NEBOC_DIAGNOSTIC_NEW_PRIMARY_SPAN_OFFSET]
 test r15,r15
 jnz .new_span_check
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_CATEGORY_OFFSET]
 cmp rax,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 je .new_args_check
 cmp rax,NEBOC_DIAGNOSTIC_CATEGORY_ENVIRONMENT
 je .new_args_check
 cmp rax,NEBOC_DIAGNOSTIC_CATEGORY_INTERNAL
 je .new_args_check
 jmp .new_invalid_local
.new_span_check:
 cmp qword [r15+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],0
 je .new_invalid_local
 mov rax,[r15+NEBOC_SOURCE_SPAN_START_OFFSET]
 cmp rax,[r15+NEBOC_SOURCE_SPAN_END_OFFSET]
 ja .new_invalid_local
 mov rax,[r15+NEBOC_SOURCE_SPAN_END_OFFSET]
 cmp rax,[r15+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET]
 ja .new_invalid_local
.new_args_check:
 mov r13,[r12+NEBOC_DIAGNOSTIC_NEW_ARGUMENT_COUNT_OFFSET]
 cmp r13,NEBOC_DIAGNOSTIC_MAX_ARGUMENTS
 ja .new_limit
 test r13,r13
 jz .new_commit
 mov r14,[r12+NEBOC_DIAGNOSTIC_NEW_ARGUMENTS_OFFSET]
 test r14,r14
 jz .new_invalid_local
 xor r15d,r15d
.new_validate_arg:
 cmp r15,r13
 jae .new_commit
 mov rax,r15
 imul rax,NEBOC_DIAGNOSTIC_ARGUMENT_SIZE
 add rax,r14
 mov rdx,[rax+NEBOC_DIAGNOSTIC_ARGUMENT_TYPE_OFFSET]
 test rdx,rdx
 jz .new_invalid_local
 cmp rdx,NEBOC_DIAGNOSTIC_ARGUMENT_SIGNED
 ja .new_invalid_local
 cmp rdx,NEBOC_DIAGNOSTIC_ARGUMENT_TEXT
 jne .new_arg_next
 cmp qword [rax+NEBOC_DIAGNOSTIC_ARGUMENT_LENGTH_OFFSET],NEBOC_DIAGNOSTIC_MAX_TEXT_BYTES
 ja .new_limit
 cmp qword [rax+NEBOC_DIAGNOSTIC_ARGUMENT_LENGTH_OFFSET],0
 je .new_arg_next
 cmp qword [rax+NEBOC_DIAGNOSTIC_ARGUMENT_DATA_OFFSET],0
 je .new_invalid_local
.new_arg_next:
 inc r15
 jmp .new_validate_arg
.new_commit:
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_DIAGNOSTIC_QWORDS
 rep stosq
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_CODE_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],rax
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_CODE_LENGTH_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_SEVERITY_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],rax
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_CATEGORY_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],rax
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_PHASE_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET],rax
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_MESSAGE_KEY_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET],rax
 mov rax,[r12+NEBOC_DIAGNOSTIC_NEW_MESSAGE_KEY_LENGTH_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET],rax
 mov qword [rbx+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 mov r15,[r12+NEBOC_DIAGNOSTIC_NEW_PRIMARY_SPAN_OFFSET]
 test r15,r15
 jz .new_copy_args
 mov rdi,rbx
 add rdi,NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET
 mov rsi,r15
 mov ecx,NEBOC_SOURCE_SPAN_QWORDS
 rep movsq
 mov qword [rbx+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
.new_copy_args:
 mov r13,[r12+NEBOC_DIAGNOSTIC_NEW_ARGUMENT_COUNT_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_ARGUMENT_COUNT_OFFSET],r13
 test r13,r13
 jz .new_exit_map
 mov rsi,[r12+NEBOC_DIAGNOSTIC_NEW_ARGUMENTS_OFFSET]
 lea rdi,[rbx+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET]
 mov rcx,r13
 shl rcx,2
 rep movsq
.new_exit_map:
 mov qword [rbx+NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET],NEBOC_DIAGNOSTIC_EXIT_SUCCESS
 mov rax,[rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 cmp rax,NEBOC_DIAGNOSTIC_SEVERITY_BUG
 je .new_exit_internal
 cmp rax,NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 jne .new_ok
 cmp qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_ENVIRONMENT
 je .new_exit_environment
 mov qword [rbx+NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET],NEBOC_DIAGNOSTIC_EXIT_USER_ERROR
 jmp .new_ok
.new_exit_environment:
 mov qword [rbx+NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET],NEBOC_DIAGNOSTIC_EXIT_ENVIRONMENT_ERROR
 jmp .new_ok
.new_exit_internal:
 mov qword [rbx+NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET],NEBOC_DIAGNOSTIC_EXIT_INTERNAL_ERROR
.new_ok:
 xor eax,eax
 jmp .new_finish
.new_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .new_finish
.new_invalid_local:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.new_finish:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.new_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; diagnostic_code(diag*, out_slice*)
NEBOC_ABI_FUNCTION neboc_diagnostic_code
 test rdi,rdi
 jz .code_invalid
 test rsi,rsi
 jz .code_invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .code_invalid
 mov rax,[rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 test rax,rax
 jz .code_invalid
 mov [rsi+NEBOC_DIAGNOSTIC_SLICE_POINTER_OFFSET],rax
 mov rax,[rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov [rsi+NEBOC_DIAGNOSTIC_SLICE_LENGTH_OFFSET],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.code_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%macro DIAGNOSTIC_SCALAR_ACCESSOR 2
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne %%invalid
 mov rax,[rdi+%2]
 mov [rsi],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
%%invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%endmacro

DIAGNOSTIC_SCALAR_ACCESSOR neboc_diagnostic_severity, NEBOC_DIAGNOSTIC_SEVERITY_OFFSET
DIAGNOSTIC_SCALAR_ACCESSOR neboc_diagnostic_category, NEBOC_DIAGNOSTIC_CATEGORY_OFFSET
DIAGNOSTIC_SCALAR_ACCESSOR neboc_diagnostic_phase, NEBOC_DIAGNOSTIC_PHASE_OFFSET
DIAGNOSTIC_SCALAR_ACCESSOR neboc_diagnostic_schema_version, NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET
DIAGNOSTIC_SCALAR_ACCESSOR neboc_diagnostic_exit_code, NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET

; diagnostic_primary_span(diag*, out_span*)
NEBOC_ABI_FUNCTION neboc_diagnostic_primary_span
 test rdi,rdi
 jz .primary_invalid
 test rsi,rsi
 jz .primary_invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .primary_invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 jne .primary_invalid
 add rdi,NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET
 mov rcx,NEBOC_SOURCE_SPAN_QWORDS
 xchg rdi,rsi
 rep movsq
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.primary_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; diagnostic_arguments(diag*, out_slice*) where length is argument count.
NEBOC_ABI_FUNCTION neboc_diagnostic_arguments
 test rdi,rdi
 jz .arguments_invalid
 test rsi,rsi
 jz .arguments_invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .arguments_invalid
 lea rax,[rdi+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET]
 mov [rsi+NEBOC_DIAGNOSTIC_SLICE_POINTER_OFFSET],rax
 mov rax,[rdi+NEBOC_DIAGNOSTIC_ARGUMENT_COUNT_OFFSET]
 mov [rsi+NEBOC_DIAGNOSTIC_SLICE_LENGTH_OFFSET],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.arguments_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; diagnostic_add_label(diag*, span*, text*, text_len, role)
NEBOC_ABI_FUNCTION neboc_diagnostic_add_label
 test rdi,rdi
 jz .label_invalid
 test rsi,rsi
 jz .label_invalid
 test rcx,rcx
 jz .label_invalid
 cmp rcx,NEBOC_DIAGNOSTIC_MAX_TEXT_BYTES
 ja .label_limit
 test rdx,rdx
 jz .label_invalid
 cmp r8,NEBOC_DIAGNOSTIC_LABEL_ROLE_PRIMARY
 jb .label_invalid
 cmp r8,NEBOC_DIAGNOSTIC_LABEL_ROLE_SECONDARY
 ja .label_invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .label_invalid
 mov r9,[rsi+NEBOC_SOURCE_SPAN_START_OFFSET]
 cmp r9,[rsi+NEBOC_SOURCE_SPAN_END_OFFSET]
 ja .label_invalid
 mov r9,[rsi+NEBOC_SOURCE_SPAN_END_OFFSET]
 cmp r9,[rsi+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET]
 ja .label_invalid
 mov r9,[rdi+NEBOC_DIAGNOSTIC_LABEL_COUNT_OFFSET]
 cmp r9,NEBOC_DIAGNOSTIC_MAX_LABELS
 jae .label_limit
 imul r9,NEBOC_DIAGNOSTIC_LABEL_SIZE
 add r9,rdi
 add r9,NEBOC_DIAGNOSTIC_LABELS_OFFSET
 mov rax,[rsi]
 mov [r9],rax
 mov rax,[rsi+8]
 mov [r9+8],rax
 mov rax,[rsi+16]
 mov [r9+16],rax
 mov rax,[rsi+24]
 mov [r9+24],rax
 mov [r9+NEBOC_DIAGNOSTIC_LABEL_TEXT_OFFSET],rdx
 mov [r9+NEBOC_DIAGNOSTIC_LABEL_TEXT_LENGTH_OFFSET],rcx
 mov [r9+NEBOC_DIAGNOSTIC_LABEL_ROLE_OFFSET],r8
 inc qword [rdi+NEBOC_DIAGNOSTIC_LABEL_COUNT_OFFSET]
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.label_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.label_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%macro DIAGNOSTIC_ADD_TEXT 3
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 test rdx,rdx
 jz %%invalid
 cmp rdx,NEBOC_DIAGNOSTIC_MAX_TEXT_BYTES
 ja %%limit
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne %%invalid
 mov rcx,[rdi+%2]
 cmp rcx,NEBOC_DIAGNOSTIC_MAX_NOTES
 jae %%limit
 mov r8,rcx
 imul r8,NEBOC_DIAGNOSTIC_TEXT_ITEM_SIZE
 add r8,rdi
 add r8,%3
 mov [r8+NEBOC_DIAGNOSTIC_TEXT_POINTER_OFFSET],rsi
 mov [r8+NEBOC_DIAGNOSTIC_TEXT_LENGTH_OFFSET],rdx
 inc qword [rdi+%2]
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
%%limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
%%invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%endmacro

DIAGNOSTIC_ADD_TEXT neboc_diagnostic_add_note, NEBOC_DIAGNOSTIC_NOTE_COUNT_OFFSET, NEBOC_DIAGNOSTIC_NOTES_OFFSET
DIAGNOSTIC_ADD_TEXT neboc_diagnostic_add_help, NEBOC_DIAGNOSTIC_HELP_COUNT_OFFSET, NEBOC_DIAGNOSTIC_HELPS_OFFSET

; diagnostic_add_cause(diag*, cause*)
NEBOC_ABI_FUNCTION neboc_diagnostic_add_cause
 test rdi,rdi
 jz .cause_invalid
 test rsi,rsi
 jz .cause_invalid
 cmp rdi,rsi
 je .cause_invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .cause_invalid
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .cause_invalid
 mov rdx,[rsi+NEBOC_DIAGNOSTIC_CAUSE_DEPTH_OFFSET]
 inc rdx
 cmp rdx,NEBOC_DIAGNOSTIC_MAX_CAUSE_DEPTH
 ja .cause_limit
 mov rcx,[rdi+NEBOC_DIAGNOSTIC_CAUSE_COUNT_OFFSET]
 cmp rcx,NEBOC_DIAGNOSTIC_MAX_CAUSES
 jae .cause_limit
 mov r8,rcx
 imul r8,NEBOC_DIAGNOSTIC_CAUSE_SIZE
 add r8,rdi
 add r8,NEBOC_DIAGNOSTIC_CAUSES_OFFSET
 mov [r8+NEBOC_DIAGNOSTIC_CAUSE_POINTER_OFFSET],rsi
 mov [r8+NEBOC_DIAGNOSTIC_CAUSE_DEPTH_VALUE_OFFSET],rdx
 inc qword [rdi+NEBOC_DIAGNOSTIC_CAUSE_COUNT_OFFSET]
 cmp rdx,[rdi+NEBOC_DIAGNOSTIC_CAUSE_DEPTH_OFFSET]
 jbe .cause_ok
 mov [rdi+NEBOC_DIAGNOSTIC_CAUSE_DEPTH_OFFSET],rdx
.cause_ok: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.cause_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.cause_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
