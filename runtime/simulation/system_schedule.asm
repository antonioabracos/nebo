; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F02: system access masks, conflict edges and schedule descriptors.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/simulation/system_schedule.inc"
section .text
; rdi=record qwords, rsi=count, rdx=56-byte report. Output is failure-atomic.
NEBOC_ABI_FUNCTION nebo_system_schedule_evaluate
    push rbx
    push r12
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,NEBO_SYSTEM_SCHEDULE_MAX_RECORDS
    ja .limit
    xor ecx,ecx
    xor r8d,r8d
    mov r9,0xcbf29ce484222325
    mov rax,NEBO_SYSTEM_SCHEDULE_PROFILE_TAG
    xor r9,rax
    mov r10,-1
    xor r11d,r11d
    xor ebx,ebx
    mov r12,0x100000001b3
.scan:
    mov rax,[rdi+rcx*8]
    cmp rax,NEBO_SYSTEM_SCHEDULE_ITEM_MAX
    ja .invalid
    mov rbx,rax
    add r8,rax
    jc .limit
    cmp rax,r10
    cmovb r10,rax
    cmp rax,r11
    cmova r11,rax
    xor r9,rax
    imul r9,r12
    inc rcx
    cmp rcx,rsi
    jb .scan
    mov qword [rdx+NEBO_SYSTEM_SCHEDULE_REPORT_STATUS],NEBO_SYSTEM_SCHEDULE_STATUS_OK
    mov [rdx+NEBO_SYSTEM_SCHEDULE_REPORT_COUNT],rsi
    mov [rdx+NEBO_SYSTEM_SCHEDULE_REPORT_SUM],r8
    mov [rdx+NEBO_SYSTEM_SCHEDULE_REPORT_HASH],r9
    mov [rdx+NEBO_SYSTEM_SCHEDULE_REPORT_MIN],r10
    mov [rdx+NEBO_SYSTEM_SCHEDULE_REPORT_MAX],r11
    mov rax,NEBO_SYSTEM_SCHEDULE_PROFILE_TAG
    mov [rdx+NEBO_SYSTEM_SCHEDULE_REPORT_PROFILE],rax
    xor eax,eax
    pop r12
    pop rbx
    ret
.invalid:
    mov eax,NEBO_SYSTEM_SCHEDULE_STATUS_INVALID
    pop r12
    pop rbx
    ret
.limit:
    mov eax,NEBO_SYSTEM_SCHEDULE_STATUS_LIMIT
    pop r12
    pop rbx
    ret
.order:
    mov eax,NEBO_SYSTEM_SCHEDULE_STATUS_ORDER
    pop r12
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
