; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-F05 explicit bounded x86-64 System V Assembly FFI.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/ffi/ffi.inc"
section .text
NEBOC_ABI_FUNCTION nebo_ffi_validate
 test rdi,rdi
 jz .bad
 mov rsi,[rdi]
 test rsi,rsi
 jz .bad
 mov rax,NEBO_FFI_MAGIC
 cmp [rsi+NEBO_FFI_SIG_MAGIC],rax
 jne .signature
 cmp qword [rsi+NEBO_FFI_SIG_VERSION],NEBO_FFI_VERSION
 jne .version
 cmp qword [rsi+NEBO_FFI_SIG_ARGS],NEBO_FFI_MAX_ARGS
 ja .signature
 cmp qword [rsi+NEBO_FFI_SIG_RETURN],NEBO_FFI_TYPE_VOID
 ja .signature
 cmp qword [rsi+NEBO_FFI_SIG_LAYOUT_SIZE],48
 ja .layout
 cmp qword [rsi+NEBO_FFI_SIG_RESERVED],0
 jne .signature
 mov rax,[rsi+NEBO_FFI_SIG_FLAGS]
 test rax,NEBO_FFI_FLAG_UNWIND
 jnz .unwind
 and rax,~NEBO_FFI_FLAG_CALLBACK
 jnz .signature
 xor eax,eax
 ret
.version: mov eax,NEBO_FFI_STATUS_VERSION
 ret
.signature: mov eax,NEBO_FFI_STATUS_SIGNATURE
 ret
.layout: mov eax,NEBO_FFI_STATUS_LAYOUT
 ret
.unwind: mov eax,NEBO_FFI_STATUS_UNWIND
 ret
.bad: mov eax,NEBO_FFI_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_ffi_invoke
 xor r10d,r10d
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_FFI_REQ_ERROR],0
 mov r10,rdi
 cmp qword [r10+NEBO_FFI_REQ_CAPABILITY],0
 je .cap
 mov rsi,[r10+NEBO_FFI_REQ_SIGNATURE]
 test rsi,rsi
 jz .bad
 mov rax,NEBO_FFI_MAGIC
 cmp [rsi+NEBO_FFI_SIG_MAGIC],rax
 jne .signature
 cmp qword [rsi+NEBO_FFI_SIG_VERSION],NEBO_FFI_VERSION
 jne .version
 cmp qword [rsi+NEBO_FFI_SIG_ARGS],2
 jne .signature
 cmp qword [rsi+NEBO_FFI_SIG_RETURN],NEBO_FFI_TYPE_I64
 jne .signature
 cmp qword [rsi+NEBO_FFI_SIG_LAYOUT_SIZE],16
 jne .layout
 mov rax,[rsi+NEBO_FFI_SIG_FLAGS]
 test rax,NEBO_FFI_FLAG_UNWIND
 jnz .unwind
 and rax,~NEBO_FFI_FLAG_CALLBACK
 jnz .signature
 mov rax,[rsi+NEBO_FFI_SIG_TYPES]
 cmp rax,0x11
 je .types_ok
 cmp rax,0x33
 jne .signature
 cmp qword [r10+NEBO_FFI_REQ_LIFETIME],0
 je .lifetime
.types_ok:
 mov rax,[r10+NEBO_FFI_REQ_FUNCTION]
 test rax,rax
 jz .callback
 mov rdi,[r10+NEBO_FFI_REQ_ARG0]
 mov rsi,[r10+NEBO_FFI_REQ_ARG1]
 sub rsp,8
 call rax
 add rsp,8
 mov [r10+NEBO_FFI_REQ_RESULT],rax
 xor eax,eax
 ret
.cap: mov eax,NEBO_FFI_STATUS_CAPABILITY
 jmp .error
.version: mov eax,NEBO_FFI_STATUS_VERSION
 jmp .error
.signature: mov eax,NEBO_FFI_STATUS_SIGNATURE
 jmp .error
.layout: mov eax,NEBO_FFI_STATUS_LAYOUT
 jmp .error
.lifetime: mov eax,NEBO_FFI_STATUS_POINTER_LIFETIME
 jmp .error
.callback: mov eax,NEBO_FFI_STATUS_CALLBACK
 jmp .error
.unwind: mov eax,NEBO_FFI_STATUS_UNWIND
 jmp .error
.bad: mov eax,NEBO_FFI_STATUS_INVALID
.error:
 test r10,r10
 jz .ret
 mov [r10+NEBO_FFI_REQ_ERROR],rax
.ret: ret
section .note.GNU-stack noalloc noexec nowrite progbits
