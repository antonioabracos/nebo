; Nebo Assembly — BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF004 caller-owned binding slot primitives
bits 64
default rel
%include "runtime/bindings/binding_runtime.inc"
global neboc_runtime_store_bool
global neboc_runtime_load_bool
global neboc_runtime_store_i64
global neboc_runtime_load_i64
global neboc_runtime_store_f64
global neboc_runtime_load_f64
global neboc_runtime_store_ptr
global neboc_runtime_load_ptr
global neboc_runtime_store_char
global neboc_runtime_load_char
section .text
align 16
neboc_runtime_store_bool: mov [rdi],sil
 cld
 ret
align 16
neboc_runtime_load_bool: movzx eax,byte [rdi]
 cld
 ret
align 16
neboc_runtime_store_i64: mov [rdi],rsi
 cld
 ret
align 16
neboc_runtime_load_i64: mov rax,[rdi]
 cld
 ret
align 16
neboc_runtime_store_f64: movsd [rdi],xmm0
 cld
 ret
align 16
neboc_runtime_load_f64: movsd xmm0,[rdi]
 cld
 ret
align 16
neboc_runtime_store_ptr: mov [rdi],rsi
 cld
 ret
align 16
neboc_runtime_load_ptr: mov rax,[rdi]
 cld
 ret
align 16
neboc_runtime_store_char: mov [rdi],esi
 cld
 ret
align 16
neboc_runtime_load_char: mov eax,[rdi]
 cld
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
