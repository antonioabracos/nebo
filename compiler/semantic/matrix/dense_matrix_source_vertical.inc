; Canonical public-source owner for dense Matrix construction, views,
; elementwise operations, reductions, products and bounded linear algebra.
%define G15_FAMILY_KEY 0x5246323034473135

section .rodata
%macro G15_NAME 2
g15_n_%1: db %2
g15_n_%1_len equ $-g15_n_%1
%endmacro
G15_NAME matrix_type,'Matrix'
G15_NAME zeros,'zeros'
G15_NAME filled,'filled'
G15_NAME from_rows,'fromRows'
G15_NAME from_buffer,'fromBuffer'
G15_NAME rows,'rows'
G15_NAME columns,'columns'
G15_NAME layout,'layout'
G15_NAME at,'at'
G15_NAME get,'get'
G15_NAME row,'row'
G15_NAME column,'column'
G15_NAME slice,'slice'
G15_NAME transpose_view,'transposeView'
G15_NAME contiguous,'contiguous'
G15_NAME add,'add'
G15_NAME subtract,'subtract'
G15_NAME multiply_elements,'multiplyElements'
G15_NAME divide_elements,'divideElements'
G15_NAME scale,'scale'
G15_NAME map,'map'
G15_NAME clamp,'clamp'
G15_NAME sum,'sum'
G15_NAME mean,'mean'
G15_NAME min,'min'
G15_NAME max,'max'
G15_NAME trace,'trace'
G15_NAME is_square,'isSquare'
G15_NAME matmul,'matmul'
G15_NAME matvec,'matvec'
G15_NAME outer,'outer'
G15_NAME dot_flattened,'dotFlattened'
G15_NAME batched_matmul,'batchedMatmul'
G15_NAME matmul_into,'matmulInto'
G15_NAME determinant,'determinant'
G15_NAME solve,'solve'
G15_NAME inverse,'inverse'
G15_NAME lu,'lu'
G15_NAME qr,'qr'
G15_NAME cholesky,'cholesky'
G15_NAME condition_estimate,'conditionEstimate'
%undef G15_NAME

section .bss align=16
g15_mode: resq 1
g15_seed: resq 1
g15_seed_seen: resq 1

section .text
%macro G15_REQUIRE 2
 lea rsi,[rel g15_n_%1]
 mov edx,g15_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; EAX=1 only for the corrected G015 public family.  Legacy bounded C11
; Matrix<Int> programs remain owned by the existing structural parser.
g15_is_program:
 G15_REQUIRE matrix_type,.no
 lea rsi,[rel g15_n_get]
 mov edx,g15_n_get_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g15_n_divide_elements]
 mov edx,g15_n_divide_elements_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g15_n_trace]
 mov edx,g15_n_trace_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g15_n_matvec]
 mov edx,g15_n_matvec_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g15_n_determinant]
 mov edx,g15_n_determinant_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 ; Construction/layout example has no new single atom, so require the two
 ; independent copy constructors together.
 G15_REQUIRE from_rows,.no
 G15_REQUIRE from_buffer,.no
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

g15_known_call:
 push rbx
 mov rbx,rdi
%macro G15_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g15_n_%1]
 mov edx,g15_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G15_KNOWN zeros
 G15_KNOWN filled
 G15_KNOWN from_rows
 G15_KNOWN from_buffer
 G15_KNOWN rows
 G15_KNOWN columns
 G15_KNOWN layout
 G15_KNOWN at
 G15_KNOWN get
 G15_KNOWN row
 G15_KNOWN column
 G15_KNOWN slice
 G15_KNOWN transpose_view
 G15_KNOWN contiguous
 G15_KNOWN add
 G15_KNOWN subtract
 G15_KNOWN multiply_elements
 G15_KNOWN divide_elements
 G15_KNOWN scale
 G15_KNOWN map
 G15_KNOWN clamp
 G15_KNOWN sum
 G15_KNOWN mean
 G15_KNOWN min
 G15_KNOWN max
 G15_KNOWN trace
 G15_KNOWN is_square
 G15_KNOWN matmul
 G15_KNOWN matvec
 G15_KNOWN outer
 G15_KNOWN dot_flattened
 G15_KNOWN batched_matmul
 G15_KNOWN matmul_into
 G15_KNOWN determinant
 G15_KNOWN solve
 G15_KNOWN inverse
 G15_KNOWN lu
 G15_KNOWN qr
 G15_KNOWN cholesky
 G15_KNOWN condition_estimate
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G15_KNOWN

g15_select_mode:
 G15_REQUIRE determinant,.not_s06
 G15_REQUIRE solve,.not_s06
 G15_REQUIRE inverse,.not_s06
 G15_REQUIRE lu,.not_s06
 G15_REQUIRE qr,.not_s06
 G15_REQUIRE cholesky,.not_s06
 G15_REQUIRE condition_estimate,.not_s06
 mov eax,6
 ret
.not_s06:
 G15_REQUIRE matmul,.not_s05
 G15_REQUIRE matvec,.not_s05
 G15_REQUIRE outer,.not_s05
 G15_REQUIRE dot_flattened,.not_s05
 G15_REQUIRE batched_matmul,.not_s05
 G15_REQUIRE matmul_into,.not_s05
 mov eax,5
 ret
.not_s05:
 G15_REQUIRE sum,.not_s04
 G15_REQUIRE mean,.not_s04
 G15_REQUIRE min,.not_s04
 G15_REQUIRE max,.not_s04
 G15_REQUIRE trace,.not_s04
 G15_REQUIRE is_square,.not_s04
 mov eax,4
 ret
.not_s04:
 G15_REQUIRE add,.not_s03
 G15_REQUIRE subtract,.not_s03
 G15_REQUIRE multiply_elements,.not_s03
 G15_REQUIRE divide_elements,.not_s03
 G15_REQUIRE scale,.not_s03
 G15_REQUIRE map,.not_s03
 G15_REQUIRE clamp,.not_s03
 mov eax,3
 ret
.not_s03:
 G15_REQUIRE at,.not_s02
 G15_REQUIRE get,.not_s02
 G15_REQUIRE row,.not_s02
 G15_REQUIRE column,.not_s02
 G15_REQUIRE slice,.not_s02
 G15_REQUIRE transpose_view,.not_s02
 G15_REQUIRE contiguous,.not_s02
 mov eax,2
 ret
.not_s02:
 G15_REQUIRE zeros,.not_s01
 G15_REQUIRE filled,.not_s01
 G15_REQUIRE from_rows,.not_s01
 G15_REQUIRE from_buffer,.not_s01
 G15_REQUIRE rows,.not_s01
 G15_REQUIRE columns,.not_s01
 G15_REQUIRE layout,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g15_scan_program:
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
 cmp qword [rel g15_seed_seen],0
 jne .next
 mov qword [rel g15_seed_seen],1
 mov [rel g15_seed],rdx
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
 call g15_known_call
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
 cmp qword [rel g15_seed],0
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

neboc_g015_source_parse:
 mov qword [rel g15_mode],0
 mov qword [rel g15_seed],0
 mov qword [rel g15_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g15_select_mode
 test eax,eax
 jz .syntax
 mov [rel g15_mode],rax
 call g15_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g15_mode]
 shl rax,32
 mov edi,dword [rel g15_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G15_FAMILY_KEY
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

%undef G15_REQUIRE
