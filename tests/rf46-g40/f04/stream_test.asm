bits 64
default rel
%include "runtime/protocol/stream.inc"
extern nebo_rpc_method_server_stream
extern nebo_rpc_method_client_stream
extern nebo_rpc_method_bidirectional
extern nebo_client_open_stream
extern nebo_stream_send
extern nebo_stream_receive
extern nebo_stream_half_close
extern nebo_stream_cancel
section .bss
methods resb NEBO_METHOD_SIZE*3
stream resb nebo_ast_hir_lir_planner_e_otimizacao_STREAM_SIZE
storage resq 2
item_a resq 1
item_b resq 1
item_c resq 1
output resq 1
section .text
global _start
_start:
    lea rdi,[methods]
    mov esi,1
    mov edx,1
    mov ecx,2
    call nebo_rpc_method_server_stream
    test eax,eax
    jnz fail
    lea rdi,[methods+NEBO_METHOD_SIZE]
    mov esi,2
    mov edx,1
    mov ecx,2
    call nebo_rpc_method_client_stream
    test eax,eax
    jnz fail
    lea rdi,[methods+NEBO_METHOD_SIZE*2]
    mov esi,3
    mov edx,1
    mov ecx,2
    call nebo_rpc_method_bidirectional
    test eax,eax
    jnz fail
    lea rdi,[stream]
    lea rsi,[storage]
    mov edx,2
    mov ecx,8
    mov r8d,100
    mov r9d,10
    call nebo_client_open_stream
    test eax,eax
    jnz fail
    mov qword [item_a],11
    mov qword [item_b],22
    mov qword [item_c],33
    lea rdi,[stream]
    lea rsi,[item_a]
    call nebo_stream_send
    test eax,eax
    jnz fail
    lea rdi,[stream]
    lea rsi,[item_b]
    call nebo_stream_send
    test eax,eax
    jnz fail
    lea rdi,[stream]
    lea rsi,[item_c]
    call nebo_stream_send
    cmp eax,NEBO_BACKPRESSURE
    jne fail
    cmp qword [stream+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_COUNT],2
    jne fail
    lea rdi,[stream]
    lea rsi,[output]
    call nebo_stream_receive
    test eax,eax
    jnz fail
    cmp qword [output],11
    jne fail
    lea rdi,[stream]
    lea rsi,[item_c]
    call nebo_stream_send
    test eax,eax
    jnz fail
    lea rdi,[stream]
    call nebo_stream_half_close
    test eax,eax
    jnz fail
    lea rdi,[stream]
    lea rsi,[item_a]
    call nebo_stream_send
    cmp eax,NEBO_STREAM_END
    jne fail
    lea rdi,[stream]
    lea rsi,[output]
    call nebo_stream_receive
    test eax,eax
    jnz fail
    cmp qword [output],22
    jne fail
    lea rdi,[stream]
    lea rsi,[output]
    call nebo_stream_receive
    test eax,eax
    jnz fail
    cmp qword [output],33
    jne fail
    lea rdi,[stream]
    lea rsi,[output]
    call nebo_stream_receive
    cmp eax,NEBO_STREAM_END
    jne fail
    lea rdi,[stream]
    call nebo_stream_cancel
    test eax,eax
    jnz fail
    cmp qword [stream+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_COUNT],0
    jne fail
    lea rdi,[stream]
    lea rsi,[output]
    call nebo_stream_receive
    cmp eax,NEBO_CANCELLED
    jne fail
    ; expired open does not initialize caller state.
    mov qword [stream+NEBO_STREAM_STATE],0x7777
    lea rdi,[stream]
    lea rsi,[storage]
    mov edx,2
    mov ecx,8
    mov r8d,9
    mov r9d,10
    call nebo_client_open_stream
    cmp eax,NEBO_DEADLINE
    jne fail
    cmp qword [stream+NEBO_STREAM_STATE],0x7777
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
