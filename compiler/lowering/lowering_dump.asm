; Nebo Assembly — MF030 canonical continuation and lowering-plan dump
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/dependency/continuation/continuation_table.inc"
%include "compiler/lowering/function_lowering_plan.inc"
%include "compiler/lowering/lowering_dump.inc"

%macro EMIT_PREFIX 2
 lea rsi,[rel %1]
 mov ecx,%2
 rep movsb
%endmacro

section .rodata
header: db 'continuation-lowering-v1',10
c_i: db 'c='
c_f: db ' f='
c_p: db ' p='
c_u: db ' u='
c_e: db ' e='
c_n: db ' n='
c_o: db ' o='
c_d: db ' d='
c_s: db ' s='
c_q: db ' q='
c_a: db ' a='
c_b: db ' b='
c_x: db ' x='
c_y: db ' y='
c_g: db ' g='
c_h: db ' h='
p_i: db 'p='
p_f: db ' f='
p_o: db ' o='
p_n: db ' n='
p_c: db ' c='
p_x: db ' x='
p_g: db ' g='
p_h: db ' h='
o_i: db 'o='
o_p: db ' p='
o_k: db ' k='
o_n: db ' n='
o_r: db ' r='
o_d: db ' d='
o_c: db ' c='
o_t: db ' t='
o_s: db ' s='
o_h: db ' h='
hex_digits: db '0123456789abcdef'

section .text

NEBOC_ABI_FUNCTION neboc_lowering_dump
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov qword [r12+NEBOC_LOWERING_DUMP_LENGTH_OFFSET],0
 mov r13,[r12+NEBOC_LOWERING_DUMP_CONTINUATION_TABLE_OFFSET]
 mov r14,[r12+NEBOC_LOWERING_DUMP_PLAN_TABLE_OFFSET]
 mov r15,[r12+NEBOC_LOWERING_DUMP_BUFFER_OFFSET]
 mov r11,[r12+NEBOC_LOWERING_DUMP_CAPACITY_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 cmp qword [r13+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_FROZEN
 jne .invalid_source
 cmp qword [r14+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_FROZEN
 jne .invalid_source
 mov rax,[r13+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET]
 imul rax,NEBOC_LOWERING_DUMP_CONTINUATION_LINE_SIZE
 mov rdx,[r14+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET]
 imul rdx,NEBOC_LOWERING_DUMP_PLAN_LINE_SIZE
 add rax,rdx
 jc .limit
 mov rdx,[r14+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET]
 imul rdx,NEBOC_LOWERING_DUMP_OPERATION_LINE_SIZE
 add rax,rdx
 jc .limit
 add rax,NEBOC_LOWERING_DUMP_HEADER_SIZE
 jc .limit
 cmp r11,rax
 jb .limit
 mov rdi,r15
 EMIT_PREFIX header,NEBOC_LOWERING_DUMP_HEADER_SIZE
 xor ebx,ebx
 mov r10,[r13+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_DATA_OFFSET]
.cont_loop:
 cmp rbx,[r13+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET]
 jae .plan_start
 mov rax,rbx
 imul rax,NEBOC_CONTINUATION_DESCRIPTOR_SIZE
 lea r9,[r10+rax]
 EMIT_PREFIX c_i,2
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX c_f,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_FUNCTION_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX c_p,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_PRODUCER_PENDING_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX c_u,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_CONSUMER_PENDING_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX c_e,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_TRIGGER_EDGE_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX c_n,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_ENTRY_SYMBOL_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX c_o,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_SOURCE_ORDER_OFFSET]
 call write_hex16
 EMIT_PREFIX c_d,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_DOMAIN_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX c_s,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_STATE_OFFSET]
 call write_hex16
 EMIT_PREFIX c_q,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_COUNT_OFFSET]
 call write_hex16
 EMIT_PREFIX c_a,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_0_OFFSET]
 call write_hex16
 EMIT_PREFIX c_b,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_1_OFFSET]
 call write_hex16
 EMIT_PREFIX c_x,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_2_OFFSET]
 call write_hex16
 EMIT_PREFIX c_y,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_3_OFFSET]
 call write_hex16
 EMIT_PREFIX c_g,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_FLAGS_OFFSET]
 call write_hex16
 EMIT_PREFIX c_h,3
 mov rax,[r9+NEBOC_CONTINUATION_DESCRIPTOR_HASH_OFFSET]
 call write_hex16
 mov byte [rdi],10
 inc rdi
 inc rbx
 jmp .cont_loop
.plan_start:
 xor ebx,ebx
 mov r10,[r14+NEBOC_LOWERING_TABLE_PLAN_DATA_OFFSET]
.plan_loop:
 cmp rbx,[r14+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET]
 jae .operation_start
 mov rax,rbx
 imul rax,NEBOC_FUNCTION_PLAN_SIZE
 lea r9,[r10+rax]
 EMIT_PREFIX p_i,2
 mov rax,[r9+NEBOC_FUNCTION_PLAN_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_f,3
 mov rax,[r9+NEBOC_FUNCTION_PLAN_FUNCTION_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_o,3
 mov rax,[r9+NEBOC_FUNCTION_PLAN_SOURCE_ORDER_OFFSET]
 call write_hex16
 EMIT_PREFIX p_n,3
 mov rax,[r9+NEBOC_FUNCTION_PLAN_OPERATION_COUNT_OFFSET]
 call write_hex16
 EMIT_PREFIX p_c,3
 mov rax,[r9+NEBOC_FUNCTION_PLAN_CONTINUATION_COUNT_OFFSET]
 call write_hex16
 EMIT_PREFIX p_x,3
 mov rax,[r9+NEBOC_FUNCTION_PLAN_EXIT_PATH_COUNT_OFFSET]
 call write_hex16
 EMIT_PREFIX p_g,3
 mov rax,[r9+NEBOC_FUNCTION_PLAN_FLAGS_OFFSET]
 call write_hex16
 EMIT_PREFIX p_h,3
 mov rax,[r9+NEBOC_FUNCTION_PLAN_HASH_OFFSET]
 call write_hex16
 mov byte [rdi],10
 inc rdi
 inc rbx
 jmp .plan_loop
.operation_start:
 xor ebx,ebx
 mov r10,[r14+NEBOC_LOWERING_TABLE_OPERATION_DATA_OFFSET]
.operation_loop:
 cmp rbx,[r14+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET]
 jae .done_dump
 mov rax,rbx
 imul rax,NEBOC_LOWERING_OPERATION_SIZE
 lea r9,[r10+rax]
 EMIT_PREFIX o_i,2
 mov rax,[r9+NEBOC_LOWERING_OPERATION_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX o_p,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_PLAN_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX o_k,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_KIND_OFFSET]
 call write_hex16
 EMIT_PREFIX o_n,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_SOURCE_NODE_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX o_r,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_ROUTE_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX o_d,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_PENDING_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX o_c,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_CONTINUATION_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX o_t,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_RUNTIME_CONTRACT_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX o_s,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_SOURCE_ORDER_OFFSET]
 call write_hex16
 EMIT_PREFIX o_h,3
 mov rax,[r9+NEBOC_LOWERING_OPERATION_HASH_OFFSET]
 call write_hex16
 mov byte [rdi],10
 inc rdi
 inc rbx
 jmp .operation_loop
.done_dump:
 mov rax,rdi
 sub rax,r15
 mov [r12+NEBOC_LOWERING_DUMP_LENGTH_OFFSET],rax
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
