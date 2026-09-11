bits 64
default rel
%include "compiler/assembler/assembler_ir.inc"
%include "compiler/assembler/x86_64_encoder.inc"
global _start
extern neboc_instruction_encoder_for_target,neboc_encoder_encode,neboc_encoder_estimate_size
extern neboc_encoder_validate_operands,neboc_encoder_relocation_for,neboc_encoder_relax
extern neboc_encoder_feature_requirements,neboc_encoder_decode_for_test,neboc_encoder_compare_oracle
extern neboc_encoder_vector_corpus,neboc_encoder_coverage_report,neboc_host_process_exit
section .bss align=16
encoder: resb NEBOC_ENCODER_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel encoder]
 mov esi,1
 xor edx,edx
 call neboc_instruction_encoder_for_target
 test eax,eax
 jne .f1
 lea rdi,[rel encoder]
 mov esi,3
 mov edx,0x12345678
 lea rcx,[rel out]
 call neboc_encoder_encode
 test eax,eax
 jne .f2
 cmp byte [rel out],0xb8
 jne .f3
 cmp dword [rel out+1],0x12345678
 jne .f4
 cmp qword [rel out+8],5
 jne .f5
 lea rdi,[rel encoder]
 mov esi,3
 lea rdx,[rel out+16]
 call neboc_encoder_estimate_size
 cmp qword [rel out+16],5
 jne .f6
 lea rdi,[rel encoder]
 mov esi,3
 mov rdx,0x100000000
 call neboc_encoder_validate_operands
 cmp eax,4
 jne .f7
 lea rdi,[rel encoder]
 mov esi,1
 lea rdx,[rel out]
 call neboc_encoder_relocation_for
 cmp qword [rel out],2
 jne .f8
 lea rdi,[rel encoder]
 mov esi,1
 mov rdx,100
 lea rcx,[rel out]
 call neboc_encoder_relax
 cmp qword [rel out],2
 jne .f9
 lea rdi,[rel encoder]
 mov esi,4
 lea rdx,[rel out]
 call neboc_encoder_feature_requirements
 cmp qword [rel out],0
 jne .f10
 lea rdi,[rel encoder]
 lea rsi,[rel out]
 mov edx,5
 lea rcx,[rel out+16]
 mov byte [rel out],0xb8
 mov dword [rel out+1],7
 call neboc_encoder_decode_for_test
 cmp qword [rel out+16],3
 jne .f11
 cmp qword [rel out+24],7
 jne .f12
 lea rdi,[rel encoder]
 mov esi,0x1234
 lea rdx,[rel out]
 mov ecx,0x1234
 call neboc_encoder_compare_oracle
 test eax,eax
 jne .f13
 cmp qword [rel out],1
 jne .f14
 lea rdi,[rel encoder]
 lea rsi,[rel out]
 call neboc_encoder_vector_corpus
 cmp qword [rel out],4
 jne .f15
 lea rdi,[rel encoder]
 lea rsi,[rel out]
 call neboc_encoder_coverage_report
 cmp qword [rel out],4
 jne .f16
 cmp qword [rel out+8],1
 jne .f17
 lea rdi,[rel encoder]
 mov esi,99
 xor edx,edx
 lea rcx,[rel out]
 call neboc_encoder_encode
 cmp eax,4
 jne .f18
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 18
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
