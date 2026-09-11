; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F02 native graph inference and explain-path tests.
bits 64
default rel
%include "compiler/semantic/effects/effect_inference.inc"

extern nebo_effect_infer

section .bss
align 16
request resb NEBO_EFFECT_INFER_REQUEST_SIZE
request2 resb NEBO_EFFECT_INFER_REQUEST_SIZE
nodes resb NEBO_EFFECT_NODE_SIZE*4
edges resq 4
outputs resb NEBO_EFFECT_OUTPUT_SIZE*4
outputs2 resb NEBO_EFFECT_OUTPUT_SIZE*4
trace resq 4
trace2 resq 4

section .text
prepare:
    lea rdi,[request]
    mov ecx,NEBO_EFFECT_INFER_REQUEST_QWORDS
    xor eax,eax
    rep stosq
    lea rdi,[nodes]
    mov ecx,(NEBO_EFFECT_NODE_SIZE*4)/8
    rep stosq
    lea rdi,[outputs]
    mov ecx,(NEBO_EFFECT_OUTPUT_SIZE*4)/8
    rep stosq
    lea rdi,[trace]
    mov ecx,4
    rep stosq

    lea rax,[nodes]
    mov [request+NEBO_EFFECT_INFER_NODES_OFFSET],rax
    mov qword [request+NEBO_EFFECT_INFER_NODE_COUNT_OFFSET],4
    lea rax,[edges]
    mov [request+NEBO_EFFECT_INFER_EDGES_OFFSET],rax
    mov qword [request+NEBO_EFFECT_INFER_EDGE_COUNT_OFFSET],3
    lea rax,[outputs]
    mov [request+NEBO_EFFECT_INFER_OUTPUTS_OFFSET],rax
    mov qword [request+NEBO_EFFECT_INFER_OUTPUT_CAPACITY_OFFSET],4
    lea rax,[trace]
    mov [request+NEBO_EFFECT_INFER_TRACE_OFFSET],rax
    mov qword [request+NEBO_EFFECT_INFER_TRACE_CAPACITY_OFFSET],4
    mov qword [request+NEBO_EFFECT_INFER_EXPLAIN_NODE_OFFSET],0
    mov qword [request+NEBO_EFFECT_INFER_EXPLAIN_EFFECT_OFFSET],NEBO_EFFECT_AI_TOOL

    ; function 0 -> module 1, closure 2
    mov qword [nodes+NEBO_EFFECT_NODE_DIRECT_OFFSET],NEBO_EFFECT_MUTATION
    mov qword [nodes+NEBO_EFFECT_NODE_DECLARED_OFFSET],NEBO_EFFECT_MUTATION | NEBO_EFFECT_FILE_READ | NEBO_EFFECT_CONSOLE_WRITE | NEBO_EFFECT_AI_TOOL
    mov qword [nodes+NEBO_EFFECT_NODE_EDGE_OFFSET_OFFSET],0
    mov qword [nodes+NEBO_EFFECT_NODE_EDGE_COUNT_OFFSET],2
    mov qword [nodes+NEBO_EFFECT_NODE_KIND_OFFSET],NEBO_EFFECT_NODE_FUNCTION
    ; module 1 -> tool 3
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_DIRECT_OFFSET],NEBO_EFFECT_FILE_READ
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_DECLARED_OFFSET],NEBO_EFFECT_FILE_READ | NEBO_EFFECT_AI_TOOL
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_EDGE_OFFSET_OFFSET],2
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_EDGE_COUNT_OFFSET],1
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_KIND_OFFSET],NEBO_EFFECT_NODE_MODULE
    ; closure 2
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*2+NEBO_EFFECT_NODE_DIRECT_OFFSET],NEBO_EFFECT_CONSOLE_WRITE
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*2+NEBO_EFFECT_NODE_DECLARED_OFFSET],NEBO_EFFECT_CONSOLE_WRITE
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*2+NEBO_EFFECT_NODE_EDGE_OFFSET_OFFSET],3
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*2+NEBO_EFFECT_NODE_KIND_OFFSET],NEBO_EFFECT_NODE_CLOSURE
    ; tool 3
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*3+NEBO_EFFECT_NODE_DIRECT_OFFSET],NEBO_EFFECT_AI_TOOL
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*3+NEBO_EFFECT_NODE_DECLARED_OFFSET],NEBO_EFFECT_AI_TOOL
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*3+NEBO_EFFECT_NODE_EDGE_OFFSET_OFFSET],3
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*3+NEBO_EFFECT_NODE_KIND_OFFSET],NEBO_EFFECT_NODE_TOOL
    mov qword [edges],1
    mov qword [edges+8],2
    mov qword [edges+16],3
    ret

evaluate:
    lea rdi,[request]
    jmp nebo_effect_infer

global _start
_start:
    ; 1. Null requests are rejected.
    xor edi,edi
    call nebo_effect_infer
    cmp eax,NEBO_EFFECT_INFER_STATUS_INVALID_ARGUMENT
    jne .fail1

    ; 2-11. Functions/modules/closures/tools compose transitively.
    call prepare
    call evaluate
    test eax,eax
    jnz .fail2
    cmp qword [outputs+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET],NEBO_EFFECT_MUTATION | NEBO_EFFECT_FILE_READ | NEBO_EFFECT_CONSOLE_WRITE | NEBO_EFFECT_AI_TOOL
    jne .fail3
    cmp qword [outputs+NEBO_EFFECT_OUTPUT_SIZE+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET],NEBO_EFFECT_FILE_READ | NEBO_EFFECT_AI_TOOL
    jne .fail4
    cmp qword [outputs+NEBO_EFFECT_OUTPUT_SIZE*2+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET],NEBO_EFFECT_CONSOLE_WRITE
    jne .fail5
    cmp qword [outputs+NEBO_EFFECT_OUTPUT_SIZE*3+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET],NEBO_EFFECT_AI_TOOL
    jne .fail6
    cmp qword [request+NEBO_EFFECT_INFER_TRACE_COUNT_OFFSET],3
    jne .fail7
    cmp qword [trace],0
    jne .fail8
    cmp qword [trace+8],1
    jne .fail9
    cmp qword [trace+16],3
    jne .fail10
    cmp qword [request+NEBO_EFFECT_INFER_HASH_OFFSET],0
    je .fail11

    ; 12-15. An undeclared transitive effect is exact and typed.
    call prepare
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_DECLARED_OFFSET],NEBO_EFFECT_FILE_READ
    call evaluate
    cmp eax,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jne .fail12
    cmp qword [request+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_UNDECLARED
    jne .fail13
    cmp qword [request+NEBO_EFFECT_INFER_ERROR_NODE_OFFSET],1
    jne .fail14
    cmp qword [request+NEBO_EFFECT_INFER_ERROR_EFFECT_OFFSET],NEBO_EFFECT_AI_TOOL
    jne .fail15

    ; 16-18. Unknown effects fail before caller output mutation.
    call prepare
    mov qword [outputs],0x7788
    mov qword [nodes+NEBO_EFFECT_NODE_SIZE*2],0x4000
    call evaluate
    cmp eax,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jne .fail16
    cmp qword [request+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_UNKNOWN
    jne .fail17
    cmp qword [outputs],0x7788
    jne .fail18

    ; 19-20. Invalid callees are graph errors and failure-atomic.
    call prepare
    mov qword [outputs],0x8899
    mov qword [edges],4
    call evaluate
    cmp eax,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jne .fail19
    cmp qword [outputs],0x8899
    jne .fail20

    ; 21-22. Explain requests for absent effects are incompatible, not hidden.
    call prepare
    mov qword [request+NEBO_EFFECT_INFER_EXPLAIN_EFFECT_OFFSET],NEBO_EFFECT_NETWORK
    call evaluate
    cmp eax,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jne .fail21
    cmp qword [request+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_INCOMPATIBLE
    jne .fail22

    ; 23. Output capacity is bounded before writes.
    call prepare
    mov qword [request+NEBO_EFFECT_INFER_OUTPUT_CAPACITY_OFFSET],3
    call evaluate
    cmp eax,NEBO_EFFECT_INFER_STATUS_LIMIT
    jne .fail23

    ; 24-26. An identical request produces identical outputs, trace and hash.
    call prepare
    call evaluate
    test eax,eax
    jnz .fail24
    lea rsi,[request]
    lea rdi,[request2]
    mov ecx,NEBO_EFFECT_INFER_REQUEST_QWORDS
    rep movsq
    lea rax,[outputs2]
    mov [request2+NEBO_EFFECT_INFER_OUTPUTS_OFFSET],rax
    lea rax,[trace2]
    mov [request2+NEBO_EFFECT_INFER_TRACE_OFFSET],rax
    lea rdi,[request2]
    call nebo_effect_infer
    test eax,eax
    jnz .fail24
    lea rsi,[outputs]
    lea rdi,[outputs2]
    mov ecx,(NEBO_EFFECT_OUTPUT_SIZE*4)/8
    repe cmpsq
    jne .fail25
    lea rsi,[trace]
    lea rdi,[trace2]
    mov ecx,3
    repe cmpsq
    jne .fail26
    mov rax,[request+NEBO_EFFECT_INFER_HASH_OFFSET]
    cmp rax,[request2+NEBO_EFFECT_INFER_HASH_OFFSET]
    jne .fail26

    xor edi,edi
    jmp .exit
%assign i 1
%rep 26
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
