; Public Text.hash uses the canonical bounded deterministic FNV-1a Hasher.
; Its 64-bit result is the Int bit pattern; no process seed or network input.
bits 64
default rel
%include "compiler/semantic/collections/hash_map_contract.inc"
extern nebo_runtime_textual_text_byte_length
extern neboc_hasher_init
extern neboc_hasher_write_bytes
extern neboc_hasher_finish
extern nebo_runtime_trap
global nebo_runtime_textual_text_hash
section .text
nebo_runtime_textual_text_hash:
 push rbx
 sub rsp,48
 mov rbx,rdi
 call nebo_runtime_textual_text_byte_length
 cmp rax,NEBO_HASH_MAX_STREAM_BYTES
 ja .trap
 mov [rsp+40],rax
 mov rdi,rsp
 xor esi,esi
 mov edx,NEBO_HASH_MODE_DETERMINISTIC
 xor ecx,ecx
 call neboc_hasher_init
 test eax,eax
 jnz .trap
 mov rdi,rsp
 mov rsi,[rbx]
 mov rdx,[rsp+40]
 call neboc_hasher_write_bytes
 test eax,eax
 jnz .trap
 mov rdi,rsp
 call neboc_hasher_finish
 add rsp,48
 pop rbx
 ret
.trap:
 mov edi,46
 jmp nebo_runtime_trap
section .note.GNU-stack noalloc noexec nowrite progbits
