bits 64
default rel
%define NEBO_SHA256_IMPLEMENTATION 1
%include "runtime/crypto/sha256.inc"

section .rodata align=4
sha256_k:
 dd 0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5
 dd 0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5
 dd 0xd807aa98,0x12835b01,0x243185be,0x550c7dc3
 dd 0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174
 dd 0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc
 dd 0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da
 dd 0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7
 dd 0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967
 dd 0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13
 dd 0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85
 dd 0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3
 dd 0xd192e819,0xd6990624,0xf40e3585,0x106aa070
 dd 0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5
 dd 0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3
 dd 0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208
 dd 0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2

section .text
global nebo_sha256_init
global nebo_sha256_update
global nebo_sha256_final
global nebo_sha256_hash
global nebo_hmac_sha256
global nebo_secret_init
global nebo_secret_zeroize

nebo_sha256_init:
 test rdi,rdi
 jz .init_invalid
 mov dword [rdi],0x6a09e667
 mov dword [rdi+4],0xbb67ae85
 mov dword [rdi+8],0x3c6ef372
 mov dword [rdi+12],0xa54ff53a
 mov dword [rdi+16],0x510e527f
 mov dword [rdi+20],0x9b05688c
 mov dword [rdi+24],0x1f83d9ab
 mov dword [rdi+28],0x5be0cd19
 mov qword [rdi+NEBO_SHA256_TOTAL],0
 mov qword [rdi+NEBO_SHA256_BUFFERED],0
 xor eax,eax
 ret
.init_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret

; rdi=context, rsi=data, rdx=length.
nebo_sha256_update:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .update_invalid
 test r14,r14
 jz .update_success
 test r13,r13
 jz .update_invalid
 mov rax,[r12+NEBO_SHA256_TOTAL]
 add rax,r14
 jc .update_limit
 mov rcx,0x1fffffffffffffff
 cmp rax,rcx
 ja .update_limit
 mov [r12+NEBO_SHA256_TOTAL],rax
 xor ebx,ebx
.update_loop:
 cmp rbx,r14
 jae .update_success
 mov rcx,[r12+NEBO_SHA256_BUFFERED]
 mov al,[r13+rbx]
 mov [r12+NEBO_SHA256_BUFFER+rcx],al
 inc rcx
 inc rbx
 mov [r12+NEBO_SHA256_BUFFERED],rcx
 cmp rcx,64
 jne .update_loop
 mov rdi,r12
 lea rsi,[r12+NEBO_SHA256_BUFFER]
 call sha256_compress
 mov qword [r12+NEBO_SHA256_BUFFERED],0
 jmp .update_loop
.update_success:
 xor eax,eax
 jmp .update_return
.update_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .update_return
.update_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
.update_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=context, rsi=32-byte output.
nebo_sha256_final:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,rsi
 test r12,r12
 jz .final_invalid
 test rbx,rbx
 jz .final_invalid
 mov rcx,[r12+NEBO_SHA256_BUFFERED]
 cmp rcx,64
 jae .final_invalid
 mov byte [r12+NEBO_SHA256_BUFFER+rcx],0x80
 inc rcx
 cmp rcx,56
 jbe .final_zero_to_56
.final_zero_to_64:
 cmp rcx,64
 jae .final_extra_block
 mov byte [r12+NEBO_SHA256_BUFFER+rcx],0
 inc rcx
 jmp .final_zero_to_64
.final_extra_block:
 mov rdi,r12
 lea rsi,[r12+NEBO_SHA256_BUFFER]
 call sha256_compress
 xor ecx,ecx
.final_zero_to_56:
 cmp rcx,56
 jae .final_length
 mov byte [r12+NEBO_SHA256_BUFFER+rcx],0
 inc rcx
 jmp .final_zero_to_56
.final_length:
 mov rax,[r12+NEBO_SHA256_TOTAL]
 shl rax,3
 bswap rax
 mov [r12+NEBO_SHA256_BUFFER+56],rax
 mov rdi,r12
 lea rsi,[r12+NEBO_SHA256_BUFFER]
 call sha256_compress
 xor ecx,ecx
.final_output:
 mov eax,[r12+rcx*4]
 bswap eax
 mov [rbx+rcx*4],eax
 inc ecx
 cmp ecx,8
 jb .final_output
 mov qword [r12+NEBO_SHA256_BUFFERED],0
 xor eax,eax
 jmp .final_return
.final_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
.final_return:
 pop r12
 pop rbx
 ret

; rdi=data rsi=len rdx=out.
nebo_sha256_hash:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 sub rsp,NEBO_SHA256_CONTEXT_SIZE
 mov rbx,rsp
 mov rdi,rbx
 call nebo_sha256_init
 test eax,eax
 jnz .hash_return
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call nebo_sha256_update
 test eax,eax
 jnz .hash_return
 mov rdi,rbx
 mov rsi,r14
 call nebo_sha256_final
.hash_return:
 add rsp,NEBO_SHA256_CONTEXT_SIZE
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=key rsi=keylen rdx=data rcx=datalen r8=out.
nebo_hmac_sha256:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test rbx,rbx
 jz .hmac_invalid
 test r12,r12
 jz .hmac_invalid
 test r13,r13
 jz .hmac_invalid
 cmp r13,64
 ja .hmac_limit
 test r15,r15
 jz .hmac_data_ok
 test r14,r14
 jz .hmac_invalid
.hmac_data_ok:
 sub rsp,208
 xor ecx,ecx
.hmac_ipad:
 mov al,0x36
 cmp rcx,r13
 jae .hmac_ipad_store
 xor al,[r12+rcx]
.hmac_ipad_store:
 mov [rsp+112+rcx],al
 inc rcx
 cmp rcx,64
 jb .hmac_ipad
 mov rdi,rsp
 call nebo_sha256_init
 mov rdi,rsp
 lea rsi,[rsp+112]
 mov edx,64
 call nebo_sha256_update
 mov rdi,rsp
 mov rsi,r14
 mov rdx,r15
 call nebo_sha256_update
 mov rdi,rsp
 lea rsi,[rsp+176]
 call nebo_sha256_final
 xor ecx,ecx
.hmac_opad:
 mov al,0x5c
 cmp rcx,r13
 jae .hmac_opad_store
 xor al,[r12+rcx]
.hmac_opad_store:
 mov [rsp+112+rcx],al
 inc rcx
 cmp rcx,64
 jb .hmac_opad
 mov rdi,rsp
 call nebo_sha256_init
 mov rdi,rsp
 lea rsi,[rsp+112]
 mov edx,64
 call nebo_sha256_update
 mov rdi,rsp
 lea rsi,[rsp+176]
 mov edx,32
 call nebo_sha256_update
 mov rdi,rsp
 mov rsi,rbx
 call nebo_sha256_final
 ; wipe context, pads and inner digest.
 xor ecx,ecx
.hmac_wipe:
 mov byte [rsp+rcx],0
 inc rcx
 cmp rcx,208
 jb .hmac_wipe
 mfence
 add rsp,208
 xor eax,eax
 jmp .hmac_return
.hmac_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .hmac_return
.hmac_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
.hmac_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=SecretBytes descriptor, rsi=data, rdx=len, rcx=capacity.
nebo_secret_init:
 test rdi,rdi
 jz .secret_invalid
 test rsi,rsi
 jz .secret_invalid
 test rdx,rdx
 jz .secret_invalid
 cmp rdx,rcx
 ja .secret_limit
 mov [rdi+NEBO_SECRET_DATA],rsi
 mov [rdi+NEBO_SECRET_LENGTH],rdx
 mov [rdi+NEBO_SECRET_CAPACITY],rcx
 mov qword [rdi+NEBO_SECRET_STATE],NEBO_SECRET_STATE_ACTIVE
 mov qword [rdi+32],0
 mov qword [rdi+40],0
 xor eax,eax
 ret
.secret_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.secret_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

nebo_secret_zeroize:
 test rdi,rdi
 jz .zero_invalid
 cmp qword [rdi+NEBO_SECRET_STATE],NEBO_SECRET_STATE_ACTIVE
 jne .zero_state
 mov r8,[rdi+NEBO_SECRET_DATA]
 mov rcx,[rdi+NEBO_SECRET_LENGTH]
 xor eax,eax
.zero_loop:
 cmp rax,rcx
 jae .zero_done
 mov byte [r8+rax],0
 inc rax
 jmp .zero_loop
.zero_done:
 mfence
 mov qword [rdi+NEBO_SECRET_LENGTH],0
 mov qword [rdi+NEBO_SECRET_STATE],NEBO_SECRET_STATE_ZEROIZED
 xor eax,eax
 ret
.zero_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.zero_state:
 mov eax,NEBO_SYSTEM_ERROR_ALREADY_COMPLETED
 ret

; rdi=context, rsi=64-byte block. Preserves SysV callee-saved registers.
sha256_compress:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 sub rsp,264
 xor ecx,ecx
.schedule_first:
 mov eax,[rsi+rcx*4]
 bswap eax
 mov [rsp+rcx*4],eax
 inc ecx
 cmp ecx,16
 jb .schedule_first
.schedule_extend:
 mov eax,[rsp+rcx*4-60]
 mov edx,eax
 ror eax,7
 ror edx,18
 xor eax,edx
 mov edx,[rsp+rcx*4-60]
 shr edx,3
 xor eax,edx
 mov edi,[rsp+rcx*4-8]
 mov edx,edi
 ror edi,17
 ror edx,19
 xor edi,edx
 mov edx,[rsp+rcx*4-8]
 shr edx,10
 xor edi,edx
 add eax,[rsp+rcx*4-64]
 add eax,[rsp+rcx*4-28]
 add eax,edi
 mov [rsp+rcx*4],eax
 inc ecx
 cmp ecx,64
 jb .schedule_extend
 mov r8d,[rbx]
 mov r9d,[rbx+4]
 mov r10d,[rbx+8]
 mov r11d,[rbx+12]
 mov r12d,[rbx+16]
 mov r13d,[rbx+20]
 mov r14d,[rbx+24]
 mov r15d,[rbx+28]
 lea rsi,[rel sha256_k]
 xor ebp,ebp
.round:
 mov eax,r12d
 ror eax,6
 mov edx,r12d
 ror edx,11
 xor eax,edx
 mov edx,r12d
 ror edx,25
 xor eax,edx
 mov ecx,r12d
 and ecx,r13d
 mov edx,r12d
 not edx
 and edx,r14d
 xor ecx,edx
 mov edi,r15d
 add edi,eax
 add edi,ecx
 add edi,[rsi+rbp*4]
 add edi,[rsp+rbp*4]
 mov eax,r8d
 ror eax,2
 mov edx,r8d
 ror edx,13
 xor eax,edx
 mov edx,r8d
 ror edx,22
 xor eax,edx
 mov ecx,r8d
 and ecx,r9d
 mov edx,r8d
 and edx,r10d
 xor ecx,edx
 mov edx,r9d
 and edx,r10d
 xor ecx,edx
 add eax,ecx
 mov [rsp+256],eax
 mov r15d,r14d
 mov r14d,r13d
 mov r13d,r12d
 mov r12d,r11d
 add r12d,edi
 mov r11d,r10d
 mov r10d,r9d
 mov r9d,r8d
 mov r8d,edi
 add r8d,[rsp+256]
 inc ebp
 cmp ebp,64
 jb .round
 add [rbx],r8d
 add [rbx+4],r9d
 add [rbx+8],r10d
 add [rbx+12],r11d
 add [rbx+16],r12d
 add [rbx+20],r13d
 add [rbx+24],r14d
 add [rbx+28],r15d
 add rsp,264
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
