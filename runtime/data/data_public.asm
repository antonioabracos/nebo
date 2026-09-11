; Public typed Column ABI: canonical dtype, missing bitmap and checked native
; aggregates. Each source value owns a descriptor and up to 32 qword cells.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/data/data_contract.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_column_from
extern neboc_column_validate
extern neboc_column_get
extern neboc_column_is_missing
extern neboc_colecoes_primitivas_column_count_missing
extern neboc_column_sum_i64
extern neboc_column_min_i64
extern neboc_column_max_i64
extern neboc_column_cast
extern neboc_column_fill_missing
extern neboc_column_drop_missing
extern neboc_column_coalesce
extern neboc_list_validate
extern nebo_runtime_trap
extern nebo_stream_call
extern nebo_tabular_call
section .text
NEBOC_ABI_FUNCTION nebo_data_call
 cmp edi,400
 jae nebo_tabular_call
 cmp edi,350
 jae nebo_stream_call
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,300
 je .array_new
 cmp ebx,301
 je .from_list
 cmp ebx,332
 je .option_some
 cmp ebx,333
 je .option_none
 cmp ebx,334
 je .option_expect
 mov rdi,r12
 call neboc_column_validate
 test eax,eax
 jnz .trap
 cmp ebx,308
 je .cast_uint
 cmp ebx,309
 je .cast_int
 cmp ebx,310
 je .sum
 cmp ebx,311
 je .minimum
 cmp ebx,312
 je .maximum
 cmp ebx,313
 je .missing_count
 cmp ebx,314
 je .get
 cmp ebx,315
 je .is_missing
 cmp ebx,316
 je .fill_missing
 cmp ebx,317
 je .drop_missing
 cmp ebx,318
 je .coalesce
 cmp ebx,330
 je .append_int
 cmp ebx,331
 je .append_option
 jmp .trap
.array_new:
 xor edx,edx
 jmp .new_length
.from_list:
 mov rdi,r13
 call neboc_list_validate
 test eax,eax
 jnz .trap
 cmp qword [r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET],8
 jne .trap
 mov rdx,[r13+NEBOC_LIST_LENGTH_OFFSET]
 cmp rdx,32
 ja .trap
 mov rsi,[r13+NEBOC_LIST_DATA_OFFSET]
 xor ecx,ecx
.copy_list:
 cmp rcx,rdx
 jae .new_length
 mov rax,[rsi+rcx*8]
 mov [r15+64+rcx*8],rax
 inc rcx
 jmp .copy_list
.new_length:
 mov rdi,r15
 lea rsi,[r15+64]
 mov ecx,32
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_from
 test eax,eax
 jnz .trap
 jmp .result
.append_int:
 xor r14d,r14d
 jmp .append
.append_option:
 cmp qword [r13],1
 ja .trap
 mov r14,[r13]
 xor r14,1
 mov r13,[r13+8]
 test r14,r14
 jz .append
 xor r13d,r13d
.append:
 cmp qword [r12+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .trap
 mov rdx,[r12+NEBO_COLUMN_LENGTH]
 cmp rdx,32
 jae .trap
 mov rsi,[r12+NEBO_COLUMN_VALUES]
 mov [rsi+rdx*8],r13
 mov r9,[r12+NEBO_COLUMN_MISSING_BITMAP]
 test r14,r14
 jz .append_present
 bts r9,rdx
.append_present:
 inc rdx
 mov ecx,32
 mov r8d,NEBO_DTYPE_I64
 mov rdi,r12
 call neboc_column_from
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.sum:
 mov rsi,r15
 call neboc_column_sum_i64
 jmp .scalar_status
.minimum:
 mov rsi,r15
 mov rdx,rsp
 call neboc_column_min_i64
 jmp .extreme_status
.maximum:
 mov rsi,r15
 mov rdx,rsp
 call neboc_column_max_i64
.extreme_status:
 test eax,eax
 jnz .trap
 cmp qword [rsp],1
 jne .trap
 mov rax,[r15]
 jmp .done
.missing_count:
 mov rsi,r15
 call neboc_colecoes_primitivas_column_count_missing
 jmp .scalar_status
.get:
 mov rsi,r13
 lea rdx,[r15+8]
 mov rcx,r15
 call neboc_column_get
 test eax,eax
 jnz .trap
 jmp .result
.is_missing:
 mov rsi,r13
 mov rdx,r15
 call neboc_column_is_missing
 jmp .scalar_status
.fill_missing:
 mov rsi,r13
 mov rdx,rsp
 call neboc_column_fill_missing
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.drop_missing:
 mov rsi,r15
 lea rdx,[r15+64]
 mov ecx,32
 call neboc_column_drop_missing
 test eax,eax
 jnz .trap
 jmp .result
.coalesce:
 mov rsi,r13
 lea rdx,[r15+64]
 mov rcx,rsp
 call neboc_column_coalesce
 test eax,eax
 jnz .trap
 mov rdi,r15
 lea rsi,[r15+64]
 mov rdx,[r12+NEBO_COLUMN_LENGTH]
 mov ecx,32
 mov r8,[r12+NEBO_COLUMN_DTYPE]
 mov r9,[rsp]
 call neboc_column_from
 test eax,eax
 jnz .trap
 jmp .result
.cast_uint:
 mov esi,NEBO_DTYPE_U64
 jmp .cast
.cast_int:
 mov esi,NEBO_DTYPE_I64
.cast:
 mov rdx,r15
 lea rcx,[r15+64]
 mov r8d,32
 call neboc_column_cast
 test eax,eax
 jnz .trap
 jmp .result
.option_some:
 mov rax,[r12]
 jmp .done
.option_none:
 xor eax,eax
 cmp qword [r12],0
 sete al
 jmp .done
.option_expect:
 cmp qword [r12],1
 jne .trap
 mov rax,[r12+8]
 jmp .done
.result:
 mov rax,r15
 jmp .done
.scalar_status:
 test eax,eax
 jnz .trap
 mov rax,[r15]
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 mov edi,49
 call nebo_runtime_trap
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
