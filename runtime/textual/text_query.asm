; COMPRIMENTO-IGUALDADE-PESQUISA-E-CLASSIFICACAO-DE-TEXT pure bounded Text queries.
bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_query.inc"
global neboc_text_byte_length
global neboc_text_is_empty
global neboc_text_equal
global neboc_text_compare_ascii
global neboc_text_starts_with
global neboc_text_ends_with
global neboc_text_contains
global neboc_text_find
global neboc_text_rfind
global neboc_text_classify
global neboc_text_query_profile
global neboc_text_query_cost
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
neboc_text_starts_with:
 test rdi,rdi
 jz match_null
 test rsi,rsi
 jz match_null
 mov rcx,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 cmp rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 ja match_false
 mov rdi,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov rsi,[rsi+NEBO_TEXT_DATA_OFFSET]
 repe cmpsb
 setz al
 movzx eax,al
 ret

align 16
neboc_text_ends_with:
 test rdi,rdi
 jz match_null
 test rsi,rsi
 jz match_null
 mov rcx,[rsi+NEBO_TEXT_LENGTH_OFFSET]
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

; Returns a bit mask for the bounded ASCII/validated-UTF8 profile.
align 16
neboc_text_classify:
 test rdi,rdi
 jz .class_null
 xor eax,eax
 mov r8,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 test r8,NEBO_TEXT_FLAG_ASCII
 jz .not_ascii_flag
 or eax,NEBO_QUERY_CLASS_ASCII
.not_ascii_flag:
 test r8,NEBO_TEXT_FLAG_VALID_UTF8
 jz .not_utf8_flag
 or eax,NEBO_QUERY_CLASS_UTF8
.not_utf8_flag:
 mov r8d,NEBO_QUERY_CLASS_BLANK | NEBO_QUERY_CLASS_DIGITS | NEBO_QUERY_CLASS_ALPHA | NEBO_QUERY_CLASS_ALNUM
 mov rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 test rcx,rcx
 jnz .class_loop_setup
 and r8d,NEBO_QUERY_CLASS_BLANK
 or eax,r8d
 ret
.class_loop_setup:
 mov rdi,[rdi+NEBO_TEXT_DATA_OFFSET]
.class_loop:
 mov dl,[rdi]
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
 and r8d,~NEBO_QUERY_CLASS_DIGITS
 jmp .blank_check
.is_digit:
 and r8d,~NEBO_QUERY_CLASS_ALPHA
.blank_check:
 cmp dl,' '
 je .next_class
 cmp dl,9
 je .next_class
 cmp dl,10
 je .next_class
 cmp dl,13
 je .next_class
 and r8d,~NEBO_QUERY_CLASS_BLANK
.next_class:
 inc rdi
 dec rcx
 jnz .class_loop
 or eax,r8d
 ret
.class_null:
 mov eax,-1
 ret

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
