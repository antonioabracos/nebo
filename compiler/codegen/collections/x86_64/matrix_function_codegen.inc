; Matrix function values keep the ordinary FunctionTable and ABI adapter.
; Parameters snapshot readonly descriptors; results copy into caller storage.
section .text
; Both scientific aggregates share the ordinary FunctionTable sret protocol.
; RDX tags Tensor dtypes with bit 4 for compiler-side emission only.
fcg_aggregate_sret_type_decode:
 cmp edi,FCG_TAGGED_OPTION_BASE
 jb .not_tagged
 call fcg_tagged_decode
 test eax,eax
 jz .done
 mov edx,edi
 ret
.not_tagged:
 cmp edi,FCG_TYPE_NATIVE_LIST_INT
 je .list
 cmp edi,FCG_TYPE_DICT_INT_INT
 je .dict
 cmp edi,FCG_TYPE_HASH_SET_INT
 je .set
 call fcg_matrix_type_decode
 test eax,eax
 jnz .done
 call fcg_tensor_type_decode
 test eax,eax
 jz .done
 or edx,16
.done:
 ret
.list:
 mov edx,32
 mov eax,1
 ret
.dict:
 mov edx,33
 mov eax,1
 ret
.set:
 mov edx,34
 mov eax,1
 ret

; State, Matrix expression, depth -> whether its storage is a readonly
; parameter borrow. Follow lexical aliases and view projections, but stop at
; real owned-result operations (including function sret and contiguous copy).
fcg_matrix_is_parameter_borrow:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,64
 jae .yes
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_matrix_info
 cmp eax,9
 je .view
 cmp eax,11
 je .view
 cmp eax,12
 je .view
 cmp eax,29
 jne .no
.view:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 jmp .recurse
.identifier:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jz .no
 mov r12,rax
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .alias
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 inc rcx
 cmp r12,rcx
 jbe .yes
.alias:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.recurse:
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_matrix_is_parameter_borrow
 jmp .done
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_matrix_emit_parameter_borrows:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 xor r13d,r13d
.parameter:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .ok
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r13
 mov rdi,rbx
 mov rsi,r12
 call fcg_decl_type_from_node
 mov rdi,rax
 call fcg_aggregate_sret_type_decode
 test eax,eax
 jz .next
 cmp edx,32
 jae .next
 mov [rsp],rdx
 test edx,16
 jnz .tensor_extern
 MP_APPEND mf_extern
 jmp .borrow_frame
.tensor_extern:
 MP_APPEND tf_extern
.borrow_frame:
 MP_APPEND ftm_frame_head
 mov esi,160
 test qword [rsp],16
 jz .borrow_size
 mov esi,240
.borrow_size:
 MP_NUMBER rsi
 MP_APPEND ftm_frame_tail
 MP_APPEND mf_borrow_load
 mov rsi,r13
 shl rsi,3
 MP_NUMBER rsi
 test qword [rsp],16
 jnz .tensor_borrow
 MP_APPEND mf_borrow_call
 jmp .borrow_store
.tensor_borrow:
 MP_APPEND tf_borrow_call
.borrow_store:
 MP_APPEND fcg_store_slot
 mov rsi,r13
 shl rsi,3
 MP_NUMBER rsi
 MP_APPEND fcg_store_slot_suffix
.next:
 mov r12,r14
 jmp .parameter
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; State, return expression id, depth -> emit evaluation and canonical copy.
fcg_matrix_emit_return:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 call fcg_emit_expr
 test eax,eax
 jnz .done
 ; Evaluate the returned value first, then end local views before relocating
 ; its storage. The common epilogue's idempotent release sees closed records.
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_RETURN_TYPE_OFFSET]
 call fcg_aggregate_sret_type_decode
 cmp edx,32
 jb .views_ready
 mov rdi,rbx
 xor esi,esi
 mov edx,59
 call fcg_assoc_emit_view_lifecycle
 test eax,eax
 jnz .done
.views_ready:
 MP_APPEND mf_extern
 MP_APPEND tf_extern
 MP_APPEND mf_return_load
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET]
 shl rsi,3
 MP_NUMBER rsi
 MP_APPEND mf_return_dtype
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_RETURN_TYPE_OFFSET]
 call fcg_aggregate_sret_type_decode
 mov [rsp],rdx
 cmp edx,32
 jae .collection_return
 and edx,15
 MP_NUMBER rdx
 test qword [rsp],16
 jnz .tensor_return
 MP_APPEND mf_return_call
 jmp .done
.tensor_return:
 MP_APPEND tf_return_call
 jmp .done
.collection_return:
 MP_NUMBER rdx
 MP_APPEND cf_return_call
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; State, ordinary call id, depth. Hidden sret uses RDI; source arguments keep
; source order in a linked frame, including the sixth source argument on stack.
fcg_matrix_emit_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_resolve_call
 test rax,rax
 jz .bad
 mov [rsp],rax
 mov rdi,rdx
 call fcg_aggregate_sret_type_decode
 test eax,eax
 jz .bad
 mov [rsp+8],rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rax,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov [rsp+16],rax
 MP_APPEND ftm_frame_head
 mov esi,4352
 cmp qword [rsp+8],32
 jae .size_ready
 mov esi,672
 cmp qword [rsp+8],1
 je .size_ready
 mov esi,32928
 test qword [rsp+8],16
 jz .size_ready
 mov esi,33008
.size_ready:
 MP_NUMBER rsi
 MP_APPEND ftm_frame_tail
 xor r15d,r15d
.argument:
 cmp r15,[rsp+16]
 jae .arguments_ready
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 MP_APPEND fcg_call_store_head
 mov rsi,r15
 shl rsi,3
 cmp rsi,24
 jb .argument_offset
 add rsi,8
.argument_offset:
 MP_NUMBER rsi
 MP_APPEND fcg_call_store_tail
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .argument
.arguments_ready:
 MP_APPEND mf_call_arguments
 cmp qword [rsp+16],6
 jne .call
 MP_APPEND mf_call_sixth
.call:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp]
 call neboc_abi_adapter_emit_prepared_call
 test eax,eax
 jnz .done
 ; Drop only call arguments allocated below this frame. Keep the destination
 ; descriptor/payload alive in the caller until its ordinary scope epilogue.
 MP_APPEND mf_call_restore
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
mf_extern:
 db 10,'%ifndef NEBO_MATRIX_FUNCTION_EXTERN',10,'%define NEBO_MATRIX_FUNCTION_EXTERN 1',10
 db 'extern nebo_matrix_public_borrow',10,'extern nebo_matrix_public_sret',10
 db 'extern nebo_collection_public_sret',10,'%endif',10
mf_extern_len equ $-mf_extern
mf_borrow_load: db '    mov rsi, [rbp - '
mf_borrow_load_len equ $-mf_borrow_load
mf_borrow_call:
 db ']',10,'    lea rdi, [r12 + 64]',10,'    call nebo_matrix_public_borrow',10
 db '    test eax, eax',10,'    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    mov rax, rdx',10,'    mov r12, [r12 + 24]',10
mf_borrow_call_len equ $-mf_borrow_call
mf_return_load: db '    mov rsi, rax',10,'    mov rdi, [rbp - '
mf_return_load_len equ $-mf_return_load
mf_return_dtype: db ']',10,'    mov edx, '
mf_return_dtype_len equ $-mf_return_dtype
mf_return_call:
 db 10,'    call nebo_matrix_public_sret',10,'    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10,'    mov rax, rdx',10
mf_return_call_len equ $-mf_return_call
mf_call_arguments:
 db '    lea rdi, [r12 + 64]',10,'    mov rsi, [r12]',10
 db '    mov rdx, [r12 + 8]',10,'    mov rcx, [r12 + 16]',10
 db '    mov r8, [r12 + 32]',10,'    mov r9, [r12 + 40]',10
mf_call_arguments_len equ $-mf_call_arguments
mf_call_sixth: db '    sub rsp, 16',10,'    mov r10, [r12 + 48]',10,'    mov [rsp], r10',10
mf_call_sixth_len equ $-mf_call_sixth
mf_call_restore: db '    mov rsp, r12',10,'    mov r12, [r12 + 24]',10
mf_call_restore_len equ $-mf_call_restore

tf_extern:
 db 10,'%ifndef NEBO_TENSOR_FUNCTION_EXTERN',10,'%define NEBO_TENSOR_FUNCTION_EXTERN 1',10
 db 'extern nebo_tensor_public_borrow',10,'extern nebo_tensor_public_sret',10,'%endif',10
tf_extern_len equ $-tf_extern
tf_borrow_call:
 db ']',10,'    lea rdi, [r12 + 64]',10,'    call nebo_tensor_public_borrow',10
 db '    test eax, eax',10,'    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    mov rax, rdx',10,'    mov r12, [r12 + 24]',10
tf_borrow_call_len equ $-tf_borrow_call
tf_return_call:
 db 10,'    call nebo_tensor_public_sret',10,'    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10,'    mov rax, rdx',10
tf_return_call_len equ $-tf_return_call
cf_return_call:
 db 10,'    call nebo_collection_public_sret',10,'    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10,'    mov rax, rdx',10
cf_return_call_len equ $-cf_return_call
