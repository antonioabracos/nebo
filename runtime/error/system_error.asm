bits 64
default rel
%define NEBO_SYSTEM_ERROR_BRIDGE_IMPLEMENTATION 1
%include "runtime/error/system_error.inc"
%include "compiler/semantic/system/system_contract.inc"

section .text
global nebo_system_error_map
global nebo_system_error_with_cause

; rdi=Error out,rsi=category,rdx=nonzero raw code,rcx=source id,r8=safe context hash.
; No path, address, argv, secret or message pointer crosses the bridge.
nebo_system_error_map:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBO_ERROR_CATEGORY_FILESYSTEM
 jb .invalid
 cmp rsi,NEBO_ERROR_CATEGORY_HTTP
 ja .invalid
 mov eax,edx
 mov [rdi+NEBO_ERROR_CODE],eax
 mov [rdi+NEBO_ERROR_CATEGORY],si
 mov word [rdi+NEBO_ERROR_FLAGS],0
 mov [rdi+NEBO_ERROR_SOURCE_ID],rcx
 mov qword [rdi+NEBO_ERROR_SPAN_START],0
 mov qword [rdi+NEBO_ERROR_SPAN_END],0
 mov qword [rdi+NEBO_ERROR_MESSAGE],0
 mov qword [rdi+NEBO_ERROR_MESSAGE_LENGTH],0
 mov qword [rdi+NEBO_ERROR_CAUSE_ID],0
 mov [rdi+NEBO_ERROR_CONTEXT_HASH],r8
 ; Retryable is a typed flag, never a string heuristic.
 cmp edx,NEBO_SYSTEM_ERROR_INTERRUPTED
 je .retryable
 cmp edx,NEBO_SYSTEM_ERROR_TIMEOUT
 je .retryable
 xor eax,eax
 ret
.retryable:
 or word [rdi+NEBO_ERROR_FLAGS],NEBO_ERROR_FLAG_RETRYABLE
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret

; rdi=Error, rsi=stable nonzero cause id. Bounded one-link copy-on-write.
nebo_system_error_with_cause:
 test rdi,rdi
 jz .cause_invalid
 test rsi,rsi
 jz .cause_invalid
 cmp qword [rdi+NEBO_ERROR_CAUSE_ID],0
 jne .cause_completed
 mov [rdi+NEBO_ERROR_CAUSE_ID],rsi
 xor eax,eax
 ret
.cause_invalid: mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.cause_completed: mov eax,NEBO_SYSTEM_ERROR_ALREADY_COMPLETED
 ret
