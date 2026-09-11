bits 64
default rel
%define NEBO_SCAN_PLAN_IMPLEMENTATION 1
%include "runtime/textual/scan_plan.inc"

section .note.GNU-stack noalloc noexec nowrite progbits
section .text

global neboc_scan_feature_available
neboc_scan_feature_available:
    xor eax, eax
    cmp edi, SCAN_MIN_FEATURE_ID
    jl .done
    cmp edi, SCAN_MAX_FEATURE_ID
    jg .done
    mov eax, 1
.done:
    ret

global neboc_scan_feature_validate
neboc_scan_feature_validate:
    cmp edi, SCAN_MIN_FEATURE_ID
    jl .invalid
    cmp edi, SCAN_MAX_FEATURE_ID
    jg .invalid
    cmp esi, SCAN_KIND_TEXT
    jl .invalid
    cmp esi, SCAN_KIND_MAX
    jg .invalid
    cmp ecx, SCAN_MAX_INPUT_BYTES
    ja .limit
    test r8d, r8d
    jz .invalid
    cmp r8d, SCAN_MAX_ATTEMPTS
    ja .limit
    cmp r9d, SCAN_SOURCE_MOCK
    jl .invalid
    cmp r9d, SCAN_SOURCE_DEVICE
    jg .invalid
    mov eax, edx
    and eax, SCAN_FLAG_REQUIRED | SCAN_FLAG_OPTIONAL
    cmp eax, SCAN_FLAG_REQUIRED | SCAN_FLAG_OPTIONAL
    je .invalid
    test edx, SCAN_FLAG_SECRET
    jz .ok
    test edx, SCAN_FLAG_NO_HISTORY
    jz .invalid
.ok:
    xor eax, eax
    ret
.invalid:
    mov eax, -SCAN_E_INVALID
    ret
.limit:
    mov eax, -SCAN_E_LIMIT
    ret

global neboc_scan_normalize_ascii
neboc_scan_normalize_ascii:
    push r12
    mov r12, rdx
    cmp rsi, SCAN_MAX_INPUT_BYTES
    ja .norm_limit
    test rsi, rsi
    jz .norm_empty
    test rdi, rdi
    jz .norm_invalid
    xor r9d, r9d
    mov r10, rsi
    test r8d, SCAN_FLAG_CHOMP
    jz .norm_trim
    cmp byte [rdi + r10 - 1], 10
    jne .norm_trim
    dec r10
    test r10, r10
    jz .norm_trim
    cmp byte [rdi + r10 - 1], 13
    jne .norm_trim
    dec r10
.norm_trim:
    test r8d, SCAN_FLAG_TRIM
    jz .norm_measure_setup
.trim_left:
    cmp r9, r10
    jae .trim_right
    movzx eax, byte [rdi + r9]
    cmp al, ' '
    je .trim_left_advance
    cmp al, 9
    jne .trim_right
.trim_left_advance:
    inc r9
    jmp .trim_left
.trim_right:
    cmp r10, r9
    jbe .norm_measure_setup
    movzx eax, byte [rdi + r10 - 1]
    cmp al, ' '
    je .trim_right_advance
    cmp al, 9
    jne .norm_measure_setup
.trim_right_advance:
    dec r10
    jmp .trim_right
.norm_measure_setup:
    mov rsi, rcx
    xor eax, eax
    mov r11, r9
    xor ecx, ecx
.norm_measure:
    cmp r11, r10
    jae .norm_capacity
    movzx edx, byte [rdi + r11]
    test r8d, SCAN_FLAG_COLLAPSE_SPACES
    jz .measure_regular
    cmp dl, ' '
    je .measure_space
    cmp dl, 9
    jne .measure_nonspace
.measure_space:
    test ecx, ecx
    jnz .measure_next
    mov ecx, 1
    inc rax
    jmp .measure_next
.measure_nonspace:
    xor ecx, ecx
.measure_regular:
    inc rax
.measure_next:
    inc r11
    jmp .norm_measure
.norm_capacity:
    cmp rax, rsi
    ja .norm_capacity_fail
    test rax, rax
    jz .norm_empty
    test r12, r12
    jz .norm_invalid
    mov r11, r9
    xor ecx, ecx
    xor esi, esi
.norm_write:
    cmp r11, r10
    jae .norm_written
    movzx eax, byte [rdi + r11]
    test r8d, SCAN_FLAG_COLLAPSE_SPACES
    jz .normalize_case
    cmp al, ' '
    je .write_space
    cmp al, 9
    jne .write_nonspace
.write_space:
    test esi, esi
    jnz .write_next
    mov esi, 1
    mov al, ' '
    jmp .normalize_case
.write_nonspace:
    xor esi, esi
.normalize_case:
    test r8d, SCAN_FLAG_LOWER
    jz .maybe_upper
    cmp al, 'A'
    jb .store
    cmp al, 'Z'
    ja .store
    add al, 32
    jmp .store
.maybe_upper:
    test r8d, SCAN_FLAG_UPPER
    jz .store
    cmp al, 'a'
    jb .store
    cmp al, 'z'
    ja .store
    sub al, 32
.store:
    mov [r12 + rcx], al
    inc rcx
.write_next:
    inc r11
    jmp .norm_write
.norm_written:
    mov rax, rcx
    pop r12
    ret
.norm_empty:
    xor eax, eax
    pop r12
    ret
.norm_invalid:
    mov rax, -SCAN_E_INVALID
    pop r12
    ret
.norm_limit:
    mov rax, -SCAN_E_LIMIT
    pop r12
    ret
.norm_capacity_fail:
    mov rax, -SCAN_E_CAPACITY
    pop r12
    ret

global neboc_scan_parse_int
neboc_scan_parse_int:
    test rdi, rdi
    jz .parse_invalid
    test rdx, rdx
    jz .parse_invalid
    test rsi, rsi
    jz .parse_fail
    cmp rsi, 20
    ja .parse_limit
    mov r11, rdx
    xor r8d, r8d
    xor r9d, r9d
    xor ecx, ecx
    movzx eax, byte [rdi]
    cmp al, '-'
    jne .parse_plus
    mov ecx, 1
    inc r8
    jmp .parse_digits
.parse_plus:
    cmp al, '+'
    jne .parse_digits
    inc r8
.parse_digits:
    cmp r8, rsi
    jae .parse_fail
.parse_loop:
    movzx eax, byte [rdi + r8]
    sub eax, '0'
    cmp eax, 9
    ja .parse_fail
    mov r10, rax
    mov rax, r9
    mov edx, 10
    mul rdx
    test rdx, rdx
    jnz .parse_limit
    add rax, r10
    jc .parse_limit
    ; Accumulate an unsigned magnitude. A negative Int64 additionally owns
    ; magnitude 2^63; only that signed endpoint may exceed INT64_MAX.
    mov rdx, 0x7fffffffffffffff
    add rdx, rcx
    cmp rax, rdx
    ja .parse_limit
    mov r9, rax
    inc r8
    cmp r8, rsi
    jb .parse_loop
    test ecx, ecx
    jz .parse_store
    neg r9
.parse_store:
    mov [r11], r9
    xor eax, eax
    ret
.parse_invalid:
    mov eax, -SCAN_E_INVALID
    ret
.parse_fail:
    mov eax, -SCAN_E_PARSE
    ret
.parse_limit:
    mov eax, -SCAN_E_LIMIT
    ret

global neboc_scan_validate_int
neboc_scan_validate_int:
    cmp rdi, rsi
    jl .int_fail
    cmp rdi, rdx
    jg .int_fail
    test ecx, SCAN_INT_POSITIVE
    jz .int_nonnegative
    test rdi, rdi
    jle .int_fail
.int_nonnegative:
    test ecx, SCAN_INT_NONNEGATIVE
    jz .int_even
    test rdi, rdi
    js .int_fail
.int_even:
    test ecx, SCAN_INT_EVEN
    jz .int_odd
    test dil, 1
    jnz .int_fail
.int_odd:
    test ecx, SCAN_INT_ODD
    jz .int_ok
    test dil, 1
    jz .int_fail
.int_ok:
    xor eax, eax
    ret
.int_fail:
    mov eax, -SCAN_E_VALIDATE
    ret

global neboc_scan_validate_text
neboc_scan_validate_text:
    test rdi, rdi
    jz .text_invalid
    cmp rsi, rdx
    jb .text_fail
    cmp rsi, rcx
    ja .text_fail
    xor r9d, r9d
.text_loop:
    cmp r9, rsi
    jae .text_ok
    movzx eax, byte [rdi + r9]
    test r8d, SCAN_TEXT_NO_CONTROL
    jz .text_digits
    cmp al, 32
    jb .text_fail
    cmp al, 127
    je .text_fail
.text_digits:
    test r8d, SCAN_TEXT_DIGITS
    jz .text_letters
    cmp al, '0'
    jb .text_fail
    cmp al, '9'
    ja .text_fail
.text_letters:
    test r8d, SCAN_TEXT_LETTERS
    jz .text_alnum
    or al, 32
    cmp al, 'a'
    jb .text_fail
    cmp al, 'z'
    ja .text_fail
.text_alnum:
    test r8d, SCAN_TEXT_ALNUM
    jz .text_next
    cmp al, '0'
    jb .text_alpha_check
    cmp al, '9'
    jbe .text_next
.text_alpha_check:
    or al, 32
    cmp al, 'a'
    jb .text_fail
    cmp al, 'z'
    ja .text_fail
.text_next:
    inc r9
    jmp .text_loop
.text_ok:
    xor eax, eax
    ret
.text_invalid:
    mov eax, -SCAN_E_INVALID
    ret
.text_fail:
    mov eax, -SCAN_E_VALIDATE
    ret

global neboc_scan_choice_index
neboc_scan_choice_index:
    test rdi, rdi
    jz .choice_invalid
    test rdx, rdx
    jz .choice_invalid
    test rcx, rcx
    jz .choice_invalid
    test r8d, r8d
    jz .choice_invalid
    cmp r8d, SCAN_MAX_CHOICES
    ja .choice_limit
    xor r9d, r9d
.choice_outer:
    cmp r9d, r8d
    jae .choice_fail
    cmp rsi, [rcx + r9 * 8]
    jne .choice_next
    mov r11, [rdx + r9 * 8]
    xor r10d, r10d
.choice_compare:
    cmp r10, rsi
    jae .choice_found
    mov al, [rdi + r10]
    cmp al, [r11 + r10]
    jne .choice_next
    inc r10
    jmp .choice_compare
.choice_found:
    mov rax, r9
    ret
.choice_next:
    inc r9
    jmp .choice_outer
.choice_invalid:
    mov rax, -SCAN_E_INVALID
    ret
.choice_limit:
    mov rax, -SCAN_E_LIMIT
    ret
.choice_fail:
    mov rax, -SCAN_E_VALIDATE
    ret

global neboc_scan_should_retry
neboc_scan_should_retry:
    test esi, esi
    jz .retry_invalid
    cmp esi, SCAN_MAX_ATTEMPTS
    ja .retry_limit
    xor eax, eax
    cmp edi, esi
    setl al
    ret
.retry_invalid:
    mov eax, -SCAN_E_INVALID
    ret
.retry_limit:
    mov eax, -SCAN_E_LIMIT
    ret

global neboc_scan_source_validate
neboc_scan_source_validate:
    cmp edi, SCAN_SOURCE_MOCK
    jl .source_invalid
    cmp edi, SCAN_SOURCE_DEVICE
    jg .source_invalid
    mov ecx, edi
    dec ecx
    mov eax, 1
    shl eax, cl
    test esi, eax
    jz .source_denied
    xor eax, eax
    ret
.source_invalid:
    mov eax, -SCAN_E_INVALID
    ret
.source_denied:
    mov eax, -SCAN_E_IO
    ret

global neboc_scan_multiline_validate
neboc_scan_multiline_validate:
    test edx, edx
    jz .multi_invalid
    cmp edx, SCAN_MAX_LINES
    ja .multi_limit
    cmp ecx, SCAN_MAX_INPUT_BYTES
    ja .multi_limit
    cmp rsi, rcx
    ja .multi_limit
    test rsi, rsi
    jz .multi_ok
    test rdi, rdi
    jz .multi_invalid
    mov r8d, 1
    xor r9d, r9d
.multi_loop:
    cmp r9, rsi
    jae .multi_ok
    cmp byte [rdi + r9], 10
    jne .multi_next
    inc r8d
    cmp r8d, edx
    ja .multi_limit
.multi_next:
    inc r9
    jmp .multi_loop
.multi_ok:
    xor eax, eax
    ret
.multi_invalid:
    mov eax, -SCAN_E_INVALID
    ret
.multi_limit:
    mov eax, -SCAN_E_LIMIT
    ret

global neboc_scan_result_resolve
neboc_scan_result_resolve:
    cmp edi, -SCAN_E_EOF
    jne .result_passthrough
    test esi, SCAN_FLAG_EOF_NONE
    jz .result_passthrough
    mov eax, 1
    ret
.result_passthrough:
    mov eax, edi
    ret
