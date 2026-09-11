bits 64
default rel
%include "compiler/debug/debug_metadata.inc"

extern nebo_debug_metadata_init
extern nebo_debug_source_add
extern nebo_debug_frame_add
extern nebo_debug_binding_add
extern nebo_debug_metadata_encode

section .bss
align 16
state resb NEBO_DEBUG_STATE_SIZE
sources resb NEBO_DEBUG_SOURCE_SIZE*4
frames resb NEBO_DEBUG_FRAME_SIZE*4
bindings resb NEBO_DEBUG_BINDING_SIZE*8
init_req resb NEBO_DEBUG_INIT_SIZE
source_req resb NEBO_DEBUG_SOURCE_REQUEST_SIZE
frame_req resb NEBO_DEBUG_FRAME_REQUEST_SIZE
binding_req resb NEBO_DEBUG_BINDING_REQUEST_SIZE
encode_req resb NEBO_DEBUG_ENCODE_SIZE
encoded resb 1024
encoded_copy resb 1024
hash_saved resq 1

section .text
prepare_source:
    lea rdi,[source_req]
    mov ecx,NEBO_DEBUG_SOURCE_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [source_req+NEBO_DEBUG_SOURCE_REQUEST_STATE],rax
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_ADDRESS_START],0x1000
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_ADDRESS_END],0x1010
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_ID],0xabc
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_SPAN_START],0
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_SPAN_END],10
    ret
prepare_frame:
    lea rdi,[frame_req]
    mov ecx,NEBO_DEBUG_FRAME_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [frame_req+NEBO_DEBUG_FRAME_REQUEST_STATE],rax
    mov qword [frame_req+NEBO_DEBUG_FRAME_REQUEST_ID],0x101
    mov qword [frame_req+NEBO_DEBUG_FRAME_REQUEST_ADDRESS_START],0x1000
    mov qword [frame_req+NEBO_DEBUG_FRAME_REQUEST_ADDRESS_END],0x1020
    ret
prepare_binding:
    lea rdi,[binding_req]
    mov ecx,NEBO_DEBUG_BINDING_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [binding_req+NEBO_DEBUG_BINDING_REQUEST_STATE],rax
    mov qword [binding_req+NEBO_DEBUG_BINDING_REQUEST_NAME],0x201
    mov qword [binding_req+NEBO_DEBUG_BINDING_REQUEST_FRAME],0
    mov qword [binding_req+NEBO_DEBUG_BINDING_REQUEST_KIND],NEBO_DEBUG_BINDING_REGISTER
    mov qword [binding_req+NEBO_DEBUG_BINDING_REQUEST_LOCATION],3
    ret
prepare_encode:
    lea rdi,[encode_req]
    mov ecx,NEBO_DEBUG_ENCODE_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [encode_req+NEBO_DEBUG_ENCODE_STATE],rax
    lea rax,[encoded]
    mov [encode_req+NEBO_DEBUG_ENCODE_OUTPUT],rax
    mov qword [encode_req+NEBO_DEBUG_ENCODE_CAPACITY],1024
    ret

global _start
_start:
    ; 1-3 initialization.
    lea rdi,[init_req]
    mov ecx,NEBO_DEBUG_INIT_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [init_req+NEBO_DEBUG_INIT_STATE],rax
    lea rax,[sources]
    mov [init_req+NEBO_DEBUG_INIT_SOURCES],rax
    mov qword [init_req+NEBO_DEBUG_INIT_SOURCE_CAP],4
    lea rax,[frames]
    mov [init_req+NEBO_DEBUG_INIT_FRAMES],rax
    mov qword [init_req+NEBO_DEBUG_INIT_FRAME_CAP],4
    lea rax,[bindings]
    mov [init_req+NEBO_DEBUG_INIT_BINDINGS],rax
    mov qword [init_req+NEBO_DEBUG_INIT_BINDING_CAP],8
    lea rdi,[init_req]
    call nebo_debug_metadata_init
    test eax,eax
    jnz .fail1
    mov rax,NEBO_DEBUG_MAGIC
    cmp [state+NEBO_DEBUG_STATE_MAGIC],rax
    jne .fail2
    cmp qword [state+NEBO_DEBUG_STATE_VERSION],1
    jne .fail3

    ; 4-9 source maps are monotonic and non-overlapping.
    call prepare_source
    lea rdi,[source_req]
    call nebo_debug_source_add
    test eax,eax
    jnz .fail4
    cmp qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_INDEX],0
    jne .fail5
    call prepare_source
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_ADDRESS_START],0x1010
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_ADDRESS_END],0x1020
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_SPAN_START],10
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_SPAN_END],20
    lea rdi,[source_req]
    call nebo_debug_source_add
    test eax,eax
    jnz .fail6
    call prepare_source
    mov qword [source_req+NEBO_DEBUG_SOURCE_REQUEST_ADDRESS_START],0x1008
    lea rdi,[source_req]
    call nebo_debug_source_add
    cmp eax,NEBO_DEBUG_STATUS_OVERLAP
    jne .fail7
    cmp qword [state+NEBO_DEBUG_STATE_SOURCE_COUNT],2
    jne .fail8
    cmp qword [sources+NEBO_DEBUG_SOURCE_SIZE+NEBO_DEBUG_SOURCE_SPAN_END],20
    jne .fail9

    ; 10-14 frame table is bounded and ordered.
    call prepare_frame
    lea rdi,[frame_req]
    call nebo_debug_frame_add
    test eax,eax
    jnz .fail10
    call prepare_frame
    mov qword [frame_req+NEBO_DEBUG_FRAME_REQUEST_ID],0x102
    mov qword [frame_req+NEBO_DEBUG_FRAME_REQUEST_ADDRESS_START],0x1020
    mov qword [frame_req+NEBO_DEBUG_FRAME_REQUEST_ADDRESS_END],0x1040
    lea rdi,[frame_req]
    call nebo_debug_frame_add
    test eax,eax
    jnz .fail11
    call prepare_frame
    mov qword [frame_req+NEBO_DEBUG_FRAME_REQUEST_ADDRESS_START],0x1010
    lea rdi,[frame_req]
    call nebo_debug_frame_add
    cmp eax,NEBO_DEBUG_STATUS_OVERLAP
    jne .fail12
    cmp qword [state+NEBO_DEBUG_STATE_FRAME_COUNT],2
    jne .fail13
    cmp qword [frames+NEBO_DEBUG_FRAME_STATE],1
    jne .fail14

    ; 15-20 bindings never expose classified raw values.
    call prepare_binding
    lea rdi,[binding_req]
    call nebo_debug_binding_add
    test eax,eax
    jnz .fail15
    call prepare_binding
    mov qword [binding_req+NEBO_DEBUG_BINDING_REQUEST_NAME],0x202
    mov qword [binding_req+NEBO_DEBUG_BINDING_REQUEST_CLASS],nebo_privacy_PRIVACY_SECRET
    lea rdi,[binding_req]
    call nebo_debug_binding_add
    cmp eax,NEBO_DEBUG_STATUS_PRIVACY
    jne .fail16
    mov qword [binding_req+NEBO_DEBUG_BINDING_REQUEST_REDACTED],1
    lea rdi,[binding_req]
    call nebo_debug_binding_add
    test eax,eax
    jnz .fail17
    cmp qword [state+NEBO_DEBUG_STATE_BINDING_COUNT],2
    jne .fail18
    cmp qword [bindings+NEBO_DEBUG_BINDING_SIZE+NEBO_DEBUG_BINDING_REDACTED],1
    jne .fail19
    cmp qword [frames+NEBO_DEBUG_FRAME_BINDING_COUNT],2
    jne .fail20

    ; 21-26 deterministic pointer-free encoding and capacity refusal.
    call prepare_encode
    lea rdi,[encode_req]
    call nebo_debug_metadata_encode
    test eax,eax
    jnz .fail21
    cmp qword [encode_req+NEBO_DEBUG_ENCODE_LENGTH],312
    jne .fail22
    mov rax,[encode_req+NEBO_DEBUG_ENCODE_HASH]
    test rax,rax
    jz .fail23
    mov [hash_saved],rax
    lea rsi,[encoded]
    lea rdi,[encoded_copy]
    mov ecx,312/8
    rep movsq
    lea rdi,[encode_req]
    call nebo_debug_metadata_encode
    mov rax,[hash_saved]
    cmp [encode_req+NEBO_DEBUG_ENCODE_HASH],rax
    jne .fail24
    lea rsi,[encoded]
    lea rdi,[encoded_copy]
    mov ecx,312
    repe cmpsb
    jne .fail25
    mov qword [encode_req+NEBO_DEBUG_ENCODE_CAPACITY],311
    lea rdi,[encode_req]
    call nebo_debug_metadata_encode
    cmp eax,NEBO_DEBUG_STATUS_LIMIT
    jne .fail26

    ; 27-28 invalid frame and null request are typed.
    call prepare_binding
    mov qword [binding_req+NEBO_DEBUG_BINDING_REQUEST_FRAME],2
    lea rdi,[binding_req]
    call nebo_debug_binding_add
    cmp eax,NEBO_DEBUG_STATUS_FRAME
    jne .fail27
    xor edi,edi
    call nebo_debug_source_add
    cmp eax,NEBO_DEBUG_STATUS_INVALID_ARGUMENT
    jne .fail28
    xor edi,edi
    mov eax,60
    syscall

%macro FAIL_LABEL 1
.fail%1: mov edi,%1
    mov eax,60
    syscall
%endmacro
%assign i 1
%rep 28
FAIL_LABEL i
%assign i i+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
