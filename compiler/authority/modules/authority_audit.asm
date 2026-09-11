; G149 read-only audit of the live post-RF148 authority surface.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/authority/modules/foundation.inc"

section .rodata
authority_states: dq 1,2,2,2,1,1,1,2,2,1,3,4
authority_owners: dq 3,151,151,152,150,154,155,160,164,84,164,152

section .text

; LanguageAuthorityAudit.new(rows, count, report).  Inputs are borrowed and
; report publication is failure atomic.
NEBOC_ABI_FUNCTION neboc_rf166_language_authority_audit_new
    test rdi,rdi
    jz .argument
    test rdx,rdx
    jz .argument
    test rdi,7
    jnz .argument
    test rdx,7
    jnz .argument
    cmp rdi,rdx
    je .argument
    cmp rsi,NEBOC_RF166_AUTHORITY_ROWS
    jne .source
    NEBOC_RF166_REJECT_OVERLAP rdi,(NEBOC_RF166_AUTHORITY_ROWS*NEBOC_RF166_ROW_SIZE),rdx,NEBOC_RF166_REPORT_SIZE,.argument,rax
    push rbx
    push rbp
    lea r8,[rel authority_states]
    lea r9,[rel authority_owners]
    xor ecx,ecx
    xor r10d,r10d
    xor r11d,r11d
    xor eax,eax
.loop:
    cmp rcx,rsi
    jae .counts
    mov rax,rcx
    imul rax,NEBOC_RF166_ROW_SIZE
    lea rax,[rdi+rax]
    lea rbx,[rcx+1]
    cmp [rax+NEBOC_RF166_ROW_ID_OFFSET],rbx
    jne .source_pushed
    mov rbx,[rax+NEBOC_RF166_ROW_STATE_OFFSET]
    cmp rbx,[r8+rcx*8]
    jne .source_pushed
    mov rbp,[rax+NEBOC_RF166_ROW_OWNER_OFFSET]
    cmp rbp,[r9+rcx*8]
    jne .source_pushed
    rol r10,7
    xor r10,[rax+NEBOC_RF166_ROW_ID_OFFSET]
    rol r10,11
    xor r10,rbx
    rol r10,13
    xor r10,rbp
    cmp ebx,NEBOC_RF166_STATE_MATERIAL
    jne .not_material
    inc r11d
.not_material:
    inc ecx
    jmp .loop
.counts:
    cmp r11d,5
    jne .source_pushed
    mov qword [rdx+NEBOC_RF166_REPORT_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    mov qword [rdx+NEBOC_RF166_REPORT_TOTAL_OFFSET],NEBOC_RF166_AUTHORITY_ROWS
    mov qword [rdx+NEBOC_RF166_REPORT_MATERIAL_OFFSET],5
    mov qword [rdx+NEBOC_RF166_REPORT_ASSUMED_OFFSET],5
    mov qword [rdx+NEBOC_RF166_REPORT_RESERVED_OFFSET],1
    mov qword [rdx+NEBOC_RF166_REPORT_REJECTED_OFFSET],1
    mov [rdx+NEBOC_RF166_REPORT_DIGEST_OFFSET],r10
    pop rbp
    pop rbx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.source_pushed:
    pop rbp
    pop rbx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
