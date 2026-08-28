; Emits a deterministic sectionless ELF64 ET_REL image to stdout.
bits 64
default rel
%include "compiler/assembler/assembler_ir.inc"
%include "compiler/format/internal_object_writer.inc"
global _start
extern neboc_assembler_module_new,neboc_assembler_add_section,neboc_assembler_emit_instruction
extern neboc_internal_object_writer_new,neboc_object_writer_consume,neboc_object_writer_layout_sections
extern neboc_object_writer_emit_bytes,neboc_host_process_exit
section .bss align=16
module: resb NEBOC_ASM_SIZE
writer: resb NEBOC_IOW_SIZE
image: resb NEBOC_IOW_IMAGE_SIZE
written: resq 1
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
 lea rdi,[rel writer]
 mov esi,1
 mov edx,1
 call neboc_internal_object_writer_new
 lea rdi,[rel writer]
 lea rsi,[rel module]
 call neboc_object_writer_consume
 lea rdi,[rel writer]
 call neboc_object_writer_layout_sections
 lea rdi,[rel writer]
 lea rsi,[rel image]
 mov edx,64
 lea rcx,[rel written]
 call neboc_object_writer_emit_bytes
 test eax,eax
 jne .fail
 mov eax,1
 mov edi,1
 lea rsi,[rel image]
 mov edx,64
 syscall
 cmp rax,64
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail: mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
