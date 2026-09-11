bits 64
default rel
%include "runtime/matrix/matrix_ops.inc"
section .data
align 8
a_data dq 1.0,2.0,3.0,4.0
b_data dq 4.0,3.0,2.0,1.0
z_data dq 1.0,0.0,1.0,1.0
o_data dq 99.0,99.0,99.0,99.0
five dq 5.0
ten dq 10.0
twofive dq 2.5
one dq 1.0
two dq 2.0
three dq 3.0
four dq 4.0
zero dq 0.0
callback_count dq 0
callback_misaligned dq 0
section .bss
align 8
a resb NEBO_MATRIX_SIZE
b resb NEBO_MATRIX_SIZE
z resb NEBO_MATRIX_SIZE
o resb NEBO_MATRIX_SIZE
section .text
global _start
square:
 inc qword [rel callback_count]
 mov rax,rsp
 and eax,15
 cmp eax,8
 je .aligned
 mov qword [rel callback_misaligned],1
.aligned:
 mulsd xmm0,xmm0
 ret
integer_scale:
 inc qword [rel callback_count]
 imul rax,rsi,3
 ret
map_square:
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[rel square]
 xor ecx,ecx
 jmp nebo_matrix_map_f64
init:
 lea rdi,[a]
 lea rsi,[a_data]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,1
 call nebo_matrix_init_owned
 lea rdi,[b]
 lea rsi,[b_data]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,2
 call nebo_matrix_init_owned
 lea rdi,[z]
 lea rsi,[z_data]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,3
 call nebo_matrix_init_owned
 lea rdi,[o]
 lea rsi,[o_data]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,4
 call nebo_matrix_init_owned
 ret
_start:
 call init
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,NEBO_MATRIX_OP_ADD
 call nebo_matrix_elementwise_f64
 test eax,eax
 jnz .fail1
 movsd xmm0,[o_data]
 ucomisd xmm0,[rel five]
 jne .fail2
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,NEBO_MATRIX_OP_SUB
 call nebo_matrix_elementwise_f64
 movsd xmm0,[o_data]
 mov rax,0xc008000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .fail3
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,NEBO_MATRIX_OP_MUL
 call nebo_matrix_elementwise_f64
 movsd xmm0,[o_data]
 ucomisd xmm0,[rel four]
 jne .fail4
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[z]
 mov ecx,NEBO_MATRIX_OP_DIV
 call nebo_matrix_elementwise_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail5
 movsd xmm0,[o_data]
 ucomisd xmm0,[rel four]
 jne .fail6
 lea rdi,[o]
 lea rsi,[a]
 movsd xmm0,[rel two]
 call nebo_matrix_scale_f64
 test eax,eax
 jnz .fail7
 movsd xmm0,[o_data+24]
 mov rax,0x4020000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .fail8
 lea rdi,[o]
 lea rsi,[a]
 movsd xmm0,[rel two]
 movsd xmm1,[rel three]
 call nebo_matrix_clamp_f64
 movsd xmm0,[o_data]
 ucomisd xmm0,[rel two]
 jne .fail9
 movsd xmm0,[o_data+24]
 ucomisd xmm0,[rel three]
 jne .fail10
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[rel square]
 xor ecx,ecx
 call nebo_matrix_map_f64
 test eax,eax
 jnz .fail11
 movsd xmm0,[o_data+16]
 mov rax,0x4022000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .fail12
 lea rdi,[a]
 mov esi,NEBO_MATRIX_REDUCE_SUM
 call nebo_matrix_reduce_f64
 ucomisd xmm0,[rel ten]
 jne .fail13
 lea rdi,[a]
 mov esi,NEBO_MATRIX_REDUCE_MEAN
 call nebo_matrix_reduce_f64
 ucomisd xmm0,[rel twofive]
 jne .fail14
 lea rdi,[a]
 mov esi,NEBO_MATRIX_REDUCE_MIN
 call nebo_matrix_reduce_f64
 ucomisd xmm0,[rel one]
 jne .fail15
 lea rdi,[a]
 mov esi,NEBO_MATRIX_REDUCE_MAX
 call nebo_matrix_reduce_f64
 ucomisd xmm0,[rel four]
 jne .fail16
 lea rdi,[o]
 lea rsi,[a]
 movsd xmm0,[rel three]
 movsd xmm1,[rel two]
 call nebo_matrix_clamp_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail17
 lea rdi,[a]
 mov esi,9
 call nebo_matrix_reduce_f64
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail18
 ; Shape/type/write/alias preflight must not invoke a callback or write output.
 cmp qword [callback_count],4
 jne .fail19
 cmp qword [callback_misaligned],0
 jne .fail20
 mov qword [callback_count],0
 mov qword [o+NEBO_MATRIX_ROWS],1
 call map_square
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail21
 mov qword [o+NEBO_MATRIX_ROWS],2
 mov qword [o+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 call map_square
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail22
 mov qword [o+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 or qword [o+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 call map_square
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail23
 and qword [o+NEBO_MATRIX_FLAGS],~NEBO_MATRIX_FLAG_READONLY
 mov qword [o+NEBO_MATRIX_STORAGE_ID],1
 call map_square
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail24
 mov qword [o+NEBO_MATRIX_STORAGE_ID],4
 cmp qword [callback_count],0
 jne .fail25
 movsd xmm0,[o_data]
 ucomisd xmm0,[rel one]
 jne .fail26
 mov qword [a+NEBO_MATRIX_ROWS],0
 mov qword [o+NEBO_MATRIX_ROWS],0
 call map_square
 test eax,eax
 jnz .fail27
 cmp qword [callback_count],0
 jne .fail27
 mov qword [a+NEBO_MATRIX_ROWS],2
 mov qword [o+NEBO_MATRIX_ROWS],2
 mov qword [a+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 mov qword [o+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 mov qword [a_data],17
 mov qword [a_data+8],29
 mov qword [a_data+16],43
 mov qword [a_data+24],71
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[integer_scale]
 xor ecx,ecx
 call nebo_matrix_map_i64
 test eax,eax
 jnz .fail28
 cmp qword [o_data],51
 jne .fail28
 cmp qword [o_data+24],213
 jne .fail28
 cmp qword [callback_count],4
 jne .fail28
 ; A later Int axis overflow cannot publish earlier successful lanes.
 mov qword [a_data],1
 mov rax,9223372036854775807
 mov [a_data+8],rax
 mov qword [a_data+16],2
 mov qword [a_data+24],1
 mov qword [o_data],99
 mov qword [o_data+8],99
 lea rdi,[a]
 mov esi,NEBO_MATRIX_REDUCE_SUM
 xor edx,edx
 lea rcx,[o_data]
 mov r8d,2
 call nebo_matrix_reduce_axis_i64
 cmp eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail29
 cmp qword [o_data],99
 jne .fail30
 cmp qword [o_data+8],99
 jne .fail30
 mov qword [a_data+8],17
 lea rdi,[a]
 mov esi,NEBO_MATRIX_REDUCE_SUM
 xor edx,edx
 lea rcx,[o_data]
 mov r8d,2
 call nebo_matrix_reduce_axis_i64
 test eax,eax
 jnz .fail31
 cmp qword [o_data],3
 jne .fail31
 cmp qword [o_data+8],18
 jne .fail31
 xor edi,edi
 jmp .exit
%assign i 1
%rep 31
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
