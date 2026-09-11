; G097 token-owned Matrix/Tensor/Volume scientific-view source vertical.
%define G97_FAMILY_KEY 0x5246323034473937

section .rodata
%macro G97_NAME 2
g97_n_%1: db %2
g97_n_%1_len equ $-g97_n_%1
%endmacro
G97_NAME matrix_root,'MatrixScientificView'
G97_NAME shape_root,'TensorShapeView'
G97_NAME tensor_slice_root,'TensorSliceView'
G97_NAME volume_slice_root,'VolumeSliceView'
G97_NAME isosurface_root,'VolumeIsosurfaceView'
G97_NAME compare_root,'ScientificCompareView'
G97_NAME color_root,'ScientificColorQualityView'
G97_NAME bounded_root,'BoundedTensorView'
G97_NAME oracle_root,'ScientificOracleView'
G97_NAME closeout_root,'ScientificCloseoutView'
G97_NAME compare,'compare'
G97_NAME index,'index'
G97_NAME isosurface,'isosurface'
G97_NAME matrix,'matrix'
G97_NAME shape_inspector,'shapeInspector'
G97_NAME slice,'slice'
G97_NAME tensor,'tensor'
G97_NAME tensor_slice,'tensorSlice'
G97_NAME threshold,'threshold'
G97_NAME volume,'volume'
G97_NAME with,'with'
%undef G97_NAME

section .text
g97_is_program:
%macro G97_ROOT 1
    lea rsi,[rel g97_n_%1]
    mov edx,g97_n_%1_len
    call ls_contains_atom
    test eax,eax
    jnz .yes
%endmacro
    G97_ROOT matrix_root
    G97_ROOT shape_root
    G97_ROOT tensor_slice_root
    G97_ROOT volume_slice_root
    G97_ROOT isosurface_root
    G97_ROOT compare_root
    G97_ROOT color_root
    G97_ROOT bounded_root
    G97_ROOT oracle_root
    G97_ROOT closeout_root
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret
%undef G97_ROOT

; Each bounded form binds one nominal scientific-view family, an exact
; receiver-first operation sequence and one source-derived generation value.
neboc_g097_source_parse:
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
%macro G97_PARSE_ROOT 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g97_n_%1]
    mov edx,g97_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov ebx,%2
    jmp .root_ready
%%next:
%endmacro
    G97_PARSE_ROOT matrix_root,1
    G97_PARSE_ROOT shape_root,2
    G97_PARSE_ROOT tensor_slice_root,3
    G97_PARSE_ROOT volume_slice_root,4
    G97_PARSE_ROOT isosurface_root,5
    G97_PARSE_ROOT compare_root,6
    G97_PARSE_ROOT color_root,7
    G97_PARSE_ROOT bounded_root,8
    G97_PARSE_ROOT oracle_root,9
    G97_PARSE_ROOT closeout_root,10
    jmp .method
.root_ready:
    xor r12d,r12d
%macro G97_CALL 1
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
    lea rsi,[rel g97_n_%1]
    mov edx,g97_n_%1_len
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
    je .matrix
    cmp ebx,2
    je .shape
    cmp ebx,3
    je .tensor_slice
    cmp ebx,4
    je .volume_slice
    cmp ebx,5
    je .isosurface
    cmp ebx,6
    je .compare
    cmp ebx,7
    je .color
    cmp ebx,8
    je .bounded
    cmp ebx,9
    je .oracle
    jmp .closeout
.matrix:
    G97_CALL matrix
    jmp .return_value
.shape:
    G97_CALL tensor
    G97_CALL shape_inspector
    jmp .return_value
.tensor_slice:
    G97_CALL tensor_slice
    G97_CALL slice
    G97_CALL index
    jmp .return_value
.volume_slice:
    G97_CALL volume
    G97_CALL slice
    G97_CALL index
    jmp .return_value
.isosurface:
    G97_CALL volume
    G97_CALL isosurface
    G97_CALL threshold
    jmp .return_value
.compare:
    G97_CALL compare
    G97_CALL with
    jmp .return_value
.color:
    G97_CALL matrix
    G97_CALL shape_inspector
    jmp .return_value
.bounded:
    G97_CALL tensor
    G97_CALL slice
    G97_CALL index
    jmp .return_value
.oracle:
    G97_CALL compare
    G97_CALL with
    jmp .return_value
.closeout:
    G97_CALL tensor
    G97_CALL shape_inspector
    G97_CALL compare
    G97_CALL with

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
    mov rdx,G97_FAMILY_KEY
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
%undef G97_CALL
%undef G97_PARSE_ROOT
