; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F06 identity, A0 layout, active-payload and ABI classification.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/nominal_types.inc"

section .text

; EAX type -> RAX size, RDX alignment; zero type is unit payload.
nominal_type_layout:
 cmp eax,NEBOC_NOM_TYPE_NONE
 je .none
 cmp eax,NEBOC_NOM_TYPE_BOOL
 je .bool
 cmp eax,NEBOC_NOM_TYPE_CHAR
 je .char
 cmp eax,NEBOC_NOM_TYPE_TEXT
 je .text
 cmp eax,NEBOC_NOM_TYPE_INT
 je .eight
 cmp eax,NEBOC_NOM_TYPE_FLOAT
 je .eight
 xor eax,eax
 xor edx,edx
 ret
.none:
 xor eax,eax
 mov edx,1
 ret
.bool:
 mov eax,1
 mov edx,1
 ret
.char:
 mov eax,4
 mov edx,4
 ret
.eight:
 mov eax,8
 mov edx,8
 ret
.text:
 mov eax,16
 mov edx,8
 ret

nominal_semantic_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 %assign nom_off NEBOC_NOM_KIND_OFFSET
 %rep 14
 xor rax,[rdi+nom_off]
 imul rax,r8
 %assign nom_off nom_off+8
 %endrep
 test rax,rax
 jnz .ready
 mov eax,1
.ready:
 mov [rdi+NEBOC_NOM_SEMANTIC_HASH_OFFSET],rax
 ret

nominal_semantic_error:
 mov [rdi+NEBOC_NOM_DIAGNOSTIC_OFFSET],rsi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

NEBOC_ABI_FUNCTION neboc_nominal_analyze
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
 cmp qword [r12+NEBOC_NOM_FOUND_OFFSET],1
 jne .invalid
 mov rax,[r12+NEBOC_NOM_FLAGS_OFFSET]
 and rax,NEBOC_NOM_FLAG_PARSED | NEBOC_NOM_FLAG_ABI_A0
 cmp rax,NEBOC_NOM_FLAG_PARSED | NEBOC_NOM_FLAG_ABI_A0
 jne .invalid
 mov rax,[r12+NEBOC_NOM_KIND_OFFSET]
 cmp rax,NEBOC_NOM_KIND_ALIAS
 je .alias
 cmp rax,NEBOC_NOM_KIND_NEWTYPE
 je .newtype
 cmp rax,NEBOC_NOM_KIND_ENUM
 jne .invalid

.enum:
 mov r14,[r12+NEBOC_NOM_VARIANT_COUNT_OFFSET]
 cmp r14,2
 jb .variant
 cmp r14,NEBOC_NOM_MAX_VARIANTS
 ja .variant
 mov r13,[r12+NEBOC_NOM_VARIANTS_OFFSET]
 test r13,r13
 jz .invalid
 xor ebx,ebx
 xor ebp,ebp                         ; max payload size
 mov r15d,1                          ; max payload alignment
.variant_loop:
 cmp rbx,r14
 jae .enum_layout
 mov rdx,rbx
 shl rdx,5
 add rdx,r13
 cmp qword [rdx+NEBOC_NOM_VARIANT_NAME_HASH_OFFSET],0
 je .variant
 mov eax,[rdx+NEBOC_NOM_VARIANT_PAYLOAD_TYPE_OFFSET]
 push rdx
 call nominal_type_layout
 pop rcx
 test rdx,rdx
 jz .payload
 mov [rcx+NEBOC_NOM_VARIANT_PAYLOAD_SIZE_OFFSET],rax
 mov [rcx+NEBOC_NOM_VARIANT_PAYLOAD_ALIGN_OFFSET],rdx
 cmp rax,rbp
 cmova rbp,rax
 cmp rdx,r15
 cmova r15,rdx
 inc rbx
 jmp .variant_loop
.enum_layout:
 mov rax,r15
 dec rax
 mov rcx,4
 add rcx,rax
 jc .internal
 not rax
 and rcx,rax
 mov [r12+NEBOC_NOM_PAYLOAD_OFFSET_OFFSET],rcx
 add rcx,rbp
 jc .internal
 mov rax,r15
 cmp rax,4
 cmovb rax,qword [rel nominal_four]
 mov [r12+NEBOC_NOM_ALIGN_OFFSET],rax
 mov rdx,rax
 dec rdx
 add rcx,rdx
 jc .internal
 not rdx
 and rcx,rdx
 mov [r12+NEBOC_NOM_SIZE_OFFSET],rcx
 cmp qword [r12+NEBOC_NOM_ACTIVE_TAG_OFFSET],r14
 jae .variant
 mov rax,[r12+NEBOC_NOM_TYPE_KEY_OFFSET]
 mov rdx,0x4130473036454e55
 xor rax,rdx
 rol rax,23
 test rax,rax
 jnz .enum_key
 mov eax,1
.enum_key:
 mov [r12+NEBOC_NOM_TYPE_KEY_OFFSET],rax
 jmp .result

.alias:
 mov eax,[r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 NEBOC_ABI_ALIGNED_CALL nominal_type_layout
 test rdx,rdx
 jz .payload
 mov [r12+NEBOC_NOM_SIZE_OFFSET],rax
 mov [r12+NEBOC_NOM_ALIGN_OFFSET],rdx
 mov rax,[r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 mov [r12+NEBOC_NOM_TYPE_KEY_OFFSET],rax
 jmp .value_type

.newtype:
 mov eax,[r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 NEBOC_ABI_ALIGNED_CALL nominal_type_layout
 test rdx,rdx
 jz .payload
 mov [r12+NEBOC_NOM_SIZE_OFFSET],rax
 mov [r12+NEBOC_NOM_ALIGN_OFFSET],rdx
 mov rax,[r12+NEBOC_NOM_TYPE_KEY_OFFSET]
 mov rdx,0x41304730364e4557
 xor rax,rdx
 rol rax,17
 test rax,rax
 jnz .newtype_key
 mov eax,1
.newtype_key:
 cmp rax,[r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 je .identity
 mov [r12+NEBOC_NOM_TYPE_KEY_OFFSET],rax
.value_type:
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_SIZEOF
 jnz .result
 mov rax,[r12+NEBOC_NOM_PAYLOAD_TYPE_OFFSET]
 test rax,rax
 jz .payload
 cmp rax,[r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 jne .payload

.result:
 mov rax,[r12+NEBOC_NOM_FLAGS_OFFSET]
 test rax,NEBOC_NOM_FLAG_OP_SIZEOF
 jnz .sizeof_result
 cmp qword [r12+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 jne .value_result
 test rax,NEBOC_NOM_FLAG_OP_DISCRIMINANT
 jnz .tag_result
 cmp qword [r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET],NEBOC_NOM_TYPE_NONE
 jne .value_result
 mov rax,[r12+NEBOC_NOM_ACTIVE_TAG_OFFSET]
 inc rax
 jmp .store_result
.tag_result:
 mov rax,[r12+NEBOC_NOM_ACTIVE_TAG_OFFSET]
 jmp .store_result
.value_result:
 mov rax,[r12+NEBOC_NOM_PAYLOAD_VALUE_OFFSET]
 jmp .store_result
.sizeof_result:
 mov rax,[r12+NEBOC_NOM_SIZE_OFFSET]
.store_result:
 mov [r12+NEBOC_NOM_RESULT_OFFSET],rax

 cmp qword [r12+NEBOC_NOM_SIZE_OFFSET],16
 ja .memory
 mov qword [r12+NEBOC_NOM_PASS_CLASS_OFFSET],NEBOC_NOM_PASS_REGISTERS
 jmp .drop
.memory:
 mov qword [r12+NEBOC_NOM_PASS_CLASS_OFFSET],NEBOC_NOM_PASS_MEMORY
.drop:
 mov qword [r12+NEBOC_NOM_DROP_COUNT_OFFSET],0
 mov rax,[r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 cmp rax,NEBOC_NOM_TYPE_TEXT
 jne .matched
 mov qword [r12+NEBOC_NOM_DROP_COUNT_OFFSET],1
.matched:
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_MATCH
 jz .success
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_MATCHED
.success:
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_ANALYZED
 mov rdi,r12
 NEBOC_ABI_ALIGNED_CALL nominal_semantic_hash
 xor eax,eax
 jmp .done
.identity:
 mov esi,NEBOC_NOM_DIAG_IDENTITY
 jmp .error
.variant:
 mov esi,NEBOC_NOM_DIAG_VARIANT
 jmp .error
.payload:
 mov esi,NEBOC_NOM_DIAG_PAYLOAD
 jmp .error
.internal:
 mov esi,NEBOC_NOM_DIAG_INTERNAL
.error:
 mov rdi,r12
 NEBOC_ABI_ALIGNED_CALL nominal_semantic_error
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

section .rodata align=8
nominal_four: dq 4

section .note.GNU-stack noalloc noexec nowrite progbits
