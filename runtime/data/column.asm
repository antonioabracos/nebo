; COLECOES-PRIMITIVAS-F02 bounded qword Column with explicit missing bitmap.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
section .text

; init(column*, values*, length, capacity, dtype, missing_bitmap)
NEBOC_ABI_FUNCTION neboc_column_init
 test rdi,rdi
 jz .init_bad
 test rdi,7
 jnz .init_bad
 test rsi,rsi
 jz .init_bad
 test rcx,rcx
 jz .init_limit
 cmp rcx,NEBO_DATA_MAX_ROWS
 ja .init_limit
 cmp rdx,rcx
 ja .init_limit
 cmp r8,NEBO_DTYPE_I64
 jb .init_bad
 cmp r8,NEBO_DTYPE_FLOAT64
 ja .init_bad
 mov r10,rcx
 mov rcx,rdx
 mov rax,r9
 shr rax,cl
 test rax,rax
 jnz .init_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,r8
 mov rbp,r9
 mov rdi,r12
 mov ecx,NEBO_COLUMN_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_COLUMN_VALUES],r13
 mov [r12+NEBO_COLUMN_LENGTH],r14
 mov [r12+NEBO_COLUMN_CAPACITY],r10
 mov [r12+NEBO_COLUMN_DTYPE],r15
 mov [r12+NEBO_COLUMN_MISSING_BITMAP],rbp
 mov qword [r12+NEBO_COLUMN_GENERATION],1
 xor eax,eax
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.init_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.init_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_column_validate
 test rdi,rdi
 jz .cv_bad
 mov rax,[rdi+NEBO_COLUMN_CAPACITY]
 test rax,rax
 jz .cv_source
 cmp rax,NEBO_DATA_MAX_ROWS
 ja .cv_source
 mov rcx,[rdi+NEBO_COLUMN_LENGTH]
 cmp rcx,rax
 ja .cv_source
 cmp qword [rdi+NEBO_COLUMN_VALUES],0
 je .cv_source
 mov rdx,[rdi+NEBO_COLUMN_DTYPE]
 cmp rdx,NEBO_DTYPE_I64
 jb .cv_source
 cmp rdx,NEBO_DTYPE_FLOAT64
 ja .cv_source
 mov rdx,[rdi+NEBO_COLUMN_MISSING_BITMAP]
 shr rdx,cl
 test rdx,rdx
 jnz .cv_source
 xor eax,eax
 ret
.cv_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.cv_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; get(column*, index, out_value*, present*)
NEBOC_ABI_FUNCTION neboc_column_get
 test rdx,rdx
 jz .get_bad
 test rcx,rcx
 jz .get_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r14],0
 mov qword [r15],0
 call neboc_column_validate
 test eax,eax
 jnz .get_done
 cmp r13,[r12+NEBO_COLUMN_LENGTH]
 jae .get_limit
 mov rax,[r12+NEBO_COLUMN_MISSING_BITMAP]
 bt rax,r13
 jc .get_ok
 mov rax,[r12+NEBO_COLUMN_VALUES]
 mov rax,[rax+r13*8]
 mov [r14],rax
 mov qword [r15],1
.get_ok: xor eax,eax
 jmp .get_done
.get_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.get_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.get_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; is_missing(column*, index, out_bool*)
NEBOC_ABI_FUNCTION neboc_column_is_missing
 test rdx,rdx
 jz .im_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_column_validate
 test eax,eax
 jnz .im_done
 cmp r13,[r12+NEBO_COLUMN_LENGTH]
 jae .im_limit
 mov rax,[r12+NEBO_COLUMN_MISSING_BITMAP]
 bt rax,r13
 jnc .im_ok
 mov qword [r14],1
.im_ok: xor eax,eax
 jmp .im_done
.im_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.im_done:
 pop r14
 pop r13
 pop r12
 ret
.im_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; set(column*, index, value, old_value*, was_missing*) clears missing.
NEBOC_ABI_FUNCTION neboc_column_set
 test rcx,rcx
 jz .set_bad
 test r8,r8
 jz .set_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov qword [r15],0
 mov qword [rbp],0
 call neboc_column_validate
 test eax,eax
 jnz .set_done
 cmp qword [r12+NEBO_COLUMN_BORROW],0
 jne .set_borrow
 cmp r13,[r12+NEBO_COLUMN_LENGTH]
 jae .set_limit
 mov rax,[r12+NEBO_COLUMN_MISSING_BITMAP]
 bt rax,r13
 jnc .set_present
 mov qword [rbp],1
 jmp .set_write
.set_present:
 mov rcx,[r12+NEBO_COLUMN_VALUES]
 mov rcx,[rcx+r13*8]
 mov [r15],rcx
.set_write:
 btr rax,r13
 mov [r12+NEBO_COLUMN_MISSING_BITMAP],rax
 mov rcx,[r12+NEBO_COLUMN_VALUES]
 mov [rcx+r13*8],r14
 inc qword [r12+NEBO_COLUMN_GENERATION]
 xor eax,eax
 jmp .set_done
.set_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .set_done
.set_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.set_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.set_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; set_missing(column*, index, missing_bool, old_missing*)
NEBOC_ABI_FUNCTION neboc_column_set_missing
 test rcx,rcx
 jz .sm_bad
 cmp rdx,1
 ja .sm_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r15],0
 call neboc_column_validate
 test eax,eax
 jnz .sm_done
 cmp qword [r12+NEBO_COLUMN_BORROW],0
 jne .sm_borrow
 cmp r13,[r12+NEBO_COLUMN_LENGTH]
 jae .sm_limit
 mov rax,[r12+NEBO_COLUMN_MISSING_BITMAP]
 bt rax,r13
 jnc .sm_apply
 mov qword [r15],1
.sm_apply:
 test r14,r14
 jz .sm_clear
 bts rax,r13
 jmp .sm_commit
.sm_clear: btr rax,r13
.sm_commit:
 mov [r12+NEBO_COLUMN_MISSING_BITMAP],rax
 inc qword [r12+NEBO_COLUMN_GENERATION]
 xor eax,eax
 jmp .sm_done
.sm_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .sm_done
.sm_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.sm_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sm_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_colecoes_primitivas_column_count_missing
 test rsi,rsi
 jz .cm_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov qword [r13],0
 call neboc_column_validate
 test eax,eax
 jnz .cm_done
 mov rax,[r12+NEBO_COLUMN_MISSING_BITMAP]
 popcnt rax,rax
 mov [r13],rax
 xor eax,eax
.cm_done: pop r14
 pop r13
 pop r12
 ret
.cm_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_column_sum_i64
 test rsi,rsi
 jz .sum_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov qword [r13],0
 call neboc_column_validate
 test eax,eax
 jnz .sum_done
 cmp qword [r12+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .sum_source
 xor eax,eax
 xor ecx,ecx
.sum_loop:
 cmp rcx,[r12+NEBO_COLUMN_LENGTH]
 jae .sum_ok
 mov rdx,[r12+NEBO_COLUMN_MISSING_BITMAP]
 bt rdx,rcx
 jc .sum_next
 mov rdx,[r12+NEBO_COLUMN_VALUES]
 add rax,[rdx+rcx*8]
 jo .sum_limit
.sum_next:
 inc rcx
 jmp .sum_loop
.sum_ok:
 mov [r13],rax
 xor eax,eax
 jmp .sum_done
.sum_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .sum_done
.sum_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.sum_done: pop r14
 pop r13
 pop r12
 ret
.sum_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; min_i64/max_i64(column*, out*, found*)
%macro COLUMN_EXTREME 2
NEBOC_ABI_FUNCTION %1
 test rsi,rsi
 jz %%bad
 test rdx,rdx
 jz %%bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r13],0
 mov qword [r14],0
 call neboc_column_validate
 test eax,eax
 jnz %%done
 cmp qword [r12+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne %%source
 xor ecx,ecx
 xor r15d,r15d
%%loop:
 cmp rcx,[r12+NEBO_COLUMN_LENGTH]
 jae %%ok
 mov rax,[r12+NEBO_COLUMN_MISSING_BITMAP]
 bt rax,rcx
 jc %%next
 mov rax,[r12+NEBO_COLUMN_VALUES]
 mov rax,[rax+rcx*8]
 test r15,r15
 jz %%take
 cmp rax,rbp
 %2 %%next
%%take:
 mov rbp,rax
 mov r15d,1
%%next:
 inc rcx
 jmp %%loop
%%ok:
 test r15,r15
 jz %%success
 mov [r13],rbp
 mov qword [r14],1
%%success: xor eax,eax
 jmp %%done
%%source: mov eax,NEBOC_STATUS_INVALID_SOURCE
%%done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
%%bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
COLUMN_EXTREME neboc_column_min_i64,jge
COLUMN_EXTREME neboc_column_max_i64,jle

NEBOC_ABI_FUNCTION neboc_column_iterator_begin
 test rdi,rdi
 jz .ib_bad
 test rdi,7
 jnz .ib_bad
 test rsi,rsi
 jz .ib_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov rdi,r13
 call neboc_column_validate
 test eax,eax
 jnz .ib_done
 cmp qword [r13+NEBO_COLUMN_BORROW],-1
 je .ib_limit
 mov rdi,r12
 mov ecx,NEBO_COLUMN_ITERATOR_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_COLUMN_ITERATOR_OWNER],r13
 mov rax,[r13+NEBO_COLUMN_GENERATION]
 mov [r12+NEBO_COLUMN_ITERATOR_GENERATION],rax
 mov rax,[r13+NEBO_COLUMN_LENGTH]
 mov [r12+NEBO_COLUMN_ITERATOR_REMAINING],rax
 inc qword [r13+NEBO_COLUMN_BORROW]
 xor eax,eax
 jmp .ib_done
.ib_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.ib_done: pop r14
 pop r13
 pop r12
 ret
.ib_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; iterator_next(iter*, out_value*, found*, missing*)
NEBOC_ABI_FUNCTION neboc_column_iterator_next
 test rsi,rsi
 jz .in_bad
 test rdx,rdx
 jz .in_bad
 test rcx,rcx
 jz .in_bad
 mov qword [rsi],0
 mov qword [rdx],0
 mov qword [rcx],0
 cmp qword [rdi+NEBO_COLUMN_ITERATOR_RELEASED],0
 jne .in_source
 mov r8,[rdi+NEBO_COLUMN_ITERATOR_OWNER]
 test r8,r8
 jz .in_source
 mov rax,[r8+NEBO_COLUMN_GENERATION]
 cmp rax,[rdi+NEBO_COLUMN_ITERATOR_GENERATION]
 jne .in_source
 mov r9,[rdi+NEBO_COLUMN_ITERATOR_INDEX]
 cmp r9,[r8+NEBO_COLUMN_LENGTH]
 jae .in_end
 mov rax,[r8+NEBO_COLUMN_MISSING_BITMAP]
 bt rax,r9
 jnc .in_value
 mov qword [rcx],1
 jmp .in_publish
.in_value:
 mov rax,[r8+NEBO_COLUMN_VALUES]
 mov rax,[rax+r9*8]
 mov [rsi],rax
.in_publish:
 mov qword [rdx],1
 inc qword [rdi+NEBO_COLUMN_ITERATOR_INDEX]
 dec qword [rdi+NEBO_COLUMN_ITERATOR_REMAINING]
.in_end: xor eax,eax
 ret
.in_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.in_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_column_iterator_release
 test rdi,rdi
 jz .ir_bad
 cmp qword [rdi+NEBO_COLUMN_ITERATOR_RELEASED],0
 jne .ir_source
 mov rax,[rdi+NEBO_COLUMN_ITERATOR_OWNER]
 test rax,rax
 jz .ir_source
 cmp qword [rax+NEBO_COLUMN_BORROW],0
 je .ir_source
 dec qword [rax+NEBO_COLUMN_BORROW]
 mov qword [rdi+NEBO_COLUMN_ITERATOR_RELEASED],1
 xor eax,eax
 ret
.ir_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.ir_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
