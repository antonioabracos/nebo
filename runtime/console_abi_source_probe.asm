; G115 source-to-effect proof for the complete internal Console ABI. Every
; source mode traverses the same versioned request, capability registry,
; renderer lifecycle and 31-operation observation surface.
bits 64
default rel
%define NEBO_G115_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_abi_source_probe.inc"

extern nebo_g089_source_probe

section .note.GNU-stack noalloc noexec nowrite progbits

section .rodata align=16
g115_operations:
    dq nebo_console_emit_plot2d
    dq nebo_console_emit_table
    dq nebo_console_emit_text
    dq nebo_console_emit_value
    dq nebo_console_event_make_text
    dq nebo_console_event_stream
    dq nebo_console_event_stream_write_jsonl
    dq nebo_console_event_value_bool
    dq nebo_console_event_value_float
    dq nebo_console_event_value_none
    dq nebo_console_event_value_text
    dq g115_option_model
    dq g115_options_default
    dq g115_options_init
    dq nebo_console_options_plot_line
    dq g115_options_validate
    dq nebo_console_options_x
    dq nebo_console_options_y
    dq nebo_console_print_event
    dq nebo_console_print_text
    dq g115_registry
    dq nebo_console_render_kv
    dq g115_render_plan_is_safe
    dq nebo_console_render_plot_bar
    dq nebo_console_render_plot_line
    dq nebo_console_render_plot_points
    dq nebo_console_render_section
    dq nebo_console_render_summary
    dq nebo_console_render_table
    dq nebo_console_render_text
    dq nebo_console_write_stdout

section .bss align=16
g115_request: resb NEBO_G115_REQUEST_SIZE
g115_receipts: resb NEBO_G115_RECEIPT_SIZE * NEBO_G115_OPERATION_COUNT
g115_live_receipt: resb NEBO_G115_RECEIPT_SIZE
g115_load_receipt: resb NEBO_G115_RECEIPT_SIZE
g115_call_receipt: resb NEBO_G115_RECEIPT_SIZE
g115_unload_receipt: resb NEBO_G115_RECEIPT_SIZE
g115_negative_receipt: resb NEBO_G115_RECEIPT_SIZE
g115_registry_snapshot: resq 6
g115_last_mode: resq 1
g115_last_seed: resq 1

section .text
global nebo_g115_source_probe
global nebo_g115_surface_probe
global nebo_g115_negative_probe

; EDI=mode 1..10, ESI=source-derived seed 3501..3510.
nebo_g115_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov ebp,esi
    mov r12d,edi
    cmp r12d,1
    jb .invalid
    cmp r12d,NEBO_G115_SOURCE_MAX_MODE
    ja .invalid
    lea eax,[r12+3500]
    cmp ebp,eax
    jne .invalid

    cld
    xor eax,eax
    lea rdi,[rel g115_request]
    mov ecx,(NEBO_G115_REQUEST_SIZE + NEBO_G115_RECEIPT_SIZE * (NEBO_G115_OPERATION_COUNT + 4) + 48) / 8
    rep stosq

    lea r14,[rel g115_request]
    mov qword [r14+NEBO_G115_REQUEST_VERSION_OFFSET],NEBO_G115_REQUEST_VERSION
    mov qword [r14+NEBO_G115_REQUEST_TARGET_OFFSET],NEBO_G115_TARGET_HEADLESS
    mov qword [r14+NEBO_G115_REQUEST_CAPABILITIES_OFFSET],NEBO_G115_CAP_ALL
    mov qword [r14+NEBO_G115_REQUEST_EFFECTS_OFFSET],NEBO_G115_CAP_ALL
    mov rax,rbp
    imul rax,131
    mov rdx,0x473131355041594c
    xor rax,rdx
    mov [r14+NEBO_G115_REQUEST_PAYLOAD_DIGEST_OFFSET],rax
    lea eax,[r12+96]
    mov [r14+NEBO_G115_REQUEST_PAYLOAD_UNITS_OFFSET],rax
    mov [r14+NEBO_G115_REQUEST_GENERATION_OFFSET],rbp
    mov [r14+NEBO_G115_REQUEST_OWNER_GENERATION_OFFSET],rbp
    mov qword [r14+NEBO_G115_REQUEST_PLUGIN_ABI_OFFSET],NEBO_G115_PLUGIN_ABI_VERSION
    mov rax,NEBO_G115_PLUGIN_LAYOUT_HASH
    mov [r14+NEBO_G115_REQUEST_PLUGIN_LAYOUT_OFFSET],rax
    mov rax,rbp
    imul rax,17
    mov rdx,0x47313135504c5547
    xor rax,rdx
    mov [r14+NEBO_G115_REQUEST_PLUGIN_ID_OFFSET],rax
    mov qword [r14+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_UNLOADED
    mov qword [r14+NEBO_G115_REQUEST_FLAGS_OFFSET],NEBO_G115_FLAG_PLUGIN_TRUSTED|NEBO_G115_FLAG_JSONL_NORMALIZED|NEBO_G115_FLAG_NO_C_NO_LIBC

    lea rdi,[rel g115_registry_snapshot]
    call nebo_g115_abi_registry_snapshot
    test eax,eax
    jnz .effect
    cmp qword [rel g115_registry_snapshot],NEBO_G115_REQUEST_VERSION
    jne .effect
    cmp qword [rel g115_registry_snapshot+8],NEBO_G115_REQUEST_SIZE
    jne .effect
    cmp qword [rel g115_registry_snapshot+16],NEBO_G115_RECEIPT_SIZE
    jne .effect
    cmp qword [rel g115_registry_snapshot+24],NEBO_G115_CAP_ALL
    jne .effect
    cmp qword [rel g115_registry_snapshot+32],NEBO_G115_PLUGIN_ABI_VERSION
    jne .effect
    mov rax,NEBO_G115_PLUGIN_LAYOUT_HASH
    cmp [rel g115_registry_snapshot+40],rax
    jne .effect
    mov edi,NEBO_G115_CAP_ALL
    mov esi,NEBO_G115_CAP_ALL
    call nebo_g115_capability_registry_validate
    test eax,eax
    jnz .effect

    mov rdi,r14
    lea rsi,[rel g115_load_receipt]
    call nebo_g115_renderer_plugin_load
    test eax,eax
    jnz .effect
    cmp qword [rel g115_load_receipt+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_LOADED
    jne .effect
    mov rax,[rel g115_load_receipt+NEBO_G115_RECEIPT_PLUGIN_HANDLE_OFFSET]
    test rax,rax
    jz .effect
    mov [r14+NEBO_G115_REQUEST_VALUE_OFFSET],rax
    mov qword [r14+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_LOADED
    mov rdi,r14
    lea rsi,[rel g115_call_receipt]
    call nebo_g115_renderer_plugin_call
    test eax,eax
    jnz .effect
    cmp qword [rel g115_call_receipt+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_ACTIVE
    jne .effect
    mov qword [r14+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_ACTIVE

    xor ebx,ebx
    lea r13,[rel g115_operations]
    lea r15,[rel g115_receipts]
.operation:
    mov rdi,r14
    mov rsi,r15
    call [r13+rbx*8]
    test eax,eax
    jnz .effect
    lea rax,[rbx+1]
    cmp [r15+NEBO_G115_RECEIPT_OPERATION_OFFSET],rax
    jne .effect
    cmp qword [r15+NEBO_G115_RECEIPT_TARGET_OFFSET],NEBO_G115_TARGET_HEADLESS
    jne .effect
    cmp qword [r15+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_ACTIVE
    jne .effect
    cmp qword [r15+NEBO_G115_RECEIPT_MATURITY_OFFSET],NEBO_G115_MATURITY_MULTITARGET_RENDERER_PLUGIN_GREEN
    jne .effect
    cmp qword [r15+NEBO_G115_RECEIPT_RESULT_DIGEST_OFFSET],0
    je .effect
    cmp qword [r15+NEBO_G115_RECEIPT_AUDIT_DIGEST_OFFSET],0
    je .effect
    add r15,NEBO_G115_RECEIPT_SIZE
    inc ebx
    cmp ebx,NEBO_G115_OPERATION_COUNT
    jb .operation

    ; The logical digests are target-neutral while the target receipt changes.
    mov qword [r14+NEBO_G115_REQUEST_TARGET_OFFSET],NEBO_G115_TARGET_LIVE
    mov rdi,r14
    lea rsi,[rel g115_live_receipt]
    call nebo_console_emit_text
    test eax,eax
    jnz .effect
    cmp qword [rel g115_live_receipt+NEBO_G115_RECEIPT_TARGET_OFFSET],NEBO_G115_TARGET_LIVE
    jne .effect
    mov rax,[rel g115_live_receipt+NEBO_G115_RECEIPT_RESULT_DIGEST_OFFSET]
    cmp rax,[rel g115_receipts+(NEBO_G115_OP_EMIT_TEXT-1)*NEBO_G115_RECEIPT_SIZE+NEBO_G115_RECEIPT_RESULT_DIGEST_OFFSET]
    jne .effect
    mov rax,[rel g115_live_receipt+NEBO_G115_RECEIPT_AUDIT_DIGEST_OFFSET]
    cmp rax,[rel g115_receipts+(NEBO_G115_OP_EMIT_TEXT-1)*NEBO_G115_RECEIPT_SIZE+NEBO_G115_RECEIPT_AUDIT_DIGEST_OFFSET]
    jne .effect
    mov qword [r14+NEBO_G115_REQUEST_TARGET_OFFSET],NEBO_G115_TARGET_HEADLESS

    mov rdi,r14
    lea rsi,[rel g115_unload_receipt]
    call nebo_g115_renderer_plugin_unload
    test eax,eax
    jnz .effect
    cmp qword [rel g115_unload_receipt+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_CLOSED
    jne .effect

    mov [rel g115_last_mode],r12
    mov [rel g115_last_seed],rbp
    mov eax,ebp
    jmp .done
.invalid:
    mov eax,NEBO_G115_ERROR_INVALID
    jmp .done
.effect:
    mov eax,-99
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

%macro G115_G089_ADAPTER 3
%1:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov ebx,%2
    mov esi,[r12+NEBO_G115_REQUEST_GENERATION_OFFSET]
    and esi,255
    mov edi,%3
    call nebo_g089_source_probe
    test eax,eax
    js %%fail
    mov rdi,r12
    mov rsi,r13
    mov edx,ebx
    pop r13
    pop r12
    pop rbx
    jmp nebo_g115_observation_commit
%%fail:
    pop r13
    pop r12
    pop rbx
    ret
%endmacro

G115_G089_ADAPTER g115_option_model,NEBO_G115_OP_OPTION_MODEL,2
G115_G089_ADAPTER g115_options_default,NEBO_G115_OP_OPTIONS_DEFAULT,2
G115_G089_ADAPTER g115_options_init,NEBO_G115_OP_OPTIONS_INIT,2
G115_G089_ADAPTER g115_options_validate,NEBO_G115_OP_OPTIONS_VALIDATE,2
G115_G089_ADAPTER g115_registry,NEBO_G115_OP_REGISTRY,2
G115_G089_ADAPTER g115_render_plan_is_safe,NEBO_G115_OP_RENDER_PLAN_IS_SAFE,6
%undef G115_G089_ADAPTER

; EDI=field 1..78. Fields 3..33 are result digests and 34..64 are audit
; digests, so each catalogue surface has an independent observation.
nebo_g115_surface_probe:
    cmp edi,1
    je .mode
    cmp edi,2
    je .seed
    cmp edi,3
    jb .zero
    cmp edi,33
    jbe .result
    cmp edi,64
    jbe .audit
    cmp edi,65
    je .first_operation
    cmp edi,66
    je .last_operation
    cmp edi,67
    je .maturity
    cmp edi,68
    je .capabilities
    cmp edi,69
    je .effects
    cmp edi,70
    je .units
    cmp edi,71
    je .generation
    cmp edi,72
    je .target
    cmp edi,73
    je .plugin_abi
    cmp edi,74
    je .layout
    cmp edi,75
    je .plugin_id
    cmp edi,76
    je .load_state
    cmp edi,77
    je .call_state
    cmp edi,78
    je .unload_state
.zero:
    xor eax,eax
    ret
.mode: mov rax,[rel g115_last_mode]
    ret
.seed: mov rax,[rel g115_last_seed]
    ret
.result:
    sub edi,3
    imul edi,NEBO_G115_RECEIPT_SIZE
    lea rdx,[rel g115_receipts]
    mov rax,[rdx+rdi+NEBO_G115_RECEIPT_RESULT_DIGEST_OFFSET]
    ret
.audit:
    sub edi,34
    imul edi,NEBO_G115_RECEIPT_SIZE
    lea rdx,[rel g115_receipts]
    mov rax,[rdx+rdi+NEBO_G115_RECEIPT_AUDIT_DIGEST_OFFSET]
    ret
.first_operation: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_OPERATION_OFFSET]
    ret
.last_operation: mov rax,[rel g115_receipts+(NEBO_G115_OPERATION_COUNT-1)*NEBO_G115_RECEIPT_SIZE+NEBO_G115_RECEIPT_OPERATION_OFFSET]
    ret
.maturity: mov rax,[rel g115_receipts+(NEBO_G115_OPERATION_COUNT-1)*NEBO_G115_RECEIPT_SIZE+NEBO_G115_RECEIPT_MATURITY_OFFSET]
    ret
.capabilities: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_CAPABILITIES_OFFSET]
    ret
.effects: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_EFFECTS_OFFSET]
    ret
.units: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_PAYLOAD_UNITS_OFFSET]
    ret
.generation: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_GENERATION_OFFSET]
    ret
.target: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_TARGET_OFFSET]
    ret
.plugin_abi: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_PLUGIN_ABI_OFFSET]
    ret
.layout: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_PLUGIN_LAYOUT_OFFSET]
    ret
.plugin_id: mov rax,[rel g115_receipts+NEBO_G115_RECEIPT_PLUGIN_ID_OFFSET]
    ret
.load_state: mov rax,[rel g115_load_receipt+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET]
    ret
.call_state: mov rax,[rel g115_call_receipt+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET]
    ret
.unload_state: mov rax,[rel g115_unload_receipt+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET]
    ret

; EDI=case 1..24. Every failing ABI or lifecycle operation must leave the
; destination receipt byte-identical at the independent sentinel field.
nebo_g115_negative_probe:
    push rbx
    push r12
    push r13
    push r14
    sub rsp,8
    mov ebx,edi
    cmp ebx,1
    jb .negative_bad
    cmp ebx,NEBO_G115_SOURCE_NEGATIVE_COUNT
    ja .negative_bad
    cmp ebx,1
    je .bad_mode
    cmp ebx,2
    je .bad_seed
    mov edi,1
    mov esi,3501
    call nebo_g115_source_probe
    cmp eax,3501
    jne .negative_bad
    lea r12,[rel g115_request]
    lea r13,[rel g115_negative_receipt]
    mov rax,0x6e65676174697665
    mov [r13+NEBO_G115_RECEIPT_RESULT_DIGEST_OFFSET],rax
    cmp ebx,3
    je .null_request
    cmp ebx,4
    je .misaligned_request
    cmp ebx,5
    je .null_receipt
    cmp ebx,6
    je .misaligned_receipt
    cmp ebx,7
    je .bad_version
    cmp ebx,8
    je .bad_target
    cmp ebx,9
    je .unknown_capability
    cmp ebx,10
    je .effects_not_subset
    cmp ebx,11
    je .zero_digest
    cmp ebx,12
    je .zero_units
    cmp ebx,13
    je .excess_units
    cmp ebx,14
    je .zero_generation
    cmp ebx,15
    je .owner_mismatch
    cmp ebx,16
    je .bad_plugin_abi
    cmp ebx,17
    je .bad_layout
    cmp ebx,18
    je .zero_plugin_id
    cmp ebx,19
    je .bad_service_state
    cmp ebx,20
    je .missing_trust
    cmp ebx,21
    je .missing_jsonl
    cmp ebx,22
    je .missing_capability
    cmp ebx,23
    je .plugin_double_load
    jmp .plugin_bad_handle
.bad_mode:
    xor edi,edi
    mov esi,3501
    call nebo_g115_source_probe
    cmp eax,NEBO_G115_ERROR_INVALID
    jmp .negative_result
.bad_seed:
    mov edi,1
    mov esi,3502
    call nebo_g115_source_probe
    cmp eax,NEBO_G115_ERROR_INVALID
    jmp .negative_result
.null_request:
    xor edi,edi
    mov rsi,r13
    call nebo_console_emit_text
    mov r14d,NEBO_G115_ERROR_INVALID
    jmp .check_atomic
.misaligned_request:
    lea rdi,[r12+1]
    mov rsi,r13
    call nebo_console_emit_text
    mov r14d,NEBO_G115_ERROR_INVALID
    jmp .check_atomic
.null_receipt:
    mov rdi,r12
    xor esi,esi
    call nebo_console_emit_text
    cmp eax,NEBO_G115_ERROR_INVALID
    jmp .negative_result
.misaligned_receipt:
    mov rdi,r12
    lea rsi,[r13+1]
    call nebo_console_emit_text
    cmp eax,NEBO_G115_ERROR_INVALID
    jmp .negative_result
.bad_version:
    inc qword [r12+NEBO_G115_REQUEST_VERSION_OFFSET]
    mov r14d,NEBO_G115_ERROR_VERSION
    jmp .service
.bad_target:
    mov qword [r12+NEBO_G115_REQUEST_TARGET_OFFSET],3
    mov r14d,NEBO_G115_ERROR_INVALID
    jmp .service
.unknown_capability:
    or qword [r12+NEBO_G115_REQUEST_CAPABILITIES_OFFSET],0x80
    mov r14d,NEBO_G115_ERROR_CAPABILITY
    jmp .service
.effects_not_subset:
    mov qword [r12+NEBO_G115_REQUEST_CAPABILITIES_OFFSET],NEBO_G115_CAP_EMIT|NEBO_G115_CAP_RENDER|NEBO_G115_CAP_PLUGIN
    mov qword [r12+NEBO_G115_REQUEST_EFFECTS_OFFSET],NEBO_G115_CAP_ALL
    mov r14d,NEBO_G115_ERROR_CAPABILITY
    jmp .service
.zero_digest:
    mov qword [r12+NEBO_G115_REQUEST_PAYLOAD_DIGEST_OFFSET],0
    mov r14d,NEBO_G115_ERROR_INTEGRITY
    jmp .service
.zero_units:
    mov qword [r12+NEBO_G115_REQUEST_PAYLOAD_UNITS_OFFSET],0
    mov r14d,NEBO_G115_ERROR_BOUNDS
    jmp .service
.excess_units:
    mov qword [r12+NEBO_G115_REQUEST_PAYLOAD_UNITS_OFFSET],NEBO_G115_MAX_PAYLOAD_UNITS+1
    mov r14d,NEBO_G115_ERROR_BOUNDS
    jmp .service
.zero_generation:
    mov qword [r12+NEBO_G115_REQUEST_GENERATION_OFFSET],0
    mov r14d,NEBO_G115_ERROR_STATE
    jmp .service
.owner_mismatch:
    inc qword [r12+NEBO_G115_REQUEST_OWNER_GENERATION_OFFSET]
    mov r14d,NEBO_G115_ERROR_STATE
    jmp .service
.bad_plugin_abi:
    inc qword [r12+NEBO_G115_REQUEST_PLUGIN_ABI_OFFSET]
    mov r14d,NEBO_G115_ERROR_ABI
    jmp .service
.bad_layout:
    inc qword [r12+NEBO_G115_REQUEST_PLUGIN_LAYOUT_OFFSET]
    mov r14d,NEBO_G115_ERROR_ABI
    jmp .service
.zero_plugin_id:
    mov qword [r12+NEBO_G115_REQUEST_PLUGIN_ID_OFFSET],0
    mov r14d,NEBO_G115_ERROR_INTEGRITY
    jmp .service
.bad_service_state:
    mov qword [r12+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_UNLOADED
    mov r14d,NEBO_G115_ERROR_STATE
    jmp .service
.missing_trust:
    mov qword [r12+NEBO_G115_REQUEST_FLAGS_OFFSET],NEBO_G115_FLAG_NO_C_NO_LIBC
    mov r14d,NEBO_G115_ERROR_INTEGRITY
    jmp .service
.missing_jsonl:
    mov qword [r12+NEBO_G115_REQUEST_FLAGS_OFFSET],NEBO_G115_REQUIRED_FLAGS
    mov rdi,r12
    mov rsi,r13
    call nebo_console_event_stream_write_jsonl
    mov r14d,NEBO_G115_ERROR_INTEGRITY
    jmp .check_atomic
.missing_capability:
    and qword [r12+NEBO_G115_REQUEST_CAPABILITIES_OFFSET],~NEBO_G115_CAP_PLUGIN
    and qword [r12+NEBO_G115_REQUEST_EFFECTS_OFFSET],~NEBO_G115_CAP_PLUGIN
    mov r14d,NEBO_G115_ERROR_CAPABILITY
    jmp .service
.plugin_double_load:
    mov qword [r12+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_LOADED
    mov rdi,r12
    mov rsi,r13
    call nebo_g115_renderer_plugin_load
    mov r14d,NEBO_G115_ERROR_STATE
    jmp .check_atomic
.plugin_bad_handle:
    inc qword [r12+NEBO_G115_REQUEST_VALUE_OFFSET]
    mov rdi,r12
    mov rsi,r13
    call nebo_g115_renderer_plugin_unload
    mov r14d,NEBO_G115_ERROR_STATE
    jmp .check_atomic
.service:
    mov rdi,r12
    mov rsi,r13
    call nebo_console_emit_text
.check_atomic:
    cmp eax,r14d
    jne .negative_fail
    mov rax,0x6e65676174697665
    cmp [r13+NEBO_G115_RECEIPT_RESULT_DIGEST_OFFSET],rax
    jne .negative_fail
    xor eax,eax
    jmp .negative_done
.negative_result:
    jne .negative_fail
    xor eax,eax
    jmp .negative_done
.negative_bad:
    mov eax,NEBO_G115_ERROR_INVALID
    jmp .negative_done
.negative_fail:
    mov eax,-99
.negative_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
