; AST-HIR-LIR-PLANNER-E-OTIMIZACAO-F02: canonical byte copy, bounded framing and incremental decode.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/protocol/frame.inc"

section .text

; rdi=source, rsi=length, rdx=destination, rcx=capacity
NEBOC_ABI_FUNCTION nebo_protocol_encode
    cmp rsi,NEBO_MAX_FRAME_BYTES
    ja .limit
    cmp rcx,rsi
    jb .limit
    test rsi,rsi
    jz .ok
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    mov rcx,rsi
    mov rsi,rdi
    mov rdi,rdx
    rep movsb
.ok:
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=source, rsi=length, rdx=destination, rcx=capacity, r8=explicit limit
NEBOC_ABI_FUNCTION nebo_protocol_decode
    cmp r8,NEBO_MAX_FRAME_BYTES
    ja .limit
    cmp rsi,r8
    ja .limit
    jmp nebo_protocol_encode
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=payload, rsi=length, rdx=frame, rcx=capacity, r8=metadata
NEBOC_ABI_FUNCTION nebo_frame_wrap
    cmp rsi,NEBO_MAX_FRAME_BYTES
    ja .limit
    mov rax,rsi
    add rax,NEBO_FRAME_HEADER
    jc .limit
    cmp rcx,rax
    jb .limit
    test rdx,rdx
    jz .invalid
    test rsi,rsi
    jz .header
    test rdi,rdi
    jz .invalid
.header:
    mov qword [rdx+NEBO_FRAME_MAGIC_OFF],NEBO_FRAME_MAGIC
    mov [rdx+NEBO_FRAME_LENGTH],rsi
    mov [rdx+NEBO_FRAME_METADATA],r8
    mov r9,1469598103934665603
    mov r11,1099511628211
    mov r10,r8
    mov ecx,8
.metadata_hash:
    movzx eax,r10b
    xor r9,rax
    imul r9,r11
    shr r10,8
    dec ecx
    jnz .metadata_hash
    xor ecx,ecx
.payload_hash:
    cmp rcx,rsi
    jae .checksum
    movzx eax,byte [rdi+rcx]
    xor r9,rax
    imul r9,r11
    inc rcx
    jmp .payload_hash
.checksum:
    mov [rdx+NEBO_FRAME_CHECKSUM],r9
    lea r10,[rdx+NEBO_FRAME_HEADER]
    mov rcx,rsi
    mov rsi,rdi
    mov rdi,r10
    rep movsb
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=frame, rsi=total length
NEBOC_ABI_FUNCTION nebo_frame_checksum
    test rdi,rdi
    jz .invalid
    cmp rsi,NEBO_FRAME_HEADER
    jb .truncated
    cmp qword [rdi+NEBO_FRAME_MAGIC_OFF],NEBO_FRAME_MAGIC
    jne .invalid
    mov r8,[rdi+NEBO_FRAME_LENGTH]
    cmp r8,NEBO_MAX_FRAME_BYTES
    ja .limit
    lea rax,[r8+NEBO_FRAME_HEADER]
    cmp rsi,rax
    jne .truncated
    mov r9,1469598103934665603
    mov r11,1099511628211
    mov r10,[rdi+NEBO_FRAME_METADATA]
    mov ecx,8
.metadata_hash:
    movzx eax,r10b
    xor r9,rax
    imul r9,r11
    shr r10,8
    dec ecx
    jnz .metadata_hash
    xor ecx,ecx
.payload_hash:
    cmp rcx,r8
    jae .compare
    movzx eax,byte [rdi+NEBO_FRAME_HEADER+rcx]
    xor r9,rax
    imul r9,r11
    inc rcx
    jmp .payload_hash
.compare:
    cmp r9,[rdi+NEBO_FRAME_CHECKSUM]
    jne .checksum
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.truncated:
    mov eax,NEBO_TRUNCATED
    ret
.checksum:
    mov eax,NEBO_CHECKSUM
    ret

; rdi=decoder, rsi=buffer, rdx=capacity, rcx=max payload
NEBOC_ABI_FUNCTION nebo_frame_decoder_init
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rdx,NEBO_FRAME_HEADER
    jb .limit
    cmp rcx,NEBO_MAX_FRAME_BYTES
    ja .limit
    test rcx,rcx
    jz .limit
    mov rax,rcx
    add rax,NEBO_FRAME_HEADER
    cmp rdx,rax
    jb .limit
    mov [rdi+NEBO_DECODER_BUFFER],rsi
    mov [rdi+NEBO_DECODER_CAPACITY],rdx
    mov qword [rdi+NEBO_DECODER_USED],0
    mov [rdi+NEBO_DECODER_MAX_FRAME],rcx
    mov qword [rdi+NEBO_DECODER_STATE],NEBO_DECODER_READY
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=decoder, rsi=chunk, rdx=chunk length, rcx=payload output,
; r8=output capacity, r9=output length pointer
NEBOC_ABI_FUNCTION nebo_decoder_push
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_DECODER_STATE],NEBO_DECODER_READY
    jne .failed
    test r9,r9
    jz .invalid
    mov qword [r9],0
    test rdx,rdx
    jz .inspect
    test rsi,rsi
    jz .invalid
    mov r10,[rdi+NEBO_DECODER_USED]
    mov r11,r10
    add r11,rdx
    jc .poison_limit
    cmp r11,[rdi+NEBO_DECODER_CAPACITY]
    ja .poison_limit
    push rdi
    push r9
    push rcx
    mov rax,rdi
    mov rdi,[rax+NEBO_DECODER_BUFFER]
    add rdi,r10
    mov rcx,rdx
    rep movsb
    pop rcx
    pop r9
    pop rdi
    mov [rdi+NEBO_DECODER_USED],r11
.inspect:
    mov r10,[rdi+NEBO_DECODER_USED]
    cmp r10,NEBO_FRAME_HEADER
    jb .need_more
    mov r11,[rdi+NEBO_DECODER_BUFFER]
    cmp qword [r11+NEBO_FRAME_MAGIC_OFF],NEBO_FRAME_MAGIC
    jne .poison_invalid
    mov rax,[r11+NEBO_FRAME_LENGTH]
    cmp rax,[rdi+NEBO_DECODER_MAX_FRAME]
    ja .poison_limit
    lea rdx,[rax+NEBO_FRAME_HEADER]
    cmp r10,rdx
    jb .need_more
    jne .poison_invalid
    cmp r8,rax
    jb .limit
    test rax,rax
    jz .verify
    test rcx,rcx
    jz .invalid
.verify:
    push rdi
    push r9
    push rcx
    mov rdi,r11
    mov rsi,rdx
    call nebo_frame_checksum
    pop rcx
    pop r9
    pop rdi
    test eax,eax
    jnz .poison_status
    mov r11,[rdi+NEBO_DECODER_BUFFER]
    mov rax,[r11+NEBO_FRAME_LENGTH]
    mov [r9],rax
    push rdi
    mov rdx,rcx
    lea rsi,[r11+NEBO_FRAME_HEADER]
    mov rdi,rdx
    mov rcx,rax
    rep movsb
    pop rdi
    mov qword [rdi+NEBO_DECODER_USED],0
    xor eax,eax
    ret
.need_more:
    mov eax,NEBO_NEED_MORE
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.failed:
    mov eax,NEBO_FAILED
    ret
.poison_invalid:
    mov eax,NEBO_INVALID
    jmp .poison_status
.poison_limit:
    mov eax,NEBO_LIMIT
.poison_status:
    mov qword [rdi+NEBO_DECODER_STATE],NEBO_DECODER_POISONED
    ret

; rdi=decoder
NEBOC_ABI_FUNCTION nebo_decoder_finish
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_DECODER_STATE],NEBO_DECODER_READY
    jne .failed
    cmp qword [rdi+NEBO_DECODER_USED],0
    jne .truncated
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.failed:
    mov eax,NEBO_FAILED
    ret
.truncated:
    mov eax,NEBO_TRUNCATED
    ret

; No compression backend is selected by AST-HIR-LIR-PLANNER-E-OTIMIZACAO.
NEBOC_ABI_FUNCTION nebo_frame_compress
    mov eax,NEBO_UNSUPPORTED
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
