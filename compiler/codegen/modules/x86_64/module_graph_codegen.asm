; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F05 deterministic x86-64 NASM emitter for a static module plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/modules/x86_64/module_graph_codegen.inc"

extern neboc_assembly_writer_append_bytes

section .rodata
mod_template:
 db 10,'section .text',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    mov eax, 0x'
mod_hex_offset equ $-mod_template
 db '00000000',10
 db '    ret',10
mod_template_len equ $-mod_template
mod_hex: db '0123456789abcdef'

section .text

NEBOC_ABI_FUNCTION neboc_seguranca_numerica_conversoes_e_overflow_module_codegen_emit_start
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 push rbx
 push r12
 push r13
 sub rsp,128
 mov r12,rdi
 mov qword [r12+NEBOC_MODULE_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+NEBOC_MODULE_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov rbx,[r12+NEBOC_MODULE_CODEGEN_PLAN_OFFSET]
 mov r13,[r12+NEBOC_MODULE_CODEGEN_WRITER_OFFSET]
 test rbx,rbx
 jz .invalid_state
 test r13,r13
 jz .invalid_state
 mov rax,rbx
 or rax,r13
 test rax,7
 jnz .invalid_state
 mov rax,NEBOC_MODULE_PLAN_MAGIC
 cmp [rbx+NEBOC_MODULE_PLAN_MAGIC_OFFSET],rax
 jne .source
 cmp qword [rbx+NEBOC_MODULE_PLAN_UNIT_COUNT_OFFSET],NEBOC_MODULE_MAX_UNITS
 jne .source
 cmp qword [rbx+NEBOC_MODULE_PLAN_FLAGS_OFFSET],NEBOC_MODULE_PLAN_FLAG_POINTERLESS
 jne .source
 cmp qword [rbx+NEBOC_MODULE_PLAN_TARGET_OFFSET],NEBOC_MODULE_PLAN_TARGET_X86_64_SYSV_ELF
 jne .source
 mov rsi,rbx
 mov ecx,NEBOC_MODULE_PLAN_HASHED_BYTES
 call mod_codegen_hash
 cmp rax,[rbx+NEBOC_MODULE_PLAN_HASH_OFFSET]
 jne .source
 lea rsi,[rel mod_template]
 mov rdi,rsp
 mov ecx,mod_template_len
 rep movsb
 mov rax,[rbx+NEBOC_MODULE_PLAN_RESULT_OFFSET]
 lea rdi,[rsp+mod_hex_offset+8]
 lea rsi,[rel mod_hex]
 mov ecx,8
.hex:
 mov rdx,rax
 and edx,15
 mov dl,[rsi+rdx]
 dec rdi
 mov [rdi],dl
 shr rax,4
 dec ecx
 jnz .hex
 mov rdi,r13
 mov rsi,rsp
 mov edx,mod_template_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_MODULE_CODEGEN_EMITTED_OFFSET],1
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_MODULE_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+NEBOC_MODULE_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_INTERNAL
 jmp .done
.invalid_state:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,128
 pop r13
 pop r12
 pop rbx
 cld
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

mod_codegen_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rsi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
