; FILESYSTEM-PATHS-E-FORMATOS-F06 bounded macro invocation and deterministic expansion trace.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/meta/code_model.inc"
%include "compiler/meta/macro.inc"
section .text
NEBOC_ABI_FUNCTION nebo_macro_invocation_validate
 ; arity, input kind, allowed input mask, output kind, allowed output mask
 cmp rdi,NEBO_MACRO_MAX_ARITY
 ja .arity
 cmp rsi,1
 jb .kind
 cmp rsi,NEBO_META_KIND_MAX
 ja .kind
 mov ecx,esi
 dec ecx
 mov rax,1
 shl rax,cl
 test rax,rdx
 jz .kind
 cmp rcx,NEBO_META_KIND_MAX
 ; rcx was scratch; validate output from original r8 below
 cmp r8,1
 jb .kind
 cmp r8,NEBO_META_KIND_MAX
 ja .kind
 mov ecx,r8d
 dec ecx
 mov rax,1
 shl rax,cl
 test rax,r9
 jz .kind
 xor eax,eax
 ret
.arity: mov eax,NEBO_MACRO_STATUS_ARITY
 ret
.kind: mov eax,NEBO_MACRO_STATUS_KIND
 ret

NEBOC_ABI_FUNCTION nebo_macro_trace_init
 ; state, entries, capacity
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .limit
 cmp rdx,NEBO_MACRO_MAX_TRACE
 ja .limit
 mov [rdi+NEBO_MACRO_STATE_ENTRIES],rsi
 mov [rdi+NEBO_MACRO_STATE_CAPACITY],rdx
 mov qword [rdi+NEBO_MACRO_STATE_COUNT],0
 xor eax,eax
 ret
.invalid: mov eax,NEBO_MACRO_STATUS_INVALID
 ret
.limit: mov eax,NEBO_MACRO_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_macro_trace_append
 ; state, trace record; validate all before copying
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBO_MACRO_TRACE_MACRO_ID],0
 je .invalid
 cmp qword [rsi+NEBO_MACRO_TRACE_CALL_SPAN],0
 je .invalid
 cmp qword [rsi+NEBO_MACRO_TRACE_OUTPUT_SPAN],0
 je .invalid
 mov rax,[rsi+NEBO_MACRO_TRACE_DEPTH]
 test rax,rax
 jz .depth
 cmp rax,NEBO_META_MAX_DEPTH
 ja .depth
 mov rax,[rsi+NEBO_MACRO_TRACE_NODES]
 cmp rax,NEBO_META_MAX_NODES
 ja .nodes
 mov rax,[rsi+NEBO_MACRO_TRACE_BYTES]
 cmp rax,NEBO_META_MAX_BYTES
 ja .bytes
 mov rdx,[rdi+NEBO_MACRO_STATE_COUNT]
 cmp rdx,[rdi+NEBO_MACRO_STATE_CAPACITY]
 jae .limit
 imul rax,rdx,NEBO_MACRO_TRACE_SIZE
 add rax,[rdi+NEBO_MACRO_STATE_ENTRIES]
 push rdi
 mov rdi,rax
 mov ecx,NEBO_MACRO_TRACE_SIZE/8
 rep movsq
 pop rdi
 inc qword [rdi+NEBO_MACRO_STATE_COUNT]
 xor eax,eax
 ret
.invalid: mov eax,NEBO_MACRO_STATUS_INVALID
 ret
.limit: mov eax,NEBO_MACRO_STATUS_LIMIT
 ret
.depth: mov eax,NEBO_MACRO_STATUS_DEPTH
 ret
.nodes: mov eax,NEBO_MACRO_STATUS_NODES
 ret
.bytes: mov eax,NEBO_MACRO_STATUS_BYTES
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
