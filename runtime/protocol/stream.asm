; AST-HIR-LIR-PLANNER-E-OTIMIZACAO-F04: fixed-capacity typed stream state machine.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/protocol/stream.inc"
section .text

; rdi=method, rsi=id, rdx=request, rcx=item
NEBOC_ABI_FUNCTION nebo_rpc_method_server_stream
    mov r8,NEBO_RPC_METHOD_SERVER_STREAM
    jmp stream_method_init

; rdi=method, rsi=id, rdx=item, rcx=response
NEBOC_ABI_FUNCTION nebo_rpc_method_client_stream
    mov r8,NEBO_RPC_METHOD_CLIENT_STREAM
    jmp stream_method_init

; rdi=method, rsi=id, rdx=input, rcx=output
NEBOC_ABI_FUNCTION nebo_rpc_method_bidirectional
    mov r8,NEBO_RPC_METHOD_BIDI_STREAM
stream_method_init:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rcx,rcx
    jz .invalid
    mov [rdi+NEBO_METHOD_ID],rsi
    mov [rdi+NEBO_METHOD_REQUEST_TYPE],rdx
    mov [rdi+NEBO_METHOD_RESPONSE_TYPE],rcx
    mov qword [rdi+NEBO_METHOD_EFFECTS],0
    mov [rdi+NEBO_METHOD_FLAGS],r8
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; rdi=stream, rsi=storage, rdx=capacity, rcx=item bytes,
; r8=deadline, r9=logical now
NEBOC_ABI_FUNCTION nebo_client_open_stream
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .limit
    cmp rdx,nebo_ast_hir_lir_planner_e_otimizacao_STREAM_MAX_CAPACITY
    ja .limit
    test rcx,rcx
    jz .limit
    cmp rcx,NEBO_STREAM_MAX_ITEM_BYTES
    ja .limit
    mov rax,rdx
    mul rcx
    test rdx,rdx
    jnz .limit
    cmp r8,r9
    jb .deadline
    mov [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_BUFFER],rsi
    mov [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_CAPACITY],rax
    ; Recover item count from total bytes / item size only after overflow check.
    xor edx,edx
    div rcx
    mov [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_CAPACITY],rax
    mov [rdi+NEBO_STREAM_ITEM_SIZE],rcx
    mov qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_HEAD],0
    mov qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_TAIL],0
    mov qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_COUNT],0
    mov qword [rdi+NEBO_STREAM_STATE],NEBO_STREAM_OPEN
    mov qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_FLAGS],0
    mov [rdi+NEBO_STREAM_DEADLINE],r8
    mov [rdi+NEBO_STREAM_NOW],r9
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.deadline:
    mov eax,NEBO_DEADLINE
    ret

; rdi=stream, rsi=item
NEBOC_ABI_FUNCTION nebo_stream_send
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_STREAM_STATE],NEBO_STREAM_OPEN
    jne .cancelled_or_closed
    mov rax,[rdi+NEBO_STREAM_NOW]
    cmp rax,[rdi+NEBO_STREAM_DEADLINE]
    ja .deadline
    mov rax,[rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_COUNT]
    cmp rax,[rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_CAPACITY]
    jae .full
    mov rdx,[rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_TAIL]
    imul rdx,[rdi+NEBO_STREAM_ITEM_SIZE]
    add rdx,[rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_BUFFER]
    push rdi
    mov rcx,[rdi+NEBO_STREAM_ITEM_SIZE]
    mov rdi,rdx
    rep movsb
    pop rdi
    mov rax,[rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_TAIL]
    inc rax
    xor edx,edx
    div qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_CAPACITY]
    mov [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_TAIL],rdx
    inc qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_COUNT]
    xor eax,eax
    ret
.cancelled_or_closed:
    cmp qword [rdi+NEBO_STREAM_STATE],nebo_ast_hir_lir_planner_e_otimizacao_STREAM_CANCELLED
    je .cancelled
    mov eax,NEBO_STREAM_END
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.deadline:
    mov eax,NEBO_DEADLINE
    ret
.full:
    mov eax,NEBO_BACKPRESSURE
    ret
.cancelled:
    mov eax,NEBO_CANCELLED
    ret

; rdi=stream, rsi=output
NEBOC_ABI_FUNCTION nebo_stream_receive
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_STREAM_STATE],nebo_ast_hir_lir_planner_e_otimizacao_STREAM_CANCELLED
    je .cancelled
    cmp qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_COUNT],0
    jne .copy
    cmp qword [rdi+NEBO_STREAM_STATE],NEBO_STREAM_HALF_CLOSED
    je .end
    mov eax,NEBO_NEED_MORE
    ret
.copy:
    mov rdx,[rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_HEAD]
    imul rdx,[rdi+NEBO_STREAM_ITEM_SIZE]
    add rdx,[rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_BUFFER]
    push rdi
    mov rcx,[rdi+NEBO_STREAM_ITEM_SIZE]
    mov rdi,rsi
    mov rsi,rdx
    rep movsb
    pop rdi
    mov rax,[rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_HEAD]
    inc rax
    xor edx,edx
    div qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_CAPACITY]
    mov [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_HEAD],rdx
    dec qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_COUNT]
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.cancelled:
    mov eax,NEBO_CANCELLED
    ret
.end:
    mov eax,NEBO_STREAM_END
    ret

; rdi=stream
NEBOC_ABI_FUNCTION nebo_stream_half_close
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_STREAM_STATE],NEBO_STREAM_OPEN
    jne .invalid
    mov qword [rdi+NEBO_STREAM_STATE],NEBO_STREAM_HALF_CLOSED
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; rdi=stream
NEBOC_ABI_FUNCTION nebo_stream_cancel
    test rdi,rdi
    jz .invalid
    mov qword [rdi+NEBO_STREAM_STATE],nebo_ast_hir_lir_planner_e_otimizacao_STREAM_CANCELLED
    mov qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_HEAD],0
    mov qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_TAIL],0
    mov qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_STREAM_COUNT],0
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
