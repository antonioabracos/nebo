; Nebo Assembly — MF024 behavior descriptor classification
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/semantic/effect/effect_classifier.inc"
%include "compiler/semantic/behavior/behavior_table.inc"

section .text

; behavior_classify(request*)
NEBOC_ABI_FUNCTION neboc_behavior_classify
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_BEHAVIOR_REQUEST_ARGUMENTS_OFFSET]
 test r13,r13
 jz .invalid
 mov rax,[r12+NEBOC_BEHAVIOR_REQUEST_ARGUMENT_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_CAPACITY_OFFSET]
 ja .limit
 cmp rax,[r12+NEBOC_BEHAVIOR_REQUEST_ENTRY_CAPACITY_OFFSET]
 ja .limit
 cmp qword [r12+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_NODES_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_BEHAVIOR_REQUEST_ENTRIES_OFFSET],0
 je .invalid
 mov qword [r12+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_COUNT_OFFSET],0
 mov qword [r12+NEBOC_BEHAVIOR_REQUEST_ENTRY_COUNT_OFFSET],0
 mov qword [r12+NEBOC_BEHAVIOR_REQUEST_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_BEHAVIOR_REQUEST_ERROR_INDEX_OFFSET],0
 mov qword [r12+NEBOC_BEHAVIOR_REQUEST_HASH_OFFSET],0
 xor r14d,r14d
 xor r15d,r15d                    ; seen behavior bitset
.loop:
 cmp r14,[r12+NEBOC_BEHAVIOR_REQUEST_ARGUMENT_COUNT_OFFSET]
 jae .finish
 mov rax,r14
 imul rax,NEBOC_BEHAVIOR_ARGUMENT_SIZE
 add rax,r13
 mov rbx,rax
 mov rcx,[rbx+NEBOC_BEHAVIOR_ARGUMENT_KIND_OFFSET]
 cmp rcx,NEBOC_ARGUMENT_KIND_POSITIONAL
 je .positional
 cmp rcx,NEBOC_ARGUMENT_KIND_BEHAVIOR
 jne .unsupported
 mov rcx,[rbx+NEBOC_BEHAVIOR_ARGUMENT_DESCRIPTOR_KIND_OFFSET]
 cmp rcx,NEBOC_BEHAVIOR_KIND_COLOR
 jne .unsupported
 mov rax,1
 shl rax,cl
 test [r12+NEBOC_BEHAVIOR_REQUEST_ACCEPTED_MASK_OFFSET],rax
 jz .unsupported
 cmp qword [rbx+NEBOC_BEHAVIOR_ARGUMENT_EFFECT_ID_OFFSET],NEBOC_EFFECT_ID_PURE
 jne .effectful
 mov rax,1
 shl rax,cl
 test r15,rax
 jnz .conflict
 or r15,rax
 cmp qword [rbx+NEBOC_BEHAVIOR_ARGUMENT_VALUE_OFFSET],NEBOC_COLOR_RED
 jne .unsupported
 mov rdx,[r12+NEBOC_BEHAVIOR_REQUEST_ENTRY_COUNT_OFFSET]
 cmp rdx,[r12+NEBOC_BEHAVIOR_REQUEST_ENTRY_CAPACITY_OFFSET]
 jae .limit
 mov rax,rdx
 imul rax,NEBOC_BEHAVIOR_ENTRY_SIZE
 add rax,[r12+NEBOC_BEHAVIOR_REQUEST_ENTRIES_OFFSET]
 mov rcx,[rbx+NEBOC_BEHAVIOR_ARGUMENT_DESCRIPTOR_KIND_OFFSET]
 mov [rax+NEBOC_BEHAVIOR_ENTRY_KIND_OFFSET],rcx
 mov rcx,[rbx+NEBOC_BEHAVIOR_ARGUMENT_VALUE_OFFSET]
 mov [rax+NEBOC_BEHAVIOR_ENTRY_VALUE_OFFSET],rcx
 mov [rax+NEBOC_BEHAVIOR_ENTRY_SOURCE_INDEX_OFFSET],r14
 mov [rax+NEBOC_BEHAVIOR_ENTRY_APPLICATION_ORDER_OFFSET],rdx
 mov rcx,[rbx+NEBOC_BEHAVIOR_ARGUMENT_NODE_ID_OFFSET]
 mov [rax+NEBOC_BEHAVIOR_ENTRY_NODE_ID_OFFSET],rcx
 inc qword [r12+NEBOC_BEHAVIOR_REQUEST_ENTRY_COUNT_OFFSET]
 jmp .next
.positional:
 mov rdx,[r12+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_COUNT_OFFSET]
 cmp rdx,[r12+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_CAPACITY_OFFSET]
 jae .limit
 mov rax,[r12+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_NODES_OFFSET]
 mov rcx,[rbx+NEBOC_BEHAVIOR_ARGUMENT_NODE_ID_OFFSET]
 mov [rax+rdx*8],rcx
 inc qword [r12+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_COUNT_OFFSET]
.next:
 inc r14
 jmp .loop
.unsupported:
 mov rsi,NEBOC_DIAG_BEHAVIOR_UNSUPPORTED
 jmp .fail
.conflict:
 mov rsi,NEBOC_DIAG_BEHAVIOR_CONFLICT
 jmp .fail
.effectful:
 mov rsi,NEBOC_DIAG_BEHAVIOR_EFFECTFUL
.fail:
 mov [r12+NEBOC_BEHAVIOR_REQUEST_ERROR_CODE_OFFSET],rsi
 mov [r12+NEBOC_BEHAVIOR_REQUEST_ERROR_INDEX_OFFSET],r14
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.finish:
 mov eax,NEBOC_BEHAVIOR_HASH_FNV1A32_OFFSET_BASIS
 xor r14d,r14d
.hash_loop:
 cmp r14,[r12+NEBOC_BEHAVIOR_REQUEST_ENTRY_COUNT_OFFSET]
 jae .hash_done
 mov rdx,r14
 imul rdx,NEBOC_BEHAVIOR_ENTRY_SIZE
 add rdx,[r12+NEBOC_BEHAVIOR_REQUEST_ENTRIES_OFFSET]
 xor eax,[rdx+NEBOC_BEHAVIOR_ENTRY_KIND_OFFSET]
 imul eax,eax,NEBOC_BEHAVIOR_HASH_FNV1A32_PRIME
 xor eax,[rdx+NEBOC_BEHAVIOR_ENTRY_VALUE_OFFSET]
 imul eax,eax,NEBOC_BEHAVIOR_HASH_FNV1A32_PRIME
 xor eax,[rdx+NEBOC_BEHAVIOR_ENTRY_SOURCE_INDEX_OFFSET]
 imul eax,eax,NEBOC_BEHAVIOR_HASH_FNV1A32_PRIME
 inc r14
 jmp .hash_loop
.hash_done:
 mov [r12+NEBOC_BEHAVIOR_REQUEST_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret
