; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F05 bounded diagnostic budgets, deduplication and cascade control.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/recovery.inc"

section .text

; byte_strings_compare(a*, a_len, b*, b_len) -> {-1,0,1}
byte_strings_compare:
 xor eax,eax
 xor r8d,r8d
 mov r9,rsi
 cmp r9,rcx
 cmova r9,rcx
.loop:
 cmp r8,r9
 jae .length
 mov al,[rdi+r8]
 cmp al,[rdx+r8]
 jb .less
 ja .greater
 inc r8
 jmp .loop
.length:
 cmp rsi,rcx
 jb .less
 ja .greater
 xor eax,eax
 ret
.less:
 mov eax,-1
 ret
.greater:
 mov eax,1
 ret

; DiagnosticBag.new(bag*, entries*, capacity, max_count, max_bytes)
NEBOC_ABI_FUNCTION neboc_diagnostic_bag_new
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp rdx,NEBOC_DIAG_BAG_HARD_MAX
 ja .limit
 cmp rcx,rdx
 ja .invalid
 cmp r8,NEBOC_DIAG_BAG_HARD_MAX_BYTES
 ja .limit
 push rdi
 push rsi
 push rdx
 push rcx
 push r8
 mov rcx,rdx
 imul rcx,NEBOC_RECOVERY_DIAG_ENTRY_SIZE/8
 mov rdi,rsi
 xor eax,eax
 rep stosq
 pop r8
 pop rcx
 pop rdx
 pop rsi
 pop rdi
 mov [rdi+NEBOC_DIAG_BAG_ENTRIES_OFFSET],rsi
 mov [rdi+NEBOC_DIAG_BAG_CAPACITY_OFFSET],rdx
 mov [rdi+NEBOC_DIAG_BAG_MAX_COUNT_OFFSET],rcx
 mov [rdi+NEBOC_DIAG_BAG_MAX_BYTES_OFFSET],r8
 mov qword [rdi+NEBOC_DIAG_BAG_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; diagnosticBag.add(bag*, diagnostic*, payload_bytes, out_id*)
NEBOC_ABI_FUNCTION neboc_diagnostic_bag_add
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp qword [rdi+NEBOC_DIAG_BAG_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .invalid
 cmp qword [rsi+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 jne .invalid
 mov r8,[rdi+NEBOC_DIAG_BAG_COUNT_OFFSET]
 cmp r8,[rdi+NEBOC_DIAG_BAG_CAPACITY_OFFSET]
 jae .limit
 cmp r8,[rdi+NEBOC_DIAG_BAG_MAX_COUNT_OFFSET]
 jae .limit
 mov r9,[rdi+NEBOC_DIAG_BAG_USED_BYTES_OFFSET]
 mov r10,r9
 add r10,rdx
 jc .limit
 cmp r10,[rdi+NEBOC_DIAG_BAG_MAX_BYTES_OFFSET]
 ja .limit
 mov r11,r8
 imul r11,NEBOC_RECOVERY_DIAG_ENTRY_SIZE
 add r11,[rdi+NEBOC_DIAG_BAG_ENTRIES_OFFSET]
 mov [r11+NEBOC_DIAG_ENTRY_DIAGNOSTIC_OFFSET],rsi
 lea rax,[r8+1]
 mov [r11+NEBOC_DIAG_ENTRY_ID_OFFSET],rax
 mov [r11+NEBOC_DIAG_ENTRY_PAYLOAD_BYTES_OFFSET],rdx
 mov [r11+NEBOC_DIAG_ENTRY_INSERTION_OFFSET],r8
 mov [rcx],rax
 inc r8
 mov [rdi+NEBOC_DIAG_BAG_COUNT_OFFSET],r8
 mov [rdi+NEBOC_DIAG_BAG_USED_BYTES_OFFSET],r10
 inc qword [rdi+NEBOC_DIAG_BAG_VISIBLE_COUNT_OFFSET]
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; structural_equal(diag_a*, diag_b*) -> 1/0
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
diagnostic_structural_equal:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 mov rdi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov rdx,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rcx,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call byte_strings_compare
 test eax,eax
 jne .no
 mov rax,[rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 cmp rax,[r12+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 jne .no
 mov rax,[rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET]
 cmp rax,[r12+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET]
 jne .no
 mov rax,[rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET]
 cmp rax,[r12+NEBOC_DIAGNOSTIC_PHASE_OFFSET]
 jne .no
 %assign off 0
 %rep 3
 mov rax,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+off]
 cmp rax,[r12+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+off]
 jne .no
 %assign off off+8
 %endrep
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

; diagnosticBag.deduplicate(bag*, structural_policy, out_suppressed*)
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_diagnostic_bag_deduplicate
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBOC_DIAG_DEDUP_STRUCTURAL
 jne .invalid
 cmp qword [rdi+NEBOC_DIAG_BAG_ACTIVE_OFFSET],1
 jne .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov [rsp],rdx
 xor r12d,r12d
 xor r13d,r13d
.outer:
 cmp r12,[rbx+NEBOC_DIAG_BAG_COUNT_OFFSET]
 jae .finish
 mov r14,r12
 imul r14,NEBOC_RECOVERY_DIAG_ENTRY_SIZE
 add r14,[rbx+NEBOC_DIAG_BAG_ENTRIES_OFFSET]
 test qword [r14+NEBOC_DIAG_ENTRY_FLAGS_OFFSET],NEBOC_DIAG_ENTRY_DUPLICATE|NEBOC_DIAG_ENTRY_CASCADE
 jnz .outer_next
 lea r15,[r12+1]
.inner:
 cmp r15,[rbx+NEBOC_DIAG_BAG_COUNT_OFFSET]
 jae .outer_next
 mov r10,r15
 imul r10,NEBOC_RECOVERY_DIAG_ENTRY_SIZE
 add r10,[rbx+NEBOC_DIAG_BAG_ENTRIES_OFFSET]
 test qword [r10+NEBOC_DIAG_ENTRY_FLAGS_OFFSET],NEBOC_DIAG_ENTRY_DUPLICATE|NEBOC_DIAG_ENTRY_CASCADE
 jnz .inner_next
 mov rdi,[r14+NEBOC_DIAG_ENTRY_DIAGNOSTIC_OFFSET]
 mov rsi,[r10+NEBOC_DIAG_ENTRY_DIAGNOSTIC_OFFSET]
 push r10
 call diagnostic_structural_equal
 pop r10
 test eax,eax
 jz .inner_next
 or qword [r10+NEBOC_DIAG_ENTRY_FLAGS_OFFSET],NEBOC_DIAG_ENTRY_DUPLICATE
 dec qword [rbx+NEBOC_DIAG_BAG_VISIBLE_COUNT_OFFSET]
 inc r13
.inner_next:
 inc r15
 jmp .inner
.outer_next:
 inc r12
 jmp .outer
.finish:
 mov rax,[rsp]
 mov [rax],r13
 xor eax,eax
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; diagnosticBag.suppressCascade(bag*, root_id, derived_ids*, count)
; The validation pass is complete before any entry is changed.
%undef call
NEBOC_ABI_FUNCTION neboc_diagnostic_bag_suppress_cascade
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp qword [rdi+NEBOC_DIAG_BAG_ACTIVE_OFFSET],1
 jne .invalid
 mov r8,[rdi+NEBOC_DIAG_BAG_COUNT_OFFSET]
 test rsi,rsi
 jz .invalid
 cmp rsi,r8
 ja .invalid
 cmp rcx,r8
 ja .invalid
 mov r9,rsi
 dec r9
 imul r9,NEBOC_RECOVERY_DIAG_ENTRY_SIZE
 add r9,[rdi+NEBOC_DIAG_BAG_ENTRIES_OFFSET]
 test qword [r9+NEBOC_DIAG_ENTRY_FLAGS_OFFSET],NEBOC_DIAG_ENTRY_DUPLICATE|NEBOC_DIAG_ENTRY_CASCADE
 jnz .invalid
 xor r10d,r10d
.validate:
 cmp r10,rcx
 jae .apply_start
 mov rax,[rdx+r10*8]
 test rax,rax
 jz .invalid
 cmp rax,r8
 ja .invalid
 cmp rax,rsi
 je .invalid
 inc r10
 jmp .validate
.apply_start:
 xor r10d,r10d
.apply:
 cmp r10,rcx
 jae .ok
 mov rax,[rdx+r10*8]
 dec rax
 imul rax,NEBOC_RECOVERY_DIAG_ENTRY_SIZE
 add rax,[rdi+NEBOC_DIAG_BAG_ENTRIES_OFFSET]
 test qword [rax+NEBOC_DIAG_ENTRY_FLAGS_OFFSET],NEBOC_DIAG_ENTRY_DUPLICATE|NEBOC_DIAG_ENTRY_CASCADE
 jnz .apply_next
 or qword [rax+NEBOC_DIAG_ENTRY_FLAGS_OFFSET],NEBOC_DIAG_ENTRY_CASCADE
 dec qword [rdi+NEBOC_DIAG_BAG_VISIBLE_COUNT_OFFSET]
.apply_next:
 inc r10
 jmp .apply
.ok:
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; compare_entry(entry_a*, entry_b*) -> {-1,0,1}
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
compare_entry:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 mov r8,[rbx+NEBOC_DIAG_ENTRY_DIAGNOSTIC_OFFSET]
 mov r9,[r12+NEBOC_DIAG_ENTRY_DIAGNOSTIC_OFFSET]
 mov rax,[r8+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 cmp rax,[r9+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 jb .less
 ja .greater
 mov rax,[r8+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 cmp rax,[r9+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 jb .less
 ja .greater
 mov rax,[r8+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 cmp rax,[r9+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 jb .less
 ja .greater
 mov rdi,[r8+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[r8+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov rdx,[r9+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rcx,[r9+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call byte_strings_compare
 test eax,eax
 jne .done
 mov rax,[rbx+NEBOC_DIAG_ENTRY_INSERTION_OFFSET]
 cmp rax,[r12+NEBOC_DIAG_ENTRY_INSERTION_OFFSET]
 jb .less
 ja .greater
 xor eax,eax
 jmp .done
.less:
 mov eax,-1
 jmp .done
.greater:
 mov eax,1
.done:
 pop r12
 pop rbx
 ret

; diagnosticBag.sortCanonical(bag*) -- stable bounded insertion sort.
%undef call
NEBOC_ABI_FUNCTION neboc_diagnostic_bag_sort_canonical
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_DIAG_BAG_ACTIVE_OFFSET],1
 jne .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,[rbx+NEBOC_DIAG_BAG_ENTRIES_OFFSET]
 mov r13,1
.outer:
 cmp r13,[rbx+NEBOC_DIAG_BAG_COUNT_OFFSET]
 jae .ok
 mov r14,r13
.inner:
 test r14,r14
 jz .next
 mov r15,r14
 imul r15,NEBOC_RECOVERY_DIAG_ENTRY_SIZE
 add r15,r12
 lea rdi,[r15-NEBOC_RECOVERY_DIAG_ENTRY_SIZE]
 mov rsi,r15
 call compare_entry
 cmp eax,0
 jle .next
 lea rsi,[r15-NEBOC_RECOVERY_DIAG_ENTRY_SIZE]
 mov rdi,rsp
 mov rcx,NEBOC_RECOVERY_DIAG_ENTRY_SIZE/8
 rep movsq
 mov rsi,r15
 lea rdi,[r15-NEBOC_RECOVERY_DIAG_ENTRY_SIZE]
 mov rcx,NEBOC_RECOVERY_DIAG_ENTRY_SIZE/8
 rep movsq
 mov rsi,rsp
 mov rdi,r15
 mov rcx,NEBOC_RECOVERY_DIAG_ENTRY_SIZE/8
 rep movsq
 dec r14
 jmp .inner
.next:
 inc r13
 jmp .outer
.ok:
 xor eax,eax
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
