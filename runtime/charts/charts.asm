; CONTROLO-DE-FLUXO-ESTRUTURADO-F08 bounded line/scatter/bar/histogram charts over F06 Canvas.
bits 64
default rel
%define NEBO_CHARTS_IMPLEMENTATION 1
%include "runtime/charts/charts.inc"

section .rodata align=16
chart_zero: dq 0.0
chart_one: dq 1.0
chart_half: dq 0.5
align 16
chart_abs_mask: dq 0x7fffffffffffffff,0

section .text

global nebo_chart_init
global nebo_chart_validate
global nebo_chart_line
global nebo_chart_scatter
global nebo_chart_bar
global nebo_chart_histogram
global nebo_chart_title
global nebo_chart_axis
global nebo_chart_legend
global nebo_chart_render
global nebo_chart_close

; ---------------------------------------------------------------------------
; Small internal helpers
; ---------------------------------------------------------------------------

; rdi=ptr, rcx=qwords.
chart_zero_qwords:
    xor eax,eax
    rep stosq
    ret

; rdi=ptr1,rsi=size1,rdx=ptr2,rcx=size2 -> eax=1 overlap/wrap,0 disjoint.
chart_ranges_overlap:
    test rdi,rdi
    jz .overlap
    test rdx,rdx
    jz .overlap
    mov r8,rdi
    add r8,rsi
    jc .overlap
    mov r9,rdx
    add r9,rcx
    jc .overlap
    cmp rdi,r9
    jae .disjoint
    cmp rdx,r8
    jae .disjoint
.overlap:
    mov eax,1
    ret
.disjoint:
    xor eax,eax
    ret

; Strict canonical UTF-8 decoder. rdi=data,rsi=remaining -> r8=scalar,r9=bytes,eax=status.
chart_utf8_next:
    test rdi,rdi
    jz .bad
    test rsi,rsi
    jz .bad
    movzx eax,byte [rdi]
    cmp eax,0x80
    jb .one
    cmp eax,0xc2
    jb .bad
    cmp eax,0xdf
    jbe .two
    cmp eax,0xef
    jbe .three
    cmp eax,0xf4
    jbe .four
    jmp .bad
.one:
    mov r8d,eax
    mov r9d,1
    xor eax,eax
    ret
.two:
    cmp rsi,2
    jb .bad
    movzx edx,byte [rdi+1]
    mov ecx,edx
    and ecx,0xc0
    cmp ecx,0x80
    jne .bad
    and eax,0x1f
    shl eax,6
    and edx,0x3f
    or eax,edx
    mov r8d,eax
    mov r9d,2
    xor eax,eax
    ret
.three:
    cmp rsi,3
    jb .bad
    movzx edx,byte [rdi+1]
    movzx ecx,byte [rdi+2]
    mov r10d,edx
    and r10d,0xc0
    cmp r10d,0x80
    jne .bad
    mov r10d,ecx
    and r10d,0xc0
    cmp r10d,0x80
    jne .bad
    cmp eax,0xe0
    jne .three_not_e0
    cmp edx,0xa0
    jb .bad
.three_not_e0:
    cmp eax,0xed
    jne .three_ready
    cmp edx,0xa0
    jae .bad
.three_ready:
    and eax,0x0f
    shl eax,12
    and edx,0x3f
    shl edx,6
    and ecx,0x3f
    or eax,edx
    or eax,ecx
    mov r8d,eax
    mov r9d,3
    xor eax,eax
    ret
.four:
    cmp rsi,4
    jb .bad
    movzx edx,byte [rdi+1]
    movzx ecx,byte [rdi+2]
    movzx r10d,byte [rdi+3]
    mov r11d,edx
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    mov r11d,ecx
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    mov r11d,r10d
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    cmp eax,0xf0
    jne .four_not_f0
    cmp edx,0x90
    jb .bad
.four_not_f0:
    cmp eax,0xf4
    jne .four_ready
    cmp edx,0x90
    jae .bad
.four_ready:
    and eax,0x07
    shl eax,18
    and edx,0x3f
    shl edx,12
    and ecx,0x3f
    shl ecx,6
    and r10d,0x3f
    or eax,edx
    or eax,ecx
    or eax,r10d
    cmp eax,0x10ffff
    ja .bad
    mov r8d,eax
    mov r9d,4
    xor eax,eax
    ret
.bad:
    mov eax,NEBO_CHART_ERROR_INVALID_UTF8
    xor r8d,r8d
    xor r9d,r9d
    ret

; rdi=data,rsi=len -> eax=status. Empty is valid; callers decide whether required.
chart_validate_utf8:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r13,r13
    jz .ok
    test r12,r12
    jz .invalid
    xor ebx,ebx
.loop:
    cmp rbx,r13
    jae .ok
    lea rdi,[r12+rbx]
    mov rsi,r13
    sub rsi,rbx
    call chart_utf8_next
    test eax,eax
    jnz .return
    add rbx,r9
    jmp .loop
.ok:
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_CHART_ERROR_INVALID_ARGUMENT
.return:
    pop r13
    pop r12
    pop rbx
    ret

; rdi=chart,esi=status,edx=error. Records only when magic is valid.
chart_record_status:
    mov eax,esi
    test rdi,rdi
    jz .return
    test rdi,7
    jnz .return
    mov r8,NEBO_CHART_MAGIC
    cmp [rdi+NEBO_CHART_MAGIC_OFFSET],r8
    jne .return
    mov [rdi+NEBO_CHART_LAST_STATUS_OFFSET],rsi
    mov [rdi+NEBO_CHART_LAST_ERROR_OFFSET],rdx
.return:
    ret

; rdi=chart -> eax=status. Active and closed descriptors are structurally valid.
chart_validate_common:
    test rdi,rdi
    jz .invalid
    test rdi,7
    jnz .invalid
    mov rax,NEBO_CHART_MAGIC
    cmp [rdi+NEBO_CHART_MAGIC_OFFSET],rax
    jne .bad_state
    mov eax,[rdi+NEBO_CHART_STATE_OFFSET]
    cmp eax,NEBO_CHART_STATE_ACTIVE
    je .state_ok
    cmp eax,NEBO_CHART_STATE_CLOSED
    jne .bad_state
.state_ok:
    mov eax,[rdi+NEBO_CHART_FLAGS_OFFSET]
    mov ecx,eax
    and ecx,~NEBO_CHART_KNOWN_FLAGS
    jnz .bad_state
    mov rax,[rdi+NEBO_CHART_SERIES_PTR_OFFSET]
    test rax,rax
    jz .invalid
    test rax,7
    jnz .invalid
    mov rcx,[rdi+NEBO_CHART_SERIES_CAPACITY_OFFSET]
    cmp rcx,1
    jb .limit
    cmp rcx,NEBO_CHART_MAX_SERIES
    ja .limit
    mov rdx,[rdi+NEBO_CHART_SERIES_COUNT_OFFSET]
    cmp rdx,rcx
    ja .bad_state
    cmp qword [rdi+NEBO_CHART_TOTAL_POINTS_OFFSET],NEBO_CHART_MAX_TOTAL_POINTS
    ja .bad_state
    mov r8,[rdi+NEBO_CHART_X_TICKS_OFFSET]
    cmp r8,NEBO_CHART_MIN_TICKS
    jb .bad_state
    cmp r8,NEBO_CHART_MAX_TICKS
    ja .bad_state
    mov r8,[rdi+NEBO_CHART_Y_TICKS_OFFSET]
    cmp r8,NEBO_CHART_MIN_TICKS
    jb .bad_state
    cmp r8,NEBO_CHART_MAX_TICKS
    ja .bad_state
    mov eax,[rdi+NEBO_CHART_X_AXIS_FLAGS_OFFSET]
    and eax,~NEBO_CHART_AXIS_KNOWN_FLAGS
    jnz .bad_state
    mov eax,[rdi+NEBO_CHART_Y_AXIS_FLAGS_OFFSET]
    and eax,~NEBO_CHART_AXIS_KNOWN_FLAGS
    jnz .bad_state
    mov rax,[rdi+NEBO_CHART_LEGEND_FLAGS_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_CHART_LEGEND_KNOWN_FLAGS
    jnz .bad_state
    test rax,NEBO_CHART_LEGEND_FLAG_ENABLED
    jz .legend_ok
    mov rax,[rdi+NEBO_CHART_LEGEND_MAX_ENTRIES_OFFSET]
    cmp rax,1
    jb .bad_state
    cmp rax,NEBO_CHART_MAX_LEGEND_ENTRIES
    ja .bad_state
.legend_ok:
    cmp qword [rdi+NEBO_CHART_RESERVED0_OFFSET],0
    jne .bad_state
    cmp qword [rdi+NEBO_CHART_RESERVED1_OFFSET],0
    jne .bad_state
    cmp qword [rdi+NEBO_CHART_RESERVED2_OFFSET],0
    jne .bad_state
    cmp qword [rdi+NEBO_CHART_RESERVED3_OFFSET],0
    jne .bad_state
    cmp qword [rdi+NEBO_CHART_RESERVED4_OFFSET],0
    jne .bad_state
    cmp qword [rdi+NEBO_CHART_RESERVED5_OFFSET],0
    jne .bad_state
    mov rax,[rdi+NEBO_CHART_SERIES_CAPACITY_OFFSET]
    imul rax,NEBO_CHART_SERIES_SIZE
    mov rdx,[rdi+NEBO_CHART_SERIES_PTR_OFFSET]
    mov r8,rdx
    add r8,rax
    jc .invalid
    mov r9,rdi
    add r9,NEBO_CHART_SIZE
    jc .invalid
    cmp rdi,r8
    jae .ranges_ok
    cmp rdx,r9
    jb .overlap
.ranges_ok:
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_CHART_ERROR_INVALID_ARGUMENT
    ret
.bad_state:
    mov eax,NEBO_CHART_ERROR_BAD_STATE
    ret
.limit:
    mov eax,NEBO_CHART_ERROR_LIMIT_EXCEEDED
    ret
.overlap:
    mov eax,NEBO_CHART_ERROR_STORAGE_OVERLAP
    ret

chart_require_active:
    sub rsp,8
    call chart_validate_common
    add rsp,8
    test eax,eax
    jnz .return
    cmp dword [rdi+NEBO_CHART_STATE_OFFSET],NEBO_CHART_STATE_ACTIVE
    jne .closed
    xor eax,eax
.return:
    ret
.closed:
    mov eax,NEBO_CHART_ERROR_CLOSED
    ret

; rdi=series,rsi=index,edx=axis(0=x,1=y) -> xmm0. Series is prevalidated.
chart_series_value:
    cmp dword [rdi+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_MATRIX
    je .matrix
    test edx,edx
    jnz .array_y
    test dword [rdi+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    jnz .auto_index
    mov rax,[rdi+NEBO_CHART_SERIES_X_STRIDE_OFFSET]
    imul rax,rsi
    mov rcx,[rdi+NEBO_CHART_SERIES_X_PTR_OFFSET]
    movsd xmm0,[rcx+rax*8]
    ret
.array_y:
    mov rax,[rdi+NEBO_CHART_SERIES_Y_STRIDE_OFFSET]
    imul rax,rsi
    mov rcx,[rdi+NEBO_CHART_SERIES_Y_PTR_OFFSET]
    movsd xmm0,[rcx+rax*8]
    ret
.matrix:
    test edx,edx
    jnz .matrix_y
    test dword [rdi+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    jnz .auto_index
    mov rdx,[rdi+NEBO_CHART_SERIES_X_COLUMN_OFFSET]
    jmp .matrix_load
.matrix_y:
    mov rdx,[rdi+NEBO_CHART_SERIES_Y_COLUMN_OFFSET]
.matrix_load:
    mov rcx,[rdi+NEBO_CHART_SERIES_MATRIX_PTR_OFFSET]
    mov rax,rsi
    imul rax,[rcx+NEBO_MATRIX_ROW_STRIDE]
    mov r8,rdx
    imul r8,[rcx+NEBO_MATRIX_COL_STRIDE]
    add rax,r8
    mov rcx,[rcx+NEBO_MATRIX_DATA]
    movsd xmm0,[rcx+rax*8]
    ret
.auto_index:
    cvtsi2sd xmm0,rsi
    ret

; xmm0=value -> eax=0 finite, chart nonfinite error otherwise.
chart_require_finite:
    sub rsp,8
    call nebo_float_classify_f64
    add rsp,8
    test eax,NEBO_FLOAT_FINITE
    jz .bad
    xor eax,eax
    ret
.bad:
    mov eax,NEBO_CHART_ERROR_NONFINITE_DATA
    ret

; rdi=ptr,rsi=count,rdx=stride -> eax=status. Elements are f64.
chart_validate_f64_range:
    test rdi,rdi
    jz .invalid
    test rdi,7
    jnz .invalid
    test rsi,rsi
    jz .empty
    cmp rsi,NEBO_CHART_MAX_POINTS
    ja .limit
    cmp rdx,1
    jb .invalid
    cmp rdx,NEBO_CHART_MAX_POINTS
    ja .limit
    mov rax,rsi
    dec rax
    mul rdx
    test rdx,rdx
    jnz .limit
    inc rax
    jc .limit
    shl rax,3
    jc .limit
    add rax,rdi
    jc .invalid
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_CHART_ERROR_INVALID_ARGUMENT
    ret
.empty:
    mov eax,NEBO_CHART_ERROR_EMPTY_DATA
    ret
.limit:
    mov eax,NEBO_CHART_ERROR_LIMIT_EXCEEDED
    ret

; rdi=spec,edx=kind -> eax=status,r8=actual count.
; Performs source, UTF-8, finite-data and category validation without mutation.
chart_validate_series_spec:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    mov r13d,edx
    xor r8d,r8d
    test r12,r12
    jz .invalid
    test r12,7
    jnz .invalid
    cmp r13d,NEBO_CHART_KIND_LINE
    jb .invalid_source
    cmp r13d,NEBO_CHART_KIND_HISTOGRAM
    ja .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_RESERVED0_OFFSET],0
    jne .invalid
    cmp qword [r12+NEBO_CHART_SERIES_RESERVED1_OFFSET],0
    jne .invalid
    mov eax,[r12+NEBO_CHART_SERIES_FLAGS_OFFSET]
    and eax,~NEBO_CHART_SERIES_KNOWN_FLAGS
    jnz .invalid_source
    mov rdi,[r12+NEBO_CHART_SERIES_LABEL_PTR_OFFSET]
    mov rsi,[r12+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET]
    cmp rsi,1
    jb .utf8
    cmp rsi,NEBO_CHART_MAX_SERIES_LABEL_BYTES
    ja .utf8
    call chart_validate_utf8
    test eax,eax
    jnz .utf8
    mov rax,[r12+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET]
    cmp r13d,NEBO_CHART_KIND_SCATTER
    je .radius_required
    cmp r13d,NEBO_CHART_KIND_LINE
    jne .radius_zero
    test dword [r12+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_SHOW_POINTS
    jz .radius_zero
.radius_required:
    cmp rax,NEBO_CHART_POINT_RADIUS_MIN
    jb .limit
    cmp rax,NEBO_CHART_POINT_RADIUS_MAX
    ja .limit
    jmp .source
.radius_zero:
    test rax,rax
    jnz .invalid_source
.source:
    mov eax,[r12+NEBO_CHART_SERIES_SOURCE_OFFSET]
    cmp eax,NEBO_CHART_SOURCE_ARRAY
    je .array
    cmp eax,NEBO_CHART_SOURCE_MATRIX
    je .matrix
    jmp .invalid_source
.array:
    cmp qword [r12+NEBO_CHART_SERIES_MATRIX_PTR_OFFSET],0
    jne .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_X_COLUMN_OFFSET],0
    jne .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_Y_COLUMN_OFFSET],0
    jne .invalid_source
    mov r14,[r12+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    test r14,r14
    jz .empty
    cmp r14,NEBO_CHART_MAX_POINTS
    ja .limit
    cmp r13d,NEBO_CHART_KIND_LINE
    jne .array_count_ok
    cmp r14,2
    jb .empty
.array_count_ok:
    mov rdi,[r12+NEBO_CHART_SERIES_Y_PTR_OFFSET]
    mov rsi,r14
    mov rdx,[r12+NEBO_CHART_SERIES_Y_STRIDE_OFFSET]
    call chart_validate_f64_range
    test eax,eax
    jnz .return
    cmp r13d,NEBO_CHART_KIND_LINE
    je .array_x_policy
    cmp r13d,NEBO_CHART_KIND_SCATTER
    je .array_x_policy
    test dword [r12+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    jz .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_X_PTR_OFFSET],0
    jne .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_X_STRIDE_OFFSET],0
    jne .invalid_source
    jmp .array_ready
.array_x_policy:
    test dword [r12+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    jnz .array_auto_x
    mov rdi,[r12+NEBO_CHART_SERIES_X_PTR_OFFSET]
    mov rsi,r14
    mov rdx,[r12+NEBO_CHART_SERIES_X_STRIDE_OFFSET]
    call chart_validate_f64_range
    test eax,eax
    jnz .return
    jmp .array_ready
.array_auto_x:
    cmp qword [r12+NEBO_CHART_SERIES_X_PTR_OFFSET],0
    jne .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_X_STRIDE_OFFSET],0
    jne .invalid_source
.array_ready:
    mov r8,r14
    jmp .kind_specific
.matrix:
    cmp qword [r12+NEBO_CHART_SERIES_X_PTR_OFFSET],0
    jne .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_Y_PTR_OFFSET],0
    jne .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_X_STRIDE_OFFSET],0
    jne .invalid_source
    cmp qword [r12+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],0
    jne .invalid_source
    mov rdi,[r12+NEBO_CHART_SERIES_MATRIX_PTR_OFFSET]
    test rdi,rdi
    jz .matrix_error
    call nebo_matrix_validate
    test eax,eax
    jnz .matrix_error
    mov rbx,[r12+NEBO_CHART_SERIES_MATRIX_PTR_OFFSET]
    cmp qword [rbx+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
    jne .matrix_error
    mov r14,[rbx+NEBO_MATRIX_ROWS]
    test r14,r14
    jz .empty
    cmp r14,NEBO_CHART_MAX_POINTS
    ja .limit
    cmp r13d,NEBO_CHART_KIND_LINE
    jne .matrix_count_ok
    cmp r14,2
    jb .empty
.matrix_count_ok:
    mov rax,[r12+NEBO_CHART_SERIES_Y_COLUMN_OFFSET]
    cmp rax,[rbx+NEBO_MATRIX_COLS]
    jae .matrix_error
    cmp r13d,NEBO_CHART_KIND_LINE
    je .matrix_x_policy
    cmp r13d,NEBO_CHART_KIND_SCATTER
    je .matrix_x_policy
    test dword [r12+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    jz .invalid_source
    mov rax,[r12+NEBO_CHART_SERIES_X_COLUMN_OFFSET]
    cmp rax,NEBO_CHART_AUTO_COLUMN
    jne .invalid_source
    jmp .matrix_ready
.matrix_x_policy:
    test dword [r12+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    jnz .matrix_auto_x
    mov rax,[r12+NEBO_CHART_SERIES_X_COLUMN_OFFSET]
    cmp rax,[rbx+NEBO_MATRIX_COLS]
    jae .matrix_error
    jmp .matrix_ready
.matrix_auto_x:
    mov rax,[r12+NEBO_CHART_SERIES_X_COLUMN_OFFSET]
    cmp rax,NEBO_CHART_AUTO_COLUMN
    jne .invalid_source
.matrix_ready:
    mov r8,r14
.kind_specific:
    cmp r13d,NEBO_CHART_KIND_BAR
    jne .not_bar
    mov rdi,[r12+NEBO_CHART_SERIES_CATEGORIES_PTR_OFFSET]
    test rdi,rdi
    jz .category
    test rdi,7
    jnz .category
    cmp [r12+NEBO_CHART_SERIES_CATEGORY_COUNT_OFFSET],r8
    jne .category
    mov rax,r8
    shl rax,4
    jc .category
    add rax,rdi
    jc .category
    xor r15d,r15d
.category_loop:
    cmp r15,r8
    jae .categories_ok
    mov rax,r15
    shl rax,4
    mov rbx,[rdi+rax+NEBO_CHART_STRING_PTR_OFFSET]
    mov r14,[rdi+rax+NEBO_CHART_STRING_LENGTH_OFFSET]
    cmp r14,1
    jb .category
    cmp r14,NEBO_CHART_MAX_CATEGORY_BYTES
    ja .category
    mov [rsp],rdi
    mov [rsp+8],r8
    mov rdi,rbx
    mov rsi,r14
    call chart_validate_utf8
    mov rdi,[rsp]
    mov r8,[rsp+8]
    test eax,eax
    jnz .category
    inc r15
    jmp .category_loop
.categories_ok:
    cmp qword [r12+NEBO_CHART_SERIES_BINS_OFFSET],0
    jne .invalid_bins
    jmp .scan
.not_bar:
    cmp qword [r12+NEBO_CHART_SERIES_CATEGORIES_PTR_OFFSET],0
    jne .category
    cmp qword [r12+NEBO_CHART_SERIES_CATEGORY_COUNT_OFFSET],0
    jne .category
    cmp r13d,NEBO_CHART_KIND_HISTOGRAM
    jne .not_hist
    mov rax,[r12+NEBO_CHART_SERIES_BINS_OFFSET]
    cmp rax,1
    jb .invalid_bins
    cmp rax,NEBO_CHART_MAX_BINS
    ja .invalid_bins
    jmp .scan
.not_hist:
    cmp qword [r12+NEBO_CHART_SERIES_BINS_OFFSET],0
    jne .invalid_bins
.scan:
    mov [rsp+16],r8
    xor r15d,r15d
.scan_loop:
    cmp r15,[rsp+16]
    jae .ok
    mov rdi,r12
    mov rsi,r15
    mov edx,1
    call chart_series_value
    call chart_require_finite
    test eax,eax
    jnz .return_count
    cmp r13d,NEBO_CHART_KIND_LINE
    je .scan_x
    cmp r13d,NEBO_CHART_KIND_SCATTER
    jne .next
.scan_x:
    mov rdi,r12
    mov rsi,r15
    xor edx,edx
    call chart_series_value
    call chart_require_finite
    test eax,eax
    jnz .return_count
.next:
    inc r15
    jmp .scan_loop
.ok:
    mov r8,[rsp+16]
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_CHART_ERROR_INVALID_ARGUMENT
    jmp .return
.invalid_source:
    mov eax,NEBO_CHART_ERROR_INVALID_SOURCE
    jmp .return
.matrix_error:
    mov eax,NEBO_CHART_ERROR_MATRIX
    jmp .return
.utf8:
    mov eax,NEBO_CHART_ERROR_INVALID_UTF8
    jmp .return
.category:
    mov eax,NEBO_CHART_ERROR_CATEGORY_MISMATCH
    jmp .return
.invalid_bins:
    mov eax,NEBO_CHART_ERROR_INVALID_BINS
    jmp .return
.empty:
    mov eax,NEBO_CHART_ERROR_EMPTY_DATA
    jmp .return
.limit:
    mov eax,NEBO_CHART_ERROR_LIMIT_EXCEEDED
    jmp .return
.return_count:
    mov r8,[rsp+16]
.return:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; rdi=chart,rsi=spec,edx=kind.
chart_add_common:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14d,edx
    call chart_require_active
    test eax,eax
    jnz .record_error
    mov rdi,r13
    mov edx,r14d
    call chart_validate_series_spec
    test eax,eax
    jnz .record_error
    mov r15,r8
    mov rax,[r12+NEBO_CHART_TOTAL_POINTS_OFFSET]
    add rax,r15
    jc .limit
    cmp rax,NEBO_CHART_MAX_TOTAL_POINTS
    ja .limit
    mov rbx,[r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    cmp rbx,[r12+NEBO_CHART_SERIES_CAPACITY_OFFSET]
    jae .full
    imul rbx,NEBO_CHART_SERIES_SIZE
    add rbx,[r12+NEBO_CHART_SERIES_PTR_OFFSET]
    mov rdi,rbx
    mov rsi,r13
    mov ecx,NEBO_CHART_SERIES_QWORDS
    cld
    rep movsq
    mov [rbx+NEBO_CHART_SERIES_KIND_OFFSET],r14d
    mov [rbx+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],r15
    inc qword [r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    mov [r12+NEBO_CHART_TOTAL_POINTS_OFFSET],rax
    and dword [r12+NEBO_CHART_FLAGS_OFFSET],~NEBO_CHART_FLAG_RENDERED
    xor eax,eax
    xor edx,edx
    mov rdi,r12
    xor esi,esi
    call chart_record_status
    jmp .return
.limit:
    mov eax,NEBO_CHART_ERROR_LIMIT_EXCEEDED
    jmp .record_error
.full:
    mov eax,NEBO_CHART_ERROR_SERIES_FULL
.record_error:
    mov edx,eax
    mov esi,eax
    mov rdi,r12
    call chart_record_status
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Bounds helper: xmm0 value, rdi=min*,rsi=max*,rdx=initialized*.
chart_bounds_update:
    cmp qword [rdx],0
    jne .existing
    movsd [rdi],xmm0
    movsd [rsi],xmm0
    mov qword [rdx],1
    ret
.existing:
    ucomisd xmm0,[rdi]
    jae .not_min
    movsd [rdi],xmm0
.not_min:
    ucomisd xmm0,[rsi]
    jbe .done
    movsd [rsi],xmm0
.done:
    ret

; xmm0=value,xmm1=min,xmm2=max,rdi=start,rsi=span -> rax mapped coordinate.
; Uses scale-normalized arithmetic to avoid max-min overflow for large finite values.
chart_map_value:
    ucomisd xmm1,xmm2
    jne .normal
    mov rax,rsi
    shr rax,1
    add rax,rdi
    ret
.normal:
    movapd xmm3,xmm0
    andpd xmm3,[rel chart_abs_mask]
    movapd xmm4,xmm1
    andpd xmm4,[rel chart_abs_mask]
    maxsd xmm3,xmm4
    movapd xmm4,xmm2
    andpd xmm4,[rel chart_abs_mask]
    maxsd xmm3,xmm4
    ucomisd xmm3,[rel chart_zero]
    je .center
    divsd xmm0,xmm3
    divsd xmm1,xmm3
    divsd xmm2,xmm3
    subsd xmm0,xmm1
    subsd xmm2,xmm1
    divsd xmm0,xmm2
    maxsd xmm0,[rel chart_zero]
    minsd xmm0,[rel chart_one]
    cvtsi2sd xmm1,rsi
    mulsd xmm0,xmm1
    addsd xmm0,[rel chart_half]
    cvttsd2si rax,xmm0
    add rax,rdi
    ret
.center:
    mov rax,rsi
    shr rax,1
    add rax,rdi
    ret

; xmm0=value,xmm1=min,xmm2=max,rdi=bins -> rax bin [0,bins-1].
chart_value_to_bin:
    ucomisd xmm1,xmm2
    jne .normal
    xor eax,eax
    ret
.normal:
    movapd xmm3,xmm0
    andpd xmm3,[rel chart_abs_mask]
    movapd xmm4,xmm1
    andpd xmm4,[rel chart_abs_mask]
    maxsd xmm3,xmm4
    movapd xmm4,xmm2
    andpd xmm4,[rel chart_abs_mask]
    maxsd xmm3,xmm4
    ucomisd xmm3,[rel chart_zero]
    je .zero
    divsd xmm0,xmm3
    divsd xmm1,xmm3
    divsd xmm2,xmm3
    subsd xmm0,xmm1
    subsd xmm2,xmm1
    divsd xmm0,xmm2
    maxsd xmm0,[rel chart_zero]
    minsd xmm0,[rel chart_one]
    cvtsi2sd xmm1,rdi
    mulsd xmm0,xmm1
    cvttsd2si rax,xmm0
    cmp rax,rdi
    jb .done
    mov rax,rdi
    dec rax
.done:
    ret
.zero:
    xor eax,eax
    ret

; Canvas wrappers create a 16-byte Paint on the aligned stack.
; line(canvas,x0,y0,x1,y1,color)
chart_draw_line:
    sub rsp,24
    mov [rsp+0],r9d
    mov dword [rsp+4],NEBO_CANVAS_PAINT_MODE_STROKE
    mov dword [rsp+8],1
    mov dword [rsp+12],0
    mov r9,rsp
    call nebo_canvas_line
    add rsp,24
    ret

; rect fill(canvas,x,y,w,h,color)
chart_draw_rect_fill:
    sub rsp,24
    mov [rsp+0],r9d
    mov dword [rsp+4],NEBO_CANVAS_PAINT_MODE_FILL
    mov dword [rsp+8],1
    mov dword [rsp+12],0
    mov r9,rsp
    call nebo_canvas_rectangle
    add rsp,24
    ret

; rect stroke(canvas,x,y,w,h,color)
chart_draw_rect_stroke:
    sub rsp,24
    mov [rsp+0],r9d
    mov dword [rsp+4],NEBO_CANVAS_PAINT_MODE_STROKE
    mov dword [rsp+8],1
    mov dword [rsp+12],0
    mov r9,rsp
    call nebo_canvas_rectangle
    add rsp,24
    ret

; circle fill(canvas,cx,cy,radius,color)
chart_draw_circle_fill:
    sub rsp,24
    mov [rsp+0],r8d
    mov dword [rsp+4],NEBO_CANVAS_PAINT_MODE_FILL
    mov dword [rsp+8],1
    mov dword [rsp+12],0
    mov r8,rsp
    call nebo_canvas_circle
    add rsp,24
    ret

; text(canvas,ptr,len,x,y,color)
chart_draw_text:
    sub rsp,24
    mov [rsp+0],r9d
    mov dword [rsp+4],NEBO_CANVAS_PAINT_MODE_FILL
    mov dword [rsp+8],1
    mov dword [rsp+12],0
    mov r9,rsp
    call nebo_canvas_text
    add rsp,24
    ret

; ---------------------------------------------------------------------------
; Public lifecycle and configuration
; ---------------------------------------------------------------------------

; init(chart*,series_storage*,capacity,owner_context)
nebo_chart_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    test r12,r12
    jz .invalid
    test r12,7
    jnz .invalid
    test r13,r13
    jz .invalid
    test r13,7
    jnz .invalid
    cmp r14,1
    jb .limit
    cmp r14,NEBO_CHART_MAX_SERIES
    ja .limit
    test r15,r15
    jz .owner
    mov rax,r14
    imul rax,NEBO_CHART_SERIES_SIZE
    mov rdi,r12
    mov rsi,NEBO_CHART_SIZE
    mov rdx,r13
    mov rcx,rax
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r12
    mov ecx,NEBO_CHART_QWORDS
    call chart_zero_qwords
    mov rdi,r13
    mov rax,r14
    imul rax,NEBO_CHART_SERIES_QWORDS
    mov rcx,rax
    call chart_zero_qwords
    mov [r12+NEBO_CHART_SERIES_PTR_OFFSET],r13
    mov [r12+NEBO_CHART_SERIES_CAPACITY_OFFSET],r14
    mov dword [r12+NEBO_CHART_STATE_OFFSET],NEBO_CHART_STATE_ACTIVE
    mov [r12+NEBO_CHART_OWNER_CONTEXT_OFFSET],r15
    mov dword [r12+NEBO_CHART_X_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    mov dword [r12+NEBO_CHART_Y_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    mov qword [r12+NEBO_CHART_X_TICKS_OFFSET],5
    mov qword [r12+NEBO_CHART_Y_TICKS_OFFSET],5
    mov dword [r12+NEBO_CHART_BACKGROUND_RGBA_OFFSET],0x101820ff
    mov dword [r12+NEBO_CHART_PLOT_RGBA_OFFSET],0x182430ff
    mov dword [r12+NEBO_CHART_AXIS_RGBA_OFFSET],0xc0d0e0ff
    mov dword [r12+NEBO_CHART_GRID_RGBA_OFFSET],0x405060ff
    mov dword [r12+NEBO_CHART_TEXT_RGBA_OFFSET],0xffffffff
    mov dword [r12+NEBO_CHART_LEGEND_RGBA_OFFSET],0x202830ff
    mov rax,NEBO_CHART_MAGIC
    mov [r12+NEBO_CHART_MAGIC_OFFSET],rax
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_CHART_ERROR_INVALID_ARGUMENT
    jmp .return
.limit:
    mov eax,NEBO_CHART_ERROR_LIMIT_EXCEEDED
    jmp .return
.owner:
    mov eax,NEBO_CHART_ERROR_OWNER_MISMATCH
    jmp .return
.overlap:
    mov eax,NEBO_CHART_ERROR_STORAGE_OVERLAP
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_chart_validate:
    jmp chart_validate_common

nebo_chart_line:
    mov edx,NEBO_CHART_KIND_LINE
    jmp chart_add_common

nebo_chart_scatter:
    mov edx,NEBO_CHART_KIND_SCATTER
    jmp chart_add_common

nebo_chart_bar:
    mov edx,NEBO_CHART_KIND_BAR
    jmp chart_add_common

nebo_chart_histogram:
    mov edx,NEBO_CHART_KIND_HISTOGRAM
    jmp chart_add_common

; title(chart*,utf8*,length)
nebo_chart_title:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rbx,rdx
    call chart_require_active
    test eax,eax
    jnz .error
    cmp rbx,1
    jb .utf8
    cmp rbx,NEBO_CHART_MAX_TEXT_BYTES
    ja .utf8
    mov rdi,r13
    mov rsi,rbx
    call chart_validate_utf8
    test eax,eax
    jnz .utf8
    mov [r12+NEBO_CHART_TITLE_PTR_OFFSET],r13
    mov [r12+NEBO_CHART_TITLE_LENGTH_OFFSET],rbx
    or dword [r12+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_TITLE
    and dword [r12+NEBO_CHART_FLAGS_OFFSET],~NEBO_CHART_FLAG_RENDERED
    xor eax,eax
    jmp .record
.utf8:
    mov eax,NEBO_CHART_ERROR_INVALID_UTF8
.error:
.record:
    mov edx,eax
    mov esi,eax
    mov rdi,r12
    call chart_record_status
    pop r13
    pop r12
    pop rbx
    ret

; axis(chart*,axis_options*)
nebo_chart_axis:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    call chart_require_active
    test eax,eax
    jnz .record
    test r13,r13
    jz .invalid
    test r13,7
    jnz .invalid
    cmp qword [r13+NEBO_CHART_AXIS_RESERVED0_OFFSET],0
    jne .invalid
    cmp qword [r13+NEBO_CHART_AXIS_RESERVED1_OFFSET],0
    jne .invalid
    mov ebx,[r13+NEBO_CHART_AXIS_ID_OFFSET]
    cmp ebx,NEBO_CHART_AXIS_X
    je .axis_ok
    cmp ebx,NEBO_CHART_AXIS_Y
    jne .invalid
.axis_ok:
    mov r14d,[r13+NEBO_CHART_AXIS_FLAGS_OFFSET]
    mov eax,r14d
    and eax,~NEBO_CHART_AXIS_KNOWN_FLAGS
    jnz .invalid
    mov r15,[r13+NEBO_CHART_AXIS_TICKS_OFFSET]
    cmp r15,NEBO_CHART_MIN_TICKS
    jb .limit
    cmp r15,NEBO_CHART_MAX_TICKS
    ja .limit
    mov rdi,[r13+NEBO_CHART_AXIS_LABEL_PTR_OFFSET]
    mov rsi,[r13+NEBO_CHART_AXIS_LABEL_LENGTH_OFFSET]
    cmp rsi,NEBO_CHART_MAX_TEXT_BYTES
    ja .utf8
    test rsi,rsi
    jz .range
    call chart_validate_utf8
    test eax,eax
    jnz .utf8
.range:
    test r14d,NEBO_CHART_AXIS_FLAG_MANUAL_RANGE
    jz .store
    movsd xmm0,[r13+NEBO_CHART_AXIS_MIN_OFFSET]
    call chart_require_finite
    test eax,eax
    jnz .range_error
    movsd xmm0,[r13+NEBO_CHART_AXIS_MAX_OFFSET]
    call chart_require_finite
    test eax,eax
    jnz .range_error
    movsd xmm0,[r13+NEBO_CHART_AXIS_MIN_OFFSET]
    ucomisd xmm0,[r13+NEBO_CHART_AXIS_MAX_OFFSET]
    jae .range_error
.store:
    cmp ebx,NEBO_CHART_AXIS_X
    jne .store_y
    mov [r12+NEBO_CHART_X_AXIS_FLAGS_OFFSET],r14d
    mov [r12+NEBO_CHART_X_TICKS_OFFSET],r15
    mov rax,[r13+NEBO_CHART_AXIS_LABEL_PTR_OFFSET]
    mov [r12+NEBO_CHART_X_LABEL_PTR_OFFSET],rax
    mov rax,[r13+NEBO_CHART_AXIS_LABEL_LENGTH_OFFSET]
    mov [r12+NEBO_CHART_X_LABEL_LENGTH_OFFSET],rax
    mov rax,[r13+NEBO_CHART_AXIS_MIN_OFFSET]
    mov [r12+NEBO_CHART_X_MIN_OFFSET],rax
    mov rax,[r13+NEBO_CHART_AXIS_MAX_OFFSET]
    mov [r12+NEBO_CHART_X_MAX_OFFSET],rax
    or dword [r12+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_X_AXIS
    jmp .success
.store_y:
    mov [r12+NEBO_CHART_Y_AXIS_FLAGS_OFFSET],r14d
    mov [r12+NEBO_CHART_Y_TICKS_OFFSET],r15
    mov rax,[r13+NEBO_CHART_AXIS_LABEL_PTR_OFFSET]
    mov [r12+NEBO_CHART_Y_LABEL_PTR_OFFSET],rax
    mov rax,[r13+NEBO_CHART_AXIS_LABEL_LENGTH_OFFSET]
    mov [r12+NEBO_CHART_Y_LABEL_LENGTH_OFFSET],rax
    mov rax,[r13+NEBO_CHART_AXIS_MIN_OFFSET]
    mov [r12+NEBO_CHART_Y_MIN_OFFSET],rax
    mov rax,[r13+NEBO_CHART_AXIS_MAX_OFFSET]
    mov [r12+NEBO_CHART_Y_MAX_OFFSET],rax
    or dword [r12+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_Y_AXIS
.success:
    and dword [r12+NEBO_CHART_FLAGS_OFFSET],~NEBO_CHART_FLAG_RENDERED
    xor eax,eax
    jmp .record
.invalid:
    mov eax,NEBO_CHART_ERROR_INVALID_ARGUMENT
    jmp .record
.limit:
    mov eax,NEBO_CHART_ERROR_LIMIT_EXCEEDED
    jmp .record
.utf8:
    mov eax,NEBO_CHART_ERROR_INVALID_UTF8
    jmp .record
.range_error:
    mov eax,NEBO_CHART_ERROR_INVALID_RANGE
.record:
    mov edx,eax
    mov esi,eax
    mov rdi,r12
    call chart_record_status
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; legend(chart*,legend_options*)
nebo_chart_legend:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    call chart_require_active
    test eax,eax
    jnz .record
    test r13,r13
    jz .invalid
    test r13,7
    jnz .invalid
    cmp dword [r13+NEBO_CHART_LEGEND_RESERVED32_OFFSET],0
    jne .invalid
    cmp qword [r13+NEBO_CHART_LEGEND_RESERVED64_OFFSET],0
    jne .invalid
    mov ebx,[r13+NEBO_CHART_LEGEND_OPTIONS_FLAGS_OFFSET]
    mov eax,ebx
    and eax,~NEBO_CHART_LEGEND_KNOWN_FLAGS
    jnz .invalid
    test ebx,NEBO_CHART_LEGEND_FLAG_ENABLED
    jz .disable
    mov rax,[r13+NEBO_CHART_LEGEND_MAX_OFFSET]
    cmp rax,1
    jb .limit
    cmp rax,NEBO_CHART_MAX_LEGEND_ENTRIES
    ja .limit
    cmp qword [r13+NEBO_CHART_LEGEND_POSITION_OFFSET],NEBO_CHART_LEGEND_TOP_RIGHT
    jne .unsupported
    mov [r12+NEBO_CHART_LEGEND_FLAGS_OFFSET],rbx
    mov [r12+NEBO_CHART_LEGEND_MAX_ENTRIES_OFFSET],rax
    or dword [r12+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_LEGEND
    jmp .success
.disable:
    cmp qword [r13+NEBO_CHART_LEGEND_MAX_OFFSET],0
    jne .invalid
    cmp qword [r13+NEBO_CHART_LEGEND_POSITION_OFFSET],0
    jne .invalid
    mov qword [r12+NEBO_CHART_LEGEND_FLAGS_OFFSET],0
    mov qword [r12+NEBO_CHART_LEGEND_MAX_ENTRIES_OFFSET],0
    and dword [r12+NEBO_CHART_FLAGS_OFFSET],~NEBO_CHART_FLAG_LEGEND
.success:
    and dword [r12+NEBO_CHART_FLAGS_OFFSET],~NEBO_CHART_FLAG_RENDERED
    xor eax,eax
    jmp .record
.invalid:
    mov eax,NEBO_CHART_ERROR_INVALID_ARGUMENT
    jmp .record
.limit:
    mov eax,NEBO_CHART_ERROR_LIMIT_EXCEEDED
    jmp .record
.unsupported:
    mov eax,NEBO_CHART_ERROR_UNSUPPORTED
.record:
    mov edx,eax
    mov esi,eax
    mov rdi,r12
    call chart_record_status
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------------------------
; Rendering
; ---------------------------------------------------------------------------

; Local frame offsets below rbp. Saved registers occupy -8..-40.
%define CR_XMIN -48
%define CR_XMAX -56
%define CR_YMIN -64
%define CR_YMAX -72
%define CR_XINIT -80
%define CR_YINIT -88
%define CR_COMMAND_EST -96
%define CR_CANVAS_BEFORE -104
%define CR_LEFT -112
%define CR_TOP -120
%define CR_PLOT_W -128
%define CR_PLOT_H -136
%define CR_CANVAS_W -144
%define CR_CANVAS_H -152
%define CR_SERIES_INDEX -160
%define CR_POINT_INDEX -168
%define CR_PREV_X -176
%define CR_PREV_Y -184
%define CR_TEMP0 -192
%define CR_TEMP1 -200
%define CR_HIST_MIN -208
%define CR_HIST_MAX -216
%define CR_HIST_INIT -224
%define CR_RENDER_RESULT_HASH -232
%define CR_ZERO_COORD -240
%define CR_TEMP2 -248
%define CR_TEMP3 -256
%define CR_TEMP4 -264
%define CR_TEMP5 -272
%define CR_TEMP6 -280
%define CR_TEMP7 -288
%define CR_TEMP8 -296
%define CR_TEMP9 -304

; render(chart*,canvas*,result*)
nebo_chart_render:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,264
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    call chart_require_active
    test eax,eax
    jnz .record_error
    test r14,r14
    jz .invalid
    test r14,7
    jnz .invalid
    mov rdi,r13
    call nebo_canvas_validate
    test eax,eax
    jnz .render_failure

    ; Chart, series, result, Canvas descriptor, pixel storage and command
    ; storage are independent caller-owned regions. Reject every cross-object
    ; overlap before the first Canvas mutation so render remains failure atomic.
    mov rax,[r12+NEBO_CHART_SERIES_CAPACITY_OFFSET]
    imul rax,NEBO_CHART_SERIES_SIZE
    mov [rbp+CR_TEMP7],rax
    mov rax,[r13+NEBO_CANVAS_COMMAND_CAPACITY_OFFSET]
    shl rax,6
    jc .overlap
    mov [rbp+CR_TEMP8],rax

    ; result versus Chart/series/Canvas/pixels/commands
    mov rdi,r14
    mov rsi,NEBO_CHART_RESULT_SIZE
    mov rdx,r12
    mov rcx,NEBO_CHART_SIZE
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r14
    mov rsi,NEBO_CHART_RESULT_SIZE
    mov rdx,[r12+NEBO_CHART_SERIES_PTR_OFFSET]
    mov rcx,[rbp+CR_TEMP7]
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r14
    mov rsi,NEBO_CHART_RESULT_SIZE
    mov rdx,r13
    mov rcx,NEBO_CANVAS_SIZE
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r14
    mov rsi,NEBO_CHART_RESULT_SIZE
    mov rdx,[r13+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov rcx,[r13+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET]
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r14
    mov rsi,NEBO_CHART_RESULT_SIZE
    mov rdx,[r13+NEBO_CANVAS_COMMANDS_PTR_OFFSET]
    mov rcx,[rbp+CR_TEMP8]
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap

    ; Chart descriptor versus Canvas descriptor/pixels/commands
    mov rdi,r12
    mov rsi,NEBO_CHART_SIZE
    mov rdx,r13
    mov rcx,NEBO_CANVAS_SIZE
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r12
    mov rsi,NEBO_CHART_SIZE
    mov rdx,[r13+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov rcx,[r13+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET]
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r12
    mov rsi,NEBO_CHART_SIZE
    mov rdx,[r13+NEBO_CANVAS_COMMANDS_PTR_OFFSET]
    mov rcx,[rbp+CR_TEMP8]
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap

    ; Series storage versus Canvas descriptor/pixels/commands
    mov rdi,[r12+NEBO_CHART_SERIES_PTR_OFFSET]
    mov rsi,[rbp+CR_TEMP7]
    mov rdx,r13
    mov rcx,NEBO_CANVAS_SIZE
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,[r12+NEBO_CHART_SERIES_PTR_OFFSET]
    mov rsi,[rbp+CR_TEMP7]
    mov rdx,[r13+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov rcx,[r13+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET]
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,[r12+NEBO_CHART_SERIES_PTR_OFFSET]
    mov rsi,[rbp+CR_TEMP7]
    mov rdx,[r13+NEBO_CANVAS_COMMANDS_PTR_OFFSET]
    mov rcx,[rbp+CR_TEMP8]
    call chart_ranges_overlap
    test eax,eax
    jnz .overlap

    cmp dword [r13+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
    jne .render_failure
    mov rax,[r13+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    mov [rbp+CR_CANVAS_W],rax
    cmp rax,NEBO_CHART_MIN_CANVAS_WIDTH
    jb .canvas_size
    mov rax,[r13+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    mov [rbp+CR_CANVAS_H],rax
    cmp rax,NEBO_CHART_MIN_CANVAS_HEIGHT
    jb .canvas_size
    mov rax,[r13+NEBO_CANVAS_OWNER_CONTEXT_OFFSET]
    test rax,rax
    jz .owner_preflight_ok
    cmp rax,[r12+NEBO_CHART_OWNER_CONTEXT_OFFSET]
    jne .owner
.owner_preflight_ok:
    ; Borrowed presentation text is revalidated on every render so later caller
    ; mutation cannot turn a preflight-success into a partial Canvas failure.
    test dword [r12+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_TITLE
    jz .render_x_label_preflight
    mov rdi,[r12+NEBO_CHART_TITLE_PTR_OFFSET]
    mov rsi,[r12+NEBO_CHART_TITLE_LENGTH_OFFSET]
    call chart_validate_utf8
    test eax,eax
    jnz .utf8
.render_x_label_preflight:
    mov rsi,[r12+NEBO_CHART_X_LABEL_LENGTH_OFFSET]
    test rsi,rsi
    jz .render_y_label_preflight
    mov rdi,[r12+NEBO_CHART_X_LABEL_PTR_OFFSET]
    call chart_validate_utf8
    test eax,eax
    jnz .utf8
.render_y_label_preflight:
    mov rsi,[r12+NEBO_CHART_Y_LABEL_LENGTH_OFFSET]
    test rsi,rsi
    jz .render_text_preflight_done
    mov rdi,[r12+NEBO_CHART_Y_LABEL_PTR_OFFSET]
    call chart_validate_utf8
    test eax,eax
    jnz .utf8
.render_text_preflight_done:
    mov rax,[r12+NEBO_CHART_LEGEND_FLAGS_OFFSET]
    test rax,NEBO_CHART_LEGEND_FLAG_ENABLED
    jz .legend_preflight_ok
    mov rax,[r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    cmp rax,[r12+NEBO_CHART_LEGEND_MAX_ENTRIES_OFFSET]
    ja .limit
.legend_preflight_ok:
    cmp qword [r12+NEBO_CHART_RENDER_GENERATION_OFFSET],-1
    je .limit
    mov qword [rbp+CR_XINIT],0
    mov qword [rbp+CR_YINIT],0
    mov qword [rbp+CR_TEMP5],0       ; recomputed total point count
    mov qword [rbp+CR_COMMAND_EST],4 ; clear, plot fill, x axis, y axis
    mov rax,[r12+NEBO_CHART_X_TICKS_OFFSET]
    add [rbp+CR_COMMAND_EST],rax      ; tick marks
    test dword [r12+NEBO_CHART_X_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    jz .no_x_grid_est
    add [rbp+CR_COMMAND_EST],rax
.no_x_grid_est:
    mov rax,[r12+NEBO_CHART_Y_TICKS_OFFSET]
    add [rbp+CR_COMMAND_EST],rax
    test dword [r12+NEBO_CHART_Y_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    jz .no_y_grid_est
    add [rbp+CR_COMMAND_EST],rax
.no_y_grid_est:
    test dword [r12+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_TITLE
    jz .no_title_est
    inc qword [rbp+CR_COMMAND_EST]
.no_title_est:
    cmp qword [r12+NEBO_CHART_X_LABEL_LENGTH_OFFSET],0
    je .no_x_label_est
    inc qword [rbp+CR_COMMAND_EST]
.no_x_label_est:
    cmp qword [r12+NEBO_CHART_Y_LABEL_LENGTH_OFFSET],0
    je .no_y_label_est
    inc qword [rbp+CR_COMMAND_EST]
.no_y_label_est:
    xor ebx,ebx
.preflight_series_loop:
    cmp rbx,[r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    jae .preflight_series_done
    mov r15,rbx
    imul r15,NEBO_CHART_SERIES_SIZE
    add r15,[r12+NEBO_CHART_SERIES_PTR_OFFSET]
    mov rdi,r15
    mov edx,[r15+NEBO_CHART_SERIES_KIND_OFFSET]
    call chart_validate_series_spec
    test eax,eax
    jnz .record_error
    mov rax,[r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    cmp rax,r8
    jne .bad_state
    mov [rbp+CR_TEMP6],r8
    add [rbp+CR_TEMP5],r8
    jc .bad_state
    cmp qword [rbp+CR_TEMP5],NEBO_CHART_MAX_TOTAL_POINTS
    ja .bad_state
    mov eax,[r15+NEBO_CHART_SERIES_KIND_OFFSET]
    cmp eax,NEBO_CHART_KIND_LINE
    je .estimate_line
    cmp eax,NEBO_CHART_KIND_SCATTER
    je .estimate_scatter
    cmp eax,NEBO_CHART_KIND_BAR
    je .estimate_bar
    cmp eax,NEBO_CHART_KIND_HISTOGRAM
    je .estimate_hist
    jmp .bad_state
.estimate_line:
    mov rax,[rbp+CR_TEMP6]
    dec rax
    add [rbp+CR_COMMAND_EST],rax
    test dword [r15+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_SHOW_POINTS
    jz .bounds_line_scatter
    mov rax,[rbp+CR_TEMP6]
    add [rbp+CR_COMMAND_EST],rax
    jmp .bounds_line_scatter
.estimate_scatter:
    mov rax,[rbp+CR_TEMP6]
    add [rbp+CR_COMMAND_EST],rax
.bounds_line_scatter:
    xor ecx,ecx
.bounds_xy_loop:
    cmp rcx,[rbp+CR_TEMP6]
    jae .next_series
    mov [rbp+CR_POINT_INDEX],rcx
    mov rdi,r15
    mov rsi,rcx
    xor edx,edx
    call chart_series_value
    lea rdi,[rbp+CR_XMIN]
    lea rsi,[rbp+CR_XMAX]
    lea rdx,[rbp+CR_XINIT]
    call chart_bounds_update
    mov rcx,[rbp+CR_POINT_INDEX]
    mov rdi,r15
    mov rsi,rcx
    mov edx,1
    call chart_series_value
    lea rdi,[rbp+CR_YMIN]
    lea rsi,[rbp+CR_YMAX]
    lea rdx,[rbp+CR_YINIT]
    call chart_bounds_update
    mov rcx,[rbp+CR_POINT_INDEX]
    inc rcx
    jmp .bounds_xy_loop
.estimate_bar:
    mov rax,[rbp+CR_TEMP6]
    add [rbp+CR_COMMAND_EST],rax
    mov rax,[rbp+CR_TEMP6]
    cmp rax,[r12+NEBO_CHART_X_TICKS_OFFSET]
    jbe .bar_label_count_ok
    mov rax,[r12+NEBO_CHART_X_TICKS_OFFSET]
.bar_label_count_ok:
    add [rbp+CR_COMMAND_EST],rax
    movsd xmm0,[rel chart_half]
    xorpd xmm1,xmm1
    subsd xmm1,xmm0
    movapd xmm0,xmm1
    lea rdi,[rbp+CR_XMIN]
    lea rsi,[rbp+CR_XMAX]
    lea rdx,[rbp+CR_XINIT]
    call chart_bounds_update
    cvtsi2sd xmm0,qword [rbp+CR_TEMP6]
    subsd xmm0,[rel chart_half]
    lea rdi,[rbp+CR_XMIN]
    lea rsi,[rbp+CR_XMAX]
    lea rdx,[rbp+CR_XINIT]
    call chart_bounds_update
    movsd xmm0,[rel chart_zero]
    lea rdi,[rbp+CR_YMIN]
    lea rsi,[rbp+CR_YMAX]
    lea rdx,[rbp+CR_YINIT]
    call chart_bounds_update
    xor ecx,ecx
.bounds_bar_y:
    cmp rcx,[rbp+CR_TEMP6]
    jae .next_series
    mov [rbp+CR_POINT_INDEX],rcx
    mov rdi,r15
    mov rsi,rcx
    mov edx,1
    call chart_series_value
    lea rdi,[rbp+CR_YMIN]
    lea rsi,[rbp+CR_YMAX]
    lea rdx,[rbp+CR_YINIT]
    call chart_bounds_update
    mov rcx,[rbp+CR_POINT_INDEX]
    inc rcx
    jmp .bounds_bar_y
.estimate_hist:
    mov rax,[r15+NEBO_CHART_SERIES_BINS_OFFSET]
    add [rbp+CR_COMMAND_EST],rax
    movsd xmm0,[rel chart_zero]
    lea rdi,[rbp+CR_YMIN]
    lea rsi,[rbp+CR_YMAX]
    lea rdx,[rbp+CR_YINIT]
    call chart_bounds_update
    cvtsi2sd xmm0,qword [rbp+CR_TEMP6]
    lea rdi,[rbp+CR_YMIN]
    lea rsi,[rbp+CR_YMAX]
    lea rdx,[rbp+CR_YINIT]
    call chart_bounds_update
    xor ecx,ecx
.bounds_hist_x:
    cmp rcx,[rbp+CR_TEMP6]
    jae .next_series
    mov [rbp+CR_POINT_INDEX],rcx
    mov rdi,r15
    mov rsi,rcx
    mov edx,1
    call chart_series_value
    lea rdi,[rbp+CR_XMIN]
    lea rsi,[rbp+CR_XMAX]
    lea rdx,[rbp+CR_XINIT]
    call chart_bounds_update
    mov rcx,[rbp+CR_POINT_INDEX]
    inc rcx
    jmp .bounds_hist_x
.next_series:
    inc rbx
    jmp .preflight_series_loop
.preflight_series_done:
    mov rax,[rbp+CR_TEMP5]
    cmp rax,[r12+NEBO_CHART_TOTAL_POINTS_OFFSET]
    jne .bad_state
    cmp qword [rbp+CR_XINIT],1
    je .x_bounds_ready
    movsd xmm0,[rel chart_one]
    xorpd xmm1,xmm1
    subsd xmm1,xmm0
    movsd [rbp+CR_XMIN],xmm1
    movsd [rbp+CR_XMAX],xmm0
    mov qword [rbp+CR_XINIT],1
.x_bounds_ready:
    cmp qword [rbp+CR_YINIT],1
    je .y_bounds_ready
    movsd xmm0,[rel chart_one]
    xorpd xmm1,xmm1
    subsd xmm1,xmm0
    movsd [rbp+CR_YMIN],xmm1
    movsd [rbp+CR_YMAX],xmm0
    mov qword [rbp+CR_YINIT],1
.y_bounds_ready:
    test dword [r12+NEBO_CHART_X_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_MANUAL_RANGE
    jz .auto_x_done
    mov rax,[r12+NEBO_CHART_X_MIN_OFFSET]
    mov [rbp+CR_XMIN],rax
    mov rax,[r12+NEBO_CHART_X_MAX_OFFSET]
    mov [rbp+CR_XMAX],rax
.auto_x_done:
    test dword [r12+NEBO_CHART_Y_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_MANUAL_RANGE
    jz .auto_y_done
    mov rax,[r12+NEBO_CHART_Y_MIN_OFFSET]
    mov [rbp+CR_YMIN],rax
    mov rax,[r12+NEBO_CHART_Y_MAX_OFFSET]
    mov [rbp+CR_YMAX],rax
.auto_y_done:
    mov qword [rbp+CR_LEFT],28
    mov qword [rbp+CR_TOP],18
    mov rax,[rbp+CR_CANVAS_W]
    sub rax,40
    test qword [r12+NEBO_CHART_LEGEND_FLAGS_OFFSET],NEBO_CHART_LEGEND_FLAG_ENABLED
    jz .plot_width_ok
    sub rax,52
.plot_width_ok:
    cmp rax,32
    jb .canvas_size
    mov [rbp+CR_PLOT_W],rax
    mov rax,[rbp+CR_CANVAS_H]
    sub rax,38
    cmp rax,32
    jb .canvas_size
    mov [rbp+CR_PLOT_H],rax
    test qword [r12+NEBO_CHART_LEGEND_FLAGS_OFFSET],NEBO_CHART_LEGEND_FLAG_ENABLED
    jz .legend_est_done
    inc qword [rbp+CR_COMMAND_EST]
    mov rax,[r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    shl rax,1
    add [rbp+CR_COMMAND_EST],rax
.legend_est_done:
    mov rax,[r13+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    mov [rbp+CR_CANVAS_BEFORE],rax
    mov rcx,[r13+NEBO_CANVAS_COMMAND_CAPACITY_OFFSET]
    sub rcx,rax
    jc .command_budget
    cmp rcx,[rbp+CR_COMMAND_EST]
    jb .command_budget

    ; Mutation starts only after all source, range, geometry and command checks.
    cmp qword [r13+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0
    jne .canvas_owner_bound
    mov rax,[r12+NEBO_CHART_OWNER_CONTEXT_OFFSET]
    mov [r13+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],rax
.canvas_owner_bound:
    mov rdi,r13
    mov esi,[r12+NEBO_CHART_BACKGROUND_RGBA_OFFSET]
    call nebo_canvas_clear
    test eax,eax
    jnz .render_failure
    mov rdi,r13
    mov rsi,[rbp+CR_LEFT]
    mov rdx,[rbp+CR_TOP]
    mov rcx,[rbp+CR_PLOT_W]
    mov r8,[rbp+CR_PLOT_H]
    mov r9d,[r12+NEBO_CHART_PLOT_RGBA_OFFSET]
    call chart_draw_rect_fill
    test eax,eax
    jnz .render_failure

    ; Vertical grid and x ticks.
    xor ebx,ebx
.x_tick_loop:
    cmp rbx,[r12+NEBO_CHART_X_TICKS_OFFSET]
    jae .y_tick_start
    mov rax,[rbp+CR_PLOT_W]
    dec rax
    imul rax,rbx
    xor edx,edx
    mov rcx,[r12+NEBO_CHART_X_TICKS_OFFSET]
    dec rcx
    div rcx
    add rax,[rbp+CR_LEFT]
    mov [rbp+CR_TEMP0],rax
    test dword [r12+NEBO_CHART_X_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    jz .x_tick_mark
    mov rdi,r13
    mov rsi,rax
    mov rdx,[rbp+CR_TOP]
    mov rcx,rax
    mov r8,[rbp+CR_TOP]
    add r8,[rbp+CR_PLOT_H]
    dec r8
    mov r9d,[r12+NEBO_CHART_GRID_RGBA_OFFSET]
    call chart_draw_line
    test eax,eax
    jnz .render_failure
.x_tick_mark:
    mov rax,[rbp+CR_TEMP0]
    mov rdi,r13
    mov rsi,rax
    mov rdx,[rbp+CR_TOP]
    add rdx,[rbp+CR_PLOT_H]
    dec rdx
    mov rcx,rax
    mov r8,rdx
    add r8,3
    mov r9d,[r12+NEBO_CHART_AXIS_RGBA_OFFSET]
    call chart_draw_line
    test eax,eax
    jnz .render_failure
    inc rbx
    jmp .x_tick_loop
.y_tick_start:
    xor ebx,ebx
.y_tick_loop:
    cmp rbx,[r12+NEBO_CHART_Y_TICKS_OFFSET]
    jae .draw_axes
    mov rax,[rbp+CR_PLOT_H]
    dec rax
    imul rax,rbx
    xor edx,edx
    mov rcx,[r12+NEBO_CHART_Y_TICKS_OFFSET]
    dec rcx
    div rcx
    mov rdx,[rbp+CR_TOP]
    add rdx,[rbp+CR_PLOT_H]
    dec rdx
    sub rdx,rax
    mov [rbp+CR_TEMP0],rdx
    test dword [r12+NEBO_CHART_Y_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    jz .y_tick_mark
    mov rdi,r13
    mov rsi,[rbp+CR_LEFT]
    mov rcx,rsi
    add rcx,[rbp+CR_PLOT_W]
    dec rcx
    mov r8,rdx
    mov r9d,[r12+NEBO_CHART_GRID_RGBA_OFFSET]
    call chart_draw_line
    test eax,eax
    jnz .render_failure
.y_tick_mark:
    mov rdx,[rbp+CR_TEMP0]
    mov rdi,r13
    mov rsi,[rbp+CR_LEFT]
    sub rsi,3
    mov rcx,[rbp+CR_LEFT]
    mov r8,rdx
    mov r9d,[r12+NEBO_CHART_AXIS_RGBA_OFFSET]
    call chart_draw_line
    test eax,eax
    jnz .render_failure
    inc rbx
    jmp .y_tick_loop
.draw_axes:
    mov rdi,r13
    mov rsi,[rbp+CR_LEFT]
    mov rdx,[rbp+CR_TOP]
    add rdx,[rbp+CR_PLOT_H]
    dec rdx
    mov rcx,rsi
    add rcx,[rbp+CR_PLOT_W]
    dec rcx
    mov r8,rdx
    mov r9d,[r12+NEBO_CHART_AXIS_RGBA_OFFSET]
    call chart_draw_line
    test eax,eax
    jnz .render_failure
    mov rdi,r13
    mov rsi,[rbp+CR_LEFT]
    mov rdx,[rbp+CR_TOP]
    mov rcx,rsi
    mov r8,rdx
    add r8,[rbp+CR_PLOT_H]
    dec r8
    mov r9d,[r12+NEBO_CHART_AXIS_RGBA_OFFSET]
    call chart_draw_line
    test eax,eax
    jnz .render_failure

    ; Title and axis labels.
    test dword [r12+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_TITLE
    jz .x_label
    mov rdi,r13
    mov rsi,[r12+NEBO_CHART_TITLE_PTR_OFFSET]
    mov rdx,[r12+NEBO_CHART_TITLE_LENGTH_OFFSET]
    mov rcx,[rbp+CR_LEFT]
    mov r8d,4
    mov r9d,[r12+NEBO_CHART_TEXT_RGBA_OFFSET]
    call chart_draw_text
    test eax,eax
    jnz .render_failure
.x_label:
    cmp qword [r12+NEBO_CHART_X_LABEL_LENGTH_OFFSET],0
    je .y_label
    mov rdi,r13
    mov rsi,[r12+NEBO_CHART_X_LABEL_PTR_OFFSET]
    mov rdx,[r12+NEBO_CHART_X_LABEL_LENGTH_OFFSET]
    mov rcx,[rbp+CR_LEFT]
    mov r8,[rbp+CR_CANVAS_H]
    sub r8,8
    mov r9d,[r12+NEBO_CHART_TEXT_RGBA_OFFSET]
    call chart_draw_text
    test eax,eax
    jnz .render_failure
.y_label:
    cmp qword [r12+NEBO_CHART_Y_LABEL_LENGTH_OFFSET],0
    je .render_series_start
    mov rdi,r13
    mov rsi,[r12+NEBO_CHART_Y_LABEL_PTR_OFFSET]
    mov rdx,[r12+NEBO_CHART_Y_LABEL_LENGTH_OFFSET]
    mov ecx,2
    mov r8,[rbp+CR_TOP]
    mov r9d,[r12+NEBO_CHART_TEXT_RGBA_OFFSET]
    call chart_draw_text
    test eax,eax
    jnz .render_failure

.render_series_start:
    mov qword [rbp+CR_SERIES_INDEX],0
.render_series_loop:
    mov rbx,[rbp+CR_SERIES_INDEX]
    cmp rbx,[r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    jae .legend
    mov r15,rbx
    imul r15,NEBO_CHART_SERIES_SIZE
    add r15,[r12+NEBO_CHART_SERIES_PTR_OFFSET]
    mov eax,[r15+NEBO_CHART_SERIES_KIND_OFFSET]
    cmp eax,NEBO_CHART_KIND_LINE
    je .render_line
    cmp eax,NEBO_CHART_KIND_SCATTER
    je .render_scatter
    cmp eax,NEBO_CHART_KIND_BAR
    je .render_bar
    cmp eax,NEBO_CHART_KIND_HISTOGRAM
    je .render_hist
    jmp .bad_state

.render_line:
    mov qword [rbp+CR_POINT_INDEX],0
.line_loop:
    mov rbx,[rbp+CR_POINT_INDEX]
    cmp rbx,[r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    jae .series_done
    mov rdi,r15
    mov rsi,rbx
    xor edx,edx
    call chart_series_value
    movsd xmm1,[rbp+CR_XMIN]
    movsd xmm2,[rbp+CR_XMAX]
    mov rdi,[rbp+CR_LEFT]
    mov rsi,[rbp+CR_PLOT_W]
    dec rsi
    call chart_map_value
    mov [rbp+CR_TEMP0],rax
    mov rdi,r15
    mov rsi,rbx
    mov edx,1
    call chart_series_value
    movsd xmm1,[rbp+CR_YMIN]
    movsd xmm2,[rbp+CR_YMAX]
    xor edi,edi
    mov rsi,[rbp+CR_PLOT_H]
    dec rsi
    call chart_map_value
    mov rcx,[rbp+CR_TOP]
    add rcx,[rbp+CR_PLOT_H]
    dec rcx
    sub rcx,rax
    mov [rbp+CR_TEMP1],rcx
    test rbx,rbx
    jz .line_point
    mov rdi,r13
    mov rsi,[rbp+CR_PREV_X]
    mov rdx,[rbp+CR_PREV_Y]
    mov rcx,[rbp+CR_TEMP0]
    mov r8,[rbp+CR_TEMP1]
    mov r9d,[r15+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET]
    call chart_draw_line
    test eax,eax
    jnz .render_failure
.line_point:
    test dword [r15+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_SHOW_POINTS
    jz .line_save
    mov rdi,r13
    mov rsi,[rbp+CR_TEMP0]
    mov rdx,[rbp+CR_TEMP1]
    mov rcx,[r15+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET]
    mov r8d,[r15+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET]
    call chart_draw_circle_fill
    test eax,eax
    jnz .render_failure
.line_save:
    mov rax,[rbp+CR_TEMP0]
    mov [rbp+CR_PREV_X],rax
    mov rax,[rbp+CR_TEMP1]
    mov [rbp+CR_PREV_Y],rax
    inc qword [rbp+CR_POINT_INDEX]
    jmp .line_loop

.render_scatter:
    mov qword [rbp+CR_POINT_INDEX],0
.scatter_loop:
    mov rbx,[rbp+CR_POINT_INDEX]
    cmp rbx,[r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    jae .series_done
    mov rdi,r15
    mov rsi,rbx
    xor edx,edx
    call chart_series_value
    movsd xmm1,[rbp+CR_XMIN]
    movsd xmm2,[rbp+CR_XMAX]
    mov rdi,[rbp+CR_LEFT]
    mov rsi,[rbp+CR_PLOT_W]
    dec rsi
    call chart_map_value
    mov [rbp+CR_TEMP0],rax
    mov rdi,r15
    mov rsi,rbx
    mov edx,1
    call chart_series_value
    movsd xmm1,[rbp+CR_YMIN]
    movsd xmm2,[rbp+CR_YMAX]
    xor edi,edi
    mov rsi,[rbp+CR_PLOT_H]
    dec rsi
    call chart_map_value
    mov rdx,[rbp+CR_TOP]
    add rdx,[rbp+CR_PLOT_H]
    dec rdx
    sub rdx,rax
    mov rdi,r13
    mov rsi,[rbp+CR_TEMP0]
    mov rcx,[r15+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET]
    mov r8d,[r15+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET]
    call chart_draw_circle_fill
    test eax,eax
    jnz .render_failure
    inc qword [rbp+CR_POINT_INDEX]
    jmp .scatter_loop

.render_bar:
    mov qword [rbp+CR_POINT_INDEX],0
    ; Baseline y=0.
    movsd xmm0,[rel chart_zero]
    movsd xmm1,[rbp+CR_YMIN]
    movsd xmm2,[rbp+CR_YMAX]
    xor edi,edi
    mov rsi,[rbp+CR_PLOT_H]
    dec rsi
    call chart_map_value
    mov rcx,[rbp+CR_TOP]
    add rcx,[rbp+CR_PLOT_H]
    dec rcx
    sub rcx,rax
    mov [rbp+CR_ZERO_COORD],rcx
.bar_loop:
    mov rbx,[rbp+CR_POINT_INDEX]
    cmp rbx,[r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    jae .bar_labels
    mov rax,[rbp+CR_PLOT_W]
    imul rax,rbx
    xor edx,edx
    div qword [r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    add rax,[rbp+CR_LEFT]
    mov [rbp+CR_TEMP0],rax
    mov rax,rbx
    inc rax
    imul rax,[rbp+CR_PLOT_W]
    xor edx,edx
    div qword [r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    add rax,[rbp+CR_LEFT]
    mov rcx,rax
    sub rcx,[rbp+CR_TEMP0]
    cmp rcx,1
    jbe .bar_width_one
    dec rcx
    jmp .bar_width_ready
.bar_width_one:
    mov ecx,1
.bar_width_ready:
    mov [rbp+CR_TEMP2],rcx
    mov rdi,r15
    mov rsi,rbx
    mov edx,1
    call chart_series_value
    movsd xmm1,[rbp+CR_YMIN]
    movsd xmm2,[rbp+CR_YMAX]
    xor edi,edi
    mov rsi,[rbp+CR_PLOT_H]
    dec rsi
    call chart_map_value
    mov rdx,[rbp+CR_TOP]
    add rdx,[rbp+CR_PLOT_H]
    dec rdx
    sub rdx,rax
    mov rax,[rbp+CR_ZERO_COORD]
    mov rcx,rdx
    cmp rcx,rax
    jbe .bar_top_ready
    xchg rcx,rax
.bar_top_ready:
    mov r8,rax
    sub r8,rcx
    inc r8
    mov rdi,r13
    mov rsi,[rbp+CR_TEMP0]
    mov rdx,rcx
    mov rcx,[rbp+CR_TEMP2]
    mov r9d,[r15+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET]
    call chart_draw_rect_fill
    test eax,eax
    jnz .render_failure
    inc qword [rbp+CR_POINT_INDEX]
    jmp .bar_loop
.bar_labels:
    mov rax,[r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    cmp rax,[r12+NEBO_CHART_X_TICKS_OFFSET]
    jbe .bar_label_count_ready
    mov rax,[r12+NEBO_CHART_X_TICKS_OFFSET]
.bar_label_count_ready:
    mov [rbp+CR_TEMP3],rax
    mov qword [rbp+CR_POINT_INDEX],0
.bar_label_loop:
    mov rbx,[rbp+CR_POINT_INDEX]
    cmp rbx,[rbp+CR_TEMP3]
    jae .series_done
    cmp qword [rbp+CR_TEMP3],1
    je .bar_label_zero
    mov rax,[r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    dec rax
    imul rax,rbx
    xor edx,edx
    mov rcx,[rbp+CR_TEMP3]
    dec rcx
    div rcx
    jmp .bar_label_index_ready
.bar_label_zero:
    xor eax,eax
.bar_label_index_ready:
    mov [rbp+CR_TEMP4],rax
    mov rcx,rax
    shl rcx,4
    add rcx,[r15+NEBO_CHART_SERIES_CATEGORIES_PTR_OFFSET]
    mov rsi,[rcx+NEBO_CHART_STRING_PTR_OFFSET]
    mov rdx,[rcx+NEBO_CHART_STRING_LENGTH_OFFSET]
    mov rax,[rbp+CR_PLOT_W]
    imul rax,[rbp+CR_TEMP4]
    xor edx,edx
    div qword [r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    add rax,[rbp+CR_LEFT]
    mov rcx,rax
    mov rax,[rbp+CR_TEMP4]
    shl rax,4
    add rax,[r15+NEBO_CHART_SERIES_CATEGORIES_PTR_OFFSET]
    mov rsi,[rax+NEBO_CHART_STRING_PTR_OFFSET]
    mov rdx,[rax+NEBO_CHART_STRING_LENGTH_OFFSET]
    mov r8,[rbp+CR_TOP]
    add r8,[rbp+CR_PLOT_H]
    add r8,4
    mov rdi,r13
    mov r9d,[r12+NEBO_CHART_TEXT_RGBA_OFFSET]
    call chart_draw_text
    test eax,eax
    jnz .render_failure
    inc qword [rbp+CR_POINT_INDEX]
    jmp .bar_label_loop

.render_hist:
    mov qword [rbp+CR_HIST_INIT],0
    mov qword [rbp+CR_POINT_INDEX],0
.hist_bounds_loop:
    mov rbx,[rbp+CR_POINT_INDEX]
    cmp rbx,[r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    jae .hist_bins_start
    mov rdi,r15
    mov rsi,rbx
    mov edx,1
    call chart_series_value
    lea rdi,[rbp+CR_HIST_MIN]
    lea rsi,[rbp+CR_HIST_MAX]
    lea rdx,[rbp+CR_HIST_INIT]
    call chart_bounds_update
    inc qword [rbp+CR_POINT_INDEX]
    jmp .hist_bounds_loop
.hist_bins_start:
    mov qword [rbp+CR_POINT_INDEX],0
.hist_bin_loop:
    mov rbx,[rbp+CR_POINT_INDEX]
    cmp rbx,[r15+NEBO_CHART_SERIES_BINS_OFFSET]
    jae .series_done
    mov qword [rbp+CR_TEMP0],0 ; count
    mov qword [rbp+CR_TEMP1],0 ; sample index
.hist_count_loop:
    mov rax,[rbp+CR_TEMP1]
    cmp rax,[r15+NEBO_CHART_SERIES_POINT_COUNT_OFFSET]
    jae .hist_count_done
    mov rdi,r15
    mov rsi,rax
    mov edx,1
    call chart_series_value
    movsd xmm1,[rbp+CR_HIST_MIN]
    movsd xmm2,[rbp+CR_HIST_MAX]
    mov rdi,[r15+NEBO_CHART_SERIES_BINS_OFFSET]
    call chart_value_to_bin
    cmp rax,rbx
    jne .hist_count_next
    inc qword [rbp+CR_TEMP0]
.hist_count_next:
    inc qword [rbp+CR_TEMP1]
    jmp .hist_count_loop
.hist_count_done:
    mov rax,[rbp+CR_PLOT_W]
    imul rax,rbx
    xor edx,edx
    div qword [r15+NEBO_CHART_SERIES_BINS_OFFSET]
    add rax,[rbp+CR_LEFT]
    mov [rbp+CR_TEMP2],rax
    mov rax,rbx
    inc rax
    imul rax,[rbp+CR_PLOT_W]
    xor edx,edx
    div qword [r15+NEBO_CHART_SERIES_BINS_OFFSET]
    add rax,[rbp+CR_LEFT]
    mov rcx,rax
    sub rcx,[rbp+CR_TEMP2]
    cmp rcx,1
    jbe .hist_width_one
    dec rcx
    jmp .hist_width_ready
.hist_width_one:
    mov ecx,1
.hist_width_ready:
    mov [rbp+CR_TEMP3],rcx
    cvtsi2sd xmm0,qword [rbp+CR_TEMP0]
    movsd xmm1,[rbp+CR_YMIN]
    movsd xmm2,[rbp+CR_YMAX]
    xor edi,edi
    mov rsi,[rbp+CR_PLOT_H]
    dec rsi
    call chart_map_value
    mov rdx,[rbp+CR_TOP]
    add rdx,[rbp+CR_PLOT_H]
    dec rdx
    sub rdx,rax
    mov r8,[rbp+CR_TOP]
    add r8,[rbp+CR_PLOT_H]
    sub r8,rdx
    mov rdi,r13
    mov rsi,[rbp+CR_TEMP2]
    mov rcx,[rbp+CR_TEMP3]
    mov r9d,[r15+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET]
    call chart_draw_rect_fill
    test eax,eax
    jnz .render_failure
    inc qword [rbp+CR_POINT_INDEX]
    jmp .hist_bin_loop

.series_done:
    inc qword [rbp+CR_SERIES_INDEX]
    jmp .render_series_loop

.legend:
    test qword [r12+NEBO_CHART_LEGEND_FLAGS_OFFSET],NEBO_CHART_LEGEND_FLAG_ENABLED
    jz .finalize
    mov rax,[rbp+CR_CANVAS_W]
    sub rax,60
    mov [rbp+CR_TEMP0],rax
    mov qword [rbp+CR_TEMP1],8
    mov r8,[r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    imul r8,9
    add r8,4
    mov rdi,r13
    mov rsi,rax
    mov rdx,8
    mov ecx,56
    mov r9d,[r12+NEBO_CHART_LEGEND_RGBA_OFFSET]
    call chart_draw_rect_fill
    test eax,eax
    jnz .render_failure
    mov qword [rbp+CR_SERIES_INDEX],0
.legend_loop:
    mov rbx,[rbp+CR_SERIES_INDEX]
    cmp rbx,[r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    jae .finalize
    mov r15,rbx
    imul r15,NEBO_CHART_SERIES_SIZE
    add r15,[r12+NEBO_CHART_SERIES_PTR_OFFSET]
    mov rdi,r13
    mov rsi,[rbp+CR_TEMP0]
    add rsi,3
    mov rdx,rbx
    imul rdx,9
    add rdx,11
    mov ecx,6
    mov r8d,6
    mov r9d,[r15+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET]
    call chart_draw_rect_fill
    test eax,eax
    jnz .render_failure
    mov rdi,r13
    mov rsi,[r15+NEBO_CHART_SERIES_LABEL_PTR_OFFSET]
    mov rdx,[r15+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET]
    mov rcx,[rbp+CR_TEMP0]
    add rcx,12
    mov r8,rbx
    imul r8,9
    add r8,10
    mov r9d,[r12+NEBO_CHART_TEXT_RGBA_OFFSET]
    call chart_draw_text
    test eax,eax
    jnz .render_failure
    inc qword [rbp+CR_SERIES_INDEX]
    jmp .legend_loop

.finalize:
    lea rsi,[rbp+CR_RENDER_RESULT_HASH]
    mov rdi,r13
    call nebo_canvas_state_hash
    test eax,eax
    jnz .render_failure
    mov rax,[r13+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    sub rax,[rbp+CR_CANVAS_BEFORE]
    mov [r12+NEBO_CHART_LAST_COMMAND_COUNT_OFFSET],rax
    mov rcx,[rbp+CR_RENDER_RESULT_HASH]
    mov [r12+NEBO_CHART_LAST_PIXEL_HASH_OFFSET],rcx
    inc qword [r12+NEBO_CHART_RENDER_GENERATION_OFFSET]
    or dword [r12+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_RENDERED
    mov rax,[r12+NEBO_CHART_SERIES_COUNT_OFFSET]
    mov [r14+NEBO_CHART_RESULT_SERIES_OFFSET],rax
    mov rax,[r12+NEBO_CHART_TOTAL_POINTS_OFFSET]
    mov [r14+NEBO_CHART_RESULT_POINTS_OFFSET],rax
    mov rax,[r12+NEBO_CHART_LAST_COMMAND_COUNT_OFFSET]
    mov [r14+NEBO_CHART_RESULT_COMMANDS_OFFSET],rax
    mov rax,[rbp+CR_RENDER_RESULT_HASH]
    mov [r14+NEBO_CHART_RESULT_PIXEL_HASH_OFFSET],rax
    mov rax,[rbp+CR_XMIN]
    mov [r14+NEBO_CHART_RESULT_X_MIN_OFFSET],rax
    mov rax,[rbp+CR_XMAX]
    mov [r14+NEBO_CHART_RESULT_X_MAX_OFFSET],rax
    mov rax,[rbp+CR_YMIN]
    mov [r14+NEBO_CHART_RESULT_Y_MIN_OFFSET],rax
    mov rax,[rbp+CR_YMAX]
    mov [r14+NEBO_CHART_RESULT_Y_MAX_OFFSET],rax
    xor eax,eax
    jmp .record_success
.invalid:
    mov eax,NEBO_CHART_ERROR_INVALID_ARGUMENT
    jmp .record_error
.bad_state:
    mov eax,NEBO_CHART_ERROR_BAD_STATE
    jmp .record_error
.empty:
    mov eax,NEBO_CHART_ERROR_EMPTY_DATA
    jmp .record_error
.limit:
    mov eax,NEBO_CHART_ERROR_LIMIT_EXCEEDED
    jmp .record_error
.canvas_size:
    mov eax,NEBO_CHART_ERROR_CANVAS_SIZE
    jmp .record_error
.command_budget:
    mov eax,NEBO_CHART_ERROR_COMMAND_BUDGET
    jmp .record_error
.owner:
    mov eax,NEBO_CHART_ERROR_OWNER_MISMATCH
    jmp .record_error
.overlap:
    mov eax,NEBO_CHART_ERROR_STORAGE_OVERLAP
    jmp .record_error
.utf8:
    mov eax,NEBO_CHART_ERROR_INVALID_UTF8
    jmp .record_error
.render_failure:
    mov eax,NEBO_CHART_ERROR_RENDER_FAILURE
.record_error:
    mov edx,eax
    mov esi,eax
    mov rdi,r12
    call chart_record_status
    jmp .return
.record_success:
    xor edx,edx
    xor esi,esi
    mov rdi,r12
    call chart_record_status
.return:
    add rsp,264
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

nebo_chart_close:
    push r12
    mov r12,rdi
    call chart_validate_common
    test eax,eax
    jnz .record
    cmp dword [r12+NEBO_CHART_STATE_OFFSET],NEBO_CHART_STATE_ACTIVE
    jne .closed
    mov dword [r12+NEBO_CHART_STATE_OFFSET],NEBO_CHART_STATE_CLOSED
    xor eax,eax
    jmp .record
.closed:
    mov eax,NEBO_CHART_ERROR_CLOSED
.record:
    mov edx,eax
    mov esi,eax
    mov rdi,r12
    call chart_record_status
    pop r12
    ret
