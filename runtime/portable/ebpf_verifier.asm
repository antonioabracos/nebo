; RESOLVER-TYPECHECKER-E-SEMANTICA-F04: restricted eBPF instruction, helper, map and stack facts.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/portable/ebpf_verifier.inc"
section .text
; rdi=record qwords, rsi=count, rdx=56-byte report. Output is failure-atomic.
NEBOC_ABI_FUNCTION nebo_ebpf_verifier_evaluate
    push rbx
    push r12
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,NEBO_EBPF_VERIFIER_MAX_RECORDS
    ja .limit
    xor ecx,ecx
    xor r8d,r8d
    mov r9,0xcbf29ce484222325
    mov rax,NEBO_EBPF_VERIFIER_PROFILE_TAG
    xor r9,rax
    mov r10,-1
    xor r11d,r11d
    xor ebx,ebx
    mov r12,0x100000001b3
.scan:
    mov rax,[rdi+rcx*8]
    cmp rax,NEBO_EBPF_VERIFIER_ITEM_MAX
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
    mov qword [rdx+NEBO_EBPF_VERIFIER_REPORT_STATUS],NEBO_EBPF_VERIFIER_STATUS_OK
    mov [rdx+NEBO_EBPF_VERIFIER_REPORT_COUNT],rsi
    mov [rdx+NEBO_EBPF_VERIFIER_REPORT_SUM],r8
    mov [rdx+NEBO_EBPF_VERIFIER_REPORT_HASH],r9
    mov [rdx+NEBO_EBPF_VERIFIER_REPORT_MIN],r10
    mov [rdx+NEBO_EBPF_VERIFIER_REPORT_MAX],r11
    mov rax,NEBO_EBPF_VERIFIER_PROFILE_TAG
    mov [rdx+NEBO_EBPF_VERIFIER_REPORT_PROFILE],rax
    xor eax,eax
    pop r12
    pop rbx
    ret
.invalid:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_INVALID
    pop r12
    pop rbx
    ret
.limit:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_LIMIT
    pop r12
    pop rbx
    ret
.order:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_ORDER
    pop r12
    pop rbx
    ret

; rdi=encoded 64-bit eBPF instructions, rsi=count, rdx=report.
; Closed profile: MOV64/ADD64 immediate, forward JEQ/JNE, bounded stack
; LDXDW/STXDW, allowlisted map lookup and terminal EXIT.
NEBOC_ABI_FUNCTION nebo_ebpf_verify
    push rbx
    push r12
    push r13
    push r14
    push r15
    test rdi,rdi
    jz .verify_invalid
    test rdx,rdx
    jz .verify_invalid
    test rsi,rsi
    jz .verify_invalid
    cmp rsi,NEBO_EBPF_VERIFIER_MAX_INSTRUCTIONS
    ja .verify_limit
    mov r13,rdi
    mov r14,rsi
    mov r15,rdx
    xor r8d,r8d
    xor r9d,r9d
    xor r10d,r10d
    xor r11d,r11d
    mov r12,0xcbf29ce484222325
    mov rax,NEBO_EBPF_VERIFIER_PROFILE_TAG
    xor r12,rax
.verify_scan:
    mov rax,[r13+r8*8]
    xor r12,rax
    mov rbx,0x100000001b3
    imul r12,rbx
    mov ebx,eax
    and ebx,0xff
    mov rcx,rax
    shr rcx,8
    and ecx,0xff
    mov edi,ecx
    and edi,0x0f
    mov esi,ecx
    shr esi,4
    mov rcx,rax
    shr rcx,16
    movsx ecx,cx
    mov rdx,rax
    sar rdx,32
    cmp ebx,0xb7
    je .verify_alu_imm
    cmp ebx,0x07
    je .verify_alu_imm
    cmp ebx,0x15
    je .verify_jump
    cmp ebx,0x55
    je .verify_jump
    cmp ebx,0x7b
    je .verify_store_stack
    cmp ebx,0x79
    je .verify_load_stack
    cmp ebx,0x85
    je .verify_helper
    cmp ebx,0x95
    je .verify_exit
    jmp .verify_opcode
.verify_alu_imm:
    cmp edi,9
    ja .verify_register
    test esi,esi
    jnz .verify_register
    test ecx,ecx
    jnz .verify_flow
    jmp .verify_next
.verify_jump:
    cmp edi,9
    ja .verify_register
    test esi,esi
    jnz .verify_register
    test ecx,ecx
    jle .verify_flow
    mov rbx,r8
    inc rbx
    add rbx,rcx
    cmp rbx,r14
    jae .verify_flow
    inc r11
    jmp .verify_next
.verify_store_stack:
    cmp edi,10
    jne .verify_register
    cmp esi,9
    ja .verify_register
    test edx,edx
    jnz .verify_stack
    jmp .verify_stack_offset
.verify_load_stack:
    cmp esi,10
    jne .verify_register
    cmp edi,9
    ja .verify_register
    test edx,edx
    jnz .verify_stack
.verify_stack_offset:
    cmp ecx,-NEBO_EBPF_VERIFIER_STACK_BYTES
    jl .verify_stack
    cmp ecx,-8
    jg .verify_stack
    test ecx,7
    jnz .verify_stack
    inc r10
    jmp .verify_next
.verify_helper:
    test edi,edi
    jnz .verify_register
    test esi,esi
    jnz .verify_register
    test ecx,ecx
    jnz .verify_flow
    cmp edx,NEBO_EBPF_VERIFIER_HELPER_MAP_LOOKUP
    jne .verify_helper_denied
    inc r9
    jmp .verify_next
.verify_exit:
    test ecx,ecx
    jnz .verify_exit_bad
    test edx,edx
    jnz .verify_exit_bad
    test edi,edi
    jnz .verify_exit_bad
    test esi,esi
    jnz .verify_exit_bad
    mov rax,r14
    dec rax
    cmp r8,rax
    jne .verify_exit_bad
.verify_next:
    inc r8
    cmp r8,r14
    jb .verify_scan
    cmp ebx,0x95
    jne .verify_exit_bad
    mov qword [r15+NEBO_EBPF_VERIFY_STATUS],NEBO_EBPF_VERIFIER_STATUS_OK
    mov [r15+NEBO_EBPF_VERIFY_INSTRUCTIONS],r14
    mov [r15+NEBO_EBPF_VERIFY_HELPERS],r9
    mov [r15+NEBO_EBPF_VERIFY_HASH],r12
    mov [r15+NEBO_EBPF_VERIFY_BRANCHES],r11
    mov [r15+NEBO_EBPF_VERIFY_STACK_ACCESSES],r10
    mov rax,NEBO_EBPF_VERIFIER_PROFILE_TAG
    mov [r15+NEBO_EBPF_VERIFY_PROFILE],rax
    xor eax,eax
    jmp .verify_return
.verify_invalid:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_INVALID
    jmp .verify_return
.verify_limit:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_LIMIT
    jmp .verify_return
.verify_opcode:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_OPCODE
    jmp .verify_return
.verify_register:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_REGISTER
    jmp .verify_return
.verify_flow:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_FLOW
    jmp .verify_return
.verify_stack:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_STACK
    jmp .verify_return
.verify_helper_denied:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_HELPER
    jmp .verify_return
.verify_exit_bad:
    mov eax,NEBO_EBPF_VERIFIER_STATUS_EXIT
.verify_return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
