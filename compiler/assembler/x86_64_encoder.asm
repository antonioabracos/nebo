; X86-64-ENCODER-F03 bounded x86_64 encoder and relocation classifier.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/assembler/assembler_ir.inc"
%include "compiler/assembler/x86_64_encoder.inc"
section .text
NEBOC_ABI_FUNCTION neboc_instruction_encoder_for_target
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_ENCODER_TARGET_X86_64_ELF
 jne .target
 cmp rdx,1
 ja .target
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov qword [rdi+16],0
 mov qword [rdi+24],0
 xor eax,eax
 ret
.target: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_validate_operands
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_ASM_OPCODE_NOP
 je .zero
 cmp rsi,NEBOC_ASM_OPCODE_RET
 je .zero
 cmp rsi,NEBOC_ASM_OPCODE_SYSCALL
 je .zero
 cmp rsi,NEBOC_ASM_OPCODE_MOV_IMM
 jne .source
 mov rax,rdx
 shr rax,32
 jnz .source
 xor eax,eax
 ret
.zero:
 test rdx,rdx
 jnz .source
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_encode
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp qword [rdi],NEBOC_ENCODER_TARGET_X86_64_ELF
 jne .target
 cmp rsi,NEBOC_ASM_OPCODE_NOP
 je .nop
 cmp rsi,NEBOC_ASM_OPCODE_RET
 je .ret
 cmp rsi,NEBOC_ASM_OPCODE_SYSCALL
 je .syscall
 cmp rsi,NEBOC_ASM_OPCODE_MOV_IMM
 jne .source
 mov rax,rdx
 shr rax,32
 jnz .source
 mov byte [rcx],0xb8
 mov [rcx+1],edx
 mov qword [rcx+8],5
 jmp .ok
.nop: test rdx,rdx
 jnz .source
 mov byte [rcx],0x90
 mov qword [rcx+8],1
 jmp .ok
.ret: test rdx,rdx
 jnz .source
 mov byte [rcx],0xc3
 mov qword [rcx+8],1
 jmp .ok
.syscall: test rdx,rdx
 jnz .source
 mov word [rcx],0x050f
 mov qword [rcx+8],2
.ok: inc qword [rdi+16]
 xor eax,eax
 ret
.target: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_estimate_size
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov eax,1
 cmp rsi,NEBOC_ASM_OPCODE_MOV_IMM
 jne .not_mov
 mov eax,5
 jmp .write
.not_mov:
 cmp rsi,NEBOC_ASM_OPCODE_SYSCALL
 jne .base
 mov eax,2
 jmp .write
.base:
 cmp rsi,NEBOC_ASM_OPCODE_NOP
 jb .source
 cmp rsi,NEBOC_ASM_OPCODE_RET
 ja .source
.write: mov [rdx],rax
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_relocation_for
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,1
 jne .source
 mov qword [rdx],NEBOC_RELOC_X86_64_PC32
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_relax
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rsi,NEBOC_RELAX_NEAR
 jne .source
 mov eax,NEBOC_RELAX_NEAR
 cmp rdx,-128
 jl .write
 cmp rdx,127
 jg .write
 mov eax,NEBOC_RELAX_SHORT
.write: mov [rcx],rax
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_feature_requirements
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBOC_ASM_OPCODE_NOP
 jb .source
 cmp rsi,NEBOC_ASM_OPCODE_SYSCALL
 ja .source
 mov qword [rdx],0
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_decode_for_test
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .source
 test rcx,rcx
 jz .invalid
 movzx eax,byte [rsi]
 cmp al,0x90
 je .nop
 cmp al,0xc3
 je .ret
 cmp al,0xb8
 je .mov
 cmp al,0x0f
 jne .source
 cmp rdx,2
 jb .source
 cmp byte [rsi+1],0x05
 jne .source
 mov eax,NEBOC_ASM_OPCODE_SYSCALL
 xor edx,edx
 jmp .write
.nop: mov eax,NEBOC_ASM_OPCODE_NOP
 xor edx,edx
 jmp .write
.ret: mov eax,NEBOC_ASM_OPCODE_RET
 xor edx,edx
 jmp .write
.mov:
 cmp rdx,5
 jb .source
 mov eax,NEBOC_ASM_OPCODE_MOV_IMM
 mov edx,[rsi+1]
.write: mov [rcx],rax
 mov [rcx+8],rdx
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_compare_oracle
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,rcx
 jne .mismatch
 mov qword [rdx],1
 xor eax,eax
 ret
.mismatch: inc qword [rdi+24]
 mov qword [rdx],0
 mov eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_vector_corpus
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov qword [rsi],4
 mov eax,0x9005c3b8
 mov [rsi+8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_encoder_coverage_report
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov qword [rsi],4
 mov qword [rsi+8],1
 mov qword [rsi+16],5
 mov rax,[rdi+24]
 mov [rsi+24],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
