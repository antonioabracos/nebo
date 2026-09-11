; IDENTIDADE-DE-MODULOS-SOURCE-UNITS-ROOTS-E-MODULE-GRAPH-DETERMINISTICO-F03 deterministic multi-file source-unit ordering.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/modules.inc"

section .text

; source_units_sort(records*, count, out_indices*, capacity) -> status
; Records are (ModuleId digest, SourceUnitId, revision). The permutation is
; lexicographic by those stable fields and independent of filesystem order.
NEBOC_ABI_FUNCTION neboc_source_units_sort
 test rdi,rdi
 jz .invalid_argument
 test rdi,7
 jnz .invalid_argument
 test rdx,rdx
 jz .invalid_argument
 test rdx,7
 jnz .invalid_argument
 test rsi,rsi
 jz .invalid_source
 cmp rsi,NEBOC_MODULE_MAX_NODES
 ja .limit
 cmp rcx,rsi
 jb .limit
 mov rax,rsi
 imul rax,NEBOC_SOURCE_UNIT_SIZE
 jo .invalid_argument
 mov r8,rdi
 add r8,rax
 jc .invalid_argument
 mov r9,rsi
 shl r9,3
 mov r10,rdx
 add r10,r9
 jc .invalid_argument
 cmp rdi,r10
 jae .ranges_ok
 cmp rdx,r8
 jb .invalid_argument
.ranges_ok:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 ; Validate all identities/revisions and reject duplicate unit identity.
 xor ebx,ebx
.validate_outer:
 cmp rbx,r13
 jae .emit
 mov rax,rbx
 imul rax,NEBOC_SOURCE_UNIT_SIZE
 cmp qword [r12+rax+NEBOC_SOURCE_UNIT_MODULE_ID],0
 je .bad_source
 cmp qword [r12+rax+NEBOC_SOURCE_UNIT_ID],0
 je .bad_source
 cmp qword [r12+rax+NEBOC_SOURCE_UNIT_REVISION],0
 je .bad_source
 lea rbp,[rbx+1]
.validate_inner:
 cmp rbp,r13
 jae .validate_next
 mov rcx,rbp
 imul rcx,NEBOC_SOURCE_UNIT_SIZE
 mov rdx,[r12+rax+NEBOC_SOURCE_UNIT_ID]
 cmp rdx,[r12+rcx+NEBOC_SOURCE_UNIT_ID]
 je .bad_source
.inner_next:
 inc rbp
 jmp .validate_inner
.validate_next:
 inc rbx
 jmp .validate_outer

.emit:
 xor ebx,ebx
.position:
 cmp rbx,r13
 jae .ok
 mov r15,-1
 xor ebp,ebp
.candidate:
 cmp rbp,r13
 jae .publish_index
 ; Skip indices already present in the emitted prefix.
 xor ecx,ecx
.used_scan:
 cmp rcx,rbx
 jae .not_used
 cmp [r14+rcx*8],rbp
 je .candidate_next
 inc rcx
 jmp .used_scan
.not_used:
 cmp r15,-1
 je .choose
 mov rax,rbp
 imul rax,NEBOC_SOURCE_UNIT_SIZE
 mov rdx,r15
 imul rdx,NEBOC_SOURCE_UNIT_SIZE
 mov rcx,[r12+rax+NEBOC_SOURCE_UNIT_MODULE_ID]
 cmp rcx,[r12+rdx+NEBOC_SOURCE_UNIT_MODULE_ID]
 jb .choose
 ja .candidate_next
 mov rcx,[r12+rax+NEBOC_SOURCE_UNIT_ID]
 cmp rcx,[r12+rdx+NEBOC_SOURCE_UNIT_ID]
 jb .choose
 ja .candidate_next
 mov rcx,[r12+rax+NEBOC_SOURCE_UNIT_REVISION]
 cmp rcx,[r12+rdx+NEBOC_SOURCE_UNIT_REVISION]
 jae .candidate_next
.choose:
 mov r15,rbp
.candidate_next:
 inc rbp
 jmp .candidate
.publish_index:
 cmp r15,-1
 je .internal
 mov [r14+rbx*8],r15
 inc rbx
 jmp .position
.ok:
 xor eax,eax
 jmp .done
.bad_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.invalid_argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.invalid_source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

extern neboc_module_path_validate

; source_unit_discover(module_digest, logical_path*, length, revision, out*)
; hashes only canonical logical identity; host absolute paths never participate.
NEBOC_ABI_FUNCTION neboc_source_unit_discover
 test rdi,rdi
 jz .discover_source
 test rsi,rsi
 jz .discover_arg
 test r8,r8
 jz .discover_arg
 test r8,7
 jnz .discover_arg
 test rdx,rdx
 jz .discover_source
 test rcx,rcx
 jz .discover_source
 cmp rdx,NEBOC_MODULE_MAX_TEXT
 ja .discover_limit
 mov r9,rsi
 add r9,rdx
 jc .discover_arg
 mov r10,r8
 add r10,NEBOC_SOURCE_UNIT_SIZE
 jc .discover_arg
 cmp rsi,r10
 jae .discover_ranges_ok
 cmp r8,r9
 jb .discover_arg
.discover_ranges_ok:
 push rbx
 sub rsp,32
 mov rbx,r8
 mov [rsp],rdi
 mov [rsp+8],rcx
 mov rdi,rsi
 mov rsi,rdx
 lea rdx,[rsp+16]
 call neboc_module_path_validate
 test eax,eax
 jnz .discover_done
 mov rax,[rsp]
 mov [rbx+NEBOC_SOURCE_UNIT_MODULE_ID],rax
 mov rax,[rsp+16]
 mov [rbx+NEBOC_SOURCE_UNIT_ID],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_SOURCE_UNIT_REVISION],rax
 xor eax,eax
.discover_done:
 add rsp,32
 pop rbx
 ret
.discover_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.discover_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.discover_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; module_add_unit(records*, count, capacity, candidate*) -> status.
; A SourceUnitId is globally single-owner within the snapshot.
NEBOC_ABI_FUNCTION neboc_module_add_unit
 test rdi,rdi
 jz .add_arg
 test rcx,rcx
 jz .add_arg
 mov rax,rdi
 or rax,rcx
 test rax,7
 jnz .add_arg
 cmp rsi,rdx
 jae .add_limit
 cmp rdx,NEBOC_MODULE_MAX_NODES
 ja .add_limit
 mov rax,rdx
 imul rax,NEBOC_SOURCE_UNIT_SIZE
 jo .add_arg
 mov r8,rdi
 add r8,rax
 jc .add_arg
 mov r9,rcx
 add r9,NEBOC_SOURCE_UNIT_SIZE
 jc .add_arg
 cmp rdi,r9
 jae .add_ranges_ok
 cmp rcx,r8
 jb .add_arg
.add_ranges_ok:
 cmp qword [rcx+NEBOC_SOURCE_UNIT_MODULE_ID],0
 je .add_source
 cmp qword [rcx+NEBOC_SOURCE_UNIT_ID],0
 je .add_source
 cmp qword [rcx+NEBOC_SOURCE_UNIT_REVISION],0
 je .add_source
 xor r8d,r8d
.add_scan:
 cmp r8,rsi
 jae .add_publish
 mov rax,r8
 imul rax,NEBOC_SOURCE_UNIT_SIZE
 mov r9,[rdi+rax+NEBOC_SOURCE_UNIT_ID]
 cmp r9,[rcx+NEBOC_SOURCE_UNIT_ID]
 je .add_source
 inc r8
 jmp .add_scan
.add_publish:
 mov rax,rsi
 imul rax,NEBOC_SOURCE_UNIT_SIZE
 mov r8,[rcx]
 mov [rdi+rax],r8
 mov r8,[rcx+8]
 mov [rdi+rax+8],r8
 mov r8,[rcx+16]
 mov [rdi+rax+16],r8
 xor eax,eax
 ret
.add_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.add_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.add_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
