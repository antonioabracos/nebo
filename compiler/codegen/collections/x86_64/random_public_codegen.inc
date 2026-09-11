; Explicit Random state is a material value in the shared Program pipeline.
; Runtime/system/random and numeric/distributions own every PRNG algorithm.
; These effectful calls intentionally do not join the interpolation pure set.
section .text
%macro RP_MATCH 3
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jnz %3
%endmacro

; state, call id -> op EAX, exact result type RCX, categorical extent RDX.
fcg_random_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov qword [rsp+40],0
 mov qword [rsp+56],0
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rax
 mov qword [rsp+16],0
 test rax,rax
 jz .args_ready
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+16],rax
.args_ready:
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .method
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel rp_Random]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jz .method
 RP_MATCH rp_seed,4,.seed
 jmp .bad
.seed:
 mov qword [rsp+24],1
 mov qword [rsp+32],FCG_TYPE_RANDOM_STATE
 mov qword [rsp+48],NEBOC_TYPE_ID_INT
 jmp .one
.method:
 mov rdi,rbx
 mov rsi,[rsp]
 mov edx,1
 call fcg_probe_receiver_type
 cmp rax,FCG_TYPE_RANDOM_STATE
 jne .no
 RP_MATCH rp_uniform,7,.uniform
 RP_MATCH rp_normal,6,.normal
 RP_MATCH rp_bernoulli,9,.bernoulli
 RP_MATCH rp_categorical,11,.categorical
 RP_MATCH rp_shuffle,7,.shuffle
 RP_MATCH rp_sample,6,.sample
 jmp .no
.uniform:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 je .uniform_int
 cmp rax,NEBOC_TYPE_ID_FLOAT
 jne .bad
 mov qword [rsp+24],2
 mov qword [rsp+32],NEBOC_TYPE_ID_FLOAT
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
 jmp .two
.uniform_int:
 mov qword [rsp+24],3
 mov qword [rsp+32],NEBOC_TYPE_ID_INT
 mov qword [rsp+48],NEBOC_TYPE_ID_INT
 jmp .two
.normal:
 mov qword [rsp+24],4
 mov qword [rsp+32],NEBOC_TYPE_ID_FLOAT
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
 jmp .two
.bernoulli:
 mov qword [rsp+24],5
 mov qword [rsp+32],NEBOC_TYPE_ID_BOOL
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
 jmp .one
.categorical:
 mov qword [rsp+24],6
 mov qword [rsp+32],NEBOC_TYPE_ID_INT
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 mov rdi,rax
 call fcg_vector_type_decode
 cmp rax,NEBOC_TYPE_ID_FLOAT
 jne .bad
 mov [rsp+40],rdx
 jmp .yes
.shuffle:
 mov qword [rsp+24],7
 mov qword [rsp+32],NEBOC_TYPE_ID_VOID
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .bad
 cmp qword [rax+NEBOC_AR_BIND_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 jne .bad
 mov r15,rax
 mov rdi,rbx
 mov rsi,rax
 mov rdx,[r13+NEBOC_AST_NODE_START_OFFSET]
 call fcg_slice_live_at_source
 cmp eax,2
 je .released
 test eax,eax
 jz .bad
 mov rax,r15
 mov rdx,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 cmp rdx,64
 ja .bad
 mov [rsp+40],rdx
 mov rdi,rbx
 mov rsi,r15
 call fcg_mutable_owner_info
 test rax,rax
 jz .bad
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
 jz .bad
 ; A scoped in-place operation requires a unique view of mutable storage.
 ; Read-only parameters/call results and multiply aliased views fail closed.
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 mov rcx,[rdx+NEBOC_AR_BINDING_COUNT_OFFSET]
 mov rdx,[rdx+NEBOC_AR_BINDINGS_OFFSET]
 mov r8,[r15+NEBOC_AR_BIND_START_OFFSET]
.unique_view:
 test rcx,rcx
 jz .yes
 cmp qword [rdx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .next_view
 cmp rdx,r15
 je .next_view
 cmp [rdx+NEBOC_AR_BIND_START_OFFSET],r8
 jne .next_view
 mov [rsp+48],rcx
 mov [rsp+56],rdx
 mov rdi,rbx
 mov rsi,rdx
 mov rdx,[r13+NEBOC_AST_NODE_START_OFFSET]
 call fcg_slice_live_at_source
 cmp eax,1
 je .borrowed
 mov rcx,[rsp+48]
 mov rdx,[rsp+56]
 mov r8,[r15+NEBOC_AR_BIND_START_OFFSET]
.next_view:
 add rdx,NEBOC_AR_BIND_SIZE
 dec rcx
 jmp .unique_view
.sample:
 mov qword [rsp+24],8
 mov qword [rsp+32],FCG_TYPE_NATIVE_LIST_INT
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_FUNCTION_TYPE_SLICE_INT
 je .sample_slice
 mov rdi,rax
 call fcg_vector_type_decode
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov [rsp+40],rdx
 jmp .sample_count
.sample_slice:
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .bad
 mov r15,rax
 mov rdi,rbx
 mov rsi,rax
 mov rdx,[r13+NEBOC_AST_NODE_START_OFFSET]
 call fcg_slice_live_at_source
 cmp eax,2
 je .released
 test eax,eax
 jz .bad
 mov rax,r15
 mov rdx,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 cmp rdx,64
 ja .bad
 mov [rsp+40],rdx
 mov qword [rsp+56],1
.sample_count:
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 jmp .yes
.two:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+48]
 jne .bad
 jmp .first
.one:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
.first:
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+48]
 jne .bad
.yes:
 mov rax,[rsp+24]
 mov rcx,[rsp+32]
 mov rdx,[rsp+40]
 mov r8,[rsp+56]
 jmp .done
.bad:
 ; The numeric diagnostic record preserves the first causal type/span.
 mov edx,1
 jmp .error
.released:
 mov edx,3
 jmp .error
.borrowed:
 mov edx,4
.error:
 mov rdi,rbx
 mov rsi,r12
 call fcg_vector_error
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; State, canonical Slice record, source byte offset -> active lexical view.
; Final RELEASED flags include automatic cleanup and cannot answer this query.
fcg_slice_live_at_source:
 mov r8,[rdi+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r8,r8
 jz .no
 mov rax,[rsi+NEBOC_AR_SLICE_CREATED_TOKEN_OFFSET]
 test rax,rax
 jz .no
 dec rax
 cmp rax,[r8+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .no
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r8+NEBOC_AR_TOKENS_OFFSET]
 cmp [rax+NEBOC_TOKEN_START_OFFSET],rdx
 ja .no
 mov rax,[rsi+NEBOC_AR_SLICE_RELEASE_TOKEN_OFFSET]
 test rax,rax
 jz .yes
 dec rax
 cmp rax,[r8+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .no
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r8+NEBOC_AR_TOKENS_OFFSET]
 cmp [rax+NEBOC_TOKEN_START_OFFSET],rdx
 jbe .released
.yes:
 mov eax,1
 ret
.released:
 mov eax,2
 ret
.no:
 xor eax,eax
 ret

%macro RP_APPEND 1
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%1 %+ _len
 call fcg_append
 test eax,eax
 jnz .done
%endmacro
%macro RP_NUMBER 1
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,%1
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
%endmacro

fcg_random_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_random_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rdx
 mov [rsp+40],r8
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,rax
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+16],rsi
 mov rdi,rbx
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+24],rsi
 mov rdi,rbx
 call fcg_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+32],rax
 RP_APPEND rp_externs
 RP_APPEND ftm_frame_head
 RP_NUMBER 1024
 RP_APPEND ftm_frame_tail
 cmp qword [rsp],1
 je .first
 mov rdi,rbx
 mov rsi,[rsp+16]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 RP_APPEND rp_save_receiver
.first:
 ; A public native call has one Slice operand, in the first canonical
 ; descriptor temporary. A previous ordinary call's argument ordinal is not
 ; part of this call's ABI.
 cmp qword [rsp],7
 je .slice_temporary
 cmp qword [rsp],8
 jne .first_expression
 cmp qword [rsp+40],1
 jne .first_expression
.slice_temporary:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SLICE_TEMP_OFFSET],0
.first_expression:
 mov rdi,rbx
 mov rsi,[rsp+24]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 RP_APPEND rp_save_first
 cmp qword [rsp],2
 jb .invoke
 cmp qword [rsp],8
 je .second
 cmp qword [rsp],4
 ja .invoke
.second:
 mov rdi,rbx
 mov rsi,[rsp+32]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 RP_APPEND rp_save_second
.invoke:
 RP_APPEND rp_extent
 RP_NUMBER [rsp+8]
 RP_APPEND fcg_newline
 cmp qword [rsp+8],0
 jne .known_extent
 cmp qword [rsp],6
 je .dynamic_extent
 cmp qword [rsp],8
 jne .adapter
.dynamic_extent:
 RP_APPEND rp_dynamic_vector
 jmp .adapter
.known_extent:
 cmp qword [rsp],8
 jne .adapter
 cmp qword [rsp+40],0
 je .adapter
 RP_APPEND rp_sample_slice
.adapter:
 mov rax,[rsp]
 dec rax
 shl rax,4
 lea rdx,[rel rp_adapters]
 add rdx,rax
 mov rsi,[rdx]
 mov edx,[rdx+8]
 mov rdi,rbx
 call fcg_append
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
rp_Random: db 'Random'
rp_seed: db 'seed'
rp_uniform: db 'uniform'
rp_normal: db 'normal'
rp_bernoulli: db 'bernoulli'
rp_categorical: db 'categorical'
rp_shuffle: db 'shuffle'
rp_sample: db 'sample'
rp_externs:
 db '%ifndef NEBO_PUBLIC_RANDOM_DECLARED',10
 db '%define NEBO_PUBLIC_RANDOM_DECLARED 1',10
 db 'extern nebo_random_seed',10
 db 'extern nebo_random_next_range',10
 db 'extern nebo_distribution_uniform_f64',10
 db 'extern nebo_distribution_normal_params_f64',10
 db 'extern nebo_distribution_bernoulli',10
 db 'extern nebo_distribution_categorical',10
 db 'extern nebo_distribution_shuffle_i64',10
 db 'extern nebo_random_sample_public',10
 db '%endif',10
rp_externs_len equ $-rp_externs
rp_save_receiver:
 db '    mov [r12], rax',10
rp_save_receiver_len equ $-rp_save_receiver
rp_save_first:
 db '    mov [r12 + 8], rax',10
 db '    movq [r12 + 64], xmm0',10
rp_save_first_len equ $-rp_save_first
rp_save_second:
 db '    mov [r12 + 16], rax',10
 db '    movq [r12 + 72], xmm0',10
rp_save_second_len equ $-rp_save_second
rp_extent:
 db '    mov rdx, '
rp_extent_len equ $-rp_extent
rp_1:
 db '    lea rdi, [r12 + 32]',10
 db '    mov rsi, [r12 + 8]',10
 db '    call nebo_random_seed',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 32]',10
 db '    mov r12, [r12 + 24]',10
rp_1_len equ $-rp_1
rp_2:
 db '    mov rdi, [r12]',10
 db '    movq xmm0, [r12 + 64]',10
 db '    movq xmm1, [r12 + 72]',10
 db '    call nebo_distribution_uniform_f64',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    movq rax, xmm0',10
 db '    mov r12, [r12 + 24]',10
rp_2_len equ $-rp_2
rp_3:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    call nebo_random_next_range',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    mov rax, rdx',10
 db '    mov r12, [r12 + 24]',10
rp_3_len equ $-rp_3
rp_4:
 db '    mov rdi, [r12]',10
 db '    movq xmm0, [r12 + 64]',10
 db '    movq xmm1, [r12 + 72]',10
 db '    call nebo_distribution_normal_params_f64',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    movq rax, xmm0',10
 db '    mov r12, [r12 + 24]',10
rp_4_len equ $-rp_4
rp_5:
 db '    mov rdi, [r12]',10
 db '    movq xmm0, [r12 + 64]',10
 db '    call nebo_distribution_bernoulli',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    mov rax, rdx',10
 db '    mov r12, [r12 + 24]',10
rp_5_len equ $-rp_5
rp_6:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    call nebo_distribution_categorical',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    mov rax, rdx',10
 db '    mov r12, [r12 + 24]',10
rp_6_len equ $-rp_6
align 8
rp_adapters:
 dq rp_1,rp_1_len
 dq rp_2,rp_2_len
 dq rp_3,rp_3_len
 dq rp_4,rp_4_len
 dq rp_5,rp_5_len
 dq rp_6,rp_6_len
 dq rp_7,rp_7_len
 dq rp_8,rp_8_len
section .text

section .rodata
rp_sample_slice:
 db '    mov rax, [r12 + 8]',10,'    mov rax, [rax]',10,'    mov [r12 + 8], rax',10
rp_sample_slice_len equ $-rp_sample_slice
rp_7:
 db '    mov rdi, [r12]',10,'    mov rax, [r12 + 8]',10,'    mov rsi, [rax]',10
 db '    call nebo_distribution_shuffle_i64',10,'    test eax, eax',10,'    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    xor eax, eax',10,'    mov r12, [r12 + 24]',10
rp_7_len equ $-rp_7
rp_8:
 db '    mov rdi, [r12]',10,'    mov rsi, [r12 + 8]',10,'    mov rcx, [r12 + 16]',10
 db '    lea r8, [r12 + 80]',10,'    lea r9, [r12 + 432]',10
 db '    call nebo_random_sample_public',10,'    test eax, eax',10,'    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 80]',10,'    mov r12, [r12 + 24]',10
rp_8_len equ $-rp_8
section .text

section .rodata
rp_dynamic_vector: db '    mov rax, [r12 + 8]',10,'    mov rdx, [rax + 8]',10,'    mov rax, [rax]',10,'    mov [r12 + 8], rax',10
rp_dynamic_vector_len equ $-rp_dynamic_vector
section .text
