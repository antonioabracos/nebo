; G149 bounded syntax/schema/interface/prelude decision registries.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/authority/modules/foundation.inc"

section .rodata
import_states: dq 2,2,2,2,2,2,4,3
import_owners: dq 151,151,151,152,152,152,152,152
doc_states: dq 2,4
doc_owners: dq 155,155
interface_states: dq 2
interface_owners: dq 154
prelude_states: dq 2,2,1
prelude_owners: dq 163,163,163

section .text

NEBOC_ABI_FUNCTION neboc_rf166_import_syntax_registry_freeze
    mov ecx,NEBOC_RF166_IMPORT_ROWS
    lea r8,[rel import_states]
    lea r9,[rel import_owners]
    mov r10d,0
    mov r11d,6
    sub rsp,8
    push qword 1
    push qword 1
    call freeze_rows
    add rsp,24
    ret

NEBOC_ABI_FUNCTION neboc_rf166_doc_schema_registry_freeze
    mov ecx,NEBOC_RF166_DOC_ROWS
    lea r8,[rel doc_states]
    lea r9,[rel doc_owners]
    mov r10d,0
    mov r11d,1
    sub rsp,8
    push qword 0
    push qword 1
    call freeze_rows
    add rsp,24
    ret

NEBOC_ABI_FUNCTION neboc_rf166_interface_format_registry_freeze
    mov ecx,NEBOC_RF166_INTERFACE_ROWS
    lea r8,[rel interface_states]
    lea r9,[rel interface_owners]
    mov r10d,0
    mov r11d,1
    sub rsp,8
    push qword 0
    push qword 0
    call freeze_rows
    add rsp,24
    ret

NEBOC_ABI_FUNCTION neboc_rf166_prelude_contract_freeze
    mov ecx,NEBOC_RF166_PRELUDE_ROWS
    lea r8,[rel prelude_states]
    lea r9,[rel prelude_owners]
    mov r10d,1
    mov r11d,2
    sub rsp,8
    push qword 0
    push qword 0
    call freeze_rows
    add rsp,24
    ret

; rdi rows, rsi count, rdx report, ecx expected total, r8 states, r9 owners,
; r10 material, r11 assumed, [rsp+8] rejected, [rsp+16] reserved.
freeze_rows:
    test rdi,rdi
    jz .argument
    test rdx,rdx
    jz .argument
    mov rax,rdi
    or rax,rdx
    test rax,7
    jnz .argument
    cmp rdi,rdx
    je .argument
    cmp rsi,rcx
    jne .source
    mov rax,rsi
    imul rax,NEBOC_RF166_ROW_SIZE
    add rax,rdi
    jc .argument
    cmp rdx,rax
    jae .no_overlap
    mov rax,rdx
    add rax,NEBOC_RF166_REPORT_SIZE
    jc .argument
    cmp rdi,rax
    jb .argument
.no_overlap:
    push rbx
    push rbp
    push r12
    xor eax,eax
    xor ecx,ecx
    xor ebx,ebx
.loop:
    cmp rcx,rsi
    jae .publish
    mov rax,rcx
    imul rax,NEBOC_RF166_ROW_SIZE
    lea rax,[rdi+rax]
    lea rbp,[rcx+1]
    cmp [rax+NEBOC_RF166_ROW_ID_OFFSET],rbp
    jne .source_pushed
    mov rbp,[rax+NEBOC_RF166_ROW_STATE_OFFSET]
    cmp rbp,[r8+rcx*8]
    jne .source_pushed
    mov r12,[rax+NEBOC_RF166_ROW_OWNER_OFFSET]
    cmp r12,[r9+rcx*8]
    jne .source_pushed
    rol rbx,7
    xor rbx,[rax+NEBOC_RF166_ROW_ID_OFFSET]
    rol rbx,11
    xor rbx,rbp
    rol rbx,13
    xor rbx,r12
    inc ecx
    jmp .loop
.publish:
    mov qword [rdx+NEBOC_RF166_REPORT_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    mov [rdx+NEBOC_RF166_REPORT_TOTAL_OFFSET],rsi
    mov [rdx+NEBOC_RF166_REPORT_MATERIAL_OFFSET],r10
    mov [rdx+NEBOC_RF166_REPORT_ASSUMED_OFFSET],r11
    mov rax,[rsp+32]
    mov [rdx+NEBOC_RF166_REPORT_REJECTED_OFFSET],rax
    mov rax,[rsp+40]
    mov [rdx+NEBOC_RF166_REPORT_RESERVED_OFFSET],rax
    mov [rdx+NEBOC_RF166_REPORT_DIGEST_OFFSET],rbx
    pop r12
    pop rbp
    pop rbx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.source_pushed:
    pop r12
    pop rbp
    pop rbx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
