; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF004 caller-owned inline Option/Result primitives
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/scalars/option_result_runtime.inc"
section .text

; RDI=slot, RSI=tag. Canonicalizes all bytes and leaves payload zero.
NEBOC_ABI_FUNCTION neboc_runtime_store_zero_payload
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 ret

; RDI=slot, RSI=tag, RDX=zero-extended or full-width integer payload.
NEBOC_ABI_FUNCTION neboc_runtime_store_integer
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 mov [rdi+NEBO_RUNTIME_PAYLOAD_OFFSET],rdx
 ret

; RDI=slot, RSI=tag, XMM0=binary64 payload.
NEBOC_ABI_FUNCTION neboc_runtime_store_float
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 movq [rdi+NEBO_RUNTIME_PAYLOAD_OFFSET],xmm0
 ret

; RDI=slot -> RAX=zero-extended tag.
NEBOC_ABI_FUNCTION neboc_runtime_load_tag
 movzx eax,byte [rdi+NEBO_RUNTIME_TAG_OFFSET]
 ret

; RDI=slot -> RAX=raw payload bits.
NEBOC_ABI_FUNCTION neboc_runtime_load_integer
 mov rax,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
 ret

; RDI=slot -> XMM0=binary64 payload.
NEBOC_ABI_FUNCTION neboc_runtime_load_float
 movq xmm0,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
 ret

; RDI=slot, RSI=expected tag -> RAX canonical Bool.
NEBOC_ABI_FUNCTION neboc_runtime_tag_test
 movzx eax,byte [rdi+NEBO_RUNTIME_TAG_OFFSET]
 cmp rax,rsi
 sete al
 movzx eax,al
 ret

; RDI=slot, RSI=success tag, RDX=fallback -> RAX payload or fallback.
NEBOC_ABI_FUNCTION neboc_runtime_unwrap_integer
 mov rax,rdx
 cmp byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 jne .done
 mov rax,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
.done:
 ret

; RDI=slot, RSI=success tag, XMM0=fallback -> XMM0 payload or unchanged fallback.
NEBOC_ABI_FUNCTION neboc_runtime_unwrap_float
 cmp byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 jne .done
 movq xmm0,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
.done:
 ret

; Option canonicality: tag 0/1, padding zero, and None payload zero.
NEBOC_ABI_FUNCTION neboc_runtime_validate_option
 movzx eax,byte [rdi]
 cmp eax,1
 ja .bad
 mov rcx,[rdi]
 and rcx,-256
 jnz .bad
 test eax,eax
 jnz .good
 cmp qword [rdi+8],0
 jne .bad
.good:
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; Result canonicality: tag 0/1 and padding zero; both variants carry a payload.
NEBOC_ABI_FUNCTION neboc_runtime_validate_result
 movzx eax,byte [rdi]
 cmp eax,1
 ja .bad
 mov rcx,[rdi]
 and rcx,-256
 jnz .bad
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; Register-level SysV aggregate prototype for INTEGER/INTEGER values.
; RDI=tag, RSI=payload -> RAX=tag, RDX=payload.
NEBOC_ABI_FUNCTION neboc_runtime_roundtrip_integer_aggregate
 mov rax,rdi
 mov rdx,rsi
 ret

; Register-level SysV aggregate prototype for INTEGER/SSE values.
; RDI=tag, XMM0=payload -> RAX=tag, XMM0=payload.
NEBOC_ABI_FUNCTION neboc_runtime_roundtrip_sse_aggregate
 mov rax,rdi
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
