; G097 source-to-effect probe over the target-neutral scientific-view model.
bits 64
default rel
%define NEBO_G097_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/scientific_view_source_probe.inc"
%include "runtime/console/scientific_view.inc"

global nebo_g097_source_probe
global nebo_g097_negative_probe

section .bss align=16
g97_request: resb NEBO_G097_REQUEST_SIZE
g97_headless: resb NEBO_G097_RESULT_SIZE
g97_live: resb NEBO_G097_RESULT_SIZE
g97_shape: resq NEBO_G097_MAX_RANK
g97_peer_shape: resq NEBO_G097_MAX_RANK
g97_data: resq 256
g97_peer_data: resq 256

section .text
g97_clear:
    lea rdi,[rel g97_request]
    mov ecx,NEBO_G097_REQUEST_SIZE/8
    xor eax,eax
    cld
    rep stosq
    lea rdi,[rel g97_headless]
    mov ecx,NEBO_G097_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g97_live]
    mov ecx,NEBO_G097_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g97_shape]
    mov ecx,NEBO_G097_MAX_RANK*2
    rep stosq
    ret

; EDI=subgroup 1..10, ESI=source generation 1..255 -> EAX=generation.
nebo_g097_source_probe:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12d,edi
    mov r13d,esi
    cmp r12d,1
    jb .failure
    cmp r12d,10
    ja .failure
    test r13d,r13d
    jz .failure
    cmp r13d,255
    ja .failure
    call g97_clear

    lea rbx,[rel g97_shape]
    mov qword [rbx],2
    mov qword [rbx+8],3
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],2
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_MATRIX
    mov r14,NEBO_G097_OPTION_MATRIX
    cmp r12d,1
    je .shape_ready
    cmp r12d,2
    je .tensor_shape
    cmp r12d,3
    je .tensor_slice
    cmp r12d,4
    je .volume_slice
    cmp r12d,5
    je .volume_isosurface
    cmp r12d,6
    je .compare_matrix
    cmp r12d,7
    je .color_quality
    cmp r12d,8
    je .bounded_tensor
    cmp r12d,9
    je .compare_tensor
    jmp .closeout
.tensor_shape:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_TENSOR
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],3
    mov qword [rbx],2
    mov qword [rbx+8],3
    mov eax,r13d
    xor edx,edx
    mov ecx,5
    div ecx
    add edx,2
    mov [rbx+16],rdx
    mov r14,NEBO_G097_OPTION_TENSOR | NEBO_G097_OPTION_SHAPE_INSPECTOR
    jmp .shape_ready
.tensor_slice:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_TENSOR
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],3
    mov qword [rbx],2
    mov qword [rbx+8],3
    mov qword [rbx+16],4
    mov r14,NEBO_G097_OPTION_TENSOR_SLICE | NEBO_G097_OPTION_SLICE | NEBO_G097_OPTION_INDEX
    jmp .slice_axis
.volume_slice:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_VOLUME
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],3
    mov qword [rbx],3
    mov qword [rbx+8],3
    mov eax,r13d
    xor edx,edx
    mov ecx,4
    div ecx
    add edx,2
    mov [rbx+16],rdx
    mov r14,NEBO_G097_OPTION_VOLUME | NEBO_G097_OPTION_SLICE | NEBO_G097_OPTION_INDEX
    mov qword [rel g97_request+NEBO_G097_REQUEST_AXIS_OFFSET],2
    mov eax,r13d
    xor edx,edx
    div qword [rbx+16]
    mov [rel g97_request+NEBO_G097_REQUEST_INDEX_OFFSET],rdx
    jmp .shape_ready
.volume_isosurface:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_VOLUME
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],3
    mov qword [rbx],3
    mov qword [rbx+8],3
    mov qword [rbx+16],3
    mov r14,NEBO_G097_OPTION_VOLUME | NEBO_G097_OPTION_ISOSURFACE | NEBO_G097_OPTION_THRESHOLD
    mov eax,r13d
    inc eax
    cvtsi2sd xmm0,eax
    movq rax,xmm0
    mov [rel g97_request+NEBO_G097_REQUEST_THRESHOLD_OFFSET],rax
    jmp .shape_ready
.compare_matrix:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_COMPARE
    mov r14,NEBO_G097_OPTION_COMPARE | NEBO_G097_OPTION_WITH
    jmp .compare_fields
.color_quality:
    mov r14,NEBO_G097_OPTION_MATRIX | NEBO_G097_OPTION_SHAPE_INSPECTOR
    jmp .shape_ready
.bounded_tensor:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_TENSOR
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],3
    mov qword [rbx],4
    mov qword [rbx+8],4
    mov eax,r13d
    xor edx,edx
    mov ecx,4
    div ecx
    add edx,2
    mov [rbx+16],rdx
    mov r14,NEBO_G097_OPTION_TENSOR | NEBO_G097_OPTION_SLICE | NEBO_G097_OPTION_INDEX
    mov qword [rel g97_request+NEBO_G097_REQUEST_AXIS_OFFSET],1
    mov eax,r13d
    xor edx,edx
    mov ecx,4
    div ecx
    mov [rel g97_request+NEBO_G097_REQUEST_INDEX_OFFSET],rdx
    jmp .shape_ready
.compare_tensor:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_COMPARE
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],3
    mov qword [rbx],2
    mov qword [rbx+8],2
    mov qword [rbx+16],3
    mov r14,NEBO_G097_OPTION_COMPARE | NEBO_G097_OPTION_WITH
    jmp .compare_fields
.closeout:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_COMPARE
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],3
    mov qword [rbx],2
    mov qword [rbx+8],3
    mov qword [rbx+16],2
    mov r14,NEBO_G097_OPTION_TENSOR | NEBO_G097_OPTION_SHAPE_INSPECTOR | NEBO_G097_OPTION_COMPARE | NEBO_G097_OPTION_WITH
.compare_fields:
    mov eax,r13d
    xor edx,edx
    mov ecx,3
    div ecx
    inc edx
    mov [rel g97_request+NEBO_G097_REQUEST_METRIC_OFFSET],rdx
    lea rax,[rel g97_peer_shape]
    mov [rel g97_request+NEBO_G097_REQUEST_PEER_SHAPE_PTR_OFFSET],rax
    lea rax,[rel g97_peer_data]
    mov [rel g97_request+NEBO_G097_REQUEST_PEER_DATA_PTR_OFFSET],rax
    mov eax,r13d
    add eax,200
    mov [rel g97_request+NEBO_G097_REQUEST_PROVENANCE_RIGHT_OFFSET],rax
    jmp .shape_ready
.slice_axis:
    mov eax,r13d
    xor edx,edx
    mov ecx,3
    div ecx
    mov [rel g97_request+NEBO_G097_REQUEST_AXIS_OFFSET],rdx
    mov rax,[rbx+rdx*8]
    mov rcx,rax
    mov eax,r13d
    xor edx,edx
    div rcx
    mov [rel g97_request+NEBO_G097_REQUEST_INDEX_OFFSET],rdx

.shape_ready:
    mov r10,[rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET]
    lea rdi,[rel g97_peer_shape]
    xor ecx,ecx
    mov r15,1
.element_product:
    cmp rcx,r10
    jae .element_product_ready
    imul r15,qword [rbx+rcx*8]
    mov rax,[rbx+rcx*8]
    mov [rdi+rcx*8],rax
    inc rcx
    jmp .element_product
.element_product_ready:
    mov [rel g97_request+NEBO_G097_REQUEST_ELEMENTS_OFFSET],r15
    mov [rel g97_request+NEBO_G097_REQUEST_OPTIONS_OFFSET],r14
    lea rax,[rel g97_shape]
    mov [rel g97_request+NEBO_G097_REQUEST_SHAPE_PTR_OFFSET],rax
    lea rax,[rel g97_data]
    mov [rel g97_request+NEBO_G097_REQUEST_DATA_PTR_OFFSET],rax
    mov eax,r13d
    add eax,100
    mov [rel g97_request+NEBO_G097_REQUEST_PROVENANCE_LEFT_OFFSET],rax
    mov [rel g97_request+NEBO_G097_REQUEST_OWNER_GENERATION_OFFSET],r13
    mov [rel g97_request+NEBO_G097_REQUEST_VIEW_GENERATION_OFFSET],r13
    mov eax,r13d
    xor edx,edx
    mov ecx,8
    div ecx
    inc edx
    mov [rel g97_request+NEBO_G097_REQUEST_COLORMAP_OFFSET],rdx
    mov eax,r13d
    xor edx,edx
    mov ecx,3
    div ecx
    inc edx
    mov [rel g97_request+NEBO_G097_REQUEST_QUALITY_OFFSET],rdx
    mov rax,r15
    cmp r12d,8
    jne .sample_budget_ready
    shr rax,1
    test rax,rax
    jnz .sample_budget_ready
    inc rax
.sample_budget_ready:
    mov [rel g97_request+NEBO_G097_REQUEST_SAMPLE_BUDGET_OFFSET],rax

    xor ecx,ecx
    lea r8,[rel g97_data]
    lea r9,[rel g97_peer_data]
.fill_data:
    cmp rcx,r15
    jae .run
    mov eax,r13d
    add rax,rcx
    inc rax
    cvtsi2sd xmm0,rax
    movsd [r8+rcx*8],xmm0
    inc rax
    cvtsi2sd xmm0,rax
    movsd [r9+rcx*8],xmm0
    inc rcx
    jmp .fill_data

.run:
    mov dword [rel g97_request+NEBO_G097_REQUEST_TARGET_OFFSET],NEBO_G097_TARGET_HEADLESS
    lea rdi,[rel g97_request]
    lea rsi,[rel g97_headless]
    call nebo_g097_scientific_view_model
    test eax,eax
    jnz .failure
    mov dword [rel g97_request+NEBO_G097_REQUEST_TARGET_OFFSET],NEBO_G097_TARGET_LIVE
    lea rdi,[rel g97_request]
    lea rsi,[rel g97_live]
    call nebo_g097_scientific_view_model
    test eax,eax
    jnz .failure
%macro G97_COMPARE_QWORD 1
    mov rax,[rel g97_headless+%1]
    cmp rax,[rel g97_live+%1]
    jne .failure
%endmacro
    G97_COMPARE_QWORD NEBO_G097_RESULT_RANK_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_ELEMENTS_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_AXIS_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_INDEX_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_SAMPLES_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_METRIC_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_COLORMAP_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_QUALITY_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_OPTIONS_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_DIGEST_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_OWNER_GENERATION_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_VIEW_GENERATION_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_SELECTED_OFFSET
    G97_COMPARE_QWORD NEBO_G097_RESULT_COMPARISON_OFFSET
%undef G97_COMPARE_QWORD
    mov eax,[rel g97_headless+NEBO_G097_RESULT_KIND_OFFSET]
    cmp eax,[rel g97_live+NEBO_G097_RESULT_KIND_OFFSET]
    jne .failure
    mov eax,[rel g97_headless+NEBO_G097_RESULT_VIEW_GENERATION_OFFSET]
    cmp eax,r13d
    jne .failure
    jmp .done
.failure:
    mov eax,-1
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=case 1..15 -> EAX=stable model error and sentinel-preserving failure.
nebo_g097_negative_probe:
    push rbx
    push r12
    mov r12d,edi
    call g97_clear
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_COMPARE
    mov dword [rel g97_request+NEBO_G097_REQUEST_TARGET_OFFSET],NEBO_G097_TARGET_HEADLESS
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],2
    mov qword [rel g97_request+NEBO_G097_REQUEST_ELEMENTS_OFFSET],4
    mov qword [rel g97_request+NEBO_G097_REQUEST_SAMPLE_BUDGET_OFFSET],4
    mov qword [rel g97_request+NEBO_G097_REQUEST_METRIC_OFFSET],NEBO_G097_METRIC_ABSOLUTE
    mov qword [rel g97_request+NEBO_G097_REQUEST_COLORMAP_OFFSET],1
    mov qword [rel g97_request+NEBO_G097_REQUEST_QUALITY_OFFSET],2
    mov qword [rel g97_request+NEBO_G097_REQUEST_OPTIONS_OFFSET],NEBO_G097_OPTION_COMPARE | NEBO_G097_OPTION_WITH
    mov qword [rel g97_shape],2
    mov qword [rel g97_shape+8],2
    mov qword [rel g97_peer_shape],2
    mov qword [rel g97_peer_shape+8],2
    lea rax,[rel g97_shape]
    mov [rel g97_request+NEBO_G097_REQUEST_SHAPE_PTR_OFFSET],rax
    lea rax,[rel g97_peer_shape]
    mov [rel g97_request+NEBO_G097_REQUEST_PEER_SHAPE_PTR_OFFSET],rax
    lea rax,[rel g97_data]
    mov [rel g97_request+NEBO_G097_REQUEST_DATA_PTR_OFFSET],rax
    lea rax,[rel g97_peer_data]
    mov [rel g97_request+NEBO_G097_REQUEST_PEER_DATA_PTR_OFFSET],rax
    mov qword [rel g97_request+NEBO_G097_REQUEST_PROVENANCE_LEFT_OFFSET],101
    mov qword [rel g97_request+NEBO_G097_REQUEST_PROVENANCE_RIGHT_OFFSET],202
    mov qword [rel g97_request+NEBO_G097_REQUEST_OWNER_GENERATION_OFFSET],7
    mov qword [rel g97_request+NEBO_G097_REQUEST_VIEW_GENERATION_OFFSET],7
    lea rdi,[rel g97_data]
    mov ecx,8
    mov rax,0x3ff0000000000000
    cld
    rep stosq
    mov rax,0x6a6a6a6a6a6a6a6a
    mov [rel g97_headless],rax
    cmp r12d,1
    je .bad_kind
    cmp r12d,2
    je .bad_target
    cmp r12d,3
    je .bad_rank
    cmp r12d,4
    je .bad_elements
    cmp r12d,5
    je .zero_dimension
    cmp r12d,6
    je .bad_budget
    cmp r12d,7
    je .bad_axis
    cmp r12d,8
    je .bad_index
    cmp r12d,9
    je .nan_data
    cmp r12d,10
    je .stale_view
    cmp r12d,11
    je .unknown_options
    cmp r12d,12
    je .peer_shape
    cmp r12d,13
    je .unexpected_threshold
    cmp r12d,14
    je .bad_metric
    cmp r12d,15
    je .same_provenance
    mov eax,-1
    jmp .negative_done
.bad_kind:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],0
    jmp .negative_run
.bad_target:
    mov dword [rel g97_request+NEBO_G097_REQUEST_TARGET_OFFSET],0
    jmp .negative_run
.bad_rank:
    mov qword [rel g97_request+NEBO_G097_REQUEST_RANK_OFFSET],1
    jmp .negative_run
.bad_elements:
    mov qword [rel g97_request+NEBO_G097_REQUEST_ELEMENTS_OFFSET],5
    jmp .negative_run
.zero_dimension:
    mov qword [rel g97_shape],0
    jmp .negative_run
.bad_budget:
    mov qword [rel g97_request+NEBO_G097_REQUEST_SAMPLE_BUDGET_OFFSET],NEBO_G097_MAX_SAMPLES+1
    jmp .negative_run
.bad_axis:
    call g97_negative_tensor_slice
    mov qword [rel g97_request+NEBO_G097_REQUEST_AXIS_OFFSET],2
    jmp .negative_run
.bad_index:
    call g97_negative_tensor_slice
    mov qword [rel g97_request+NEBO_G097_REQUEST_INDEX_OFFSET],2
    jmp .negative_run
.nan_data:
    mov rax,0x7ff8000000000001
    mov [rel g97_data],rax
    jmp .negative_run
.stale_view:
    mov qword [rel g97_request+NEBO_G097_REQUEST_VIEW_GENERATION_OFFSET],8
    jmp .negative_run
.unknown_options:
    or qword [rel g97_request+NEBO_G097_REQUEST_OPTIONS_OFFSET],0x800
    jmp .negative_run
.peer_shape:
    mov qword [rel g97_peer_shape+8],3
    jmp .negative_run
.unexpected_threshold:
    mov rax,0x3ff0000000000000
    mov [rel g97_request+NEBO_G097_REQUEST_THRESHOLD_OFFSET],rax
    jmp .negative_run
.bad_metric:
    mov qword [rel g97_request+NEBO_G097_REQUEST_METRIC_OFFSET],4
    jmp .negative_run
.same_provenance:
    mov qword [rel g97_request+NEBO_G097_REQUEST_PROVENANCE_RIGHT_OFFSET],101
.negative_run:
    lea rdi,[rel g97_request]
    lea rsi,[rel g97_headless]
    call nebo_g097_scientific_view_model
    mov ebx,eax
    mov rax,0x6a6a6a6a6a6a6a6a
    cmp [rel g97_headless],rax
    jne .atomicity_failed
    mov eax,ebx
    jmp .negative_done
.atomicity_failed:
    mov eax,-1
.negative_done:
    pop r12
    pop rbx
    ret

g97_negative_tensor_slice:
    mov dword [rel g97_request+NEBO_G097_REQUEST_KIND_OFFSET],NEBO_G097_KIND_TENSOR
    mov qword [rel g97_request+NEBO_G097_REQUEST_METRIC_OFFSET],0
    mov qword [rel g97_request+NEBO_G097_REQUEST_OPTIONS_OFFSET],NEBO_G097_OPTION_TENSOR | NEBO_G097_OPTION_SLICE | NEBO_G097_OPTION_INDEX
    mov qword [rel g97_request+NEBO_G097_REQUEST_PEER_SHAPE_PTR_OFFSET],0
    mov qword [rel g97_request+NEBO_G097_REQUEST_PEER_DATA_PTR_OFFSET],0
    mov qword [rel g97_request+NEBO_G097_REQUEST_PROVENANCE_RIGHT_OFFSET],0
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
