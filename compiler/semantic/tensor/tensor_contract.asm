; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F01 bounded CPU Tensor descriptor and alias contract
bits 64
default rel
%define NEBO_TENSOR_CONTRACT_IMPLEMENTATION 1
%include "compiler/semantic/tensor/tensor_contract.inc"
section .text
global nebo_tensor_init_owned
global nebo_tensor_validate
global nebo_tensor_validate_view_owner
global nebo_tensor_element_count

; desc rdi, data rsi, rank rdx, shape rcx, dtype r8, storage id r9
nebo_tensor_init_owned:
 push r12
 mov r12,rdx
 test rdi,rdi
 jz .arg
 test rdi,7
 jnz .arg
 cmp rdx,NEBO_TENSOR_MAX_RANK
 ja .shape
 cmp r8,NEBO_TENSOR_DTYPE_BOOL
 jb .contract
 cmp r8,NEBO_TENSOR_DTYPE_F64
 ja .contract
 test rdx,rdx
 jz .shape_ok
 test rcx,rcx
 jz .arg
.shape_ok:
 mov r10,r12
 mov r11,1
 test r10,r10
 jz .have_count
.copy_shape:
 dec r10
 mov rax,[rcx+r10*8]
 cmp rax,NEBO_TENSOR_MAX_ELEMENTS
 ja .shape
 mov [rdi+NEBO_TENSOR_SHAPE+r10*8],rax
 mov [rdi+NEBO_TENSOR_STRIDES+r10*8],r11
 mul r11
 test rdx,rdx
 jnz .shape
 cmp rax,NEBO_TENSOR_MAX_ELEMENTS
 ja .shape
 mov r11,rax
 test r10,r10
 jnz .copy_shape
.have_count:
 test r11,r11
 jz .store
 test rsi,rsi
 jz .arg
.store:
 mov rax,NEBO_TENSOR_MAGIC
 mov [rdi+NEBO_TENSOR_MAGIC_OFF],rax
 mov [rdi+NEBO_TENSOR_DTYPE],r8
 mov qword [rdi+NEBO_TENSOR_DEVICE],NEBO_TENSOR_DEVICE_CPU
 mov [rdi+NEBO_TENSOR_RANK],r12
 mov [rdi+NEBO_TENSOR_DATA],rsi
 mov [rdi+NEBO_TENSOR_CAPACITY],r11
 mov [rdi+NEBO_TENSOR_STORAGE_ID],r9
 mov qword [rdi+NEBO_TENSOR_GENERATION],1
 mov qword [rdi+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_OWNED|NEBO_TENSOR_FLAG_CONTIGUOUS
 xor eax,eax
 pop r12
 ret
.arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 pop r12
 ret
.shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 pop r12
 ret
.contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 pop r12
 ret

; desc rdi -> rax count, edx status
nebo_tensor_element_count:
 test rdi,rdi
 jz .ec_arg
 mov rcx,[rdi+NEBO_TENSOR_RANK]
 cmp rcx,NEBO_TENSOR_MAX_RANK
 ja .ec_shape
 mov rax,1
 xor r8d,r8d
.ec_loop:
 cmp r8,rcx
 jae .ec_ok
 mul qword [rdi+NEBO_TENSOR_SHAPE+r8*8]
 test rdx,rdx
 jnz .ec_shape
 cmp rax,NEBO_TENSOR_MAX_ELEMENTS
 ja .ec_shape
 inc r8
 jmp .ec_loop
.ec_ok: xor edx,edx
 ret
.ec_arg: xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.ec_shape: xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_SHAPE
 ret

nebo_tensor_validate:
 push r12
 mov r12,rdi
 test rdi,rdi
 jz .v_arg
 mov rax,NEBO_TENSOR_MAGIC
 cmp [rdi+NEBO_TENSOR_MAGIC_OFF],rax
 jne .v_contract
 cmp qword [rdi+NEBO_TENSOR_DEVICE],NEBO_TENSOR_DEVICE_CPU
 jne .v_contract
 mov rax,[rdi+NEBO_TENSOR_DTYPE]
 cmp rax,NEBO_TENSOR_DTYPE_BOOL
 jb .v_contract
 cmp rax,NEBO_TENSOR_DTYPE_F64
 ja .v_contract
 call nebo_tensor_element_count
 test edx,edx
 jnz .v_shape
 cmp rax,[r12+NEBO_TENSOR_CAPACITY]
 ja .v_shape
 test rax,rax
 jz .v_flags
 cmp qword [r12+NEBO_TENSOR_DATA],0
 je .v_arg
.v_flags:
 mov rax,[r12+NEBO_TENSOR_FLAGS]
 and rax,NEBO_TENSOR_FLAG_OWNED|NEBO_TENSOR_FLAG_VIEW
 cmp rax,NEBO_TENSOR_FLAG_OWNED
 je .v_owned
 cmp rax,NEBO_TENSOR_FLAG_VIEW
 jne .v_contract
 xor eax,eax
 jmp .v_ret
.v_owned:
 mov rcx,[r12+NEBO_TENSOR_RANK]
 mov r8,1
.v_stride:
 test rcx,rcx
 jz .v_ok
 dec rcx
 cmp [r12+NEBO_TENSOR_STRIDES+rcx*8],r8
 jne .v_contract
 imul r8,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 jmp .v_stride
.v_ok: xor eax,eax
.v_ret: pop r12
 ret
.v_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .v_ret
.v_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .v_ret
.v_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .v_ret

nebo_tensor_validate_view_owner:
 push r12
 mov r12,rdi
 call nebo_tensor_validate
 test eax,eax
 jnz .o_ret
 test rsi,rsi
 jz .o_arg
 mov rdi,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .o_ret
 test qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_VIEW
 jz .o_contract
 mov rax,[r12+NEBO_TENSOR_STORAGE_ID]
 cmp rax,[rsi+NEBO_TENSOR_STORAGE_ID]
 jne .o_alias
 mov rax,[r12+NEBO_TENSOR_GENERATION]
 cmp rax,[rsi+NEBO_TENSOR_GENERATION]
 jne .o_alias
 xor eax,eax
.o_ret: pop r12
 ret
.o_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .o_ret
.o_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .o_ret
.o_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .o_ret
section .note.GNU-stack noalloc noexec nowrite progbits
