; TIPOS-PRIMITIVOS-ESCALARES-F08 bounded Buffer layout and unique-local semantic gate.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/buffer_parser.inc"
%include "compiler/semantic/types/buffer_freeze.inc"
%include "compiler/semantic/collections/public_slice.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"

section .rodata
buffer_freeze_name: db 'freeze'
buffer_freeze_name_len equ $-buffer_freeze_name
buffer_byte_length_name: db 'byteLength'
buffer_byte_length_name_len equ $-buffer_byte_length_name
buffer_at_name: db 'at'
buffer_at_name_len equ $-buffer_at_name

section .text

; RAX token index -> token pointer or zero. R12 is the Buffer request.
buffer_semantic_token_ptr:
 cmp rax,[r12+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_BUFFER_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; RAX token index -> token kind or INVALID.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_semantic_token_kind:
 call buffer_semantic_token_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.bad:
 mov eax,NEBOC_TOKEN_INVALID
 ret

; RAX token index, RSI bytes, EDX length -> EAX boolean identifier match.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_semantic_token_match:
 mov r10,rax
 mov r11,rsi
 mov r9d,edx
 call buffer_semantic_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r9
 jne .no
 mov r8,[r12+NEBOC_BUFFER_SOURCE_OFFSET]
 add r8,[rax+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r9
 jae .yes
 mov al,[r8+rcx]
 cmp al,[r11+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; RAX and RBX token indices -> EAX boolean identifier equality.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_semantic_token_equal:
 mov r10,rax
 call buffer_semantic_token_ptr
 test rax,rax
 jz .no
 mov r8,rax
 mov rax,rbx
 call buffer_semantic_token_ptr
 test rax,rax
 jz .no
 mov r9,rax
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 cmp qword [r9+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[r8+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[r8+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[r9+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[r9+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .no
 mov r10,[r12+NEBOC_BUFFER_SOURCE_OFFSET]
 mov r11,r10
 add r10,[r8+NEBOC_TOKEN_START_OFFSET]
 add r11,[r9+NEBOC_TOKEN_START_OFFSET]
 xor edx,edx
.loop:
 cmp rdx,rcx
 jae .yes
 mov al,[r10+rdx]
 cmp al,[r11+rdx]
 jne .no
 inc rdx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; Discover freeze without expanding the F09 parser surface. Returns status.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_semantic_scan_freeze:
 xor r14d,r14d
.find:
 cmp r14,[r12+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .none
 mov rax,r14
 lea rsi,[rel buffer_freeze_name]
 mov edx,buffer_freeze_name_len
 call buffer_semantic_token_match
 test eax,eax
 jnz .found
 inc r14
 jmp .find
.found:
 ; The spelling belongs to this request only when the receiver is the exact
 ; owner token captured by its constructor.  Whole-program suffixes can hold
 ; many Buffer owners and method spelling alone carries no owner authority.
 cmp r14,2
 jb .next_candidate
 mov rax,r14
 sub rax,2
 mov rbx,[r12+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 call buffer_semantic_token_equal
 test eax,eax
 jz .next_candidate
 mov rax,r14
 dec rax
 call buffer_semantic_token_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .next_candidate
 mov rax,r14
 inc rax
 call buffer_semantic_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .internal
 mov rax,r14
 add rax,2
 call buffer_semantic_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .internal
 mov rax,r14
 add rax,3
 call buffer_semantic_token_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .internal
 mov rax,r14
 add rax,4
 call buffer_semantic_token_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .internal
 mov rax,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 test rax,rax
 jz .length_ok
 cmp rax,1
 je .length_ok
 cmp rax,4
 jne .length_unsupported
.length_ok:
 mov [r12+NEBOC_BUFFER_FROZEN_LENGTH_OFFSET],rax
 mov rcx,[r12+NEBOC_BUFFER_STORAGE_OFFSET]
 test rax,rax
 jz .storage_zero
 cmp rax,1
 jne .storage_ready
 and ecx,255
 jmp .storage_ready
.storage_zero:
 xor ecx,ecx
.storage_ready:
 mov [r12+NEBOC_BUFFER_FROZEN_STORAGE_OFFSET],rcx
 mov qword [r12+NEBOC_BUFFER_FROZEN_TYPE_ID_OFFSET],NEBOC_TYPE_ID_BYTES
 mov qword [r12+NEBOC_BUFFER_FREEZE_COUNT_OFFSET],1
 lea r13,[r14+4]
 mov [r12+NEBOC_BUFFER_FROZEN_NAME_TOKEN_OFFSET],r13
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_FREEZE
 add r14,5
 jmp .scan_use
.next_candidate:
 inc r14
 jmp .find
.scan_use:
 cmp r14,[r12+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .ok
 mov rax,r14
 mov rbx,r13
 call buffer_semantic_token_equal
 test eax,eax
 jz .use_next
 mov rax,r14
 inc rax
 call buffer_semantic_token_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .use_next
 mov rax,r14
 add rax,2
 lea rsi,[rel buffer_byte_length_name]
 mov edx,buffer_byte_length_name_len
 call buffer_semantic_token_match
 test eax,eax
 jnz .byte_length
 mov rax,r14
 add rax,2
 lea rsi,[rel buffer_at_name]
 mov edx,buffer_at_name_len
 call buffer_semantic_token_match
 test eax,eax
 jnz .at
.use_next:
 inc r14
 jmp .scan_use
.byte_length:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_FROZEN_BYTE_LENGTH
 mov rax,[r12+NEBOC_BUFFER_FROZEN_LENGTH_OFFSET]
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 jmp .use_next
.at:
 mov rax,r14
 add rax,4
 call buffer_semantic_token_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .internal
 mov rcx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rcx,[r12+NEBOC_BUFFER_FROZEN_LENGTH_OFFSET]
 jae .bounds
 shl rcx,3
 mov rax,[r12+NEBOC_BUFFER_FROZEN_STORAGE_OFFSET]
 shr rax,cl
 and eax,255
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_FROZEN_AT
 jmp .use_next
.length_unsupported:
 mov qword [r12+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_FREEZE_LENGTH
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.bounds:
 mov qword [r12+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_READ_BOUNDS
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.internal:
 mov qword [r12+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.ok:
.none:
 xor eax,eax
 ret

%undef call
buffer_semantic_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 %assign buffer_off NEBOC_BUFFER_FLAGS_OFFSET
 %rep 10
 xor rax,[rdi+buffer_off]
 imul rax,r8
 %assign buffer_off buffer_off+8
 %endrep
 %assign buffer_f09_off NEBOC_BUFFER_OPERATION_COUNT_OFFSET
 %rep 5
 xor rax,[rdi+buffer_f09_off]
 imul rax,r8
 %assign buffer_f09_off buffer_f09_off+8
 %endrep
 %assign buffer_f10_off NEBOC_BUFFER_FROZEN_LENGTH_OFFSET
 %rep 5
 xor rax,[rdi+buffer_f10_off]
 imul rax,r8
 %assign buffer_f10_off buffer_f10_off+8
 %endrep
 %assign buffer_f11_off NEBOC_SLICE_START_OFFSET
 %rep 9
 xor rax,[rdi+buffer_f11_off]
 imul rax,r8
 %assign buffer_f11_off buffer_f11_off+8
 %endrep
 test rax,rax
 jnz .ready
 mov eax,1
.ready:
 ret

NEBOC_ABI_FUNCTION neboc_buffer_analyze
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push r12
 push rbx
 push r13
 push r14
 push r15
 mov r12,rdi
 cmp qword [r12+NEBOC_BUFFER_FOUND_OFFSET],1
 jne .invalid
 test qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PARSED
 jz .source
 cmp qword [r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET],4
 ja .source
 cmp qword [r12+NEBOC_BUFFER_PLAN_BUFFER_CAPACITY_OFFSET],4
 jne .source
 mov rax,[r12+NEBOC_BUFFER_STORAGE_OFFSET]
 shr rax,32
 test rax,rax
 jnz .source
 cmp qword [r12+NEBOC_BUFFER_RESERVED_OFFSET],0
 jne .source
 cmp qword [r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET],64
 ja .source
 cmp qword [r12+NEBOC_BUFFER_OPTION_TAG_OFFSET],NEBOC_BUFFER_OPTION_SOME
 ja .source
 cmp qword [r12+NEBOC_BUFFER_RESULT_TAG_OFFSET],NEBOC_BUFFER_RESULT_ERR
 ja .source
 mov rax,[r12+NEBOC_BUFFER_MUTATION_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_BUFFER_GENERATION_OFFSET]
 jne .source
 cmp rax,[r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET]
 ja .source
 mov rax,[r12+NEBOC_SLICE_VIEW_COUNT_OFFSET]
 test rax,rax
 jz .slice_none
 cmp rax,12
 ja .source
 test qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PUBLIC_SLICE
 jz .source
 mov rax,[r12+NEBOC_SLICE_STATE_OFFSET]
 cmp rax,NEBOC_SLICE_STATE_LIVE
 je .slice_state
 cmp rax,NEBOC_SLICE_STATE_RELEASED
 jne .source
.slice_state:
 mov rax,[r12+NEBOC_SLICE_VIEW_GENERATION_OFFSET]
 cmp rax,[r12+neboc_buffer_parser_SLICE_OWNER_GENERATION_OFFSET]
 jne .source
 cmp qword [r12+NEBOC_SLICE_RELEASE_COUNT_OFFSET],1
 ja .source
 mov rax,[r12+NEBOC_SLICE_STORAGE_OFFSET]
 shr rax,32
 test rax,rax
 jnz .source
 jmp .slice_ready
.slice_none:
 cmp qword [r12+NEBOC_SLICE_STATE_OFFSET],NEBOC_SLICE_STATE_NONE
 jne .source
.slice_ready:
 mov rax,[r12+NEBOC_BUFFER_STATE_OFFSET]
 cmp rax,NEBOC_BUFFER_STATE_LIVE
 je .state_ready
 cmp rax,NEBOC_BUFFER_STATE_DROPPED
 jne .source
 cmp qword [r12+NEBOC_BUFFER_DROP_COUNT_OFFSET],1
 jne .source
.state_ready:
 call buffer_semantic_scan_freeze
 test eax,eax
 jnz .done
 mov qword [r12+NEBOC_BUFFER_TYPE_ID_OFFSET],NEBOC_TYPE_ID_BUFFER
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_ANALYZED
 mov rdi,r12
 call buffer_semantic_hash
 mov [r12+NEBOC_BUFFER_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop rbx
 pop r12
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
