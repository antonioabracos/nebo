; Nebo Assembly — MF025 caller-backed ControlFlowTable
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/database/control_flow_table.inc"

section .text

; control_flow_table_init(table*, entries*, capacity)
NEBOC_ABI_FUNCTION neboc_control_flow_table_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 push rbx
 mov rbx,rdi
 mov r8,rsi
 mov r9,rdx
 xor eax,eax
 mov ecx,NEBOC_CONTROL_FLOW_TABLE_QWORDS
 rep stosq
 mov rdi,r8
 mov rcx,r9
 xor eax,eax
 rep stosq
 mov [rbx+NEBOC_CONTROL_FLOW_TABLE_DATA_OFFSET],r8
 mov [rbx+NEBOC_CONTROL_FLOW_TABLE_CAPACITY_OFFSET],r9
 mov qword [rbx+NEBOC_CONTROL_FLOW_TABLE_STATE_OFFSET],NEBOC_CONTROL_FLOW_TABLE_STATE_MUTABLE
 pop rbx
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; control_flow_table_set(table*, NodeId, annotation)
NEBOC_ABI_FUNCTION neboc_control_flow_table_set
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_CONTROL_FLOW_TABLE_STATE_OFFSET],NEBOC_CONTROL_FLOW_TABLE_STATE_MUTABLE
 jne .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_CONTROL_FLOW_TABLE_CAPACITY_OFFSET]
 ja .invalid
 test rdx,rdx
 jz .invalid
 mov r8,[rdi+NEBOC_CONTROL_FLOW_TABLE_DATA_OFFSET]
 test r8,r8
 jz .invalid
 dec rsi
 cmp qword [r8+rsi*8],0
 jne .store
 inc qword [rdi+NEBOC_CONTROL_FLOW_TABLE_COUNT_OFFSET]
.store:
 mov [r8+rsi*8],rdx
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; control_flow_table_get(table*, NodeId, out*)
NEBOC_ABI_FUNCTION neboc_control_flow_table_get
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_CONTROL_FLOW_TABLE_CAPACITY_OFFSET]
 ja .invalid
 mov r8,[rdi+NEBOC_CONTROL_FLOW_TABLE_DATA_OFFSET]
 test r8,r8
 jz .invalid
 dec rsi
 mov rax,[r8+rsi*8]
 mov [rdx],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; control_flow_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_control_flow_table_freeze
 sub rsp,8
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_CONTROL_FLOW_TABLE_STATE_OFFSET],NEBOC_CONTROL_FLOW_TABLE_STATE_MUTABLE
 jne .invalid
 mov r8,[rdi+NEBOC_CONTROL_FLOW_TABLE_DATA_OFFSET]
 mov r9,[rdi+NEBOC_CONTROL_FLOW_TABLE_CAPACITY_OFFSET]
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 mov eax,2166136261
 xor ecx,ecx
.hash_loop:
 cmp rcx,r9
 jae .done
 mov rdx,[r8+rcx*8]
 call .hash_qword
 inc rcx
 jmp .hash_loop
.done:
 mov [rdi+NEBOC_CONTROL_FLOW_TABLE_HASH_OFFSET],rax
 mov qword [rdi+NEBOC_CONTROL_FLOW_TABLE_STATE_OFFSET],NEBOC_CONTROL_FLOW_TABLE_STATE_FROZEN
 xor eax,eax
 add rsp,8
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 add rsp,8
 ret
.hash_qword:
 push rcx
 mov ecx,8
.hq:
 movzx r10d,dl
 xor eax,r10d
 imul eax,eax,16777619
 shr rdx,8
 dec ecx
 jnz .hq
 pop rcx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
