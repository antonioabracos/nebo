; G096 target-neutral Plot3D/Scene3D schema, bounds and parity owner.
bits 64
default rel
%define NEBO_G096_SCENE_MODEL_IMPLEMENTATION 1
%include "runtime/console/scene_model.inc"

section .text
global nebo_g096_scene_model

; scene_model(request*, result*) -> status. The receipt is published atomically.
nebo_g096_scene_model:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,80
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

    mov ebx,[r12+NEBO_G096_REQUEST_KIND_OFFSET]
    cmp ebx,NEBO_G096_KIND_POINTS
    jb .kind
    cmp ebx,NEBO_G096_KIND_MESH
    ja .kind
    mov eax,[r12+NEBO_G096_REQUEST_TARGET_OFFSET]
    cmp eax,NEBO_G096_TARGET_HEADLESS
    jb .target
    cmp eax,NEBO_G096_TARGET_LIVE
    ja .target
    mov r14,[r12+NEBO_G096_REQUEST_VERTICES_OFFSET]
    test r14,r14
    jz .bounds
    cmp r14,NEBO_G096_MAX_VERTICES
    ja .bounds
    cmp qword [r12+NEBO_G096_REQUEST_COMPONENTS_OFFSET],3
    jne .shape
    mov rax,[r12+NEBO_G096_REQUEST_VERTEX_PTR_OFFSET]
    test rax,rax
    jz .invalid
    test rax,7
    jnz .invalid
    cmp qword [r12+NEBO_G096_REQUEST_GENERATION_OFFSET],0
    je .invalid
    cmp ebx,NEBO_G096_KIND_LINE
    jne .kind_extent_ready
    cmp r14,2
    jb .shape
.kind_extent_ready:
    mov rax,[r12+NEBO_G096_REQUEST_OPTIONS_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_G096_OPTION_KNOWN
    jnz .options
    mov rcx,rax
    and rcx,NEBO_G096_OPTION_REQUIRED
    cmp rcx,NEBO_G096_OPTION_REQUIRED
    jne .options
    mov r15,[r12+NEBO_G096_REQUEST_CAMERA_MODE_OFFSET]
    cmp r15,NEBO_G096_CAMERA_ORBIT
    je .orbit
    cmp r15,NEBO_G096_CAMERA_FREE
    jne .camera
    test rax,NEBO_G096_OPTION_FREE
    jz .camera
    test rax,NEBO_G096_OPTION_ORBIT
    jnz .camera
    jmp .camera_ready
.orbit:
    test rax,NEBO_G096_OPTION_ORBIT
    jz .camera
    test rax,NEBO_G096_OPTION_FREE
    jnz .camera
.camera_ready:
    mov rax,[r12+NEBO_G096_REQUEST_POSITION_PTR_OFFSET]
    test rax,rax
    jz .camera
    test rax,7
    jnz .camera
    mov rdx,[r12+NEBO_G096_REQUEST_LOOK_AT_PTR_OFFSET]
    test rdx,rdx
    jz .camera
    test rdx,7
    jnz .camera
    xor r11d,r11d
    xor ecx,ecx
.camera_vector:
    mov r8,[rax+rcx*8]
    mov r9,r8
    shr r9,52
    and r9d,0x7ff
    cmp r9d,0x7ff
    je .nonfinite
    mov r9,[rdx+rcx*8]
    mov r10,r9
    shr r10,52
    and r10d,0x7ff
    cmp r10d,0x7ff
    je .nonfinite
    cmp r8,r9
    je .camera_same
    mov r11d,1
.camera_same:
    inc ecx
    cmp ecx,3
    jb .camera_vector
    test r11d,r11d
    jz .camera

    mov rax,[r12+NEBO_G096_REQUEST_NEAR_OFFSET]
    bt rax,63
    jc .clip
    test rax,rax
    jz .clip
    mov rdx,rax
    shr rdx,52
    and edx,0x7ff
    cmp edx,0x7ff
    je .nonfinite
    mov rcx,[r12+NEBO_G096_REQUEST_FAR_OFFSET]
    bt rcx,63
    jc .clip
    test rcx,rcx
    jz .clip
    mov rdx,rcx
    shr rdx,52
    and edx,0x7ff
    cmp edx,0x7ff
    je .nonfinite
    cmp rax,rcx
    jae .clip
    mov rax,[r12+NEBO_G096_REQUEST_PRECISION_OFFSET]
    cmp rax,16
    je .precision_ready
    cmp rax,24
    je .precision_ready
    cmp rax,32
    jne .clip
.precision_ready:
    mov rax,[r12+NEBO_G096_REQUEST_AMBIENT_OFFSET]
    bt rax,63
    jc .lighting
    mov rdx,rax
    shr rdx,52
    and edx,0x7ff
    cmp edx,0x7ff
    je .nonfinite
    mov rdx,0x3ff0000000000000
    cmp rax,rdx
    ja .lighting
    mov rax,[r12+NEBO_G096_REQUEST_LIGHT_COUNT_OFFSET]
    cmp rax,1
    jb .lighting
    cmp rax,NEBO_G096_MAX_LIGHTS
    ja .lighting

    mov r10,[r12+NEBO_G096_REQUEST_INDICES_OFFSET]
    cmp ebx,NEBO_G096_KIND_SURFACE
    jb .no_indices
    cmp r10,3
    jb .shape
    cmp r10,NEBO_G096_MAX_INDICES
    ja .bounds
    mov rax,r10
    xor edx,edx
    mov ecx,3
    div rcx
    test rdx,rdx
    jnz .shape
    mov r9,[r12+NEBO_G096_REQUEST_INDEX_PTR_OFFSET]
    test r9,r9
    jz .invalid
    test r9,7
    jnz .invalid
    xor ecx,ecx
.index_loop:
    cmp rcx,r10
    jae .indices_ready
    cmp qword [r9+rcx*8],r14
    jae .index
    inc rcx
    jmp .index_loop
.no_indices:
    test r10,r10
    jnz .shape
.indices_ready:
    mov r15,0xcbf29ce484222325
    mov eax,ebx
    xor r15,rax
    rol r15,13
    xor r15,r14
    rol r15,17
    xor r15,r10
    rol r15,19
    xor r15,[r12+NEBO_G096_REQUEST_OPTIONS_OFFSET]
    rol r15,23
    xor r15,[r12+NEBO_G096_REQUEST_CAMERA_MODE_OFFSET]
    rol r15,29
    xor r15,[r12+NEBO_G096_REQUEST_NEAR_OFFSET]
    rol r15,31
    xor r15,[r12+NEBO_G096_REQUEST_FAR_OFFSET]
    rol r15,7
    xor r15,[r12+NEBO_G096_REQUEST_AMBIENT_OFFSET]
    mov r8,[r12+NEBO_G096_REQUEST_POSITION_PTR_OFFSET]
    mov r9,[r12+NEBO_G096_REQUEST_LOOK_AT_PTR_OFFSET]
    xor ecx,ecx
.camera_digest_loop:
    xor r15,[r8+rcx*8]
    rol r15,9
    xor r15,[r9+rcx*8]
    rol r15,15
    inc rcx
    cmp ecx,3
    jb .camera_digest_loop
    mov rax,r14
    mov ecx,3
    mul rcx
    test rdx,rdx
    jnz .bounds
    mov r10,rax
    mov r9,[r12+NEBO_G096_REQUEST_VERTEX_PTR_OFFSET]
    xor ecx,ecx
.vertex_loop:
    cmp rcx,r10
    jae .digest_indices
    mov rdx,[r9+rcx*8]
    mov rax,rdx
    shr rax,52
    and eax,0x7ff
    cmp eax,0x7ff
    je .nonfinite
    xor r15,rdx
    rol r15,11
    inc rcx
    jmp .vertex_loop
.digest_indices:
    mov r10,[r12+NEBO_G096_REQUEST_INDICES_OFFSET]
    test r10,r10
    jz .publish
    mov r9,[r12+NEBO_G096_REQUEST_INDEX_PTR_OFFSET]
    xor ecx,ecx
.index_digest_loop:
    cmp rcx,r10
    jae .publish
    xor r15,[r9+rcx*8]
    rol r15,5
    inc rcx
    jmp .index_digest_loop

.publish:
    mov dword [rbp-120+NEBO_G096_RESULT_KIND_OFFSET],ebx
    mov eax,[r12+NEBO_G096_REQUEST_TARGET_OFFSET]
    mov dword [rbp-120+NEBO_G096_RESULT_TARGET_OFFSET],eax
    mov rax,[r12+NEBO_G096_REQUEST_VERTICES_OFFSET]
    mov [rbp-120+NEBO_G096_RESULT_VERTICES_OFFSET],rax
    mov rax,[r12+NEBO_G096_REQUEST_INDICES_OFFSET]
    mov [rbp-120+NEBO_G096_RESULT_INDICES_OFFSET],rax
    mov rax,[r12+NEBO_G096_REQUEST_OPTIONS_OFFSET]
    mov [rbp-120+NEBO_G096_RESULT_OPTIONS_OFFSET],rax
    mov rax,[r12+NEBO_G096_REQUEST_CAMERA_MODE_OFFSET]
    mov [rbp-120+NEBO_G096_RESULT_CAMERA_MODE_OFFSET],rax
    mov rax,[r12+NEBO_G096_REQUEST_LIGHT_COUNT_OFFSET]
    mov [rbp-120+NEBO_G096_RESULT_LIGHT_COUNT_OFFSET],rax
    mov rax,[r12+NEBO_G096_REQUEST_PRECISION_OFFSET]
    mov [rbp-120+NEBO_G096_RESULT_PRECISION_OFFSET],rax
    mov [rbp-120+NEBO_G096_RESULT_DIGEST_OFFSET],r15
    mov rax,[r12+NEBO_G096_REQUEST_GENERATION_OFFSET]
    mov [rbp-120+NEBO_G096_RESULT_GENERATION_OFFSET],rax
    lea rsi,[rbp-120]
    mov rdi,r13
    mov ecx,NEBO_G096_RESULT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done
.invalid:
    mov eax,NEBO_G096_ERROR_INVALID
    jmp .done
.bounds:
    mov eax,NEBO_G096_ERROR_BOUNDS
    jmp .done
.kind:
    mov eax,NEBO_G096_ERROR_KIND
    jmp .done
.shape:
    mov eax,NEBO_G096_ERROR_SHAPE
    jmp .done
.index:
    mov eax,NEBO_G096_ERROR_INDEX
    jmp .done
.nonfinite:
    mov eax,NEBO_G096_ERROR_NONFINITE
    jmp .done
.camera:
    mov eax,NEBO_G096_ERROR_CAMERA
    jmp .done
.clip:
    mov eax,NEBO_G096_ERROR_CLIP
    jmp .done
.options:
    mov eax,NEBO_G096_ERROR_OPTIONS
    jmp .done
.target:
    mov eax,NEBO_G096_ERROR_TARGET
    jmp .done
.lighting:
    mov eax,NEBO_G096_ERROR_LIGHTING
.done:
    add rsp,80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
