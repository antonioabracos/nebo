bits 64
default rel
%define NEBO_TINY_CAUSAL_IMPLEMENTATION 1
%include "runtime/ai/tiny_causal.inc"
section .text
global nebo_causal_forward
global nebo_kv_init
global nebo_kv_append
global nebo_kv_length
global nebo_kv_truncate
global nebo_causal_context_length

; rdi=tokens u64*, rsi=len, rdx=logits i64[16]. Q16.16 deterministic fixture model.
nebo_causal_forward:
 test rdx,rdx
 jz .forward_argument
 test rsi,rsi
 jz .forward_argument
 cmp rsi,NEBO_CAUSAL_CONTEXT
 ja .forward_limit
 test rdi,rdi
 jz .forward_argument
 xor ecx,ecx
.validate:
 cmp qword [rdi+rcx*8],NEBO_CAUSAL_VOCAB-1
 ja .forward_token
 inc rcx
 cmp rcx,rsi
 jb .validate
 mov r8,[rdi+rsi*8-8]
 imul r8,r8,17
 mov r9,rsi
 shl r9,1
 xor ecx,ecx
.logits:
 lea rax,[rcx+rcx*2]
 add rax,r8
 sub rax,r9
 shl rax,16
 mov [rdx+rcx*8],rax
 inc rcx
 cmp rcx,NEBO_CAUSAL_VOCAB
 jb .logits
 xor eax,eax
 ret
.forward_token:
 mov eax,NEBO_CAUSAL_E_TOKEN
 ret
.forward_limit:
 mov eax,NEBO_CAUSAL_E_LIMIT
 ret
.forward_argument:
 mov eax,NEBO_CAUSAL_E_ARGUMENT
 ret

; Cache layout: length, generation, 32 u64 tokens.
nebo_kv_init:
 test rdi,rdi
 jz .init_argument
 mov qword [rdi],0
 mov qword [rdi+8],1
 xor eax,eax
 ret
.init_argument:
 mov eax,NEBO_CAUSAL_E_ARGUMENT
 ret
nebo_kv_append:
 test rdi,rdi
 jz .append_argument
 cmp rsi,NEBO_CAUSAL_VOCAB-1
 ja .append_token
 mov rax,[rdi]
 cmp rax,NEBO_CAUSAL_CONTEXT
 jae .append_limit
 mov [rdi+rax*8+16],rsi
 inc rax
 mov [rdi],rax
 xor eax,eax
 ret
.append_token:
 mov eax,NEBO_CAUSAL_E_TOKEN
 ret
.append_limit:
 mov eax,NEBO_CAUSAL_E_LIMIT
 ret
.append_argument:
 mov eax,NEBO_CAUSAL_E_ARGUMENT
 ret
nebo_kv_length:
 test rdi,rdi
 jz .length_argument
 test rsi,rsi
 jz .length_argument
 mov rax,[rdi]
 mov [rsi],rax
 xor eax,eax
 ret
.length_argument:
 mov eax,NEBO_CAUSAL_E_ARGUMENT
 ret
nebo_kv_truncate:
 test rdi,rdi
 jz .truncate_argument
 cmp rsi,[rdi]
 ja .truncate_limit
 mov [rdi],rsi
 inc qword [rdi+8]
 xor eax,eax
 ret
.truncate_limit:
 mov eax,NEBO_CAUSAL_E_LIMIT
 ret
.truncate_argument:
 mov eax,NEBO_CAUSAL_E_ARGUMENT
 ret
nebo_causal_context_length:
 test rdi,rdi
 jz .context_argument
 mov qword [rdi],NEBO_CAUSAL_CONTEXT
 xor eax,eax
 ret
.context_argument:
 mov eax,NEBO_CAUSAL_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
