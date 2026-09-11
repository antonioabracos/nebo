bits 64
default rel
%include "compiler/target/target_registry.inc"
%include "compiler/target/arch_backend.inc"
global _start
extern neboc_arch_backend_new,neboc_backend_legalize,neboc_backend_select_instructions
extern neboc_backend_register_file,neboc_backend_stack_frame,neboc_backend_lower_call
extern neboc_backend_lower_atomic,neboc_backend_relocation_kinds,neboc_backend_code_model
extern neboc_backend_disassembly_oracle,neboc_backend_conformance_corpus
extern neboc_cli_emit_asm_target,neboc_host_process_exit
section .data
x86_target: dq 1,1,1,64,16,1,1,1,1,1,0x1f,0x1f,3
x86_scalar_target: dq 1,1,1,64,16,1,1,1,1,1,3,0,3
aarch64_target: dq 2,1,1,64,16,2,1,1,1,2,1,0x07,1
section .bss align=16
backend: resb NEBOC_BACKEND_SIZE
scalar_backend: resb NEBOC_BACKEND_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel backend]
 lea rsi,[rel x86_target]
 call neboc_arch_backend_new
 test eax,eax
 jne .fail1
 lea rdi,[rel scalar_backend]
 lea rsi,[rel x86_scalar_target]
 call neboc_arch_backend_new
 test eax,eax
 jne .fail2
 lea rdi,[rel backend]
 lea rsi,[rel aarch64_target]
 call neboc_arch_backend_new
 cmp eax,6
 jne .fail3
 lea rdi,[rel backend]
 mov esi,1
 lea rdx,[rel out]
 call neboc_backend_legalize
 test eax,eax
 jne .fail4
 mov esi,99
 call neboc_backend_legalize
 cmp eax,4
 jne .fail5
 lea rdi,[rel scalar_backend]
 mov esi,4
 lea rdx,[rel out]
 call neboc_backend_select_instructions
 cmp eax,4
 jne .fail6
 lea rdi,[rel backend]
 mov esi,4
 call neboc_backend_select_instructions
 test eax,eax
 jne .fail7
 cmp qword [rel out],0x1004
 jne .fail8
 lea rsi,[rel out]
 call neboc_backend_register_file
 test eax,eax
 jne .fail9
 cmp qword [rel out],16
 jne .fail10
 mov esi,24
 mov edx,8
 lea rcx,[rel out]
 call neboc_backend_stack_frame
 test eax,eax
 jne .fail11
 cmp qword [rel out],32
 jne .fail12
 cmp qword [rel out+8],16
 jne .fail13
 mov esi,7
 mov edx,2
 xor ecx,ecx
 lea r8,[rel out]
 call neboc_backend_lower_call
 test eax,eax
 jne .fail14
 cmp qword [rel out],6
 jne .fail15
 cmp qword [rel out+8],1
 jne .fail16
 mov ecx,1
 call neboc_backend_lower_call
 cmp eax,4
 jne .fail17
 xor ecx,ecx
 mov esi,3
 lea rdx,[rel out]
 call neboc_backend_lower_atomic
 test eax,eax
 jne .fail18
 cmp qword [rel out],0x3003
 jne .fail19
 lea rsi,[rel out]
 call neboc_backend_relocation_kinds
 cmp qword [rel out],3
 jne .fail20
 call neboc_backend_code_model
 cmp qword [rel out],1
 jne .fail21
 call neboc_backend_disassembly_oracle
 test eax,eax
 jne .fail22
 call neboc_backend_conformance_corpus
 test eax,eax
 jne .fail23
 mov esi,2
 lea rdx,[rel out]
 call neboc_cli_emit_asm_target
 test eax,eax
 jne .fail24
 cmp qword [rel out],1
 jne .fail25
 cmp qword [rel out+8],0x1002
 jne .fail26
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 26
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
