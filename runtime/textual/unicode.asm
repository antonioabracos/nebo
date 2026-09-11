; UNICODE-CODE-POINTS-GRAPHEMES-NORMALIZACAO-E-LOCALE versioned bounded Unicode primitives.
bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
global neboc_utf8_next
%ifndef NEBO_RUNTIME_CORE_EMBED
global neboc_utf8_validate
%endif
global neboc_codepoint_count
global neboc_codepoint_slice
global neboc_grapheme_count
global neboc_grapheme_slice
global neboc_unicode_profile_version
global neboc_unicode_normalize_latin
global neboc_unicode_casefold_root
global neboc_unicode_locale_supported
global neboc_unicode_collate_root
global neboc_unicode_table_version
global neboc_unicode_table_bytes
global neboc_unicode_budget_check
global nebo_runtime_textual_text_grapheme_count
global nebo_runtime_textual_text_normalize_nfc
global nebo_runtime_textual_text_normalize_nfd
global nebo_runtime_textual_text_case_fold
global nebo_runtime_textual_text_slice_codepoints
global nebo_runtime_textual_text_slice_graphemes
section .text
; rdi=bytes, rsi=length, rdx=offset, rcx=out codepoint, r8=out next offset.
align 16
neboc_utf8_next:
 test rdi,rdi
 jz .next_null
 test rcx,rcx
 jz .next_null
 test r8,r8
 jz .next_null
 cmp rdx,rsi
 jae .next_bounds
 movzx eax,byte [rdi+rdx]
 cmp eax,0x80
 jb .next_ascii
 cmp eax,0xc2
 jb .next_invalid
 cmp eax,0xdf
 jbe .next_two
 cmp eax,0xef
 jbe .next_three
 cmp eax,0xf4
 jbe .next_four
 jmp .next_invalid
.next_ascii:
 lea r9,[rdx+1]
 jmp .next_commit
.next_two:
 lea r9,[rdx+2]
 cmp r9,rsi
 ja .next_invalid
 movzx r10d,byte [rdi+rdx+1]
 mov r11d,r10d
 and r11d,0xc0
 cmp r11d,0x80
 jne .next_invalid
 and eax,0x1f
 shl eax,6
 and r10d,0x3f
 or eax,r10d
 jmp .next_commit
.next_three:
 lea r9,[rdx+3]
 cmp r9,rsi
 ja .next_invalid
 movzx r10d,byte [rdi+rdx+1]
 mov r11d,r10d
 and r11d,0xc0
 cmp r11d,0x80
 jne .next_invalid
 movzx r11d,byte [rdi+rdx+2]
 mov r9d,r11d
 and r9d,0xc0
 cmp r9d,0x80
 jne .next_invalid
 cmp al,0xe0
 jne .three_not_e0
 cmp r10b,0xa0
 jb .next_invalid
.three_not_e0:
 cmp al,0xed
 jne .three_decode
 cmp r10b,0xa0
 jae .next_invalid
.three_decode:
 and eax,0x0f
 shl eax,12
 and r10d,0x3f
 shl r10d,6
 or eax,r10d
 and r11d,0x3f
 or eax,r11d
 lea r9,[rdx+3]
 jmp .next_commit
.next_four:
 lea r9,[rdx+4]
 cmp r9,rsi
 ja .next_invalid
 movzx r10d,byte [rdi+rdx+1]
 mov r11d,r10d
 and r11d,0xc0
 cmp r11d,0x80
 jne .next_invalid
 movzx r11d,byte [rdi+rdx+2]
 mov r9d,r11d
 and r9d,0xc0
 cmp r9d,0x80
 jne .next_invalid
 movzx r9d,byte [rdi+rdx+3]
 mov esi,r9d
 and esi,0xc0
 cmp esi,0x80
 jne .next_invalid
 cmp al,0xf0
 jne .four_not_f0
 cmp r10b,0x90
 jb .next_invalid
.four_not_f0:
 cmp al,0xf4
 jne .four_decode
 cmp r10b,0x90
 jae .next_invalid
.four_decode:
 and eax,7
 shl eax,18
 and r10d,0x3f
 shl r10d,12
 or eax,r10d
 and r11d,0x3f
 shl r11d,6
 or eax,r11d
 and r9d,0x3f
 or eax,r9d
 lea r9,[rdx+4]
.next_commit:
 mov [rcx],eax
 mov [r8],r9
 xor eax,eax
 ret
.next_null:
 mov eax,NEBO_UNICODE_NULL
 ret
.next_bounds:
 mov eax,NEBO_UNICODE_BOUNDS
 ret
.next_invalid:
 mov eax,NEBO_UNICODE_INVALID_UTF8
 ret

; rdi=Text descriptor, rsi=out failing offset. Validates whole input.
align 16
neboc_utf8_validate:
 test rdi,rdi
 jz .validate_null
 test rsi,rsi
 jz .validate_null
 mov rax,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp rax,NEBO_UNICODE_MAX_INPUT_BYTES
 ja .validate_bounds
 sub rsp,56
 mov rdx,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov [rsp+16],rdx
 mov [rsp+24],rax
 mov qword [rsp+32],0
 mov [rsp+40],rsi
.validate_loop:
 mov rdx,[rsp+32]
 cmp rdx,[rsp+24]
 jae .validate_ok
 mov rdi,[rsp+16]
 mov rsi,[rsp+24]
 lea rcx,[rsp]
 lea r8,[rsp+8]
 call neboc_utf8_next
 test eax,eax
 jnz .validate_fail
 mov rax,[rsp+8]
 mov [rsp+32],rax
 jmp .validate_loop
.validate_ok:
 mov rdi,[rsp+40]
 mov qword [rdi],-1
 add rsp,56
 xor eax,eax
 ret
.validate_fail:
 mov rdi,[rsp+40]
 mov rdx,[rsp+32]
 mov [rdi],rdx
 add rsp,56
 ret
.validate_null:
 mov eax,NEBO_UNICODE_NULL
 ret
.validate_bounds:
 mov eax,NEBO_UNICODE_BOUNDS
 ret

; rdi=validated UTF-8 Text descriptor. rax=count or -typed-error.
align 16
neboc_codepoint_count:
 test rdi,rdi
 jz .cp_count_null
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .cp_count_invalid
 mov rcx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 xor eax,eax
 xor edx,edx
.cp_count_loop:
 cmp rdx,rcx
 jae .cp_count_done
 mov r9b,[r8+rdx]
 and r9b,0xc0
 cmp r9b,0x80
 je .cp_count_next
 inc rax
.cp_count_next:
 inc rdx
 jmp .cp_count_loop
.cp_count_done:
 ret
.cp_count_null:
 mov rax,-NEBO_UNICODE_NULL
 ret
.cp_count_invalid:
 mov rax,-NEBO_UNICODE_INVALID_UTF8
 ret

; rdi=validated Text, rsi=start codepoint, rdx=count, rcx=out immutable view.
align 16
neboc_codepoint_slice:
 test rdi,rdi
 jz .cp_slice_null
 test rcx,rcx
 jz .cp_slice_null
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .cp_slice_invalid
 add rdx,rsi
 jc .cp_slice_bounds
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r9,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 push rbx
 xor r10d,r10d
 xor r11d,r11d
 mov rax,-1
 mov rbx,-1
.cp_slice_loop:
 cmp r10,r9
 jae .cp_slice_end
 mov dil,[r8+r10]
 and dil,0xc0
 cmp dil,0x80
 je .cp_slice_byte_next
 cmp r11,rsi
 jne .cp_slice_check_end
 mov rax,r10
.cp_slice_check_end:
 cmp r11,rdx
 jne .cp_slice_count_next
 mov rbx,r10
 jmp .cp_slice_commit
.cp_slice_count_next:
 inc r11
.cp_slice_byte_next:
 inc r10
 jmp .cp_slice_loop
.cp_slice_end:
 cmp r11,rsi
 jne .cp_slice_end_check
 mov rax,r9
.cp_slice_end_check:
 cmp r11,rdx
 jne .cp_slice_bounds_saved
 mov rbx,r9
.cp_slice_commit:
 cmp rax,-1
 je .cp_slice_bounds_saved
 cmp rbx,-1
 je .cp_slice_bounds_saved
 add r8,rax
 sub rbx,rax
 mov [rcx+NEBO_TEXT_DATA_OFFSET],r8
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],rbx
 mov qword [rcx+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [rcx+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_BORROWED
 pop rbx
 xor eax,eax
 ret
.cp_slice_bounds_saved:
 pop rbx
.cp_slice_bounds:
 mov eax,NEBO_UNICODE_BOUNDS
 ret
.cp_slice_null:
 mov eax,NEBO_UNICODE_NULL
 ret
.cp_slice_invalid:
 mov eax,NEBO_UNICODE_INVALID_UTF8
 ret

; Bounded grapheme profile: CRLF, U+0300..U+036F combining extends and
; Extended_Pictographic-style UTF-8 sequences connected by U+200D ZWJ.
align 16
neboc_grapheme_count:
 test rdi,rdi
 jz .gr_count_null
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .gr_count_invalid
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r9,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 xor eax,eax
 xor ecx,ecx
.gr_count_loop:
 cmp rcx,r9
 jae .gr_count_done
 mov dl,[r8+rcx]
 cmp rcx,3
 jb .gr_count_current
 cmp word [r8+rcx-3],0x80e2
 jne .gr_count_current
 cmp byte [r8+rcx-1],0x8d
 je .gr_count_advance
.gr_count_current:
 cmp dl,0xe2
 jne .gr_count_extend
 lea r10,[rcx+3]
 cmp r10,r9
 ja .gr_count_extend
 cmp word [r8+rcx+1],0x8d80
 je .gr_count_advance
.gr_count_extend:
 cmp dl,0xcc
 je .gr_count_advance
 cmp dl,0xcd
 jne .gr_count_crlf
 cmp byte [r8+rcx+1],0xaf
 jbe .gr_count_advance
.gr_count_crlf:
 cmp dl,10
 jne .gr_count_boundary
 test rcx,rcx
 jz .gr_count_boundary
 cmp byte [r8+rcx-1],13
 je .gr_count_advance
.gr_count_boundary:
 inc rax
.gr_count_advance:
 cmp dl,0x80
 jb .gr_advance_one
 cmp dl,0xe0
 jb .gr_advance_two
 cmp dl,0xf0
 jb .gr_advance_three
 add rcx,4
 jmp .gr_count_loop
.gr_advance_three:
 add rcx,3
 jmp .gr_count_loop
.gr_advance_two:
 add rcx,2
 jmp .gr_count_loop
.gr_advance_one:
 inc rcx
 jmp .gr_count_loop
.gr_count_done:
 ret
.gr_count_null:
 mov rax,-NEBO_UNICODE_NULL
 ret
.gr_count_invalid:
 mov rax,-NEBO_UNICODE_INVALID_UTF8
 ret

; rdi=validated Text, rsi=start grapheme, rdx=count, rcx=out view.
align 16
neboc_grapheme_slice:
 test rdi,rdi
 jz .gr_slice_null
 test rcx,rcx
 jz .gr_slice_null
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .gr_slice_invalid
 add rdx,rsi
 jc .gr_slice_bounds
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r9,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 push rbx
 xor r10d,r10d
 xor r11d,r11d
 mov rax,-1
 mov rbx,-1
.gr_slice_loop:
 cmp r10,r9
 jae .gr_slice_end
 mov dil,[r8+r10]
 cmp r10,3
 jb .gr_slice_current
 cmp word [r8+r10-3],0x80e2
 jne .gr_slice_current
 cmp byte [r8+r10-1],0x8d
 je .gr_slice_advance
.gr_slice_current:
 cmp dil,0xe2
 jne .gr_slice_extend
 lea rbx,[r10+3]
 cmp rbx,r9
 ja .gr_slice_extend
 cmp word [r8+r10+1],0x8d80
 je .gr_slice_advance
.gr_slice_extend:
 cmp dil,0xcc
 je .gr_slice_advance
 cmp dil,0xcd
 jne .gr_slice_crlf
 cmp byte [r8+r10+1],0xaf
 jbe .gr_slice_advance
.gr_slice_crlf:
 cmp dil,10
 jne .gr_slice_boundary
 test r10,r10
 jz .gr_slice_boundary
 cmp byte [r8+r10-1],13
 je .gr_slice_advance
.gr_slice_boundary:
 cmp r11,rsi
 jne .gr_slice_check_end
 mov rax,r10
.gr_slice_check_end:
 cmp r11,rdx
 jne .gr_slice_next_cluster
 mov rbx,r10
 jmp .gr_slice_commit
.gr_slice_next_cluster:
 inc r11
.gr_slice_advance:
 cmp dil,0x80
 jb .gr_slice_one
 cmp dil,0xe0
 jb .gr_slice_two
 cmp dil,0xf0
 jb .gr_slice_three
 add r10,4
 jmp .gr_slice_loop
.gr_slice_three:
 add r10,3
 jmp .gr_slice_loop
.gr_slice_two:
 add r10,2
 jmp .gr_slice_loop
.gr_slice_one:
 inc r10
 jmp .gr_slice_loop
.gr_slice_end:
 cmp r11,rsi
 jne .gr_slice_end_check
 mov rax,r9
.gr_slice_end_check:
 cmp r11,rdx
 jne .gr_slice_bounds_saved
 mov rbx,r9
.gr_slice_commit:
 cmp rax,-1
 je .gr_slice_bounds_saved
 cmp rbx,-1
 je .gr_slice_bounds_saved
 add r8,rax
 sub rbx,rax
 mov [rcx+NEBO_TEXT_DATA_OFFSET],r8
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],rbx
 mov qword [rcx+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [rcx+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_BORROWED
 pop rbx
 xor eax,eax
 ret
.gr_slice_bounds_saved:
 pop rbx
.gr_slice_bounds:
 mov eax,NEBO_UNICODE_BOUNDS
 ret
.gr_slice_null:
 mov eax,NEBO_UNICODE_NULL
 ret
.gr_slice_invalid:
 mov eax,NEBO_UNICODE_INVALID_UTF8
 ret

align 16
neboc_unicode_profile_version:
 mov eax,NEBO_UNICODE_PROFILE_VERSION
 ret

; rdi=input, rsi=NFC/NFD, rdx=out bytes, rcx=capacity, r8=out descriptor.
; Versioned bounded table maps e + U+0301 <-> U+00E9; other UTF-8 is preserved.
align 16
neboc_unicode_normalize_latin:
 test rdi,rdi
 jz .norm_null
 test r8,r8
 jz .norm_null
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .norm_invalid
 cmp rsi,NEBO_NORMALIZE_NFC
 je .norm_mode_ok
 cmp rsi,NEBO_NORMALIZE_NFD
 jne .norm_unsupported
.norm_mode_ok:
 mov r9,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r10,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp r10,NEBO_UNICODE_MAX_INPUT_BYTES
 ja .norm_capacity
 mov rdi,rcx
 xor r11d,r11d
 xor eax,eax
.norm_size_loop:
 cmp r11,r10
 jae .norm_size_done
 cmp rsi,NEBO_NORMALIZE_NFC
 jne .norm_size_nfd
 lea rcx,[r11+3]
 cmp rcx,r10
 ja .norm_size_plain
 cmp byte [r9+r11],'e'
 jne .norm_size_plain
 cmp word [r9+r11+1],0x81cc
 jne .norm_size_plain
 add r11,3
 add rax,2
 jmp .norm_size_loop
.norm_size_nfd:
 lea rcx,[r11+2]
 cmp rcx,r10
 ja .norm_size_plain
 cmp word [r9+r11],0xa9c3
 jne .norm_size_plain
 add r11,2
 add rax,3
 jmp .norm_size_loop
.norm_size_plain:
 inc r11
 inc rax
 jmp .norm_size_loop
.norm_size_done:
 cmp rax,rdi
 ja .norm_capacity
 test rax,rax
 jz .norm_commit_empty
 test rdx,rdx
 jz .norm_null
 xor r11d,r11d
 xor ecx,ecx
.norm_copy_loop:
 cmp r11,r10
 jae .norm_commit
 cmp rsi,NEBO_NORMALIZE_NFC
 jne .norm_copy_nfd
 lea rax,[r11+3]
 cmp rax,r10
 ja .norm_copy_plain
 cmp byte [r9+r11],'e'
 jne .norm_copy_plain
 cmp word [r9+r11+1],0x81cc
 jne .norm_copy_plain
 mov word [rdx+rcx],0xa9c3
 add r11,3
 add rcx,2
 jmp .norm_copy_loop
.norm_copy_nfd:
 lea rax,[r11+2]
 cmp rax,r10
 ja .norm_copy_plain
 cmp word [r9+r11],0xa9c3
 jne .norm_copy_plain
 mov byte [rdx+rcx],'e'
 mov word [rdx+rcx+1],0x81cc
 add r11,2
 add rcx,3
 jmp .norm_copy_loop
.norm_copy_plain:
 mov al,[r9+r11]
 mov [rdx+rcx],al
 inc r11
 inc rcx
 jmp .norm_copy_loop
.norm_commit_empty:
 xor ecx,ecx
.norm_commit:
 mov [r8+NEBO_TEXT_DATA_OFFSET],rdx
 mov [r8+NEBO_TEXT_LENGTH_OFFSET],rcx
 mov qword [r8+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [r8+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 xor eax,eax
 ret
.norm_null:
 mov eax,NEBO_UNICODE_NULL
 ret
.norm_invalid:
 mov eax,NEBO_UNICODE_INVALID_UTF8
 ret
.norm_capacity:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret
.norm_unsupported:
 mov eax,NEBO_UNICODE_UNSUPPORTED
 ret

; rdi=input, rsi=out bytes, rdx=capacity, rcx=out descriptor.
; Root profile covers ASCII and Latin-1 simple one-to-one lowercase mappings.
align 16
neboc_unicode_casefold_root:
 test rdi,rdi
 jz .fold_null
 test rcx,rcx
 jz .fold_null
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .fold_invalid
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp r8,NEBO_UNICODE_MAX_INPUT_BYTES
 ja .fold_capacity
 cmp r8,rdx
 ja .fold_capacity
 test r8,r8
 jz .fold_commit
 test rsi,rsi
 jz .fold_null
 mov r9,[rdi+NEBO_TEXT_DATA_OFFSET]
 xor r10d,r10d
.fold_loop:
 cmp r10,r8
 jae .fold_commit
 mov al,[r9+r10]
 cmp al,'A'
 jb .fold_latin
 cmp al,'Z'
 ja .fold_latin
 add al,32
 mov [rsi+r10],al
 inc r10
 jmp .fold_loop
.fold_latin:
 cmp al,0xc3
 jne .fold_plain
 lea r11,[r10+2]
 cmp r11,r8
 ja .fold_plain
 mov dl,[r9+r10+1]
 cmp dl,0x80
 jb .fold_plain
 cmp dl,0x9e
 ja .fold_plain
 cmp dl,0x97
 je .fold_plain
 add dl,0x20
 mov byte [rsi+r10],0xc3
 mov [rsi+r10+1],dl
 add r10,2
 jmp .fold_loop
.fold_plain:
 mov [rsi+r10],al
 inc r10
 jmp .fold_loop
.fold_commit:
 mov [rcx+NEBO_TEXT_DATA_OFFSET],rsi
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],r8
 mov qword [rcx+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [rcx+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 xor eax,eax
 ret
.fold_null:
 mov eax,NEBO_UNICODE_NULL
 ret
.fold_invalid:
 mov eax,NEBO_UNICODE_INVALID_UTF8
 ret
.fold_capacity:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

align 16
neboc_unicode_locale_supported:
 xor eax,eax
 test edi,edi
 sete al
 ret

; rdi=lhs, rsi=rhs, edx=locale. Root is explicit codepoint/UTF-8 order.
align 16
neboc_unicode_collate_root:
 test edx,edx
 jnz .collate_unsupported
 test rdi,rdi
 jz .collate_null
 test rsi,rsi
 jz .collate_null
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r9,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 mov rdi,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov rsi,[rsi+NEBO_TEXT_DATA_OFFSET]
 xor ecx,ecx
.collate_loop:
 cmp rcx,r8
 jae .collate_lengths
 cmp rcx,r9
 jae .collate_greater
 mov al,[rdi+rcx]
 cmp al,[rsi+rcx]
 jb .collate_less
 ja .collate_greater
 inc rcx
 jmp .collate_loop
.collate_lengths:
 cmp r8,r9
 jb .collate_less
 ja .collate_greater
 xor eax,eax
 ret
.collate_less:
 mov eax,-1
 ret
.collate_greater:
 mov eax,1
 ret
.collate_null:
 mov eax,-NEBO_UNICODE_NULL
 ret
.collate_unsupported:
 mov eax,-NEBO_UNICODE_UNSUPPORTED
 ret

align 16
neboc_unicode_table_version:
 mov eax,NEBO_UNICODE_PROFILE_VERSION
 ret
align 16
neboc_unicode_table_bytes:
 mov eax,NEBO_UNICODE_TABLE_BYTES
 ret

; rdi=input bytes, rsi=requested output bytes. Enforces input and 3/2 expansion caps.
align 16
neboc_unicode_budget_check:
 cmp rdi,NEBO_UNICODE_MAX_INPUT_BYTES
 ja .unicode_budget_fail
 mov rax,rdi
 mov ecx,NEBO_UNICODE_MAX_EXPANSION_NUMERATOR
 mul rcx
 mov ecx,NEBO_UNICODE_MAX_EXPANSION_DENOMINATOR
 div rcx
 cmp rsi,rax
 ja .unicode_budget_fail
 xor eax,eax
 ret
.unicode_budget_fail:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

; Source-facing G057 ABI.  The generated program owns the bounded stack
; workspace; normalization and case folding return its descriptor, while
; slicing returns an immutable view descriptor.  Internal typed failures are
; mapped to a null descriptor and never publish partially initialized output.
%macro UNICODE_PUBLIC_ENTER 0
 push rbx
 sub rsp,32
 ; The public Text carrier is 24 bytes, while these native Unicode owners
 ; use a 32-byte descriptor and a different flags namespace. Materialize a
 ; native borrowed input without reading beyond the public carrier.
 test rdi,rdi
 jz unicode_public_invalid
 cmp word [rdi+20],1
 jne unicode_public_invalid
 mov rax,[rdi]
 mov [rsp],rax
 mov rax,[rdi+8]
 mov [rsp+8],rax
 mov qword [rsp+16],NEBO_TEXT_FLAG_VALID_UTF8
 mov [rsp+24],rdi
 mov rdi,rsp
%endmacro

align 16
nebo_runtime_textual_text_grapheme_count:
 UNICODE_PUBLIC_ENTER
 call neboc_grapheme_count
 jmp unicode_public_done

align 16
nebo_runtime_textual_text_normalize_nfc:
 UNICODE_PUBLIC_ENTER
 mov rbx,rcx
 mov r8,rcx
 mov rcx,rdx
 mov rdx,rsi
 mov esi,NEBO_NORMALIZE_NFC
 call neboc_unicode_normalize_latin
 jmp unicode_public_output

align 16
nebo_runtime_textual_text_normalize_nfd:
 UNICODE_PUBLIC_ENTER
 mov rbx,rcx
 mov r8,rcx
 mov rcx,rdx
 mov rdx,rsi
 mov esi,NEBO_NORMALIZE_NFD
 call neboc_unicode_normalize_latin
 jmp unicode_public_output

align 16
nebo_runtime_textual_text_case_fold:
 UNICODE_PUBLIC_ENTER
 mov rbx,rcx
 call neboc_unicode_casefold_root
 jmp unicode_public_output

align 16
nebo_runtime_textual_text_slice_codepoints:
 UNICODE_PUBLIC_ENTER
 mov rbx,rcx
 call neboc_codepoint_slice
 jmp unicode_public_output

align 16
nebo_runtime_textual_text_slice_graphemes:
 UNICODE_PUBLIC_ENTER
 mov rbx,rcx
 call neboc_grapheme_slice

unicode_public_output:
 test eax,eax
 jnz unicode_public_invalid
 ; Immutable UTF-8 value backed by the caller's function workspace. It is
 ; not static storage. Native AUX stays outside the public 24-byte prefix.
 mov dword [rbx+16],5
 mov word [rbx+20],1
 mov word [rbx+22],0
 mov rax,rbx
 jmp unicode_public_done
unicode_public_invalid:
 xor eax,eax
unicode_public_done:
 add rsp,32
 pop rbx
 ret
%unmacro UNICODE_PUBLIC_ENTER 0
section .note.GNU-stack noalloc noexec nowrite progbits
