; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-PF004 bounded internal native layout for nominal products and sums
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/aggregates/programmer_type_layout.inc"
section .text
layout_hash:
 mov rax,1469598103934665603
 mov r8,1099511628211
 %assign off 0
 %rep 15
 xor rax,[rdi+off]
 imul rax,r8
 %assign off off+8
 %endrep
 mov [rdi+NEBOC_LAYOUT_HASH_OFFSET],rax
 ret
layout_error:
 mov [rdi+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_DIAGNOSTIC_OFFSET],rsi
 call layout_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
NEBOC_ABI_FUNCTION neboc_programmer_type_layout
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],0
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_ALIGN_OFFSET],0
 mov qword [r12+NEBOC_LAYOUT_TAG_OFFSET],0
 mov qword [r12+NEBOC_LAYOUT_TAG_WIDTH_OFFSET],0
 mov qword [r12+NEBOC_LAYOUT_PAYLOAD_OFFSET],0
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_DIAGNOSTIC_OFFSET],0
 mov rax,[r12+NEBOC_LAYOUT_FLAGS_OFFSET]
 and rax,NEBOC_LAYOUT_FLAGS_REQUIRED
 cmp rax,NEBOC_LAYOUT_FLAGS_REQUIRED
 jne .flags
 cmp qword [r12+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_PRODUCT
 je .product
 cmp qword [r12+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_SUM
 je .sum
 jmp .bounds
.product:
 mov rcx,[r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_MEMBER_COUNT_OFFSET]
 cmp rcx,1
 jb .bounds
 cmp rcx,8
 ja .bounds
 mov r13,[r12+NEBOC_LAYOUT_SIZES_PTR_OFFSET]
 mov r14,[r12+NEBOC_LAYOUT_ALIGNS_PTR_OFFSET]
 mov r15,[r12+NEBOC_LAYOUT_OFFSETS_PTR_OFFSET]
 test r13,r13
 jz .bounds
 test r14,r14
 jz .bounds
 test r15,r15
 jz .bounds
 xor ebx,ebx
 xor r9d,r9d
 mov r10d,1
.field_loop:
 mov rax,[r14+rbx*8]
 test rax,rax
 jz .alignment
 cmp rax,16
 ja .alignment
 lea rdx,[rax-1]
 test rax,rdx
 jnz .alignment
 cmp rax,r10
 cmova r10,rax
 mov r8,[r13+rbx*8]
 test r8,r8
 jz .bounds
 add r9,rdx
 jc .bounds
 not rdx
 and r9,rdx
 mov [r15+rbx*8],r9
 add r9,r8
 jc .bounds
 inc rbx
 cmp rbx,rcx
 jb .field_loop
 lea rdx,[r10-1]
 add r9,rdx
 jc .bounds
 not rdx
 and r9,rdx
 mov [r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],r9
 mov [r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_ALIGN_OFFSET],r10
 jmp .success
.sum:
 mov rax,[r12+NEBOC_LAYOUT_VARIANT_COUNT_OFFSET]
 cmp rax,2
 jb .bounds
 cmp rax,8
 ja .bounds
 mov rax,[r12+NEBOC_LAYOUT_PAYLOAD_ALIGN_OFFSET]
 test rax,rax
 jz .alignment
 cmp rax,8
 ja .alignment
 lea rdx,[rax-1]
 test rax,rdx
 jnz .alignment
 mov qword [r12+NEBOC_LAYOUT_TAG_OFFSET],0
 mov qword [r12+NEBOC_LAYOUT_TAG_WIDTH_OFFSET],4
 mov qword [r12+NEBOC_LAYOUT_PAYLOAD_OFFSET],8
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_ALIGN_OFFSET],8
 mov rax,[r12+NEBOC_LAYOUT_PAYLOAD_SIZE_OFFSET]
 add rax,8
 jc .bounds
 add rax,7
 jc .bounds
 and rax,-8
 cmp rax,8
 cmovb rax,[r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_ALIGN_OFFSET]
 mov [r12+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],rax
.success:
 mov rdi,r12
 call layout_hash
 xor eax,eax
 jmp .done
.flags: mov esi,4
 jmp .diag
.alignment: mov esi,3
 jmp .diag
.bounds: mov esi,2
.diag:
 mov rdi,r12
 call layout_error
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
