; SIZE-REPORT-F09 bounded binary size explainability and budgets.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/linker/size_report.inc"
section .text
NEBOC_ABI_FUNCTION neboc_size_report_from_artifact
 ; rdi=context rsi=entries rdx=count rcx=validated manifest token r8=stripped.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_SIZE_MAX_ENTRIES
 ja .limit
 test r8,r8
 jz .accept
 test rcx,rcx
 jz .source
.accept:
 mov [rdi+NEBOC_SIZE_CTX_ENTRIES_OFFSET],rsi
 mov [rdi+NEBOC_SIZE_CTX_COUNT_OFFSET],rdx
 mov [rdi+NEBOC_SIZE_CTX_MANIFEST_OFFSET],rcx
 mov [rdi+NEBOC_SIZE_CTX_STRIPPED_OFFSET],r8
 xor r9d,r9d
 xor eax,eax
 xor r10d,r10d
 xor r11d,r11d
.sum:
 cmp r9,rdx
 jae .done
 add rax,[rsi+NEBOC_SIZE_ENTRY_FILE_OFFSET]
 add r10,[rsi+NEBOC_SIZE_ENTRY_MEMORY_OFFSET]
 add r11,[rsi+NEBOC_SIZE_ENTRY_BSS_OFFSET]
 add rsi,NEBOC_SIZE_ENTRY_SIZE
 inc r9
 jmp .sum
.done:
 mov [rdi+NEBOC_SIZE_CTX_FILE_OFFSET],rax
 mov [rdi+NEBOC_SIZE_CTX_MEMORY_OFFSET],r10
 mov [rdi+NEBOC_SIZE_CTX_BSS_OFFSET],r11
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
; Group functions return total bytes and matching entry count for a key field.
%macro SIZE_GROUP 2
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 mov r8,[rdi+NEBOC_SIZE_CTX_ENTRIES_OFFSET]
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
%%loop:
 cmp r9,[rdi+NEBOC_SIZE_CTX_COUNT_OFFSET]
 jae %%done
 cmp qword [r8+%2],0
 je %%next
 add r10,[r8+NEBOC_SIZE_ENTRY_FILE_OFFSET]
 inc r11
%%next: add r8,NEBOC_SIZE_ENTRY_SIZE
 inc r9
 jmp %%loop
%%done: mov [rsi],r10
 mov [rsi+8],r11
 xor eax,eax
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
SIZE_GROUP neboc_size_report_by_section,NEBOC_SIZE_ENTRY_SECTION_OFFSET
SIZE_GROUP neboc_size_report_by_symbol,NEBOC_SIZE_ENTRY_SYMBOL_OFFSET
SIZE_GROUP neboc_size_report_by_component,NEBOC_SIZE_ENTRY_COMPONENT_OFFSET
SIZE_GROUP neboc_size_report_by_source,NEBOC_SIZE_ENTRY_SOURCE_OFFSET
NEBOC_ABI_FUNCTION neboc_size_report_why_linked
 ; rdi=context rsi=symbol/component token rdx=reason output.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov r8,[rdi+NEBOC_SIZE_CTX_ENTRIES_OFFSET]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+NEBOC_SIZE_CTX_COUNT_OFFSET]
 jae .absent
 cmp [r8+NEBOC_SIZE_ENTRY_SYMBOL_OFFSET],rsi
 je .found
 cmp [r8+NEBOC_SIZE_ENTRY_COMPONENT_OFFSET],rsi
 je .found
 add r8,NEBOC_SIZE_ENTRY_SIZE
 inc r9
 jmp .loop
.found: mov rax,[r8+NEBOC_SIZE_ENTRY_REASON_OFFSET]
 mov [rdx],rax
 xor eax,eax
 ret
.absent: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_size_report_compare
 ; rdi=current rsi=baseline rdx=3-qword file/memory/bss signed delta.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rdi+NEBOC_SIZE_CTX_FILE_OFFSET]
 sub rax,[rsi+NEBOC_SIZE_CTX_FILE_OFFSET]
 mov [rdx],rax
 mov rax,[rdi+NEBOC_SIZE_CTX_MEMORY_OFFSET]
 sub rax,[rsi+NEBOC_SIZE_CTX_MEMORY_OFFSET]
 mov [rdx+8],rax
 mov rax,[rdi+NEBOC_SIZE_CTX_BSS_OFFSET]
 sub rax,[rsi+NEBOC_SIZE_CTX_BSS_OFFSET]
 mov [rdx+16],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_binary_size_budget_new
 ; rdi=budget rsi=scope rdx=max rcx=delta r8=security proof.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test r8,r8
 jz .source
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 mov [rdi+24],r8
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_size_budget_evaluate
 ; rdi=budget rsi=report rdx=result: 1 pass,2 regression,3 inconclusive.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rsi+NEBOC_SIZE_CTX_COUNT_OFFSET],0
 je .inconclusive
 mov rax,[rsi+NEBOC_SIZE_CTX_FILE_OFFSET]
 cmp rax,[rdi+NEBOC_SIZE_BUDGET_MAX_OFFSET]
 ja .regression
 mov qword [rdx],1
 xor eax,eax
 ret
.regression: mov qword [rdx],2
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.inconclusive: mov qword [rdx],3
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_size_report_top
 ; rdi=context rsi=n rdx=entry output. Bounded oracle returns largest file entry.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,[rdi+NEBOC_SIZE_CTX_COUNT_OFFSET]
 ja .limit
 mov r8,[rdi+NEBOC_SIZE_CTX_ENTRIES_OFFSET]
 mov r9,[rdi+NEBOC_SIZE_CTX_COUNT_OFFSET]
 xor r10d,r10d
 xor r11d,r11d
.loop:
 test r9,r9
 jz .done
 mov rax,[r8+NEBOC_SIZE_ENTRY_FILE_OFFSET]
 cmp rax,r10
 jbe .next
 mov r10,rax
 mov r11,r8
.next: add r8,NEBOC_SIZE_ENTRY_SIZE
 dec r9
 jmp .loop
.done:
 mov [rdx],r11
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_size_report
 mov rax,[rdi+NEBOC_SIZE_CTX_FILE_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_SIZE_CTX_MEMORY_OFFSET]
 mov [rsi+8],rax
 mov rax,[rdi+NEBOC_SIZE_CTX_BSS_OFFSET]
 mov [rsi+16],rax
 xor eax,eax
 ret
NEBOC_ABI_FUNCTION neboc_cli_why_linked
 jmp neboc_size_report_why_linked
NEBOC_ABI_FUNCTION neboc_cli_binary_diff
 jmp neboc_size_report_compare
NEBOC_ABI_FUNCTION neboc_cli_size_gate
 jmp neboc_size_budget_evaluate
section .note.GNU-stack noalloc noexec nowrite progbits
