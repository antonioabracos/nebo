bits 64
default rel
%include "runtime/protocol/transport.inc"
extern nebo_http2_transport_open
extern nebo_quic_transport_open
extern nebo_unix_transport_open
extern nebo_in_memory_transport_pair
extern nebo_in_memory_transport_send
extern nebo_in_memory_transport_receive
extern nebo_gateway_map
extern nebo_gateway_translate
extern nebo_transport_capabilities
extern nebo_field_optional
extern nebo_protocol_define
section .rodata
unix_path db '/tmp/nebo-g40.sock'
unix_path_len equ $-unix_path
section .bss
endpoint_a resb NEBO_TRANSPORT_SIZE
endpoint_b resb NEBO_TRANSPORT_SIZE
storage_a resq 2
storage_b resq 2
token resq 1
report resb NEBO_TRANSPORT_REPORT_SIZE
gateway resb NEBO_GATEWAY_SIZE
field resb nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE
field_b resb nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE
schema_a resb NEBO_PROTOCOL_SIZE
schema_b resb NEBO_PROTOCOL_SIZE
section .text
global _start
_start:
    call nebo_http2_transport_open
    cmp eax,NEBO_UNAVAILABLE
    jne fail
    call nebo_quic_transport_open
    cmp eax,NEBO_UNAVAILABLE
    jne fail
    lea rdi,[unix_path]
    mov esi,unix_path_len
    mov edx,1
    call nebo_unix_transport_open
    cmp eax,NEBO_ENVIRONMENT_LIMITED
    jne fail
    lea rdi,[endpoint_a]
    lea rsi,[endpoint_b]
    lea rdx,[storage_a]
    lea rcx,[storage_b]
    mov r8d,2
    mov r9d,1024
    call nebo_in_memory_transport_pair
    test eax,eax
    jnz fail
    lea rdi,[endpoint_a]
    mov rsi,11
    call nebo_in_memory_transport_send
    test eax,eax
    jnz fail
    lea rdi,[endpoint_a]
    mov rsi,22
    call nebo_in_memory_transport_send
    test eax,eax
    jnz fail
    lea rdi,[endpoint_a]
    mov rsi,33
    call nebo_in_memory_transport_send
    cmp eax,NEBO_BACKPRESSURE
    jne fail
    lea rdi,[endpoint_b]
    lea rsi,[token]
    call nebo_in_memory_transport_receive
    test eax,eax
    jnz fail
    cmp qword [token],11
    jne fail
    lea rdi,[endpoint_b]
    lea rsi,[token]
    call nebo_in_memory_transport_receive
    test eax,eax
    jnz fail
    cmp qword [token],22
    jne fail
    lea rdi,[endpoint_b]
    lea rsi,[token]
    call nebo_in_memory_transport_receive
    cmp eax,NEBO_NEED_MORE
    jne fail
    lea rdi,[endpoint_a]
    lea rsi,[report]
    call nebo_transport_capabilities
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_TRANSPORT_REPORT_MAX_FRAME],1024
    jne fail
    test qword [report+NEBO_TRANSPORT_REPORT_FLAGS],NEBO_TRANSPORT_FLAG_SECURITY
    jnz fail
    lea rdi,[field]
    mov esi,1
    mov edx,1
    call nebo_field_optional
    test eax,eax
    jnz fail
    lea rdi,[field_b]
    mov esi,1
    mov edx,1
    call nebo_field_optional
    test eax,eax
    jnz fail
    lea rdi,[schema_a]
    mov esi,1
    lea rdx,[field_b]
    mov ecx,1
    xor r8d,r8d
    xor r9d,r9d
    call nebo_protocol_define
    test eax,eax
    jnz fail
    lea rdi,[schema_b]
    mov esi,2
    lea rdx,[field]
    mov ecx,1
    xor r8d,r8d
    xor r9d,r9d
    call nebo_protocol_define
    test eax,eax
    jnz fail
    lea rdi,[gateway]
    lea rsi,[schema_b]
    mov edx,0x44
    call nebo_gateway_map
    test eax,eax
    jnz fail
    lea rdi,[schema_b]
    lea rsi,[schema_a]
    call nebo_gateway_translate
    test eax,eax
    jnz fail
    ; Type mutation makes translation breaking and leaves gateway unchanged.
    mov qword [field_b+NEBO_FIELD_TYPE],2
    lea rdi,[schema_b]
    lea rsi,[schema_a]
    call nebo_gateway_translate
    cmp eax,NEBO_BREAKING
    jne fail
    cmp qword [gateway+NEBO_GATEWAY_ROUTE],0x44
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
