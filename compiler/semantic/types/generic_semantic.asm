; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F05 bounded constraint checking, deduplication and symbol identity.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_parser.inc"

section .text

semantic_error:
 mov [rdi+NEBOC_GEN_DIAGNOSTIC_OFFSET],rsi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; EAX type, EDX constraint -> EAX 1/0
constraint_satisfied:
 cmp edx,NEBOC_GEN_CONSTRAINT_COPY
 je .copy
 cmp edx,NEBOC_GEN_CONSTRAINT_EQ
 je .eq
 cmp edx,NEBOC_GEN_CONSTRAINT_COMPARABLE
 je .comparable
 cmp edx,NEBOC_GEN_CONSTRAINT_HASH
 je .hash
 xor eax,eax
 ret
.copy:
 cmp eax,NEBOC_GEN_TYPE_FLOAT
 jbe .yes
 xor eax,eax
 ret
.eq:
 cmp eax,NEBOC_GEN_TYPE_BOOL
 je .yes
 cmp eax,NEBOC_GEN_TYPE_INT
 je .yes
 cmp eax,NEBOC_GEN_TYPE_CHAR
 je .yes
 xor eax,eax
 ret
.comparable:
 cmp eax,NEBOC_GEN_TYPE_INT
 je .yes
 cmp eax,NEBOC_GEN_TYPE_CHAR
 je .yes
 cmp eax,NEBOC_GEN_TYPE_FLOAT
 je .yes
 xor eax,eax
 ret
.hash:
 cmp eax,NEBOC_GEN_TYPE_INT
 je .yes
 cmp eax,NEBOC_GEN_TYPE_CHAR
 je .yes
 cmp eax,NEBOC_GEN_TYPE_TEXT
 je .yes
 xor eax,eax
 ret
.yes:
 mov eax,1
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_generic_analyze
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 cmp qword [r12+NEBOC_GEN_FOUND_OFFSET],1
 jne .invalid
 cmp qword [r12+NEBOC_GEN_FLAGS_OFFSET],NEBOC_GEN_FLAG_PARSED
 jne .invalid
 mov r13,[r12+NEBOC_GEN_RECORDS_OFFSET]
 test r13,r13
 jz .invalid
 mov r14,[r12+NEBOC_GEN_USE_COUNT_OFFSET]
 test r14,r14
 jz .invalid
 cmp r14,NEBOC_GEN_MAX_INSTANCES
 ja .budget
 mov qword [r12+NEBOC_GEN_INSTANCE_COUNT_OFFSET],0
 mov qword [r12+NEBOC_GEN_SEMANTIC_HASH_OFFSET],0
 xor ebx,ebx
.record_loop:
 cmp rbx,r14
 jae .success
 mov r15,rbx
 shl r15,6
 add r15,r13
 mov rax,[r15+NEBOC_GEN_RECORD_TYPE_ID_OFFSET]
 mov rdx,[r15+NEBOC_GEN_RECORD_CONSTRAINT_OFFSET]
 call constraint_satisfied
 test eax,eax
 jz .constraint
 cmp qword [r15+NEBOC_GEN_RECORD_DECLARATION_HASH_OFFSET],0
 je .invalid
 mov rax,[r15+NEBOC_GEN_RECORD_DECLARATION_HASH_OFFSET]
 mov r8,1099511628211
 xor rax,[r15+NEBOC_GEN_RECORD_TYPE_ID_OFFSET]
 imul rax,r8
 xor rax,[r15+NEBOC_GEN_RECORD_CONST_KEY_OFFSET]
 imul rax,r8
 xor rax,[r15+NEBOC_GEN_RECORD_CONSTRAINT_OFFSET]
 imul rax,r8
 xor rax,[r15+NEBOC_GEN_RECORD_KIND_OFFSET]
 imul rax,r8
 test rax,rax
 jnz .key_ready
 mov eax,1
.key_ready:
 mov [r15+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET],rax
 mov rbp,[r15+NEBOC_GEN_RECORD_SYMBOL_HASH_OFFSET]
 test rbp,rbp
 jnz .symbol_ready
 mov rbp,rax
 rol rbp,29
 mov rdx,0x47303647454e3035
 xor rbp,rdx
 test rbp,rbp
 jnz .symbol_ready
 mov ebp,1
.symbol_ready:
 mov [r15+NEBOC_GEN_RECORD_SYMBOL_HASH_OFFSET],rbp

 ; Earlier equal keys deduplicate; equal symbols for different keys collide.
 xor ecx,ecx
.prior_loop:
 cmp rcx,rbx
 jae .new_instance
 mov rdx,rcx
 shl rdx,6
 add rdx,r13
 mov rax,[r15+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET]
 cmp rax,[rdx+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET]
 je .dedup
 mov rax,[r15+NEBOC_GEN_RECORD_SYMBOL_HASH_OFFSET]
 cmp rax,[rdx+NEBOC_GEN_RECORD_SYMBOL_HASH_OFFSET]
 je .collision
 inc rcx
 jmp .prior_loop
.dedup:
 jmp .next_record
.new_instance:
 mov rax,[r12+NEBOC_GEN_INSTANCE_COUNT_OFFSET]
 cmp rax,NEBOC_GEN_MAX_INSTANCES
 jae .budget
 inc qword [r12+NEBOC_GEN_INSTANCE_COUNT_OFFSET]
.next_record:
 inc rbx
 jmp .record_loop

.success:
 ; Rank each distinct key by numeric key order, independent of source use order.
 xor ebx,ebx
.rank_record:
 cmp rbx,r14
 jae .ranked
 mov r15,rbx
 shl r15,6
 add r15,r13
 mov r8,[r15+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET]
 xor ebp,ebp
 xor ecx,ecx
.rank_candidate:
 cmp rcx,r14
 jae .rank_ready
 mov rdx,rcx
 shl rdx,6
 add rdx,r13
 mov rax,[rdx+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET]
 cmp rax,r8
 jae .rank_next
 ; Count this smaller key only at its first source occurrence.
 xor r9d,r9d
.rank_prior:
 cmp r9,rcx
 jae .rank_unique
 mov r10,r9
 shl r10,6
 cmp rax,[r13+r10+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET]
 je .rank_next
 inc r9
 jmp .rank_prior
.rank_unique:
 inc rbp
.rank_next:
 inc rcx
 jmp .rank_candidate
.rank_ready:
 mov [r15+NEBOC_GEN_RECORD_CANONICAL_INDEX_OFFSET],rbp
 mov rax,r8
 mov rcx,rbp
 and ecx,63
 rol rax,cl
 xor [r12+NEBOC_GEN_SEMANTIC_HASH_OFFSET],rax
 inc rbx
 jmp .rank_record
.ranked:
 cmp qword [r12+NEBOC_GEN_SEMANTIC_HASH_OFFSET],0
 jne .hash_ready
 mov qword [r12+NEBOC_GEN_SEMANTIC_HASH_OFFSET],1
.hash_ready:
 or qword [r12+NEBOC_GEN_FLAGS_OFFSET],NEBOC_GEN_FLAG_ANALYZED
 xor eax,eax
 jmp .done
.constraint:
 mov esi,NEBOC_GEN_DIAG_CONSTRAINT
 jmp .error
.budget:
 mov esi,NEBOC_GEN_DIAG_BUDGET
 jmp .error
.collision:
 mov esi,NEBOC_GEN_DIAG_COLLISION
.error:
 mov rdi,r12
 call semantic_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
