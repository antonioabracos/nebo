bits 64
default rel
%include "compiler/assembler/assembler_ir.inc"
%include "compiler/format/internal_object_writer.inc"
global _start
extern neboc_assembler_module_new,neboc_assembler_add_section,neboc_assembler_emit_instruction
extern neboc_internal_object_writer_new,neboc_object_writer_consume,neboc_object_writer_layout_sections
extern neboc_object_writer_build_symbol_table,neboc_object_writer_build_relocations,neboc_object_writer_emit_bytes
extern neboc_object_writer_verify_roundtrip,neboc_object_writer_normalized_digest,neboc_object_writer_report
extern neboc_cli_object_build,neboc_cli_object_verify,neboc_host_process_exit
section .bss align=16
module: resb NEBOC_ASM_SIZE
writer: resb NEBOC_IOW_SIZE
image: resb NEBOC_IOW_IMAGE_SIZE
out: resq 10
section .text
_start:
 sub rsp,8
 lea rdi,[rel module]
 mov esi,1
 mov edx,8
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
 test eax,eax
 jne .f1
 lea rdi,[rel writer]
 lea rsi,[rel module]
 call neboc_object_writer_consume
 test eax,eax
 jne .f2
 lea rdi,[rel writer]
 call neboc_object_writer_layout_sections
 test eax,eax
 jne .f3
 lea rdi,[rel writer]
 call neboc_object_writer_build_symbol_table
 test eax,eax
 jne .f4
 lea rdi,[rel writer]
 call neboc_object_writer_build_relocations
 test eax,eax
 jne .f5
 lea rdi,[rel writer]
 lea rsi,[rel image]
 mov edx,NEBOC_IOW_IMAGE_SIZE
 lea rcx,[rel out]
 call neboc_object_writer_emit_bytes
 test eax,eax
 jne .f6
 cmp qword [rel out],64
 jne .f7
 cmp dword [rel image],0x464c457f
 jne .f8
 lea rdi,[rel writer]
 lea rsi,[rel image]
 mov edx,64
 call neboc_object_writer_verify_roundtrip
 test eax,eax
 jne .f9
 lea rdi,[rel writer]
 lea rsi,[rel out]
 call neboc_object_writer_normalized_digest
 test qword [rel out],-1
 jz .f10
 lea rdi,[rel writer]
 lea rsi,[rel out]
 call neboc_object_writer_report
 cmp qword [rel out+16],1
 jne .f11
 lea rdi,[rel writer]
 lea rsi,[rel image]
 mov edx,63
 lea rcx,[rel out]
 call neboc_cli_object_build
 cmp eax,8
 jne .f12
 lea rdi,[rel image]
 mov esi,64
 call neboc_cli_object_verify
 test eax,eax
 jne .f13
 mov byte [rel image],0
 lea rdi,[rel image]
 mov esi,64
 call neboc_cli_object_verify
 cmp eax,4
 jne .f14
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 14
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
