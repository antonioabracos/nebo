; RF172-P02: public typed `.console()` receivers reach retained ConsoleDocument.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/document/console_document.inc"

extern nebo_runtime_console_publish_text
extern nebo_runtime_console_publish_int
extern nebo_runtime_console_publish_bool
extern nebo_runtime_console_context
extern nebo_console_domain_from_handle
extern nebo_console_document_copy_plain_text
extern neboc_host_process_exit

global _start

section .rodata align=8
text_bytes: db 'Nebo'
text_descriptor:
 dq text_bytes,4
 dd 0
 dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
expected_bytes: db 'Nebo42true'

section .bss align=16
domain_ptr: resq 1
plain_length: resq 1
plain_bytes: resb 32

section .text
_start:
 lea rdi,[rel text_descriptor]
 call nebo_runtime_console_publish_text
 mov r12,rax
 mov edi,42
 call nebo_runtime_console_publish_int
 cmp rax,r12
 jne test_fail
 mov edi,1
 call nebo_runtime_console_publish_bool
 cmp rax,r12
 jne test_fail

 lea rdi,[rel nebo_runtime_console_context]
 mov rsi,r12
 lea rdx,[rel domain_ptr]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz test_fail
 mov rbx,[rel domain_ptr]
 mov rbx,[rbx+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
 test rbx,rbx
 jz test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET],4
 jne test_fail
 mov rax,[rbx+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
 cmp dword [rax+NEBO_CONSOLE_NODE_HEADER_SIZE+NEBO_CONSOLE_NODE_KIND_OFFSET],NEBO_CONSOLE_NODE_KIND_TEXT
 jne test_fail
 cmp dword [rax+2*NEBO_CONSOLE_NODE_HEADER_SIZE+NEBO_CONSOLE_NODE_KIND_OFFSET],NEBO_CONSOLE_NODE_KIND_INT
 jne test_fail
 cmp dword [rax+3*NEBO_CONSOLE_NODE_HEADER_SIZE+NEBO_CONSOLE_NODE_KIND_OFFSET],NEBO_CONSOLE_NODE_KIND_BOOL
 jne test_fail

 mov rdi,rbx
 lea rsi,[rel plain_bytes]
 mov edx,32
 lea rcx,[rel plain_length]
 call nebo_console_document_copy_plain_text
 test eax,eax
 jnz test_fail
 cmp qword [rel plain_length],10
 jne test_fail
 lea rsi,[rel plain_bytes]
 lea rdi,[rel expected_bytes]
 mov ecx,10
 cld
 repe cmpsb
 jne test_fail

 xor edi,edi
 jmp neboc_host_process_exit

test_fail:
 mov edi,1
 jmp neboc_host_process_exit
