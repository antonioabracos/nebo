bits 64
default rel
%include "compiler/semantic/numeric/numeric_contract.inc"
%include "compiler/semantic/collections/list_core.inc"
extern nebo_distribution_sample_i64
; The canonical sampling algorithm publishes an existing public List<Int>.
; Random RDI, input RSI, N RDX, K RCX, List output R8 (320 bytes), workspace R9
; (512 bytes). The List profile already admits 0..16 entries; no second List
; implementation or sampling algorithm is introduced here.
section .text
extern neboc_list_init
global nebo_random_sample_public
nebo_random_sample_public:
 cmp rdx,64
 ja .bounds
 cmp rcx,16
 ja .bounds
 cmp rcx,rdx
 ja .domain
 test rdi,rdi
 jz .argument
 test rsi,rsi
 jz .argument
 test r8,r8
 jz .argument
 test r9,r9
 jz .argument
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 mov rdi,rbx
 lea rsi,[rbx+80]
 mov edx,16
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 lea r8,[rbx+80]
 mov r9,[rsp]
 call nebo_distribution_sample_i64
 test eax,eax
 jnz .done
 ; Length publishes only after the native sampler completes successfully.
 mov [rbx+NEBOC_LIST_LENGTH_OFFSET],r15
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
.domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret
.argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
