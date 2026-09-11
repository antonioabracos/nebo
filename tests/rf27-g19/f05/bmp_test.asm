bits 64
default rel
%include "runtime/image/bmp.inc"
section .data
bmp_fixture:
 db 0x42,0x4d,0x46,0,0,0,0,0,0,0,0x36,0,0,0
 dd 40,2,2
 dw 1,32
 dd 0,16,0,0,0,0
 db 0xff,0,0,0x40, 0xff,0xff,0xff,0xff
 db 0,0,0xff,0xff, 0,0xff,0,0x80
bmp_fixture_end:
section .bss
align 16
meta resb 32
desc resb 64
pixels resb 16
encoded resb 70
encoded_len resq 1
section .text
global _start
_start:
 lea rdi,[rel bmp_fixture]
 mov esi,bmp_fixture_end-bmp_fixture
 lea rdx,[rel meta]
 call nebo_bmp_inspect
 test eax,eax
 jnz .fail1
 cmp dword [rel meta],2
 jne .fail2
 cmp dword [rel meta+4],2
 jne .fail3
 cmp word [rel meta+8],32
 jne .fail4
 cmp dword [rel meta+12],8
 jne .fail5
 cmp qword [rel meta+16],16
 jne .fail6
 lea rdi,[rel bmp_fixture]
 mov esi,bmp_fixture_end-bmp_fixture
 lea rdx,[rel desc]
 lea rcx,[rel pixels]
 mov r8d,16
 call nebo_bmp_decode
 test eax,eax
 jnz .fail7
 cmp dword [rel pixels],0xff0000ff
 jne .fail8
 cmp dword [rel pixels+4],0x8000ff00
 jne .fail9
 cmp dword [rel pixels+8],0x40ff0000
 jne .fail10
 cmp dword [rel pixels+12],0xffffffff
 jne .fail11
 cmp dword [rel desc+16],2
 jne .fail12
 cmp word [rel desc+28],NEBO_PIXEL_RGBA8
 jne .fail13
 lea rdi,[rel desc]
 lea rsi,[rel encoded]
 mov edx,70
 lea rcx,[rel encoded_len]
 call nebo_bmp_encode
 test eax,eax
 jnz .fail14
 cmp qword [rel encoded_len],70
 jne .fail15
 lea rsi,[rel bmp_fixture]
 lea rdi,[rel encoded]
 mov ecx,70
.compare:
 mov al,[rsi]
 cmp al,[rdi]
 jne .fail16
 inc rsi
 inc rdi
 dec ecx
 jnz .compare
 ; Truncated input and magic mismatch are typed.
 lea rdi,[rel bmp_fixture]
 mov esi,53
 lea rdx,[rel meta]
 call nebo_bmp_inspect
 cmp eax,NEBO_BMP_E_TRUNCATED
 jne .fail17
 xor byte [rel bmp_fixture],1
 lea rdi,[rel bmp_fixture]
 mov esi,70
 lea rdx,[rel meta]
 call nebo_bmp_inspect
 cmp eax,NEBO_BMP_E_MAGIC
 jne .fail18
 xor byte [rel bmp_fixture],1
 ; Unsupported bpp and compression do not publish metadata.
 mov rax,0x5a5a5a5a5a5a5a5a
 mov [rel meta],rax
 mov word [rel bmp_fixture+28],16
 lea rdi,[rel bmp_fixture]
 mov esi,70
 lea rdx,[rel meta]
 call nebo_bmp_inspect
 cmp eax,NEBO_BMP_E_UNSUPPORTED
 jne .fail19
 mov rax,0x5a5a5a5a5a5a5a5a
 cmp qword [rel meta],rax
 jne .fail20
 mov word [rel bmp_fixture+28],32
 mov dword [rel bmp_fixture+30],1
 lea rdi,[rel bmp_fixture]
 mov esi,70
 lea rdx,[rel meta]
 call nebo_bmp_inspect
 cmp eax,NEBO_BMP_E_UNSUPPORTED
 jne .fail21
 mov dword [rel bmp_fixture+30],0
 ; Exact file length prevents trailing-data ambiguity.
 lea rdi,[rel bmp_fixture]
 mov esi,71
 lea rdx,[rel meta]
 call nebo_bmp_inspect
 cmp eax,NEBO_BMP_E_HEADER
 jne .fail22
 ; Capacity error is failure-atomic for the descriptor.
 mov rax,0x3333333333333333
 mov [rel desc],rax
 lea rdi,[rel bmp_fixture]
 mov esi,70
 lea rdx,[rel desc]
 lea rcx,[rel pixels]
 mov r8d,15
 call nebo_bmp_decode
 cmp eax,NEBO_BMP_E_CAPACITY
 jne .fail23
 mov rax,0x3333333333333333
 cmp qword [rel desc],rax
 jne .fail24
 ; Re-decode, then verify encode capacity and stale errors.
 lea rdi,[rel bmp_fixture]
 mov esi,70
 lea rdx,[rel desc]
 lea rcx,[rel pixels]
 mov r8d,16
 call nebo_bmp_decode
 test eax,eax
 jnz .fail25
 mov rax,0x4444444444444444
 mov [rel encoded_len],rax
 lea rdi,[rel desc]
 lea rsi,[rel encoded]
 mov edx,69
 lea rcx,[rel encoded_len]
 call nebo_bmp_encode
 cmp eax,NEBO_BMP_E_CAPACITY
 jne .fail26
 mov rax,0x4444444444444444
 cmp qword [rel encoded_len],rax
 jne .fail27
 or word [rel desc+30],NEBO_IMAGE_FLAG_CLOSED
 lea rdi,[rel desc]
 lea rsi,[rel encoded]
 mov edx,70
 lea rcx,[rel encoded_len]
 call nebo_bmp_encode
 cmp eax,NEBO_MEDIA_E_STALE
 jne .fail28
 ; Decode rejects overlap with the borrowed BMP bytes before mutation.
 lea rdi,[rel bmp_fixture]
 mov esi,70
 lea rdx,[rel desc]
 lea rcx,[rel bmp_fixture]
 mov r8d,16
 call nebo_bmp_decode
 cmp eax,NEBO_MEDIA_E_ARGUMENT
 jne .fail29
 xor edi,edi
 jmp .exit
%assign i 1
%rep 29
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
