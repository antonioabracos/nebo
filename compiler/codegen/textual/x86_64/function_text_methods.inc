; Shared typed Text method emission. The canonical API contract supplies
; MethodId/arity/result type; this table only describes native ABI lowering.
; Expressions run once, left to right, and each result owns distinct bounded
; function storage. Native calls never receive an unreserved red-zone slot.
section .rodata
ftm_code_1:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_byte_length',10
 db '    mov r12, [r12 + 24]',10
ftm_code_1_len equ $-ftm_code_1
ftm_code_2:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_codepoint_count',10
 db '    mov r12, [r12 + 24]',10
ftm_code_2_len equ $-ftm_code_2
ftm_code_11:
 db '    mov rdi, [r12]',10
 db '    mov esi, 1',10
 db '    call neboc_runtime_tag_test',10
 db '    mov r12, [r12 + 24]',10
ftm_code_11_len equ $-ftm_code_11
ftm_code_12:
 db '    mov rdi, [r12]',10
 db '    mov esi, 0',10
 db '    call neboc_runtime_tag_test',10
 db '    mov r12, [r12 + 24]',10
ftm_code_12_len equ $-ftm_code_12
ftm_code_13:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, rsi',10
 db '    mov esi, 1',10
 db '    call neboc_runtime_unwrap_integer',10
 db '    mov r12, [r12 + 24]',10
ftm_code_13_len equ $-ftm_code_13
ftm_code_22:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_is_empty',10
 db '    mov r12, [r12 + 24]',10
ftm_code_22_len equ $-ftm_code_22
ftm_code_23:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    call nebo_runtime_textual_text_equals',10
 db '    mov r12, [r12 + 24]',10
ftm_code_23_len equ $-ftm_code_23
ftm_code_24:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    call nebo_runtime_textual_text_equals_ascii_ignore_case',10
 db '    mov r12, [r12 + 24]',10
ftm_code_24_len equ $-ftm_code_24
ftm_code_25:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    call nebo_runtime_textual_text_starts_with',10
 db '    mov r12, [r12 + 24]',10
ftm_code_25_len equ $-ftm_code_25
ftm_code_26:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    call nebo_runtime_textual_text_ends_with',10
 db '    mov r12, [r12 + 24]',10
ftm_code_26_len equ $-ftm_code_26
ftm_code_27:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    call nebo_runtime_textual_text_contains',10
 db '    mov r12, [r12 + 24]',10
ftm_code_27_len equ $-ftm_code_27
ftm_code_28:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    lea rdx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_index_of',10
 db '    mov r12, [r12 + 24]',10
ftm_code_28_len equ $-ftm_code_28
ftm_code_29:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    lea rdx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_last_index_of',10
 db '    mov r12, [r12 + 24]',10
ftm_code_29_len equ $-ftm_code_29
ftm_code_30:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_is_ascii',10
 db '    mov r12, [r12 + 24]',10
ftm_code_30_len equ $-ftm_code_30
ftm_code_31:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_is_utf8',10
 db '    mov r12, [r12 + 24]',10
ftm_code_31_len equ $-ftm_code_31
ftm_code_32:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_is_blank',10
 db '    mov r12, [r12 + 24]',10
ftm_code_32_len equ $-ftm_code_32
ftm_code_33:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_is_digits',10
 db '    mov r12, [r12 + 24]',10
ftm_code_33_len equ $-ftm_code_33
ftm_code_34:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_is_alpha_ascii',10
 db '    mov r12, [r12 + 24]',10
ftm_code_34_len equ $-ftm_code_34
ftm_code_35:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_is_alnum_ascii',10
 db '    mov r12, [r12 + 24]',10
ftm_code_35_len equ $-ftm_code_35
ftm_code_36:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12 + 8]',10
 db '    lea rsi, [r12 + 96]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 8], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    lea rdx, [r12 + 160]',10
 db '    mov ecx, 4096',10
 db '    lea r8, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_concat',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_36_len equ $-ftm_code_36
ftm_code_37:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_trim',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_37_len equ $-ftm_code_37
ftm_code_38:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_trim_start',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_38_len equ $-ftm_code_38
ftm_code_39:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_trim_end',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_39_len equ $-ftm_code_39
ftm_code_40:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_lower',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_40_len equ $-ftm_code_40
ftm_code_41:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_upper',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_41_len equ $-ftm_code_41
ftm_code_42:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_byte_slice',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_42_len equ $-ftm_code_42
ftm_code_43:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    lea rdx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_take_bytes',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_43_len equ $-ftm_code_43
ftm_code_44:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    lea rdx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_drop_bytes',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_44_len equ $-ftm_code_44
ftm_code_45:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_normalize_newlines',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_45_len equ $-ftm_code_45
ftm_code_46:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_normalize_whitespace',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_46_len equ $-ftm_code_46
ftm_code_47:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12 + 8]',10
 db '    lea rsi, [r12 + 96]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 8], rax',10
 db '    mov rdi, [r12 + 16]',10
 db '    lea rsi, [r12 + 128]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 16], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    lea rcx, [r12 + 160]',10
 db '    mov r8d, 4096',10
 db '    lea r9, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_replace_once',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_47_len equ $-ftm_code_47
ftm_code_48:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12 + 8]',10
 db '    lea rsi, [r12 + 96]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 8], rax',10
 db '    mov rdi, [r12 + 16]',10
 db '    lea rsi, [r12 + 128]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 16], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    lea rcx, [r12 + 160]',10
 db '    mov r8d, 4096',10
 db '    lea r9, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_replace_all',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_48_len equ $-ftm_code_48
ftm_code_49:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12 + 8]',10
 db '    lea rsi, [r12 + 96]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 8], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    lea rdx, [r12 + 160]',10
 db '    mov ecx, 254',10
 db '    lea r8, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_split',10
 db '    mov r12, [r12 + 24]',10
ftm_code_49_len equ $-ftm_code_49
ftm_code_50:
 db '    mov rdi, [r12 + 8]',10
 db '    lea rsi, [r12 + 96]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 8], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    lea rdx, [r12 + 160]',10
 db '    mov ecx, 4096',10
 db '    lea r8, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_join',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_50_len equ $-ftm_code_50
ftm_code_51:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12 + 16]',10
 db '    lea rsi, [r12 + 128]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 16], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    lea rcx, [r12 + 160]',10
 db '    mov r8d, 4096',10
 db '    lea r9, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_pad_start',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_51_len equ $-ftm_code_51
ftm_code_52:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12 + 16]',10
 db '    lea rsi, [r12 + 128]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 16], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    lea rcx, [r12 + 160]',10
 db '    mov r8d, 4096',10
 db '    lea r9, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_pad_end',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_52_len equ $-ftm_code_52
ftm_code_63:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_grapheme_count',10
 db '    mov r12, [r12 + 24]',10
ftm_code_63_len equ $-ftm_code_63
ftm_code_64:
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_normalize_nfc',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_64_len equ $-ftm_code_64
ftm_code_65:
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_normalize_nfd',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_65_len equ $-ftm_code_65
ftm_code_66:
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_case_fold',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_66_len equ $-ftm_code_66
ftm_code_67:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_slice_codepoints',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_67_len equ $-ftm_code_67
ftm_code_68:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_slice_graphemes',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_68_len equ $-ftm_code_68
align 8
ftm_code_53:
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_parse_int',10
 db '    mov r12, [r12 + 24]',10
ftm_code_53_len equ $-ftm_code_53
ftm_code_54:
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_parse_float',10
 db '    mov r12, [r12 + 24]',10
ftm_code_54_len equ $-ftm_code_54
ftm_code_55:
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_parse_bool',10
 db '    mov r12, [r12 + 24]',10
ftm_code_55_len equ $-ftm_code_55
ftm_code_56:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 80]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12 + 8]',10
 db '    lea rsi, [r12 + 112]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 8], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    lea rdx, [r12 + 32]',10
 db '    lea rcx, [r12 + 176]',10
 db '    mov r8d, 254',10
 db '    call nebo_runtime_textual_text_split_checked',10
 db '    mov r12, [r12 + 24]',10
ftm_code_56_len equ $-ftm_code_56
ftm_code_57:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 80]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12 + 8]',10
 db '    lea rsi, [r12 + 112]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 8], rax',10
 db '    mov rdi, [r12 + 16]',10
 db '    lea rsi, [r12 + 144]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 16], rax',10
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, [r12 + 16]',10
 db '    lea rcx, [r12 + 32]',10
 db '    lea r8, [r12 + 176]',10
 db '    mov r9d, 4096',10
 db '    call nebo_runtime_textual_text_replace_all_checked',10
 db '    mov r12, [r12 + 24]',10
ftm_code_57_len equ $-ftm_code_57
ftm_code_58:
 db '    mov rdi, [r12 + 0]',10
 db '    lea rsi, [r12 + 64]',10
 db '    call nebo_runtime_textual_native_descriptor',10
 db '    mov [r12 + 0], rax',10
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_text_to_text',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_58_len equ $-ftm_code_58
ftm_code_58_int:
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 160]',10
 db '    mov edx, 4096',10
 db '    lea rcx, [r12 + 32]',10
 db '    call nebo_runtime_textual_int_to_text',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_58_int_len equ $-ftm_code_58_int
ftm_code_58_bool:
 db '    mov rdi, [r12]',10
 db '    lea rsi, [r12 + 32]',10
 db '    call nebo_runtime_textual_bool_to_text',10
 db '    call nebo_runtime_textual_public_descriptor',10
 db '    mov r12, [r12 + 24]',10
ftm_code_58_bool_len equ $-ftm_code_58_bool
ftm_code_59:
 db '    mov rdi, [r12]',10
 db '    call nebo_runtime_textual_text_is_nebo_identifier',10
 db '    mov r12, [r12 + 24]',10
ftm_code_59_len equ $-ftm_code_59
ftm_code_60:
 db '    mov rdi, [r12]',10
 db '    mov esi, 0',10
 db '    call neboc_runtime_tag_test',10
 db '    mov r12, [r12 + 24]',10
ftm_code_60_len equ $-ftm_code_60
ftm_code_61:
 db '    mov rdi, [r12]',10
 db '    mov esi, 1',10
 db '    call neboc_runtime_tag_test',10
 db '    mov r12, [r12 + 24]',10
ftm_code_61_len equ $-ftm_code_61
ftm_code_62:
 db '    mov rdi, [r12]',10
 db '    mov rdx, [r12 + 8]',10
 db '    xor esi, esi',10
 db '    call neboc_runtime_unwrap_integer',10
 db '    mov r12, [r12 + 24]',10
ftm_code_62_len equ $-ftm_code_62
ftm_code_62_float:
 db '    mov rdi, [r12]',10
 db '    movq xmm0, [r12 + 8]',10
 db '    xor esi, esi',10
 db '    call neboc_runtime_unwrap_float',10
 db '    movq rax, xmm0',10
 db '    mov r12, [r12 + 24]',10
ftm_code_62_float_len equ $-ftm_code_62_float
ftm_code_62_text:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov edx, 4',10
 db '    call nebo_runtime_textual_checked_unwrap',10
 db '    mov r12, [r12 + 24]',10
ftm_code_62_text_len equ $-ftm_code_62_text
ftm_code_62_split:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov edx, 13',10
 db '    call nebo_runtime_textual_checked_unwrap',10
 db '    mov r12, [r12 + 24]',10
ftm_code_62_split_len equ $-ftm_code_62_split
ftm_methods:
 dq 1,0,160,0,0,ftm_code_1,ftm_code_1_len
 dq 2,0,160,0,0,ftm_code_2,ftm_code_2_len
 dq 11,0,160,0,0,ftm_code_11,ftm_code_11_len
 dq 12,0,160,0,0,ftm_code_12,ftm_code_12_len
 dq 13,1,160,3,0,ftm_code_13,ftm_code_13_len
 dq 22,0,160,0,0,ftm_code_22,ftm_code_22_len
 dq 23,1,160,4,0,ftm_code_23,ftm_code_23_len
 dq 24,1,160,4,0,ftm_code_24,ftm_code_24_len
 dq 25,1,160,4,0,ftm_code_25,ftm_code_25_len
 dq 26,1,160,4,0,ftm_code_26,ftm_code_26_len
 dq 27,1,160,4,0,ftm_code_27,ftm_code_27_len
 dq 28,1,160,4,0,ftm_code_28,ftm_code_28_len
 dq 29,1,160,4,0,ftm_code_29,ftm_code_29_len
 dq 30,0,160,0,0,ftm_code_30,ftm_code_30_len
 dq 31,0,160,0,0,ftm_code_31,ftm_code_31_len
 dq 32,0,160,0,0,ftm_code_32,ftm_code_32_len
 dq 33,0,160,0,0,ftm_code_33,ftm_code_33_len
 dq 34,0,160,0,0,ftm_code_34,ftm_code_34_len
 dq 35,0,160,0,0,ftm_code_35,ftm_code_35_len
 dq 36,1,4256,4,0,ftm_code_36,ftm_code_36_len
 dq 37,0,160,0,0,ftm_code_37,ftm_code_37_len
 dq 38,0,160,0,0,ftm_code_38,ftm_code_38_len
 dq 39,0,160,0,0,ftm_code_39,ftm_code_39_len
 dq 40,0,4256,0,0,ftm_code_40,ftm_code_40_len
 dq 41,0,4256,0,0,ftm_code_41,ftm_code_41_len
 dq 42,2,160,3,3,ftm_code_42,ftm_code_42_len
 dq 43,1,160,3,0,ftm_code_43,ftm_code_43_len
 dq 44,1,160,3,0,ftm_code_44,ftm_code_44_len
 dq 45,0,4256,0,0,ftm_code_45,ftm_code_45_len
 dq 46,0,4256,0,0,ftm_code_46,ftm_code_46_len
 dq 47,2,4256,4,4,ftm_code_47,ftm_code_47_len
 dq 48,2,4256,4,4,ftm_code_48,ftm_code_48_len
 dq 49,1,4256,4,0,ftm_code_49,ftm_code_49_len
 dq 50,1,4256,4,0,ftm_code_50,ftm_code_50_len
 dq 51,2,4256,3,4,ftm_code_51,ftm_code_51_len
 dq 52,2,4256,3,4,ftm_code_52,ftm_code_52_len
 dq 63,0,160,0,0,ftm_code_63,ftm_code_63_len
 dq 64,0,4256,0,0,ftm_code_64,ftm_code_64_len
 dq 65,0,4256,0,0,ftm_code_65,ftm_code_65_len
 dq 66,0,4256,0,0,ftm_code_66,ftm_code_66_len
 dq 67,2,160,3,3,ftm_code_67,ftm_code_67_len
 dq 68,2,160,3,3,ftm_code_68,ftm_code_68_len
 dq 53,0,160,0,0,ftm_code_53,ftm_code_53_len
 dq 54,0,160,0,0,ftm_code_54,ftm_code_54_len
 dq 55,0,160,0,0,ftm_code_55,ftm_code_55_len
 dq 56,1,4272,4,0,ftm_code_56,ftm_code_56_len
 dq 57,2,4272,4,4,ftm_code_57,ftm_code_57_len
 dq 58,0,4256,0,0,ftm_code_58,ftm_code_58_len
 dq 59,0,160,0,0,ftm_code_59,ftm_code_59_len
 dq 60,0,160,0,0,ftm_code_60,ftm_code_60_len
 dq 61,0,160,0,0,ftm_code_61,ftm_code_61_len
 dq 62,1,160,3,0,ftm_code_62,ftm_code_62_len
 dq 69,0,160,0,0,ftm_code_69,ftm_code_69_len
ftm_methods_end:
ftm_convert_int: dq 58,0,4256,0,0,ftm_code_58_int,ftm_code_58_int_len
ftm_convert_bool: dq 58,0,160,0,0,ftm_code_58_bool,ftm_code_58_bool_len
ftm_unwrap_bool: dq 62,1,160,2,0,ftm_code_62,ftm_code_62_len
ftm_unwrap_float: dq 62,1,160,9,0,ftm_code_62_float,ftm_code_62_float_len
ftm_unwrap_text: dq 62,1,160,4,0,ftm_code_62_text,ftm_code_62_text_len
ftm_unwrap_split: dq 62,1,160,4100,0,ftm_code_62_split,ftm_code_62_split_len

ftm_frame_head: db 32,32,32,32,109,111,118,32,114,49,49,44,32,114,115,112,10,32,32,32,32,115,117,98,32,114,49,49,44,32
ftm_frame_head_len equ $-ftm_frame_head
ftm_frame_tail: db 10,32,32,32,32,106,99,32,110,101,98,111,95,114,117,110,116,105,109,101,95,116,114,97,112,95,115,116,97,99,107,95,98,117,100,103,101,116,10,32,32,32,32,99,109,112,32,114,49,49,44,32,91,114,101,108,32,110,101,98,111,95,114,117,110,116,105,109,101,95,111,119,110,101,100,95,115,116,97,99,107,95,102,108,111,111,114,93,10,32,32,32,32,106,98,32,110,101,98,111,95,114,117,110,116,105,109,101,95,116,114,97,112,95,115,116,97,99,107,95,98,117,100,103,101,116,10,32,32,32,32,109,111,118,32,91,114,49,49,32,43,32,50,52,93,44,32,114,49,50,10,32,32,32,32,109,111,118,32,114,49,50,44,32,114,49,49,10,32,32,32,32,109,111,118,32,114,115,112,44,32,114,49,49,10
ftm_frame_tail_len equ $-ftm_frame_tail
ftm_store_head: db 32,32,32,32,109,111,118,32,91,114,49,50,32,43,32
ftm_store_head_len equ $-ftm_store_head
ftm_store_tail: db 93,44,32,114,97,120,10
ftm_store_tail_len equ $-ftm_store_tail
section .text
; state*, call id, canonical receiver TypeId -> StatusCode or -1 (other API).
fcg_emit_native_text_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov [rsp+16],rdx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r13,rax
 mov rdi,rbx
 mov rsi,r13
 mov rdx,[rsp+16]
 call fcg_text_contract_result
 test eax,eax
 jz .not_applicable
 lea r14,[rel ftm_methods]
.find:
 lea rax,[rel ftm_methods_end]
 cmp r14,rax
 jae .not_applicable
 cmp rcx,[r14]
 je .found
 add r14,56
 jmp .find
.found:
 mov rdi,r14
 mov rsi,[rsp+16]
 call fcg_native_text_select_row
 mov r14,rax
 mov rax,[r14+8]
 inc rax
 cmp rax,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad
 mov rdi,rbx
 lea rsi,[rel ftm_frame_head]
 mov edx,ftm_frame_head_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ftm_frame_tail]
 mov edx,ftm_frame_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov r15,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp],0
.argument:
 test r15,r15
 jz .bad
 cmp qword [rsp],0
 je .emit_argument
 mov rax,[rsp]
 mov rcx,[r14+rax*8+16]
 mov [rsp+8],rcx
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+8]
 jne .argument_type_error
.emit_argument:
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ftm_store_head]
 mov edx,ftm_store_head_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ftm_store_tail]
 mov edx,ftm_store_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rax,[rsp]
 inc rax
 mov [rsp],rax
 cmp rax,[r14+8]
 jbe .argument
 test r15,r15
 jnz .bad
 mov rdi,rbx
 mov rsi,[r14+40]
 mov rdx,[r14+48]
 call fcg_append
 jmp .done
.not_applicable:
 mov eax,-1
 jmp .done
.argument_type_error:
 mov rdi,rbx
 mov rsi,r13
 mov rdx,r14
 call fcg_native_text_validate_arguments
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TYPE_ASSERTION
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Infer only methods whose full argument/ABI handling exists above. This
; allows a bound Text receiver even when the older whole-program validator
; found no literal receiver. The emitter still validates every argument type.
fcg_native_text_candidate:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 mov r13,rax
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 xor edx,edx
 call fcg_textual_expr_type
 cmp rax,NEBOC_TYPE_ID_BYTES
 je .bytes_receiver
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .receiver
 cmp rax,FCG_TEXTUAL_OPTION_INT
 je .option
 cmp rax,FCG_TEXTUAL_SPLIT
 je .split_receiver
 cmp rax,NEBOC_TYPE_ID_INT
 je .receiver
 cmp rax,NEBOC_TYPE_ID_BOOL
 je .receiver
 cmp rax,NEBOC_FUNCTION_TYPE_TEXT_RESULT_INT
 jb .no
 cmp rax,NEBOC_FUNCTION_TYPE_TEXT_RESULT_SPLIT
 ja .no
 sub rax,4087
 jmp .receiver
.bytes_receiver:
 ; Bytes expressions use the same typed FunctionTable emitter as scalar
 ; methods; their descriptor value is no longer limited to static literals.
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_textual_expr_type
 test eax,eax
 jz .no
 mov rcx,rax
 jmp .private_ready
.split_receiver:
 mov eax,NEBOC_TYPE_ID_TEXT_SPLIT
 jmp .receiver
.option:
 mov eax,NEBOC_TYPE_ID_OPTION_INT
.receiver:
 mov [rsp+8],rax
 mov rdx,rax
 mov rdi,rbx
 mov rsi,r13
 call fcg_text_contract_result
 test eax,eax
 jz .no
 mov [rsp],rax
 lea rdx,[rel ftm_methods]
.find:
 lea rax,[rel ftm_methods_end]
 cmp rdx,rax
 jae .no
 cmp rcx,[rdx]
 je .found
 add rdx,56
 jmp .find
.found:
 mov rdi,rdx
 mov rsi,[rsp+8]
 call fcg_native_text_select_row
 mov rdx,rax
 mov rdi,rbx
 mov rsi,r13
 call fcg_native_text_validate_arguments
 test eax,eax
 jz .no
 mov rcx,[rsp]
 cmp rcx,NEBOC_TYPE_ID_OPTION_INT
 jne .split
 mov ecx,FCG_TEXTUAL_OPTION_INT
.split:
 cmp rcx,NEBOC_TYPE_ID_TEXT_SPLIT
 jne .yes
 mov ecx,FCG_TEXTUAL_SPLIT
.yes:
 cmp rcx,NEBOC_TYPE_ID_RESULT_INT_TEXT_ERROR
 jb .private_ready
 cmp rcx,NEBOC_TYPE_ID_RESULT_TEXT_SPLIT_TEXT_ERROR
 ja .private_ready
 add rcx,4087
.private_ready:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; Validate actual typed operands before a method can claim its result type.
; Preserve the first causal argument span and the public native API code.
; RDI state, RSI parsed CallExpr pointer, RDX native ABI table row.
fcg_native_text_validate_arguments:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r14,rdx
 mov rsi,[r12+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 xor r15d,r15d
.next:
 cmp r15,[r14+8]
 jae .complete
 test r13,r13
 jz .bad
 mov rax,[r14+r15*8+24]
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp]
 jne .type_error
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .next
.complete:
 test r13,r13
 jnz .bad
 mov eax,1
 jmp .done
.type_error:
 cmp qword [rbx+FCG_TEXT_ERROR],0
 jne .bad
 cmp qword [r14],NEBOC_API_METHOD_TEXT_IS_EMPTY
 jb .bad
 mov edx,NEBOC_API_DIAG_TEXT_RESULT_FALLBACK
 cmp qword [r14],NEBOC_API_METHOD_RESULT_UNWRAP_OR
 je .record
 mov edx,NEBOC_API_DIAG_ARGUMENT_MUST_BE_TEXT
 cmp qword [r14],NEBOC_API_METHOD_TEXT_IS_ALNUM_ASCII
 jbe .record
 mov edx,NEBOC_API_DIAG_TEXT_TRANSFORM_TEXT_ARGUMENT
 cmp qword [rsp],NEBOC_TYPE_ID_INT
 jne .record
 mov edx,NEBOC_API_DIAG_TEXT_TRANSFORM_INT_ARGUMENT
.record:
 mov [rbx+FCG_TEXT_ERROR],rdx
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rbx+FCG_TEXT_ERROR_START],rdx
 mov rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rbx+FCG_TEXT_ERROR_END],rdx
.bad:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Select an ABI specialization by the canonical receiver, retaining MethodId.
; RDI table row, RSI canonical receiver -> RAX selected row.
fcg_native_text_select_row:
 mov rax,rdi
 cmp qword [rdi],NEBOC_API_METHOD_TO_TEXT
 jne .result
 cmp rsi,NEBOC_TYPE_ID_INT
 je .integer_conversion
 cmp rsi,NEBOC_TYPE_ID_BOOL
 je .bool_conversion
 ret
.integer_conversion:
 lea rax,[rel ftm_convert_int]
 ret
.bool_conversion:
 lea rax,[rel ftm_convert_bool]
 ret
.result:
 cmp qword [rdi],NEBOC_API_METHOD_RESULT_UNWRAP_OR
 jne .done
 cmp rsi,NEBOC_TYPE_ID_RESULT_BOOL_TEXT_ERROR
 je .bool
 cmp rsi,NEBOC_TYPE_ID_RESULT_FLOAT_TEXT_ERROR
 je .float
 cmp rsi,NEBOC_TYPE_ID_RESULT_TEXT_TEXT_ERROR
 je .text
 cmp rsi,NEBOC_TYPE_ID_RESULT_TEXT_SPLIT_TEXT_ERROR
 je .split
 ret
.bool:
 lea rax,[rel ftm_unwrap_bool]
 ret
.float:
 lea rax,[rel ftm_unwrap_float]
 ret
.text:
 lea rax,[rel ftm_unwrap_text]
 ret
.split:
 lea rax,[rel ftm_unwrap_split]
.done:
 ret

section .rodata
ftm_code_69:
 db '%ifndef NEBO_TEXT_HASH_DECLARED',10,'%define NEBO_TEXT_HASH_DECLARED 1',10,'extern nebo_runtime_textual_text_hash',10,'%endif',10
 db '    mov rdi, [r12]',10,'    call nebo_runtime_textual_text_hash',10,'    mov r12, [r12+24]',10
ftm_code_69_len equ $-ftm_code_69
