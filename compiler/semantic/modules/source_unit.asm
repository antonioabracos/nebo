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
 mov rdx,[r12+rax+NEBOC_SOURCE_UNIT_MODULE_ID]
 cmp rdx,[r12+rcx+NEBOC_SOURCE_UNIT_MODULE_ID]
 jne .inner_next
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
