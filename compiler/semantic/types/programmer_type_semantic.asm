bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/programmer_type_semantic.inc"
section .text
structs_enums_variants_e_tipos_do_programador_sem_hash:
 mov rax,1469598103934665603
 mov r8,1099511628211
 %assign off 0
 %rep 11
 xor rax,[rdi+off]
 imul rax,r8
 %assign off off+8
 %endrep
 mov [rdi+neboc_structs_enums_variants_e_tipos_do_programador_SEM_HASH_OFFSET],rax
 ret
structs_enums_variants_e_tipos_do_programador_sem_error:
 mov [rdi+neboc_structs_enums_variants_e_tipos_do_programador_SEM_DIAGNOSTIC_OFFSET],rsi
 call structs_enums_variants_e_tipos_do_programador_sem_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
NEBOC_ABI_FUNCTION neboc_programmer_type_semantic_analyze
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_SEM_RESULT_TYPE_OFFSET],0
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_SEM_DIAGNOSTIC_OFFSET],0
 mov rax,[r12+neboc_structs_enums_variants_e_tipos_do_programador_SEM_KIND_OFFSET]
 cmp rax,1
 jb .identity
 cmp rax,4
 ja .identity
 cmp qword [r12+NEBOC_SEM_NOMINAL_ID_OFFSET],0
 je .identity
 mov rax,[r12+neboc_structs_enums_variants_e_tipos_do_programador_SEM_FLAGS_OFFSET]
 and rax,neboc_structs_enums_variants_e_tipos_do_programador_SEM_FLAGS_REQUIRED
 cmp rax,neboc_structs_enums_variants_e_tipos_do_programador_SEM_FLAGS_REQUIRED
 jne .unresolved
 mov rax,[r12+neboc_structs_enums_variants_e_tipos_do_programador_SEM_SOURCE_END_OFFSET]
 cmp rax,[r12+neboc_structs_enums_variants_e_tipos_do_programador_SEM_SOURCE_START_OFFSET]
 jb .span
 cmp qword [r12+NEBOC_SEM_RECURSION_DEPTH_OFFSET],8
 ja .recursion
 cmp qword [r12+NEBOC_SEM_INSTANTIATION_COUNT_OFFSET],32
 ja .limit
 cmp qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_SEM_KIND_OFFSET],NEBOC_SEM_KIND_INSTANTIATION
 jne .success
 mov rax,[r12+NEBOC_SEM_CONCRETE_TYPE_OFFSET]
 cmp rax,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_BOOL
 je .success
 cmp rax,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_INT
 je .success
 cmp rax,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_FLOAT
 je .success
 cmp rax,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_CHAR
 jne .constraint
.success:
 mov rax,[r12+NEBOC_SEM_NOMINAL_ID_OFFSET]
 rol rax,17
 xor rax,[r12+NEBOC_SEM_CONCRETE_TYPE_OFFSET]
 mov [r12+neboc_structs_enums_variants_e_tipos_do_programador_SEM_RESULT_TYPE_OFFSET],rax
 mov rdi,r12
 call structs_enums_variants_e_tipos_do_programador_sem_hash
 xor eax,eax
 jmp .done
.identity: mov esi,NEBOC_SEM_DIAG_NOMINAL_IDENTITY
 jmp .diag
.unresolved: mov esi,NEBOC_SEM_DIAG_UNRESOLVED_TYPE
 jmp .diag
.constraint: mov esi,NEBOC_SEM_DIAG_CONSTRAINT
 jmp .diag
.recursion: mov esi,NEBOC_SEM_DIAG_RECURSION
 jmp .diag
.limit: mov esi,NEBOC_SEM_DIAG_INSTANTIATION_LIMIT
 jmp .diag
.span: mov esi,neboc_structs_enums_variants_e_tipos_do_programador_SEM_DIAG_SPAN_INVARIANT
.diag:
 mov rdi,r12
 call structs_enums_variants_e_tipos_do_programador_sem_error
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
