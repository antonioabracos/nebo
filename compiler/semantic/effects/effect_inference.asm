; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F02 bounded transitive effect inference and explain path.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/effects/effect_inference.inc"

section .text

; rdi = aligned pointer to a 128-byte request/result.  Node and edge buffers
; are validated completely before outputs or trace are mutated.
NEBOC_ABI_FUNCTION nebo_effect_infer
    test rdi,rdi
    jz .bare_argument
    test rdi,NEBO_EFFECT_INFER_ALIGNMENT-1
    jnz .bare_argument
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi

    mov qword [r12+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],0
    mov qword [r12+NEBO_EFFECT_INFER_ERROR_NODE_OFFSET],0
    mov qword [r12+NEBO_EFFECT_INFER_ERROR_EFFECT_OFFSET],0
    mov qword [r12+NEBO_EFFECT_INFER_TRACE_COUNT_OFFSET],0
    mov qword [r12+NEBO_EFFECT_INFER_PASSES_OFFSET],0
    mov qword [r12+NEBO_EFFECT_INFER_HASH_OFFSET],0

    mov r13,[r12+NEBO_EFFECT_INFER_NODES_OFFSET]
    mov r15,[r12+NEBO_EFFECT_INFER_NODE_COUNT_OFFSET]
    mov r14,[r12+NEBO_EFFECT_INFER_OUTPUTS_OFFSET]
    test r13,r13
    jz .argument
    test r13,7
    jnz .argument
    test r14,r14
    jz .argument
    test r14,7
    jnz .argument
    test r15,r15
    jz .argument
    cmp r15,NEBO_EFFECT_INFER_MAX_NODES
    ja .limit
    cmp [r12+NEBO_EFFECT_INFER_OUTPUT_CAPACITY_OFFSET],r15
    jb .limit
    cmp qword [r12+NEBO_EFFECT_INFER_EDGE_COUNT_OFFSET],NEBO_EFFECT_INFER_MAX_EDGES
    ja .limit
    mov rax,[r12+NEBO_EFFECT_INFER_EDGES_OFFSET]
    test rax,rax
    jz .argument
    test rax,7
    jnz .argument
    mov rax,[r12+NEBO_EFFECT_INFER_TRACE_OFFSET]
    test rax,rax
    jz .argument
    test rax,7
    jnz .argument
    cmp [r12+NEBO_EFFECT_INFER_TRACE_CAPACITY_OFFSET],r15
    jb .limit
    mov rax,[r12+NEBO_EFFECT_INFER_EXPLAIN_NODE_OFFSET]
    cmp rax,r15
    jae .graph
    mov rax,[r12+NEBO_EFFECT_INFER_EXPLAIN_EFFECT_OFFSET]
    test rax,rax
    jz .graph
    mov rcx,rax
    dec rcx
    test rax,rcx
    jnz .graph
    test rax,~NEBO_EFFECT_MASK
    jnz .unknown_query

    ; Validate every node, effect mask, edge slice and callee index first.
    xor ecx,ecx
.validate_node:
    cmp rcx,r15
    jae .initialize
    mov rax,rcx
    imul rax,NEBO_EFFECT_NODE_SIZE
    lea r11,[r13+rax]
    mov r8,[r11+NEBO_EFFECT_NODE_DIRECT_OFFSET]
    or r8,[r11+NEBO_EFFECT_NODE_DECLARED_OFFSET]
    mov rax,r8
    and rax,~NEBO_EFFECT_MASK
    jnz .unknown_node
    mov rax,[r11+NEBO_EFFECT_NODE_KIND_OFFSET]
    cmp rax,NEBO_EFFECT_NODE_FUNCTION
    jb .graph_node
    cmp rax,NEBO_EFFECT_NODE_TOOL
    ja .graph_node
    mov rax,[r11+NEBO_EFFECT_NODE_EDGE_OFFSET_OFFSET]
    mov rdx,[r11+NEBO_EFFECT_NODE_EDGE_COUNT_OFFSET]
    mov r8,rax
    add r8,rdx
    jc .graph_node
    cmp r8,[r12+NEBO_EFFECT_INFER_EDGE_COUNT_OFFSET]
    ja .graph_node
    xor r9d,r9d
.validate_edge:
    cmp r9,rdx
    jae .validate_next
    mov r8,[r12+NEBO_EFFECT_INFER_EDGES_OFFSET]
    mov rsi,rax
    add rsi,r9
    mov r8,[r8+rsi*8]
    cmp r8,r15
    jae .graph_node
    inc r9
    jmp .validate_edge
.validate_next:
    inc rcx
    jmp .validate_node

.initialize:
    xor ecx,ecx
.initialize_loop:
    cmp rcx,r15
    jae .iterate
    mov rax,rcx
    imul rax,NEBO_EFFECT_NODE_SIZE
    mov r8,[r13+rax+NEBO_EFFECT_NODE_DIRECT_OFFSET]
    mov rdx,rcx
    imul rdx,NEBO_EFFECT_OUTPUT_SIZE
    mov [r14+rdx+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET],r8
    mov qword [r14+rdx+NEBO_EFFECT_OUTPUT_MISSING_OFFSET],0
    mov qword [r14+rdx+NEBO_EFFECT_OUTPUT_PARENT_OFFSET],0
    test r8,[r12+NEBO_EFFECT_INFER_EXPLAIN_EFFECT_OFFSET]
    jz .initialize_next
    lea r8,[rcx+1]
    mov [r14+rdx+NEBO_EFFECT_OUTPUT_PARENT_OFFSET],r8
.initialize_next:
    inc rcx
    jmp .initialize_loop

.iterate:
    inc qword [r12+NEBO_EFFECT_INFER_PASSES_OFFSET]
    xor r11d,r11d                         ; changed flag
    xor ecx,ecx
.iterate_node:
    cmp rcx,r15
    jae .iterate_done
    mov rax,rcx
    imul rax,NEBO_EFFECT_NODE_SIZE
    lea rsi,[r13+rax]
    mov rdx,rcx
    imul rdx,NEBO_EFFECT_OUTPUT_SIZE
    lea rdi,[r14+rdx]
    mov r8,[rdi+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET]
    mov rbx,r8
    mov rax,[rsi+NEBO_EFFECT_NODE_EDGE_OFFSET_OFFSET]
    mov rdx,[rsi+NEBO_EFFECT_NODE_EDGE_COUNT_OFFSET]
    xor r9d,r9d
.union_edges:
    cmp r9,rdx
    jae .union_done
    mov rsi,[r12+NEBO_EFFECT_INFER_EDGES_OFFSET]
    mov r10,rax
    add r10,r9
    mov r10,[rsi+r10*8]
    imul r10,NEBO_EFFECT_OUTPUT_SIZE
    or rbx,[r14+r10+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET]
    inc r9
    jmp .union_edges
.union_done:
    cmp rbx,r8
    je .iterate_next
    ; If the requested atom arrived this pass, freeze its first deterministic
    ; callee as a temporal parent. It can therefore never form a trace cycle.
    mov r10,[r12+NEBO_EFFECT_INFER_EXPLAIN_EFFECT_OFFSET]
    test r8,r10
    jnz .store_union
    test rbx,r10
    jz .store_union
    mov rax,rcx
    imul rax,NEBO_EFFECT_NODE_SIZE
    lea rsi,[r13+rax]
    mov rax,[rsi+NEBO_EFFECT_NODE_EDGE_OFFSET_OFFSET]
    mov rdx,[rsi+NEBO_EFFECT_NODE_EDGE_COUNT_OFFSET]
    xor r9d,r9d
.find_parent:
    cmp r9,rdx
    jae .trace_invariant
    mov rsi,[r12+NEBO_EFFECT_INFER_EDGES_OFFSET]
    mov r8,rax
    add r8,r9
    mov r8,[rsi+r8*8]
    mov rsi,r8
    imul rsi,NEBO_EFFECT_OUTPUT_SIZE
    test [r14+rsi+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET],r10
    jnz .parent_found
    inc r9
    jmp .find_parent
.parent_found:
    inc r8
    mov [rdi+NEBO_EFFECT_OUTPUT_PARENT_OFFSET],r8
.store_union:
    mov [rdi+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET],rbx
    mov r11d,1
.iterate_next:
    inc rcx
    jmp .iterate_node
.iterate_done:
    test r11d,r11d
    jz .check_declarations
    mov rax,[r12+NEBO_EFFECT_INFER_PASSES_OFFSET]
    cmp rax,r15
    jb .iterate
    jmp .graph

.check_declarations:
    xor ecx,ecx
.declaration_loop:
    cmp rcx,r15
    jae .build_trace
    mov rax,rcx
    imul rax,NEBO_EFFECT_NODE_SIZE
    mov r8,[r13+rax+NEBO_EFFECT_NODE_DECLARED_OFFSET]
    not r8
    mov rdx,rcx
    imul rdx,NEBO_EFFECT_OUTPUT_SIZE
    and r8,[r14+rdx+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET]
    mov [r14+rdx+NEBO_EFFECT_OUTPUT_MISSING_OFFSET],r8
    test r8,r8
    jnz .undeclared
    inc rcx
    jmp .declaration_loop

.build_trace:
    mov rcx,[r12+NEBO_EFFECT_INFER_EXPLAIN_NODE_OFFSET]
    mov r10,[r12+NEBO_EFFECT_INFER_TRACE_OFFSET]
    xor r9d,r9d
.trace_loop:
    cmp r9,r15
    jae .trace_invariant
    mov [r10+r9*8],rcx
    inc r9
    mov rdx,rcx
    imul rdx,NEBO_EFFECT_OUTPUT_SIZE
    mov r8,[r14+rdx+NEBO_EFFECT_OUTPUT_PARENT_OFFSET]
    test r8,r8
    jz .incompatible
    lea rax,[rcx+1]
    cmp r8,rax
    je .trace_done
    dec r8
    mov rcx,r8
    jmp .trace_loop
.trace_done:
    mov [r12+NEBO_EFFECT_INFER_TRACE_COUNT_OFFSET],r9
    xor ebx,ebx
    jmp .hash

.unknown_query:
    mov qword [r12+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_UNKNOWN
    mov rax,[r12+NEBO_EFFECT_INFER_EXPLAIN_EFFECT_OFFSET]
    and rax,~NEBO_EFFECT_MASK
    mov [r12+NEBO_EFFECT_INFER_ERROR_EFFECT_OFFSET],rax
    mov eax,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jmp .done
.unknown_node:
    mov qword [r12+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_UNKNOWN
    mov [r12+NEBO_EFFECT_INFER_ERROR_NODE_OFFSET],rcx
    mov rax,r8
    and rax,~NEBO_EFFECT_MASK
    mov [r12+NEBO_EFFECT_INFER_ERROR_EFFECT_OFFSET],rax
    mov eax,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jmp .done
.graph_node:
    mov [r12+NEBO_EFFECT_INFER_ERROR_NODE_OFFSET],rcx
.graph:
    mov qword [r12+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_GRAPH
    mov eax,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jmp .done
.undeclared:
    mov qword [r12+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_UNDECLARED
    mov [r12+NEBO_EFFECT_INFER_ERROR_NODE_OFFSET],rcx
    mov [r12+NEBO_EFFECT_INFER_ERROR_EFFECT_OFFSET],r8
    mov ebx,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jmp .hash
.incompatible:
    mov qword [r12+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_INCOMPATIBLE
    mov [r12+NEBO_EFFECT_INFER_ERROR_NODE_OFFSET],rcx
    mov rax,[r12+NEBO_EFFECT_INFER_EXPLAIN_EFFECT_OFFSET]
    mov [r12+NEBO_EFFECT_INFER_ERROR_EFFECT_OFFSET],rax
    mov [r12+NEBO_EFFECT_INFER_TRACE_COUNT_OFFSET],r9
    mov ebx,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE
    jmp .hash
.trace_invariant:
    mov qword [r12+NEBO_EFFECT_INFER_DIAGNOSTIC_OFFSET],NEBO_EFFECT_INFER_DIAG_TRACE
    mov ebx,NEBO_EFFECT_INFER_STATUS_INVALID_SOURCE

.hash:
    ; Successful/semantic results hash normalized outputs and the exact trace,
    ; never caller addresses or ambient process state.
    mov rax,NEBO_EFFECT_INFER_FNV1A64_OFFSET_BASIS
    mov r8,NEBO_EFFECT_INFER_FNV1A64_PRIME
    mov rdx,r15
    imul rdx,NEBO_EFFECT_OUTPUT_SIZE
    xor ecx,ecx
.hash_outputs:
    cmp rcx,rdx
    jae .hash_trace_start
    movzx esi,byte [r14+rcx]
    xor rax,rsi
    imul rax,r8
    inc rcx
    jmp .hash_outputs
.hash_trace_start:
    mov rsi,[r12+NEBO_EFFECT_INFER_TRACE_OFFSET]
    mov rdx,[r12+NEBO_EFFECT_INFER_TRACE_COUNT_OFFSET]
    shl rdx,3
    xor ecx,ecx
.hash_trace:
    cmp rcx,rdx
    jae .hash_done
    movzx edi,byte [rsi+rcx]
    xor rax,rdi
    imul rax,r8
    inc rcx
    jmp .hash_trace
.hash_done:
    mov [r12+NEBO_EFFECT_INFER_HASH_OFFSET],rax
    mov eax,ebx
    jmp .done

.argument:
    mov eax,NEBO_EFFECT_INFER_STATUS_INVALID_ARGUMENT
    jmp .done
.limit:
    mov eax,NEBO_EFFECT_INFER_STATUS_LIMIT
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.bare_argument:
    mov eax,NEBO_EFFECT_INFER_STATUS_INVALID_ARGUMENT
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
