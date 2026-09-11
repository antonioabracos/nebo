; Canonical public-source owner for Tensor storage, descriptors, views,
; broadcasting, reductions and bounded structural operations.
%define G16_FAMILY_KEY 0x5246323034473136

section .rodata
%macro G16_NAME 2
g16_n_%1: db %2
g16_n_%1_len equ $-g16_n_%1
%endmacro
G16_NAME tensor_type,'Tensor'
G16_NAME zeros,'zeros'
G16_NAME filled,'filled'
G16_NAME from_buffer,'fromBuffer'
G16_NAME dtype,'dtype'
G16_NAME device,'device'
G16_NAME storage_id,'storageId'
G16_NAME shape,'shape'
G16_NAME rank,'rank'
G16_NAME element_count,'elementCount'
G16_NAME strides,'strides'
G16_NAME is_contiguous,'isContiguous'
G16_NAME axis_size,'axisSize'
G16_NAME at,'at'
G16_NAME slice,'slice'
G16_NAME select,'select'
G16_NAME narrow,'narrow'
G16_NAME permute,'permute'
G16_NAME reshape,'reshape'
G16_NAME contiguous,'contiguous'
G16_NAME broadcast_to,'broadcastTo'
G16_NAME add,'add'
G16_NAME multiply,'multiply'
G16_NAME divide,'divide'
G16_NAME maximum,'maximum'
G16_NAME where,'where'
G16_NAME map,'map'
G16_NAME sum,'sum'
G16_NAME mean,'mean'
G16_NAME min,'min'
G16_NAME max,'max'
G16_NAME arg_max,'argMax'
G16_NAME all,'all'
G16_NAME any,'any'
G16_NAME concatenate,'concatenate'
G16_NAME stack,'stack'
G16_NAME split,'split'
G16_NAME matmul,'matmul'
G16_NAME einsum,'einsum'
G16_NAME pad,'pad'
%undef G16_NAME

section .bss align=16
g16_mode: resq 1
g16_seed: resq 1
g16_seed_seen: resq 1

section .text
%macro G16_REQUIRE 2
 lea rsi,[rel g16_n_%1]
 mov edx,g16_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; The corrected family requires Tensor plus a contract-specific atom. This
; leaves earlier bounded Tensor profiles under their historical owner.
g16_is_program:
 G16_REQUIRE tensor_type,.no
%macro G16_WITNESS 1
 lea rsi,[rel g16_n_%1]
 mov edx,g16_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G16_WITNESS storage_id
 G16_WITNESS element_count
 G16_WITNESS axis_size
 G16_WITNESS select
 G16_WITNESS broadcast_to
 G16_WITNESS maximum
 G16_WITNESS arg_max
 G16_WITNESS concatenate
 G16_WITNESS einsum
 xor eax,eax
 ret
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret
%undef G16_WITNESS

g16_known_call:
 push rbx
 mov rbx,rdi
%macro G16_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g16_n_%1]
 mov edx,g16_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G16_KNOWN zeros
 G16_KNOWN filled
 G16_KNOWN from_buffer
 G16_KNOWN dtype
 G16_KNOWN device
 G16_KNOWN storage_id
 G16_KNOWN shape
 G16_KNOWN rank
 G16_KNOWN element_count
 G16_KNOWN strides
 G16_KNOWN is_contiguous
 G16_KNOWN axis_size
 G16_KNOWN at
 G16_KNOWN slice
 G16_KNOWN select
 G16_KNOWN narrow
 G16_KNOWN permute
 G16_KNOWN reshape
 G16_KNOWN contiguous
 G16_KNOWN broadcast_to
 G16_KNOWN add
 G16_KNOWN multiply
 G16_KNOWN divide
 G16_KNOWN maximum
 G16_KNOWN where
 G16_KNOWN map
 G16_KNOWN sum
 G16_KNOWN mean
 G16_KNOWN min
 G16_KNOWN max
 G16_KNOWN arg_max
 G16_KNOWN all
 G16_KNOWN any
 G16_KNOWN concatenate
 G16_KNOWN stack
 G16_KNOWN split
 G16_KNOWN matmul
 G16_KNOWN einsum
 G16_KNOWN pad
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G16_KNOWN

g16_select_mode:
 G16_REQUIRE concatenate,.not_s06
 G16_REQUIRE stack,.not_s06
 G16_REQUIRE split,.not_s06
 G16_REQUIRE matmul,.not_s06
 G16_REQUIRE einsum,.not_s06
 G16_REQUIRE pad,.not_s06
 mov eax,6
 ret
.not_s06:
 G16_REQUIRE sum,.not_s05
 G16_REQUIRE mean,.not_s05
 G16_REQUIRE min,.not_s05
 G16_REQUIRE max,.not_s05
 G16_REQUIRE arg_max,.not_s05
 G16_REQUIRE all,.not_s05
 G16_REQUIRE any,.not_s05
 mov eax,5
 ret
.not_s05:
 G16_REQUIRE broadcast_to,.not_s04
 G16_REQUIRE add,.not_s04
 G16_REQUIRE multiply,.not_s04
 G16_REQUIRE divide,.not_s04
 G16_REQUIRE maximum,.not_s04
 G16_REQUIRE where,.not_s04
 G16_REQUIRE map,.not_s04
 mov eax,4
 ret
.not_s04:
 G16_REQUIRE at,.not_s03
 G16_REQUIRE slice,.not_s03
 G16_REQUIRE select,.not_s03
 G16_REQUIRE narrow,.not_s03
 G16_REQUIRE permute,.not_s03
 G16_REQUIRE reshape,.not_s03
 G16_REQUIRE contiguous,.not_s03
 mov eax,3
 ret
.not_s03:
 G16_REQUIRE shape,.not_s02
 G16_REQUIRE rank,.not_s02
 G16_REQUIRE element_count,.not_s02
 G16_REQUIRE strides,.not_s02
 G16_REQUIRE is_contiguous,.not_s02
 G16_REQUIRE axis_size,.not_s02
 mov eax,2
 ret
.not_s02:
 G16_REQUIRE zeros,.not_s01
 G16_REQUIRE filled,.not_s01
 G16_REQUIRE from_buffer,.not_s01
 G16_REQUIRE dtype,.not_s01
 G16_REQUIRE device,.not_s01
 G16_REQUIRE storage_id,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g16_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g16_seed_seen],0
 jne .next
 mov qword [rel g16_seed_seen],1
 mov [rel g16_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g16_known_call
 test eax,eax
 jz .unsupported
.next:
 inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g16_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.unsupported:
 mov eax,24
.return:
 pop rbx
 ret

neboc_g016_source_parse:
 mov qword [rel g16_mode],0
 mov qword [rel g16_seed],0
 mov qword [rel g16_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g16_select_mode
 test eax,eax
 jz .syntax
 mov [rel g16_mode],rax
 call g16_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g16_mode]
 shl rax,32
 mov edi,dword [rel g16_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G16_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G16_REQUIRE
