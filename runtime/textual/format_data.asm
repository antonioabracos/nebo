; RF84 O5 bounded formats/data/tooling core
; SysV AMD64, caller-owned buffers, no C, no libc, no allocation.
bits 64
default rel

global format_front_state
global format_validate_kind
global format_check_limits
global format_detect
global delimited_scan
global json_validate
global ascii_upper_vector
global pattern_find
global format_normalize
global lint_text

%define OK          0
%define INVALID     1
%define LIMIT       2
%define CAPACITY    3
%define SYNTAX      4
%define NOT_FOUND   5
%define CONTRACT    1
%define INTERNAL    2
%define EXTERNAL    3
%define PUBLIC      4

section .text

; rdi=front sequence 1..44 -> eax=factual maturity class or INVALID.
format_front_state:
    cmp rdi, 1
    jb .invalid
    cmp rdi, 44
    ja .invalid
    mov eax, CONTRACT
    cmp rdi, 35
    jae .public
    cmp rdi, 21
    je .external
    cmp rdi, 22
    je .external
    cmp rdi, 23
    je .external
    cmp rdi, 25
    je .external
    cmp rdi, 27
    jb .specific
    cmp rdi, 34
    jbe .internal
.specific:
    cmp rdi, 1
    je .internal
    cmp rdi, 2
    je .internal
    cmp rdi, 4
    je .internal
    cmp rdi, 5
    je .internal
    cmp rdi, 6
    je .internal
    cmp rdi, 10
    je .internal
    cmp rdi, 11
    je .internal
    cmp rdi, 13
    je .internal
    cmp rdi, 36
    je .internal
    cmp rdi, 39
    jb .done
    cmp rdi, 43
    jbe .internal
.done:
    ret
.internal:
    mov eax, INTERNAL
    ret
.external:
    mov eax, EXTERNAL
    ret
.public:
    mov eax, PUBLIC
    ret
.invalid:
    mov eax, INVALID
    ret

; rdi=kind -> OK for the closed registry, INVALID otherwise.
format_validate_kind:
    xor eax, eax
    cmp rdi, 1
    jb .bad
    cmp rdi, 20
    ja .bad
    ret
.bad:
    mov eax, INVALID
    ret

; rdi=bytes, rsi=records, rdx=fields, rcx=depth.
format_check_limits:
    xor eax, eax
    cmp rdi, 4096
    ja .limit
    cmp rsi, 256
    ja .limit
    cmp rdx, 64
    ja .limit
    cmp rcx, 32
    ja .limit
    ret
.limit:
    mov eax, LIMIT
    ret

; rdi=bytes, rsi=len -> rax=kind, rdx=confidence 0..100.
; Detection is advisory only; it never confirms or parses a format.
format_detect:
    xor eax, eax
    xor edx, edx
    test rsi, rsi
    jz .return
    cmp rsi, 4096
    ja .return
    xor r8d, r8d
.skip_space:
    cmp r8, rsi
    jae .return
    movzx r9d, byte [rdi + r8]
    cmp r9b, ' '
    je .next_space
    cmp r9b, 9
    je .next_space
    cmp r9b, 10
    je .next_space
    cmp r9b, 13
    jne .marker
.next_space:
    inc r8
    jmp .skip_space
.marker:
    cmp r9b, '{'
    je .json
    cmp r9b, '['
    je .json
    cmp r9b, '#'
    je .markdown
    cmp r9b, '<'
    je .xml
    xor r8d, r8d
.scan:
    cmp r8, rsi
    jae .fallback
    movzx r9d, byte [rdi + r8]
    cmp r9b, 9
    je .tsv
    cmp r9b, ','
    je .csv
    cmp r9b, '='
    je .ini
    inc r8
    jmp .scan
.json:
    mov eax, 3
    mov edx, 95
    ret
.markdown:
    mov eax, 5
    mov edx, 80
    ret
.xml:
    mov eax, 9
    mov edx, 70
    ret
.tsv:
    mov eax, 2
    mov edx, 80
    ret
.csv:
    mov eax, 1
    mov edx, 75
    ret
.ini:
    mov eax, 12
    mov edx, 65
    ret
.fallback:
    mov eax, 7
    mov edx, 25
.return:
    ret

; rdi=data, rsi=len, rdx=delimiter, rcx=max fields per record.
; Returns rax=status, rdx=total fields, rcx=records. RFC-style doubled
; quotes are accepted and delimiters/newlines inside quotes are ignored.
delimited_scan:
    xor eax, eax
    test rsi, rsi
    jz .delim_ok_empty
    cmp rsi, 4096
    ja .delim_limit
    cmp dl, ','
    je .delimiter_valid
    cmp dl, 9
    jne .delim_invalid
.delimiter_valid:
    test rcx, rcx
    jz .delim_invalid
    cmp rcx, 64
    ja .delim_limit
    mov qword [rsp - 8], 0       ; in quotes
    mov qword [rsp - 16], 0      ; total fields
    mov qword [rsp - 24], 0      ; records
    mov qword [rsp - 32], 1      ; current fields
    mov qword [rsp - 40], 1      ; at field start
    mov qword [rsp - 48], 0      ; just closed a quoted field
    xor r9d, r9d
.delim_loop:
    cmp r9, rsi
    jae .delim_end
    movzx r8d, byte [rdi + r9]
    cmp r8b, '"'
    jne .delim_not_quote
    cmp qword [rsp - 8], 0
    je .delim_open_quote_check
    lea r10, [r9 + 1]
    cmp r10, rsi
    jae .delim_close_quote
    cmp byte [rdi + r10], '"'
    jne .delim_close_quote
    add r9, 2
    jmp .delim_loop
.delim_open_quote:
    mov qword [rsp - 8], 1
    mov qword [rsp - 40], 0
    mov qword [rsp - 48], 0
    inc r9
    jmp .delim_loop
.delim_open_quote_check:
    cmp qword [rsp - 40], 1
    jne .delim_syntax
    jmp .delim_open_quote
.delim_close_quote:
    mov qword [rsp - 8], 0
    mov qword [rsp - 48], 1
    inc r9
    jmp .delim_loop
.delim_not_quote:
    cmp qword [rsp - 8], 0
    jne .delim_next
    cmp qword [rsp - 48], 0
    je .delim_classify
    cmp r8b, dl
    je .delim_field
    cmp r8b, 10
    je .delim_record
    cmp r8b, 13
    je .delim_record
    jmp .delim_syntax
.delim_classify:
    cmp r8b, dl
    je .delim_field
    cmp r8b, 10
    je .delim_record
    cmp r8b, 13
    je .delim_record
    mov qword [rsp - 40], 0
.delim_next:
    inc r9
    jmp .delim_loop
.delim_field:
    inc qword [rsp - 32]
    mov r10, [rsp - 32]
    cmp r10, rcx
    ja .delim_limit
    mov qword [rsp - 40], 1
    mov qword [rsp - 48], 0
    inc r9
    jmp .delim_loop
.delim_record:
    mov r10, [rsp - 32]
    add [rsp - 16], r10
    inc qword [rsp - 24]
    mov qword [rsp - 32], 1
    mov qword [rsp - 40], 1
    mov qword [rsp - 48], 0
    cmp r8b, 13
    jne .delim_record_advance
    lea r10, [r9 + 1]
    cmp r10, rsi
    jae .delim_record_advance
    cmp byte [rdi + r10], 10
    jne .delim_record_advance
    inc r9
.delim_record_advance:
    inc r9
    jmp .delim_loop
.delim_end:
    cmp qword [rsp - 8], 0
    jne .delim_syntax
    cmp byte [rdi + rsi - 1], 10
    je .delim_return
    cmp byte [rdi + rsi - 1], 13
    je .delim_return
    mov r10, [rsp - 32]
    add [rsp - 16], r10
    inc qword [rsp - 24]
.delim_return:
    mov rdx, [rsp - 16]
    mov rcx, [rsp - 24]
    xor eax, eax
    ret
.delim_ok_empty:
    xor edx, edx
    xor ecx, ecx
    ret
.delim_invalid:
    mov eax, INVALID
    ret
.delim_limit:
    mov eax, LIMIT
    ret
.delim_syntax:
    mov eax, SYNTAX
    ret

; rdi=data, rsi=len, rdx=max depth -> bounded structural JSON validation.
; It checks root delimiters, strings/escapes, controls and balanced depth;
; it deliberately does not claim a complete JSON value model.
json_validate:
    test rsi, rsi
    jz .json_syntax
    cmp rsi, 4096
    ja .json_limit
    test rdx, rdx
    jz .json_invalid
    cmp rdx, 32
    ja .json_limit
    xor r8d, r8d
.json_leading:
    cmp r8, rsi
    jae .json_syntax
    movzx eax, byte [rdi + r8]
    cmp al, ' '
    je .json_lead_next
    cmp al, 9
    je .json_lead_next
    cmp al, 10
    je .json_lead_next
    cmp al, 13
    je .json_lead_next
    cmp al, '{'
    je .json_started
    cmp al, '['
    jne .json_syntax
.json_started:
    xor r9d, r9d                ; depth
    xor r10d, r10d              ; in string
    xor r11d, r11d              ; escape
    mov qword [rsp - 8], 0      ; root closed
.json_loop:
    cmp r8, rsi
    jae .json_end
    movzx eax, byte [rdi + r8]
    test r10, r10
    jz .json_outside
    test r11, r11
    jnz .json_escape_done
    cmp al, 92
    je .json_set_escape
    cmp al, '"'
    je .json_close_string
    cmp al, 32
    jb .json_syntax
    jmp .json_next
.json_set_escape:
    mov r11d, 1
    jmp .json_next
.json_escape_done:
    xor r11d, r11d
    jmp .json_next
.json_close_string:
    xor r10d, r10d
    jmp .json_next
.json_outside:
    cmp al, '"'
    je .json_open_string
    cmp al, '{'
    je .json_open
    cmp al, '['
    je .json_open
    cmp al, '}'
    je .json_close
    cmp al, ']'
    je .json_close
    cmp qword [rsp - 8], 0
    je .json_next
    cmp al, ' '
    je .json_next
    cmp al, 9
    je .json_next
    cmp al, 10
    je .json_next
    cmp al, 13
    jne .json_syntax
    jmp .json_next
.json_open_string:
    cmp qword [rsp - 8], 0
    jne .json_syntax
    mov r10d, 1
    jmp .json_next
.json_open:
    cmp qword [rsp - 8], 0
    jne .json_syntax
    inc r9
    cmp r9, rdx
    ja .json_limit
    jmp .json_next
.json_close:
    test r9, r9
    jz .json_syntax
    dec r9
    jnz .json_next
    mov qword [rsp - 8], 1
.json_next:
    inc r8
    jmp .json_loop
.json_end:
    test r10, r10
    jnz .json_syntax
    test r9, r9
    jnz .json_syntax
    cmp qword [rsp - 8], 1
    jne .json_syntax
    xor eax, eax
    ret
.json_lead_next:
    inc r8
    jmp .json_leading
.json_invalid:
    mov eax, INVALID
    ret
.json_limit:
    mov eax, LIMIT
    ret
.json_syntax:
    mov eax, SYNTAX
    ret

; rdi=array of {src,len,dst,capacity}, rsi=count. Two-pass validation
; provides collection-level failure atomicity before ASCII transformation.
ascii_upper_vector:
    cmp rsi, 64
    ja .vector_limit
    xor r8d, r8d
.vector_preflight:
    cmp r8, rsi
    jae .vector_copy_start
    mov r9, r8
    shl r9, 5
    add r9, rdi
    mov r10, [r9 + 8]
    cmp r10, 4096
    ja .vector_limit
    cmp [r9 + 24], r10
    jb .vector_capacity
    test r10, r10
    jz .vector_preflight_next
    cmp qword [r9], 0
    je .vector_invalid
    cmp qword [r9 + 16], 0
    je .vector_invalid
.vector_preflight_next:
    inc r8
    jmp .vector_preflight
.vector_copy_start:
    xor r8d, r8d
.vector_item:
    cmp r8, rsi
    jae .vector_ok
    mov r9, r8
    shl r9, 5
    add r9, rdi
    mov r10, [r9]
    mov r11, [r9 + 16]
    mov rcx, [r9 + 8]
    xor edx, edx
.vector_byte:
    cmp rdx, rcx
    jae .vector_item_done
    mov al, [r10 + rdx]
    cmp al, 'a'
    jb .vector_store
    cmp al, 'z'
    ja .vector_store
    sub al, 32
.vector_store:
    mov [r11 + rdx], al
    inc rdx
    jmp .vector_byte
.vector_item_done:
    inc r8
    jmp .vector_item
.vector_ok:
    xor eax, eax
    ret
.vector_invalid:
    mov eax, INVALID
    ret
.vector_limit:
    mov eax, LIMIT
    ret
.vector_capacity:
    mov eax, CAPACITY
    ret

; rdi=haystack,rsi=len,rdx=literal,rcx=literal len,r8=max steps.
; Returns rax=status, rdx=index or -1, r8=steps. This is intentionally a
; literal bounded subset, not a claim of a complete regex implementation.
pattern_find:
    test rcx, rcx
    jz .pattern_invalid
    cmp rsi, 4096
    ja .pattern_limit
    cmp rcx, 256
    ja .pattern_limit
    test r8, r8
    jz .pattern_limit
    cmp r8, 65536
    ja .pattern_limit
    cmp rcx, rsi
    ja .pattern_not_found_zero
    mov qword [rsp - 8], r8
    xor r9d, r9d
    xor r10d, r10d
.pattern_candidate:
    mov rax, rsi
    sub rax, rcx
    cmp r9, rax
    ja .pattern_not_found
    xor r11d, r11d
.pattern_compare:
    cmp r11, rcx
    jae .pattern_found
    cmp r10, [rsp - 8]
    jae .pattern_limit_steps
    inc r10
    add r9, r11
    mov al, [rdi + r9]
    mov r8b, [rdx + r11]
    sub r9, r11
    cmp al, r8b
    jne .pattern_next
    inc r11
    jmp .pattern_compare
.pattern_next:
    inc r9
    jmp .pattern_candidate
.pattern_found:
    xor eax, eax
    mov rdx, r9
    mov r8, r10
    ret
.pattern_not_found_zero:
    xor r10d, r10d
.pattern_not_found:
    mov eax, NOT_FOUND
    mov rdx, -1
    mov r8, r10
    ret
.pattern_invalid:
    mov eax, INVALID
    ret
.pattern_limit_steps:
    mov r8, r10
.pattern_limit:
    mov eax, LIMIT
    ret

; rdi=src,rsi=len,rdx=dst,rcx=capacity -> rax=status,rdx=out length.
; Normalizes CRLF/LF, trims trailing horizontal space, ensures final LF.
format_normalize:
    cmp rsi, 4096
    ja .normalize_limit
    mov rax, rsi
    inc rax
    cmp rcx, rax
    jb .normalize_capacity
    test rsi, rsi
    jz .normalize_empty
    test rdi, rdi
    jz .normalize_invalid
    test rdx, rdx
    jz .normalize_invalid
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
.normalize_loop:
    cmp r8, rsi
    jae .normalize_end
    mov al, [rdi + r8]
    cmp al, 10
    je .normalize_newline
    mov [rdx + r9], al
    inc r9
    inc r8
    jmp .normalize_loop
.normalize_newline:
.normalize_trim_line:
    cmp r9, r10
    jbe .normalize_write_lf
    mov al, [rdx + r9 - 1]
    cmp al, ' '
    je .normalize_drop
    cmp al, 9
    je .normalize_drop
    cmp al, 13
    jne .normalize_write_lf
.normalize_drop:
    dec r9
    jmp .normalize_trim_line
.normalize_write_lf:
    mov byte [rdx + r9], 10
    inc r9
    mov r10, r9
    inc r8
    jmp .normalize_loop
.normalize_end:
.normalize_trim_end:
    cmp r9, r10
    jbe .normalize_ensure_lf
    mov al, [rdx + r9 - 1]
    cmp al, ' '
    je .normalize_drop_end
    cmp al, 9
    je .normalize_drop_end
    cmp al, 13
    jne .normalize_ensure_lf
.normalize_drop_end:
    dec r9
    jmp .normalize_trim_end
.normalize_ensure_lf:
    test r9, r9
    jz .normalize_add_lf
    cmp byte [rdx + r9 - 1], 10
    je .normalize_ok
.normalize_add_lf:
    mov byte [rdx + r9], 10
    inc r9
.normalize_ok:
    xor eax, eax
    mov rdx, r9
    ret
.normalize_empty:
    test rdx, rdx
    jz .normalize_invalid
    mov byte [rdx], 10
    xor eax, eax
    mov edx, 1
    ret
.normalize_invalid:
    mov eax, INVALID
    ret
.normalize_limit:
    mov eax, LIMIT
    ret
.normalize_capacity:
    mov eax, CAPACITY
    ret

; rdi=text,rsi=len -> rax=status,rdx=bounded issue count.
lint_text:
    cmp rsi, 4096
    ja .lint_limit
    test rsi, rsi
    jz .lint_empty
    test rdi, rdi
    jz .lint_invalid
    xor edx, edx
    xor r8d, r8d
.lint_loop:
    cmp r8, rsi
    jae .lint_end
    mov al, [rdi + r8]
    cmp al, 9
    jne .lint_newline_check
    inc rdx
.lint_newline_check:
    cmp al, 10
    jne .lint_next
    test r8, r8
    jz .lint_next
    mov al, [rdi + r8 - 1]
    cmp al, ' '
    je .lint_trailing
    cmp al, 9
    je .lint_trailing
    cmp al, 13
    jne .lint_next
.lint_trailing:
    inc rdx
.lint_next:
    inc r8
    jmp .lint_loop
.lint_end:
    cmp byte [rdi + rsi - 1], 10
    je .lint_ok
    inc rdx
.lint_ok:
    xor eax, eax
    ret

.lint_empty:
    xor eax, eax
    mov edx, 1
    ret
.lint_invalid:
    mov eax, INVALID
    ret
.lint_limit:
    mov eax, LIMIT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
