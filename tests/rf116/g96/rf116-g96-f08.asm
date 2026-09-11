bits 64
default rel
global _start
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_depth_precision_clipping_nebo
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_scene3d_composition_nebo
section .text
_start:
    mov rdi, 64
    mov rsi, 1
    mov rdx, 4
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_scene3d_composition_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 1000
    mov rdx, 24
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_depth_precision_clipping_nebo
    test rax, rax
    jne .fail
    mov rdi, 100
    mov rsi, 10
    mov rdx, 24
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_depth_precision_clipping_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
