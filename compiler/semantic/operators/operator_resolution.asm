; Exact-type operator candidate resolution. No conversions or fallback search.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

section .text
extern neboc_operator_known_implementations
extern neboc_operator_substitute_type

; resolve_exact(request*) copies exactly one admissible candidate to OUTPUT.
; On every failure OUTPUT and OUTPUT_INDEX/MATCH_COUNT remain unchanged; only
; the diagnostic field is written when the request itself is valid.
NEBOC_ABI_FUNCTION neboc_operator_resolve_exact
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov rax,[r12+NEBOC_OPERATOR_RESOLVE_PROTOCOL_OFFSET]
 test rax,rax
 jz .invalid_request
 cmp rax,NEBOC_OPERATOR_PROTOCOL_COUNT
 ja .invalid_request
 cmp qword [r12+NEBOC_OPERATOR_RESOLVE_LEFT_TYPE_OFFSET],0
 je .invalid_request
 mov r13,[r12+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET]
 test r13,r13
 jz .invalid_request
 mov rax,[r12+NEBOC_OPERATOR_RESOLVE_OUTPUT_OFFSET]
 test rax,rax
 jz .invalid_request
 mov r14,[r12+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET]
 test r14,r14
 jz .no_candidate
 cmp r14,NEBOC_OPERATOR_MAX_CANDIDATES
 ja .limit

 xor ebx,ebx
 xor r15d,r15d
 xor r11d,r11d
 xor r9d,r9d
 mov r8d,NEBOC_OPERATOR_DIAG_NO_EXACT_CANDIDATE
.scan:
 cmp rbx,r14
 jae .scan_done
 mov rax,rbx
 imul rax,NEBOC_OPERATOR_IMPL_SIZE
 add rax,r13
 mov rdx,[r12+NEBOC_OPERATOR_RESOLVE_PROTOCOL_OFFSET]
 cmp [rax+NEBOC_OPERATOR_IMPL_PROTOCOL_OFFSET],rdx
 jne .next
 mov rdx,[r12+NEBOC_OPERATOR_RESOLVE_LEFT_TYPE_OFFSET]
 cmp [rax+NEBOC_OPERATOR_IMPL_LEFT_TYPE_OFFSET],rdx
 jne .next
 mov rdx,[r12+NEBOC_OPERATOR_RESOLVE_RIGHT_TYPE_OFFSET]
 cmp [rax+NEBOC_OPERATOR_IMPL_RIGHT_TYPE_OFFSET],rdx
 jne .next
 mov rdx,[rax+NEBOC_OPERATOR_IMPL_FLAGS_OFFSET]
 test rdx,NEBOC_OPERATOR_IMPL_FLAG_ACTIVE
 jz .next
 test rdx,NEBOC_OPERATOR_IMPL_FLAG_INACTIVE
 jnz .next
 test rdx,NEBOC_OPERATOR_IMPL_FLAG_EXACT_TYPES
 jz .next
 test rdx,NEBOC_OPERATOR_IMPL_FLAG_COHERENT
 jz .incoherent
 mov rcx,rdx
 and rcx,NEBOC_OPERATOR_IMPL_FLAG_BUILTIN|NEBOC_OPERATOR_IMPL_FLAG_USER
 cmp rcx,NEBOC_OPERATOR_IMPL_FLAG_BUILTIN
 je .owner_valid
 cmp rcx,NEBOC_OPERATOR_IMPL_FLAG_USER
 jne .incoherent
 mov rcx,[rax+NEBOC_OPERATOR_IMPL_OWNER_TYPE_OFFSET]
 cmp rcx,[rax+NEBOC_OPERATOR_IMPL_LEFT_TYPE_OFFSET]
 je .owner_valid
 cmp rcx,[rax+NEBOC_OPERATOR_IMPL_RIGHT_TYPE_OFFSET]
 jne .incoherent
.owner_valid:
 cmp qword [rax+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET],0
 je .incoherent
 cmp qword [rax+NEBOC_OPERATOR_IMPL_OWNER_TYPE_OFFSET],0
 je .incoherent
 cmp qword [rax+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET],0
 je .incoherent
 cmp qword [rax+NEBOC_OPERATOR_IMPL_CONSTRAINTS_OFFSET],NEBOC_OPERATOR_MAX_CONSTRAINTS
 ja .limit
 cmp qword [rax+NEBOC_OPERATOR_IMPL_SPECIFICITY_OFFSET],0
 je .incoherent
 mov rdx,[rax+NEBOC_OPERATOR_IMPL_REQUIRED_CAPABILITIES_OFFSET]
 mov rcx,[r12+NEBOC_OPERATOR_RESOLVE_AVAILABLE_CAPABILITIES_OFFSET]
 not rcx
 test rdx,rcx
 jz .effects
 cmp r8d,NEBOC_OPERATOR_DIAG_CAPABILITY_MISSING
 jae .next
 mov r8d,NEBOC_OPERATOR_DIAG_CAPABILITY_MISSING
 jmp .next
.effects:
 mov rdx,[rax+NEBOC_OPERATOR_IMPL_EFFECTS_OFFSET]
 mov rcx,[r12+NEBOC_OPERATOR_RESOLVE_ALLOWED_EFFECTS_OFFSET]
 not rcx
 test rdx,rcx
 jz .matched
 cmp r8d,NEBOC_OPERATOR_DIAG_EFFECT_FORBIDDEN
 jae .next
 mov r8d,NEBOC_OPERATOR_DIAG_EFFECT_FORBIDDEN
 jmp .next
.matched:
 mov rcx,[rax+NEBOC_OPERATOR_IMPL_SPECIFICITY_OFFSET]
 test r11d,r11d
 jz .new_best
 cmp rcx,r9
 ja .new_best
 jne .next
 inc r11d
 jmp .next
.new_best:
 mov r9,rcx
 mov r15,rax
 mov r10,rbx
 mov r11d,1
 jmp .next
.incoherent:
 cmp r8d,NEBOC_OPERATOR_DIAG_COHERENCE_VIOLATION
 jae .next
 mov r8d,NEBOC_OPERATOR_DIAG_COHERENCE_VIOLATION
.next:
 inc rbx
 jmp .scan

.scan_done:
 test r11d,r11d
 jz .resolution_failure
 cmp r11d,1
 jne .ambiguous
 mov [rsp+8],r10
 mov rdi,[r15+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET]
 mov rsi,[r12+NEBOC_OPERATOR_RESOLVE_SUBSTITUTIONS_OFFSET]
 mov rdx,[r12+NEBOC_OPERATOR_RESOLVE_SUBSTITUTION_COUNT_OFFSET]
 lea rcx,[rsp]
 call neboc_operator_substitute_type
 test eax,eax
 jnz .substitution_failure
 mov rax,[r12+NEBOC_OPERATOR_RESOLVE_OUTPUT_OFFSET]
 %assign field 0
 %rep 11
  mov rdx,[r15+field]
  mov [rax+field],rdx
  %assign field field+8
 %endrep
 mov rdx,[rsp]
 mov [rax+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET],rdx
 mov r10,[rsp+8]
 mov [r12+NEBOC_OPERATOR_RESOLVE_OUTPUT_INDEX_OFFSET],r10
 mov qword [r12+NEBOC_OPERATOR_RESOLVE_MATCH_COUNT_OFFSET],1
 mov qword [r12+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_NONE
 xor eax,eax
 jmp .done
.substitution_failure:
 mov [r12+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],rdx
 jmp .done
.ambiguous:
 mov r8d,NEBOC_OPERATOR_DIAG_AMBIGUOUS_CANDIDATE
.resolution_failure:
 mov [r12+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],r8
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.no_candidate:
 mov qword [r12+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_NO_EXACT_CANDIDATE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov qword [r12+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_LIMIT_EXCEEDED
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_request:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_operator_resolution_limits
 mov eax,NEBOC_OPERATOR_MAX_CANDIDATES
 mov edx,NEBOC_OPERATOR_MAX_CONSTRAINTS
 mov ecx,NEBOC_OPERATOR_RESOLVE_SIZE
 mov r8d,NEBOC_OPERATOR_IMPL_SIZE
 ret

; Versioned internal ABI descriptor for OperatorKind/OperatorProtocol,
; candidate, resolution, and lowering records.
NEBOC_ABI_FUNCTION neboc_operator_protocol_schema
 mov eax,NEBOC_OPERATOR_PROTOCOL_SCHEMA_VERSION
 mov edx,NEBOC_OPERATOR_PROTOCOL_COUNT
 mov ecx,NEBOC_OPERATOR_KIND_COUNT
 mov r8d,NEBOC_OPERATOR_IMPL_SIZE
 mov r9d,NEBOC_OPERATOR_RESOLVE_SIZE
 mov r10d,NEBOC_OPERATOR_LOWER_SIZE
 ret

; resolve_builtin_type(protocol, left_type, right_type, out_type*) resolves the
; canonical built-in implementation table. Unary calls pass right_type zero.
; The public output remains zero on every failure.
NEBOC_ABI_FUNCTION neboc_operator_resolve_builtin_type
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r15,r15
 jz .builtin_invalid
 mov qword [r15],0
 sub rsp,NEBOC_OPERATOR_RESOLVE_SIZE+NEBOC_OPERATOR_IMPL_SIZE
 call neboc_operator_known_implementations
 mov rbx,rax
 mov r10d,edx
 mov rdi,rsp
 mov ecx,(NEBOC_OPERATOR_RESOLVE_SIZE+NEBOC_OPERATOR_IMPL_SIZE)/8
 xor eax,eax
 rep stosq
 mov [rsp+NEBOC_OPERATOR_RESOLVE_PROTOCOL_OFFSET],r12
 mov [rsp+NEBOC_OPERATOR_RESOLVE_LEFT_TYPE_OFFSET],r13
 mov [rsp+NEBOC_OPERATOR_RESOLVE_RIGHT_TYPE_OFFSET],r14
 mov qword [rsp+NEBOC_OPERATOR_RESOLVE_AVAILABLE_CAPABILITIES_OFFSET],NEBOC_OPERATOR_CAPABILITY_CORE
 mov qword [rsp+NEBOC_OPERATOR_RESOLVE_ALLOWED_EFFECTS_OFFSET],NEBOC_OPERATOR_EFFECT_ALL
 mov [rsp+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rbx
 mov [rsp+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],r10
 lea rax,[rsp+NEBOC_OPERATOR_RESOLVE_SIZE]
 mov [rsp+NEBOC_OPERATOR_RESOLVE_OUTPUT_OFFSET],rax
 mov rdi,rsp
 call neboc_operator_resolve_exact
 test eax,eax
 jnz .builtin_done
 mov rdx,[rsp+NEBOC_OPERATOR_RESOLVE_SIZE+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET]
 mov [r15],rdx
.builtin_done:
 add rsp,NEBOC_OPERATOR_RESOLVE_SIZE+NEBOC_OPERATOR_IMPL_SIZE
 jmp .builtin_restore
.builtin_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.builtin_restore:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
