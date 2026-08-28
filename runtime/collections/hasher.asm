; TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-F02 bounded non-cryptographic FNV-1a hasher.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"

%define FNV_OFFSET 14695981039346656037
%define FNV_PRIME 1099511628211

section .text
; init(hasher*, seed, mode, process_seed)
NEBOC_ABI_FUNCTION neboc_hasher_init
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 cmp rdx,NEBO_HASH_MODE_DETERMINISTIC
 jne .process_mode
 test rcx,rcx
 jnz .invalid
 jmp .seed_ok
.process_mode:
 cmp rdx,NEBO_HASH_MODE_PROCESS_SEEDED
 jne .invalid
 test rcx,rcx
 jz .invalid
 xor rsi,rcx
.seed_ok:
 mov rax,FNV_OFFSET
 xor rax,rsi
 mov [rdi],rax
 mov [rdi+8],rsi
 mov [rdi+16],rdx
 mov qword [rdi+24],0
 mov rax,NEBO_HASHER_VERSION_TAG
 mov [rdi+NEBO_HASHER_VERSION_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; write_bytes(hasher*, bytes*, length), bounded to 4096 total bytes.
NEBOC_ABI_FUNCTION neboc_hasher_write_bytes
 test rdi,rdi
 jz .write_invalid
 test rdi,7
 jnz .write_invalid
 mov rax,NEBO_HASHER_VERSION_TAG
 cmp [rdi+NEBO_HASHER_VERSION_OFFSET],rax
 jne .write_invalid
 cmp qword [rdi+16],NEBO_HASH_MODE_PROCESS_SEEDED
 ja .write_invalid
 cmp qword [rdi+24],NEBO_HASH_MAX_STREAM_BYTES
 ja .write_invalid
 test rdx,rdx
 jz .write_ok
 test rsi,rsi
 jz .write_invalid
 mov rcx,[rdi+24]
 add rcx,rdx
 jc .write_limit
 cmp rcx,NEBO_DICT_MAX_PAYLOAD_BYTES
 ja .write_limit
 mov rax,[rdi]
 mov r8,FNV_PRIME
 xor r9d,r9d
.loop:
 movzx r10d,byte [rsi+r9]
 xor rax,r10
 imul rax,r8
 inc r9
 cmp r9,rdx
 jb .loop
 mov [rdi],rax
 mov [rdi+24],rcx
.write_ok:
 xor eax,eax
 ret
.write_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.write_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_hasher_finish
 test rdi,rdi
 jz .finish_invalid
 test rdi,7
 jnz .finish_invalid
 mov rcx,NEBO_HASHER_VERSION_TAG
 cmp [rdi+NEBO_HASHER_VERSION_OFFSET],rcx
 jne .finish_invalid
 cmp qword [rdi+16],NEBO_HASH_MODE_PROCESS_SEEDED
 ja .finish_invalid
 cmp qword [rdi+24],NEBO_HASH_MAX_STREAM_BYTES
 ja .finish_invalid
 mov rax,[rdi]
 ret
.finish_invalid:
 xor eax,eax
 ret

; hash_u64(value, seed) -> canonical little-endian FNV-1a hash.
NEBOC_ABI_FUNCTION neboc_hash_u64
 mov rax,FNV_OFFSET
 xor rax,rsi
 mov rcx,8
 mov r8,FNV_PRIME
.u64_loop:
 movzx edx,dil
 xor rax,rdx
 imul rax,r8
 shr rdi,8
 dec rcx
 jnz .u64_loop
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
