; Current bounded system calls use typed lexical operands and native owners.
section .text
fcg_system_public_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 lea r14,[rel sy_plans]
.plan:
 cmp qword [r14],0
 je .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[r14]
 mov rcx,[r14+8]
 call fcg_token_matches_literal
 test eax,eax
 jz .next_plan
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,rax
 cmp qword [r14+16],0
 je .instance
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .next_plan
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .next_plan
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[r14+16]
 mov rcx,[r14+24]
 call fcg_token_matches_literal
 test eax,eax
 jz .next_plan
 cmp qword [r14+32],10
 je .channel_type
 cmp qword [r14+32],60
 je .channel_type
 cmp qword [r14+32],61
 je .channel_type
 cmp qword [r14+32],11
 jne .static_ready
.channel_type:
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jz .bad
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
.static_ready:
 mov r15,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .shape
.instance:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_probe_receiver_type
 cmp rax,[r14+24]
 jne .next_plan
 mov r15,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
.shape:
 mov rax,[r14+48]
 inc rax
 cmp [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 jne .bad
 mov qword [rsp],0
.argument:
 mov rax,[rsp]
 cmp rax,[r14+48]
 jae .yes
 mov rdx,[r14+56+rax*8]
 cmp rdx,65532
 je .canonical_keys
 cmp rdx,65531
 je .callback
 cmp rdx,65530
 je .text_or_bytes
 mov [rsp+8],rdx
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+8]
 jne .bad
 cmp qword [r14+32],10
 jne .argument_valid
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .argument_valid
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],64
 ja .limit
.argument_valid:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp]
 jmp .argument
.callback:
 mov rdi,rbx
 mov rsi,r15
 xor edx,edx
 mov ecx,NEBOC_TYPE_ID_INT
 call fcg_typed_callable_symbol
 test rax,rax
 jz .bad
 jmp .argument_valid
.text_or_bytes:
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .argument_valid
 cmp rax,NEBOC_TYPE_ID_BYTES
 jne .bad
 jmp .argument_valid
.canonical_keys:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+16],rsi
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .bad
 mov rdi,rbx
 mov rsi,[rsp+16]
 lea rdx,[rel sy_canonical_keys]
 mov ecx,13
 call fcg_token_matches_literal
 test eax,eax
 jz .bad
 jmp .argument_valid
.yes:
 mov rax,[r14+32]
 mov rcx,[r14+40]
 mov rdx,r14
 jmp .done
.next_plan:
 add r14,88
 jmp .plan
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
 jmp .no
.limit:
 mov rdi,rbx
 mov rsi,r15
 mov edx,2
 call fcg_vector_error
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_system_public_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_system_public_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov r14,rdx
 CP_APPEND sy_extern
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,1024
 cmp qword [rsp],31
 jb .frame_size
 mov esi,16384
.frame_size:
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ftm_frame_tail
 CP_APPEND sy_clear_arguments
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+8],0
 cmp qword [r14+16],0
 je .argument
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov qword [rsp+8],1
.argument:
 test r15,r15
 jz .call
 cmp qword [rsp],101
 jne .ordinary_argument
 cmp qword [rsp+8],1
 jne .ordinary_argument
 CP_APPEND sy_context_one
 jmp .argument_saved
.ordinary_argument:
 cmp qword [rsp+8],1
 jne .expression_argument
 cmp qword [rsp],41
 je .emit_callback
 cmp qword [rsp],42
 je .emit_callback
 cmp qword [rsp],46
 je .emit_callback
.expression_argument:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND ac_save
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 shl rsi,3
 cmp rsi,24
 jb .argument_offset
 add rsi,8
.argument_offset:
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ac_save_end
.argument_saved:
 inc qword [rsp+8]
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .argument
.emit_callback:
 mov rdi,rbx
 mov rsi,r15
 xor edx,edx
 mov ecx,NEBOC_TYPE_ID_INT
 call fcg_typed_callable_symbol
 test rax,rax
 jz .bad
 mov [rsp+16-8],rax
 ; Keep the argument index in its own slot; emit the exact resolved symbol.
 CP_APPEND ac_function_pointer
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ac_function_pointer_end
 CP_APPEND sy_save_callback
 mov qword [rsp+8],1
 jmp .argument_saved
.call:
 CP_APPEND sy_operation
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 cmp qword [rsp],63
 jb .ordinary_call
 cmp qword [rsp],66
 ja .ordinary_call
 CP_APPEND sy_guard_arguments
 mov rdi,rbx
 mov rsi,r12
 call fcg_assoc_find_plan
 test rax,rax
 jz .bad
 mov rsi,[rax+24]
 add rsi,[rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_BASE_SLOT_OFFSET]
 shl rsi,3
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND sy_guard_call
 jmp .done
.ordinary_call:
 CP_APPEND sy_call
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
sy_lifecycle_call: db 10,'%ifndef NEBO_SYSTEM_PUBLIC_EXTERN',10,'%define NEBO_SYSTEM_PUBLIC_EXTERN 1',10,'extern nebo_system_public',10,'%endif',10,'    call nebo_system_public',10
sy_lifecycle_call_len equ $-sy_lifecycle_call
sy_guard_arguments: db 10,'    mov rsi, [r12]',10,'    lea r8, [rbp - '
sy_guard_arguments_len equ $-sy_guard_arguments
sy_guard_call: db ']',10,'    call nebo_system_public',10,'    movq xmm0, rax',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
sy_guard_call_len equ $-sy_guard_call
sy_extern: db '%ifndef NEBO_SYSTEM_PUBLIC_EXTERN',10,'%define NEBO_SYSTEM_PUBLIC_EXTERN 1',10,'extern nebo_system_public',10,'%endif',10
sy_extern_len equ $-sy_extern
sy_clear_arguments: db '    mov qword [r12], 0',10,'    mov qword [r12+8], 0',10,'    mov qword [r12+16], 0',10,'    mov qword [r12+32], 0',10
sy_clear_arguments_len equ $-sy_clear_arguments
sy_operation: db '    mov edi, '
sy_operation_len equ $-sy_operation
sy_call: db 10,'    mov rsi, [r12]',10,'    mov rdx, [r12+8]',10,'    mov rcx, [r12+16]',10,'    mov r9, [r12+32]',10,'    lea r8, [r12+64]',10,'    call nebo_system_public',10,'    movq xmm0, rax',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
sy_call_len equ $-sy_call
sy_name_0: db 'new'
sy_name_1: db 'isCancelled'
sy_name_2: db 'cancel'
sy_name_3: db 'throwIfCancelled'
sy_name_4: db 'bounded'
sy_name_5: db 'unbuffered'
sy_name_6: db 'capacity'
sy_name_7: db 'trySend'
sy_name_8: db 'tryReceive'
sy_name_9: db 'send'
sy_name_10: db 'receive'
sy_name_11: db 'close'
sy_name_12: db 'fromMillis'
sy_name_13: db 'asNanos'
sy_name_14: db 'now'
sy_name_15: db 'elapsed'
sy_name_16: db 'sleep'
sy_name_17: db 'currentId'
sy_ns_CancellationToken: db 'CancellationToken'
sy_ns_ChannelNamespace: db 'Channel'
sy_ns_DurationNamespace: db 'Duration'
sy_ns_InstantNamespace: db 'Instant'
sy_ns_time: db 'time'
sy_ns_Process: db 'Process'
sy_ns_Json: db 'Json'
sy_ns_Csv: db 'Csv'
sy_ns_Task: db 'Task'
sy_ns_TaskGroup: db 'TaskGroup'
sy_ns_Environment: db 'Environment'
sy_env_get: db 'get'
sy_env_arguments: db 'arguments'
sy_args_length: db 'length'
sy_args_at: db 'at'
sy_task_spawn: db 'spawn'
sy_task_join: db 'joinAll'
sy_task_await: db 'await'
sy_task_map: db 'map'
sy_task_select: db 'select'
sy_save_callback: db '    mov [r12+8], rax',10
sy_save_callback_len equ $-sy_save_callback
sy_csv_read: db 'read'
sy_csv_write: db 'write'
sy_json_parse: db 'parse'
sy_json_write: db 'toJson'
sy_canonical_keys: db 'canonicalKeys'
sy_context_one: db '    mov qword [r12+8], 1',10
sy_context_one_len equ $-sy_context_one
align 8
sy_network_name_0: db 'withCapacity'
sy_network_ns_0: db 'Buffer'
sy_network_name_1: db 'zeroed'
sy_network_ns_1: db 'Buffer'
sy_network_name_2: db 'byteLength'
sy_network_name_3: db 'length'
sy_network_name_4: db 'capacity'
sy_network_name_5: db 'at'
sy_network_name_6: db 'set'
sy_network_name_7: db 'freeze'
sy_network_name_8: db 'push'
sy_network_name_9: db 'parse'
sy_network_ns_9: db 'IpAddress'
sy_network_name_10: db 'new'
sy_network_ns_10: db 'SocketAddress'
sy_network_name_11: db 'toText'
sy_network_name_12: db 'bind'
sy_network_ns_12: db 'TcpListener'
sy_network_name_13: db 'accept'
sy_network_name_14: db 'connect'
sy_network_ns_14: db 'TcpStream'
sy_network_name_15: db 'read'
sy_network_name_16: db 'writeAll'
sy_network_name_17: db 'close'
sy_network_name_18: db 'close'
sy_network_name_19: db 'close'
sy_network_name_20: db 'localAddress'
sy_network_name_21: db 'localAddress'
sy_network_name_22: db 'bind'
sy_network_ns_22: db 'UdpSocket'
sy_network_name_23: db 'sendTo'
sy_network_name_24: db 'receiveFrom'
sy_network_name_25: db 'byteLength'
sy_network_name_26: db 'sender'
sy_network_name_27: db 'new'
sy_network_ns_27: db 'HttpRequest'
sy_network_name_28: db 'header'
sy_network_name_29: db 'send'
sy_network_ns_29: db 'HttpClient'
sy_network_name_30: db 'status'
sy_network_name_31: db 'body'
align 8
sy_plans:
 dq sy_name_0,3,sy_sync_mutex,5,60,FCG_TYPE_MUTEX_INT,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_name_0,3,sy_sync_rwlock,6,61,FCG_TYPE_RWLOCK_INT,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_name_0,3,sy_sync_atomic,9,62,FCG_TYPE_ATOMIC_INT,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_sync_lock,4,0,FCG_TYPE_MUTEX_INT,63,FCG_TYPE_SYNC_GUARD,0,0,0,0,0
 dq sy_sync_trylock,7,0,FCG_TYPE_MUTEX_INT,64,FCG_TYPE_SYNC_GUARD,0,0,0,0,0
 dq sy_sync_read,4,0,FCG_TYPE_RWLOCK_INT,65,FCG_TYPE_SYNC_GUARD,0,0,0,0,0
 dq sy_sync_write,5,0,FCG_TYPE_RWLOCK_INT,66,FCG_TYPE_SYNC_GUARD,0,0,0,0,0
 dq sy_sync_load,4,0,FCG_TYPE_ATOMIC_INT,67,NEBOC_TYPE_ID_INT,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_sync_store,5,0,FCG_TYPE_ATOMIC_INT,68,NEBOC_TYPE_ID_VOID,2,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT,0,0
 dq sy_sync_exchange,15,0,FCG_TYPE_ATOMIC_INT,69,FCG_TYPE_ATOMIC_EXCHANGE,3,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT,0
 dq sy_sync_add,8,0,FCG_TYPE_ATOMIC_INT,70,NEBOC_TYPE_ID_INT,2,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT,0,0
 dq sy_sync_acquired,10,0,FCG_TYPE_SYNC_GUARD,71,NEBOC_TYPE_ID_BOOL,0,0,0,0,0
 dq sy_sync_get,3,0,FCG_TYPE_SYNC_GUARD,72,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_sync_set,3,0,FCG_TYPE_SYNC_GUARD,73,NEBOC_TYPE_ID_VOID,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_sync_release,7,0,FCG_TYPE_SYNC_GUARD,74,NEBOC_TYPE_ID_VOID,0,0,0,0,0
 dq sy_sync_swapped,7,0,FCG_TYPE_ATOMIC_EXCHANGE,75,NEBOC_TYPE_ID_BOOL,0,0,0,0,0
 dq sy_sync_observed,8,0,FCG_TYPE_ATOMIC_EXCHANGE,76,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_name_0,3,sy_ns_CancellationToken,17,1,FCG_TYPE_CANCEL_TOKEN,0,0,0,0,0
 dq sy_name_1,11,0,FCG_TYPE_CANCEL_TOKEN,2,NEBOC_TYPE_ID_BOOL,0,0,0,0,0
 dq sy_name_2,6,0,FCG_TYPE_CANCEL_TOKEN,3,NEBOC_TYPE_ID_VOID,0,0,0,0,0
 dq sy_name_3,16,0,FCG_TYPE_CANCEL_TOKEN,4,FCG_TAGGED_RESULT_BASE+1,0,0,0,0,0
 dq sy_name_4,7,sy_ns_ChannelNamespace,7,10,FCG_TYPE_CHANNEL_INT,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_name_5,10,sy_ns_ChannelNamespace,7,11,FCG_TYPE_CHANNEL_INT,0,0,0,0,0
 dq sy_name_6,8,0,FCG_TYPE_CHANNEL_INT,12,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_name_7,7,0,FCG_TYPE_CHANNEL_INT,13,FCG_TAGGED_RESULT_BASE+1,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_name_8,10,0,FCG_TYPE_CHANNEL_INT,14,FCG_TAGGED_RESULT_BASE+1,0,0,0,0,0
 dq sy_name_9,4,0,FCG_TYPE_CHANNEL_INT,15,FCG_TAGGED_RESULT_BASE+1,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_name_10,7,0,FCG_TYPE_CHANNEL_INT,16,FCG_TAGGED_RESULT_BASE+1,0,0,0,0,0
 dq sy_name_11,5,0,FCG_TYPE_CHANNEL_INT,17,NEBOC_TYPE_ID_VOID,0,0,0,0,0
 dq sy_name_12,10,sy_ns_DurationNamespace,8,20,FCG_TYPE_DURATION,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_name_13,7,0,FCG_TYPE_DURATION,21,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_name_14,3,sy_ns_InstantNamespace,7,22,FCG_TYPE_INSTANT,0,0,0,0,0
 dq sy_name_15,7,0,FCG_TYPE_INSTANT,23,FCG_TYPE_DURATION,0,0,0,0,0
 dq sy_name_16,5,sy_ns_time,4,24,NEBOC_TYPE_ID_VOID,1,FCG_TYPE_DURATION,0,0,0
 dq sy_name_17,9,sy_ns_Process,7,30,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_env_get,3,sy_ns_Environment,11,31,FCG_TAGGED_OPTION_BASE+5,1,NEBOC_TYPE_ID_TEXT,0,0,0
 dq sy_env_arguments,9,sy_ns_Environment,11,32,FCG_TYPE_PROCESS_ARGUMENTS,0,0,0,0,0
 dq sy_args_length,6,0,FCG_TYPE_PROCESS_ARGUMENTS,33,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_args_at,2,0,FCG_TYPE_PROCESS_ARGUMENTS,34,NEBOC_TYPE_ID_TEXT,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_name_0,3,sy_ns_TaskGroup,9,40,FCG_TYPE_TASK_GROUP,0,0,0,0,0
 dq sy_task_spawn,5,0,FCG_TYPE_TASK_GROUP,41,FCG_TYPE_TASK_HANDLE,1,65531,0,0,0
 dq sy_task_spawn,5,sy_ns_Task,4,42,FCG_TYPE_TASK_HANDLE,1,65531,0,0,0
 dq sy_task_join,7,0,FCG_TYPE_TASK_GROUP,43,FCG_TAGGED_RESULT_BASE+1,0,0,0,0,0
 dq sy_name_2,6,0,FCG_TYPE_TASK_GROUP,44,NEBOC_TYPE_ID_VOID,0,0,0,0,0
 dq sy_task_await,5,0,FCG_TYPE_TASK_HANDLE,45,FCG_TAGGED_RESULT_BASE+1,0,0,0,0,0
 dq sy_task_map,3,0,FCG_TYPE_TASK_HANDLE,46,FCG_TYPE_TASK_HANDLE,1,65531,0,0,0
 dq sy_task_select,6,0,FCG_TYPE_TASK_HANDLE,47,FCG_TYPE_TASK_HANDLE,1,FCG_TYPE_TASK_HANDLE,0,0,0
 dq sy_json_parse,5,sy_ns_Json,4,100,FCG_TYPE_JSON,1,NEBOC_TYPE_ID_TEXT,0,0,0
 dq sy_json_write,6,0,FCG_TYPE_JSON,101,NEBOC_TYPE_ID_TEXT,1,65532,0,0,0
 dq sy_csv_read,4,sy_ns_Csv,3,110,FCG_TYPE_NATIVE_TABLE_INT,2,FCG_TYPE_PATH,FCG_TYPE_NATIVE_SCHEMA_INT,0,0
 dq sy_csv_write,5,sy_ns_Csv,3,111,NEBOC_TYPE_ID_INT,3,FCG_TYPE_NATIVE_TABLE_INT,FCG_TYPE_PATH,FCG_TYPE_NATIVE_SCHEMA_INT,0
 dq sy_network_name_0,12,sy_network_ns_0,6,200,FCG_TYPE_IO_BUFFER,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_network_name_1,6,sy_network_ns_1,6,201,FCG_TYPE_IO_BUFFER,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_network_name_2,10,0,FCG_TYPE_IO_BUFFER,202,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_network_name_3,6,0,FCG_TYPE_IO_BUFFER,202,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_network_name_4,8,0,FCG_TYPE_IO_BUFFER,203,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_network_name_5,2,0,FCG_TYPE_IO_BUFFER,204,NEBOC_TYPE_ID_INT,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_network_name_6,3,0,FCG_TYPE_IO_BUFFER,205,NEBOC_TYPE_ID_INT,2,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT,0,0
 dq sy_network_name_7,6,0,FCG_TYPE_IO_BUFFER,206,NEBOC_TYPE_ID_BYTES,0,0,0,0,0
 dq sy_network_name_8,4,0,FCG_TYPE_IO_BUFFER,207,NEBOC_TYPE_ID_VOID,1,NEBOC_TYPE_ID_INT,0,0,0
 dq sy_network_name_9,5,sy_network_ns_9,9,210,FCG_TYPE_IP_ADDRESS,1,NEBOC_TYPE_ID_TEXT,0,0,0
 dq sy_network_name_10,3,sy_network_ns_10,13,211,FCG_TYPE_SOCKET_ADDRESS,2,FCG_TYPE_IP_ADDRESS,NEBOC_TYPE_ID_INT,0,0
 dq sy_network_name_11,6,0,FCG_TYPE_SOCKET_ADDRESS,212,NEBOC_TYPE_ID_TEXT,0,0,0,0,0
 dq sy_network_name_12,4,sy_network_ns_12,11,220,FCG_TYPE_TCP_LISTENER,1,FCG_TYPE_SOCKET_ADDRESS,0,0,0
 dq sy_network_name_13,6,0,FCG_TYPE_TCP_LISTENER,221,FCG_TYPE_TCP_STREAM,0,0,0,0,0
 dq sy_network_name_14,7,sy_network_ns_14,9,222,FCG_TYPE_TCP_STREAM,2,FCG_TYPE_SOCKET_ADDRESS,FCG_TYPE_CANCEL_TOKEN,0,0
 dq sy_network_name_15,4,0,FCG_TYPE_TCP_STREAM,223,FCG_TAGGED_RESULT_BASE+1,1,FCG_TYPE_IO_BUFFER,0,0,0
 dq sy_network_name_16,8,0,FCG_TYPE_TCP_STREAM,224,FCG_TAGGED_RESULT_BASE+1,1,65530,0,0,0
 dq sy_network_name_17,5,0,FCG_TYPE_TCP_STREAM,225,FCG_TAGGED_RESULT_BASE+1,0,0,0,0,0
 dq sy_network_name_18,5,0,FCG_TYPE_TCP_LISTENER,225,FCG_TAGGED_RESULT_BASE+1,0,0,0,0,0
 dq sy_network_name_19,5,0,FCG_TYPE_UDP_SOCKET,225,FCG_TAGGED_RESULT_BASE+1,0,0,0,0,0
 dq sy_network_name_20,12,0,FCG_TYPE_TCP_LISTENER,226,FCG_TYPE_SOCKET_ADDRESS,0,0,0,0,0
 dq sy_network_name_21,12,0,FCG_TYPE_UDP_SOCKET,226,FCG_TYPE_SOCKET_ADDRESS,0,0,0,0,0
 dq sy_network_name_22,4,sy_network_ns_22,9,230,FCG_TYPE_UDP_SOCKET,1,FCG_TYPE_SOCKET_ADDRESS,0,0,0
 dq sy_network_name_23,6,0,FCG_TYPE_UDP_SOCKET,231,FCG_TAGGED_RESULT_BASE+1,2,65530,FCG_TYPE_SOCKET_ADDRESS,0,0
 dq sy_network_name_24,11,0,FCG_TYPE_UDP_SOCKET,232,FCG_TYPE_DATAGRAM,1,FCG_TYPE_IO_BUFFER,0,0,0
 dq sy_network_name_25,10,0,FCG_TYPE_DATAGRAM,233,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_network_name_26,6,0,FCG_TYPE_DATAGRAM,234,FCG_TYPE_SOCKET_ADDRESS,0,0,0,0,0
 dq sy_network_name_27,3,sy_network_ns_27,11,240,FCG_TYPE_HTTP_REQUEST,2,NEBOC_TYPE_ID_TEXT,NEBOC_TYPE_ID_TEXT,0,0
 dq sy_network_name_28,6,0,FCG_TYPE_HTTP_REQUEST,241,NEBOC_TYPE_ID_VOID,2,NEBOC_TYPE_ID_TEXT,NEBOC_TYPE_ID_TEXT,0,0
 dq sy_network_name_29,4,sy_network_ns_29,10,242,FCG_TYPE_HTTP_RESPONSE,1,FCG_TYPE_HTTP_REQUEST,0,0,0
 dq sy_network_name_30,6,0,FCG_TYPE_HTTP_RESPONSE,243,NEBOC_TYPE_ID_INT,0,0,0,0,0
 dq sy_network_name_31,4,0,FCG_TYPE_HTTP_RESPONSE,244,NEBOC_TYPE_ID_BYTES,1,NEBOC_TYPE_ID_INT,0,0,0
 dq 0
sy_sync_mutex: db 'Mutex'
sy_sync_rwlock: db 'RwLock'
sy_sync_atomic: db 'AtomicInt'
sy_sync_lock: db 'lock'
sy_sync_trylock: db 'tryLock'
sy_sync_read: db 'read'
sy_sync_write: db 'write'
sy_sync_load: db 'load'
sy_sync_store: db 'store'
sy_sync_exchange: db 'compareExchange'
sy_sync_add: db 'fetchAdd'
sy_sync_acquired: db 'isAcquired'
sy_sync_get: db 'get'
sy_sync_set: db 'set'
sy_sync_release: db 'release'
sy_sync_swapped: db 'swapped'
sy_sync_observed: db 'observed'
section .text
