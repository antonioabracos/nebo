; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F05 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/robotics/sensor_fusion.inc"
extern nebo_sensor_fusion_evaluate
section .data
records dq 24,48,72,96
invalid_record dq 1094209
section .bss
report resb NEBO_SENSOR_FUSION_REPORT_SIZE
max_records resq NEBO_SENSOR_FUSION_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_sensor_fusion_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_SENSOR_FUSION_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_SENSOR_FUSION_REPORT_SUM],240
    jne fail
    mov rax,0xe2604a16b47be7a0
    cmp [report+NEBO_SENSOR_FUSION_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_SENSOR_FUSION_REPORT_MIN],24
    jne fail
    cmp qword [report+NEBO_SENSOR_FUSION_REPORT_MAX],96
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_sensor_fusion_evaluate
    cmp eax,NEBO_SENSOR_FUSION_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_sensor_fusion_evaluate
    cmp eax,NEBO_SENSOR_FUSION_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_sensor_fusion_evaluate
    cmp eax,NEBO_SENSOR_FUSION_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_SENSOR_FUSION_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_sensor_fusion_evaluate
    cmp eax,NEBO_SENSOR_FUSION_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_SENSOR_FUSION_MAX_RECORDS
    lea rdx,[report]
    call nebo_sensor_fusion_evaluate
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
