; Nebo Assembly — MF025 caller-backed ConstantValueTable
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/database/constant_value_table.inc"

section .text

; constant_value_table_init(table*, values*, flags*, capacity)
NEBOC_ABI_FUNCTION neboc_constant_value_table_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 push rbx
 push r12
 mov rbx,rdi
 mov r8,rsi
 mov r9,rdx
 mov r12,rcx
 xor eax,eax
 mov ecx,NEBOC_CONSTANT_VALUE_TABLE_QWORDS
 rep stosq
 mov rdi,r8
 mov rcx,r12
 xor eax,eax
 rep stosq
 mov rdi,r9
 mov rcx,r12
 rep stosq
 mov [rbx+NEBOC_CONSTANT_VALUE_TABLE_VALUES_OFFSET],r8
 mov [rbx+NEBOC_CONSTANT_VALUE_TABLE_FLAGS_OFFSET],r9
 mov [rbx+NEBOC_CONSTANT_VALUE_TABLE_CAPACITY_OFFSET],r12
 mov qword [rbx+NEBOC_CONSTANT_VALUE_TABLE_STATE_OFFSET],NEBOC_CONSTANT_VALUE_TABLE_STATE_MUTABLE
 pop r12
 pop rbx
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; constant_value_table_set(table*, NodeId, value)
NEBOC_ABI_FUNCTION neboc_constant_value_table_set
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_CONSTANT_VALUE_TABLE_STATE_OFFSET],NEBOC_CONSTANT_VALUE_TABLE_STATE_MUTABLE
 jne .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_CONSTANT_VALUE_TABLE_CAPACITY_OFFSET]
 ja .invalid
 mov r8,[rdi+NEBOC_CONSTANT_VALUE_TABLE_VALUES_OFFSET]
 mov r9,[rdi+NEBOC_CONSTANT_VALUE_TABLE_FLAGS_OFFSET]
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 dec rsi
 cmp qword [r9+rsi*8],NEBOC_CONSTANT_VALUE_VALID
 je .store
 inc qword [rdi+NEBOC_CONSTANT_VALUE_TABLE_COUNT_OFFSET]
.store:
 mov [r8+rsi*8],rdx
 mov qword [r9+rsi*8],NEBOC_CONSTANT_VALUE_VALID
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; constant_value_table_get(table*, NodeId, out_value*, out_flag*)
NEBOC_ABI_FUNCTION neboc_constant_value_table_get
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov qword [rdx],0
 mov qword [rcx],0
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_CONSTANT_VALUE_TABLE_CAPACITY_OFFSET]
 ja .invalid
 mov r8,[rdi+NEBOC_CONSTANT_VALUE_TABLE_VALUES_OFFSET]
 mov r9,[rdi+NEBOC_CONSTANT_VALUE_TABLE_FLAGS_OFFSET]
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 dec rsi
 mov rax,[r8+rsi*8]
 mov [rdx],rax
 mov rax,[r9+rsi*8]
 mov [rcx],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; constant_value_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_constant_value_table_freeze
 sub rsp,8
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_CONSTANT_VALUE_TABLE_STATE_OFFSET],NEBOC_CONSTANT_VALUE_TABLE_STATE_MUTABLE
 jne .invalid
 mov r8,[rdi+NEBOC_CONSTANT_VALUE_TABLE_VALUES_OFFSET]
 mov r9,[rdi+NEBOC_CONSTANT_VALUE_TABLE_FLAGS_OFFSET]
 mov r10,[rdi+NEBOC_CONSTANT_VALUE_TABLE_CAPACITY_OFFSET]
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 test r10,r10
 jz .invalid
 mov eax,2166136261
 xor r11d,r11d
.hash_loop:
 cmp r11,r10
 jae .done
 mov rdx,[r9+r11*8]
 call .hash_qword
 mov rdx,[r8+r11*8]
 call .hash_qword
 inc r11
 jmp .hash_loop
.done:
 mov [rdi+NEBOC_CONSTANT_VALUE_TABLE_HASH_OFFSET],rax
 mov qword [rdi+NEBOC_CONSTANT_VALUE_TABLE_STATE_OFFSET],NEBOC_CONSTANT_VALUE_TABLE_STATE_FROZEN
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
 movzx esi,dl
 xor eax,esi
 imul eax,eax,16777619
 shr rdx,8
 dec ecx
 jnz .hq
 pop rcx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
