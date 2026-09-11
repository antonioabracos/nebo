; G097 target-neutral Matrix/Tensor/Volume view and comparison owner.
bits 64
default rel
%define NEBO_G097_SCIENTIFIC_VIEW_IMPLEMENTATION 1
%include "runtime/console/scientific_view.inc"

section .rodata align=16
g97_abs_mask: dq 0x7fffffffffffffff,0x7fffffffffffffff

section .text
global nebo_g097_scientific_view_model

; scientific_view_model(request*, result*) -> stable status.
; The result is staged on the stack and copied atomically only after validation.
nebo_g097_scientific_view_model:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,128
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

    mov ebx,[r12+NEBO_G097_REQUEST_KIND_OFFSET]
    cmp ebx,NEBO_G097_KIND_MATRIX
    jb .kind
    cmp ebx,NEBO_G097_KIND_COMPARE
    ja .kind
    mov eax,[r12+NEBO_G097_REQUEST_TARGET_OFFSET]
    cmp eax,NEBO_G097_TARGET_HEADLESS
    jb .target
    cmp eax,NEBO_G097_TARGET_LIVE
    ja .target
    mov r10,[r12+NEBO_G097_REQUEST_RANK_OFFSET]
    cmp r10,2
    jb .shape
    cmp r10,NEBO_G097_MAX_RANK
    ja .shape
    cmp ebx,NEBO_G097_KIND_MATRIX
    jne .not_matrix_rank
    cmp r10,2
    jne .shape
.not_matrix_rank:
    cmp ebx,NEBO_G097_KIND_VOLUME
    jne .rank_ready
    cmp r10,3
    jne .shape
.rank_ready:
    mov r9,[r12+NEBO_G097_REQUEST_SHAPE_PTR_OFFSET]
    test r9,r9
    jz .invalid
    test r9,7
    jnz .invalid
    mov rax,1
    xor ecx,ecx
.shape_loop:
    cmp rcx,r10
    jae .shape_product_ready
    mov rdx,[r9+rcx*8]
    test rdx,rdx
    jz .shape
    cmp rdx,NEBO_G097_MAX_AXIS
    ja .bounds
    mul qword [r9+rcx*8]
    test rdx,rdx
    jnz .bounds
    cmp rax,NEBO_G097_MAX_ELEMENTS
    ja .bounds
    inc rcx
    jmp .shape_loop
.shape_product_ready:
    mov r14,[r12+NEBO_G097_REQUEST_ELEMENTS_OFFSET]
    test r14,r14
    jz .bounds
    cmp r14,NEBO_G097_MAX_ELEMENTS
    ja .bounds
    cmp rax,r14
    jne .shape
    mov r8,[r12+NEBO_G097_REQUEST_DATA_PTR_OFFSET]
    test r8,r8
    jz .invalid
    test r8,7
    jnz .invalid

    mov r11,[r12+NEBO_G097_REQUEST_OPTIONS_OFFSET]
    mov rax,r11
    and rax,~NEBO_G097_OPTION_KNOWN
    jnz .options
    cmp ebx,NEBO_G097_KIND_MATRIX
    jne .kind_tensor
    test r11,NEBO_G097_OPTION_MATRIX
    jz .options
    mov rax,r11
    and rax,~(NEBO_G097_OPTION_MATRIX | NEBO_G097_OPTION_SHAPE_INSPECTOR)
    jnz .options
    jmp .kind_options_ready
.kind_tensor:
    cmp ebx,NEBO_G097_KIND_TENSOR
    jne .kind_volume
    mov rax,r11
    and rax,NEBO_G097_OPTION_TENSOR | NEBO_G097_OPTION_TENSOR_SLICE
    jz .options
    mov rax,r11
    and rax,~(NEBO_G097_OPTION_TENSOR | NEBO_G097_OPTION_SHAPE_INSPECTOR | NEBO_G097_OPTION_TENSOR_SLICE | NEBO_G097_OPTION_SLICE | NEBO_G097_OPTION_INDEX)
    jnz .options
    jmp .kind_options_ready
.kind_volume:
    cmp ebx,NEBO_G097_KIND_VOLUME
    jne .kind_compare
    test r11,NEBO_G097_OPTION_VOLUME
    jz .options
    mov rax,r11
    and rax,~(NEBO_G097_OPTION_VOLUME | NEBO_G097_OPTION_SLICE | NEBO_G097_OPTION_INDEX | NEBO_G097_OPTION_ISOSURFACE | NEBO_G097_OPTION_THRESHOLD)
    jnz .options
    jmp .kind_options_ready
.kind_compare:
    mov rax,r11
    and rax,NEBO_G097_OPTION_COMPARE | NEBO_G097_OPTION_WITH
    cmp rax,NEBO_G097_OPTION_COMPARE | NEBO_G097_OPTION_WITH
    jne .options
    mov rax,r11
    and rax,~(NEBO_G097_OPTION_TENSOR | NEBO_G097_OPTION_SHAPE_INSPECTOR | NEBO_G097_OPTION_COMPARE | NEBO_G097_OPTION_WITH)
    jnz .options
.kind_options_ready:
    mov rax,r11
    and rax,NEBO_G097_OPTION_ISOSURFACE | NEBO_G097_OPTION_THRESHOLD
    test rax,rax
    jz .isosurface_pair_ready
    cmp rax,NEBO_G097_OPTION_ISOSURFACE | NEBO_G097_OPTION_THRESHOLD
    jne .options
    cmp ebx,NEBO_G097_KIND_VOLUME
    jne .options
.isosurface_pair_ready:
    test r11,NEBO_G097_OPTION_TENSOR_SLICE
    jz .tensor_slice_ready
    mov rax,r11
    and rax,NEBO_G097_OPTION_SLICE | NEBO_G097_OPTION_INDEX
    cmp rax,NEBO_G097_OPTION_SLICE | NEBO_G097_OPTION_INDEX
    jne .options
.tensor_slice_ready:
    test r11,NEBO_G097_OPTION_SLICE
    jz .no_slice
    test r11,NEBO_G097_OPTION_INDEX
    jz .options
    cmp ebx,NEBO_G097_KIND_TENSOR
    je .slice_kind_ready
    cmp ebx,NEBO_G097_KIND_VOLUME
    jne .options
.slice_kind_ready:
    mov rax,[r12+NEBO_G097_REQUEST_AXIS_OFFSET]
    cmp rax,r10
    jae .axis
    mov rdx,[r12+NEBO_G097_REQUEST_INDEX_OFFSET]
    cmp rdx,[r9+rax*8]
    jae .axis
    jmp .slice_ready
.no_slice:
    cmp qword [r12+NEBO_G097_REQUEST_AXIS_OFFSET],0
    jne .axis
    cmp qword [r12+NEBO_G097_REQUEST_INDEX_OFFSET],0
    jne .axis
.slice_ready:
    mov rax,[r12+NEBO_G097_REQUEST_SAMPLE_BUDGET_OFFSET]
    test rax,rax
    jz .bounds
    cmp rax,NEBO_G097_MAX_SAMPLES
    ja .bounds
    cmp rax,r14
    jbe .samples_ready
    mov rax,r14
.samples_ready:
    mov [rbp-168+NEBO_G097_RESULT_SAMPLES_OFFSET],rax
    mov rax,[r12+NEBO_G097_REQUEST_COLORMAP_OFFSET]
    cmp rax,1
    jb .options
    cmp rax,8
    ja .options
    mov rax,[r12+NEBO_G097_REQUEST_QUALITY_OFFSET]
    cmp rax,1
    jb .options
    cmp rax,3
    ja .options
    mov rax,[r12+NEBO_G097_REQUEST_OWNER_GENERATION_OFFSET]
    test rax,rax
    jz .lifetime
    cmp rax,[r12+NEBO_G097_REQUEST_VIEW_GENERATION_OFFSET]
    jne .lifetime

    cmp ebx,NEBO_G097_KIND_COMPARE
    jne .not_compare
    mov rax,[r12+NEBO_G097_REQUEST_METRIC_OFFSET]
    cmp rax,NEBO_G097_METRIC_ABSOLUTE
    jb .metric
    cmp rax,NEBO_G097_METRIC_RMS
    ja .metric
    mov rdx,[r12+NEBO_G097_REQUEST_PEER_SHAPE_PTR_OFFSET]
    test rdx,rdx
    jz .compare
    test rdx,7
    jnz .compare
    mov rdi,[r12+NEBO_G097_REQUEST_PEER_DATA_PTR_OFFSET]
    test rdi,rdi
    jz .compare
    test rdi,7
    jnz .compare
    xor ecx,ecx
.peer_shape_loop:
    cmp rcx,r10
    jae .peer_shape_ready
    mov rax,[r9+rcx*8]
    cmp rax,[rdx+rcx*8]
    jne .compare
    inc rcx
    jmp .peer_shape_loop
.peer_shape_ready:
    mov rax,[r12+NEBO_G097_REQUEST_PROVENANCE_LEFT_OFFSET]
    test rax,rax
    jz .provenance
    mov rcx,[r12+NEBO_G097_REQUEST_PROVENANCE_RIGHT_OFFSET]
    test rcx,rcx
    jz .provenance
    cmp rax,rcx
    je .provenance
    jmp .compare_ready
.not_compare:
    cmp qword [r12+NEBO_G097_REQUEST_METRIC_OFFSET],0
    jne .metric
    cmp qword [r12+NEBO_G097_REQUEST_PEER_SHAPE_PTR_OFFSET],0
    jne .compare
    cmp qword [r12+NEBO_G097_REQUEST_PEER_DATA_PTR_OFFSET],0
    jne .compare
    cmp qword [r12+NEBO_G097_REQUEST_PROVENANCE_RIGHT_OFFSET],0
    jne .provenance
    cmp qword [r12+NEBO_G097_REQUEST_PROVENANCE_LEFT_OFFSET],0
    je .provenance
.compare_ready:
    test r11,NEBO_G097_OPTION_ISOSURFACE
    jz .no_threshold
    mov rax,[r12+NEBO_G097_REQUEST_THRESHOLD_OFFSET]
    test rax,rax
    jz .threshold
    mov rdx,rax
    shr rdx,52
    and edx,0x7ff
    cmp edx,0x7ff
    je .nonfinite
    jmp .threshold_ready
.no_threshold:
    cmp qword [r12+NEBO_G097_REQUEST_THRESHOLD_OFFSET],0
    jne .threshold
.threshold_ready:

    mov r15,0xcbf29ce484222325
    mov eax,ebx
    xor r15,rax
    rol r15,11
    xor r15,r10
    rol r15,13
    xor r15,r14
    rol r15,17
    xor r15,[r12+NEBO_G097_REQUEST_AXIS_OFFSET]
    rol r15,19
    xor r15,[r12+NEBO_G097_REQUEST_INDEX_OFFSET]
    rol r15,23
    xor r15,[r12+NEBO_G097_REQUEST_SAMPLE_BUDGET_OFFSET]
    rol r15,29
    xor r15,[r12+NEBO_G097_REQUEST_METRIC_OFFSET]
    rol r15,31
    xor r15,[r12+NEBO_G097_REQUEST_COLORMAP_OFFSET]
    rol r15,7
    xor r15,[r12+NEBO_G097_REQUEST_QUALITY_OFFSET]
    rol r15,9
    xor r15,r11
    rol r15,15
    xor r15,[r12+NEBO_G097_REQUEST_THRESHOLD_OFFSET]
    rol r15,21
    xor r15,[r12+NEBO_G097_REQUEST_PROVENANCE_LEFT_OFFSET]
    rol r15,27
    xor r15,[r12+NEBO_G097_REQUEST_PROVENANCE_RIGHT_OFFSET]
    rol r15,33
    xor r15,[r12+NEBO_G097_REQUEST_OWNER_GENERATION_OFFSET]
    xor ecx,ecx
.shape_digest_loop:
    cmp rcx,r10
    jae .data_digest_start
    xor r15,[r9+rcx*8]
    rol r15,5
    inc rcx
    jmp .shape_digest_loop
.data_digest_start:
    mov qword [rbp-168+NEBO_G097_RESULT_SELECTED_OFFSET],0
    mov qword [rbp-168+NEBO_G097_RESULT_COMPARISON_OFFSET],0
    mov r8,[r12+NEBO_G097_REQUEST_DATA_PTR_OFFSET]
    xor ecx,ecx
.data_digest_loop:
    cmp rcx,r14
    jae .peer_digest_start
    mov rdx,[r8+rcx*8]
    mov rax,rdx
    shr rax,52
    and eax,0x7ff
    cmp eax,0x7ff
    je .nonfinite
    xor r15,rdx
    rol r15,11
    test r11,NEBO_G097_OPTION_ISOSURFACE
    jz .data_next
    movq xmm0,rdx
    mov rax,[r12+NEBO_G097_REQUEST_THRESHOLD_OFFSET]
    movq xmm1,rax
    ucomisd xmm0,xmm1
    jb .data_next
    inc qword [rbp-168+NEBO_G097_RESULT_SELECTED_OFFSET]
.data_next:
    inc rcx
    jmp .data_digest_loop
.peer_digest_start:
    cmp ebx,NEBO_G097_KIND_COMPARE
    jne .digest_ready
    mov r8,[r12+NEBO_G097_REQUEST_PEER_DATA_PTR_OFFSET]
    mov rdi,[r12+NEBO_G097_REQUEST_DATA_PTR_OFFSET]
    pxor xmm2,xmm2
    pxor xmm3,xmm3
    pxor xmm4,xmm4
    xor ecx,ecx
.peer_digest_loop:
    cmp rcx,r14
    jae .digest_ready
    mov rdx,[r8+rcx*8]
    mov rax,rdx
    shr rax,52
    and eax,0x7ff
    cmp eax,0x7ff
    je .nonfinite
    xor r15,rdx
    rol r15,17
    movsd xmm0,[r8+rcx*8]
    movsd xmm1,[rdi+rcx*8]
    subsd xmm0,xmm1
    andpd xmm0,[rel g97_abs_mask]
    addsd xmm2,xmm0
    mulsd xmm0,xmm0
    addsd xmm3,xmm0
    andpd xmm1,[rel g97_abs_mask]
    addsd xmm4,xmm1
    inc rcx
    jmp .peer_digest_loop
.digest_ready:
    cmp ebx,NEBO_G097_KIND_COMPARE
    jne .comparison_ready
    cvtsi2sd xmm5,r14
    mov rax,[r12+NEBO_G097_REQUEST_METRIC_OFFSET]
    cmp rax,NEBO_G097_METRIC_ABSOLUTE
    jne .relative_metric
    divsd xmm2,xmm5
    movsd [rbp-168+NEBO_G097_RESULT_COMPARISON_OFFSET],xmm2
    jmp .comparison_ready
.relative_metric:
    cmp rax,NEBO_G097_METRIC_RELATIVE
    jne .rms_metric
    pxor xmm0,xmm0
    ucomisd xmm4,xmm0
    je .metric
    divsd xmm2,xmm4
    movsd [rbp-168+NEBO_G097_RESULT_COMPARISON_OFFSET],xmm2
    jmp .comparison_ready
.rms_metric:
    divsd xmm3,xmm5
    sqrtsd xmm3,xmm3
    movsd [rbp-168+NEBO_G097_RESULT_COMPARISON_OFFSET],xmm3
.comparison_ready:
    test r11,NEBO_G097_OPTION_ISOSURFACE
    jz .publish
    cmp qword [rbp-168+NEBO_G097_RESULT_SELECTED_OFFSET],0
    je .threshold

.publish:
    mov dword [rbp-168+NEBO_G097_RESULT_KIND_OFFSET],ebx
    mov eax,[r12+NEBO_G097_REQUEST_TARGET_OFFSET]
    mov dword [rbp-168+NEBO_G097_RESULT_TARGET_OFFSET],eax
    mov rax,[r12+NEBO_G097_REQUEST_RANK_OFFSET]
    mov [rbp-168+NEBO_G097_RESULT_RANK_OFFSET],rax
    mov [rbp-168+NEBO_G097_RESULT_ELEMENTS_OFFSET],r14
    mov rax,[r12+NEBO_G097_REQUEST_AXIS_OFFSET]
    mov [rbp-168+NEBO_G097_RESULT_AXIS_OFFSET],rax
    mov rax,[r12+NEBO_G097_REQUEST_INDEX_OFFSET]
    mov [rbp-168+NEBO_G097_RESULT_INDEX_OFFSET],rax
    mov rax,[r12+NEBO_G097_REQUEST_METRIC_OFFSET]
    mov [rbp-168+NEBO_G097_RESULT_METRIC_OFFSET],rax
    mov rax,[r12+NEBO_G097_REQUEST_COLORMAP_OFFSET]
    mov [rbp-168+NEBO_G097_RESULT_COLORMAP_OFFSET],rax
    mov rax,[r12+NEBO_G097_REQUEST_QUALITY_OFFSET]
    mov [rbp-168+NEBO_G097_RESULT_QUALITY_OFFSET],rax
    mov [rbp-168+NEBO_G097_RESULT_OPTIONS_OFFSET],r11
    mov rax,[rbp-168+NEBO_G097_RESULT_COMPARISON_OFFSET]
    xor r15,rax
    rol r15,37
    mov [rbp-168+NEBO_G097_RESULT_DIGEST_OFFSET],r15
    mov rax,[r12+NEBO_G097_REQUEST_OWNER_GENERATION_OFFSET]
    mov [rbp-168+NEBO_G097_RESULT_OWNER_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G097_REQUEST_VIEW_GENERATION_OFFSET]
    mov [rbp-168+NEBO_G097_RESULT_VIEW_GENERATION_OFFSET],rax
    lea rsi,[rbp-168]
    mov rdi,r13
    mov ecx,NEBO_G097_RESULT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done
.invalid:
    mov eax,NEBO_G097_ERROR_INVALID
    jmp .done
.bounds:
    mov eax,NEBO_G097_ERROR_BOUNDS
    jmp .done
.kind:
    mov eax,NEBO_G097_ERROR_KIND
    jmp .done
.shape:
    mov eax,NEBO_G097_ERROR_SHAPE
    jmp .done
.axis:
    mov eax,NEBO_G097_ERROR_AXIS
    jmp .done
.nonfinite:
    mov eax,NEBO_G097_ERROR_NONFINITE
    jmp .done
.lifetime:
    mov eax,NEBO_G097_ERROR_LIFETIME
    jmp .done
.options:
    mov eax,NEBO_G097_ERROR_OPTIONS
    jmp .done
.target:
    mov eax,NEBO_G097_ERROR_TARGET
    jmp .done
.compare:
    mov eax,NEBO_G097_ERROR_COMPARE
    jmp .done
.threshold:
    mov eax,NEBO_G097_ERROR_THRESHOLD
    jmp .done
.metric:
    mov eax,NEBO_G097_ERROR_METRIC
    jmp .done
.provenance:
    mov eax,NEBO_G097_ERROR_PROVENANCE
.done:
    add rsp,128
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
