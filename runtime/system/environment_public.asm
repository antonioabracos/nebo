; Environment values are read only from this process's explicit startup
; vectors. Tests supply a scrubbed environment; no host file or shell is read.
bits 64
default rel
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/system/system_contract.inc"
extern nebo_runtime_process_stack
extern nebo_environment_get
extern nebo_environment_arguments
extern neboc_list_new
extern neboc_list_validate
extern nebo_tagged_public
extern nebo_tagged_text_copy
extern nebo_utf8_validate
extern nebo_runtime_trap_arithmetic_domain
global nebo_environment_public
section .text
nebo_environment_public:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r15,r8
 cmp ebx,33
 je .length
 cmp ebx,34
 je .at
 mov r14,[rel nebo_runtime_process_stack]
 test r14,r14
 jz .trap
 cmp qword [r14],64
 ja .trap
 cmp ebx,32
 je .arguments
 cmp ebx,31
 jne .trap
 mov rax,[r14]
 lea rdx,[r14+rax*8+16]
 mov rdi,[r13]
 mov rsi,[r13+8]
 mov ecx,64
 call nebo_environment_get
 cmp eax,NEBO_SYSTEM_ERROR_NOT_FOUND
 je .none
 test eax,eax
 jnz .trap
 mov [rsp],rdx
 mov [rsp+8],r8
 mov qword [rsp+16],0
 mov word [rsp+20],1
 mov rdi,rdx
 mov rsi,r8
 call nebo_utf8_validate
 test eax,eax
 jnz .trap
 mov edi,1
 mov rsi,rsp
 jmp .option
.none:
 mov edi,2
 xor esi,esi
.option:
 mov edx,35005
 xor ecx,ecx
 mov r8,r15
 call nebo_tagged_public
 jmp .done
.arguments:
 lea rdi,[r14+8]
 mov esi,65
 call nebo_environment_arguments
 test eax,eax
 jnz .trap
 mov [rsp],r8
 mov [rsp+8],rdx
 mov rdi,r15
 mov esi,32
 mov edx,8
 mov ecx,1
 call neboc_list_new
 test eax,eax
 jnz .trap
 lea rax,[r15+64]
 mov [r15+NEBOC_LIST_DATA_OFFSET],rax
 mov rax,[rsp]
 mov [r15+NEBOC_LIST_LENGTH_OFFSET],rax
 mov qword [r15+NEBOC_LIST_CAPACITY_OFFSET],64
 xor ebx,ebx
 xor r13d,r13d
.argument:
 cmp rbx,[rsp]
 jae .list_ready
 mov rax,[rsp+8]
 mov r14,[rax+rbx*8]
 xor r12d,r12d
.count:
 cmp byte [r14+r12],0
 je .validate
 inc r12
 inc r13
 cmp r13,4096
 ja .trap
 jmp .count
.validate:
 mov rdi,r14
 mov rsi,r12
 call nebo_utf8_validate
 test eax,eax
 jnz .trap
 mov rax,rbx
 shl rax,5
 lea rax,[r15+rax+64]
 mov [rax],r14
 mov [rax+8],r12
 mov qword [rax+16],0
 mov word [rax+20],1
 mov qword [rax+24],0
 inc rbx
 jmp .argument
.list_ready:
 mov rdi,r15
 call neboc_list_validate
 test eax,eax
 jnz .trap
 mov rax,r15
 jmp .done
.length:
 mov rdi,r12
 call neboc_list_validate
 test eax,eax
 jnz .trap
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jmp .done
.at:
 mov rdi,r12
 call neboc_list_validate
 test eax,eax
 jnz .trap
 cmp r13,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .trap
 shl r13,5
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,r13
 mov rdi,r15
 call nebo_tagged_text_copy
 jmp .done
.trap:
 jmp nebo_runtime_trap_arithmetic_domain
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
