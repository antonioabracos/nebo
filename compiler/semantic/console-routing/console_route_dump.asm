; Nebo Assembly — MF027 canonical deterministic Console route dump
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/console-routing/console_routing_table.inc"
%include "compiler/semantic/console-routing/console_route_dump.inc"

%macro EMIT_PREFIX 2
 lea rsi,[rel %1]
 mov ecx,%2
 rep movsb
%endmacro

section .rodata
header: db 'console-routes-v1',10
p_r: db 'r='
p_m: db ' m='
p_i: db ' i='
p_k: db ' k='
p_v: db ' v='
p_c: db ' c='
p_s: db ' s='
p_b: db ' b='
p_o: db ' o='
p_p: db ' p='
p_n: db ' n='
p_ci: db ' x='
p_si: db ' y='
p_f: db ' f='
p_h: db ' h='
hex_digits: db '0123456789abcdef'

section .text

; console_route_dump(request*)
NEBOC_ABI_FUNCTION neboc_console_route_dump
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov qword [r12+NEBOC_CONSOLE_ROUTE_DUMP_LENGTH_OFFSET],0
 mov r13,[r12+NEBOC_CONSOLE_ROUTE_DUMP_TABLE_OFFSET]
 mov r14,[r12+NEBOC_CONSOLE_ROUTE_DUMP_BUFFER_OFFSET]
 mov r15,[r12+NEBOC_CONSOLE_ROUTE_DUMP_CAPACITY_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 cmp qword [r13+NEBOC_CONSOLE_ROUTING_TABLE_STATE_OFFSET],NEBOC_CONSOLE_ROUTING_TABLE_STATE_FROZEN
 jne .invalid_source
 mov r10,[r13+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET]
 mov rax,r10
 imul rax,NEBOC_CONSOLE_ROUTE_DUMP_LINE_SIZE
 add rax,NEBOC_CONSOLE_ROUTE_DUMP_HEADER_SIZE
 jc .limit
 cmp r15,rax
 jb .limit
 mov rdi,r14
 EMIT_PREFIX header,NEBOC_CONSOLE_ROUTE_DUMP_HEADER_SIZE
 xor ebx,ebx
.entry_loop:
 cmp rbx,r10
 jae .done_dump
 mov rax,rbx
 imul rax,NEBOC_CONSOLE_ROUTE_SIZE
 add rax,[r13+NEBOC_CONSOLE_ROUTING_TABLE_DATA_OFFSET]
 mov r11,rax
 EMIT_PREFIX p_r,2
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_m,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_MODE_OFFSET]
 call write_hex16
 EMIT_PREFIX p_i,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET]
 call write_hex16
 EMIT_PREFIX p_k,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_v,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_INITIAL_VALUE_NODE_OFFSET]
 call write_hex16
 EMIT_PREFIX p_c,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_CONSOLE_CALL_NODE_OFFSET]
 call write_hex16
 EMIT_PREFIX p_s,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_SCAN_NODE_OFFSET]
 call write_hex16
 EMIT_PREFIX p_b,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_BINDING_SYMBOL_OFFSET]
 call write_hex16
 EMIT_PREFIX p_o,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_SOURCE_ORDER_OFFSET]
 call write_hex16
 EMIT_PREFIX p_p,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET]
 call write_hex16
 EMIT_PREFIX p_n,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET]
 call write_hex16
 EMIT_PREFIX p_ci,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_CONSOLE_INTRINSIC_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_si,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_SCAN_INTRINSIC_ID_OFFSET]
 call write_hex16
 EMIT_PREFIX p_f,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET]
 call write_hex16
 EMIT_PREFIX p_h,3
 mov rax,[r11+NEBOC_CONSOLE_ROUTE_HASH_OFFSET]
 call write_hex16
 mov byte [rdi],10
 inc rdi
 inc rbx
 jmp .entry_loop
.done_dump:
 mov rax,rdi
 sub rax,r14
 mov [r12+NEBOC_CONSOLE_ROUTE_DUMP_LENGTH_OFFSET],rax
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
