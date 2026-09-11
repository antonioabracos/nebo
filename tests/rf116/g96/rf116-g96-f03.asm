bits 64
default rel
global _start
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_line_3d_nebo
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_point_cloud_nebo
section .text
_start:
    mov rdi, 100
    mov rsi, 3
    mov rdx, 0
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_point_cloud_nebo
    test rax, rax
    jne .fail
    mov rdi, 2
    mov rsi, 3
    mov rdx, 0
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_line_3d_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 3
    mov rdx, 0
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_line_3d_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
