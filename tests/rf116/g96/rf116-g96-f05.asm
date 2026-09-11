bits 64
default rel
global _start
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_camera_orbit_free_position_lookat_nebo
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_surface_e_mesh_nebo
section .text
_start:
    mov rdi, 100
    mov rsi, 300
    mov rdx, 0
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_surface_e_mesh_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 100
    mov rdx, 60
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_camera_orbit_free_position_lookat_nebo
    test rax, rax
    jne .fail
    mov rdi, 3
    mov rsi, 100
    mov rdx, 60
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_camera_orbit_free_position_lookat_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
