; G096 source-to-effect probe over the target-neutral Scene3D model.
bits 64
default rel
%define NEBO_G096_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/scene_source_probe.inc"
%include "runtime/console/scene_model.inc"

global nebo_g096_source_probe
global nebo_g096_negative_probe

section .bss align=16
g96_request: resb NEBO_G096_REQUEST_SIZE
g96_headless: resb NEBO_G096_RESULT_SIZE
g96_live: resb NEBO_G096_RESULT_SIZE
g96_vertices: resq 765
g96_indices: resq 3
g96_position: resq 3
g96_look_at: resq 3

section .text
g96_clear:
    lea rdi,[rel g96_request]
    mov ecx,NEBO_G096_REQUEST_SIZE/8
    xor eax,eax
    cld
    rep stosq
    lea rdi,[rel g96_headless]
    mov ecx,NEBO_G096_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g96_live]
    mov ecx,NEBO_G096_RESULT_SIZE/8
    rep stosq
    ret

; EDI=subgroup 1..10, ESI=source extent 1..255 -> EAX=observed extent.
nebo_g096_source_probe:
    push rbx
    push r12
    push r13
    push r14
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
    call g96_clear

    lea rbx,[rel g96_vertices]
    mov ecx,r13d
    imul ecx,3
    xor edx,edx
.fill_vertices:
    mov eax,edx
    add eax,r13d
    inc eax
    cvtsi2sd xmm0,eax
    movsd [rbx+rdx*8],xmm0
    inc edx
    cmp edx,ecx
    jb .fill_vertices
    mov qword [rel g96_indices],0
    mov qword [rel g96_indices+8],1
    mov qword [rel g96_indices+16],2
    mov rax,0x3ff0000000000000
    mov [rel g96_position],rax
    mov rax,0x4000000000000000
    mov [rel g96_position+8],rax
    mov rax,0x4008000000000000
    mov [rel g96_position+16],rax
    xor eax,eax
    mov [rel g96_look_at],rax
    mov [rel g96_look_at+8],rax
    mov [rel g96_look_at+16],rax

    mov [rel g96_request+NEBO_G096_REQUEST_VERTICES_OFFSET],r13
    mov qword [rel g96_request+NEBO_G096_REQUEST_COMPONENTS_OFFSET],3
    mov qword [rel g96_request+NEBO_G096_REQUEST_LIGHT_COUNT_OFFSET],1
    mov qword [rel g96_request+NEBO_G096_REQUEST_PRECISION_OFFSET],24
    lea rax,[rel g96_vertices]
    mov [rel g96_request+NEBO_G096_REQUEST_VERTEX_PTR_OFFSET],rax
    lea rax,[rel g96_indices]
    mov [rel g96_request+NEBO_G096_REQUEST_INDEX_PTR_OFFSET],rax
    lea rax,[rel g96_position]
    mov [rel g96_request+NEBO_G096_REQUEST_POSITION_PTR_OFFSET],rax
    lea rax,[rel g96_look_at]
    mov [rel g96_request+NEBO_G096_REQUEST_LOOK_AT_PTR_OFFSET],rax
    mov rax,0x3ff0000000000000
    mov [rel g96_request+NEBO_G096_REQUEST_NEAR_OFFSET],rax
    mov eax,r13d
    add eax,64
    cvtsi2sd xmm0,eax
    movq rax,xmm0
    mov [rel g96_request+NEBO_G096_REQUEST_FAR_OFFSET],rax
    mov rax,0x3fe0000000000000
    mov [rel g96_request+NEBO_G096_REQUEST_AMBIENT_OFFSET],rax
    mov [rel g96_request+NEBO_G096_REQUEST_GENERATION_OFFSET],r13
    mov r14,NEBO_G096_OPTION_REQUIRED

    cmp r12d,1
    je .registry
    cmp r12d,2
    je .points
    cmp r12d,3
    je .line
    cmp r12d,4
    je .mesh
    cmp r12d,6
    je .surface
    cmp r12d,7
    je .mesh
    cmp r12d,8
    je .line
    cmp r12d,9
    je .surface
    jmp .points
.registry:
    mov eax,r13d
    xor edx,edx
    mov ecx,4
    div ecx
    inc edx
    mov [rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET],edx
    jmp .kind_ready
.points:
    mov dword [rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET],NEBO_G096_KIND_POINTS
    jmp .kind_ready
.line:
    mov dword [rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET],NEBO_G096_KIND_LINE
    jmp .kind_ready
.surface:
    mov dword [rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET],NEBO_G096_KIND_SURFACE
    mov qword [rel g96_request+NEBO_G096_REQUEST_INDICES_OFFSET],3
    jmp .kind_ready
.mesh:
    mov dword [rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET],NEBO_G096_KIND_MESH
    mov qword [rel g96_request+NEBO_G096_REQUEST_INDICES_OFFSET],3
.kind_ready:
    mov eax,[rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET]
    cmp eax,NEBO_G096_KIND_SURFACE
    jb .camera_kind
    mov qword [rel g96_request+NEBO_G096_REQUEST_INDICES_OFFSET],3
.camera_kind:
    cmp r12d,10
    je .free_camera
    mov qword [rel g96_request+NEBO_G096_REQUEST_CAMERA_MODE_OFFSET],NEBO_G096_CAMERA_ORBIT
    or r14,NEBO_G096_OPTION_ORBIT
    jmp .options_ready
.free_camera:
    mov qword [rel g96_request+NEBO_G096_REQUEST_CAMERA_MODE_OFFSET],NEBO_G096_CAMERA_FREE
    or r14,NEBO_G096_OPTION_FREE
.options_ready:
    mov [rel g96_request+NEBO_G096_REQUEST_OPTIONS_OFFSET],r14
    mov eax,r13d
    xor edx,edx
    mov ecx,8
    div ecx
    inc edx
    mov [rel g96_request+NEBO_G096_REQUEST_LIGHT_COUNT_OFFSET],rdx
    mov eax,r13d
    xor edx,edx
    mov ecx,3
    div ecx
    cmp edx,0
    jne .precision_24
    mov qword [rel g96_request+NEBO_G096_REQUEST_PRECISION_OFFSET],16
    jmp .run
.precision_24:
    cmp edx,1
    jne .precision_32
    mov qword [rel g96_request+NEBO_G096_REQUEST_PRECISION_OFFSET],24
    jmp .run
.precision_32:
    mov qword [rel g96_request+NEBO_G096_REQUEST_PRECISION_OFFSET],32

.run:
    mov dword [rel g96_request+NEBO_G096_REQUEST_TARGET_OFFSET],NEBO_G096_TARGET_HEADLESS
    lea rdi,[rel g96_request]
    lea rsi,[rel g96_headless]
    call nebo_g096_scene_model
    test eax,eax
    jnz .failure
    mov dword [rel g96_request+NEBO_G096_REQUEST_TARGET_OFFSET],NEBO_G096_TARGET_LIVE
    lea rdi,[rel g96_request]
    lea rsi,[rel g96_live]
    call nebo_g096_scene_model
    test eax,eax
    jnz .failure
%macro G96_COMPARE_QWORD 1
    mov rax,[rel g96_headless+%1]
    cmp rax,[rel g96_live+%1]
    jne .failure
%endmacro
    G96_COMPARE_QWORD NEBO_G096_RESULT_VERTICES_OFFSET
    G96_COMPARE_QWORD NEBO_G096_RESULT_INDICES_OFFSET
    G96_COMPARE_QWORD NEBO_G096_RESULT_OPTIONS_OFFSET
    G96_COMPARE_QWORD NEBO_G096_RESULT_CAMERA_MODE_OFFSET
    G96_COMPARE_QWORD NEBO_G096_RESULT_LIGHT_COUNT_OFFSET
    G96_COMPARE_QWORD NEBO_G096_RESULT_PRECISION_OFFSET
    G96_COMPARE_QWORD NEBO_G096_RESULT_DIGEST_OFFSET
    G96_COMPARE_QWORD NEBO_G096_RESULT_GENERATION_OFFSET
%undef G96_COMPARE_QWORD
    mov eax,[rel g96_headless+NEBO_G096_RESULT_KIND_OFFSET]
    cmp eax,[rel g96_live+NEBO_G096_RESULT_KIND_OFFSET]
    jne .failure
    mov eax,[rel g96_headless+NEBO_G096_RESULT_VERTICES_OFFSET]
    cmp eax,r13d
    jne .failure
    jmp .done
.failure:
    mov eax,-1
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=case 1..12 -> EAX=stable model error, with failure atomicity checked.
nebo_g096_negative_probe:
    push rbx
    push r12
    mov r12d,edi
    call g96_clear
    mov dword [rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET],NEBO_G096_KIND_MESH
    mov dword [rel g96_request+NEBO_G096_REQUEST_TARGET_OFFSET],NEBO_G096_TARGET_HEADLESS
    mov qword [rel g96_request+NEBO_G096_REQUEST_VERTICES_OFFSET],4
    mov qword [rel g96_request+NEBO_G096_REQUEST_INDICES_OFFSET],3
    mov qword [rel g96_request+NEBO_G096_REQUEST_COMPONENTS_OFFSET],3
    mov qword [rel g96_request+NEBO_G096_REQUEST_OPTIONS_OFFSET],NEBO_G096_OPTION_REQUIRED | NEBO_G096_OPTION_ORBIT
    mov qword [rel g96_request+NEBO_G096_REQUEST_CAMERA_MODE_OFFSET],NEBO_G096_CAMERA_ORBIT
    mov qword [rel g96_request+NEBO_G096_REQUEST_LIGHT_COUNT_OFFSET],2
    mov qword [rel g96_request+NEBO_G096_REQUEST_PRECISION_OFFSET],24
    lea rax,[rel g96_vertices]
    mov [rel g96_request+NEBO_G096_REQUEST_VERTEX_PTR_OFFSET],rax
    lea rax,[rel g96_indices]
    mov [rel g96_request+NEBO_G096_REQUEST_INDEX_PTR_OFFSET],rax
    lea rax,[rel g96_position]
    mov [rel g96_request+NEBO_G096_REQUEST_POSITION_PTR_OFFSET],rax
    lea rax,[rel g96_look_at]
    mov [rel g96_request+NEBO_G096_REQUEST_LOOK_AT_PTR_OFFSET],rax
    mov rax,0x3ff0000000000000
    mov [rel g96_position],rax
    mov [rel g96_position+8],rax
    mov [rel g96_position+16],rax
    xor eax,eax
    mov [rel g96_look_at],rax
    mov [rel g96_look_at+8],rax
    mov [rel g96_look_at+16],rax
    mov qword [rel g96_indices],0
    mov qword [rel g96_indices+8],1
    mov qword [rel g96_indices+16],2
    mov rax,0x3ff0000000000000
    mov [rel g96_request+NEBO_G096_REQUEST_NEAR_OFFSET],rax
    mov rax,0x4059000000000000
    mov [rel g96_request+NEBO_G096_REQUEST_FAR_OFFSET],rax
    mov rax,0x3fe0000000000000
    mov [rel g96_request+NEBO_G096_REQUEST_AMBIENT_OFFSET],rax
    mov qword [rel g96_request+NEBO_G096_REQUEST_GENERATION_OFFSET],1
    lea rdi,[rel g96_vertices]
    mov ecx,12
    mov rax,0x3ff0000000000000
    cld
    rep stosq
    mov rax,0x6a6a6a6a6a6a6a6a
    mov [rel g96_headless],rax
    cmp r12d,1
    je .bad_kind
    cmp r12d,2
    je .bad_target
    cmp r12d,3
    je .zero_vertices
    cmp r12d,4
    je .too_many_vertices
    cmp r12d,5
    je .bad_components
    cmp r12d,6
    je .short_line
    cmp r12d,7
    je .bad_index_shape
    cmp r12d,8
    je .bad_index
    cmp r12d,9
    je .bad_camera
    cmp r12d,10
    je .bad_clip
    cmp r12d,11
    je .bad_ambient
    cmp r12d,12
    je .bad_options
    mov eax,-1
    jmp .negative_done
.bad_kind:
    mov dword [rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET],0
    jmp .negative_run
.bad_target:
    mov dword [rel g96_request+NEBO_G096_REQUEST_TARGET_OFFSET],0
    jmp .negative_run
.zero_vertices:
    mov qword [rel g96_request+NEBO_G096_REQUEST_VERTICES_OFFSET],0
    jmp .negative_run
.too_many_vertices:
    mov qword [rel g96_request+NEBO_G096_REQUEST_VERTICES_OFFSET],NEBO_G096_MAX_VERTICES+1
    jmp .negative_run
.bad_components:
    mov qword [rel g96_request+NEBO_G096_REQUEST_COMPONENTS_OFFSET],2
    jmp .negative_run
.short_line:
    mov dword [rel g96_request+NEBO_G096_REQUEST_KIND_OFFSET],NEBO_G096_KIND_LINE
    mov qword [rel g96_request+NEBO_G096_REQUEST_VERTICES_OFFSET],1
    mov qword [rel g96_request+NEBO_G096_REQUEST_INDICES_OFFSET],0
    jmp .negative_run
.bad_index_shape:
    mov qword [rel g96_request+NEBO_G096_REQUEST_INDICES_OFFSET],2
    jmp .negative_run
.bad_index:
    mov qword [rel g96_indices+16],4
    jmp .negative_run
.bad_camera:
    mov qword [rel g96_request+NEBO_G096_REQUEST_CAMERA_MODE_OFFSET],NEBO_G096_CAMERA_FREE
    jmp .negative_run
.bad_clip:
    mov rax,0x4059000000000000
    mov [rel g96_request+NEBO_G096_REQUEST_NEAR_OFFSET],rax
    mov rax,0x3ff0000000000000
    mov [rel g96_request+NEBO_G096_REQUEST_FAR_OFFSET],rax
    jmp .negative_run
.bad_ambient:
    mov rax,0x7ff8000000000001
    mov [rel g96_request+NEBO_G096_REQUEST_AMBIENT_OFFSET],rax
    jmp .negative_run
.bad_options:
    or qword [rel g96_request+NEBO_G096_REQUEST_OPTIONS_OFFSET],0x2000
.negative_run:
    lea rdi,[rel g96_request]
    lea rsi,[rel g96_headless]
    call nebo_g096_scene_model
    mov ebx,eax
    mov rax,0x6a6a6a6a6a6a6a6a
    cmp [rel g96_headless],rax
    jne .atomicity_failed
    mov eax,ebx
    jmp .negative_done
.atomicity_failed:
    mov eax,-1
.negative_done:
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
