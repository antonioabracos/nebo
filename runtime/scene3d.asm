bits 64
default rel
section .text
global nebo_plot3d_scene3d_camera_lighting_e_mesh_plot3d_kind_registry_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_plot3d_kind_registry_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-PLOT3D-KIND-REGISTRY-F01

global nebo_plot3d_scene3d_camera_lighting_e_mesh_point_cloud_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_point_cloud_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 100000
    jg .invalid
    cmp rsi, 3
    jne .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-POINT-CLOUD-F02

global nebo_plot3d_scene3d_camera_lighting_e_mesh_line_3d_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_line_3d_nebo:
    cmp rdi, 2
    jl .invalid
    cmp rdi, 100000
    jg .invalid
    cmp rsi, 3
    jne .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-LINE-3D-F03

global nebo_plot3d_scene3d_camera_lighting_e_mesh_surface_e_mesh_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_surface_e_mesh_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 100000
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 300000
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-SURFACE-E-MESH-F04

global nebo_plot3d_scene3d_camera_lighting_e_mesh_camera_orbit_free_position_lookat_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_camera_orbit_free_position_lookat_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 2
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 1000000
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 179
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-CAMERA-ORBIT-FREE-POSITION-LOOKAT-F05

global nebo_plot3d_scene3d_camera_lighting_e_mesh_axes_grid_light_ambient_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_axes_grid_light_ambient_nebo:
    cmp rdi, 0
    jl .invalid
    cmp rdi, 1
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 1
    jg .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 8
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-AXES-GRID-LIGHT-AMBIENT-F06

global nebo_plot3d_scene3d_camera_lighting_e_mesh_scene3d_composition_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_scene3d_composition_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 256
    jg .invalid
    cmp rsi, 1
    jne .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 8
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-SCENE3D-COMPOSITION-F07

global nebo_plot3d_scene3d_camera_lighting_e_mesh_depth_precision_clipping_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_depth_precision_clipping_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 1000000
    jg .invalid
    cmp rsi, 2
    jl .invalid
    cmp rsi, 1000000
    jg .invalid
    cmp rdi, rsi
    jge .invalid
    cmp rdx, 16
    jl .invalid
    cmp rdx, 32
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-DEPTH-PRECISION-CLIPPING-F08

global nebo_plot3d_scene3d_camera_lighting_e_mesh_headless_schema_live_renderer_parity_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_headless_schema_live_renderer_parity_nebo:
    cmp rdi, 1
    jne .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 4
    jg .invalid
    cmp rsi, rdx
    jne .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-HEADLESS-SCHEMA-LIVE-RENDERER-PARITY-F09

global nebo_plot3d_scene3d_camera_lighting_e_mesh_closeout_nebo
nebo_plot3d_scene3d_camera_lighting_e_mesh_closeout_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 256
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 4
    jg .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 1
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END PLOT3D-SCENE3D-CAMERA-LIGHTING-E-MESH-CLOSEOUT-F10
