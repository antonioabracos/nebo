; G101 deterministic large-data owner. The model is target-neutral, bounded,
; generation-aware and publishes a result only after every check succeeds.
bits 64
default rel
%define NEBO_G101_LARGE_DATA_IMPLEMENTATION 1
%include "runtime/console/large_data.inc"

global nebo_g101_large_data_model

section .rodata
g101_model_masks: dq 0x480,0x090,0x810,0x0a0,0x021,0x088,0x104,0x642,0x242,0xfff

section .text
; RDI=points, RSI=count. Return a deterministic corpus digest in RAX.
g101_digest_points:
    push rbx
    mov rax,0xcbf29ce484222325
    xor ecx,ecx
.loop:
    cmp rcx,rsi
    jae .done
    mov rdx,rcx
    shl rdx,4
    mov rbx,[rdi+rdx+NEBO_G101_POINT_X_OFFSET]
    xor rax,rbx
    rol rax,11
    mov rbx,[rdi+rdx+NEBO_G101_POINT_Y_OFFSET]
    xor rax,rbx
    rol rax,17
    xor rax,rcx
    rol rax,7
    inc rcx
    jmp .loop
.done:
    pop rbx
    ret

; RDI=count, RSI=target. Return the number of binary LOD reductions.
g101_lod_level:
    xor eax,eax
.loop:
    cmp rdi,rsi
    jbe .done
    add rdi,1
    shr rdi,1
    inc eax
    jmp .loop
.done:
    ret

; RDI=points, RSI=count. Return min/max digest in RAX.
g101_minmax_digest:
    push rbx
    push r12
    push r13
    mov r8,[rdi+NEBO_G101_POINT_Y_OFFSET]
    mov r9,r8
    xor r10d,r10d
    xor r11d,r11d
    mov ecx,1
.scan:
    cmp rcx,rsi
    jae .mix
    mov rdx,rcx
    shl rdx,4
    mov rax,[rdi+rdx+NEBO_G101_POINT_Y_OFFSET]
    cmp rax,r8
    jge .not_min
    mov r8,rax
    mov r10,rcx
.not_min:
    cmp rax,r9
    jle .not_max
    mov r9,rax
    mov r11,rcx
.not_max:
    inc rcx
    jmp .scan
.mix:
    mov rax,0x6d696e6d61780001
    xor rax,r8
    rol rax,9
    xor rax,r10
    rol rax,13
    xor rax,r9
    rol rax,21
    xor rax,r11
    pop r13
    pop r12
    pop rbx
    ret

; RDI=points, RSI=count, RDX=threshold. Integer LTTB: each selected point
; maximizes triangle area against the following bucket average.
g101_lttb_digest:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,64
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov qword [rsp],0                 ; bucket index
    mov qword [rsp+8],0               ; previously selected point
    mov r15,0x4c54544200000001
    mov rax,[r12+NEBO_G101_POINT_X_OFFSET]
    xor r15,rax
    rol r15,11
    mov rax,[r12+NEBO_G101_POINT_Y_OFFSET]
    xor r15,rax
.bucket:
    mov rax,[rsp]
    mov rcx,r14
    sub rcx,2
    cmp rax,rcx
    jae .last
    mov rbx,r13
    sub rbx,2                         ; scaled bucket span

    ; Average the following bucket.
    mov rax,[rsp]
    add rax,1
    imul rax,rbx
    xor edx,edx
    div rcx
    inc rax
    mov r8,rax                        ; average start
    mov rax,[rsp]
    add rax,2
    imul rax,rbx
    xor edx,edx
    div rcx
    inc rax
    cmp rax,r13
    cmova rax,r13
    mov r9,rax                        ; average end (exclusive)
    xor ebp,ebp                       ; sum x
    xor r10d,r10d                     ; sum y
    xor r11d,r11d                     ; average count
.average_loop:
    cmp r8,r9
    jae .average_ready
    mov rax,r8
    shl rax,4
    add rbp,[r12+rax+NEBO_G101_POINT_X_OFFSET]
    add r10,[r12+rax+NEBO_G101_POINT_Y_OFFSET]
    inc r11
    inc r8
    jmp .average_loop
.average_ready:
    test r11,r11
    jnz .divide_average
    mov rax,r13
    dec rax
    shl rax,4
    mov rbp,[r12+rax+NEBO_G101_POINT_X_OFFSET]
    mov r10,[r12+rax+NEBO_G101_POINT_Y_OFFSET]
    jmp .average_stored
.divide_average:
    mov rax,rbp
    cqo
    idiv r11
    mov rbp,rax
    mov rax,r10
    cqo
    idiv r11
    mov r10,rax
.average_stored:
    mov [rsp+32],rbp                  ; average x
    mov [rsp+40],r10                  ; average y

    ; Candidate range for this bucket.
    mov rax,[rsp]
    imul rax,rbx
    xor edx,edx
    div rcx
    inc rax
    mov [rsp+48],rax
    mov rax,[rsp]
    inc rax
    imul rax,rbx
    xor edx,edx
    div rcx
    inc rax
    mov rdx,r13
    dec rdx
    cmp rax,rdx
    cmova rax,rdx
    cmp rax,[rsp+48]
    ja .range_ready
    inc rax
.range_ready:
    mov [rsp+56],rax
    mov rax,[rsp+8]
    shl rax,4
    mov r8,[r12+rax+NEBO_G101_POINT_X_OFFSET]
    mov r9,[r12+rax+NEBO_G101_POINT_Y_OFFSET]
    mov qword [rsp+24],0
    mov rax,[rsp+48]
    mov [rsp+16],rax
.candidate:
    mov r11,[rsp+48]
    cmp r11,[rsp+56]
    jae .selected
    mov rax,r11
    shl rax,4
    mov rdx,[r12+rax+NEBO_G101_POINT_X_OFFSET]
    mov rsi,[r12+rax+NEBO_G101_POINT_Y_OFFSET]
    mov rax,r8
    sub rax,[rsp+32]
    mov rdi,rsi
    sub rdi,r9
    imul rax,rdi
    mov rdi,r8
    sub rdi,rdx
    mov rdx,[rsp+40]
    sub rdx,r9
    imul rdi,rdx
    sub rax,rdi
    jns .area_ready
    neg rax
.area_ready:
    cmp rax,[rsp+24]
    jbe .candidate_next
    mov [rsp+24],rax
    mov [rsp+16],r11
.candidate_next:
    inc qword [rsp+48]
    jmp .candidate
.selected:
    mov rax,[rsp+16]
    mov [rsp+8],rax
    xor r15,rax
    rol r15,13
    shl rax,4
    xor r15,[r12+rax+NEBO_G101_POINT_Y_OFFSET]
    rol r15,17
    inc qword [rsp]
    jmp .bucket
.last:
    mov rax,r13
    dec rax
    xor r15,rax
    rol r15,19
    shl rax,4
    xor r15,[r12+rax+NEBO_G101_POINT_Y_OFFSET]
    mov rax,r15
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; RDI=points, RSI=count, RDX=sample count, RCX=seed. Reservoir sampling
; stores bounded selected indices on the stack and returns their digest.
g101_reservoir_digest:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,136
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    xor ebx,ebx
.fill:
    cmp rbx,r14
    jae .replace
    mov [rsp+rbx*8],rbx
    inc rbx
    jmp .fill
.replace:
    cmp rbx,r13
    jae .digest
    mov rax,r15
    mov rdx,6364136223846793005
    mul rdx
    mov rcx,1442695040888963407
    add rax,rcx
    mov r15,rax
    xor edx,edx
    mov rcx,rbx
    inc rcx
    div rcx
    cmp rdx,r14
    jae .next
    mov [rsp+rdx*8],rbx
.next:
    inc rbx
    jmp .replace
.digest:
    mov rax,0x7265736572766f69
    xor ebx,ebx
.digest_loop:
    cmp rbx,r14
    jae .done
    mov rcx,[rsp+rbx*8]
    xor rax,rcx
    rol rax,9
    shl rcx,4
    xor rax,[r12+rcx+NEBO_G101_POINT_X_OFFSET]
    rol rax,13
    xor rax,[r12+rcx+NEBO_G101_POINT_Y_OFFSET]
    rol rax,17
    inc rbx
    jmp .digest_loop
.done:
    add rsp,136
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI=points, RSI=count. Return quadrant digest in RAX and non-empty
; quadtree leaf count in RDX.
g101_density_digest:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov r8,[r12+NEBO_G101_POINT_X_OFFSET]
    mov r9,r8
    mov r10,[r12+NEBO_G101_POINT_Y_OFFSET]
    mov r11,r10
    mov ecx,1
.bounds_loop:
    cmp rcx,r13
    jae .midpoint
    mov rax,rcx
    shl rax,4
    mov rdx,[r12+rax+NEBO_G101_POINT_X_OFFSET]
    cmp rdx,r8
    cmovl r8,rdx
    cmp rdx,r9
    cmovg r9,rdx
    mov rdx,[r12+rax+NEBO_G101_POINT_Y_OFFSET]
    cmp rdx,r10
    cmovl r10,rdx
    cmp rdx,r11
    cmovg r11,rdx
    inc rcx
    jmp .bounds_loop
.midpoint:
    add r8,r9
    sar r8,1
    add r10,r11
    sar r10,1
    xor ebx,ebx
    xor ebp,ebp
    xor r14d,r14d
.quadrant_loop:
    cmp r14,r13
    jae .quadrants_done
    mov rax,r14
    shl rax,4
    xor ecx,ecx
    cmp [r12+rax+NEBO_G101_POINT_X_OFFSET],r8
    setg cl
    xor edx,edx
    cmp [r12+rax+NEBO_G101_POINT_Y_OFFSET],r10
    setg dl
    shl edx,1
    or ecx,edx
    bts rbx,rcx
    mov rdx,1
    shl rdx,cl
    add rbp,rdx
    inc r14
    jmp .quadrant_loop
.quadrants_done:
    popcnt rdx,rbx
    mov rax,0x7175616474726565
    xor rax,rbp
    rol rax,17
    xor rax,rbx
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; RDI=points, RSI=count, RDX=chunk. Return aggregate digest in RAX and
; bucket count in RDX. Each bucket contributes its integer mean.
g101_aggregate_digest:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    xor r15d,r15d
    mov rbx,0x6275636b65747301
    xor ebp,ebp
.bucket:
    cmp rbp,r13
    jae .done
    xor r8d,r8d
    xor r9d,r9d
.items:
    cmp rbp,r13
    jae .mean
    cmp r9,r14
    jae .mean
    mov rax,rbp
    shl rax,4
    add r8,[r12+rax+NEBO_G101_POINT_Y_OFFSET]
    inc rbp
    inc r9
    jmp .items
.mean:
    mov rax,r8
    cqo
    idiv r9
    xor rbx,rax
    rol rbx,11
    xor rbx,r15
    rol rbx,7
    inc r15
    jmp .bucket
.done:
    mov rax,rbx
    mov rdx,r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; RDI=points, RSI=count, RDX=capacity. Keys are the low three bits of x;
; return hits/misses/evictions in RAX/RDX/RCX.
g101_lru_counts:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,256
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov rdi,rsp
    mov rcx,16
    mov rax,-1
    rep stosq
    lea rdi,[rsp+128]
    mov rcx,16
    xor eax,eax
    rep stosq
    xor ebx,ebx                       ; hits
    xor ebp,ebp                       ; misses
    xor r15d,r15d                     ; evictions
    xor r8d,r8d                       ; point index / logical clock
.access:
    cmp r8,r13
    jae .done
    mov rax,r8
    shl rax,4
    mov r9,[r12+rax+NEBO_G101_POINT_X_OFFSET]
    and r9,7
    xor r10d,r10d
    mov r11,-1                        ; first empty slot
    mov rdx,-1                        ; oldest age
    xor ecx,ecx                       ; oldest slot
.search:
    cmp r10,r14
    jae .miss
    cmp [rsp+r10*8],r9
    je .hit
    cmp qword [rsp+r10*8],-1
    jne .age
    cmp r11,-1
    jne .next_slot
    mov r11,r10
    jmp .next_slot
.age:
    mov rax,[rsp+128+r10*8]
    cmp rdx,-1
    je .older
    cmp rax,rdx
    jae .next_slot
.older:
    mov rdx,rax
    mov rcx,r10
.next_slot:
    inc r10
    jmp .search
.hit:
    inc rbx
    mov [rsp+128+r10*8],r8
    jmp .next_access
.miss:
    inc rbp
    cmp r11,-1
    jne .install
    mov r11,rcx
    inc r15
.install:
    mov [rsp+r11*8],r9
    mov [rsp+128+r11*8],r8
.next_access:
    inc r8
    jmp .access
.done:
    mov rax,rbx
    mov rdx,rbp
    mov rcx,r15
    add rsp,256
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; RDI=request, RSI=result -> EAX=0 or stable NEBO_G101_ERROR_*.
nebo_g101_large_data_model:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,168
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r12,7
    jnz .invalid
    test r13,7
    jnz .invalid
    mov r15,rsp
    mov rdi,r15
    mov ecx,NEBO_G101_RESULT_SIZE/8
    xor eax,eax
    cld
    rep stosq

    mov eax,[r12+NEBO_G101_REQUEST_MODE_OFFSET]
    cmp eax,1
    jb .bounds
    cmp eax,10
    ja .bounds
    mov ebx,eax
    dec eax
    lea rdx,[rel g101_model_masks]
    mov rcx,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    cmp rcx,[rdx+rax*8]
    jne .options
    mov rax,rcx
    and rax,~NEBO_G101_OPTION_KNOWN
    jnz .options
    mov eax,[r12+NEBO_G101_REQUEST_TARGET_OFFSET]
    cmp eax,NEBO_G101_TARGET_HEADLESS
    jb .target
    cmp eax,NEBO_G101_TARGET_LIVE
    ja .target
    cmp qword [r12+NEBO_G101_REQUEST_SPEC_VERSION_OFFSET],NEBO_G101_SPEC_VERSION
    jne .version
    cmp qword [r12+NEBO_G101_REQUEST_POINT_STRIDE_OFFSET],NEBO_G101_POINT_SIZE
    jne .invalid
    mov r14,[r12+NEBO_G101_REQUEST_POINT_COUNT_OFFSET]
    cmp r14,4
    jb .bounds
    cmp r14,NEBO_G101_MAX_POINTS
    ja .bounds
    mov rbp,[r12+NEBO_G101_REQUEST_POINTS_PTR_OFFSET]
    test rbp,rbp
    jz .invalid
    test rbp,7
    jnz .invalid
    mov rdx,[r12+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET]
    cmp rdx,3
    jb .bounds
    cmp rdx,r14
    ja .bounds
    mov rax,[r12+NEBO_G101_REQUEST_SAMPLE_COUNT_OFFSET]
    test rax,rax
    jz .bounds
    cmp rax,NEBO_G101_MAX_SAMPLE
    ja .bounds
    cmp rax,rdx
    ja .bounds
    mov rcx,[r12+NEBO_G101_REQUEST_CHUNK_SIZE_OFFSET]
    test rcx,rcx
    jz .bounds
    cmp rcx,r14
    ja .bounds
    mov rax,[r12+NEBO_G101_REQUEST_CACHE_CAPACITY_OFFSET]
    test rax,rax
    jz .bounds
    cmp rax,NEBO_G101_MAX_CACHE
    ja .bounds
    mov rax,[r12+NEBO_G101_REQUEST_MEMORY_BUDGET_OFFSET]
    test rax,rax
    jz .budget
    cmp rax,67108864
    ja .budget
    mov rcx,[r12+NEBO_G101_REQUEST_FRAME_BUDGET_OFFSET]
    test rcx,rcx
    jz .budget
    cmp rcx,1000
    ja .budget
    mov rdx,[r12+NEBO_G101_REQUEST_QUALITY_OFFSET]
    cmp rdx,1
    jb .bounds
    cmp rdx,4
    ja .bounds
    cmp qword [r12+NEBO_G101_REQUEST_SEED_OFFSET],0
    je .bounds
    mov rax,[r12+NEBO_G101_REQUEST_GENERATION_OFFSET]
    test rax,rax
    jz .generation
    cmp rax,[r12+NEBO_G101_REQUEST_CACHE_GENERATION_OFFSET]
    jne .generation
    mov rax,[r12+NEBO_G101_REQUEST_DECIMATION_POLICY_OFFSET]
    cmp rax,NEBO_G101_DECIMATE_TARGET
    jb .policy
    cmp rax,NEBO_G101_DECIMATE_LTTB
    ja .policy
    mov rax,[r12+NEBO_G101_REQUEST_AGGREGATION_POLICY_OFFSET]
    cmp rax,NEBO_G101_AGGREGATE_COUNT
    jb .policy
    cmp rax,NEBO_G101_AGGREGATE_DENSITY
    ja .policy

    ; Resource accounting is checked before any algorithm publishes state.
    mov rax,r14
    shl rax,4
    mov rcx,[r12+NEBO_G101_REQUEST_CACHE_CAPACITY_OFFSET]
    shl rcx,4
    add rax,rcx
    add rax,NEBO_G101_RESULT_SIZE+384
    jc .overflow
    cmp rax,[r12+NEBO_G101_REQUEST_MEMORY_BUDGET_OFFSET]
    ja .budget
    mov [r15+NEBO_G101_RESULT_MEMORY_USED_OFFSET],rax
    mov rax,[r12+NEBO_G101_REQUEST_QUALITY_OFFSET]
    add rax,8
    imul rax,r14
    mov rcx,[r12+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET]
    lea rax,[rax+rcx*4]
    mov [r15+NEBO_G101_RESULT_WORK_UNITS_OFFSET],rax
    mov rcx,[r12+NEBO_G101_REQUEST_FRAME_BUDGET_OFFSET]
    shl rcx,8
    cmp rax,rcx
    ja .budget

    mov [r15+NEBO_G101_RESULT_INPUT_COUNT_OFFSET],r14
    mov rax,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G101_OPTION_LOD|NEBO_G101_OPTION_DECIMATE|NEBO_G101_OPTION_SAMPLE
    jz .full_output
    mov rcx,[r12+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET]
    jmp .output_ready
.full_output:
    mov rcx,r14
.output_ready:
    mov [r15+NEBO_G101_RESULT_OUTPUT_COUNT_OFFSET],rcx
    mov rdi,rbp
    mov rsi,r14
    call g101_digest_points
    mov [r15+NEBO_G101_RESULT_CORPUS_DIGEST_OFFSET],rax

    mov rax,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G101_OPTION_LOD
    jz .decimation
    mov rdi,r14
    mov rsi,[r12+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET]
    call g101_lod_level
    mov [r15+NEBO_G101_RESULT_LOD_LEVEL_OFFSET],rax
.decimation:
    mov rax,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G101_OPTION_DECIMATE
    jz .sampling
    mov rax,[r12+NEBO_G101_REQUEST_DECIMATION_POLICY_OFFSET]
    cmp rax,NEBO_G101_DECIMATE_MINMAX
    je .decimate_minmax
    cmp rax,NEBO_G101_DECIMATE_LTTB
    je .decimate_lttb
    mov rdi,rbp
    mov rsi,r14
    call g101_digest_points
    xor rax,[r12+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET]
    jmp .decimate_ready
.decimate_minmax:
    mov rdi,rbp
    mov rsi,r14
    call g101_minmax_digest
    jmp .decimate_ready
.decimate_lttb:
    mov rdi,rbp
    mov rsi,r14
    mov rdx,[r12+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET]
    call g101_lttb_digest
.decimate_ready:
    mov [r15+NEBO_G101_RESULT_DECIMATION_DIGEST_OFFSET],rax
.sampling:
    mov rax,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G101_OPTION_SAMPLE
    jz .density
    mov rdi,rbp
    mov rsi,r14
    mov rdx,[r12+NEBO_G101_REQUEST_SAMPLE_COUNT_OFFSET]
    mov rcx,[r12+NEBO_G101_REQUEST_SEED_OFFSET]
    call g101_reservoir_digest
    mov [r15+NEBO_G101_RESULT_SAMPLE_DIGEST_OFFSET],rax
.density:
    mov rax,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G101_OPTION_DENSITY
    jz .aggregation
    mov rdi,rbp
    mov rsi,r14
    call g101_density_digest
    mov [r15+NEBO_G101_RESULT_DENSITY_DIGEST_OFFSET],rax
    mov [r15+NEBO_G101_RESULT_DENSITY_CELLS_OFFSET],rdx
.aggregation:
    mov rax,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G101_OPTION_AGGREGATE
    jz .chunks
    mov rdi,rbp
    mov rsi,r14
    mov rdx,[r12+NEBO_G101_REQUEST_CHUNK_SIZE_OFFSET]
    call g101_aggregate_digest
    mov [r15+NEBO_G101_RESULT_AGGREGATE_DIGEST_OFFSET],rax
    mov [r15+NEBO_G101_RESULT_BUCKET_COUNT_OFFSET],rdx
.chunks:
    mov rax,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G101_OPTION_CHUNKS
    jz .cache
    mov rax,r14
    xor edx,edx
    mov rcx,[r12+NEBO_G101_REQUEST_CHUNK_SIZE_OFFSET]
    div rcx
    test rdx,rdx
    setnz dl
    movzx rdx,dl
    add rax,rdx
    mov [r15+NEBO_G101_RESULT_TILE_COUNT_OFFSET],rax
.cache:
    mov rax,[r12+NEBO_G101_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G101_OPTION_CACHE|NEBO_G101_OPTION_LRU
    jz .report
    mov rdi,rbp
    mov rsi,r14
    mov rdx,[r12+NEBO_G101_REQUEST_CACHE_CAPACITY_OFFSET]
    call g101_lru_counts
    mov [r15+NEBO_G101_RESULT_CACHE_HITS_OFFSET],rax
    mov [r15+NEBO_G101_RESULT_CACHE_MISSES_OFFSET],rdx
    mov [r15+NEBO_G101_RESULT_CACHE_EVICTIONS_OFFSET],rcx
.report:
    mov rax,[r12+NEBO_G101_REQUEST_QUALITY_OFFSET]
    mov [r15+NEBO_G101_RESULT_QUALITY_OFFSET],rax
    mov rax,[r12+NEBO_G101_REQUEST_GENERATION_OFFSET]
    mov [r15+NEBO_G101_RESULT_GENERATION_OFFSET],rax
    mov qword [r15+NEBO_G101_RESULT_SPEC_VERSION_OFFSET],NEBO_G101_SPEC_VERSION
    mov rax,0x7065726672657031
    xor ecx,ecx
.report_loop:
    cmp ecx,NEBO_G101_RESULT_REPORT_DIGEST_OFFSET/8
    jae .publish
    xor rax,[r15+rcx*8]
    rol rax,9
    xor rax,rcx
    rol rax,5
    inc ecx
    jmp .report_loop
.publish:
    mov [r15+NEBO_G101_RESULT_REPORT_DIGEST_OFFSET],rax
    mov rdi,r13
    mov rsi,r15
    mov ecx,NEBO_G101_RESULT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done

.invalid: mov eax,NEBO_G101_ERROR_INVALID
    jmp .done
.bounds: mov eax,NEBO_G101_ERROR_BOUNDS
    jmp .done
.budget: mov eax,NEBO_G101_ERROR_BUDGET
    jmp .done
.generation: mov eax,NEBO_G101_ERROR_GENERATION
    jmp .done
.options: mov eax,NEBO_G101_ERROR_OPTIONS
    jmp .done
.target: mov eax,NEBO_G101_ERROR_TARGET
    jmp .done
.version: mov eax,NEBO_G101_ERROR_VERSION
    jmp .done
.policy: mov eax,NEBO_G101_ERROR_POLICY
    jmp .done
.overflow: mov eax,NEBO_G101_ERROR_OVERFLOW
.done:
    add rsp,168
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
