; TIPOS-PRIMITIVOS-ESCALARES-F08 pointerless authenticated Buffer construction plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/buffer_parser.inc"
%include "compiler/semantic/types/buffer_freeze.inc"
%include "compiler/semantic/collections/public_slice.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lowering/textual/buffer_plan.inc"

section .text

buffer_plan_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rdi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_buffer_lower
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 mov rax,rdi
 or rax,rsi
 test rax,7
 jnz .invalid_direct
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,r13
 mov ecx,NEBOC_BUFFER_PLAN_F11_QWORDS
 xor eax,eax
 rep stosq
 cmp qword [r12+NEBOC_BUFFER_FOUND_OFFSET],1
 jne .source
 test qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_ANALYZED
 jz .source
 mov rax,NEBOC_BUFFER_PLAN_MAGIC
 mov [r13+NEBOC_BUFFER_PLAN_MAGIC_OFFSET],rax
 mov qword [r13+NEBOC_BUFFER_PLAN_VERSION_OFFSET],NEBOC_BUFFER_PLAN_VERSION_A3
 mov rax,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_PLAN_BUFFER_CAPACITY_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_CAPACITY_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_STORAGE_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_STORAGE_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_RESERVED_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_RESERVED_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_RESULT_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_RESULT_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_TYPE_ID_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_TYPE_ID_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_STATE_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_STATE_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_DROP_COUNT_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_DROP_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_FLAGS_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_FLAGS_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_OPERATION_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_OPTION_TAG_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_OPTION_TAG_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_RESULT_TAG_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_RESULT_TAG_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_GENERATION_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_GENERATION_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_MUTATION_COUNT_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_MUTATION_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_FROZEN_LENGTH_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_FROZEN_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_FROZEN_STORAGE_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_FROZEN_STORAGE_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_FROZEN_TYPE_ID_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_FROZEN_TYPE_ID_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_FREEZE_COUNT_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_FREEZE_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_SLICE_START_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_SLICE_START_OFFSET],rax
 mov rax,[r12+neboc_buffer_parser_SLICE_LENGTH_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_SLICE_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_SLICE_STORAGE_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_SLICE_STORAGE_OFFSET],rax
 mov rax,[r12+neboc_buffer_parser_SLICE_OWNER_GENERATION_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_SLICE_OWNER_GENERATION_OFFSET],rax
 mov rax,[r12+NEBOC_SLICE_VIEW_GENERATION_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_SLICE_VIEW_GENERATION_OFFSET],rax
 mov rax,[r12+NEBOC_SLICE_STATE_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_SLICE_STATE_OFFSET],rax
 mov rax,[r12+NEBOC_SLICE_VIEW_COUNT_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_SLICE_VIEW_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_SLICE_RELEASE_COUNT_OFFSET]
 mov [r13+NEBOC_BUFFER_PLAN_SLICE_RELEASE_COUNT_OFFSET],rax
 test qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PUBLIC_SLICE
 jz .slice_type_ready
 mov qword [r13+NEBOC_BUFFER_PLAN_SLICE_TYPE_ID_OFFSET],NEBOC_TYPE_ID_SLICE
.slice_type_ready:
 mov rdi,r13
 mov ecx,NEBOC_BUFFER_PLAN_HASHED_BYTES
 call buffer_plan_hash
 mov [r13+NEBOC_BUFFER_PLAN_HASH_OFFSET],rax
 lea rdi,[r13+NEBOC_BUFFER_PLAN_F09_EXTENSION_OFFSET]
 mov ecx,NEBOC_BUFFER_PLAN_F09_HASHED_BYTES
 call buffer_plan_hash
 mov [r13+NEBOC_BUFFER_PLAN_EXTENSION_HASH_OFFSET],rax
 lea rdi,[r13+NEBOC_BUFFER_PLAN_F10_EXTENSION_OFFSET]
 mov ecx,NEBOC_BUFFER_PLAN_F10_HASHED_BYTES
 call buffer_plan_hash
 mov [r13+NEBOC_BUFFER_PLAN_F10_HASH_OFFSET],rax
 lea rdi,[r13+NEBOC_BUFFER_PLAN_F11_EXTENSION_OFFSET]
 mov ecx,NEBOC_BUFFER_PLAN_F11_HASHED_BYTES
 call buffer_plan_hash
 mov [r13+NEBOC_BUFFER_PLAN_F11_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
