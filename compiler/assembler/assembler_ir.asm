; ASSEMBLER-IR-F02 bounded versioned assembler IR and compatibility parser.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/assembler/assembler_ir.inc"
section .text
NEBOC_ABI_FUNCTION neboc_assembler_module_new
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_ASM_TARGET_X86_64_ELF
 jne .target
 test rdx,rdx
 jz .limit
 cmp rdx,NEBOC_ASM_MAX_ITEMS
 ja .limit
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov ecx,8
 lea rdi,[rdi+16]
 xor eax,eax
 rep stosq
 ret
.target: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_add_section
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rdx,7
 ja .source
 test rcx,rcx
 jz .source
 mov rax,rcx
 dec rax
 test rcx,rax
 jnz .source
 cmp rcx,64
 ja .source
 mov rax,[rdi+16]
 cmp rax,[rdi+8]
 jae .limit
 inc qword [rdi+16]
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_define_label
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rdx,2
 ja .source
 cmp [rdi+72],rsi
 je .source
 mov rax,[rdi+24]
 cmp rax,[rdi+8]
 jae .limit
 mov [rdi+72],rsi
 inc qword [rdi+24]
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_emit_instruction
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_ASM_OPCODE_NOP
 jb .source
 cmp rsi,NEBOC_ASM_OPCODE_SYSCALL
 ja .source
 cmp rdx,15
 ja .source
 cmp qword [rdi+16],0
 je .source
 mov rax,[rdi+32]
 cmp rax,[rdi+8]
 jae .limit
 inc qword [rdi+32]
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_emit_data
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 mov rax,rdx
 dec rax
 test rdx,rax
 jnz .source
 cmp rdx,64
 ja .source
 mov rax,[rdi+8]
 shl rax,3
 mov rcx,[rdi+40]
 add rcx,rsi
 jc .limit
 cmp rcx,rax
 ja .limit
 mov [rdi+40],rcx
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_emit_zero
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 mov rax,[rdi+8]
 shl rax,3
 mov rdx,[rdi+48]
 add rdx,rsi
 jc .limit
 cmp rdx,rax
 ja .limit
 mov [rdi+48],rdx
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_add_expression
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jb .source
 cmp rsi,2
 ja .source
 test rdx,rdx
 jz .source
 mov rax,[rdi+56]
 cmp rax,[rdi+8]
 jae .limit
 inc qword [rdi+56]
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_add_relocation
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jb .source
 cmp rsi,2
 ja .source
 test rdx,rdx
 jz .source
 mov rax,[rdi+64]
 cmp rax,[rdi+8]
 jae .limit
 inc qword [rdi+64]
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_validate
 test rdi,rdi
 jz .invalid
 cmp qword [rdi],NEBOC_ASM_TARGET_X86_64_ELF
 jne .target
 cmp qword [rdi+16],0
 je .source
 mov rax,[rdi+64]
 cmp rax,[rdi+56]
 ja .source
 xor eax,eax
 ret
.target: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_listing
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov ecx,10
.copy:
 mov rax,[rdi]
 mov [rsi],rax
 add rdi,8
 add rsi,8
 loop .copy
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_assembler_parser_parse
 ; rdi=module, rsi=text, rdx=length, rcx=dialect. Grammar is one-byte directives.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .source
 cmp rcx,NEBOC_ASM_DIALECT_BOUNDED
 jne .source
 mov rax,[rdi+8]
 shl rax,3
 cmp rdx,rax
 ja .limit
.next:
 mov al,[rsi]
 inc rsi
 dec rdx
 cmp al,' '
 je .continue
 cmp al,10
 je .continue
 cmp al,'s'
 je .section
 cmp al,'l'
 je .label
 cmp al,'i'
 je .instruction
 cmp al,'d'
 je .data
 cmp al,'z'
 je .zero
 jmp .source
.section: inc qword [rdi+16]
 jmp .bounded
.label: inc qword [rdi+24]
 jmp .bounded
.instruction: inc qword [rdi+32]
 jmp .bounded
.data: inc qword [rdi+40]
 jmp .continue
.zero: inc qword [rdi+48]
 jmp .continue
.bounded:
 mov rax,[rdi+8]
 cmp [rdi+16],rax
 ja .limit
 cmp [rdi+24],rax
 ja .limit
 cmp [rdi+32],rax
 ja .limit
.continue:
 test rdx,rdx
 jnz .next
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_assemble_bounded
 ; Object emission is deliberately unavailable until ASSEMBLER-IR-F04.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
