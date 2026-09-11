bits 64
default rel
%include "runtime/ffi/ffi.inc"
extern nebo_ffi_validate,nebo_ffi_invoke
section .bss
sig resb NEBO_FFI_SIG_SIZE
req resb NEBO_FFI_REQ_SIZE
section .text
foreign_add:
 lea rax,[rdi+rsi]
 ret
global _start
_start:
 mov rax,NEBO_FFI_MAGIC
 mov [sig+NEBO_FFI_SIG_MAGIC],rax
 mov qword [sig+NEBO_FFI_SIG_VERSION],1
 mov qword [sig+NEBO_FFI_SIG_ARGS],2
 mov qword [sig+NEBO_FFI_SIG_RETURN],NEBO_FFI_TYPE_I64
 mov qword [sig+NEBO_FFI_SIG_TYPES],0x11
 mov qword [sig+NEBO_FFI_SIG_LAYOUT_SIZE],16
 lea rax,[sig]
 mov [req+NEBO_FFI_REQ_SIGNATURE],rax
 mov qword [req+NEBO_FFI_REQ_CAPABILITY],0xcafe
 lea rax,[foreign_add]
 mov [req+NEBO_FFI_REQ_FUNCTION],rax
 mov qword [req+NEBO_FFI_REQ_ARG0],20
 mov qword [req+NEBO_FFI_REQ_ARG1],22
 lea rdi,[req]
 call nebo_ffi_invoke
 test eax,eax
 jnz fail
 cmp qword [req+NEBO_FFI_REQ_RESULT],42
 jne fail
 cmp qword [req+NEBO_FFI_REQ_ERROR],0
 jne fail
 mov qword [req+NEBO_FFI_REQ_CAPABILITY],0
 lea rdi,[req]
 call nebo_ffi_invoke
 cmp eax,NEBO_FFI_STATUS_CAPABILITY
 jne fail
 cmp qword [req+NEBO_FFI_REQ_RESULT],42
 jne fail
 mov qword [req+NEBO_FFI_REQ_CAPABILITY],0xcafe
 mov qword [sig+NEBO_FFI_SIG_VERSION],2
 lea rdi,[req]
 call nebo_ffi_invoke
 cmp eax,NEBO_FFI_STATUS_VERSION
 jne fail
 mov qword [sig+NEBO_FFI_SIG_VERSION],1
 mov qword [sig+NEBO_FFI_SIG_LAYOUT_SIZE],24
 lea rdi,[req]
 call nebo_ffi_invoke
 cmp eax,NEBO_FFI_STATUS_LAYOUT
 jne fail
 mov qword [sig+NEBO_FFI_SIG_LAYOUT_SIZE],16
 mov qword [sig+NEBO_FFI_SIG_FLAGS],NEBO_FFI_FLAG_UNWIND
 lea rdi,[req]
 call nebo_ffi_invoke
 cmp eax,NEBO_FFI_STATUS_UNWIND
 jne fail
 mov qword [sig+NEBO_FFI_SIG_FLAGS],0
 mov qword [req+NEBO_FFI_REQ_FUNCTION],0
 lea rdi,[req]
 call nebo_ffi_invoke
 cmp eax,NEBO_FFI_STATUS_CALLBACK
 jne fail
 lea rax,[foreign_add]
 mov [req+NEBO_FFI_REQ_FUNCTION],rax
 mov qword [sig+NEBO_FFI_SIG_TYPES],0x33
 mov qword [req+NEBO_FFI_REQ_LIFETIME],0
 lea rdi,[req]
 call nebo_ffi_invoke
 cmp eax,NEBO_FFI_STATUS_POINTER_LIFETIME
 jne fail
 mov qword [req+NEBO_FFI_REQ_LIFETIME],1
 lea rdi,[req]
 call nebo_ffi_invoke
 test eax,eax
 jnz fail
 mov qword [sig+NEBO_FFI_SIG_ARGS],7
 lea rdi,[req]
 call nebo_ffi_validate
 cmp eax,NEBO_FFI_STATUS_SIGNATURE
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
