; Nebo Assembly — MF025 deterministic Validated AST semantic dump
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/database/control_flow_table.inc"
%include "compiler/semantic/database/constant_value_table.inc"
%include "compiler/semantic/database/semantic_database.inc"
%include "compiler/semantic/dump/semantic_dump.inc"

%macro EMIT_PREFIX 2
 lea rsi,[rel %1]
 mov ecx,%2
 rep movsb
%endmacro

%macro EMIT_RAW_TABLE 3
 EMIT_PREFIX %1,%2
 mov r8,[r12+%3]
 xor eax,eax
 test r8,r8
 jz %%write
 mov rax,[r8+rbx*8]
%%write:
 call write_hex16
%endmacro

section .rodata
header: db 'validated-ast-v1',10
p_n: db 'n='
p_m: db ' m='
p_t: db ' t='
p_s: db ' s='
p_e: db ' e='
p_c: db ' c='
p_b: db ' b='
p_r: db ' r='
p_d: db ' d='
p_f: db ' f='
p_k: db ' k='
p_v: db ' v='
hex_digits: db '0123456789abcdef'

section .text

; semantic_dump(database*, buffer*, capacity, out_length*)
; Canonical text, fixed-width hexadecimal, source NodeId order, no pointers.
NEBOC_ABI_FUNCTION neboc_semantic_dump
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 test r15,r15
 jz .invalid
 mov qword [r15],0
 cmp qword [r12+NEBOC_SEMANTIC_DATABASE_STATE_OFFSET],NEBOC_SEMANTIC_DATABASE_STATE_VALIDATED
 jne .invalid_source
 mov r10,[r12+NEBOC_SEMANTIC_DATABASE_NODE_COUNT_OFFSET]
 test r10,r10
 jz .invalid
 mov rax,r10
 imul rax,NEBOC_SEMANTIC_DUMP_LINE_SIZE
 add rax,NEBOC_SEMANTIC_DUMP_HEADER_SIZE
 cmp r14,rax
 jb .limit
 mov r11,rax
 mov rdi,r13
 EMIT_PREFIX header,NEBOC_SEMANTIC_DUMP_HEADER_SIZE
 xor ebx,ebx
.node_loop:
 cmp rbx,r10
 jae .done_dump
 EMIT_PREFIX p_n,2
 lea rax,[rbx+1]
 call write_hex16
 EMIT_RAW_TABLE p_m,3,NEBOC_SEMANTIC_DATABASE_REQUIRED_MASKS_OFFSET
 EMIT_RAW_TABLE p_t,3,NEBOC_SEMANTIC_DATABASE_NODE_TYPES_OFFSET
 EMIT_RAW_TABLE p_s,3,NEBOC_SEMANTIC_DATABASE_NODE_SYMBOLS_OFFSET
 EMIT_RAW_TABLE p_e,3,NEBOC_SEMANTIC_DATABASE_NODE_EFFECTS_OFFSET
 EMIT_RAW_TABLE p_c,3,NEBOC_SEMANTIC_DATABASE_NODE_CALLS_OFFSET
 EMIT_RAW_TABLE p_b,3,NEBOC_SEMANTIC_DATABASE_NODE_BEHAVIORS_OFFSET
 EMIT_RAW_TABLE p_r,3,NEBOC_SEMANTIC_DATABASE_NODE_ROUTES_OFFSET
 EMIT_RAW_TABLE p_d,3,NEBOC_SEMANTIC_DATABASE_NODE_DEPENDENCIES_OFFSET

 EMIT_PREFIX p_f,3
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_CONTROL_TABLE_OFFSET]
 xor eax,eax
 test r8,r8
 jz .flow_write
 mov r9,[r8+NEBOC_CONTROL_FLOW_TABLE_DATA_OFFSET]
 test r9,r9
 jz .flow_write
 mov rax,[r9+rbx*8]
.flow_write:
 call write_hex16

 EMIT_PREFIX p_k,3
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_CONSTANT_TABLE_OFFSET]
 xor eax,eax
 test r8,r8
 jz .constant_write
 mov r9,[r8+NEBOC_CONSTANT_VALUE_TABLE_VALUES_OFFSET]
 test r9,r9
 jz .constant_write
 mov rax,[r9+rbx*8]
.constant_write:
 call write_hex16

 EMIT_PREFIX p_v,3
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_CONSTANT_TABLE_OFFSET]
 xor eax,eax
 test r8,r8
 jz .flag_write
 mov r9,[r8+NEBOC_CONSTANT_VALUE_TABLE_FLAGS_OFFSET]
 test r9,r9
 jz .flag_write
 mov rax,[r9+rbx*8]
.flag_write:
 call write_hex16
 mov byte [rdi],10
 inc rdi
 inc rbx
 jmp .node_loop
.done_dump:
 mov [r15],r11
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

; write_hex16(value=RAX, destination=RDI), advances RDI.
write_hex16:
 mov rdx,rax
 mov ecx,16
.hex_loop:
 mov r8,rdx
 shr r8,60
 lea r9,[rel hex_digits]
 mov r8b,[r9+r8]
 mov [rdi],r8b
 inc rdi
 shl rdx,4
 dec ecx
 jnz .hex_loop
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
