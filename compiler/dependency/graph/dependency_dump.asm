; Nebo Assembly — MF029 canonical Pending/dependency dump
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/dependency/pending/pending_table.inc"
%include "compiler/dependency/graph/dependency_graph.inc"
%include "compiler/dependency/graph/dependency_dump.inc"

%macro EMIT_PREFIX 2
 lea rsi,[rel %1]
 mov ecx,%2
 rep movsb
%endmacro

section .rodata
header: db 'pending-dependencies-v1',10
p_p: db 'p='
p_s: db ' s='
p_r: db ' r='
p_x: db ' x='
p_o: db ' o='
p_e: db ' e='
p_f: db ' f='
p_h: db ' h='
e_e: db 'e='
e_p: db ' p='
e_c: db ' c='
e_n: db ' n='
e_s: db ' s='
e_o: db ' o='
e_k: db ' k='
e_q: db ' q='
e_a: db ' a='
e_b: db ' b='
e_d: db ' d='
e_z: db ' z='
e_f: db ' f='
e_h: db ' h='
hex_digits: db '0123456789abcdef'

section .text

; dependency_dump(request*)
NEBOC_ABI_FUNCTION neboc_dependency_dump
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov qword [r12+NEBOC_DEPENDENCY_DUMP_LENGTH_OFFSET],0
 mov r13,[r12+NEBOC_DEPENDENCY_DUMP_PENDING_TABLE_OFFSET]
 mov r14,[r12+NEBOC_DEPENDENCY_DUMP_GRAPH_OFFSET]
 mov r15,[r12+NEBOC_DEPENDENCY_DUMP_BUFFER_OFFSET]
 mov r11,[r12+NEBOC_DEPENDENCY_DUMP_CAPACITY_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 cmp qword [r13+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_FROZEN
 jne .invalid_source
 cmp qword [r14+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_FROZEN
 jne .invalid_source
 mov rax,[r13+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 imul rax,NEBOC_DEPENDENCY_DUMP_PENDING_LINE_SIZE
 mov rdx,[r14+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 imul rdx,NEBOC_DEPENDENCY_DUMP_EDGE_LINE_SIZE
 add rax,rdx
 jc .limit
 add rax,NEBOC_DEPENDENCY_DUMP_HEADER_SIZE
 jc .limit
 cmp r11,rax
 jb .limit
 mov rdi,r15
 EMIT_PREFIX header,NEBOC_DEPENDENCY_DUMP_HEADER_SIZE
 xor ebx,ebx
 mov r10,[r13+NEBOC_PENDING_TABLE_DATA_OFFSET]
.pending_loop:
 cmp rbx,[r13+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 jae .edge_start
 mov rax,rbx
 imul rax,NEBOC_PENDING_RECORD_SIZE
 lea r9,[r10+rax]
 EMIT_PREFIX p_p,2
 mov rax,[r9+NEBOC_PENDING_RECORD_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_s,3
 mov rax,[r9+NEBOC_PENDING_RECORD_PRODUCER_SCAN_NODE_OFFSET]
 call write_hex16
 EMIT_PREFIX p_r,3
 mov rax,[r9+NEBOC_PENDING_RECORD_ROUTE_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_x,3
 mov rax,[r9+NEBOC_PENDING_RECORD_INTRINSIC_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_o,3
 mov rax,[r9+NEBOC_PENDING_RECORD_SOURCE_ORDER_OFFSET]
 call write_hex16
 EMIT_PREFIX p_e,3
 mov rax,[r9+NEBOC_PENDING_RECORD_EDGE_COUNT_OFFSET]
 call write_hex16
 EMIT_PREFIX p_f,3
 mov rax,[r9+NEBOC_PENDING_RECORD_FLAGS_OFFSET]
 call write_hex16
 EMIT_PREFIX p_h,3
 mov rax,[r9+NEBOC_PENDING_RECORD_HASH_OFFSET]
 call write_hex16
 mov byte [rdi],10
 inc rdi
 inc rbx
 jmp .pending_loop

.edge_start:
 xor ebx,ebx
 mov r10,[r14+NEBOC_DEPENDENCY_GRAPH_EDGE_DATA_OFFSET]
.edge_loop:
 cmp rbx,[r14+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 jae .done_dump
 mov rax,rbx
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea r9,[r10+rax]
 EMIT_PREFIX e_e,2
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX e_p,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_PRODUCER_PENDING_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX e_c,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CONSUMER_PENDING_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX e_n,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CONSUMER_NODE_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX e_s,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CONSUMER_SYMBOL_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX e_o,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_SOURCE_ORDER_OFFSET]
 call write_hex16
 EMIT_PREFIX e_k,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CONTINUATION_SEED_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX e_q,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CAPTURE_COUNT_OFFSET]
 call write_hex16
 EMIT_PREFIX e_a,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CAPTURE_0_OFFSET]
 call write_hex16
 EMIT_PREFIX e_b,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CAPTURE_1_OFFSET]
 call write_hex16
 EMIT_PREFIX e_d,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CAPTURE_2_OFFSET]
 call write_hex16
 EMIT_PREFIX e_z,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_CAPTURE_3_OFFSET]
 call write_hex16
 EMIT_PREFIX e_f,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_FLAGS_OFFSET]
 call write_hex16
 EMIT_PREFIX e_h,3
 mov rax,[r9+NEBOC_DEPENDENCY_EDGE_HASH_OFFSET]
 call write_hex16
 mov byte [rdi],10
 inc rdi
 inc rbx
 jmp .edge_loop

.done_dump:
 mov rax,rdi
 sub rax,r15
 mov [r12+NEBOC_DEPENDENCY_DUMP_LENGTH_OFFSET],rax
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

write_hex16:
 mov rdx,rax
 mov ecx,16
.hex_loop:
 mov r8,rdx
 shr r8,60
 lea rax,[rel hex_digits]
 mov r8b,[rax+r8]
 mov [rdi],r8b
 inc rdi
 shl rdx,4
 dec ecx
 jnz .hex_loop
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
