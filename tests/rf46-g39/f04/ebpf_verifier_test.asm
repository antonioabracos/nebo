; RESOLVER-TYPECHECKER-E-SEMANTICA-F04 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/portable/ebpf_verifier.inc"
extern nebo_ebpf_verifier_evaluate
extern nebo_ebpf_verify
section .data
records dq 12,24,36,48
invalid_record dq 1045057
valid_program dq 0x00000001000000b7,0x00000000fff80a7b,0x0000000000010015,0x00000002000000b7,0x0000000000000095
bad_opcode dq 0x0000000000000000,0x0000000000000095
bad_register dq 0x0000000100000ab7,0x0000000000000095
bad_flow dq 0x00000000ffff0015,0x0000000000000095
bad_stack dq 0x00000000fffc0a7b,0x0000000000000095
bad_helper dq 0x0000000500000085,0x0000000000000095
missing_exit dq 0x00000001000000b7
section .bss
report resb NEBO_EBPF_VERIFIER_REPORT_SIZE
max_records resq NEBO_EBPF_VERIFIER_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[valid_program]
    mov esi,5
    lea rdx,[report]
    call nebo_ebpf_verify
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_EBPF_VERIFY_INSTRUCTIONS],5
    jne fail
    cmp qword [report+NEBO_EBPF_VERIFY_BRANCHES],1
    jne fail
    cmp qword [report+NEBO_EBPF_VERIFY_STACK_ACCESSES],1
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[bad_opcode]
    mov esi,2
    lea rdx,[report]
    call nebo_ebpf_verify
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_OPCODE
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    lea rdi,[bad_register]
    mov esi,2
    lea rdx,[report]
    call nebo_ebpf_verify
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_REGISTER
    jne fail
    lea rdi,[bad_flow]
    mov esi,2
    lea rdx,[report]
    call nebo_ebpf_verify
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_FLOW
    jne fail
    lea rdi,[bad_stack]
    mov esi,2
    lea rdx,[report]
    call nebo_ebpf_verify
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_STACK
    jne fail
    lea rdi,[bad_helper]
    mov esi,2
    lea rdx,[report]
    call nebo_ebpf_verify
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_HELPER
    jne fail
    lea rdi,[missing_exit]
    mov esi,1
    lea rdx,[report]
    call nebo_ebpf_verify
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_EXIT
    jne fail
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_ebpf_verifier_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_EBPF_VERIFIER_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_EBPF_VERIFIER_REPORT_SUM],120
    jne fail
    mov rax,0xeb20e811288cf6d1
    cmp [report+NEBO_EBPF_VERIFIER_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_EBPF_VERIFIER_REPORT_MIN],12
    jne fail
    cmp qword [report+NEBO_EBPF_VERIFIER_REPORT_MAX],48
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_ebpf_verifier_evaluate
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_ebpf_verifier_evaluate
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_ebpf_verifier_evaluate
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_EBPF_VERIFIER_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_ebpf_verifier_evaluate
    cmp eax,NEBO_EBPF_VERIFIER_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_EBPF_VERIFIER_MAX_RECORDS
    lea rdx,[report]
    call nebo_ebpf_verifier_evaluate
    test eax,eax
    jnz fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
