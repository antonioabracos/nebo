; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-F02 conservative canonical whole-file/range formatter core.
bits 64
default rel
%define NEBO_FORMATTER_IMPLEMENTATION 1
%include "compiler/formatter/formatter.inc"

section .text
global nebo_formatter_format

; rdi = validated unified tooling contract, rsi = aligned formatter request.
; The output is disjoint and remains untouched on every validation failure.
nebo_formatter_format:
    test rsi,rsi
    jz .argument_early
    test rsi,7
    jnz .argument_early
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rsi
    call nebo_tooling_contract_validate
    test eax,eax
    jnz .contract

    mov r13,[r12+NEBO_FORMATTER_REQUEST_SOURCE_PTR]
    mov r9,[r12+NEBO_FORMATTER_REQUEST_SOURCE_LEN]
    mov r14,[r12+NEBO_FORMATTER_REQUEST_OUTPUT_PTR]
    mov r8,[r12+NEBO_FORMATTER_REQUEST_OUTPUT_CAP]
    test r13,r13
    jz .argument
    test r14,r14
    jz .argument
    cmp r9,NEBO_TOOLING_MAX_SOURCE_BYTES
    ja .limit
    test r8,r8
    jz .capacity
    cmp r8,NEBO_TOOLING_MAX_OUTPUT_BYTES
    ja .limit
    mov rax,[r12+NEBO_FORMATTER_REQUEST_FLAGS]
    mov rdx,rax
    and rdx,~NEBO_FORMATTER_KNOWN_FLAGS
    jnz .argument

    ; Resolve and validate the selected half-open line range.
    mov r10,[r12+NEBO_FORMATTER_REQUEST_RANGE_START]
    mov r11,[r12+NEBO_FORMATTER_REQUEST_RANGE_END]
    test rax,NEBO_FORMATTER_FLAG_RANGE
    jnz .range
    test r10,r10
    jnz .range_error
    test r11,r11
    jnz .range_error
    xor r10d,r10d
    mov r11,r9
    jmp .range_ready
.range:
    cmp r10,r11
    ja .range_error
    cmp r11,r9
    ja .range_error
    test r10,r10
    jz .range_start_ok
    cmp byte [r13+r10-1],10
    jne .range_error
.range_start_ok:
    cmp r11,r9
    je .range_ready
    test r11,r11
    jz .range_ready
    cmp byte [r13+r11-1],10
    jne .range_error
.range_ready:

    ; Prove source/output disjointness and pointer arithmetic before writes.
    mov rax,r13
    add rax,r9
    jc .argument
    mov rdx,r14
    add rdx,r8
    jc .argument
    cmp rax,r14
    jbe .disjoint
    cmp rdx,r13
    jbe .disjoint
    jmp .alias
.disjoint:

    ; Formatting never grows except for the whole-file final newline.
    mov rcx,r9
    test qword [r12+NEBO_FORMATTER_REQUEST_FLAGS],NEBO_FORMATTER_FLAG_RANGE
    jnz .capacity_ready
    test r9,r9
    jz .needs_newline
    cmp byte [r13+r9-1],10
    je .capacity_ready
.needs_newline:
    inc rcx
    jc .limit
.capacity_ready:
    cmp rcx,NEBO_TOOLING_MAX_OUTPUT_BYTES
    ja .limit
    cmp r8,rcx
    jb .capacity

    xor ebx,ebx
    xor r15d,r15d
.loop:
    cmp r15,r9
    jae .finish
    cmp r15,r10
    jb .copy
    cmp r15,r11
    jae .copy
    movzx eax,byte [r13+r15]
    cmp al,13
    jne .maybe_space
    lea rdx,[r15+1]
    cmp rdx,r11
    jae .copy
    cmp byte [r13+rdx],10
    jne .copy
    mov byte [r14+rbx],10
    inc rbx
    add r15,2
    jmp .loop
.maybe_space:
    cmp al,' '
    je .space_run
    cmp al,9
    jne .copy
.space_run:
    mov rdx,r15
.scan_space:
    cmp rdx,r11
    jae .space_at_end
    movzx eax,byte [r13+rdx]
    cmp al,' '
    je .scan_next
    cmp al,9
    jne .space_tail
.scan_next:
    inc rdx
    jmp .scan_space
.space_tail:
    cmp al,10
    je .drop_space
    cmp al,13
    jne .copy
    lea rcx,[rdx+1]
    cmp rcx,r11
    jae .copy
    cmp byte [r13+rcx],10
    jne .copy
.drop_space:
    mov r15,rdx
    jmp .loop
.space_at_end:
    test qword [r12+NEBO_FORMATTER_REQUEST_FLAGS],NEBO_FORMATTER_FLAG_RANGE
    jnz .copy
    cmp r11,r9
    jne .copy
    mov r15,rdx
    jmp .loop
.copy:
    mov al,[r13+r15]
    mov [r14+rbx],al
    inc rbx
    inc r15
    jmp .loop
.finish:
    test qword [r12+NEBO_FORMATTER_REQUEST_FLAGS],NEBO_FORMATTER_FLAG_RANGE
    jnz .success
    test rbx,rbx
    jz .append_newline
    cmp byte [r14+rbx-1],10
    je .success
.append_newline:
    mov byte [r14+rbx],10
    inc rbx
.success:
    mov [r12+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],rbx
    xor eax,eax
    jmp .done
.contract:
    mov eax,NEBO_FORMATTER_ERROR_CONTRACT
    jmp .done
.argument:
    mov eax,NEBO_FORMATTER_ERROR_ARGUMENT
    jmp .done
.limit:
    mov eax,NEBO_FORMATTER_ERROR_LIMIT
    jmp .done
.range_error:
    mov eax,NEBO_FORMATTER_ERROR_RANGE
    jmp .done
.alias:
    mov eax,NEBO_FORMATTER_ERROR_ALIAS
    jmp .done
.capacity:
    mov eax,NEBO_FORMATTER_ERROR_CAPACITY
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.argument_early:
    mov eax,NEBO_FORMATTER_ERROR_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
