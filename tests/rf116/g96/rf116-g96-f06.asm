bits 64
default rel
global _start
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_axes_grid_light_ambient_nebo
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_camera_orbit_free_position_lookat_nebo
section .text
_start:
    mov rdi, 1
    mov rsi, 100
    mov rdx, 60
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_camera_orbit_free_position_lookat_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 1
    mov rdx, 4
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_axes_grid_light_ambient_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 1
    mov rdx, 9
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_axes_grid_light_ambient_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
