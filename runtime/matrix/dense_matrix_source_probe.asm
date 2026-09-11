; Source-to-effect conformance probe for the corrected G015 Matrix family.
; Every mode calls the production Matrix owners and checks independent,
; hand-derived observations before returning the source seed.
bits 64
default rel
%include "runtime/matrix/matrix_core.inc"
%include "runtime/matrix/matrix_ops.inc"
%include "runtime/matrix/matrix_mul.inc"
%include "runtime/matrix/matrix_lu.inc"
%include "runtime/matrix/matrix_factor.inc"

section .rodata
align 8
g15_zero: dq 0.0
g15_one: dq 1.0
g15_two: dq 2.0
g15_three: dq 3.0
g15_four: dq 4.0
g15_five: dq 5.0
g15_six: dq 6.0
g15_seven: dq 7.0
g15_eight: dq 8.0
g15_nine: dq 9.0
g15_ten: dq 10.0
g15_thirteen: dq 13.0
g15_twenty: dq 20.0
g15_ninety: dq 90.0
g15_ninetynine: dq 99.0
g15_onefiftyfour: dq 154.0
g15_threshold: dq 1.0e-12
g15_tolerance: dq 1.0e-10
g15_rows_source: dq 1.0,2.0,3.0,4.0,5.0,6.0
g15_views_source_tail: dq 2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0
g15_s03_a_tail: dq 2.0,3.0,4.0
g15_s03_b: dq 4.0,2.0,1.0,2.0
g15_s04_tail: dq 2.0,3.0,4.0,5.0,6.0
g15_s05_a_tail: dq 2.0,3.0,4.0,5.0,6.0
g15_s05_b: dq 7.0,8.0,9.0,10.0,11.0,12.0
g15_vector3: dq 1.0,2.0,3.0
g15_outer_x: dq 1.0,2.0
g15_outer_y: dq 3.0,4.0
g15_qr_a: dq 1.0,1.0,1.0,-1.0,1.0,1.0
g15_bad_spd: dq 1.0,2.0,2.0,1.0
g15_singular: dq 1.0,2.0,2.0,4.0
g15_zero_divisor: dq 1.0,0.0,1.0,1.0

section .data
align 8
g15_dynamic: dq 1.0
g15_views_source: dq 1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0
g15_s03_a: dq 1.0,2.0,3.0,4.0
g15_s04: dq 1.0,2.0,3.0,4.0,5.0,6.0
g15_s04_square: dq 1.0,2.0,3.0,4.0
g15_s05_a: dq 1.0,2.0,3.0,4.0,5.0,6.0
g15_s06_diag: dq 1.0,0.0,0.0,1.0
g15_rhs: dq 1.0,0.0
g15_map_context: dq 3.0

section .bss align=16
g15_d0: resb NEBO_MATRIX_SIZE
g15_d1: resb NEBO_MATRIX_SIZE
g15_d2: resb NEBO_MATRIX_SIZE
g15_d3: resb NEBO_MATRIX_SIZE
g15_d4: resb NEBO_MATRIX_SIZE
g15_d5: resb NEBO_MATRIX_SIZE
g15_d6: resb NEBO_MATRIX_SIZE
g15_d7: resb NEBO_MATRIX_SIZE
g15_d8: resb NEBO_MATRIX_SIZE
g15_p0: resq 64
g15_p1: resq 64
g15_p2: resq 64
g15_p3: resq 64
g15_p4: resq 64
g15_p5: resq 64
g15_p6: resq 64
g15_p7: resq 64
g15_p8: resq 64
g15_axis0: resq 8
g15_axis1: resq 8
g15_vector_out: resq 8
g15_solve_out: resq 8
g15_work: resq 1200
g15_pivots: resq 32

section .text
g15_close:
 subsd xmm0,xmm1
 movq rax,xmm0
 btr rax,63
 movq xmm0,rax
 ucomisd xmm0,[rel g15_tolerance]
 seta al
 movzx eax,al
 ret

; Positive seeds perturb actual Matrix data, so semantic variants cannot
; collapse to an exit-code-only path. Returns integer 1..8 in RAX.
g15_seed_base:
 mov eax,edi
 and eax,7
 inc eax
 ret

g15_map_add_context:
 addsd xmm0,[rdi]
 ret

g15_probe_s01:
 push r12
 mov r12d,edi
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_p0]
 mov edx,2
 mov ecx,3
 mov r8d,101
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 call nebo_matrix_rows
 test eax,eax
 jnz .bad
 cmp rdx,2
 jne .bad
 lea rdi,[rel g15_d0]
 call nebo_matrix_columns
 test eax,eax
 jnz .bad
 cmp rdx,3
 jne .bad
 lea rdi,[rel g15_d0]
 call nebo_matrix_layout
 test eax,eax
 jnz .bad
 cmp rdx,1
 jne .bad
 lea rdi,[rel g15_d1]
 lea rsi,[rel g15_p1]
 mov edx,2
 mov ecx,3
 mov r8d,102
 cvtsi2sd xmm0,r12d
 call nebo_matrix_filled_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d1]
 mov esi,1
 mov edx,2
 call nebo_matrix_at_f64
 test eax,eax
 jnz .bad
 cvtsi2sd xmm1,r12d
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_p2]
 lea rdx,[rel g15_rows_source]
 mov ecx,2
 mov r8d,3
 mov r9d,103
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 mov esi,1
 mov edx,2
 call nebo_matrix_at_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g15_six]
 jne .bad
 lea rdi,[rel g15_d3]
 lea rsi,[rel g15_p3]
 lea rdx,[rel g15_rows_source]
 mov ecx,3
 mov r8d,2
 mov r9d,104
 call nebo_matrix_from_buffer_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d3]
 call nebo_matrix_rows
 test eax,eax
 jnz .bad
 cmp rdx,3
 jne .bad
 xor eax,eax
 pop r12
 ret
.bad:
 mov eax,1
 pop r12
 ret

g15_probe_s02:
 push r12
 mov r12d,edi
 call g15_seed_base
 cvtsi2sd xmm0,eax
 movsd [rel g15_views_source],xmm0
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_p0]
 lea rdx,[rel g15_views_source]
 mov ecx,3
 mov r8d,3
 mov r9d,201
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 xor esi,esi
 xor edx,edx
 call nebo_matrix_at_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g15_views_source]
 jne .bad
 lea rdi,[rel g15_d0]
 mov esi,2
 mov edx,1
 call nebo_matrix_get_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g15_eight]
 jne .bad
 lea rdi,[rel g15_d1]
 lea rsi,[rel g15_d0]
 xor edx,edx
 call nebo_matrix_row_view
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d1]
 lea rsi,[rel g15_d0]
 call nebo_matrix_validate_view_owner
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 mov edx,1
 call nebo_matrix_column_view
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 mov esi,2
 xor edx,edx
 call nebo_matrix_at_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g15_eight]
 jne .bad
 lea rdi,[rel g15_d3]
 lea rsi,[rel g15_d0]
 mov edx,1
 mov ecx,2
 mov r8d,1
 mov r9d,2
 call nebo_matrix_slice_view
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d3]
 mov esi,1
 mov edx,1
 call nebo_matrix_at_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g15_nine]
 jne .bad
 lea rdi,[rel g15_d4]
 lea rsi,[rel g15_d0]
 call nebo_matrix_transpose_view
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d4]
 call nebo_matrix_layout
 test eax,eax
 jnz .bad
 cmp rdx,2
 jne .bad
 lea rdi,[rel g15_d5]
 lea rsi,[rel g15_p5]
 lea rdx,[rel g15_d4]
 mov ecx,205
 call nebo_matrix_contiguous_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d5]
 mov esi,1
 mov edx,2
 call nebo_matrix_at_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g15_eight]
 jne .bad
 xor eax,eax
 pop r12
 ret
.bad:
 mov eax,1
 pop r12
 ret

g15_probe_s03:
 push r12
 mov r12d,edi
 call g15_seed_base
 cvtsi2sd xmm0,eax
 movsd [rel g15_s03_a],xmm0
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_p0]
 lea rdx,[rel g15_s03_a]
 mov ecx,2
 mov r8d,2
 mov r9d,301
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d1]
 lea rsi,[rel g15_p1]
 lea rdx,[rel g15_s03_b]
 mov ecx,2
 mov r8d,2
 mov r9d,302
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_p2]
 mov edx,2
 mov ecx,2
 mov r8d,303
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_d1]
 mov ecx,NEBO_MATRIX_OP_ADD
 call nebo_matrix_elementwise_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p2]
 movsd xmm1,[rel g15_s03_a]
 addsd xmm1,[rel g15_four]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_d1]
 mov ecx,NEBO_MATRIX_OP_SUB
 call nebo_matrix_elementwise_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p2]
 movsd xmm1,[rel g15_s03_a]
 subsd xmm1,[rel g15_four]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_d1]
 mov ecx,NEBO_MATRIX_OP_MUL
 call nebo_matrix_elementwise_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p2]
 movsd xmm1,[rel g15_s03_a]
 mulsd xmm1,[rel g15_four]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_d1]
 mov ecx,NEBO_MATRIX_OP_DIV
 call nebo_matrix_elementwise_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p2]
 movsd xmm1,[rel g15_s03_a]
 divsd xmm1,[rel g15_four]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 movsd xmm0,[rel g15_two]
 call nebo_matrix_scale_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p2]
 movsd xmm1,[rel g15_s03_a]
 mulsd xmm1,[rel g15_two]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_map_add_context]
 lea rcx,[rel g15_map_context]
 call nebo_matrix_map_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p2]
 movsd xmm1,[rel g15_s03_a]
 addsd xmm1,[rel g15_three]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 movsd xmm0,[rel g15_zero]
 movsd xmm1,[rel g15_five]
 call nebo_matrix_clamp_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p2]
 movsd xmm1,[rel g15_s03_a]
 minsd xmm1,[rel g15_five]
 ucomisd xmm0,xmm1
 jne .bad
 xor eax,eax
 pop r12
 ret
.bad:
 mov eax,1
 pop r12
 ret

g15_probe_s04:
 push r12
 mov r12d,edi
 call g15_seed_base
 cvtsi2sd xmm0,eax
 movsd [rel g15_s04],xmm0
 movsd [rel g15_s04_square],xmm0
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_p0]
 lea rdx,[rel g15_s04]
 mov ecx,2
 mov r8d,3
 mov r9d,401
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 mov esi,NEBO_MATRIX_REDUCE_SUM
 call nebo_matrix_reduce_f64
 test eax,eax
 jnz .bad
 movsd xmm1,[rel g15_s04]
 addsd xmm1,[rel g15_twenty]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d0]
 mov esi,NEBO_MATRIX_REDUCE_SUM
 xor edx,edx
 lea rcx,[rel g15_axis0]
 mov r8d,3
 call nebo_matrix_reduce_axis_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_axis0]
 movsd xmm1,[rel g15_s04]
 addsd xmm1,[rel g15_four]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d0]
 mov esi,NEBO_MATRIX_REDUCE_MEAN
 mov edx,1
 lea rcx,[rel g15_axis1]
 mov r8d,2
 call nebo_matrix_reduce_axis_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_s04]
 addsd xmm0,[rel g15_five]
 divsd xmm0,[rel g15_three]
 movsd xmm1,[rel g15_axis1]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d0]
 mov esi,NEBO_MATRIX_REDUCE_MIN
 xor edx,edx
 lea rcx,[rel g15_axis0]
 mov r8d,3
 call nebo_matrix_reduce_axis_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_s04]
 minsd xmm0,[rel g15_four]
 ucomisd xmm0,[rel g15_axis0]
 jne .bad
 lea rdi,[rel g15_d0]
 mov esi,NEBO_MATRIX_REDUCE_MAX
 mov edx,1
 lea rcx,[rel g15_axis1]
 mov r8d,2
 call nebo_matrix_reduce_axis_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_axis1+8]
 ucomisd xmm0,[rel g15_six]
 jne .bad
 lea rdi,[rel g15_d1]
 lea rsi,[rel g15_p1]
 lea rdx,[rel g15_s04_square]
 mov ecx,2
 mov r8d,2
 mov r9d,402
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d1]
 call nebo_matrix_trace_f64
 test eax,eax
 jnz .bad
 movsd xmm1,[rel g15_s04_square]
 addsd xmm1,[rel g15_four]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d1]
 call nebo_matrix_is_square
 test eax,eax
 jnz .bad
 cmp rdx,1
 jne .bad
 lea rdi,[rel g15_d0]
 call nebo_matrix_is_square
 test eax,eax
 jnz .bad
 test rdx,rdx
 jnz .bad
 xor eax,eax
 pop r12
 ret
.bad:
 mov eax,1
 pop r12
 ret

g15_probe_s05:
 push r12
 mov r12d,edi
 call g15_seed_base
 cvtsi2sd xmm0,eax
 movsd [rel g15_s05_a],xmm0
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_p0]
 lea rdx,[rel g15_s05_a]
 mov ecx,2
 mov r8d,3
 mov r9d,501
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d1]
 lea rsi,[rel g15_p1]
 lea rdx,[rel g15_s05_b]
 mov ecx,3
 mov r8d,2
 mov r9d,502
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_p2]
 mov edx,2
 mov ecx,2
 mov r8d,503
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_d1]
 call nebo_matrix_matmul_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_s05_a]
 mulsd xmm0,[rel g15_seven]
 movsd xmm1,[rel g15_p2]
 subsd xmm1,xmm0
 movsd xmm0,xmm1
 mov rax,0x4049800000000000 ; 51.0
 movq xmm1,rax
 call g15_close
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_vector_out]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_vector3]
 mov ecx,3
 call nebo_matrix_matvec_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_vector_out]
 movsd xmm1,[rel g15_s05_a]
 addsd xmm1,[rel g15_thirteen]
 ucomisd xmm0,xmm1
 jne .bad
 lea rdi,[rel g15_d3]
 lea rsi,[rel g15_p3]
 mov edx,2
 mov ecx,2
 mov r8d,504
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d3]
 lea rsi,[rel g15_outer_x]
 mov edx,2
 lea rcx,[rel g15_outer_y]
 mov r8d,2
 call nebo_matrix_outer_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p3+24]
 ucomisd xmm0,[rel g15_eight]
 jne .bad
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_d0]
 call nebo_matrix_dot_flattened_f64
 test eax,eax
 jnz .bad
 movsd xmm1,[rel g15_s05_a]
 mulsd xmm1,xmm1
 addsd xmm1,[rel g15_ninety]
 ucomisd xmm0,xmm1
 jne .bad
 mov rax,0x4058c00000000000
 mov [rel g15_p3],rax
 lea rdi,[rel g15_d3]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_d1]
 call nebo_matrix_batched_matmul_f64
 cmp eax,NEBO_NUMERIC_ERROR_UNSUPPORTED
 jne .bad
 mov rax,[rel g15_p3]
 mov rdx,0x4058c00000000000
 cmp rax,rdx
 jne .bad
 lea rdi,[rel g15_d4]
 lea rsi,[rel g15_p4]
 mov edx,2
 mov ecx,2
 mov r8d,505
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d4]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_d1]
 call nebo_matrix_matmul_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_p4+24]
 ucomisd xmm0,[rel g15_onefiftyfour]
 jne .bad
 xor eax,eax
 pop r12
 ret
.bad:
 mov eax,1
 pop r12
 ret

g15_probe_s06:
 push r12
 mov r12d,edi
 mov eax,edi
 and eax,3
 inc eax
 cvtsi2sd xmm0,eax
 movsd [rel g15_s06_diag],xmm0
 movsd [rel g15_dynamic],xmm0
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_p0]
 lea rdx,[rel g15_s06_diag]
 mov ecx,2
 mov r8d,2
 mov r9d,601
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_work]
 lea rdx,[rel g15_pivots]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_lu_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_work]
 lea rdx,[rel g15_pivots]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_determinant_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g15_dynamic]
 jne .bad
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_rhs]
 lea rdx,[rel g15_solve_out]
 lea rcx,[rel g15_work]
 lea r8,[rel g15_pivots]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_solve_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_one]
 divsd xmm0,[rel g15_dynamic]
 movsd xmm1,[rel g15_solve_out]
 call g15_close
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d1]
 lea rsi,[rel g15_p1]
 mov edx,2
 mov ecx,2
 mov r8d,602
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_d1]
 lea rdx,[rel g15_work]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_inverse_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_one]
 divsd xmm0,[rel g15_dynamic]
 movsd xmm1,[rel g15_p1]
 call g15_close
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_p2]
 lea rdx,[rel g15_qr_a]
 mov ecx,3
 mov r8d,2
 mov r9d,603
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d3]
 lea rsi,[rel g15_p3]
 mov edx,3
 mov ecx,2
 mov r8d,604
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d4]
 lea rsi,[rel g15_p4]
 mov edx,2
 mov ecx,2
 mov r8d,605
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d3]
 lea rdx,[rel g15_d4]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_qr_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d5]
 lea rsi,[rel g15_p5]
 mov edx,2
 mov ecx,2
 mov r8d,606
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_d5]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_cholesky_f64
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g15_dynamic]
 sqrtsd xmm0,xmm0
 movsd xmm1,[rel g15_p5]
 call g15_close
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d6]
 lea rsi,[rel g15_p6]
 mov edx,2
 mov ecx,2
 mov r8d,607
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_d6]
 lea rdx,[rel g15_work]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_condition_estimate_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g15_dynamic]
 jne .bad
 xor eax,eax
 pop r12
 ret
.bad:
 mov eax,1
 pop r12
 ret

global nebo_g015_negative_probe
nebo_g015_negative_probe:
 sub rsp,8
 ; Empty multiplication is a defined no-op: (0x1) @ (1x0) -> (0x0).
 lea rdi,[rel g15_d5]
 lea rsi,[rel g15_p5]
 xor edx,edx
 xor ecx,ecx
 mov r8d,1
 mov r9d,706
 call nebo_matrix_from_buffer_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d6]
 lea rsi,[rel g15_p6]
 xor edx,edx
 mov ecx,1
 xor r8d,r8d
 mov r9d,707
 call nebo_matrix_from_buffer_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d7]
 lea rsi,[rel g15_p7]
 xor edx,edx
 xor ecx,ecx
 mov r8d,708
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d7]
 lea rsi,[rel g15_d5]
 lea rdx,[rel g15_d6]
 call nebo_matrix_matmul_f64
 test eax,eax
 jnz .bad
 ; Extents above the frozen bound fail before descriptor publication.
 lea rdi,[rel g15_d8]
 lea rsi,[rel g15_p8]
 mov edx,NEBO_MATRIX_MAX_ROWS+1
 mov ecx,1
 mov r8d,709
 call nebo_matrix_zeros_f64
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .bad
 ; Bounds rejection through the same checked getter.
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_p0]
 lea rdx,[rel g15_singular]
 mov ecx,2
 mov r8d,2
 mov r9d,701
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d0]
 mov esi,2
 xor edx,edx
 call nebo_matrix_get_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .bad
 ; Divide-by-zero preflight must not mutate output.
 lea rdi,[rel g15_d1]
 lea rsi,[rel g15_p1]
 lea rdx,[rel g15_zero_divisor]
 mov ecx,2
 mov r8d,2
 mov r9d,702
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_p2]
 mov edx,2
 mov ecx,2
 mov r8d,703
 movsd xmm0,[rel g15_ninetynine]
 call nebo_matrix_filled_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d2]
 lea rsi,[rel g15_d0]
 lea rdx,[rel g15_d1]
 mov ecx,NEBO_MATRIX_OP_DIV
 call nebo_matrix_elementwise_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .bad
 movsd xmm0,[rel g15_p2]
 ucomisd xmm0,[rel g15_ninetynine]
 jne .bad
 ; Axis output shape is checked before publication.
 lea rdi,[rel g15_d0]
 mov esi,NEBO_MATRIX_REDUCE_SUM
 xor edx,edx
 lea rcx,[rel g15_axis0]
 mov r8d,1
 call nebo_matrix_reduce_axis_f64
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .bad
 ; Singular decomposition is explicit.
 lea rdi,[rel g15_d0]
 lea rsi,[rel g15_work]
 lea rdx,[rel g15_pivots]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_determinant_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .bad
 ; Non-SPD Cholesky is rejected.
 lea rdi,[rel g15_d3]
 lea rsi,[rel g15_p3]
 lea rdx,[rel g15_bad_spd]
 mov ecx,2
 mov r8d,2
 mov r9d,704
 call nebo_matrix_from_rows_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d4]
 lea rsi,[rel g15_p4]
 mov edx,2
 mov ecx,2
 mov r8d,705
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .bad
 lea rdi,[rel g15_d3]
 lea rsi,[rel g15_d4]
 movsd xmm0,[rel g15_threshold]
 call nebo_matrix_cholesky_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .bad
 xor eax,eax
 add rsp,8
 ret
.bad:
 mov eax,1
 add rsp,8
 ret

global nebo_g015_source_probe
nebo_g015_source_probe:
 push rbx
 push r12
 push r13
 mov r12d,edi
 mov r13d,esi
 test r13d,r13d
 jz .bad
 mov edi,r13d
 cmp r12d,1
 je .s01
 cmp r12d,2
 je .s02
 cmp r12d,3
 je .s03
 cmp r12d,4
 je .s04
 cmp r12d,5
 je .s05
 cmp r12d,6
 je .s06
 jmp .bad
.s01: call g15_probe_s01
 jmp .checked
.s02: call g15_probe_s02
 jmp .checked
.s03: call g15_probe_s03
 jmp .checked
.s04: call g15_probe_s04
 jmp .checked
.s05: call g15_probe_s05
 jmp .checked
.s06: call g15_probe_s06
.checked:
 test eax,eax
 jnz .bad
 mov eax,r13d
 jmp .done
.bad:
 mov eax,1
.done:
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
