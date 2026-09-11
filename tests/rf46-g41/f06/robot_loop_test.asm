; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F06 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/robotics/robot_loop.inc"
extern nebo_robot_loop_evaluate
section .data
records dq 25,50,75,100
invalid_record dq 1098305
descending dq 2,1
section .bss
report resb NEBO_ROBOT_LOOP_REPORT_SIZE
max_records resq NEBO_ROBOT_LOOP_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_robot_loop_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_ROBOT_LOOP_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_ROBOT_LOOP_REPORT_SUM],250
    jne fail
    mov rax,0x3ba1fa28914de36b
    cmp [report+NEBO_ROBOT_LOOP_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_ROBOT_LOOP_REPORT_MIN],25
    jne fail
    cmp qword [report+NEBO_ROBOT_LOOP_REPORT_MAX],100
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_robot_loop_evaluate
    cmp eax,NEBO_ROBOT_LOOP_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_robot_loop_evaluate
    cmp eax,NEBO_ROBOT_LOOP_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_robot_loop_evaluate
    cmp eax,NEBO_ROBOT_LOOP_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_ROBOT_LOOP_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_robot_loop_evaluate
    cmp eax,NEBO_ROBOT_LOOP_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_ROBOT_LOOP_MAX_RECORDS
    lea rdx,[report]
    call nebo_robot_loop_evaluate
    test eax,eax
    jnz fail
    mov rax,0x8877665544332211
    mov [report],rax
    lea rdi,[descending]
    mov esi,2
    lea rdx,[report]
    call nebo_robot_loop_evaluate
    cmp eax,NEBO_ROBOT_LOOP_STATUS_ORDER
    jne fail
    mov rax,0x8877665544332211
    cmp [report],rax
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
