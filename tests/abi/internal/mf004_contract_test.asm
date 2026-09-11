bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

%if NEBOC_INTERNAL_ABI_VERSION != 0
    %error "unexpected NEBOC_INTERNAL_ABI_VERSION"
%endif
%if NEBOC_ABI_STACK_ALIGNMENT != 16
    %error "unexpected stack alignment"
%endif
%if NEBOC_ABI_RED_ZONE_BYTES != 0
    %error "red zone must be forbidden"
%endif
%if NEBOC_STATUS_COUNT != 9
    %error "unexpected StatusCode count"
%endif

global _start
extern neboc_abi_contract_store_u64
extern neboc_host_process_exit

section .text

_start:
    cld
    sub rsp, 80

    mov rax, 0x1111111111111111
    mov [rsp + 0], rax
    mov rbx, rax
    mov rax, 0x2222222222222222
    mov [rsp + 8], rax
    mov rbp, rax
    mov rax, 0x3333333333333333
    mov [rsp + 16], rax
    mov r12, rax
    mov rax, 0x4444444444444444
    mov [rsp + 24], rax
    mov r13, rax
    mov rax, 0x5555555555555555
    mov [rsp + 32], rax
    mov r14, rax
    mov rax, 0x6666666666666666
    mov [rsp + 40], rax
    mov r15, rax

    mov rax, 0x1122334455667788
    mov [rsp + 56], rax
    mov qword [rsp + 48], 0

    std
    lea rdi, [rsp + 48]
    mov rsi, rax
    call neboc_abi_contract_store_u64

    cmp eax, NEBOC_STATUS_OK
    jne .fail_status_success
    mov rax, [rsp + 56]
    cmp [rsp + 48], rax
    jne .fail_output

    cmp rbx, [rsp + 0]
    jne .fail_rbx
    cmp rbp, [rsp + 8]
    jne .fail_rbp
    cmp r12, [rsp + 16]
    jne .fail_r12
    cmp r13, [rsp + 24]
    jne .fail_r13
    cmp r14, [rsp + 32]
    jne .fail_r14
    cmp r15, [rsp + 40]
    jne .fail_r15

    pushfq
    pop rax
    test rax, 1 << 10
    jnz .fail_direction_flag

    xor edi, edi
    xor esi, esi
    call neboc_abi_contract_store_u64
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_invalid_argument

    cmp rbx, [rsp + 0]
    jne .fail_rbx
    cmp rbp, [rsp + 8]
    jne .fail_rbp
    cmp r12, [rsp + 16]
    jne .fail_r12
    cmp r13, [rsp + 24]
    jne .fail_r13
    cmp r14, [rsp + 32]
    jne .fail_r14
    cmp r15, [rsp + 40]
    jne .fail_r15

    xor edi, edi
    jmp .exit

.fail_status_success:
    mov edi, 1
    jmp .exit
.fail_output:
    mov edi, 2
    jmp .exit
.fail_rbx:
    mov edi, 3
    jmp .exit
.fail_rbp:
    mov edi, 4
    jmp .exit
.fail_r12:
    mov edi, 5
    jmp .exit
.fail_r13:
    mov edi, 6
    jmp .exit
.fail_r14:
    mov edi, 7
    jmp .exit
.fail_r15:
    mov edi, 8
    jmp .exit
.fail_direction_flag:
    mov edi, 9
    jmp .exit
.fail_invalid_argument:
    mov edi, 10

.exit:
    cld
    add rsp, 80
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
