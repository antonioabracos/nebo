; TIPOS-PRIMITIVOS-ESCALARES-F08 deterministic native emitter for authenticated Buffer plans.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/buffer_parser.inc"
%include "compiler/semantic/types/buffer_freeze.inc"
%include "compiler/semantic/collections/public_slice.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lowering/textual/buffer_plan.inc"
%include "compiler/codegen/textual/x86_64/buffer_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal

section .rodata
buffer_prefix:
 db 10,'section .text',10
 db 'global nebo_buffer_descriptor',10
 db 'nebo_buffer_descriptor:',10
 db '    mov dword [rdi], '
buffer_prefix_len equ $-buffer_prefix
buffer_capacity:
 db 10,'    mov dword [rdi + 4], 4',10
 db '    mov qword [rdi + 8], '
buffer_capacity_len equ $-buffer_capacity
buffer_body:
 db 10,'    ret',10
 db '; F09 operations are folded in source order into one 16-byte local descriptor.',10
 db '; Successful set push and clear update that descriptor exactly once.',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    mov rax, '
buffer_body_len equ $-buffer_body
buffer_suffix: db 10,'    ret',10
buffer_suffix_len equ $-buffer_suffix
frozen_prefix:
 db 10,'section .rodata',10,'align 8',10
 db 'nebo_frozen_bytes_storage: dd '
frozen_prefix_len equ $-frozen_prefix
frozen_descriptor:
 db 10,'align 8',10
 db 'global nebo_frozen_bytes_descriptor',10
 db 'nebo_frozen_bytes_descriptor:',10
 db '    dq nebo_frozen_bytes_storage',10
 db '    dq '
frozen_descriptor_len equ $-frozen_descriptor
frozen_suffix:
 db 10,'    dd 3',10
 db '    dw 1',10
 db '    dw 1',10
frozen_suffix_len equ $-frozen_suffix
slice_prefix:
 db 10,'section .rodata',10,'align 8',10
 db 'nebo_public_slice_storage: dd '
slice_prefix_len equ $-slice_prefix
slice_descriptor:
 db 10,'align 8',10
 db 'global nebo_public_slice_descriptor',10
 db 'nebo_public_slice_descriptor:',10
 db '    dq nebo_public_slice_storage',10
 db '    dq '
slice_descriptor_len equ $-slice_descriptor
slice_stride_owner:
 db 10,'    dq 1',10
 db '    dq 12',10
 db '    dq '
slice_stride_owner_len equ $-slice_stride_owner
slice_suffix: db 10
slice_suffix_len equ $-slice_suffix

section .text

buffer_codegen_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rdi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

NEBOC_ABI_FUNCTION neboc_buffer_codegen_emit_start
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov qword [r12+NEBOC_BUFFER_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+NEBOC_BUFFER_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov r13,[r12+NEBOC_BUFFER_CODEGEN_PLAN_OFFSET]
 mov rbx,[r12+NEBOC_BUFFER_CODEGEN_WRITER_OFFSET]
 test r13,r13
 jz .invalid
 test rbx,rbx
 jz .invalid
 mov rax,NEBOC_BUFFER_PLAN_MAGIC
 cmp [r13+NEBOC_BUFFER_PLAN_MAGIC_OFFSET],rax
 jne .source
 cmp qword [r13+NEBOC_BUFFER_PLAN_VERSION_OFFSET],NEBOC_BUFFER_PLAN_VERSION_A3
 jne .source
 cmp qword [r13+NEBOC_BUFFER_PLAN_CAPACITY_OFFSET],4
 jne .source
 cmp qword [r13+NEBOC_BUFFER_PLAN_RESERVED_OFFSET],0
 jne .source
 test qword [r13+NEBOC_BUFFER_PLAN_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_ANALYZED
 jz .source
 mov rdi,r13
 mov ecx,NEBOC_BUFFER_PLAN_HASHED_BYTES
 call buffer_codegen_hash
 cmp rax,[r13+NEBOC_BUFFER_PLAN_HASH_OFFSET]
 jne .source
 lea rdi,[r13+NEBOC_BUFFER_PLAN_F09_EXTENSION_OFFSET]
 mov ecx,NEBOC_BUFFER_PLAN_F09_HASHED_BYTES
 call buffer_codegen_hash
 cmp rax,[r13+NEBOC_BUFFER_PLAN_EXTENSION_HASH_OFFSET]
 jne .source
 lea rdi,[r13+NEBOC_BUFFER_PLAN_F10_EXTENSION_OFFSET]
 mov ecx,NEBOC_BUFFER_PLAN_F10_HASHED_BYTES
 call buffer_codegen_hash
 cmp rax,[r13+NEBOC_BUFFER_PLAN_F10_HASH_OFFSET]
 jne .source
 lea rdi,[r13+NEBOC_BUFFER_PLAN_F11_EXTENSION_OFFSET]
 mov ecx,NEBOC_BUFFER_PLAN_F11_HASHED_BYTES
 call buffer_codegen_hash
 cmp rax,[r13+NEBOC_BUFFER_PLAN_F11_HASH_OFFSET]
 jne .source
 mov rdi,rbx
 lea rsi,[rel buffer_prefix]
 mov edx,buffer_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BUFFER_PLAN_LENGTH_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel buffer_capacity]
 mov edx,buffer_capacity_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BUFFER_PLAN_STORAGE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel buffer_body]
 mov edx,buffer_body_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BUFFER_PLAN_RESULT_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel buffer_suffix]
 mov edx,buffer_suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 test qword [r13+NEBOC_BUFFER_PLAN_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_FREEZE
 jz .slice_emit
 cmp qword [r13+NEBOC_BUFFER_PLAN_FROZEN_TYPE_ID_OFFSET],NEBOC_TYPE_ID_BYTES
 jne .source
 cmp qword [r13+NEBOC_BUFFER_PLAN_FREEZE_COUNT_OFFSET],1
 jne .source
 mov rdi,rbx
 lea rsi,[rel frozen_prefix]
 mov edx,frozen_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BUFFER_PLAN_FROZEN_STORAGE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel frozen_descriptor]
 mov edx,frozen_descriptor_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BUFFER_PLAN_FROZEN_LENGTH_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel frozen_suffix]
 mov edx,frozen_suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
.slice_emit:
 test qword [r13+NEBOC_BUFFER_PLAN_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PUBLIC_SLICE
 jz .emitted
 cmp qword [r13+NEBOC_BUFFER_PLAN_SLICE_TYPE_ID_OFFSET],NEBOC_TYPE_ID_SLICE
 jne .source
 cmp qword [r13+NEBOC_BUFFER_PLAN_SLICE_VIEW_COUNT_OFFSET],1
 jb .source
 mov rdi,rbx
 lea rsi,[rel slice_prefix]
 mov edx,slice_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BUFFER_PLAN_SLICE_STORAGE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel slice_descriptor]
 mov edx,slice_descriptor_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BUFFER_PLAN_SLICE_LENGTH_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel slice_stride_owner]
 mov edx,slice_stride_owner_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BUFFER_PLAN_SLICE_VIEW_GENERATION_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel slice_suffix]
 mov edx,slice_suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
.emitted:
 mov qword [r12+NEBOC_BUFFER_CODEGEN_EMITTED_OFFSET],1
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_BUFFER_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+NEBOC_BUFFER_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
