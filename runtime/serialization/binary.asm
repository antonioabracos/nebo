bits 64
default rel
%include "compiler/semantic/system/codec_contract.inc"

section .text
global nebo_binary_encoder_init
global nebo_binary_encoder_put_u32
global nebo_binary_encoder_put_u64
global nebo_binary_encoder_put_bytes
global nebo_binary_encoder_enter
global nebo_binary_encoder_leave
global nebo_binary_encoder_finish
global nebo_binary_decoder_init
global nebo_binary_decoder_get_u32
global nebo_binary_decoder_get_u64
global nebo_binary_decoder_get_bytes
global nebo_binary_decoder_enter
global nebo_binary_decoder_leave
global nebo_binary_decoder_finish

; rdi=ctx, rsi=buffer, rdx=capacity, rcx=version, r8=endian,
; r9=(max_entries<<32)|max_depth.
nebo_binary_encoder_init:
 test rdi,rdi
 jz binary_malformed
 test rsi,rsi
 jz binary_malformed
 cmp rdx,NEBO_BINARY_HEADER_SIZE
 jb binary_limit
 test rcx,rcx
 jz binary_malformed
 cmp rcx,0xffff
 ja binary_malformed
 cmp r8,NEBO_BINARY_ENDIAN_BIG
 ja binary_malformed
 mov eax,r9d
 test eax,eax
 jz binary_limit
 shr r9,32
 test r9d,r9d
 jz binary_limit
 mov [rdi+NEBO_BINARY_BUFFER],rsi
 mov [rdi+NEBO_BINARY_CAPACITY],rdx
 mov qword [rdi+NEBO_BINARY_POSITION],NEBO_BINARY_HEADER_SIZE
 mov [rdi+NEBO_BINARY_LIMIT],rdx
 mov [rdi+NEBO_BINARY_VERSION],ecx
 mov [rdi+NEBO_BINARY_ENDIAN],r8d
 mov dword [rdi+NEBO_BINARY_DEPTH],0
 mov [rdi+NEBO_BINARY_MAX_DEPTH],eax
 mov dword [rdi+NEBO_BINARY_ENTRIES],0
 mov [rdi+NEBO_BINARY_MAX_ENTRIES],r9d
 mov dword [rdi+NEBO_BINARY_FLAGS],1
 mov dword [rdi+NEBO_BINARY_RESERVED],0
 mov dword [rsi],NEBO_BINARY_MAGIC
 mov [rsi+4],cx
 mov [rsi+6],r8b
 mov byte [rsi+7],0
 mov dword [rsi+8],0
 xor eax,eax
 ret

nebo_binary_encoder_put_u32:
 push r12
 mov r12,rdi
 mov r8,rsi
 mov esi,4
 call binary_encoder_reserve
 test eax,eax
 jnz .put32_return
 cmp dword [r12+NEBO_BINARY_ENDIAN],NEBO_BINARY_ENDIAN_LITTLE
 je .put32_little
 bswap r8d
.put32_little:
 mov [rdx],r8d
.put32_return:
 pop r12
 ret

nebo_binary_encoder_put_u64:
 push r12
 mov r12,rdi
 mov r8,rsi
 mov esi,8
 call binary_encoder_reserve
 test eax,eax
 jnz .put64_return
 cmp dword [r12+NEBO_BINARY_ENDIAN],NEBO_BINARY_ENDIAN_LITTLE
 je .put64_little
 bswap r8
.put64_little:
 mov [rdx],r8
.put64_return:
 pop r12
 ret

; rdi=ctx, rsi=bytes, rdx=len. Encodes u32 length and payload as one entry.
nebo_binary_encoder_put_bytes:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r13,r13
 jz .bytes_malformed
 mov ecx,r14d
 cmp r14,rcx
 ja .bytes_limit
 mov rsi,r14
 add rsi,4
 jc .bytes_limit
 call binary_encoder_reserve
 test eax,eax
 jnz .bytes_return
 mov r8d,r14d
 cmp dword [r12+NEBO_BINARY_ENDIAN],NEBO_BINARY_ENDIAN_LITTLE
 je .bytes_length
 bswap r8d
.bytes_length:
 mov [rdx],r8d
 lea rdi,[rdx+4]
 mov rsi,r13
 mov rcx,r14
 cld
 rep movsb
 xor eax,eax
 jmp .bytes_return
.bytes_malformed:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jmp .bytes_return
.bytes_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.bytes_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

nebo_binary_encoder_enter:
 jmp binary_enter
nebo_binary_encoder_leave:
 jmp binary_leave

nebo_binary_encoder_finish:
 test rdi,rdi
 jz binary_malformed
 cmp dword [rdi+NEBO_BINARY_FLAGS],1
 jne binary_malformed
 cmp dword [rdi+NEBO_BINARY_DEPTH],0
 jne binary_malformed
 mov rdx,[rdi+NEBO_BINARY_POSITION]
 mov rax,rdx
 sub rax,NEBO_BINARY_HEADER_SIZE
 mov ecx,eax
 cmp rax,rcx
 ja binary_limit
 mov rcx,[rdi+NEBO_BINARY_BUFFER]
 mov [rcx+8],eax
 xor eax,eax
 ret

; Same init ABI; header length defines bounded payload limit.
nebo_binary_decoder_init:
 test rdi,rdi
 jz binary_malformed
 test rsi,rsi
 jz binary_malformed
 cmp rdx,NEBO_BINARY_HEADER_SIZE
 jb binary_malformed
 cmp dword [rsi],NEBO_BINARY_MAGIC
 jne binary_malformed
 cmp [rsi+4],cx
 jne binary_malformed
 cmp byte [rsi+6],r8b
 jne binary_malformed
 cmp r8,NEBO_BINARY_ENDIAN_BIG
 ja binary_malformed
 mov eax,r9d
 test eax,eax
 jz binary_limit
 shr r9,32
 test r9d,r9d
 jz binary_limit
 mov r10d,[rsi+8]
 add r10,NEBO_BINARY_HEADER_SIZE
 jc binary_malformed
 cmp r10,rdx
 ja binary_malformed
 mov [rdi+NEBO_BINARY_BUFFER],rsi
 mov [rdi+NEBO_BINARY_CAPACITY],rdx
 mov qword [rdi+NEBO_BINARY_POSITION],NEBO_BINARY_HEADER_SIZE
 mov [rdi+NEBO_BINARY_LIMIT],r10
 mov [rdi+NEBO_BINARY_VERSION],ecx
 mov [rdi+NEBO_BINARY_ENDIAN],r8d
 mov dword [rdi+NEBO_BINARY_DEPTH],0
 mov [rdi+NEBO_BINARY_MAX_DEPTH],eax
 mov dword [rdi+NEBO_BINARY_ENTRIES],0
 mov [rdi+NEBO_BINARY_MAX_ENTRIES],r9d
 mov dword [rdi+NEBO_BINARY_FLAGS],2
 mov dword [rdi+NEBO_BINARY_RESERVED],0
 xor eax,eax
 ret

nebo_binary_decoder_get_u32:
 push r12
 mov r12,rdi
 mov esi,4
 call binary_decoder_take
 test eax,eax
 jnz .get32_return
 mov edx,[rdx]
 cmp dword [r12+NEBO_BINARY_ENDIAN],NEBO_BINARY_ENDIAN_LITTLE
 je .get32_return
 bswap edx
.get32_return:
 pop r12
 ret

nebo_binary_decoder_get_u64:
 push r12
 mov r12,rdi
 mov esi,8
 call binary_decoder_take
 test eax,eax
 jnz .get64_return
 mov rdx,[rdx]
 cmp dword [r12+NEBO_BINARY_ENDIAN],NEBO_BINARY_ENDIAN_LITTLE
 je .get64_return
 bswap rdx
.get64_return:
 pop r12
 ret

; rdi=ctx. eax=status, rdx=borrowed bytes, rcx=len.
nebo_binary_decoder_get_bytes:
 push rbx
 push r12
 mov r12,rdi
 mov esi,4
 call binary_decoder_take
 test eax,eax
 jnz .get_bytes_zero
 mov ebx,[rdx]
 cmp dword [r12+NEBO_BINARY_ENDIAN],NEBO_BINARY_ENDIAN_LITTLE
 je .get_bytes_length
 bswap ebx
.get_bytes_length:
 ; Length prefix and payload count as one logical entry, undo prefix count.
 dec dword [r12+NEBO_BINARY_ENTRIES]
 mov rsi,rbx
 call binary_decoder_take
 test eax,eax
 jnz .get_bytes_zero
 mov rcx,rbx
 jmp .get_bytes_return
.get_bytes_zero:
 xor edx,edx
 xor ecx,ecx
.get_bytes_return:
 pop r12
 pop rbx
 ret

nebo_binary_decoder_enter:
 jmp binary_enter
nebo_binary_decoder_leave:
 jmp binary_leave

; rdi=ctx, rsi=trailing policy.
nebo_binary_decoder_finish:
 test rdi,rdi
 jz binary_malformed
 cmp dword [rdi+NEBO_BINARY_FLAGS],2
 jne binary_malformed
 cmp dword [rdi+NEBO_BINARY_DEPTH],0
 jne binary_malformed
 cmp qword [rdi+NEBO_BINARY_POSITION],0
 je binary_malformed
 mov rax,[rdi+NEBO_BINARY_POSITION]
 cmp rax,[rdi+NEBO_BINARY_LIMIT]
 jne binary_malformed
 cmp rsi,NEBO_BINARY_TRAILING_ALLOW
 je .decoder_finish_ok
 cmp rsi,NEBO_BINARY_TRAILING_REJECT
 jne binary_malformed
 mov rax,[rdi+NEBO_BINARY_CAPACITY]
 cmp rax,[rdi+NEBO_BINARY_LIMIT]
 jne binary_malformed
.decoder_finish_ok:
 xor eax,eax
 ret

; r12=encoder ctx, esi=bytes. eax status, rdx=reserved pointer.
binary_encoder_reserve:
 test r12,r12
 jz binary_malformed
 cmp dword [r12+NEBO_BINARY_FLAGS],1
 jne binary_malformed
 mov eax,[r12+NEBO_BINARY_ENTRIES]
 cmp eax,[r12+NEBO_BINARY_MAX_ENTRIES]
 jae binary_limit
 mov rax,[r12+NEBO_BINARY_POSITION]
 mov rcx,rax
 add rcx,rsi
 jc binary_limit
 cmp rcx,[r12+NEBO_BINARY_CAPACITY]
 ja binary_limit
 mov rdx,[r12+NEBO_BINARY_BUFFER]
 add rdx,rax
 mov [r12+NEBO_BINARY_POSITION],rcx
 inc dword [r12+NEBO_BINARY_ENTRIES]
 xor eax,eax
 ret

; r12=decoder ctx, esi=bytes. eax status, rdx=borrowed pointer.
binary_decoder_take:
 test r12,r12
 jz binary_malformed
 cmp dword [r12+NEBO_BINARY_FLAGS],2
 jne binary_malformed
 mov eax,[r12+NEBO_BINARY_ENTRIES]
 cmp eax,[r12+NEBO_BINARY_MAX_ENTRIES]
 jae binary_limit
 mov rax,[r12+NEBO_BINARY_POSITION]
 mov rcx,rax
 add rcx,rsi
 jc binary_malformed
 cmp rcx,[r12+NEBO_BINARY_LIMIT]
 ja binary_malformed
 mov rdx,[r12+NEBO_BINARY_BUFFER]
 add rdx,rax
 mov [r12+NEBO_BINARY_POSITION],rcx
 inc dword [r12+NEBO_BINARY_ENTRIES]
 xor eax,eax
 ret

binary_enter:
 test rdi,rdi
 jz binary_malformed
 mov eax,[rdi+NEBO_BINARY_DEPTH]
 cmp eax,[rdi+NEBO_BINARY_MAX_DEPTH]
 jae binary_limit
 inc eax
 mov [rdi+NEBO_BINARY_DEPTH],eax
 xor eax,eax
 ret
binary_leave:
 test rdi,rdi
 jz binary_malformed
 cmp dword [rdi+NEBO_BINARY_DEPTH],0
 je binary_malformed
 dec dword [rdi+NEBO_BINARY_DEPTH]
 xor eax,eax
 ret
binary_malformed:
 mov eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 ret
binary_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 ret
