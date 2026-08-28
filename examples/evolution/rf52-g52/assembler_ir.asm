bits 64
default rel
%include "compiler/assembler/assembler_ir.inc"
global _start
extern neboc_assembler_module_new,neboc_assembler_add_section,neboc_assembler_emit_instruction
extern neboc_assembler_validate,neboc_host_process_exit
section .bss align=16
module: resb NEBOC_ASM_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel module]
 mov esi,1
 mov edx,4
 call neboc_assembler_module_new
 lea rdi,[rel module]
 mov esi,1
 mov edx,5
 mov ecx,16
 call neboc_assembler_add_section
 lea rdi,[rel module]
 mov esi,2
 xor edx,edx
 call neboc_assembler_emit_instruction
 lea rdi,[rel module]
 call neboc_assembler_validate
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
