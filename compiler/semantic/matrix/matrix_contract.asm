; FUNCOES-LAMBDAS-CALLBACKS-E-REFERENCIAS-F01 Matrix storage/shape/ownership contract
bits 64
default rel
%define NEBO_MATRIX_CONTRACT_IMPLEMENTATION 1
%include "compiler/semantic/matrix/matrix_contract.inc"
section .text
global nebo_matrix_init_owned
global nebo_matrix_validate
global nebo_matrix_validate_view_owner
; rdi desc rsi data rdx rows rcx cols r8 dtype r9 storage id
nebo_matrix_init_owned:
 test rdi,rdi
 jz .arg
 test rdi,7
 jnz .arg
 cmp r8,NEBO_MATRIX_DTYPE_I64
 je .dtype_ok
 cmp r8,NEBO_MATRIX_DTYPE_F64
 jne .shape
.dtype_ok:
 cmp rdx,NEBO_MATRIX_MAX_ROWS
 ja .shape
 cmp rcx,NEBO_MATRIX_MAX_COLS
 ja .shape
 mov r10,rdx
 mov rax,rdx
 mul rcx
 test rdx,rdx
 jnz .shape
 cmp rax,NEBO_NUMERIC_MAX_ELEMENTS
 ja .shape
 test rax,rax
 jz .store
 test rsi,rsi
 jz .arg
.store:
 mov rax,NEBO_MATRIX_MAGIC
 mov [rdi+NEBO_MATRIX_MAGIC_OFF],rax
 mov [rdi+NEBO_MATRIX_DTYPE],r8
 mov [rdi+NEBO_MATRIX_ROWS],r10
 mov [rdi+NEBO_MATRIX_COLS],rcx
 mov [rdi+NEBO_MATRIX_ROW_STRIDE],rcx
.init_tail:
 mov qword [rdi+NEBO_MATRIX_COL_STRIDE],1
 mov [rdi+NEBO_MATRIX_DATA],rsi
 mov rax,[rdi+NEBO_MATRIX_ROWS]
 imul rax,[rdi+NEBO_MATRIX_COLS]
 mov [rdi+NEBO_MATRIX_CAPACITY],rax
 mov [rdi+NEBO_MATRIX_STORAGE_ID],r9
 mov qword [rdi+NEBO_MATRIX_GENERATION],1
 mov qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_OWNED|NEBO_MATRIX_FLAG_CONTIGUOUS
 xor eax,eax
 ret
.arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 ret

nebo_matrix_validate:
 test rdi,rdi
 jz .v_arg
 test rdi,7
 jnz .v_arg
 mov rax,NEBO_MATRIX_MAGIC
 cmp [rdi+NEBO_MATRIX_MAGIC_OFF],rax
 jne .v_contract
 mov rax,[rdi+NEBO_MATRIX_DTYPE]
 cmp rax,NEBO_MATRIX_DTYPE_I64
 je .v_dtype
 cmp rax,NEBO_MATRIX_DTYPE_F64
 jne .v_contract
.v_dtype:
 mov rax,[rdi+NEBO_MATRIX_ROWS]
 cmp rax,NEBO_MATRIX_MAX_ROWS
 ja .v_shape
 mov rcx,[rdi+NEBO_MATRIX_COLS]
 cmp rcx,NEBO_MATRIX_MAX_COLS
 ja .v_shape
 mul rcx
 test rdx,rdx
 jnz .v_shape
 cmp rax,NEBO_NUMERIC_MAX_ELEMENTS
 ja .v_shape
 cmp rax,[rdi+NEBO_MATRIX_CAPACITY]
 ja .v_shape
 test rax,rax
 jz .v_flags
 cmp qword [rdi+NEBO_MATRIX_DATA],0
 je .v_arg
.v_flags:
 mov rax,[rdi+NEBO_MATRIX_FLAGS]
 mov rcx,rax
 and rcx,NEBO_MATRIX_FLAG_OWNED|NEBO_MATRIX_FLAG_VIEW
 cmp rcx,NEBO_MATRIX_FLAG_OWNED
 je .v_owned
 cmp rcx,NEBO_MATRIX_FLAG_VIEW
 jne .v_contract
 cmp qword [rdi+NEBO_MATRIX_ROW_STRIDE],0
 je .v_shape
 cmp qword [rdi+NEBO_MATRIX_COL_STRIDE],0
 je .v_shape
 jmp .v_ok
.v_owned:
 mov rcx,[rdi+NEBO_MATRIX_COLS]
 cmp [rdi+NEBO_MATRIX_ROW_STRIDE],rcx
 jne .v_contract
 cmp qword [rdi+NEBO_MATRIX_COL_STRIDE],1
 jne .v_contract
.v_ok: xor eax,eax
 ret
.v_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.v_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret
.v_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 ret

; rdi view, rsi owner validates same storage and live generation.
nebo_matrix_validate_view_owner:
 push r12
 mov r12,rdi
 call nebo_matrix_validate
 test eax,eax
 jnz .owner_ret
 test rsi,rsi
 jz .owner_arg
 mov rdi,rsi
 call nebo_matrix_validate
 test eax,eax
 jnz .owner_ret
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_VIEW
 jz .owner_contract
 mov rax,[r12+NEBO_MATRIX_STORAGE_ID]
 cmp rax,[rsi+NEBO_MATRIX_STORAGE_ID]
 jne .owner_alias
 mov rax,[r12+NEBO_MATRIX_GENERATION]
 cmp rax,[rsi+NEBO_MATRIX_GENERATION]
 jne .owner_alias
 xor eax,eax
.owner_ret: pop r12
 ret
.owner_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .owner_ret
.owner_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .owner_ret
.owner_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .owner_ret
section .note.GNU-stack noalloc noexec nowrite progbits
