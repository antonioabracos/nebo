bits 64
default rel
%define NEBO_TOKENIZER_IMPLEMENTATION 1
%include "runtime/tokenizer/tokenizer.inc"
section .text
global nebo_tokenizer_load
global nebo_tokenizer_encode
global nebo_tokenizer_decode
global nebo_tokenizer_count
global nebo_tokenizer_vocabulary
global nebo_tokenizer_special

; rdi=header32, rsi=len, rdx=State24 {version,vocab,special_count}.
nebo_tokenizer_load:
 test rdi,rdi
 jz .load_argument
 test rdx,rdx
 jz .load_argument
 cmp rsi,32
 jne .load_format
 cmp qword [rdi],NEBO_TOKENIZER_MAGIC
 jne .load_format
 cmp qword [rdi+8],NEBO_TOKENIZER_VERSION
 jne .load_format
 cmp qword [rdi+16],NEBO_TOKENIZER_VOCAB
 jne .load_format
 mov rax,[rdi]
 xor rax,[rdi+8]
 xor rax,[rdi+16]
 cmp rax,[rdi+24]
 jne .load_format
 mov qword [rdx],NEBO_TOKENIZER_VERSION
 mov qword [rdx+8],NEBO_TOKENIZER_VOCAB
 mov qword [rdx+16],0
 xor eax,eax
 ret
.load_format:
 mov eax,NEBO_TOKENIZER_E_FORMAT
 ret
.load_argument:
 mov eax,NEBO_TOKENIZER_E_ARGUMENT
 ret

; rdi=bytes, rsi=len, rdx=u64 tokens, rcx=capacity, r8=count*.
nebo_tokenizer_encode:
 test r8,r8
 jz .encode_argument
 cmp rsi,NEBO_TOKENIZER_MAX_TOKENS
 ja .encode_limit
 cmp rcx,rsi
 jb .encode_limit
 test rsi,rsi
 jz .encode_publish
 test rdi,rdi
 jz .encode_argument
 test rdx,rdx
 jz .encode_argument
 xor r9d,r9d
.encode_loop:
 movzx eax,byte [rdi+r9]
 mov [rdx+r9*8],rax
 inc r9
 cmp r9,rsi
 jb .encode_loop
.encode_publish:
 mov [r8],rsi
 xor eax,eax
 ret
.encode_limit:
 mov eax,NEBO_TOKENIZER_E_LIMIT
 ret
.encode_argument:
 mov eax,NEBO_TOKENIZER_E_ARGUMENT
 ret

; rdi=u64 tokens, rsi=len, rdx=bytes, rcx=capacity, r8=count*.
nebo_tokenizer_decode:
 test r8,r8
 jz .decode_argument
 cmp rsi,NEBO_TOKENIZER_MAX_TOKENS
 ja .decode_limit
 cmp rcx,rsi
 jb .decode_limit
 test rsi,rsi
 jz .decode_publish
 test rdi,rdi
 jz .decode_argument
 test rdx,rdx
 jz .decode_argument
 xor r9d,r9d
.decode_validate:
 cmp qword [rdi+r9*8],255
 ja .decode_token
 inc r9
 cmp r9,rsi
 jb .decode_validate
 xor r9d,r9d
.decode_loop:
 mov al,byte [rdi+r9*8]
 mov [rdx+r9],al
 inc r9
 cmp r9,rsi
 jb .decode_loop
.decode_publish:
 mov [r8],rsi
 xor eax,eax
 ret
.decode_token:
 mov eax,NEBO_TOKENIZER_E_TOKEN
 ret
.decode_limit:
 mov eax,NEBO_TOKENIZER_E_LIMIT
 ret
.decode_argument:
 mov eax,NEBO_TOKENIZER_E_ARGUMENT
 ret

; rdi=byte length, rsi=count*.
nebo_tokenizer_count:
 test rsi,rsi
 jz .count_argument
 cmp rdi,NEBO_TOKENIZER_MAX_TOKENS
 ja .count_limit
 mov [rsi],rdi
 xor eax,eax
 ret
.count_limit:
 mov eax,NEBO_TOKENIZER_E_LIMIT
 ret
.count_argument:
 mov eax,NEBO_TOKENIZER_E_ARGUMENT
 ret

; rdi=vocabulary size*.
nebo_tokenizer_vocabulary:
 test rdi,rdi
 jz .vocab_argument
 mov qword [rdi],NEBO_TOKENIZER_VOCAB
 xor eax,eax
 ret
.vocab_argument:
 mov eax,NEBO_TOKENIZER_E_ARGUMENT
 ret

; rdi=token, rsi=is_special*. Byte tokenizer has no special tokens.
nebo_tokenizer_special:
 test rsi,rsi
 jz .special_argument
 cmp rdi,255
 ja .special_token
 mov qword [rsi],0
 xor eax,eax
 ret
.special_token:
 mov eax,NEBO_TOKENIZER_E_TOKEN
 ret
.special_argument:
 mov eax,NEBO_TOKENIZER_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
