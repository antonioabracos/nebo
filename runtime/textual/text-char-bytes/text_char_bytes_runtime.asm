; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-PF004 isolated Text/Char/Bytes runtime prototype
bits 64
default rel
%include "runtime/textual/text-char-bytes/text_char_bytes_runtime.inc"

global neboc_runtime_char_literal
global neboc_runtime_text_byte_length
global neboc_runtime_text_contract
global neboc_runtime_text_codepoint_count
global neboc_runtime_char_codepoint
global neboc_runtime_bytes_empty
global neboc_runtime_bytes_byte_length
global neboc_runtime_empty_bytes_descriptor

section .rodata align=8
neboc_runtime_empty_bytes_data: db 0
align 8
neboc_runtime_empty_bytes_descriptor:
 dq neboc_runtime_empty_bytes_data
 dq 0
 dd NEBO_RUNTIME_BYTES_FLAGS_EMPTY
 dw NEBO_RUNTIME_BYTES_ELEMENT_WIDTH
 dw NEBO_RUNTIME_LIFETIME_STATIC

section .text
align 16
neboc_runtime_char_literal:
 mov eax,edi
 cld
 ret
align 16
neboc_runtime_text_byte_length:
 mov rax,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_LENGTH_OFFSET]
 cld
 ret
align 16
neboc_runtime_text_contract:
 mov eax,NEBO_RUNTIME_TEXT_ABI_VERSION
 mov edx,NEBO_TEXT_CHAR_BYTES_RUNTIME_TEXT_DESCRIPTOR_SIZE
 mov ecx,NEBO_RUNTIME_TEXT_ENCODING_UTF8
 mov r8d,NEBO_RUNTIME_TEXT_FLAGS_LITERAL
 cld
 ret
align 16
neboc_runtime_text_codepoint_count:
 mov rcx,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_LENGTH_OFFSET]
 mov rsi,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_DATA_OFFSET]
 xor eax,eax
 test rcx,rcx
 jz .count_done
.count_loop:
 mov dl,[rsi]
 and dl,0xc0
 cmp dl,0x80
 je .continuation
 inc rax
.continuation:
 inc rsi
 dec rcx
 jnz .count_loop
.count_done:
 cld
 ret
align 16
neboc_runtime_char_codepoint:
 mov eax,edi
 cld
 ret
align 16
neboc_runtime_bytes_empty:
 lea rax,[rel neboc_runtime_empty_bytes_descriptor]
 cld
 ret
align 16
neboc_runtime_bytes_byte_length:
 mov rax,[rdi+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET]
 cld
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
