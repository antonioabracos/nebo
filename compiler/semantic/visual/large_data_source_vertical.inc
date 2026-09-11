; G101 token-owned large-data LOD, sampling, cache and budget vertical.
%define G101_FAMILY_KEY 0x4731303153524331

section .rodata
%macro G101_NAME 2
g101_n_%1: db %2
g101_n_%1_len equ $-g101_n_%1
%endmacro
G101_NAME lod_root,'LargeDataLodView'
G101_NAME decimation_root,'DecimationPlanView'
G101_NAME sampling_root,'ReservoirSampleView'
G101_NAME density_root,'QuadtreeDensityView'
G101_NAME aggregate_root,'BucketAggregateView'
G101_NAME chunks_root,'ChunkedTileView'
G101_NAME cache_root,'GenerationCacheView'
G101_NAME budget_root,'VisualBudgetView'
G101_NAME profile_root,'LargeDataProfileView'
G101_NAME closeout_root,'LargeDataCloseout'
G101_NAME aggregate,'aggregate'
G101_NAME budget,'budget'
G101_NAME cache,'cache'
G101_NAME chunks,'chunks'
G101_NAME decimate,'decimate'
G101_NAME density,'density'
G101_NAME frame_ms,'frameMs'
G101_NAME lod,'lod'
G101_NAME lru,'lru'
G101_NAME memory,'memory'
G101_NAME quality,'quality'
G101_NAME sample,'sample'
%undef G101_NAME

; Bit order follows the corrected catalogue surface order. Each row is one
; bounded subgroup profile and is checked before lowering is made visible.
g101_expected_masks: dq 0x480,0x090,0x810,0x0a0,0x021,0x088,0x104,0x642,0x242,0xfff

section .text
g101_is_program:
%macro G101_ROOT 1
    lea rsi,[rel g101_n_%1]
    mov edx,g101_n_%1_len
    call ls_contains_atom
    test eax,eax
    jnz .yes
%endmacro
    G101_ROOT lod_root
    G101_ROOT decimation_root
    G101_ROOT sampling_root
    G101_ROOT density_root
    G101_ROOT aggregate_root
    G101_ROOT chunks_root
    G101_ROOT cache_root
    G101_ROOT budget_root
    G101_ROOT profile_root
    G101_ROOT closeout_root
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret
%undef G101_ROOT

; Parse one nominal receiver, its exact public option set and one shared,
; source-derived generation. No source path or fixture name participates.
neboc_g101_source_parse:
    push rbx
    push r12
    push r13
    push r14
    mov qword [rel ls_cursor],0
    call ls_start_header
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_IDENTIFIER
    jne .syntax
    mov r14,[rel ls_cursor]
    xor ebx,ebx
%macro G101_PARSE_ROOT 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g101_n_%1]
    mov edx,g101_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov ebx,%2
    jmp .root_ready
%%next:
%endmacro
    G101_PARSE_ROOT lod_root,1
    G101_PARSE_ROOT decimation_root,2
    G101_PARSE_ROOT sampling_root,3
    G101_PARSE_ROOT density_root,4
    G101_PARSE_ROOT aggregate_root,5
    G101_PARSE_ROOT chunks_root,6
    G101_PARSE_ROOT cache_root,7
    G101_PARSE_ROOT budget_root,8
    G101_PARSE_ROOT profile_root,9
    G101_PARSE_ROOT closeout_root,10
    jmp .method
.root_ready:
    xor r12d,r12d
    xor r13d,r13d
.method_loop:
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    je .return_value
    mov rdi,[rel ls_cursor]
    mov rsi,r14
    call ls_name_equal
    test eax,eax
    jz .method
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .arity
%macro G101_METHOD 2
    lea rsi,[rel g101_n_%1]
    mov edx,g101_n_%1_len
    call ls_current_atom
    test eax,eax
    jz %%next
    bt r13,%2
    jc .method
    bts r13,%2
    jmp .argument
%%next:
%endmacro
    G101_METHOD aggregate,0
    G101_METHOD budget,1
    G101_METHOD cache,2
    G101_METHOD chunks,3
    G101_METHOD decimate,4
    G101_METHOD density,5
    G101_METHOD frame_ms,6
    G101_METHOD lod,7
    G101_METHOD lru,8
    G101_METHOD memory,9
    G101_METHOD quality,10
    G101_METHOD sample,11
    jmp .method
.argument:
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_LPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
    test r12,r12
    jnz .compare_generation
    mov r12,rax
    jmp .range_generation
.compare_generation:
    cmp rax,r12
    jne .method
.range_generation:
    test rax,rax
    jz .range_error
    cmp rax,255
    ja .range_error
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .arity
    jmp .method_loop

.return_value:
    test r12,r12
    jz .method
    mov eax,ebx
    dec eax
    lea rdx,[rel g101_expected_masks]
    cmp r13,[rdx+rax*8]
    jne .method
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],r12
    jne .method
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_KW_RETURN
    jne .syntax
    inc qword [rel ls_cursor]
    call ls_finish_program
    test eax,eax
    jz .syntax
    mov rax,rbx
    shl rax,32
    mov edi,r12d
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G101_FAMILY_KEY
    call ls_success
    jmp .done
.method:
    mov edi,20
    call ls_error
    jmp .done
.type:
    mov edi,21
    call ls_error
    jmp .done
.range_error:
    mov edi,22
    call ls_error
    jmp .done
.arity:
    mov edi,25
    call ls_error
    jmp .done
.syntax:
    mov edi,20
    call ls_error
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
%undef G101_METHOD
%undef G101_PARSE_ROOT
