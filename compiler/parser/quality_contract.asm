; QUALITY-CONFIDENCE-E-LINEAGE-PF002 bounded source-to-syntax contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/quality_contract.inc"

section .rodata
p0: db 'start(){Quality<Int>('
p0n equ $-p0
p_conf: db ').confidence('
p_confn equ $-p_conf
p_lineage: db ').lineage('
p_lineagen equ $-p_lineage
p_require: db ').require('
p_requiren equ $-p_require
p_end: db ');}'
p_endn equ $-p_end

section .text
NEBOC_ABI_FUNCTION neboc_quality_parse
    test rdi,rdi
    jz .invalid
    test rdi,7
    jnz .invalid
    mov r8,rdi
    add r8,neboc_quality_confidence_e_lineage_PARSE_REQUEST_SIZE
    jc .invalid
    cmp qword [rdi+neboc_quality_confidence_e_lineage_PARSE_SOURCE_OFFSET],0
    je .invalid
    cmp qword [rdi+neboc_quality_confidence_e_lineage_PARSE_OUTPUT_OFFSET],0
    je .invalid
    mov rax,[rdi+neboc_quality_confidence_e_lineage_PARSE_OUTPUT_OFFSET]
    test rax,7
    jnz .invalid
    mov rax,[rdi+neboc_quality_confidence_e_lineage_PARSE_SOURCE_LENGTH_OFFSET]
    test rax,rax
    jz .invalid
    cmp rax,neboc_quality_confidence_e_lineage_PARSE_MAX_SOURCE_BYTES
    ja .limit

    ; The transport is transactional: request, source and output ranges are
    ; bounded and pairwise disjoint before any field is cleared or written.
    mov r9,[rdi+neboc_quality_confidence_e_lineage_PARSE_SOURCE_OFFSET]
    mov r10,r9
    add r10,rax
    jc .invalid
    mov r11,[rdi+neboc_quality_confidence_e_lineage_PARSE_OUTPUT_OFFSET]
    mov rdx,r11
    add rdx,neboc_quality_confidence_e_lineage_RESULT_SIZE
    jc .invalid
    cmp r10,rdi
    jbe .source_request_disjoint
    cmp r9,r8
    jb .invalid
.source_request_disjoint:
    cmp rdx,rdi
    jbe .output_request_disjoint
    cmp r11,r8
    jb .invalid
.output_request_disjoint:
    cmp r10,r11
    jbe .source_output_disjoint
    cmp r9,rdx
    jb .invalid
.source_output_disjoint:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,[r12+neboc_quality_confidence_e_lineage_PARSE_SOURCE_OFFSET]
    lea r14,[r13+rax]
    mov r15,r13
    mov rbx,[r12+neboc_quality_confidence_e_lineage_PARSE_OUTPUT_OFFSET]
    mov qword [r12+neboc_quality_confidence_e_lineage_PARSE_ERROR_OFFSET_OFFSET],0
    mov qword [r12+neboc_quality_confidence_e_lineage_PARSE_DIAGNOSTIC_OFFSET],0
    mov qword [r12+neboc_quality_confidence_e_lineage_PARSE_CONSUMED_OFFSET],0
    mov qword [r12+neboc_quality_confidence_e_lineage_PARSE_CANONICAL_HASH_OFFSET],0
    mov qword [r12+neboc_quality_confidence_e_lineage_PARSE_FEATURE_MASK_OFFSET],0
    mov rdi,rbx
    mov ecx,neboc_quality_confidence_e_lineage_RESULT_QWORDS
    xor eax,eax
    rep stosq
    mov qword [rbx+neboc_quality_confidence_e_lineage_RESULT_FLAGS_OFFSET],NEBOC_RESULT_FLAG_CANONICAL
    lea rsi,[rel p0]
    mov ecx,p0n
    call match
    jc .lex
    call score
    jc .type
    mov [rbx+NEBOC_RESULT_DIRECT_QUALITY_OFFSET],rax
    call expect_comma
    jc .parse
    call score
    jc .type
    mov [rbx+NEBOC_RESULT_INHERITED_QUALITY_OFFSET],rax
    or qword [r12+neboc_quality_confidence_e_lineage_PARSE_FEATURE_MASK_OFFSET],NEBOC_FEATURE_QUALITY
    lea rsi,[rel p_conf]
    mov ecx,p_confn
    call match
    jc .parse
    call score
    jc .type
    mov [rbx+NEBOC_RESULT_DIRECT_CONFIDENCE_OFFSET],rax
    call expect_comma
    jc .parse
    call score
    jc .type
    mov [rbx+NEBOC_RESULT_INHERITED_CONFIDENCE_OFFSET],rax
    or qword [r12+neboc_quality_confidence_e_lineage_PARSE_FEATURE_MASK_OFFSET],NEBOC_FEATURE_CONFIDENCE
    lea rsi,[rel p_lineage]
    mov ecx,p_lineagen
    call match
    jc .parse
    call identity
    jc .type
    mov [rbx+NEBOC_RESULT_SOURCE_ID_OFFSET],rax
    call expect_comma
    jc .parse
    call identity
    jc .type
    mov [rbx+NEBOC_RESULT_TRANSFORM_ID_OFFSET],rax
    call expect_comma
    jc .parse
    call uint
    jc .type
    mov [rbx+NEBOC_RESULT_PARENT_HASH_OFFSET],rax
    or qword [r12+neboc_quality_confidence_e_lineage_PARSE_FEATURE_MASK_OFFSET],NEBOC_FEATURE_LINEAGE
    lea rsi,[rel p_require]
    mov ecx,p_requiren
    call match
    jc .parse
    call score
    jc .type
    mov [rbx+NEBOC_RESULT_MIN_QUALITY_OFFSET],rax
    call expect_comma
    jc .parse
    call score
    jc .type
    mov [rbx+NEBOC_RESULT_MIN_CONFIDENCE_OFFSET],rax
    or qword [r12+neboc_quality_confidence_e_lineage_PARSE_FEATURE_MASK_OFFSET],NEBOC_FEATURE_GATE
    lea rsi,[rel p_end]
    mov ecx,p_endn
    call match
    jc .parse
    cmp r15,r14
    je .finish
    cmp r15,r14
    jae .parse
    cmp byte [r15],10
    jne .parse
    inc r15
    cmp r15,r14
    jne .parse
.finish:
    mov rax,r15
    sub rax,r13
    mov [rbx+NEBOC_RESULT_STATEMENT_LENGTH_OFFSET],rax
    mov [r12+neboc_quality_confidence_e_lineage_PARSE_CONSUMED_OFFSET],rax
    mov rsi,rbx
    mov ecx,NEBOC_RESULT_HASHED_BYTES
    call hash
    mov [rbx+NEBOC_RESULT_SHAPE_HASH_OFFSET],rax
    mov [r12+neboc_quality_confidence_e_lineage_PARSE_CANONICAL_HASH_OFFSET],rax
    xor eax,eax
    jmp .done
.lex: mov eax,neboc_quality_confidence_e_lineage_DIAG_LEX_driver_cli_linux_x86_64
    jmp .failure
.parse: mov eax,neboc_quality_confidence_e_lineage_DIAG_PARSE_driver_cli_linux_x86_64
    jmp .failure
.type: mov eax,neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
.failure:
    mov [r12+neboc_quality_confidence_e_lineage_PARSE_DIAGNOSTIC_OFFSET],rax
    mov rdx,r15
    sub rdx,r13
    mov [r12+neboc_quality_confidence_e_lineage_PARSE_ERROR_OFFSET_OFFSET],rdx
    mov [r12+neboc_quality_confidence_e_lineage_PARSE_CONSUMED_OFFSET],rdx
    mov qword [r12+neboc_quality_confidence_e_lineage_PARSE_CANONICAL_HASH_OFFSET],0
    mov rdi,rbx
    mov ecx,neboc_quality_confidence_e_lineage_RESULT_QWORDS
    xor eax,eax
    rep stosq
    mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

expect_comma:
    cmp r15,r14
    jae .bad
    cmp byte [r15],','
    jne .bad
    inc r15
    clc
    ret
.bad: stc
    ret
match:
    mov rdx,r14
    sub rdx,r15
    cmp rdx,rcx
    jb .bad
.loop:
    test ecx,ecx
    jz .ok
    mov al,[r15]
    cmp al,[rsi]
    jne .bad
    inc r15
    inc rsi
    dec ecx
    jmp .loop
.ok: clc
    ret
.bad: stc
    ret
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
score:
    call uint
    jc .bad
    cmp rax,NEBOC_SCORE_SCALE
    ja .bad
    clc
    ret
.bad: stc
    ret
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
identity:
    call uint
    jc .bad
    test rax,rax
    jz .bad
    clc
    ret
.bad: stc
    ret
%undef call
uint:
    xor eax,eax
    xor ecx,ecx
.loop:
    cmp r15,r14
    jae .done
    movzx edx,byte [r15]
    sub edx,'0'
    cmp edx,9
    ja .done
    mov r8,0x1999999999999999
    cmp rax,r8
    ja .bad
    jne .accumulate
    cmp edx,5
    ja .bad
.accumulate:
    imul rax,rax,10
    add rax,rdx
    inc r15
    inc ecx
    jmp .loop
.done:
    test ecx,ecx
    jz .bad
    clc
    ret
.bad: stc
    ret
hash:
    mov rax,NEBOC_FNV1A64_OFFSET_BASIS
    mov r8,NEBOC_FNV1A64_PRIME
    xor edx,edx
.loop:
    cmp edx,ecx
    jae .done
    movzx r9d,byte [rsi+rdx]
    xor rax,r9
    imul rax,r8
    inc edx
    jmp .loop
.done: ret
section .note.GNU-stack noalloc noexec nowrite progbits
