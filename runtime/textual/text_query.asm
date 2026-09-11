; COMPRIMENTO-IGUALDADE-PESQUISA-E-CLASSIFICACAO-DE-TEXT pure bounded Text queries.
bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_query.inc"
%include "runtime/scalars/option_result_runtime.inc"
global neboc_text_byte_length
global neboc_text_is_empty
global neboc_text_equal
global neboc_text_equals_ascii_ignore_case
global neboc_text_compare_ascii
global neboc_text_starts_with
global neboc_text_ends_with
global neboc_text_contains
global neboc_text_find
global neboc_text_rfind
global neboc_text_classify
global neboc_text_query_profile
global neboc_text_query_cost
global nebo_runtime_textual_text_is_empty
global nebo_runtime_textual_text_equals
global nebo_runtime_textual_text_equals_ascii_ignore_case
global nebo_runtime_textual_text_starts_with
global nebo_runtime_textual_text_ends_with
global nebo_runtime_textual_text_contains
global nebo_runtime_textual_text_index_of
global nebo_runtime_textual_text_last_index_of
global nebo_runtime_textual_text_is_ascii
global nebo_runtime_textual_text_is_utf8
global nebo_runtime_textual_text_is_blank
global nebo_runtime_textual_text_is_digits
global nebo_runtime_textual_text_is_alpha_ascii
global nebo_runtime_textual_text_is_alnum_ascii
section .text
align 16
neboc_text_byte_length:
 test rdi,rdi
 jz .length_null
 mov rax,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 ret
.length_null:
 mov rax,-1
 ret
align 16
nebo_runtime_textual_text_is_empty:
neboc_text_is_empty:
 test rdi,rdi
 jz .empty_null
 xor eax,eax
 cmp qword [rdi+NEBO_TEXT_LENGTH_OFFSET],0
 sete al
 ret
.empty_null:
 mov eax,-1
 ret

align 16
nebo_runtime_textual_text_equals:
neboc_text_equal:
 test rdi,rdi
 jz .equal_null
 test rsi,rsi
 jz .equal_null
 mov rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp rcx,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 jne .not_equal
 mov rdi,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov rsi,[rsi+NEBO_TEXT_DATA_OFFSET]
 repe cmpsb
 setz al
 movzx eax,al
 ret
.not_equal:
 xor eax,eax
 ret
.equal_null:
 mov eax,-1
 ret

; ASCII-only case-insensitive equality. Non-ASCII input is outside this
; bounded comparison profile and therefore compares unequal.
align 16
nebo_runtime_textual_text_equals_ascii_ignore_case:
neboc_text_equals_ascii_ignore_case:
 test rdi,rdi
 jz .ascii_equal_null
 test rsi,rsi
 jz .ascii_equal_null
 mov rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp rcx,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 jne .ascii_equal_false
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r9,[rsi+NEBO_TEXT_DATA_OFFSET]
 xor edx,edx
.ascii_equal_loop:
 cmp rdx,rcx
 jae .ascii_equal_true
 mov al,[r8+rdx]
 mov r10b,[r9+rdx]
 test al,0x80
 jnz .ascii_equal_false
 test r10b,0x80
 jnz .ascii_equal_false
 cmp al,'A'
 jb .ascii_left_folded
 cmp al,'Z'
 ja .ascii_left_folded
 add al,32
.ascii_left_folded:
 cmp r10b,'A'
 jb .ascii_right_folded
 cmp r10b,'Z'
 ja .ascii_right_folded
 add r10b,32
.ascii_right_folded:
 cmp al,r10b
 jne .ascii_equal_false
 inc rdx
 jmp .ascii_equal_loop
.ascii_equal_true:
 mov eax,1
 ret
.ascii_equal_false:
 xor eax,eax
 ret
.ascii_equal_null:
 mov eax,-1
 ret

; Lexicographic unsigned-byte comparison: -1, 0, or 1.
align 16
neboc_text_compare_ascii:
 test rdi,rdi
 jz .compare_null
 test rsi,rsi
 jz .compare_null
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r9,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 mov rdi,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov rsi,[rsi+NEBO_TEXT_DATA_OFFSET]
 xor ecx,ecx
.compare_loop:
 cmp rcx,r8
 jae .compare_lengths
 cmp rcx,r9
 jae .greater
 mov al,[rdi+rcx]
 cmp al,[rsi+rcx]
 jb .less
 ja .greater
 inc rcx
 jmp .compare_loop
.compare_lengths:
 cmp r8,r9
 jb .less
 ja .greater
 xor eax,eax
 ret
.less:
 mov eax,-1
 ret
.greater:
 mov eax,1
 ret
.compare_null:
 mov eax,-2
 ret

align 16
nebo_runtime_textual_text_starts_with:
neboc_text_starts_with:
 test rdi,rdi
 jz match_null
 test rsi,rsi
 jz match_null
 mov rcx,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 test rcx,rcx
 jz match_true
 cmp rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 ja match_false
 mov rdi,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov rsi,[rsi+NEBO_TEXT_DATA_OFFSET]
 repe cmpsb
 setz al
 movzx eax,al
 ret

align 16
nebo_runtime_textual_text_ends_with:
neboc_text_ends_with:
 test rdi,rdi
 jz match_null
 test rsi,rsi
 jz match_null
 mov rcx,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 test rcx,rcx
 jz match_true
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp rcx,r8
 ja match_false
 sub r8,rcx
 mov rdi,[rdi+NEBO_TEXT_DATA_OFFSET]
 add rdi,r8
 mov rsi,[rsi+NEBO_TEXT_DATA_OFFSET]
 repe cmpsb
 setz al
 movzx eax,al
 ret

align 16
nebo_runtime_textual_text_contains:
neboc_text_contains:
 test rdi,rdi
 jz match_null
 test rsi,rsi
 jz match_null
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r9,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 test r9,r9
 jz match_true
 cmp r9,r8
 ja match_false
 mov r10,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r11,[rsi+NEBO_TEXT_DATA_OFFSET]
 sub r8,r9
 xor edx,edx
.contains_outer:
 cmp rdx,r8
 ja match_false
 xor ecx,ecx
.contains_inner:
 cmp rcx,r9
 jae match_true
 mov al,[r10+rdx]
 cmp al,[r11+rcx]
 jne .contains_next
 inc rdx
 inc rcx
 jmp .contains_inner
.contains_next:
 sub rdx,rcx
 inc rdx
 jmp .contains_outer
match_true:
 mov eax,1
 ret
match_false:
 xor eax,eax
 ret
match_null:
 mov eax,-1
 ret

; Option<Int> ABI: rax=index, or NEBO_QUERY_NOT_FOUND. Null is also none.
align 16
neboc_text_find:
 test rdi,rdi
 jz .find_none
 test rsi,rsi
 jz .find_none
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r9,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 test r9,r9
 jz .find_zero
 cmp r9,r8
 ja .find_none
 mov r10,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r11,[rsi+NEBO_TEXT_DATA_OFFSET]
 sub r8,r9
 xor eax,eax
.find_outer:
 cmp rax,r8
 ja .find_none
 xor ecx,ecx
.find_inner:
 cmp rcx,r9
 jae .find_done
 mov dl,[r10+rax]
 cmp dl,[r11+rcx]
 jne .find_next
 inc rax
 inc rcx
 jmp .find_inner
.find_next:
 sub rax,rcx
 inc rax
 jmp .find_outer
.find_done:
 sub rax,r9
 ret
.find_zero:
 xor eax,eax
 ret
.find_none:
 mov rax,NEBO_QUERY_NOT_FOUND
 ret

align 16
neboc_text_rfind:
 test rdi,rdi
 jz .rfind_none
 test rsi,rsi
 jz .rfind_none
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r9,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 cmp r9,r8
 ja .rfind_none
 sub r8,r9
 mov r10,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r11,[rsi+NEBO_TEXT_DATA_OFFSET]
 mov rax,r8
.rfind_outer:
 xor ecx,ecx
.rfind_inner:
 cmp rcx,r9
 jae .rfind_done
 mov dl,[r10+rax]
 cmp dl,[r11+rcx]
 jne .rfind_next
 inc rax
 inc rcx
 jmp .rfind_inner
.rfind_next:
 sub rax,rcx
 test rax,rax
 jz .rfind_none
 dec rax
 jmp .rfind_outer
.rfind_done:
 sub rax,r9
 ret
.rfind_none:
 mov rax,NEBO_QUERY_NOT_FOUND
 ret

; Public Option<Int> wrappers use the canonical 16-byte caller-owned slot.
; RDI=haystack, RSI=needle, RDX=slot; RAX=slot.
align 16
nebo_runtime_textual_text_index_of:
 push rdx
 call neboc_text_find
 pop rdx
 pxor xmm0,xmm0
 movdqu [rdx],xmm0
 cmp rax,NEBO_QUERY_NOT_FOUND
 je .index_option_done
 mov byte [rdx+NEBO_RUNTIME_TAG_OFFSET],NEBO_RUNTIME_OPTION_SOME
 mov [rdx+NEBO_RUNTIME_PAYLOAD_OFFSET],rax
.index_option_done:
 mov rax,rdx
 ret

align 16
nebo_runtime_textual_text_last_index_of:
 push rdx
 call neboc_text_rfind
 pop rdx
 pxor xmm0,xmm0
 movdqu [rdx],xmm0
 cmp rax,NEBO_QUERY_NOT_FOUND
 je .last_index_option_done
 mov byte [rdx+NEBO_RUNTIME_TAG_OFFSET],NEBO_RUNTIME_OPTION_SOME
 mov [rdx+NEBO_RUNTIME_PAYLOAD_OFFSET],rax
.last_index_option_done:
 mov rax,rdx
 ret

; Returns a bit mask for the bounded ASCII/validated-UTF8 profile.
align 16
neboc_text_classify:
 test rdi,rdi
 jz .class_null
 push rbx
 sub rsp,16
 mov rbx,rdi
 mov r8d,NEBO_QUERY_CLASS_ASCII | NEBO_QUERY_CLASS_BLANK | NEBO_QUERY_CLASS_DIGITS | NEBO_QUERY_CLASS_ALPHA | NEBO_QUERY_CLASS_ALNUM
 mov rcx,[rbx+NEBO_TEXT_LENGTH_OFFSET]
 test rcx,rcx
 jnz .class_loop_setup
 mov r8d,NEBO_QUERY_CLASS_ASCII | NEBO_QUERY_CLASS_BLANK
 jmp .class_utf8
.class_loop_setup:
 mov rdi,[rbx+NEBO_TEXT_DATA_OFFSET]
.class_loop:
 mov dl,[rdi]
 test dl,0x80
 jnz .class_non_ascii
 cmp dl,'0'
 jb .not_digit
 cmp dl,'9'
 jbe .is_digit
.not_digit:
 and r8d,~NEBO_QUERY_CLASS_DIGITS
 cmp dl,'A'
 jb .not_alpha
 cmp dl,'Z'
 jbe .is_alpha
 cmp dl,'a'
 jb .not_alpha
 cmp dl,'z'
 jbe .is_alpha
.not_alpha:
 and r8d,~(NEBO_QUERY_CLASS_ALPHA | NEBO_QUERY_CLASS_ALNUM)
 jmp .blank_check
.is_alpha:
 and r8d,~(NEBO_QUERY_CLASS_DIGITS | NEBO_QUERY_CLASS_BLANK)
 jmp .blank_check
.is_digit:
 and r8d,~(NEBO_QUERY_CLASS_ALPHA | NEBO_QUERY_CLASS_BLANK)
.blank_check:
 cmp dl,' '
 je .is_blank
 cmp dl,9
 je .is_blank
 cmp dl,10
 je .is_blank
 cmp dl,13
 je .is_blank
 and r8d,~NEBO_QUERY_CLASS_BLANK
 jmp .next_class
.is_blank:
 and r8d,~(NEBO_QUERY_CLASS_DIGITS | NEBO_QUERY_CLASS_ALPHA | NEBO_QUERY_CLASS_ALNUM)
 jmp .next_class
.class_non_ascii:
 and r8d,~(NEBO_QUERY_CLASS_ASCII | NEBO_QUERY_CLASS_BLANK | NEBO_QUERY_CLASS_DIGITS | NEBO_QUERY_CLASS_ALPHA | NEBO_QUERY_CLASS_ALNUM)
.next_class:
 inc rdi
 dec rcx
 jnz .class_loop
.class_utf8:
 mov [rsp],r8d
 mov rdi,rbx
 call text_query_utf8_valid
 mov r8d,[rsp]
 test eax,eax
 jz .class_done
 or r8d,NEBO_QUERY_CLASS_UTF8
.class_done:
 mov eax,r8d
 add rsp,16
 pop rbx
 ret
.class_null:
 mov eax,-1
 ret

; Strict whole-input UTF-8 validation. Empty is valid; overlong encodings,
; surrogates, values above U+10FFFF and truncated sequences are rejected.
text_query_utf8_valid:
 test rdi,rdi
 jz .utf8_false
 mov rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 test rcx,rcx
 jz .utf8_true
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 test r8,r8
 jz .utf8_false
 xor edx,edx
.utf8_loop:
 cmp rdx,rcx
 jae .utf8_true
 movzx eax,byte [r8+rdx]
 cmp eax,0x80
 jb .utf8_one
 cmp eax,0xc2
 jb .utf8_false
 cmp eax,0xdf
 jbe .utf8_two
 cmp eax,0xef
 jbe .utf8_three
 cmp eax,0xf4
 jbe .utf8_four
 jmp .utf8_false
.utf8_one:
 inc rdx
 jmp .utf8_loop
.utf8_two:
 lea r9,[rdx+2]
 cmp r9,rcx
 ja .utf8_false
 movzx r10d,byte [r8+rdx+1]
 and r10d,0xc0
 cmp r10d,0x80
 jne .utf8_false
 mov rdx,r9
 jmp .utf8_loop
.utf8_three:
 lea r9,[rdx+3]
 cmp r9,rcx
 ja .utf8_false
 movzx r10d,byte [r8+rdx+1]
 movzx r11d,byte [r8+rdx+2]
 mov esi,r10d
 and esi,0xc0
 cmp esi,0x80
 jne .utf8_false
 mov esi,r11d
 and esi,0xc0
 cmp esi,0x80
 jne .utf8_false
 cmp al,0xe0
 jne .utf8_not_e0
 cmp r10b,0xa0
 jb .utf8_false
.utf8_not_e0:
 cmp al,0xed
 jne .utf8_three_ok
 cmp r10b,0xa0
 jae .utf8_false
.utf8_three_ok:
 mov rdx,r9
 jmp .utf8_loop
.utf8_four:
 lea r9,[rdx+4]
 cmp r9,rcx
 ja .utf8_false
 movzx r10d,byte [r8+rdx+1]
 movzx r11d,byte [r8+rdx+2]
 mov esi,r10d
 and esi,0xc0
 cmp esi,0x80
 jne .utf8_false
 mov esi,r11d
 and esi,0xc0
 cmp esi,0x80
 jne .utf8_false
 movzx esi,byte [r8+rdx+3]
 and esi,0xc0
 cmp esi,0x80
 jne .utf8_false
 cmp al,0xf0
 jne .utf8_not_f0
 cmp r10b,0x90
 jb .utf8_false
.utf8_not_f0:
 cmp al,0xf4
 jne .utf8_four_ok
 cmp r10b,0x90
 jae .utf8_false
.utf8_four_ok:
 mov rdx,r9
 jmp .utf8_loop
.utf8_true:
 mov eax,1
 ret
.utf8_false:
 xor eax,eax
 ret

%macro TEXT_QUERY_CLASS_PREDICATE 2
align 16
%1:
 sub rsp,8
 call neboc_text_classify
 add rsp,8
 test eax,%2
 setnz al
 movzx eax,al
 ret
%endmacro

TEXT_QUERY_CLASS_PREDICATE nebo_runtime_textual_text_is_ascii, NEBO_QUERY_CLASS_ASCII
TEXT_QUERY_CLASS_PREDICATE nebo_runtime_textual_text_is_utf8, NEBO_QUERY_CLASS_UTF8
TEXT_QUERY_CLASS_PREDICATE nebo_runtime_textual_text_is_blank, NEBO_QUERY_CLASS_BLANK
TEXT_QUERY_CLASS_PREDICATE nebo_runtime_textual_text_is_digits, NEBO_QUERY_CLASS_DIGITS
TEXT_QUERY_CLASS_PREDICATE nebo_runtime_textual_text_is_alpha_ascii, NEBO_QUERY_CLASS_ALPHA
TEXT_QUERY_CLASS_PREDICATE nebo_runtime_textual_text_is_alnum_ascii, NEBO_QUERY_CLASS_ALNUM

align 16
neboc_text_query_profile:
 mov eax,NEBO_QUERY_PROFILE_SCALAR_DETERMINISTIC
 ret

; rdi=haystack bytes, rsi=needle bytes. rax=bounded worst-case comparisons, -1 over limit.
align 16
neboc_text_query_cost:
 mov rax,rdi
 test rsi,rsi
 jnz .cost_multiply
 mov esi,1
.cost_multiply:
 mul rsi
 test rdx,rdx
 jnz .cost_limit
 cmp rax,NEBO_QUERY_COST_LIMIT
 ja .cost_limit
 ret
.cost_limit:
 mov rax,-1
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
