bits 64
default rel
%include "runtime/crypto/sha256.inc"
section .rodata
empty db 0
abc db 'abc'
long_msg db 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'
key1 times 20 db 0x0b
hmac_data1 db 'Hi There'
key2 db 'Jefe'
hmac_data2 db 'what do ya want for nothing?'
expected_empty db 0xe3,0xb0,0xc4,0x42,0x98,0xfc,0x1c,0x14,0x9a,0xfb,0xf4,0xc8,0x99,0x6f,0xb9,0x24,0x27,0xae,0x41,0xe4,0x64,0x9b,0x93,0x4c,0xa4,0x95,0x99,0x1b,0x78,0x52,0xb8,0x55
expected_abc db 0xba,0x78,0x16,0xbf,0x8f,0x01,0xcf,0xea,0x41,0x41,0x40,0xde,0x5d,0xae,0x22,0x23,0xb0,0x03,0x61,0xa3,0x96,0x17,0x7a,0x9c,0xb4,0x10,0xff,0x61,0xf2,0x00,0x15,0xad
expected_long db 0x24,0x8d,0x6a,0x61,0xd2,0x06,0x38,0xb8,0xe5,0xc0,0x26,0x93,0x0c,0x3e,0x60,0x39,0xa3,0x3c,0xe4,0x59,0x64,0xff,0x21,0x67,0xf6,0xec,0xed,0xd4,0x19,0xdb,0x06,0xc1
expected_hmac1 db 0xb0,0x34,0x4c,0x61,0xd8,0xdb,0x38,0x53,0x5c,0xa8,0xaf,0xce,0xaf,0x0b,0xf1,0x2b,0x88,0x1d,0xc2,0x00,0xc9,0x83,0x3d,0xa7,0x26,0xe9,0x37,0x6c,0x2e,0x32,0xcf,0xf7
expected_hmac2 db 0x5b,0xdc,0xc1,0x46,0xbf,0x60,0x75,0x4e,0x6a,0x04,0x24,0x26,0x08,0x95,0x75,0xc7,0x5a,0x00,0x3f,0x08,0x9d,0x27,0x39,0x83,0x9d,0xec,0x58,0xb9,0x64,0xec,0x38,0x43
section .data
secret_data db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
section .bss
ctx resb NEBO_SHA256_CONTEXT_SIZE
digest resb 32
secret resb NEBO_SECRET_BYTES_SIZE
section .text
global _start
_start:
 lea rdi,[empty]
 xor esi,esi
 lea rdx,[digest]
 call nebo_sha256_hash
 test eax,eax
 jnz .fail1
 lea rdi,[digest]
 lea rsi,[expected_empty]
 call compare32
 test eax,eax
 jnz .fail2
 lea rdi,[abc]
 mov esi,3
 lea rdx,[digest]
 call nebo_sha256_hash
 test eax,eax
 jnz .fail3
 lea rdi,[digest]
 lea rsi,[expected_abc]
 call compare32
 test eax,eax
 jnz .fail4
 lea rdi,[long_msg]
 mov esi,56
 lea rdx,[digest]
 call nebo_sha256_hash
 test eax,eax
 jnz .fail5
 lea rdi,[digest]
 lea rsi,[expected_long]
 call compare32
 test eax,eax
 jnz .fail6
 lea rdi,[ctx]
 call nebo_sha256_init
 test eax,eax
 jnz .fail7
 lea rdi,[ctx]
 lea rsi,[abc]
 mov edx,1
 call nebo_sha256_update
 test eax,eax
 jnz .fail8
 lea rdi,[ctx]
 lea rsi,[abc+1]
 mov edx,2
 call nebo_sha256_update
 test eax,eax
 jnz .fail9
 lea rdi,[ctx]
 lea rsi,[digest]
 call nebo_sha256_final
 test eax,eax
 jnz .fail10
 lea rdi,[digest]
 lea rsi,[expected_abc]
 call compare32
 test eax,eax
 jnz .fail11
 lea rdi,[key1]
 mov esi,20
 lea rdx,[hmac_data1]
 mov ecx,8
 lea r8,[digest]
 call nebo_hmac_sha256
 test eax,eax
 jnz .fail12
 lea rdi,[digest]
 lea rsi,[expected_hmac1]
 call compare32
 test eax,eax
 jnz .fail13
 lea rdi,[key2]
 mov esi,4
 lea rdx,[hmac_data2]
 mov ecx,28
 lea r8,[digest]
 call nebo_hmac_sha256
 test eax,eax
 jnz .fail14
 lea rdi,[digest]
 lea rsi,[expected_hmac2]
 call compare32
 test eax,eax
 jnz .fail15
 lea rdi,[key1]
 mov esi,65
 lea rdx,[hmac_data1]
 mov ecx,8
 lea r8,[digest]
 call nebo_hmac_sha256
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail16
 lea rdi,[secret]
 lea rsi,[secret_data]
 mov edx,16
 mov ecx,16
 call nebo_secret_init
 test eax,eax
 jnz .fail17
 cmp qword [secret+NEBO_SECRET_STATE],NEBO_SECRET_STATE_ACTIVE
 jne .fail18
 lea rdi,[secret]
 call nebo_secret_zeroize
 test eax,eax
 jnz .fail19
 cmp qword [secret+NEBO_SECRET_STATE],NEBO_SECRET_STATE_ZEROIZED
 jne .fail20
 cmp qword [secret_data],0
 jne .fail21
 cmp qword [secret_data+8],0
 jne .fail22
 lea rdi,[secret]
 call nebo_secret_zeroize
 cmp eax,NEBO_SYSTEM_ERROR_ALREADY_COMPLETED
 jne .fail23
 lea rdi,[secret]
 lea rsi,[secret_data]
 mov edx,17
 mov ecx,16
 call nebo_secret_init
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail24
 xor edi,edi
 jmp .exit
%assign i 1
%rep 24
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall

compare32:
 xor ecx,ecx
.compare_loop:
 mov rax,[rdi+rcx]
 cmp rax,[rsi+rcx]
 jne .compare_bad
 add rcx,8
 cmp rcx,32
 jb .compare_loop
 xor eax,eax
 ret
.compare_bad:
 mov eax,1
 ret
