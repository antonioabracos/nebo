; FILESYSTEM-PATHS-E-FORMATOS-F02 typed quote clone, splice revalidation and hygienic identities.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/meta/code_model.inc"
%include "compiler/meta/quote_splice.inc"
extern nebo_meta_fragment_validate
section .text
NEBOC_ABI_FUNCTION nebo_meta_quote_clone
 test rdi,rdi
 jz .bad
 test rsi,rsi
 jz .bad
 test r8,r8
 jz .identity
 test r9,r9
 jz .identity
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,r8
 mov r14,r9
 mov rdi,rbx
 mov rsi,rdx
 mov rdx,rcx
 call nebo_meta_fragment_validate
 test eax,eax
 jnz .restore
 mov rsi,rbx
 mov rdi,r12
 mov ecx,NEBO_META_FRAGMENT_SIZE/8
 rep movsq
 mov qword [r12+NEBO_META_FRAGMENT_ORIGIN],NEBO_META_ORIGIN_GENERATED
 mov [r12+NEBO_META_FRAGMENT_SPAN_ID],r13
 mov [r12+NEBO_META_FRAGMENT_SYMBOL_ID],r14
.restore:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.bad: mov eax,NEBO_META_STATUS_INVALID_ARGUMENT
 ret
.identity: mov eax,NEBO_META_STATUS_IDENTITY_REQUIRED
 ret

NEBOC_ABI_FUNCTION nebo_meta_splice_validate
 jmp nebo_meta_fragment_validate

NEBOC_ABI_FUNCTION nebo_meta_fresh_symbol
 ; seed, expansion identity and ordinal map to a deterministic nonzero identity.
 mov rax,rdi
 mov rcx,0x100000001b3
 imul rax,rcx
 xor rax,rsi
 rol rax,17
 xor rax,rdx
 imul rax,rcx
 test rax,rax
 jnz .done
 mov eax,1
.done: ret

NEBOC_ABI_FUNCTION nebo_meta_capture_validate
 test rdi,rdi
 jz .identity
 cmp rsi,NEBO_META_CAPTURE_EXPLICIT
 jne .denied
 xor eax,eax
 ret
.identity: mov eax,NEBO_META_STATUS_IDENTITY_REQUIRED
 ret
.denied: mov eax,NEBO_META_STATUS_CAPTURE_DENIED
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
