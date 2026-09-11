; G101 source-to-effect bridge. Real Nebo source lowers to mode+generation;
; this probe builds a bounded synthetic corpus and invokes the shared owner.
bits 64
default rel
%define NEBO_G101_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/large_data_source_probe.inc"
%include "runtime/console/large_data.inc"

global nebo_g101_source_probe
global nebo_g101_observation_probe
global nebo_g101_counter_probe
global nebo_g101_negative_probe

section .rodata
g101_probe_masks: dq 0x480,0x090,0x810,0x0a0,0x021,0x088,0x104,0x642,0x242,0xfff

section .bss
align 16
g101_request: resb NEBO_G101_REQUEST_SIZE
align 16
g101_points: resb NEBO_G101_POINT_SIZE*16
align 16
g101_headless: resb NEBO_G101_RESULT_SIZE
align 16
g101_live: resb NEBO_G101_RESULT_SIZE

section .text
; RDI=mode, RSI=seed. Construct a deterministic, non-uniform 16-point corpus.
g101_prepare:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    lea rdi,[rel g101_request]
    mov ecx,NEBO_G101_REQUEST_SIZE/8
    xor eax,eax
    cld
    rep stosq
    lea rdi,[rel g101_points]
    mov ecx,(NEBO_G101_POINT_SIZE*16)/8
    xor eax,eax
    rep stosq
    lea r10,[rel g101_points]
    xor ebx,ebx
.point_loop:
    cmp ebx,16
    jae .request
    mov rax,rbx
    and rax,7
    mov rdx,rbx
    shl rdx,4
    mov [r10+rdx+NEBO_G101_POINT_X_OFFSET],rax
    mov rax,rbx
    imul rax,rax
    lea rax,[rax+rbx*4]
    mov rcx,r13
    imul rcx,3
    add rax,rcx
    xor edx,edx
    mov ecx,97
    div rcx
    inc rdx
    mov rax,rbx
    shl rax,4
    mov [r10+rax+NEBO_G101_POINT_Y_OFFSET],rdx
    inc ebx
    jmp .point_loop
.request:
    mov dword [rel g101_request+NEBO_G101_REQUEST_MODE_OFFSET],r12d
    mov dword [rel g101_request+NEBO_G101_REQUEST_TARGET_OFFSET],NEBO_G101_TARGET_HEADLESS
    lea rax,[rel g101_points]
    mov [rel g101_request+NEBO_G101_REQUEST_POINTS_PTR_OFFSET],rax
    mov qword [rel g101_request+NEBO_G101_REQUEST_POINT_COUNT_OFFSET],16
    mov qword [rel g101_request+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET],6
    mov qword [rel g101_request+NEBO_G101_REQUEST_SAMPLE_COUNT_OFFSET],5
    mov qword [rel g101_request+NEBO_G101_REQUEST_CHUNK_SIZE_OFFSET],4
    mov qword [rel g101_request+NEBO_G101_REQUEST_CACHE_CAPACITY_OFFSET],8
    mov qword [rel g101_request+NEBO_G101_REQUEST_MEMORY_BUDGET_OFFSET],65536
    mov qword [rel g101_request+NEBO_G101_REQUEST_FRAME_BUDGET_OFFSET],16
    mov rax,r13
    and eax,3
    inc eax
    mov [rel g101_request+NEBO_G101_REQUEST_QUALITY_OFFSET],rax
    mov [rel g101_request+NEBO_G101_REQUEST_SEED_OFFSET],r13
    mov [rel g101_request+NEBO_G101_REQUEST_GENERATION_OFFSET],r13
    mov [rel g101_request+NEBO_G101_REQUEST_CACHE_GENERATION_OFFSET],r13
    mov eax,r12d
    dec eax
    lea rdx,[rel g101_probe_masks]
    mov rax,[rdx+rax*8]
    mov [rel g101_request+NEBO_G101_REQUEST_OPTIONS_OFFSET],rax
    mov qword [rel g101_request+NEBO_G101_REQUEST_SPEC_VERSION_OFFSET],NEBO_G101_SPEC_VERSION
    mov qword [rel g101_request+NEBO_G101_REQUEST_POINT_STRIDE_OFFSET],NEBO_G101_POINT_SIZE
    mov qword [rel g101_request+NEBO_G101_REQUEST_DECIMATION_POLICY_OFFSET],NEBO_G101_DECIMATE_LTTB
    mov qword [rel g101_request+NEBO_G101_REQUEST_AGGREGATION_POLICY_OFFSET],NEBO_G101_AGGREGATE_MEAN
    pop r13
    pop r12
    pop rbx
    ret

; RDI=mode, RSI=seed -> seed on success, negative error otherwise.
nebo_g101_source_probe:
    push rbx
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    cmp r12,1
    jb .invalid
    cmp r12,10
    ja .invalid
    test r13,r13
    jz .invalid
    cmp r13,255
    ja .invalid
    call g101_prepare
    lea rdi,[rel g101_request]
    lea rsi,[rel g101_headless]
    call nebo_g101_large_data_model
    test eax,eax
    jnz .done
    cmp qword [rel g101_headless+NEBO_G101_RESULT_INPUT_COUNT_OFFSET],16
    jne .effect
    cmp [rel g101_headless+NEBO_G101_RESULT_GENERATION_OFFSET],r13
    jne .effect
    cmp qword [rel g101_headless+NEBO_G101_RESULT_SPEC_VERSION_OFFSET],NEBO_G101_SPEC_VERSION
    jne .effect
    cmp qword [rel g101_headless+NEBO_G101_RESULT_CORPUS_DIGEST_OFFSET],0
    je .effect
    cmp qword [rel g101_headless+NEBO_G101_RESULT_REPORT_DIGEST_OFFSET],0
    je .effect
    cmp qword [rel g101_headless+NEBO_G101_RESULT_MEMORY_USED_OFFSET],0
    je .effect
    cmp qword [rel g101_headless+NEBO_G101_RESULT_WORK_UNITS_OFFSET],0
    je .effect
    mov r14,[rel g101_request+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    mov rax,r14
    test rax,NEBO_G101_OPTION_LOD|NEBO_G101_OPTION_DECIMATE|NEBO_G101_OPTION_SAMPLE
    jz .expect_full
    cmp qword [rel g101_headless+NEBO_G101_RESULT_OUTPUT_COUNT_OFFSET],6
    jne .effect
    jmp .optional
.expect_full:
    cmp qword [rel g101_headless+NEBO_G101_RESULT_OUTPUT_COUNT_OFFSET],16
    jne .effect
.optional:
    test r14,NEBO_G101_OPTION_LOD
    jz .no_lod
    cmp qword [rel g101_headless+NEBO_G101_RESULT_LOD_LEVEL_OFFSET],2
    jne .effect
    jmp .decimate
.no_lod:
    cmp qword [rel g101_headless+NEBO_G101_RESULT_LOD_LEVEL_OFFSET],0
    jne .effect
.decimate:
    test r14,NEBO_G101_OPTION_DECIMATE
    jz .no_decimate
    cmp qword [rel g101_headless+NEBO_G101_RESULT_DECIMATION_DIGEST_OFFSET],0
    je .effect
    jmp .sample
.no_decimate:
    cmp qword [rel g101_headless+NEBO_G101_RESULT_DECIMATION_DIGEST_OFFSET],0
    jne .effect
.sample:
    test r14,NEBO_G101_OPTION_SAMPLE
    jz .no_sample
    cmp qword [rel g101_headless+NEBO_G101_RESULT_SAMPLE_DIGEST_OFFSET],0
    je .effect
    jmp .density
.no_sample:
    cmp qword [rel g101_headless+NEBO_G101_RESULT_SAMPLE_DIGEST_OFFSET],0
    jne .effect
.density:
    test r14,NEBO_G101_OPTION_DENSITY
    jz .aggregate
    cmp qword [rel g101_headless+NEBO_G101_RESULT_DENSITY_CELLS_OFFSET],0
    je .effect
.aggregate:
    test r14,NEBO_G101_OPTION_AGGREGATE
    jz .chunks
    cmp qword [rel g101_headless+NEBO_G101_RESULT_BUCKET_COUNT_OFFSET],4
    jne .effect
.chunks:
    test r14,NEBO_G101_OPTION_CHUNKS
    jz .cache
    cmp qword [rel g101_headless+NEBO_G101_RESULT_TILE_COUNT_OFFSET],4
    jne .effect
.cache:
    test r14,NEBO_G101_OPTION_CACHE|NEBO_G101_OPTION_LRU
    jz .target_parity
    cmp qword [rel g101_headless+NEBO_G101_RESULT_CACHE_HITS_OFFSET],8
    jne .effect
    cmp qword [rel g101_headless+NEBO_G101_RESULT_CACHE_MISSES_OFFSET],8
    jne .effect
    cmp qword [rel g101_headless+NEBO_G101_RESULT_CACHE_EVICTIONS_OFFSET],0
    jne .effect
.target_parity:
    mov dword [rel g101_request+NEBO_G101_REQUEST_TARGET_OFFSET],NEBO_G101_TARGET_LIVE
    lea rdi,[rel g101_request]
    lea rsi,[rel g101_live]
    call nebo_g101_large_data_model
    test eax,eax
    jnz .done
    lea rsi,[rel g101_headless]
    lea rdi,[rel g101_live]
    mov ecx,NEBO_G101_RESULT_SIZE/8
    cld
    repe cmpsq
    jne .effect
    mov eax,r13d
    jmp .done
.invalid:
    mov eax,NEBO_G101_ERROR_INVALID
    jmp .done
.effect:
    mov eax,-99
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI=mode, RSI=seed -> deterministic report observation.
nebo_g101_observation_probe:
    push rbx
    mov rbx,rsi
    call nebo_g101_source_probe
    cmp eax,ebx
    jne .failed
    mov rax,[rel g101_headless+NEBO_G101_RESULT_REPORT_DIGEST_OFFSET]
    xor rax,[rel g101_headless+NEBO_G101_RESULT_CORPUS_DIGEST_OFFSET]
    pop rbx
    ret
.failed:
    cdqe
    pop rbx
    ret

; RDI=mode, RSI=seed, RDX=selector -> selected factual counter.
nebo_g101_counter_probe:
    push rbx
    push r12
    mov rbx,rsi
    mov r12,rdx
    call nebo_g101_source_probe
    cmp eax,ebx
    jne .counter_done
    cmp r12,1
    je .output
    cmp r12,2
    je .lod
    cmp r12,3
    je .cells
    cmp r12,4
    je .buckets
    cmp r12,5
    je .tiles
    cmp r12,6
    je .hits
    mov eax,NEBO_G101_ERROR_INVALID
    jmp .counter_done
.output: mov rax,[rel g101_headless+NEBO_G101_RESULT_OUTPUT_COUNT_OFFSET]
    jmp .counter_done
.lod: mov rax,[rel g101_headless+NEBO_G101_RESULT_LOD_LEVEL_OFFSET]
    jmp .counter_done
.cells: mov rax,[rel g101_headless+NEBO_G101_RESULT_DENSITY_CELLS_OFFSET]
    jmp .counter_done
.buckets: mov rax,[rel g101_headless+NEBO_G101_RESULT_BUCKET_COUNT_OFFSET]
    jmp .counter_done
.tiles: mov rax,[rel g101_headless+NEBO_G101_RESULT_TILE_COUNT_OFFSET]
    jmp .counter_done
.hits: mov rax,[rel g101_headless+NEBO_G101_RESULT_CACHE_HITS_OFFSET]
.counter_done:
    pop r12
    pop rbx
    ret

; RDI=negative case 1..16. Return the owner's stable error and verify that
; the result sentinel remains byte-identical after failure.
nebo_g101_negative_probe:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov edi,10
    mov esi,53
    call g101_prepare
    cmp r12,1
    je .bad_target
    cmp r12,2
    je .null_points
    cmp r12,3
    je .short_corpus
    cmp r12,4
    je .small_target
    cmp r12,5
    je .large_sample
    cmp r12,6
    je .zero_chunk
    cmp r12,7
    je .large_cache
    cmp r12,8
    je .small_memory
    cmp r12,9
    je .zero_frame
    cmp r12,10
    je .bad_quality
    cmp r12,11
    je .stale_cache
    cmp r12,12
    je .unknown_options
    cmp r12,13
    je .bad_version
    cmp r12,14
    je .bad_stride
    cmp r12,15
    je .bad_decimation
    cmp r12,16
    je .bad_aggregation
    mov eax,NEBO_G101_ERROR_INVALID
    jmp .done
.bad_target: mov dword [rel g101_request+NEBO_G101_REQUEST_TARGET_OFFSET],3
    jmp .invoke
.null_points: mov qword [rel g101_request+NEBO_G101_REQUEST_POINTS_PTR_OFFSET],0
    jmp .invoke
.short_corpus: mov qword [rel g101_request+NEBO_G101_REQUEST_POINT_COUNT_OFFSET],3
    jmp .invoke
.small_target: mov qword [rel g101_request+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET],2
    jmp .invoke
.large_sample: mov qword [rel g101_request+NEBO_G101_REQUEST_SAMPLE_COUNT_OFFSET],17
    jmp .invoke
.zero_chunk: mov qword [rel g101_request+NEBO_G101_REQUEST_CHUNK_SIZE_OFFSET],0
    jmp .invoke
.large_cache: mov qword [rel g101_request+NEBO_G101_REQUEST_CACHE_CAPACITY_OFFSET],17
    jmp .invoke
.small_memory: mov qword [rel g101_request+NEBO_G101_REQUEST_MEMORY_BUDGET_OFFSET],1
    jmp .invoke
.zero_frame: mov qword [rel g101_request+NEBO_G101_REQUEST_FRAME_BUDGET_OFFSET],0
    jmp .invoke
.bad_quality: mov qword [rel g101_request+NEBO_G101_REQUEST_QUALITY_OFFSET],5
    jmp .invoke
.stale_cache: inc qword [rel g101_request+NEBO_G101_REQUEST_CACHE_GENERATION_OFFSET]
    jmp .invoke
.unknown_options: or qword [rel g101_request+NEBO_G101_REQUEST_OPTIONS_OFFSET],1 << 20
    jmp .invoke
.bad_version: mov qword [rel g101_request+NEBO_G101_REQUEST_SPEC_VERSION_OFFSET],2
    jmp .invoke
.bad_stride: mov qword [rel g101_request+NEBO_G101_REQUEST_POINT_STRIDE_OFFSET],8
    jmp .invoke
.bad_decimation: mov qword [rel g101_request+NEBO_G101_REQUEST_DECIMATION_POLICY_OFFSET],4
    jmp .invoke
.bad_aggregation: mov qword [rel g101_request+NEBO_G101_REQUEST_AGGREGATION_POLICY_OFFSET],5
.invoke:
    mov rbx,0x6b6b6b6b6b6b6b6b
    lea rdi,[rel g101_headless]
    mov rax,rbx
    mov ecx,NEBO_G101_RESULT_SIZE/8
    cld
    rep stosq
    lea rdi,[rel g101_request]
    lea rsi,[rel g101_headless]
    call nebo_g101_large_data_model
    mov r13d,eax
    lea rsi,[rel g101_headless]
    mov ecx,NEBO_G101_RESULT_SIZE/8
.sentinel:
    cmp [rsi],rbx
    jne .atomicity
    add rsi,8
    dec ecx
    jnz .sentinel
    mov eax,r13d
    jmp .done
.atomicity:
    mov eax,-99
.done:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
