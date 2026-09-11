bits 64
default rel
%include "runtime/serialization/binary.inc"

section .rodata
blob db 'xyz'

section .bss
encoder resb NEBO_BINARY_CONTEXT_SIZE
decoder resb NEBO_BINARY_CONTEXT_SIZE
buffer resb 128
big_buffer resb 32

section .text
global _start
_start:
 lea rdi,[encoder]
 lea rsi,[buffer]
 mov edx,128
 mov ecx,3
 mov r8d,NEBO_BINARY_ENDIAN_LITTLE
 mov r9,0x0000000800000004
 call nebo_binary_encoder_init
 test eax,eax
 jnz .fail1
 cmp dword [buffer],NEBO_BINARY_MAGIC
 jne .fail2
 lea rdi,[encoder]
 mov esi,0x11223344
 call nebo_binary_encoder_put_u32
 test eax,eax
 jnz .fail3
 lea rdi,[encoder]
 mov rsi,0x0102030405060708
 call nebo_binary_encoder_put_u64
 test eax,eax
 jnz .fail4
 lea rdi,[encoder]
 call nebo_binary_encoder_enter
 test eax,eax
 jnz .fail5
 lea rdi,[encoder]
 lea rsi,[blob]
 mov edx,3
 call nebo_binary_encoder_put_bytes
 test eax,eax
 jnz .fail6
 lea rdi,[encoder]
 call nebo_binary_encoder_leave
 test eax,eax
 jnz .fail7
 lea rdi,[encoder]
 call nebo_binary_encoder_finish
 test eax,eax
 jnz .fail8
 cmp edx,31
 jne .fail9
 cmp dword [buffer+8],19
 jne .fail10
 lea rdi,[decoder]
 lea rsi,[buffer]
 mov edx,31
 mov ecx,3
 mov r8d,NEBO_BINARY_ENDIAN_LITTLE
 mov r9,0x0000000800000004
 call nebo_binary_decoder_init
 test eax,eax
 jnz .fail11
 lea rdi,[decoder]
 call nebo_binary_decoder_get_u32
 test eax,eax
 jnz .fail12
 cmp edx,0x11223344
 jne .fail13
 lea rdi,[decoder]
 call nebo_binary_decoder_get_u64
 test eax,eax
 jnz .fail14
 mov rax,0x0102030405060708
 cmp rdx,rax
 jne .fail15
 lea rdi,[decoder]
 call nebo_binary_decoder_enter
 test eax,eax
 jnz .fail16
 lea rdi,[decoder]
 call nebo_binary_decoder_get_bytes
 test eax,eax
 jnz .fail17
 cmp ecx,3
 jne .fail18
 cmp word [rdx],0x7978
 jne .fail19
 cmp byte [rdx+2],'z'
 jne .fail20
 lea rdi,[decoder]
 call nebo_binary_decoder_leave
 test eax,eax
 jnz .fail21
 lea rdi,[decoder]
 mov esi,NEBO_BINARY_TRAILING_REJECT
 call nebo_binary_decoder_finish
 test eax,eax
 jnz .fail22
 lea rdi,[decoder]
 lea rsi,[buffer]
 mov edx,31
 mov ecx,4
 mov r8d,NEBO_BINARY_ENDIAN_LITTLE
 mov r9,0x0000000800000004
 call nebo_binary_decoder_init
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail23
 lea rdi,[decoder]
 lea rsi,[buffer]
 mov edx,30
 mov ecx,3
 mov r8d,NEBO_BINARY_ENDIAN_LITTLE
 mov r9,0x0000000800000004
 call nebo_binary_decoder_init
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail24
 mov byte [buffer+31],0xaa
 lea rdi,[decoder]
 lea rsi,[buffer]
 mov edx,32
 mov ecx,3
 mov r8d,NEBO_BINARY_ENDIAN_LITTLE
 mov r9,0x0000000800000004
 call nebo_binary_decoder_init
 test eax,eax
 jnz .fail25
 lea rdi,[decoder]
 call nebo_binary_decoder_get_u32
 lea rdi,[decoder]
 call nebo_binary_decoder_get_u64
 lea rdi,[decoder]
 call nebo_binary_decoder_get_bytes
 lea rdi,[decoder]
 mov esi,NEBO_BINARY_TRAILING_REJECT
 call nebo_binary_decoder_finish
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail26
 lea rdi,[decoder]
 mov esi,NEBO_BINARY_TRAILING_ALLOW
 call nebo_binary_decoder_finish
 test eax,eax
 jnz .fail27
 lea rdi,[encoder]
 lea rsi,[big_buffer]
 mov edx,32
 mov ecx,1
 mov r8d,NEBO_BINARY_ENDIAN_BIG
 mov r9,0x0000000100000001
 call nebo_binary_encoder_init
 test eax,eax
 jnz .fail28
 lea rdi,[encoder]
 mov esi,0x11223344
 call nebo_binary_encoder_put_u32
 test eax,eax
 jnz .fail29
 cmp byte [big_buffer+12],0x11
 jne .fail30
 cmp byte [big_buffer+15],0x44
 jne .fail31
 lea rdi,[encoder]
 mov esi,1
 call nebo_binary_encoder_put_u32
 cmp eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jne .fail32
 lea rdi,[encoder]
 call nebo_binary_encoder_enter
 test eax,eax
 jnz .fail33
 lea rdi,[encoder]
 call nebo_binary_encoder_enter
 cmp eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jne .fail34
 xor edi,edi
 jmp .exit
.fail1: mov edi,1
 jmp .exit
.fail2: mov edi,2
 jmp .exit
.fail3: mov edi,3
 jmp .exit
.fail4: mov edi,4
 jmp .exit
.fail5: mov edi,5
 jmp .exit
.fail6: mov edi,6
 jmp .exit
.fail7: mov edi,7
 jmp .exit
.fail8: mov edi,8
 jmp .exit
.fail9: mov edi,9
 jmp .exit
.fail10: mov edi,10
 jmp .exit
.fail11: mov edi,11
 jmp .exit
.fail12: mov edi,12
 jmp .exit
.fail13: mov edi,13
 jmp .exit
.fail14: mov edi,14
 jmp .exit
.fail15: mov edi,15
 jmp .exit
.fail16: mov edi,16
 jmp .exit
.fail17: mov edi,17
 jmp .exit
.fail18: mov edi,18
 jmp .exit
.fail19: mov edi,19
 jmp .exit
.fail20: mov edi,20
 jmp .exit
.fail21: mov edi,21
 jmp .exit
.fail22: mov edi,22
 jmp .exit
.fail23: mov edi,23
 jmp .exit
.fail24: mov edi,24
 jmp .exit
.fail25: mov edi,25
 jmp .exit
.fail26: mov edi,26
 jmp .exit
.fail27: mov edi,27
 jmp .exit
.fail28: mov edi,28
 jmp .exit
.fail29: mov edi,29
 jmp .exit
.fail30: mov edi,30
 jmp .exit
.fail31: mov edi,31
 jmp .exit
.fail32: mov edi,32
 jmp .exit
.fail33: mov edi,33
 jmp .exit
.fail34: mov edi,34
.exit:
 mov eax,60
 syscall
