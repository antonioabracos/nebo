bits 64
default rel
global _start
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_closeout_nebo
extern nebo_plot3d_scene3d_camera_lighting_e_mesh_headless_schema_live_renderer_parity_nebo
section .text
_start:
    mov rdi, 1
    mov rsi, 3
    mov rdx, 3
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_headless_schema_live_renderer_parity_nebo
    test rax, rax
    jne .fail
    mov rdi, 64
    mov rsi, 2
    mov rdx, 0
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_closeout_nebo
    test rax, rax
    jne .fail
    mov rdi, 257
    mov rsi, 2
    mov rdx, 0
    call nebo_plot3d_scene3d_camera_lighting_e_mesh_closeout_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
