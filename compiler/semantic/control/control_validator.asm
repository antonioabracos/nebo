; Nebo Assembly — MF024 semantic control validation
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/control/control_validator.inc"

section .text
NEBOC_ABI_FUNCTION neboc_control_validate
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_CONTROL_REQUEST_INPUTS_OFFSET]
 test r13,r13
 jz .invalid
 mov rax,[r12+NEBOC_CONTROL_REQUEST_INPUT_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_CONTROL_REQUEST_OUTPUT_CAPACITY_OFFSET]
 ja .limit
 cmp qword [r12+NEBOC_CONTROL_REQUEST_OUTPUTS_OFFSET],0
 je .invalid
 mov qword [r12+NEBOC_CONTROL_REQUEST_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_CONTROL_REQUEST_ERROR_INDEX_OFFSET],0
 mov qword [r12+NEBOC_CONTROL_REQUEST_HASH_OFFSET],0
 xor r14d,r14d
.loop:
 cmp r14,[r12+NEBOC_CONTROL_REQUEST_INPUT_COUNT_OFFSET]
 jae .finish
 mov rax,r14
 imul rax,NEBOC_CONTROL_INPUT_SIZE
 add rax,r13
 mov rbx,rax
 cmp qword [rbx+NEBOC_CONTROL_INPUT_CONDITION_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jne .condition_error
 mov rax,r14
 imul rax,NEBOC_CONTROL_OUTPUT_SIZE
 add rax,[r12+NEBOC_CONTROL_REQUEST_OUTPUTS_OFFSET]
 mov qword [rax+NEBOC_CONTROL_OUTPUT_ANNOTATION_OFFSET],NEBOC_CONTROL_ANNOTATION_NONE
 mov qword [rax+NEBOC_CONTROL_OUTPUT_EXECUTE_RHS_OFFSET],1
 mov rcx,[rbx+NEBOC_CONTROL_INPUT_THEN_SCOPE_OFFSET]
 mov [rax+NEBOC_CONTROL_OUTPUT_THEN_SCOPE_OFFSET],rcx
 mov rcx,[rbx+NEBOC_CONTROL_INPUT_ELSE_SCOPE_OFFSET]
 mov [rax+NEBOC_CONTROL_OUTPUT_ELSE_SCOPE_OFFSET],rcx
 mov rcx,[rbx+NEBOC_CONTROL_INPUT_KIND_OFFSET]
 cmp rcx,NEBOC_CONTROL_KIND_IF
 je .check_scopes
 cmp rcx,NEBOC_CONTROL_KIND_LOGICAL_AND
 je .logical_and
 cmp rcx,NEBOC_CONTROL_KIND_LOGICAL_OR
 je .logical_or
 jmp .invalid
.logical_and:
 mov qword [rax+NEBOC_CONTROL_OUTPUT_ANNOTATION_OFFSET],NEBOC_CONTROL_ANNOTATION_SKIP_RHS_WHEN_FALSE
 cmp qword [rbx+NEBOC_CONTROL_INPUT_LEFT_CONSTANT_OFFSET],NEBOC_CONTROL_BOOL_FALSE
 jne .next
 mov qword [rax+NEBOC_CONTROL_OUTPUT_EXECUTE_RHS_OFFSET],0
 jmp .next
.logical_or:
 mov qword [rax+NEBOC_CONTROL_OUTPUT_ANNOTATION_OFFSET],NEBOC_CONTROL_ANNOTATION_SKIP_RHS_WHEN_TRUE
 cmp qword [rbx+NEBOC_CONTROL_INPUT_LEFT_CONSTANT_OFFSET],NEBOC_CONTROL_BOOL_TRUE
 jne .next
 mov qword [rax+NEBOC_CONTROL_OUTPUT_EXECUTE_RHS_OFFSET],0
 jmp .next
.check_scopes:
 mov rcx,[rbx+NEBOC_CONTROL_INPUT_PARENT_SCOPE_OFFSET]
 test rcx,rcx
 jz .scope_error
 mov rdx,[rbx+NEBOC_CONTROL_INPUT_THEN_SCOPE_OFFSET]
 test rdx,rdx
 jz .scope_error
 cmp rdx,rcx
 je .scope_error
 mov r8,[rbx+NEBOC_CONTROL_INPUT_ELSE_SCOPE_OFFSET]
 test r8,r8
 jz .next
 cmp r8,rcx
 je .scope_error
 cmp r8,rdx
 je .scope_error
.next:
 inc r14
 jmp .loop
.condition_error:
 mov rsi,NEBOC_DIAG_CONTROL_CONDITION_TYPE
 jmp .fail
.scope_error:
 mov rsi,NEBOC_DIAG_CONTROL_BRANCH_SCOPE
.fail:
 mov [r12+NEBOC_CONTROL_REQUEST_ERROR_CODE_OFFSET],rsi
 mov [r12+NEBOC_CONTROL_REQUEST_ERROR_INDEX_OFFSET],r14
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.finish:
 mov eax,NEBOC_CONTROL_HASH_FNV1A32_OFFSET_BASIS
 xor r14d,r14d
.hash_loop:
 cmp r14,[r12+NEBOC_CONTROL_REQUEST_INPUT_COUNT_OFFSET]
 jae .hash_done
 mov rdx,r14
 imul rdx,NEBOC_CONTROL_OUTPUT_SIZE
 add rdx,[r12+NEBOC_CONTROL_REQUEST_OUTPUTS_OFFSET]
 xor eax,[rdx+NEBOC_CONTROL_OUTPUT_ANNOTATION_OFFSET]
 imul eax,eax,NEBOC_CONTROL_HASH_FNV1A32_PRIME
 xor eax,[rdx+NEBOC_CONTROL_OUTPUT_EXECUTE_RHS_OFFSET]
 imul eax,eax,NEBOC_CONTROL_HASH_FNV1A32_PRIME
 inc r14
 jmp .hash_loop
.hash_done:
 mov [r12+NEBOC_CONTROL_REQUEST_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret
