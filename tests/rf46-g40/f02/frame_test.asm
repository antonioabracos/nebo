bits 64
default rel
%include "runtime/protocol/frame.inc"
extern nebo_protocol_encode
extern nebo_protocol_decode
extern nebo_frame_wrap
extern nebo_frame_checksum
extern nebo_frame_decoder_init
extern nebo_decoder_push
extern nebo_decoder_finish
extern nebo_frame_compress
section .data
payload db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
payload_len equ $-payload
section .bss
encoded resb 64
frame resb 128
buffer resb 128
output resb 64
decoder resb NEBO_DECODER_SIZE
out_len resq 1
section .text
global _start
_start:
    lea rdi,[payload]
    mov esi,payload_len
    lea rdx,[encoded]
    mov ecx,64
    call nebo_protocol_encode
    test eax,eax
    jnz fail
    lea rdi,[encoded]
    mov esi,payload_len
    lea rdx,[output]
    mov ecx,64
    mov r8d,64
    call nebo_protocol_decode
    test eax,eax
    jnz fail
    mov rax,0x0807060504030201
    cmp [output],rax
    jne fail
    lea rdi,[payload]
    mov esi,payload_len
    lea rdx,[frame]
    mov ecx,128
    mov r8,0x1122334455667788
    call nebo_frame_wrap
    test eax,eax
    jnz fail
    lea rdi,[frame]
    mov esi,NEBO_FRAME_HEADER+payload_len
    call nebo_frame_checksum
    test eax,eax
    jnz fail
    lea rdi,[decoder]
    lea rsi,[buffer]
    mov edx,128
    mov ecx,64
    call nebo_frame_decoder_init
    test eax,eax
    jnz fail
    ; incremental chunks split inside header and payload
    lea rdi,[decoder]
    lea rsi,[frame]
    mov edx,7
    lea rcx,[output]
    mov r8d,64
    lea r9,[out_len]
    call nebo_decoder_push
    cmp eax,NEBO_NEED_MORE
    jne fail
    lea rdi,[decoder]
    lea rsi,[frame+7]
    mov edx,29
    lea rcx,[output]
    mov r8d,64
    lea r9,[out_len]
    call nebo_decoder_push
    cmp eax,NEBO_NEED_MORE
    jne fail
    lea rdi,[decoder]
    lea rsi,[frame+36]
    mov edx,NEBO_FRAME_HEADER+payload_len-36
    lea rcx,[output]
    mov r8d,64
    lea r9,[out_len]
    call nebo_decoder_push
    test eax,eax
    jnz fail
    cmp qword [out_len],payload_len
    jne fail
    mov rax,0x0807060504030201
    cmp [output],rax
    jne fail
    lea rdi,[decoder]
    call nebo_decoder_finish
    test eax,eax
    jnz fail
    ; truncation is reported at finish.
    lea rdi,[decoder]
    lea rsi,[buffer]
    mov edx,128
    mov ecx,64
    call nebo_frame_decoder_init
    test eax,eax
    jnz fail
    lea rdi,[decoder]
    lea rsi,[frame]
    mov edx,20
    lea rcx,[output]
    mov r8d,64
    lea r9,[out_len]
    call nebo_decoder_push
    cmp eax,NEBO_NEED_MORE
    jne fail
    lea rdi,[decoder]
    call nebo_decoder_finish
    cmp eax,NEBO_TRUNCATED
    jne fail
    ; checksum corruption poisons state and never writes output length.
    xor byte [frame+NEBO_FRAME_HEADER+3],0xff
    lea rdi,[decoder]
    lea rsi,[buffer]
    mov edx,128
    mov ecx,64
    call nebo_frame_decoder_init
    test eax,eax
    jnz fail
    lea rdi,[decoder]
    lea rsi,[frame]
    mov edx,NEBO_FRAME_HEADER+payload_len
    lea rcx,[output]
    mov r8d,64
    lea r9,[out_len]
    call nebo_decoder_push
    cmp eax,NEBO_CHECKSUM
    jne fail
    cmp qword [out_len],0
    jne fail
    lea rdi,[decoder]
    call nebo_decoder_finish
    cmp eax,NEBO_FAILED
    jne fail
    call nebo_frame_compress
    cmp eax,NEBO_UNSUPPORTED
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
