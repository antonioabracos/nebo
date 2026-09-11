; Linux x86-64 cryptographic primitives. AES block encryption is delegated to
; the kernel AF_ALG implementation; the bounded GCM composition follows NIST
; SP 800-38D and authenticates before publishing plaintext. PBKDF2-HMAC-SHA256
; is built from the already vector-tested HMAC owner.
bits 64
default rel
%define NEBO_AEAD_KDF_IMPLEMENTATION 1
%include "runtime/crypto/aead_kdf.inc"

%define SYS_READ 0
%define SYS_CLOSE 3
%define SYS_SOCKET 41
%define SYS_ACCEPT 43
%define SYS_SENDMSG 46
%define SYS_BIND 49
%define SYS_SETSOCKOPT 54
%define AF_ALG 38
%define SOCK_SEQPACKET 5
%define SOL_ALG 279
%define ALG_SET_KEY 1
%define ALG_SET_OP 3
%define ALG_OP_DECRYPT 0
%define ALG_OP_ENCRYPT 1
%define EINTR 4

section .text
global nebo_aead_seal
global nebo_aead_open
global nebo_key_derivation_derive

nebo_aead_seal:
 mov esi,ALG_OP_ENCRYPT
 jmp aead_run

nebo_aead_open:
 mov esi,ALG_OP_DECRYPT
 jmp aead_run

; rdi=AeadRequest, esi=operation. eax=status, rdx=published bytes.
aead_run:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13d,esi
 mov r14,-1
 mov r15,-1
 test r12,r12
 jz .invalid
 cmp qword [r12+NEBO_AEAD_REQUEST_KEY_LENGTH],32
 jne .invalid
 cmp qword [r12+NEBO_AEAD_REQUEST_NONCE_LENGTH],12
 jne .invalid
 mov rax,[r12+NEBO_AEAD_REQUEST_INPUT_LENGTH]
 cmp rax,NEBO_AEAD_MAX_INPUT
 ja .limit
 mov rcx,[r12+NEBO_AEAD_REQUEST_AAD_LENGTH]
 cmp rcx,NEBO_AEAD_MAX_AAD
 ja .limit
 test rcx,rcx
 jz .aad_ok
 cmp qword [r12+NEBO_AEAD_REQUEST_AAD],0
 je .invalid
.aad_ok:
 cmp qword [r12+NEBO_AEAD_REQUEST_KEY],0
 je .invalid
 cmp qword [r12+NEBO_AEAD_REQUEST_NONCE],0
 je .invalid
 cmp qword [r12+NEBO_AEAD_REQUEST_INPUT_LENGTH],0
 je .input_pointer_ok
 cmp qword [r12+NEBO_AEAD_REQUEST_INPUT],0
 je .invalid
.input_pointer_ok:
 cmp qword [r12+NEBO_AEAD_REQUEST_OUTPUT],0
 je .invalid
 cmp r13d,ALG_OP_DECRYPT
 jne .seal_size
 cmp rax,NEBO_AEAD_TAG_SIZE
 jb .invalid
 sub rax,NEBO_AEAD_TAG_SIZE
 jmp .size_ready
.seal_size:
 add rax,NEBO_AEAD_TAG_SIZE
.size_ready:
 cmp rax,[r12+NEBO_AEAD_REQUEST_OUTPUT_CAPACITY]
 ja .limit
 mov rbx,rax
 ; 0..87 sockaddr_alg; 128..4239 failure-atomic output; the remaining
 ; slots hold H, GHASH state, counter, keystream, lengths and tag.
 sub rsp,4672
 xor eax,eax
 mov ecx,584
 mov rdi,rsp
 rep stosq
 mov word [rsp],AF_ALG
 mov rax,0x7265687069636b73
 mov [rsp+2],rax                    ; "skcipher"
 mov rax,0x2973656128626365
 mov [rsp+24],rax                   ; "ecb(aes)"
 mov eax,SYS_SOCKET
 mov edi,AF_ALG
 mov esi,SOCK_SEQPACKET
 xor edx,edx
 syscall
 cmp rax,-4095
 jae .unsupported_stack
 mov r14,rax
 mov eax,SYS_BIND
 mov rdi,r14
 mov rsi,rsp
 mov edx,88
 syscall
 cmp rax,-4095
 jae .unsupported_close_parent
 mov eax,SYS_SETSOCKOPT
 mov rdi,r14
 mov esi,SOL_ALG
 mov edx,ALG_SET_KEY
 mov r10,[r12+NEBO_AEAD_REQUEST_KEY]
 mov r8,[r12+NEBO_AEAD_REQUEST_KEY_LENGTH]
 syscall
 cmp rax,-4095
 jae .crypto_close_parent
.accept_retry:
 mov eax,SYS_ACCEPT
 mov rdi,r14
 xor esi,esi
 xor edx,edx
 syscall
 cmp rax,-EINTR
 je .accept_retry
 cmp rax,-4095
 jae .crypto_close_parent
 mov r15,rax

 ; H = AES_K(0^128).
 lea rdi,[rsp+4288]
 xor eax,eax
 mov ecx,2
 rep stosq
 mov edi,r15d
 lea rsi,[rsp+4288]
 lea rdx,[rsp+4256]
 call aes_encrypt_block
 test eax,eax
 jnz .crypto_close_both

 ; J0 = nonce || 0x00000001 for the public 96-bit nonce profile.
 mov rsi,[r12+NEBO_AEAD_REQUEST_NONCE]
 lea rdi,[rsp+4304]
 movsq
 movsd
 mov dword [rsp+4316],0x01000000

 ; The ciphertext length excludes the authentication tag on open.
 mov rax,[r12+NEBO_AEAD_REQUEST_INPUT_LENGTH]
 cmp r13d,ALG_OP_ENCRYPT
 je .cipher_length_ready
 sub rax,NEBO_AEAD_TAG_SIZE
.cipher_length_ready:
 mov [rsp+4368],rax

 ; GHASH every AAD block, zero-padding only the final partial block.
 mov qword [rsp+4376],0
.aad_loop:
 mov rax,[rsp+4376]
 cmp rax,[r12+NEBO_AEAD_REQUEST_AAD_LENGTH]
 jae .crypt_start
 lea rdi,[rsp+4288]
 xor eax,eax
 mov ecx,2
 rep stosq
 mov rax,[r12+NEBO_AEAD_REQUEST_AAD_LENGTH]
 sub rax,[rsp+4376]
 mov ecx,16
 cmp rax,16
 cmovb rcx,rax
 mov rsi,[r12+NEBO_AEAD_REQUEST_AAD]
 add rsi,[rsp+4376]
 lea rdi,[rsp+4288]
 rep movsb
 lea rdi,[rsp+4272]
 lea rsi,[rsp+4288]
 lea rdx,[rsp+4256]
 call gcm_ghash_block
 mov rax,[r12+NEBO_AEAD_REQUEST_AAD_LENGTH]
 sub rax,[rsp+4376]
 mov ecx,16
 cmp rax,16
 cmovb rcx,rax
 add [rsp+4376],rcx
 jmp .aad_loop

 ; CTR encrypt/decrypt into private scratch, while GHASH always consumes
 ; ciphertext. No caller-visible plaintext exists before tag verification.
.crypt_start:
 mov qword [rsp+4376],0
.crypt_loop:
 mov rax,[rsp+4376]
 cmp rax,[rsp+4368]
 jae .length_block
 mov eax,[rsp+4316]
 bswap eax
 inc eax
 bswap eax
 mov [rsp+4316],eax
 mov edi,r15d
 lea rsi,[rsp+4304]
 lea rdx,[rsp+4320]
 call aes_encrypt_block
 test eax,eax
 jnz .crypto_close_both
 mov rax,[rsp+4368]
 sub rax,[rsp+4376]
 mov ecx,16
 cmp rax,16
 cmovb rcx,rax
 mov rsi,[r12+NEBO_AEAD_REQUEST_INPUT]
 add rsi,[rsp+4376]
 lea rdi,[rsp+128]
 add rdi,[rsp+4376]
 lea r8,[rsp+4320]
.xor_block:
 test rcx,rcx
 jz .hash_ciphertext
 mov al,[rsi]
 xor al,[r8]
 mov [rdi],al
 inc rsi
 inc rdi
 inc r8
 dec rcx
 jmp .xor_block
.hash_ciphertext:
 lea rdi,[rsp+4288]
 xor eax,eax
 mov ecx,2
 rep stosq
 mov rax,[rsp+4368]
 sub rax,[rsp+4376]
 mov ecx,16
 cmp rax,16
 cmovb rcx,rax
 cmp r13d,ALG_OP_ENCRYPT
 jne .hash_open_input
 lea rsi,[rsp+128]
 add rsi,[rsp+4376]
 jmp .hash_copy
.hash_open_input:
 mov rsi,[r12+NEBO_AEAD_REQUEST_INPUT]
 add rsi,[rsp+4376]
.hash_copy:
 lea rdi,[rsp+4288]
 rep movsb
 lea rdi,[rsp+4272]
 lea rsi,[rsp+4288]
 lea rdx,[rsp+4256]
 call gcm_ghash_block
 mov rax,[rsp+4368]
 sub rax,[rsp+4376]
 mov ecx,16
 cmp rax,16
 cmovb rcx,rax
 add [rsp+4376],rcx
 jmp .crypt_loop

 ; GHASH encodes the exact AAD and ciphertext lengths in bits, big-endian.
.length_block:
 mov rax,[r12+NEBO_AEAD_REQUEST_AAD_LENGTH]
 shl rax,3
 bswap rax
 mov [rsp+4336],rax
 mov rax,[rsp+4368]
 shl rax,3
 bswap rax
 mov [rsp+4344],rax
 lea rdi,[rsp+4272]
 lea rsi,[rsp+4336]
 lea rdx,[rsp+4256]
 call gcm_ghash_block

 ; Tag = AES_K(J0) xor GHASH. Comparison is constant-time on open.
 mov dword [rsp+4316],0x01000000
 mov edi,r15d
 lea rsi,[rsp+4304]
 lea rdx,[rsp+4352]
 call aes_encrypt_block
 test eax,eax
 jnz .crypto_close_both
 mov rax,[rsp+4272]
 xor [rsp+4352],rax
 mov rax,[rsp+4280]
 xor [rsp+4360],rax
 cmp r13d,ALG_OP_ENCRYPT
 jne .verify_tag
 lea rdi,[rsp+128]
 add rdi,[rsp+4368]
 lea rsi,[rsp+4352]
 mov ecx,16
 rep movsb
 jmp .publish
.verify_tag:
 mov rsi,[r12+NEBO_AEAD_REQUEST_INPUT]
 add rsi,[rsp+4368]
 lea rdi,[rsp+4352]
 xor eax,eax
 mov ecx,16
.tag_compare:
 mov dl,[rsi]
 xor dl,[rdi]
 or al,dl
 inc rsi
 inc rdi
 loop .tag_compare
 test al,al
 jnz .auth_failure
.publish:
 mov rcx,rbx
 mov rdi,[r12+NEBO_AEAD_REQUEST_OUTPUT]
 lea rsi,[rsp+128]
 rep movsb
 mov rdx,rbx
 xor ebx,ebx
 jmp .close_success
.auth_failure:
 mov ebx,NEBO_SYSTEM_ERROR_CRYPTO
 xor edx,edx
 jmp .close_success
.crypto_close_both:
 mov ebx,NEBO_SYSTEM_ERROR_CRYPTO
 xor edx,edx
.close_success:
 mov eax,SYS_CLOSE
 mov rdi,r15
 syscall
 mov eax,SYS_CLOSE
 mov rdi,r14
 syscall
 mov eax,ebx
 add rsp,4672
 jmp .return
.crypto_close_parent:
 mov ebx,NEBO_SYSTEM_ERROR_CRYPTO
 jmp .close_parent
.unsupported_close_parent:
 mov ebx,NEBO_SYSTEM_ERROR_UNSUPPORTED_TARGET
.close_parent:
 mov eax,SYS_CLOSE
 mov rdi,r14
 syscall
 add rsp,4672
 mov eax,ebx
 xor edx,edx
 jmp .return
.unsupported_stack:
 add rsp,4672
 mov eax,NEBO_SYSTEM_ERROR_UNSUPPORTED_TARGET
 xor edx,edx
 jmp .return
.invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .return
.limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
.return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Encrypt one 16-byte block through an accepted AF_ALG ecb(aes) socket.
; edi=operation fd, rsi=input, rdx=output. eax=status.
aes_encrypt_block:
 push rbx
 push r12
 mov ebx,edi
 mov r12,rsi
 mov r8,rdx
 sub rsp,96
 xor eax,eax
 mov ecx,12
 mov rdi,rsp
 rep stosq
 lea rax,[rsp+56]
 mov [rsp+16],rax
 mov qword [rsp+24],1
 lea rax,[rsp+72]
 mov [rsp+32],rax
 mov qword [rsp+40],24
 mov [rsp+56],r12
 mov qword [rsp+64],16
 mov qword [rsp+72],20
 mov dword [rsp+80],SOL_ALG
 mov dword [rsp+84],ALG_SET_OP
 mov dword [rsp+88],ALG_OP_ENCRYPT
.aes_send_retry:
 mov eax,SYS_SENDMSG
 mov edi,ebx
 mov rsi,rsp
 xor edx,edx
 syscall
 cmp rax,-EINTR
 je .aes_send_retry
 cmp rax,16
 jne .aes_error
.aes_read_retry:
 mov eax,SYS_READ
 mov edi,ebx
 mov rsi,r8
 mov edx,16
 syscall
 cmp rax,-EINTR
 je .aes_read_retry
 cmp rax,16
 jne .aes_error
 xor eax,eax
 jmp .aes_return
.aes_error:
 mov eax,NEBO_SYSTEM_ERROR_CRYPTO
.aes_return:
 add rsp,96
 pop r12
 pop rbx
 ret

; GHASH one 16-byte big-endian block: Y = (Y xor X) * H in GF(2^128).
; rdi=Y, rsi=X, rdx=H. The fixed 128-round path is data independent.
gcm_ghash_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r8,[rdi]
 bswap r8
 mov r9,[rdi+8]
 bswap r9
 mov rax,[rsi]
 bswap rax
 xor r8,rax
 mov rax,[rsi+8]
 bswap rax
 xor r9,rax
 mov r10,[rdx]
 bswap r10
 mov r11,[rdx+8]
 bswap r11
 xor r12d,r12d
 xor r13d,r13d
 mov ecx,128
.ghash_round:
 mov rax,r8
 sar rax,63
 mov rdx,r10
 and rdx,rax
 xor r12,rdx
 mov rdx,r11
 and rdx,rax
 xor r13,rdx
 shld r8,r9,1
 shl r9,1
 mov rax,r11
 and eax,1
 neg rax
 shrd r11,r10,1
 shr r10,1
 mov rdx,0xe100000000000000
 and rdx,rax
 xor r10,rdx
 dec ecx
 jnz .ghash_round
 bswap r12
 bswap r13
 mov [rbx],r12
 mov [rbx+8],r13
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; PBKDF2-HMAC-SHA256, RFC 8018 profile with one 32-byte output block.
; rdi=KdfRequest. The output is untouched until every iteration succeeds.
nebo_key_derivation_derive:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .kdf_invalid
 cmp qword [r12+NEBO_KDF_REQUEST_VERSION],NEBO_KDF_PBKDF2_HMAC_SHA256_V1
 jne .kdf_invalid
 mov r13,[r12+NEBO_KDF_REQUEST_PASSWORD_LENGTH]
 test r13,r13
 jz .kdf_invalid
 cmp r13,64
 ja .kdf_limit
 mov r14,[r12+NEBO_KDF_REQUEST_SALT_LENGTH]
 test r14,r14
 jz .kdf_invalid
 cmp r14,60
 ja .kdf_limit
 cmp qword [r12+NEBO_KDF_REQUEST_OUTPUT_LENGTH],32
 jne .kdf_limit
 mov r15,[r12+NEBO_KDF_REQUEST_ITERATIONS]
 test r15,r15
 jz .kdf_invalid
 cmp r15,100000
 ja .kdf_limit
 cmp qword [r12+NEBO_KDF_REQUEST_PASSWORD],0
 je .kdf_invalid
 cmp qword [r12+NEBO_KDF_REQUEST_SALT],0
 je .kdf_invalid
 cmp qword [r12+NEBO_KDF_REQUEST_OUTPUT],0
 je .kdf_invalid
 sub rsp,128
 mov rdi,rsp
 mov rsi,[r12+NEBO_KDF_REQUEST_SALT]
 mov rcx,r14
 rep movsb
 mov dword [rsp+r14],0x01000000
 mov rdi,[r12+NEBO_KDF_REQUEST_PASSWORD]
 mov rsi,r13
 mov rdx,rsp
 lea rcx,[r14+4]
 lea r8,[rsp+64]
 call nebo_hmac_sha256
 test eax,eax
 jnz .kdf_stack_error
 mov rax,[rsp+64]
 mov [rsp+96],rax
 mov rax,[rsp+72]
 mov [rsp+104],rax
 mov rax,[rsp+80]
 mov [rsp+112],rax
 mov rax,[rsp+88]
 mov [rsp+120],rax
 mov ebx,1
.kdf_round:
 cmp rbx,r15
 jae .kdf_publish
 mov rdi,[r12+NEBO_KDF_REQUEST_PASSWORD]
 mov rsi,r13
 lea rdx,[rsp+64]
 mov ecx,32
 lea r8,[rsp+64]
 call nebo_hmac_sha256
 test eax,eax
 jnz .kdf_stack_error
 mov rax,[rsp+64]
 xor [rsp+96],rax
 mov rax,[rsp+72]
 xor [rsp+104],rax
 mov rax,[rsp+80]
 xor [rsp+112],rax
 mov rax,[rsp+88]
 xor [rsp+120],rax
 inc rbx
 jmp .kdf_round
.kdf_publish:
 mov rdi,[r12+NEBO_KDF_REQUEST_OUTPUT]
 lea rsi,[rsp+96]
 mov ecx,4
 rep movsq
 xor eax,eax
 jmp .kdf_wipe
.kdf_stack_error:
 ; preserve the primitive's exact status.
.kdf_wipe:
 mov ebx,eax
 xor eax,eax
 mov ecx,16
 mov rdi,rsp
 rep stosq
 mfence
 add rsp,128
 mov eax,ebx
 jmp .kdf_return
.kdf_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .kdf_return
.kdf_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
.kdf_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
