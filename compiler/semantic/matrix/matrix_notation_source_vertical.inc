; G135 bounded source owner for matrix postfixes, exact norms and inner
; products.  It consumes canonical lexer tokens and evaluates only source
; values.  The profile is dense CPU Int/Complex with at most four logical
; cells (eight i64 components), so every store is statically caller-owned.

%define G135_FAMILY_KEY 0x5246323034473135
%define G135_OBJECT_CAPACITY 4
%define G135_COMPONENT_CAPACITY 8
%define G135_DTYPE_INT 1
%define G135_DTYPE_COMPLEX 2
%define G135_KIND_MATRIX 1
%define G135_KIND_VECTOR 2
%define G135_OP_TRANSPOSE 1
%define G135_OP_ADJOINT 2
%define G135_OP_INVERSE 3

section .rodata
g135_n_complex: db 'Complex'
g135_n_complex_len equ $-g135_n_complex
g135_n_transpose: db 'transpose'
g135_n_transpose_len equ $-g135_n_transpose
g135_n_adjoint: db 'adjoint'
g135_n_adjoint_len equ $-g135_n_adjoint
g135_n_inverse: db 'inverse'
g135_n_inverse_len equ $-g135_n_inverse
g135_n_norm: db 'norm'
g135_n_norm_len equ $-g135_n_norm
g135_n_inner_product: db 'innerProduct'
g135_n_inner_product_len equ $-g135_n_inner_product
g135_n_at: db 'at'
g135_n_at_len equ $-g135_n_at
g135_n_real_at: db 'realAt'
g135_n_real_at_len equ $-g135_n_real_at
g135_n_imag_at: db 'imagAt'
g135_n_imag_at_len equ $-g135_n_imag_at
g135_n_numerator_at: db 'numeratorAt'
g135_n_numerator_at_len equ $-g135_n_numerator_at
g135_n_denominator: db 'denominator'
g135_n_denominator_len equ $-g135_n_denominator

section .bss align=16
g135_scratch_start:
g135_object_count: resq 1
g135_object_names: resq G135_OBJECT_CAPACITY
g135_object_kinds: resq G135_OBJECT_CAPACITY
g135_object_dtypes: resq G135_OBJECT_CAPACITY
g135_object_rows: resq G135_OBJECT_CAPACITY
g135_object_cols: resq G135_OBJECT_CAPACITY
g135_object_components: resq G135_OBJECT_CAPACITY
g135_object_values: resq G135_OBJECT_CAPACITY*G135_COMPONENT_CAPACITY
g135_scratch_end:

section .text

; Token index RDI -> EAX boolean for a portable G135 API atom.
g135_method_at:
 push rbx
 mov rbx,rdi
%macro G135_METHOD 1
 mov rdi,rbx
 lea rsi,[rel g135_n_%1]
 mov edx,g135_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G135_METHOD transpose
 G135_METHOD adjoint
 G135_METHOD inverse
 G135_METHOD norm
 G135_METHOD inner_product
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G135_METHOD

; Claim only a bounded Matrix/Vector declaration containing an explicit
; extent comma and at least one exact G135 token or portable method.  This
; leaves G015 Matrix<Float> and G134 Vector programs with their prior owners.
g135_is_program:
 push rbx
 push r12
 xor ebx,ebx
 xor r12d,r12d
.scan:
 cmp rbx,[rel ls_token_count]
 jae .finish
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_MATRIX_TRANSPOSE
 je .feature
 cmp eax,NEBOC_TOKEN_MATRIX_ADJOINT
 je .feature
 cmp eax,NEBOC_TOKEN_MATRIX_INVERSE
 je .feature
 cmp eax,NEBOC_TOKEN_LINEAR_NORM_DELIMITER
 je .feature
 cmp eax,NEBOC_TOKEN_LINEAR_INNER_OPEN
 je .feature
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 call g135_method_at
 test eax,eax
 jnz .feature
 mov rdi,rbx
 lea rsi,[rel ls_n_matrix]
 mov edx,ls_n_matrix_len
 call ls_token_match
 test eax,eax
 jnz .declaration
 mov rdi,rbx
 lea rsi,[rel ls_n_vector]
 mov edx,ls_n_vector_len
 call ls_token_match
 test eax,eax
 jz .next
.declaration:
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LESS
 jne .next
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .next
 or r12d,1
 jmp .next
.feature:
 or r12d,2
.next:
 inc rbx
 jmp .scan
.finish:
 cmp r12d,3
 sete al
 movzx eax,al
 pop r12
 pop rbx
 ret

; Token index RDI -> object index RAX or -1.
g135_find_object:
 push rbx
 push r12
 mov r12,rdi
 xor ebx,ebx
.loop:
 cmp rbx,[rel g135_object_count]
 jae .missing
 mov rdi,r12
 mov rsi,[g135_object_names+rbx*8]
 call ls_name_equal
 test eax,eax
 jnz .found
 inc rbx
 jmp .loop
.found:
 mov rax,rbx
 jmp .done
.missing:
 mov rax,-1
.done:
 pop r12
 pop rbx
 ret

; Parse a unique binding name and semicolon into object RDI.
g135_parse_binding:
 push rbx
 mov rbx,rdi
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 call g135_find_object
 cmp rax,-1
 jne .type
 mov rax,[rel ls_cursor]
 mov [g135_object_names+rbx*8],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor eax,eax
 jmp .done
.type:
 mov eax,2
 jmp .done
.syntax:
 mov rax,-1
.done:
 pop rbx
 ret

; Parse Matrix<Int|Complex,R,C> or Vector<Int,N> into bounded local storage.
; EAX=0 success, -1 syntax, 1 shape, 2 type.
g135_parse_declaration:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,[rel g135_object_count]
 cmp rbx,G135_OBJECT_CAPACITY
 jae .shape
 mov rdi,[rel ls_cursor]
 lea rsi,[rel ls_n_matrix]
 mov edx,ls_n_matrix_len
 call ls_token_match
 test eax,eax
 jnz .matrix
 mov rdi,[rel ls_cursor]
 lea rsi,[rel ls_n_vector]
 mov edx,ls_n_vector_len
 call ls_token_match
 test eax,eax
 jz .syntax
 mov qword [rsp],G135_KIND_VECTOR
 jmp .kind_ready
.matrix:
 mov qword [rsp],G135_KIND_MATRIX
.kind_ready:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_current_atom
 test eax,eax
 jnz .dtype_int
 cmp qword [rsp],G135_KIND_MATRIX
 jne .type
 lea rsi,[rel g135_n_complex]
 mov edx,g135_n_complex_len
 call ls_current_atom
 test eax,eax
 jz .type
 mov qword [rsp+8],G135_DTYPE_COMPLEX
 jmp .dtype_ready
.dtype_int:
 mov qword [rsp+8],G135_DTYPE_INT
.dtype_ready:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .shape
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 mov r12,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test r12,r12
 jz .shape
 cmp r12,4
 ja .shape
 inc qword [rel ls_cursor]
 cmp qword [rsp],G135_KIND_VECTOR
 je .vector_extent
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .shape
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 mov r13,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test r13,r13
 jz .shape
 cmp r13,4
 ja .shape
 inc qword [rel ls_cursor]
 jmp .extent_ready
.vector_extent:
 mov r13,1
.extent_ready:
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,r12
 imul rax,r13
 jo .shape
 test rax,rax
 jz .shape
 cmp rax,4
 ja .shape
 mov r14,rax
 cmp qword [rsp+8],G135_DTYPE_COMPLEX
 jne .component_ready
 shl rax,1
.component_ready:
 mov [rsp+16],rax
 cmp rax,G135_COMPONENT_CAPACITY
 ja .shape
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov r15,rbx
 imul r15,G135_COMPONENT_CAPACITY
 xor ecx,ecx
.value_loop:
 cmp rcx,r14
 jae .values_done
 push rcx
 cmp qword [rsp+16],G135_DTYPE_COMPLEX ; original rsp+8 after push
 jne .int_value
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .value_syntax
 call ls_parse_signed_int
 test eax,eax
 jz .value_type
 pop rcx
 mov rax,rcx
 shl rax,1
 add rax,r15
 mov [g135_object_values+rax*8],rdx
 push rcx
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .value_syntax
 call ls_parse_signed_int
 test eax,eax
 jz .value_type
 pop rcx
 mov rax,rcx
 shl rax,1
 add rax,r15
 mov [g135_object_values+rax*8+8],rdx
 push rcx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .value_syntax
 pop rcx
 jmp .value_ready
.int_value:
 call ls_parse_signed_int
 test eax,eax
 jz .value_type
 pop rcx
 mov rax,r15
 add rax,rcx
 mov [g135_object_values+rax*8],rdx
.value_ready:
 inc rcx
 cmp rcx,r14
 jae .values_done
 push rcx
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .value_syntax
 pop rcx
 jmp .value_loop
.values_done:
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,rbx
 call g135_parse_binding
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .done
 mov rax,[rsp]
 mov [g135_object_kinds+rbx*8],rax
 mov rax,[rsp+8]
 mov [g135_object_dtypes+rbx*8],rax
 mov [g135_object_rows+rbx*8],r12
 mov [g135_object_cols+rbx*8],r13
 mov rax,[rsp+16]
 mov [g135_object_components+rbx*8],rax
 inc qword [rel g135_object_count]
 xor eax,eax
 jmp .done
.value_syntax:
 pop rcx
 jmp .syntax
.value_type:
 pop rcx
.type:
 mov eax,2
 jmp .done
.shape:
 mov eax,1
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Parse `(` signed-int `,` signed-int `)`, returning row in RDX and column
; in RCX.  Only non-negative indices are accepted by the bounded observers.
g135_parse_indices:
 push rbx
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov rbx,rdx
 test rbx,rbx
 js .bounds
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov rcx,rdx
 test rcx,rcx
 js .bounds
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdx,rbx
 xor eax,eax
 jmp .done
.bounds:
 mov eax,26
 jmp .done
.syntax:
 mov rax,-1
.done:
 pop rbx
 ret

; Exact transposed element observation: RDI object, RSI row, RDX column.
g135_transpose_at:
 cmp qword [g135_object_dtypes+rdi*8],G135_DTYPE_INT
 jne .type
 cmp rsi,[g135_object_cols+rdi*8]
 jae .bounds
 cmp rdx,[g135_object_rows+rdi*8]
 jae .bounds
 mov rax,rdx
 imul rax,[g135_object_cols+rdi*8]
 add rax,rsi
 imul rdi,G135_COMPONENT_CAPACITY
 add rdi,rax
 mov rdx,[g135_object_values+rdi*8]
 xor eax,eax
 ret
.type:
 mov eax,2
 xor edx,edx
 ret
.bounds:
 mov eax,26
 xor edx,edx
 ret

; Exact conjugate-transposed component: RDI object, RSI row, RDX column,
; RCX component (0 real, 1 imaginary).
g135_adjoint_at:
 cmp qword [g135_object_dtypes+rdi*8],G135_DTYPE_COMPLEX
 jne .type
 cmp rsi,[g135_object_cols+rdi*8]
 jae .bounds
 cmp rdx,[g135_object_rows+rdi*8]
 jae .bounds
 mov rax,rdx
 imul rax,[g135_object_cols+rdi*8]
 add rax,rsi
 shl rax,1
 add rax,rcx
 imul rdi,G135_COMPONENT_CAPACITY
 add rdi,rax
 mov rdx,[g135_object_values+rdi*8]
 test rcx,rcx
 jz .yes
 neg rdx
 jo .overflow
.yes:
 xor eax,eax
 ret
.type:
 mov eax,2
 xor edx,edx
 ret
.bounds:
 mov eax,26
 xor edx,edx
 ret
.overflow:
 mov eax,10
 xor edx,edx
 ret

; Compute exact 2x2 inverse observation.  RDI object, RSI observer kind
; (0 denominator, 1 numeratorAt), RDX row, RCX column.
g135_inverse_observe:
 push rbx
 push r12
 push r13
 sub rsp,16
 cmp qword [g135_object_dtypes+rdi*8],G135_DTYPE_INT
 jne .type
 cmp qword [g135_object_rows+rdi*8],2
 jne .shape
 cmp qword [g135_object_cols+rdi*8],2
 jne .shape
 mov rbx,rdi
 imul rbx,G135_COMPONENT_CAPACITY
 mov rax,[g135_object_values+rbx*8]
 imul rax,[g135_object_values+rbx*8+24]
 jo .overflow
 mov [rsp],rax
 mov rax,[g135_object_values+rbx*8+8]
 imul rax,[g135_object_values+rbx*8+16]
 jo .overflow
 sub [rsp],rax
 jo .overflow
 cmp qword [rsp],0
 je .singular
 test rsi,rsi
 jz .denominator
 cmp rdx,2
 jae .bounds
 cmp rcx,2
 jae .bounds
 lea rax,[rdx*2+rcx]
 cmp rax,0
 je .n0
 cmp rax,1
 je .n1
 cmp rax,2
 je .n2
 mov rdx,[g135_object_values+rbx*8]
 jmp .yes
.n0:
 mov rdx,[g135_object_values+rbx*8+24]
 jmp .yes
.n1:
 mov rdx,[g135_object_values+rbx*8+8]
 neg rdx
 jo .overflow
 jmp .yes
.n2:
 mov rdx,[g135_object_values+rbx*8+16]
 neg rdx
 jo .overflow
 jmp .yes
.denominator:
 mov rdx,[rsp]
.yes:
 xor eax,eax
 jmp .done
.type:
 mov eax,2
 jmp .zero
.shape:
 mov eax,25
 jmp .zero
.bounds:
 mov eax,26
 jmp .zero
.singular:
 mov eax,27
 jmp .zero
.overflow:
 mov eax,10
.zero:
 xor edx,edx
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; Exact checked inner product. RDI/RSI object indices -> RDX scalar.
g135_inner_product:
 push rbx
 push r12
 push r13
 push r14
 cmp qword [g135_object_dtypes+rdi*8],G135_DTYPE_INT
 jne .type
 cmp qword [g135_object_dtypes+rsi*8],G135_DTYPE_INT
 jne .type
 mov r12,[g135_object_rows+rdi*8]
 cmp r12,[g135_object_rows+rsi*8]
 jne .shape
 mov r13,[g135_object_cols+rdi*8]
 cmp r13,[g135_object_cols+rsi*8]
 jne .shape
 imul r12,r13
 mov rbx,rdi
 imul rbx,G135_COMPONENT_CAPACITY
 mov r13,rsi
 imul r13,G135_COMPONENT_CAPACITY
 xor r14d,r14d
 xor edx,edx
.loop:
 cmp r14,r12
 jae .yes
 mov rax,[g135_object_values+rbx*8]
 imul rax,[g135_object_values+r13*8]
 jo .overflow
 add rdx,rax
 jo .overflow
 inc rbx
 inc r13
 inc r14
 jmp .loop
.yes:
 xor eax,eax
 jmp .done
.type:
 mov eax,2
 jmp .zero
.shape:
 mov eax,25
 jmp .zero
.overflow:
 mov eax,10
.zero:
 xor edx,edx
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI non-negative exact square -> RDX root, otherwise diagnostic 28.
g135_exact_sqrt:
 push rbx
 push r12
 xor ebx,ebx
 mov r12,rdi
 mov rcx,3037000499
 cmp r12,rcx
 cmovb rcx,r12
.loop:
 cmp rbx,rcx
 ja .inexact
 lea r8,[rbx+rcx]
 shr r8,1
 mov rax,r8
 mul r8
 cmp rax,r12
 je .yes
 jb .low
 test r8,r8
 jz .inexact
 lea rcx,[r8-1]
 jmp .loop
.low:
 lea rbx,[r8+1]
 jmp .loop
.yes:
 mov rdx,r8
 xor eax,eax
 jmp .done
.inexact:
 mov eax,28
 xor edx,edx
.done:
 pop r12
 pop rbx
 ret

; Exact Euclidean norm for bounded Int values.
g135_norm:
 push rbx
 push r12
 push r13
 sub rsp,16
 cmp qword [g135_object_dtypes+rdi*8],G135_DTYPE_INT
 jne .type
 mov r12,[g135_object_components+rdi*8]
 mov rbx,rdi
 imul rbx,G135_COMPONENT_CAPACITY
 xor r13d,r13d
 mov qword [rsp],0
.loop:
 cmp r13,r12
 jae .root
 mov rax,[g135_object_values+rbx*8]
 imul rax,rax
 jo .overflow
 add [rsp],rax
 jo .overflow
 inc rbx
 inc r13
 jmp .loop
.root:
 mov rdi,[rsp]
 call g135_exact_sqrt
 jmp .done
.type:
 mov eax,2
 jmp .zero
.overflow:
 mov eax,10
.zero:
 xor edx,edx
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; Parse one symbolic or portable term and return its observed scalar in RDX.
g135_parse_term:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,32
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LINEAR_NORM_DELIMITER
 je .norm_delimited
 cmp eax,NEBOC_TOKEN_LINEAR_INNER_OPEN
 je .inner_delimited
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 call g135_find_object
 cmp rax,-1
 je .type
 mov r12,rax
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_MATRIX_TRANSPOSE
 je .symbol_transpose
 cmp eax,NEBOC_TOKEN_MATRIX_ADJOINT
 je .symbol_adjoint
 cmp eax,NEBOC_TOKEN_MATRIX_INVERSE
 je .symbol_inverse
 cmp eax,NEBOC_TOKEN_DOT
 jne .syntax
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_norm]
 mov edx,g135_n_norm_len
 call ls_token_match
 test eax,eax
 jnz .named_norm
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_inner_product]
 mov edx,g135_n_inner_product_len
 call ls_token_match
 test eax,eax
 jnz .named_inner
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_transpose]
 mov edx,g135_n_transpose_len
 call ls_token_match
 test eax,eax
 jnz .named_transpose
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_adjoint]
 mov edx,g135_n_adjoint_len
 call ls_token_match
 test eax,eax
 jnz .named_adjoint
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_inverse]
 mov edx,g135_n_inverse_len
 call ls_token_match
 test eax,eax
 jz .syntax
 mov r13d,G135_OP_INVERSE
 jmp .named_transform
.named_transpose:
 mov r13d,G135_OP_TRANSPOSE
 jmp .named_transform
.named_adjoint:
 mov r13d,G135_OP_ADJOINT
.named_transform:
 inc qword [rel ls_cursor]
 call .empty_call
 test eax,eax
 jnz .done
 jmp .observer
.symbol_transpose:
 mov r13d,G135_OP_TRANSPOSE
 inc qword [rel ls_cursor]
 jmp .observer
.symbol_adjoint:
 mov r13d,G135_OP_ADJOINT
 inc qword [rel ls_cursor]
 jmp .observer
.symbol_inverse:
 mov r13d,G135_OP_INVERSE
 inc qword [rel ls_cursor]
.observer:
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 cmp r13d,G135_OP_TRANSPOSE
 je .transpose_observer
 cmp r13d,G135_OP_ADJOINT
 je .adjoint_observer
 ; Inverse result observers expose the rational value without an implicit
 ; Result-to-value coercion.
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_denominator]
 mov edx,g135_n_denominator_len
 call ls_token_match
 test eax,eax
 jnz .inverse_denominator
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_numerator_at]
 mov edx,g135_n_numerator_at_len
 call ls_token_match
 test eax,eax
 jz .syntax
 inc qword [rel ls_cursor]
 call g135_parse_indices
 test eax,eax
 jnz .done
 mov rsi,1
 mov rdi,r12
 ; parse_indices returns row in RDX and column in RCX.
 call g135_inverse_observe
 jmp .done
.inverse_denominator:
 inc qword [rel ls_cursor]
 call .empty_call
 test eax,eax
 jnz .done
 mov rdi,r12
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call g135_inverse_observe
 jmp .done
.transpose_observer:
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_at]
 mov edx,g135_n_at_len
 call ls_token_match
 test eax,eax
 jz .syntax
 inc qword [rel ls_cursor]
 call g135_parse_indices
 test eax,eax
 jnz .done
 mov rsi,rdx
 mov rdx,rcx
 mov rdi,r12
 call g135_transpose_at
 jmp .done
.adjoint_observer:
 xor r14d,r14d
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_real_at]
 mov edx,g135_n_real_at_len
 call ls_token_match
 test eax,eax
 jnz .adjoint_name
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g135_n_imag_at]
 mov edx,g135_n_imag_at_len
 call ls_token_match
 test eax,eax
 jz .syntax
 mov r14d,1
.adjoint_name:
 inc qword [rel ls_cursor]
 call g135_parse_indices
 test eax,eax
 jnz .done
 mov rsi,rdx
 mov rdx,rcx
 mov rcx,r14
 mov rdi,r12
 call g135_adjoint_at
 jmp .done
.named_norm:
 inc qword [rel ls_cursor]
 call .empty_call
 test eax,eax
 jnz .done
 mov rdi,r12
 call g135_norm
 jmp .done
.named_inner:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call .object
 cmp rax,-1
 je .type
 mov r13,rax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov rsi,r13
 call g135_inner_product
 jmp .done
.norm_delimited:
 inc qword [rel ls_cursor]
 call .object
 cmp rax,-1
 je .type
 mov r12,rax
 mov edi,NEBOC_TOKEN_LINEAR_NORM_DELIMITER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,r12
 call g135_norm
 jmp .done
.inner_delimited:
 inc qword [rel ls_cursor]
 call .object
 cmp rax,-1
 je .type
 mov r12,rax
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call .object
 cmp rax,-1
 je .type
 mov r13,rax
 mov edi,NEBOC_TOKEN_LINEAR_INNER_CLOSE
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov rsi,r13
 call g135_inner_product
 jmp .done

; Local: empty argument list.
.empty_call:
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .local_syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .local_syntax
 xor eax,eax
 ret
.local_syntax:
 mov rax,-1
 ret

; Local: current identifier -> object index and advance, or -1.
.object:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .object_missing
 mov rdi,[rel ls_cursor]
 call g135_find_object
 cmp rax,-1
 je .object_missing
 inc qword [rel ls_cursor]
 ret
.object_missing:
 mov rax,-1
 ret
.type:
 mov eax,2
 xor edx,edx
 jmp .done
.syntax:
 mov rax,-1
 xor edx,edx
.done:
 add rsp,32
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Complete bounded G135 program: declarations and checked scalar observations
; joined by ordinary checked `+`.
g135_parse_program:
 push rbx
 sub rsp,16
 lea rdi,[rel g135_scratch_start]
 mov ecx,(g135_scratch_end-g135_scratch_start)/8
 xor eax,eax
 rep stosq
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
.declaration_loop:
 mov rdi,[rel ls_cursor]
 lea rsi,[rel ls_n_matrix]
 mov edx,ls_n_matrix_len
 call ls_token_match
 test eax,eax
 jnz .declaration
 mov rdi,[rel ls_cursor]
 lea rsi,[rel ls_n_vector]
 mov edx,ls_n_vector_len
 call ls_token_match
 test eax,eax
 jz .expression
.declaration:
 call g135_parse_declaration
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 jmp .declaration_loop
.expression:
 cmp qword [rel g135_object_count],1
 jb .type
 call g135_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
.plus_loop:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PLUS
 jne .finish
 inc qword [rel ls_cursor]
 call g135_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 add [rsp],rdx
 jo .overflow
 jmp .plus_loop
.finish:
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,G135_FAMILY_KEY
 call ls_success
 jmp .done
.semantic:
 call .record_error_token
 mov edi,eax
 call ls_error
 jmp .done
.type:
 call .record_error_token
 mov edi,2
 call ls_error
 jmp .done
.overflow:
 call .record_error_token
 mov edi,10
 call ls_error
 jmp .done
.syntax:
 call .record_error_token
 mov edi,24
 call ls_error
 jmp .done
; Local: publish a bounded causal token for all diagnostic serializers while
; preserving EAX (the semantic status selected by the caller).
.record_error_token:
 mov r8,rax
 mov rcx,[rel ls_cursor]
 cmp rcx,[rel ls_token_count]
 jb .error_token_ready
 mov rcx,[rel ls_token_count]
 test rcx,rcx
 jz .error_token_ready
 dec rcx
.error_token_ready:
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ERROR_TOKEN_OFFSET],rcx
 mov rax,r8
 ret
.done:
 add rsp,16
 pop rbx
 ret
