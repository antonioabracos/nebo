bits 64
default rel
%include "runtime/textual/scan_plan.inc"

section .rodata
raw_text: db ' ', ' ', 'H', 'e', 'L', 'L', 'o', ' ', 10
raw_text_len equ $ - raw_text
expected: db 'h', 'e', 'l', 'l', 'o'
digits: db '4', '2'
invalid_digits: db '4', 'x'
choice0: db 'red'
choice1: db 'blue'
choices: dq choice0, choice1
choice_lens: dq 3, 4
multiline: db 'a', 10, 'b', 10, 'c'

section .data
normalized: times 16 db 0xaa
atomic_buffer: times 16 db 0xaa
parsed: dq 0x7777777777777777

section .text
global _start
_start:
    mov edi, 7601
    call neboc_scan_feature_available
    cmp eax, 1
    jne .fail

    mov edi, 7601
    mov esi, SCAN_KIND_TEXT
    mov edx, SCAN_FLAG_REQUIRED | SCAN_FLAG_TRIM
    mov ecx, raw_text_len
    mov r8d, 3
    mov r9d, SCAN_SOURCE_MOCK
    call neboc_scan_feature_validate
    test eax, eax
    jnz .fail

    mov edi, 9999
    call neboc_scan_feature_available
    test eax, eax
    jnz .fail

    mov edi, SCAN_SOURCE_MOCK
    mov esi, SCAN_CAP_MOCK
    call neboc_scan_source_validate
    test eax, eax
    jnz .fail

    mov rdi, raw_text
    mov rsi, raw_text_len
    mov rdx, normalized
    mov ecx, 16
    mov r8d, SCAN_FLAG_TRIM | SCAN_FLAG_LOWER | SCAN_FLAG_COLLAPSE_SPACES | SCAN_FLAG_CHOMP
    call neboc_scan_normalize_ascii
    cmp rax, 5
    jne .fail
    mov rsi, normalized
    mov rdi, expected
    mov ecx, 5
    repe cmpsb
    jne .fail

    mov rdi, raw_text
    mov rsi, raw_text_len
    mov rdx, atomic_buffer
    mov ecx, 4
    mov r8d, SCAN_FLAG_TRIM | SCAN_FLAG_LOWER | SCAN_FLAG_CHOMP
    call neboc_scan_normalize_ascii
    cmp rax, -SCAN_E_CAPACITY
    jne .fail
    cmp byte [atomic_buffer], 0xaa
    jne .fail

    mov rdi, digits
    mov esi, 2
    mov rdx, parsed
    call neboc_scan_parse_int
    test eax, eax
    jnz .fail
    cmp qword [parsed], 42
    jne .fail

    mov rdi, invalid_digits
    mov esi, 2
    mov rdx, parsed
    call neboc_scan_parse_int
    cmp eax, -SCAN_E_PARSE
    jne .fail
    cmp qword [parsed], 42
    jne .fail

    mov edi, 42
    xor esi, esi
    mov edx, 100
    mov ecx, SCAN_INT_EVEN | SCAN_INT_NONNEGATIVE
    call neboc_scan_validate_int
    test eax, eax
    jnz .fail

    mov rdi, digits
    mov esi, 2
    mov edx, 1
    mov ecx, 3
    mov r8d, SCAN_TEXT_DIGITS | SCAN_TEXT_NO_CONTROL
    call neboc_scan_validate_text
    test eax, eax
    jnz .fail

    mov rdi, choice1
    mov esi, 4
    mov rdx, choices
    mov rcx, choice_lens
    mov r8d, 2
    call neboc_scan_choice_index
    cmp rax, 1
    jne .fail

    mov edi, 2
    mov esi, 3
    call neboc_scan_should_retry
    cmp eax, 1
    jne .fail
    mov edi, 3
    mov esi, 3
    call neboc_scan_should_retry
    test eax, eax
    jnz .fail

    mov edi, -SCAN_E_EOF
    mov esi, SCAN_FLAG_EOF_NONE
    call neboc_scan_result_resolve
    cmp eax, 1
    jne .fail

    mov rdi, multiline
    mov esi, 5
    mov edx, 3
    mov ecx, 16
    call neboc_scan_multiline_validate
    test eax, eax
    jnz .fail

    xor edi, edi
    mov eax, 60
    syscall
.fail:
    mov edi, 7601
    and edi, 255
    inc edi
    mov eax, 60
    syscall
