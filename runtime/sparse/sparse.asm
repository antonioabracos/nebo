; AUTONOMIA-CONTROLADA-E-AGENTES-F01 canonical CSR validation and overflow-checked i64 SpMV.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/sparse/sparse.inc"
section .text

; row_ptr,col_idx,rows,cols,nnz.
NEBOC_ABI_FUNCTION nebo_csr_validate
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rcx,rcx
    jz .invalid
    cmp rdx,NEBO_SPARSE_MAX_DIM
    ja .limit
    cmp rcx,NEBO_SPARSE_MAX_DIM
    ja .limit
    cmp r8,NEBO_SPARSE_MAX_NNZ
    ja .limit
    cmp dword [rdi],0
    jne .invalid
    xor r9d,r9d
.row:
    cmp r9,rdx
    jae .terminal
    mov eax,[rdi+r9*4]
    mov r10d,[rdi+r9*4+4]
    cmp eax,r10d
    ja .invalid
    cmp r10,r8
    ja .invalid
    mov r11d,eax
    xor eax,eax
.col:
    cmp r11d,r10d
    jae .next_row
    mov eax,[rsi+r11*4]
    cmp rax,rcx
    jae .invalid
    cmp r11d,[rdi+r9*4]
    je .first
    cmp eax,[rsi+r11*4-4]
    jbe .invalid
.first:
    inc r11d
    jmp .col
.next_row:
    inc r9d
    jmp .row
.terminal:
    cmp [rdi+rdx*4],r8d
    jne .invalid
    xor eax,eax
    ret
.invalid: mov eax,NEBO_SPARSE_INVALID
    ret
.limit: mov eax,NEBO_SPARSE_LIMIT
    ret

; rdi=descriptor, rsi=x i64[cols], rdx=out i64[rows]. Two-pass atomic output.
NEBOC_ABI_FUNCTION nebo_csr_spmv_i64
    test rdi,rdi
    jz .pre_invalid
    test rsi,rsi
    jz .pre_invalid
    test rdx,rdx
    jz .pre_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,[r12+NEBO_CSR_ROW_PTR]
    mov rbx,[r12+NEBO_CSR_COL_IDX]
    mov rdi,[r12+NEBO_CSR_ROW_PTR]
    mov rsi,[r12+NEBO_CSR_COL_IDX]
    mov edx,[r12+NEBO_CSR_ROWS]
    mov ecx,[r12+NEBO_CSR_COLS]
    mov r8d,[r12+NEBO_CSR_NNZ]
    call nebo_csr_validate
    test eax,eax
    jnz .done
    xor r9d,r9d
.check_row:
    cmp r9d,[r12+NEBO_CSR_ROWS]
    jae .write_begin
    xor r10d,r10d
    mov ecx,[r15+r9*4]
    mov edx,[r15+r9*4+4]
.check_item:
    cmp ecx,edx
    jae .check_next
    mov eax,[rbx+rcx*4]
    mov r11,[r12+NEBO_CSR_VALUES]
    mov r11,[r11+rcx*8]
    imul r11,[r13+rax*8]
    jo .overflow
    add r10,r11
    jo .overflow
    inc ecx
    jmp .check_item
.check_next:
    inc r9d
    jmp .check_row
.write_begin:
    xor r9d,r9d
    jmp .write_row
.write_row:
    cmp r9d,[r12+NEBO_CSR_ROWS]
    jae .success
    xor r10d,r10d
    mov ecx,[r15+r9*4]
    mov edx,[r15+r9*4+4]
.write_item:
    cmp ecx,edx
    jae .write_store
    mov eax,[rbx+rcx*4]
    mov r11,[r12+NEBO_CSR_VALUES]
    mov r11,[r11+rcx*8]
    imul r11,[r13+rax*8]
    add r10,r11
    inc ecx
    jmp .write_item
.write_store:
    mov [r14+r9*8],r10
    inc r9d
    jmp .write_row
.success: xor eax,eax
    jmp .done
.overflow: mov eax,NEBO_SPARSE_OVERFLOW
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.pre_invalid: mov eax,NEBO_SPARSE_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
