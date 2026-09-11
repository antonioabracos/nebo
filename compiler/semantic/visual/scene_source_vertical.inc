; G096 token-owned Plot3D/Scene3D adapter source vertical.
%define G96_FAMILY_KEY 0x5246323034473936

section .rodata
%macro G96_NAME 2
g96_n_%1: db %2
g96_n_%1_len equ $-g96_n_%1
%endmacro
G96_NAME registry_root,'Plot3DKindRegistry'
G96_NAME points_root,'PointCloud3D'
G96_NAME line_root,'LinePlot3D'
G96_NAME mesh_root,'SurfaceMesh3D'
G96_NAME orbit_root,'OrbitCamera3D'
G96_NAME lighting_root,'SceneLighting3D'
G96_NAME composition_root,'SceneComposition3D'
G96_NAME depth_root,'DepthPrecision3D'
G96_NAME parity_root,'RendererParity3D'
G96_NAME free_root,'FreeCameraCloseout3D'
G96_NAME ambient,'ambient'
G96_NAME axis,'axis'
G96_NAME axis3d,'axis3d'
G96_NAME camera,'camera'
G96_NAME free,'free'
G96_NAME grid3d,'grid3d'
G96_NAME light,'light'
G96_NAME look_at,'lookAt'
G96_NAME orbit,'orbit'
G96_NAME plot3d,'plot3d'
G96_NAME position,'position'
G96_NAME scene3d,'scene3d'
G96_NAME z,'z'
%undef G96_NAME

section .text
g96_is_program:
%macro G96_ROOT 1
    lea rsi,[rel g96_n_%1]
    mov edx,g96_n_%1_len
    call ls_contains_atom
    test eax,eax
    jnz .yes
%endmacro
    G96_ROOT registry_root
    G96_ROOT points_root
    G96_ROOT line_root
    G96_ROOT mesh_root
    G96_ROOT orbit_root
    G96_ROOT lighting_root
    G96_ROOT composition_root
    G96_ROOT depth_root
    G96_ROOT parity_root
    G96_ROOT free_root
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret
%undef G96_ROOT

; Every bounded form binds one nominal 3D family, its exact operation sequence
; and one source-derived extent. The extent reaches the target-neutral model.
neboc_g096_source_parse:
    push rbx
    push r12
    push r13
    push r14
    mov qword [rel ls_cursor],0
    call ls_start_header
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_IDENTIFIER
    jne .syntax
    mov r14,[rel ls_cursor]
    xor ebx,ebx
%macro G96_PARSE_ROOT 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g96_n_%1]
    mov edx,g96_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov ebx,%2
    jmp .root_ready
%%next:
%endmacro
    G96_PARSE_ROOT registry_root,1
    G96_PARSE_ROOT points_root,2
    G96_PARSE_ROOT line_root,3
    G96_PARSE_ROOT mesh_root,4
    G96_PARSE_ROOT orbit_root,5
    G96_PARSE_ROOT lighting_root,6
    G96_PARSE_ROOT composition_root,7
    G96_PARSE_ROOT depth_root,8
    G96_PARSE_ROOT parity_root,9
    G96_PARSE_ROOT free_root,10
    jmp .method
.root_ready:
    xor r12d,r12d
%macro G96_CALL 1
    mov rdi,[rel ls_cursor]
    mov rsi,r14
    call ls_name_equal
    test eax,eax
    jz .method
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .arity
    lea rsi,[rel g96_n_%1]
    mov edx,g96_n_%1_len
    call ls_current_atom
    test eax,eax
    jz .method
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_LPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
    test r12,r12
    jnz %%compare
    mov r12,rax
    jmp %%range
%%compare:
    cmp rax,r12
    jne .method
%%range:
    test rax,rax
    jz .range_error
    cmp rax,255
    ja .range_error
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .arity
%endmacro
    cmp ebx,1
    je .plot_pair
    cmp ebx,2
    je .plot_pair
    cmp ebx,3
    je .plot_pair
    cmp ebx,4
    je .plot_pair
    cmp ebx,5
    je .orbit_camera
    cmp ebx,6
    je .lighting
    cmp ebx,7
    je .composition
    cmp ebx,8
    je .depth
    cmp ebx,9
    je .parity
    jmp .free_camera
.plot_pair:
    G96_CALL plot3d
    G96_CALL z
    jmp .return_value
.orbit_camera:
    G96_CALL camera
    G96_CALL orbit
    G96_CALL position
    G96_CALL look_at
    jmp .return_value
.lighting:
    G96_CALL axis
    G96_CALL axis3d
    G96_CALL grid3d
    G96_CALL light
    G96_CALL ambient
    jmp .return_value
.composition:
    G96_CALL scene3d
    G96_CALL plot3d
    G96_CALL z
    jmp .return_value
.depth:
    G96_CALL scene3d
    G96_CALL camera
    G96_CALL position
    G96_CALL look_at
    jmp .return_value
.parity:
    G96_CALL scene3d
    G96_CALL plot3d
    G96_CALL z
    jmp .return_value
.free_camera:
    G96_CALL camera
    G96_CALL free
    G96_CALL position
    G96_CALL look_at

.return_value:
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .syntax
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],r12
    jne .method
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_KW_RETURN
    jne .syntax
    inc qword [rel ls_cursor]
    call ls_finish_program
    test eax,eax
    jz .syntax
    mov rax,rbx
    shl rax,32
    mov edi,r12d
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G96_FAMILY_KEY
    call ls_success
    jmp .done
.method:
    mov edi,20
    call ls_error
    jmp .done
.type:
    mov edi,21
    call ls_error
    jmp .done
.range_error:
    mov edi,22
    call ls_error
    jmp .done
.arity:
    mov edi,25
    call ls_error
    jmp .done
.syntax:
    mov edi,20
    call ls_error
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
%undef G96_CALL
%undef G96_PARSE_ROOT
