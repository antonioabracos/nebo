bits 64
default rel
%include "compiler/assembler/assembler_ir.inc"
global _start
extern neboc_assembler_module_new,neboc_assembler_add_section,neboc_assembler_define_label
extern neboc_assembler_emit_instruction,neboc_assembler_emit_data,neboc_assembler_emit_zero
extern neboc_assembler_add_expression,neboc_assembler_add_relocation,neboc_assembler_validate
extern neboc_assembler_listing,neboc_assembler_parser_parse,neboc_cli_assemble_bounded
extern neboc_host_process_exit
section .data
text: db 's','l','i','d','z',10
text_len equ $-text
section .bss align=16
module: resb NEBOC_ASM_SIZE
parsed: resb NEBOC_ASM_SIZE
out: resq 10
section .text
_start:
 sub rsp,8
 lea rdi,[rel module]
 mov esi,1
 mov edx,8
 call neboc_assembler_module_new
 test eax,eax
 jne .f1
 lea rdi,[rel module]
 mov esi,1
 mov edx,5
 mov ecx,16
 call neboc_assembler_add_section
 test eax,eax
 jne .f2
 lea rdi,[rel module]
 mov esi,0x42
 mov edx,1
 call neboc_assembler_define_label
 test eax,eax
 jne .f3
 lea rdi,[rel module]
 mov esi,2
 xor edx,edx
 call neboc_assembler_emit_instruction
 test eax,eax
 jne .f4
 lea rdi,[rel module]
 mov esi,4
 mov edx,4
 call neboc_assembler_emit_data
 test eax,eax
 jne .f5
 lea rdi,[rel module]
 mov esi,8
 call neboc_assembler_emit_zero
 test eax,eax
 jne .f6
 lea rdi,[rel module]
 mov esi,1
 mov edx,0x42
 xor ecx,ecx
 call neboc_assembler_add_expression
 test eax,eax
 jne .f7
 lea rdi,[rel module]
 mov esi,1
 mov edx,0x42
 xor ecx,ecx
 call neboc_assembler_add_relocation
 test eax,eax
 jne .f8
 lea rdi,[rel module]
 call neboc_assembler_validate
 test eax,eax
 jne .f9
 lea rdi,[rel module]
 lea rsi,[rel out]
 call neboc_assembler_listing
 test eax,eax
 jne .f10
 cmp qword [rel out+16],1
 jne .f11
 lea rdi,[rel parsed]
 mov esi,1
 mov edx,8
 call neboc_assembler_module_new
 lea rdi,[rel parsed]
 lea rsi,[rel text]
 mov edx,text_len
 mov ecx,1
 call neboc_assembler_parser_parse
 test eax,eax
 jne .f12
 cmp qword [rel parsed+16],1
 jne .f13
 cmp qword [rel parsed+32],1
 jne .f14
 lea rdi,[rel module]
 mov esi,0x42
 mov edx,1
 call neboc_assembler_define_label
 cmp eax,4
 jne .f15
 lea rdi,[rel module]
 mov esi,99
 xor edx,edx
 call neboc_assembler_emit_instruction
 cmp eax,4
 jne .f16
 lea rdi,[rel module]
 lea rsi,[rel out]
 call neboc_cli_assemble_bounded
 cmp eax,6
 jne .f17
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 17
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
