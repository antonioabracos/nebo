; G149 global RF166 planning DAG and foundation closeout.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/authority/modules/foundation.inc"

section .text

; planning_freeze(nodes, node_count, edges, edge_count, pack_counts, report).
; Each edge is a pair of numeric front identities.
NEBOC_ABI_FUNCTION neboc_rf166_planning_freeze
    test rdi,rdi
    jz .argument
    test rdx,rdx
    jz .argument
    test r8,r8
    jz .argument
    test r9,r9
    jz .argument
    mov rax,rdi
    or rax,rdx
    or rax,r8
    or rax,r9
    test rax,7
    jnz .argument
    cmp r9,rdi
    je .argument
    cmp r9,rdx
    je .argument
    cmp r9,r8
    je .argument
    cmp rsi,NEBOC_RF166_FRONT_COUNT
    jne .source
    cmp rcx,NEBOC_RF166_EDGE_COUNT
    jne .source
    NEBOC_RF166_REJECT_OVERLAP rdi,(NEBOC_RF166_FRONT_COUNT*8),r9,NEBOC_RF166_PLAN_SIZE,.argument,rax
    NEBOC_RF166_REJECT_OVERLAP rdx,(NEBOC_RF166_EDGE_COUNT*16),r9,NEBOC_RF166_PLAN_SIZE,.argument,rax
    NEBOC_RF166_REJECT_OVERLAP r8,(NEBOC_RF166_PACK_COUNT*8),r9,NEBOC_RF166_PLAN_SIZE,.argument,rax
    xor r10d,r10d
    xor r11d,r11d
.nodes:
    cmp r10,rsi
    jae .edges_begin
    lea rax,[r10+NEBOC_RF166_FRONT_FIRST]
    cmp [rdi+r10*8],rax
    jne .source
    rol r11,5
    xor r11,rax
    inc r10
    jmp .nodes
.edges_begin:
    xor r10d,r10d
.edges:
    cmp r10,rcx
    jae .packs
    mov rax,r10
    shl rax,4
    lea rsi,[r10+NEBOC_RF166_FRONT_FIRST]
    cmp [rdx+rax],rsi
    jne .source
    inc rsi
    cmp [rdx+rax+8],rsi
    jne .source
    rol r11,7
    xor r11,rsi
    inc r10
    jmp .edges
.packs:
    cmp qword [r8],NEBOC_RF166_PACK_P01_COUNT
    jne .source
    cmp qword [r8+8],NEBOC_RF166_PACK_P02_COUNT
    jne .source
    cmp qword [r8+16],NEBOC_RF166_PACK_P03_COUNT
    jne .source
    cmp qword [r8+24],NEBOC_RF166_PACK_P04_COUNT
    jne .source
    rol r11,11
    xor r11,NEBOC_RF166_PACK_P01_COUNT
    rol r11,11
    xor r11,NEBOC_RF166_PACK_P02_COUNT
    rol r11,11
    xor r11,NEBOC_RF166_PACK_P03_COUNT
    rol r11,11
    xor r11,NEBOC_RF166_PACK_P04_COUNT
    mov qword [r9+NEBOC_RF166_PLAN_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    mov qword [r9+NEBOC_RF166_PLAN_FRONT_OFFSET],NEBOC_RF166_FRONT_COUNT
    mov qword [r9+NEBOC_RF166_PLAN_EDGE_OFFSET],NEBOC_RF166_EDGE_COUNT
    mov qword [r9+NEBOC_RF166_PLAN_PACK_OFFSET],NEBOC_RF166_PACK_COUNT
    mov qword [r9+NEBOC_RF166_PLAN_P01_OFFSET],NEBOC_RF166_PACK_P01_COUNT
    mov qword [r9+NEBOC_RF166_PLAN_P02_OFFSET],NEBOC_RF166_PACK_P02_COUNT
    mov qword [r9+NEBOC_RF166_PLAN_P03_OFFSET],NEBOC_RF166_PACK_P03_COUNT
    mov qword [r9+NEBOC_RF166_PLAN_P04_OFFSET],NEBOC_RF166_PACK_P04_COUNT
    mov [r9+NEBOC_RF166_PLAN_DIGEST_OFFSET],r11
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; foundation_closeout(request, result).  All pointed-to reports are borrowed,
; and no result byte is written until the complete gate validates.
NEBOC_ABI_FUNCTION neboc_rf166_foundation_closeout
    test rdi,rdi
    jz .close_argument
    test rsi,rsi
    jz .close_argument
    test rdi,7
    jnz .close_argument
    test rsi,7
    jnz .close_argument
    cmp rdi,rsi
    je .close_argument
    NEBOC_RF166_REJECT_OVERLAP rdi,NEBOC_RF166_CLOSE_REQUEST_SIZE,rsi,NEBOC_RF166_CLOSE_RESULT_SIZE,.close_argument,rax
    mov r8,[rdi+NEBOC_RF166_CLOSE_AUTHORITY_PTR_OFFSET]
    mov r9,[rdi+NEBOC_RF166_CLOSE_IMPORT_PTR_OFFSET]
    mov r10,[rdi+NEBOC_RF166_CLOSE_DOC_PTR_OFFSET]
    mov r11,[rdi+NEBOC_RF166_CLOSE_INTERFACE_PTR_OFFSET]
    mov rdx,[rdi+NEBOC_RF166_CLOSE_PRELUDE_PTR_OFFSET]
    mov rcx,[rdi+NEBOC_RF166_CLOSE_EXAMPLE_PTR_OFFSET]
    mov rax,[rdi+NEBOC_RF166_CLOSE_PLAN_PTR_OFFSET]
    test r8,r8
    jz .close_argument
    test r9,r9
    jz .close_argument
    test r10,r10
    jz .close_argument
    test r11,r11
    jz .close_argument
    test rdx,rdx
    jz .close_argument
    test rcx,rcx
    jz .close_argument
    test rax,rax
    jz .close_argument
    test r8,7
    jnz .close_argument
    test r9,7
    jnz .close_argument
    test r10,7
    jnz .close_argument
    test r11,7
    jnz .close_argument
    test rdx,7
    jnz .close_argument
    test rcx,7
    jnz .close_argument
    test rax,7
    jnz .close_argument
    cmp rsi,r8
    je .close_argument
    cmp rsi,r9
    je .close_argument
    cmp rsi,r10
    je .close_argument
    cmp rsi,r11
    je .close_argument
    cmp rsi,rdx
    je .close_argument
    cmp rsi,rcx
    je .close_argument
    cmp rsi,rax
    je .close_argument
    cmp qword [r8+NEBOC_RF166_REPORT_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    jne .close_source
    cmp qword [r8+NEBOC_RF166_REPORT_TOTAL_OFFSET],NEBOC_RF166_AUTHORITY_ROWS
    jne .close_source
    cmp qword [r8+NEBOC_RF166_REPORT_MATERIAL_OFFSET],5
    jne .close_source
    cmp qword [r8+NEBOC_RF166_REPORT_ASSUMED_OFFSET],5
    jne .close_source
    cmp qword [r8+NEBOC_RF166_REPORT_RESERVED_OFFSET],1
    jne .close_source
    cmp qword [r8+NEBOC_RF166_REPORT_REJECTED_OFFSET],1
    jne .close_source

    cmp qword [r9+NEBOC_RF166_REPORT_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    jne .close_source
    cmp qword [r9+NEBOC_RF166_REPORT_TOTAL_OFFSET],NEBOC_RF166_IMPORT_ROWS
    jne .close_source
    cmp qword [r9+NEBOC_RF166_REPORT_MATERIAL_OFFSET],0
    jne .close_source
    cmp qword [r9+NEBOC_RF166_REPORT_ASSUMED_OFFSET],6
    jne .close_source
    cmp qword [r9+NEBOC_RF166_REPORT_RESERVED_OFFSET],1
    jne .close_source
    cmp qword [r9+NEBOC_RF166_REPORT_REJECTED_OFFSET],1
    jne .close_source

    cmp qword [r10+NEBOC_RF166_REPORT_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    jne .close_source
    cmp qword [r10+NEBOC_RF166_REPORT_TOTAL_OFFSET],NEBOC_RF166_DOC_ROWS
    jne .close_source
    cmp qword [r10+NEBOC_RF166_REPORT_MATERIAL_OFFSET],0
    jne .close_source
    cmp qword [r10+NEBOC_RF166_REPORT_ASSUMED_OFFSET],1
    jne .close_source
    cmp qword [r10+NEBOC_RF166_REPORT_RESERVED_OFFSET],0
    jne .close_source
    cmp qword [r10+NEBOC_RF166_REPORT_REJECTED_OFFSET],1
    jne .close_source

    cmp qword [r11+NEBOC_RF166_REPORT_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    jne .close_source
    cmp qword [r11+NEBOC_RF166_REPORT_TOTAL_OFFSET],NEBOC_RF166_INTERFACE_ROWS
    jne .close_source
    cmp qword [r11+NEBOC_RF166_REPORT_MATERIAL_OFFSET],0
    jne .close_source
    cmp qword [r11+NEBOC_RF166_REPORT_ASSUMED_OFFSET],1
    jne .close_source
    cmp qword [r11+NEBOC_RF166_REPORT_RESERVED_OFFSET],0
    jne .close_source
    cmp qword [r11+NEBOC_RF166_REPORT_REJECTED_OFFSET],0
    jne .close_source

    cmp qword [rdx+NEBOC_RF166_REPORT_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    jne .close_source
    cmp qword [rdx+NEBOC_RF166_REPORT_TOTAL_OFFSET],NEBOC_RF166_PRELUDE_ROWS
    jne .close_source
    cmp qword [rdx+NEBOC_RF166_REPORT_MATERIAL_OFFSET],1
    jne .close_source
    cmp qword [rdx+NEBOC_RF166_REPORT_ASSUMED_OFFSET],2
    jne .close_source
    cmp qword [rdx+NEBOC_RF166_REPORT_RESERVED_OFFSET],0
    jne .close_source
    cmp qword [rdx+NEBOC_RF166_REPORT_REJECTED_OFFSET],0
    jne .close_source

    cmp qword [rcx+NEBOC_RF166_EXAMPLE_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    jne .close_source
    cmp qword [rcx+NEBOC_RF166_EXAMPLE_COUNT_OFFSET],NEBOC_RF166_EXAMPLE_COUNT
    jne .close_source
    cmp qword [rcx+NEBOC_RF166_EXAMPLE_UNIQUE_OFFSET],NEBOC_RF166_EXAMPLE_COUNT
    jne .close_source

    cmp qword [rax+NEBOC_RF166_PLAN_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    jne .close_source
    cmp qword [rax+NEBOC_RF166_PLAN_FRONT_OFFSET],NEBOC_RF166_FRONT_COUNT
    jne .close_source
    cmp qword [rax+NEBOC_RF166_PLAN_EDGE_OFFSET],NEBOC_RF166_EDGE_COUNT
    jne .close_source
    cmp qword [rax+NEBOC_RF166_PLAN_PACK_OFFSET],NEBOC_RF166_PACK_COUNT
    jne .close_source
    cmp qword [rax+NEBOC_RF166_PLAN_P01_OFFSET],NEBOC_RF166_PACK_P01_COUNT
    jne .close_source
    cmp qword [rax+NEBOC_RF166_PLAN_P02_OFFSET],NEBOC_RF166_PACK_P02_COUNT
    jne .close_source
    cmp qword [rax+NEBOC_RF166_PLAN_P03_OFFSET],NEBOC_RF166_PACK_P03_COUNT
    jne .close_source
    cmp qword [rax+NEBOC_RF166_PLAN_P04_OFFSET],NEBOC_RF166_PACK_P04_COUNT
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_SURFACES_OFFSET],NEBOC_RF166_SURFACE_COUNT
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_OPEN_P0_OFFSET],0
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_OPEN_P1_OFFSET],0
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_OPEN_P2_OFFSET],0
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_MATURITY_OFFSET],NEBOC_RF166_MATURITY_ALL
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_NEXT_GROUP_OFFSET],NEBOC_RF166_NEXT_GROUP
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_NEXT_STARTED_OFFSET],0
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_RF148_ENTRIES_OFFSET],NEBOC_RF166_RF148_ENTRIES
    jne .close_source
    cmp qword [rdi+NEBOC_RF166_CLOSE_OPERATOR_ACTIVATIONS_OFFSET],0
    jne .close_source

    NEBOC_RF166_REJECT_OVERLAP r8,NEBOC_RF166_REPORT_SIZE,rsi,NEBOC_RF166_CLOSE_RESULT_SIZE,.close_argument,rdi
    NEBOC_RF166_REJECT_OVERLAP r9,NEBOC_RF166_REPORT_SIZE,rsi,NEBOC_RF166_CLOSE_RESULT_SIZE,.close_argument,rdi
    NEBOC_RF166_REJECT_OVERLAP r10,NEBOC_RF166_REPORT_SIZE,rsi,NEBOC_RF166_CLOSE_RESULT_SIZE,.close_argument,rdi
    NEBOC_RF166_REJECT_OVERLAP r11,NEBOC_RF166_REPORT_SIZE,rsi,NEBOC_RF166_CLOSE_RESULT_SIZE,.close_argument,rdi
    NEBOC_RF166_REJECT_OVERLAP rdx,NEBOC_RF166_REPORT_SIZE,rsi,NEBOC_RF166_CLOSE_RESULT_SIZE,.close_argument,rdi
    NEBOC_RF166_REJECT_OVERLAP rcx,NEBOC_RF166_EXAMPLE_SIZE,rsi,NEBOC_RF166_CLOSE_RESULT_SIZE,.close_argument,rdi
    NEBOC_RF166_REJECT_OVERLAP rax,NEBOC_RF166_PLAN_SIZE,rsi,NEBOC_RF166_CLOSE_RESULT_SIZE,.close_argument,rdi

    mov rdi,[r8+NEBOC_RF166_REPORT_DIGEST_OFFSET]
    rol rdi,7
    xor rdi,[r9+NEBOC_RF166_REPORT_DIGEST_OFFSET]
    rol rdi,11
    xor rdi,[r10+NEBOC_RF166_REPORT_DIGEST_OFFSET]
    rol rdi,13
    xor rdi,[r11+NEBOC_RF166_REPORT_DIGEST_OFFSET]
    rol rdi,17
    xor rdi,[rdx+NEBOC_RF166_REPORT_DIGEST_OFFSET]
    rol rdi,19
    xor rdi,[rcx+NEBOC_RF166_EXAMPLE_DIGEST_OFFSET]
    rol rdi,23
    xor rdi,[rax+NEBOC_RF166_PLAN_DIGEST_OFFSET]
    xor rdi,NEBOC_RF166_SURFACE_COUNT
    xor rdi,NEBOC_RF166_RF148_ENTRIES

    mov qword [rsi+0],NEBOC_RF166_FOUNDATION_SCHEMA
    mov qword [rsi+8],NEBOC_RF166_AUTHORITY_ROWS
    mov qword [rsi+16],NEBOC_RF166_DECISION_ROWS
    mov qword [rsi+24],NEBOC_RF166_FRONT_COUNT
    mov qword [rsi+32],NEBOC_RF166_EDGE_COUNT
    mov qword [rsi+40],NEBOC_RF166_PACK_COUNT
    mov qword [rsi+48],NEBOC_RF166_EXAMPLE_COUNT
    mov qword [rsi+56],NEBOC_RF166_SURFACE_COUNT
    mov qword [rsi+64],NEBOC_RF166_RF148_ENTRIES
    mov qword [rsi+72],0
    mov qword [rsi+80],0
    mov qword [rsi+88],0
    mov qword [rsi+96],0
    mov qword [rsi+104],NEBOC_RF166_MATURITY_ALL
    mov qword [rsi+112],NEBOC_RF166_NEXT_GROUP
    mov qword [rsi+120],0
    mov [rsi+128],rdi
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.close_source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.close_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
