; AST-HIR-LIR-PLANNER-E-OTIMIZACAO-F07: factual transport maturity and bounded local gateway.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/protocol/transport.inc"
extern nebo_protocol_compatibility
section .text

NEBOC_ABI_FUNCTION nebo_http2_transport_open
    mov eax,NEBO_UNAVAILABLE
    ret
NEBOC_ABI_FUNCTION nebo_quic_transport_open
    mov eax,NEBO_UNAVAILABLE
    ret

; rdi=path pointer, rsi=path length, rdx=capability.
; The contract is validated but this program has no live Unix backend gate.
NEBOC_ABI_FUNCTION nebo_unix_transport_open
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,108
    ja .limit
    test rdx,rdx
    jz .denied
    mov eax,NEBO_ENVIRONMENT_LIMITED
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.denied:
    mov eax,NEBO_EFFECT_DENIED
    ret

; rdi=A, rsi=B, rdx=A incoming qwords, rcx=B incoming qwords,
; r8=slots, r9=max frame bytes.
NEBOC_ABI_FUNCTION nebo_in_memory_transport_pair
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rcx,rcx
    jz .invalid
    test r8,r8
    jz .limit
    cmp r8,NEBO_TRANSPORT_MAX_SLOTS
    ja .limit
    test r9,r9
    jz .limit
    cmp r9,NEBO_MAX_FRAME_BYTES
    ja .limit
    mov [rdi+NEBO_TRANSPORT_PEER],rsi
    mov [rdi+NEBO_TRANSPORT_STORAGE],rdx
    mov [rdi+NEBO_TRANSPORT_CAPACITY],r8
    mov [rdi+NEBO_TRANSPORT_MAX_FRAME],r9
    mov qword [rdi+NEBO_TRANSPORT_COUNT],0
    mov qword [rdi+NEBO_TRANSPORT_HEAD],0
    mov qword [rdi+NEBO_TRANSPORT_TAIL],0
    mov qword [rdi+NEBO_TRANSPORT_STATE],0
    mov qword [rdi+NEBO_TRANSPORT_KIND],NEBO_TRANSPORT_MEMORY
    mov [rsi+NEBO_TRANSPORT_PEER],rdi
    mov [rsi+NEBO_TRANSPORT_STORAGE],rcx
    mov [rsi+NEBO_TRANSPORT_CAPACITY],r8
    mov [rsi+NEBO_TRANSPORT_MAX_FRAME],r9
    mov qword [rsi+NEBO_TRANSPORT_COUNT],0
    mov qword [rsi+NEBO_TRANSPORT_HEAD],0
    mov qword [rsi+NEBO_TRANSPORT_TAIL],0
    mov qword [rsi+NEBO_TRANSPORT_STATE],0
    mov qword [rsi+NEBO_TRANSPORT_KIND],NEBO_TRANSPORT_MEMORY
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; Extra deterministic transport operation: rdi=endpoint, rsi=message token.
NEBOC_ABI_FUNCTION nebo_in_memory_transport_send
    test rdi,rdi
    jz .invalid
    mov r8,[rdi+NEBO_TRANSPORT_PEER]
    test r8,r8
    jz .invalid
    mov rax,[r8+NEBO_TRANSPORT_COUNT]
    cmp rax,[r8+NEBO_TRANSPORT_CAPACITY]
    jae .full
    mov rcx,[r8+NEBO_TRANSPORT_TAIL]
    mov rdx,[r8+NEBO_TRANSPORT_STORAGE]
    mov [rdx+rcx*8],rsi
    inc rcx
    xor edx,edx
    mov rax,rcx
    div qword [r8+NEBO_TRANSPORT_CAPACITY]
    mov [r8+NEBO_TRANSPORT_TAIL],rdx
    inc qword [r8+NEBO_TRANSPORT_COUNT]
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.full:
    mov eax,NEBO_BACKPRESSURE
    ret

; rdi=endpoint, rsi=output token.
NEBOC_ABI_FUNCTION nebo_in_memory_transport_receive
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_TRANSPORT_COUNT],0
    je .empty
    mov rcx,[rdi+NEBO_TRANSPORT_HEAD]
    mov rdx,[rdi+NEBO_TRANSPORT_STORAGE]
    mov rax,[rdx+rcx*8]
    mov [rsi],rax
    inc rcx
    mov rax,rcx
    xor edx,edx
    div qword [rdi+NEBO_TRANSPORT_CAPACITY]
    mov [rdi+NEBO_TRANSPORT_HEAD],rdx
    dec qword [rdi+NEBO_TRANSPORT_COUNT]
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.empty:
    mov eax,NEBO_NEED_MORE
    ret

; rdi=gateway descriptor, rsi=protocol descriptor, rdx=nonzero route ID.
NEBOC_ABI_FUNCTION nebo_gateway_map
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    mov [rdi+NEBO_GATEWAY_PROTOCOL],rsi
    mov [rdi+NEBO_GATEWAY_ROUTE],rdx
    mov qword [rdi+NEBO_GATEWAY_STATE],1
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; rdi=target schema, rsi=source schema. Translation is compatibility-gated.
NEBOC_ABI_FUNCTION nebo_gateway_translate
    jmp nebo_protocol_compatibility

; rdi=endpoint, rsi=report.
NEBOC_ABI_FUNCTION nebo_transport_capabilities
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_TRANSPORT_KIND],NEBO_TRANSPORT_MEMORY
    jne .unavailable
    mov qword [rsi+NEBO_TRANSPORT_REPORT_KIND],NEBO_TRANSPORT_MEMORY
    mov qword [rsi+NEBO_TRANSPORT_REPORT_FLAGS],NEBO_TRANSPORT_FLAG_STREAMING|NEBO_TRANSPORT_FLAG_CANCELLATION
    mov rax,[rdi+NEBO_TRANSPORT_MAX_FRAME]
    mov [rsi+NEBO_TRANSPORT_REPORT_MAX_FRAME],rax
    mov rax,[rdi+NEBO_TRANSPORT_CAPACITY]
    mov [rsi+NEBO_TRANSPORT_REPORT_CAPACITY],rax
    mov qword [rsi+NEBO_TRANSPORT_REPORT_MATURITY],NEBO_OK
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.unavailable:
    mov eax,NEBO_UNAVAILABLE
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
