; GLOBAL-DCE-F02 bounded section planner and explainable global DCE model.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/optimizer/global_dce.inc"
section .text
; rdi=sections rsi=count rdx=kind rcx=out r8=cap r9=count.
section_filter:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r9,r9
 jz .invalid
 xor r10d,r10d
 xor r11d,r11d
.loop:
 cmp r10,rsi
 jae .done
 cmp [rdi+NEBOC_DCE_SECTION_KIND_OFFSET],rdx
 jne .next
 cmp r11,r8
 jae .limit
 mov rax,[rdi+NEBOC_DCE_SECTION_ID_OFFSET]
 mov [rcx+r11*8],rax
 inc r11
.next: add rdi,NEBOC_DCE_SECTION_SIZE
 inc r10
 jmp .loop
.done: mov [r9],r11
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_section_planner_function_sections
 mov edx,NEBOC_DCE_SECTION_FUNCTION
 jmp section_filter
NEBOC_ABI_FUNCTION neboc_section_planner_data_sections
 mov edx,NEBOC_DCE_SECTION_DATA
 jmp section_filter
NEBOC_ABI_FUNCTION neboc_section_planner_comdat_group
 ; rdi=identity rsi=version rdx=out stable group id.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,rdi
 rol rax,23
 xor rax,rsi
 mov rcx,0x434f4d444154
 xor rax,rcx
 mov [rdx],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Recompute counters after any pruning mutation.
dce_recount:
 mov qword [rdi+NEBOC_DCE_CONTEXT_RETAINED_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_DCE_CONTEXT_PRUNED_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_DCE_CONTEXT_RETAINED_BYTES_OFFSET],0
 mov qword [rdi+NEBOC_DCE_CONTEXT_PRUNED_BYTES_OFFSET],0
 mov rax,[rdi+NEBOC_DCE_CONTEXT_SECTIONS_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+NEBOC_DCE_CONTEXT_COUNT_OFFSET]
 jae .done
 cmp qword [rax+NEBOC_DCE_SECTION_RETAINED_OFFSET],1
 jne .pruned
 inc qword [rdi+NEBOC_DCE_CONTEXT_RETAINED_COUNT_OFFSET]
 mov rdx,[rax+NEBOC_DCE_SECTION_BYTES_OFFSET]
 add [rdi+NEBOC_DCE_CONTEXT_RETAINED_BYTES_OFFSET],rdx
 jmp .next
.pruned:
 inc qword [rdi+NEBOC_DCE_CONTEXT_PRUNED_COUNT_OFFSET]
 mov rdx,[rax+NEBOC_DCE_SECTION_BYTES_OFFSET]
 add [rdi+NEBOC_DCE_CONTEXT_PRUNED_BYTES_OFFSET],rdx
.next: add rax,NEBOC_DCE_SECTION_SIZE
 inc rcx
 jmp .loop
.done: ret

NEBOC_ABI_FUNCTION neboc_global_dce_run
 ; rdi=context with caller-owned sections/relocations and public ABI policy.
 test rdi,rdi
 jz .invalid
 mov r8,[rdi+NEBOC_DCE_CONTEXT_SECTIONS_OFFSET]
 test r8,r8
 jz .invalid
 mov r9,[rdi+NEBOC_DCE_CONTEXT_COUNT_OFFSET]
 test r9,r9
 jz .invalid
 cmp r9,NEBOC_DCE_MAX_SECTIONS
 ja .limit
 cmp qword [rdi+NEBOC_DCE_CONTEXT_RELOC_COUNT_OFFSET],NEBOC_DCE_MAX_RELOCS
 ja .limit
 xor ecx,ecx
.loop:
 cmp rcx,r9
 jae .done
 cmp qword [r8+NEBOC_DCE_SECTION_ID_OFFSET],0
 je .invalid
 mov qword [r8+NEBOC_DCE_SECTION_RETAINED_OFFSET],0
 cmp qword [r8+NEBOC_DCE_SECTION_REACHABLE_OFFSET],1
 je .retain
 cmp qword [r8+NEBOC_DCE_SECTION_KEEP_REASON_OFFSET],0
 jne .retain
 cmp qword [r8+NEBOC_DCE_SECTION_EXPORT_OFFSET],1
 jne .required
 cmp qword [rdi+NEBOC_DCE_CONTEXT_PUBLIC_ABI_OFFSET],1
 je .retain
.required:
 cmp qword [r8+NEBOC_DCE_SECTION_REQUIRED_OFFSET],1
 je .retain
 cmp qword [r8+NEBOC_DCE_SECTION_METADATA_REQUIRED_OFFSET],1
 jne .next
.retain: mov qword [r8+NEBOC_DCE_SECTION_RETAINED_OFFSET],1
.next: add r8,NEBOC_DCE_SECTION_SIZE
 inc rcx
 jmp .loop
.done:
 mov qword [rdi+NEBOC_DCE_CONTEXT_ACTIVE_OFFSET],1
 sub rsp,8
 call dce_recount
 add rsp,8
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_global_dce_prune_unused_exports
 ; rdi=context rsi=private-artifact policy flag.
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jne .invalid
 cmp qword [rdi+NEBOC_DCE_CONTEXT_PUBLIC_ABI_OFFSET],1
 je .invalid_source
 mov r8,[rdi+NEBOC_DCE_CONTEXT_SECTIONS_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+NEBOC_DCE_CONTEXT_COUNT_OFFSET]
 jae .done
 cmp qword [r8+NEBOC_DCE_SECTION_EXPORT_OFFSET],1
 jne .next
 cmp qword [r8+NEBOC_DCE_SECTION_REACHABLE_OFFSET],0
 jne .next
 cmp qword [r8+NEBOC_DCE_SECTION_KEEP_REASON_OFFSET],0
 jne .next
 mov qword [r8+NEBOC_DCE_SECTION_RETAINED_OFFSET],0
.next: add r8,NEBOC_DCE_SECTION_SIZE
 inc rcx
 jmp .loop
.done: sub rsp,8
 call dce_recount
 add rsp,8
 xor eax,eax
 ret
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_global_dce_prune_unused_diagnostics
 ; rdi=context rsi=minimal profile flag. Required diagnostics remain.
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jne .invalid
 mov r8,[rdi+NEBOC_DCE_CONTEXT_SECTIONS_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+NEBOC_DCE_CONTEXT_COUNT_OFFSET]
 jae .done
 cmp qword [r8+NEBOC_DCE_SECTION_KIND_OFFSET],NEBOC_DCE_SECTION_DIAGNOSTIC
 jne .next
 cmp qword [r8+NEBOC_DCE_SECTION_REACHABLE_OFFSET],0
 jne .next
 cmp qword [r8+NEBOC_DCE_SECTION_REQUIRED_OFFSET],0
 jne .next
 mov qword [r8+NEBOC_DCE_SECTION_RETAINED_OFFSET],0
.next: add r8,NEBOC_DCE_SECTION_SIZE
 inc rcx
 jmp .loop
.done: sub rsp,8
 call dce_recount
 add rsp,8
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_global_dce_prune_unused_type_metadata
 ; Same bounded rule for optional metadata.
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jne .invalid
 mov r8,[rdi+NEBOC_DCE_CONTEXT_SECTIONS_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+NEBOC_DCE_CONTEXT_COUNT_OFFSET]
 jae .done
 cmp qword [r8+NEBOC_DCE_SECTION_KIND_OFFSET],NEBOC_DCE_SECTION_METADATA
 jne .next
 cmp qword [r8+NEBOC_DCE_SECTION_REACHABLE_OFFSET],0
 jne .next
 cmp qword [r8+NEBOC_DCE_SECTION_METADATA_REQUIRED_OFFSET],0
 jne .next
 mov qword [r8+NEBOC_DCE_SECTION_RETAINED_OFFSET],0
.next: add r8,NEBOC_DCE_SECTION_SIZE
 inc rcx
 jmp .loop
.done: sub rsp,8
 call dce_recount
 add rsp,8
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_global_dce_report
 ; rdi=context rsi=report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_DCE_CONTEXT_RETAINED_COUNT_OFFSET]
 mov [rsi+NEBOC_DCE_REPORT_RETAINED_OFFSET],rax
 mov rax,[rdi+NEBOC_DCE_CONTEXT_PRUNED_COUNT_OFFSET]
 mov [rsi+NEBOC_DCE_REPORT_PRUNED_OFFSET],rax
 mov rax,[rdi+NEBOC_DCE_CONTEXT_RETAINED_BYTES_OFFSET]
 mov [rsi+NEBOC_DCE_REPORT_RETAINED_BYTES_OFFSET],rax
 mov rax,[rdi+NEBOC_DCE_CONTEXT_PRUNED_BYTES_OFFSET]
 mov [rsi+NEBOC_DCE_REPORT_PRUNED_BYTES_OFFSET],rax
 mov rax,[rdi+NEBOC_DCE_CONTEXT_RELOC_COUNT_OFFSET]
 mov [rsi+NEBOC_DCE_REPORT_RELOCS_OFFSET],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; rdi=context rsi=id -> rax=section.
dce_find:
 mov rax,[rdi+NEBOC_DCE_CONTEXT_SECTIONS_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+NEBOC_DCE_CONTEXT_COUNT_OFFSET]
 jae .missing
 cmp [rax],rsi
 je .done
 add rax,NEBOC_DCE_SECTION_SIZE
 inc rcx
 jmp .loop
.missing: xor eax,eax
.done: ret

NEBOC_ABI_FUNCTION neboc_section_verify_relocations
 ; Retained sources may only reference retained targets.
 test rdi,rdi
 jz .invalid0
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,[rbx+NEBOC_DCE_CONTEXT_RELOCS_OFFSET]
 xor r13d,r13d
.loop:
 cmp r13,[rbx+NEBOC_DCE_CONTEXT_RELOC_COUNT_OFFSET]
 jae .ok
 mov rdi,rbx
 mov rsi,[r12+NEBOC_DCE_RELOC_FROM_OFFSET]
 call dce_find
 test rax,rax
 jz .invalid
 cmp qword [rax+NEBOC_DCE_SECTION_RETAINED_OFFSET],1
 jne .next
 mov rdi,rbx
 mov rsi,[r12+NEBOC_DCE_RELOC_TO_OFFSET]
 call dce_find
 test rax,rax
 jz .invalid_source
 cmp qword [rax+NEBOC_DCE_SECTION_RETAINED_OFFSET],1
 jne .invalid_source
.next: add r12,NEBOC_DCE_RELOC_SIZE
 inc r13
 jmp .loop
.ok: pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.invalid_source: pop r13
 pop r12
 pop rbx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: pop r13
 pop r12
 pop rbx
.invalid0: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_section_keep
 ; rdi=context rsi=id rdx=reason.
 test rdx,rdx
 jz .invalid
 call dce_find
 test rax,rax
 jz .invalid_source
 mov [rax+NEBOC_DCE_SECTION_KEEP_REASON_OFFSET],rdx
 mov qword [rax+NEBOC_DCE_SECTION_RETAINED_OFFSET],1
 xor eax,eax
 ret
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_build_gc_sections
 ; rdi=context rsi=off/on.
 cmp rsi,NEBOC_DCE_GC_ON
 je .on
 cmp rsi,NEBOC_DCE_GC_OFF
 jne .invalid
 mov r8,[rdi+NEBOC_DCE_CONTEXT_SECTIONS_OFFSET]
 xor ecx,ecx
.all:
 cmp rcx,[rdi+NEBOC_DCE_CONTEXT_COUNT_OFFSET]
 jae .done
 mov qword [r8+NEBOC_DCE_SECTION_RETAINED_OFFSET],1
 add r8,NEBOC_DCE_SECTION_SIZE
 inc rcx
 jmp .all
.done: sub rsp,8
 call dce_recount
 add rsp,8
 xor eax,eax
 ret
.on: jmp neboc_global_dce_run
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
