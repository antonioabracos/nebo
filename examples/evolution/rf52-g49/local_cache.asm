bits 64
default rel
%include "compiler/cache/local_cache.inc"
global _start
extern neboc_compiler_cache_open,neboc_cache_key_new
extern neboc_cache_store,neboc_cache_lookup,neboc_host_process_exit

section .data
key_input: dq 1,0x11,0x21,0x31,0x41,0x51,0,NEBOC_CACHE_SCHEMA_VERSION
payload: db "artifact-one"

section .bss align=16
cache: resb NEBOC_CACHE_CTX_SIZE
entries: resb NEBOC_CACHE_ENTRY_SIZE*4
config: resb NEBOC_CACHE_CONFIG_SIZE
key: resb NEBOC_CACHE_KEY_SIZE
result: resb NEBOC_CACHE_RESULT_SIZE

section .text
_start:
 sub rsp,8
 lea rax,[rel entries]
 mov [rel config+NEBOC_CACHE_CONFIG_ENTRIES_OFFSET],rax
 mov qword [rel config+NEBOC_CACHE_CONFIG_PATH_DIGEST_OFFSET],0xcace
 mov qword [rel config+NEBOC_CACHE_CONFIG_POLICY_OFFSET],NEBOC_CACHE_MODE_READ_WRITE
 mov qword [rel config+NEBOC_CACHE_CONFIG_CAPABILITY_OFFSET],0xca01
 mov qword [rel config+NEBOC_CACHE_CONFIG_CAPACITY_OFFSET],4
 mov qword [rel config+NEBOC_CACHE_CONFIG_MAX_BYTES_OFFSET],64
 mov qword [rel config+NEBOC_CACHE_CONFIG_SCHEMA_OFFSET],NEBOC_CACHE_SCHEMA_VERSION
 lea rdi,[rel cache]
 lea rsi,[rel config]
 call neboc_compiler_cache_open
 test eax,eax
 jne .done
 lea rdi,[rel key]
 lea rsi,[rel key_input]
 call neboc_cache_key_new
 test eax,eax
 jne .done
 lea rdi,[rel cache]
 lea rsi,[rel key]
 lea rdx,[rel payload]
 mov ecx,12
 mov r8,0xe0e63357c77f7932
 xor r9d,r9d
 call neboc_cache_store
 test eax,eax
 jne .done
 lea rdi,[rel cache]
 lea rsi,[rel key]
 lea rdx,[rel result]
 call neboc_cache_lookup
.done:
 mov edi,eax
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
