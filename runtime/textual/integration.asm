; RF84 O6 bounded cross-system integration core
; SysV AMD64, caller-owned buffers, no allocation, no C, no libc.
bits 64
default rel

global integration_front_state
global registry_counts_write
global ab_semantic_equal
global console_options_validate
global pipeline_require
global performance_budget_check
global integration_diagnostic

%define OK           0
%define INVALID      1
%define LIMIT        2
%define CAPACITY     3
%define CONSOLE_DATA 8
%define ALL_MASK     0x3f

section .note.GNU-stack noalloc noexec nowrite progbits
section .text

; rdi=front sequence 1..10.  All O6 fronts are bounded integration contracts.
integration_front_state:
    xor eax, eax
    cmp rdi, 1
    jb .front_invalid
    cmp rdi, 10
    ja .front_invalid
    mov eax, 2
    ret
.front_invalid:
    mov eax, INVALID
    ret

; rdi=out qwords, rsi=capacity qwords.  Failure leaves output untouched.
; Writes groups, fronts, Text rows, output primary/supplemental, Scan primary/supplemental.
registry_counts_write:
    test rdi, rdi
    jz .registry_invalid
    cmp rsi, 7
    jb .registry_capacity
    mov qword [rdi], 32
    mov qword [rdi + 8], 242
    mov qword [rdi + 16], 51
    mov qword [rdi + 24], 381
    mov qword [rdi + 32], 184
    mov qword [rdi + 40], 137
    mov qword [rdi + 48], 141
    xor eax, eax
    ret
.registry_invalid:
    mov eax, INVALID
    ret
.registry_capacity:
    mov eax, CAPACITY
    ret

; rdi=A bytes,rsi=A length,rdx=B bytes,rcx=B length,r8=A metadata,r9=B metadata.
; Returns 1 only for byte- and metadata-identical canonical FormatPlan results.
ab_semantic_equal:
    xor eax, eax
    cmp rsi, rcx
    jne .ab_done
    cmp r8, r9
    jne .ab_done
    test rsi, rsi
    jz .ab_equal
    test rdi, rdi
    jz .ab_done
    test rdx, rdx
    jz .ab_done
    xor r10d, r10d
.ab_loop:
    cmp r10, rsi
    jae .ab_equal
    mov r11b, [rdi + r10]
    cmp r11b, [rdx + r10]
    jne .ab_done
    inc r10
    jmp .ab_loop
.ab_equal:
    mov eax, 1
.ab_done:
    ret

; rdi=ConsoleOptions bit mask, rsi=positional console data argument count.
; Formatting data is never accepted by console; options are presentation-only.
console_options_validate:
    test rdi, ~0x1f
    jnz .console_invalid
    test rsi, rsi
    jnz .console_data
    xor eax, eax
    ret
.console_invalid:
    mov eax, INVALID
    ret
.console_data:
    mov eax, CONSOLE_DATA
    ret

; rdi=observed subsystem mask,rsi=required mask.  Unknown bits are rejected.
pipeline_require:
    test rdi, ~ALL_MASK
    jnz .pipeline_invalid
    test rsi, ~ALL_MASK
    jnz .pipeline_invalid
    mov rax, rdi
    and rax, rsi
    cmp rax, rsi
    jne .pipeline_invalid
    xor eax, eax
    ret
.pipeline_invalid:
    mov eax, INVALID
    ret

; rdi=compile ticks,rsi=runtime ticks,rdx=text bytes,rcx=BSS bytes,r8=startup ticks.
performance_budget_check:
    cmp rdi, 1000000
    ja .perf_limit
    cmp rsi, 1000000
    ja .perf_limit
    cmp rdx, 1048576
    ja .perf_limit
    cmp rcx, 1048576
    ja .perf_limit
    cmp r8, 1000000
    ja .perf_limit
    xor eax, eax
    ret
.perf_limit:
    mov eax, LIMIT
    ret

; edi=status -> stable O6 diagnostic code.
integration_diagnostic:
    mov eax, 0x848400
    cmp edi, CONSOLE_DATA
    je .diag_console
    cmp edi, CAPACITY
    je .diag_capacity
    cmp edi, LIMIT
    je .diag_limit
    cmp edi, INVALID
    je .diag_invalid
    ret
.diag_invalid:
    add eax, 1
    ret
.diag_limit:
    add eax, 2
    ret
.diag_capacity:
    add eax, 3
    ret
.diag_console:
    add eax, 8
    ret
