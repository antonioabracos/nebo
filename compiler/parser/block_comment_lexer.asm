; G164 canonical nested-comment and whole-source trivia scanner.
; No allocation, libc, locale, network or normalization is used.
bits 64
default rel
%include "compiler/parser/block_comment.inc"

global neboc_block_comment_lexer
global neboc_comment_scan

section .text

; block_comment_lexer(source, remaining, result) -> status, EDX=bad offset.
; A successful scan consumes one complete outer block comment and permits
; following source bytes. The result remains byte-identical on every error.
align 16
neboc_block_comment_lexer:
    test rdi,rdi
    jz .argument
    test rdx,rdx
    jz .argument
    test rdx,7
    jnz .argument
    cmp rsi,4
    jb .length
    cmp rsi,NEBOC_COMMENT_MAX_SOURCE_BYTES
    ja .length
    cmp word [rdi],0x2a2f
    jne .syntax
    push rbx
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov ebx,1
    mov r8d,1
    mov r9d,1
    xor r10d,r10d
    mov ecx,2
.scan:
    cmp rcx,r13
    jae .unterminated_saved
    movzx eax,byte [r12+rcx]
    cmp al,10
    jne .maybe_open
    inc r10
.maybe_open:
    lea r11,[rcx+1]
    cmp r11,r13
    jae .advance
    cmp al,'/'
    jne .maybe_close
    cmp byte [r12+rcx+1],'*'
    jne .advance
    inc ebx
    cmp ebx,NEBOC_COMMENT_MAX_NESTING
    ja .depth_saved
    inc r9
    cmp ebx,r8d
    cmova r8d,ebx
    add ecx,2
    jmp .scan
.maybe_close:
    cmp al,'*'
    jne .advance
    cmp byte [r12+rcx+1],'/'
    jne .advance
    dec ebx
    add ecx,2
    test ebx,ebx
    jnz .scan
    push rcx
    push r8
    push r9
    push r10
    mov rdi,r12
    mov rsi,rcx
    call neboc_comment_utf8_validate
    mov r11d,eax
    pop r10
    pop r9
    pop r8
    pop rcx
    test r11d,r11d
    jnz .encoding_saved
    xor eax,eax
    test r10,r10
    setnz al
    mov [r14+NEBOC_BLOCK_RESULT_CONSUMED_OFFSET],rcx
    mov [r14+NEBOC_BLOCK_RESULT_MAX_DEPTH_OFFSET],r8
    mov [r14+NEBOC_BLOCK_RESULT_COMMENT_COUNT_OFFSET],r9
    mov [r14+NEBOC_BLOCK_RESULT_LINE_BREAKS_OFFSET],r10
    mov [r14+NEBOC_BLOCK_RESULT_FLAGS_OFFSET],rax
    pop r14
    pop r13
    pop r12
    pop rbx
    xor eax,eax
    xor edx,edx
    ret
.advance:
    inc rcx
    jmp .scan
.encoding_saved:
    mov edx,r11d
    pop r14
    pop r13
    pop r12
    pop rbx
    mov eax,NEBOC_COMMENT_STATUS_ENCODING
    ret
.unterminated_saved:
    mov edx,ecx
    pop r14
    pop r13
    pop r12
    pop rbx
    mov eax,NEBOC_COMMENT_STATUS_UNTERMINATED
    ret
.depth_saved:
    mov edx,ecx
    pop r14
    pop r13
    pop r12
    pop rbx
    mov eax,NEBOC_COMMENT_STATUS_DEPTH
    ret
.argument:
    mov eax,NEBOC_COMMENT_STATUS_ARGUMENT
    mov edx,eax
    ret
.length:
    mov eax,NEBOC_COMMENT_STATUS_LENGTH
    mov edx,eax
    ret
.syntax:
    mov eax,NEBOC_COMMENT_STATUS_SYNTAX
    mov edx,eax
    ret

; comment_scan(source, length, output, output_capacity) -> status.
; Delimiters inside Text/Char literals are never comments. EDX is the first
; bad byte on encoding/unterminated/depth failures.
align 16
neboc_comment_scan:
    test rdx,rdx
    jz .scan_argument
    test rdx,7
    jnz .scan_argument
    cmp rcx,NEBOC_COMMENT_SCAN_HEADER_SIZE
    jb .scan_capacity
    cmp rsi,NEBOC_COMMENT_MAX_SOURCE_BYTES
    ja .scan_length
    test rsi,rsi
    jz .scan_empty_ok
    test rdi,rdi
    jz .scan_argument
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,544
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov rbp,rcx
    mov rdi,r12
    mov rsi,r13
    call neboc_comment_utf8_validate
    test eax,eax
    jnz .scan_encoding_saved
    xor r15d,r15d
    mov qword [rsp+512],0
    mov qword [rsp+520],0
    mov qword [rsp+528],0
    mov qword [rsp+536],0
.source_loop:
    cmp r15,r13
    jae .scan_publish
    movzx eax,byte [r12+r15]
    cmp al,10
    jne .source_dispatch
    inc qword [rsp+536]
.source_dispatch:
    cmp al,'"'
    je .skip_text
    cmp al,39
    je .skip_char
    cmp al,'/'
    jne .source_next
    lea rax,[r15+1]
    cmp rax,r13
    jae .source_next
    movzx eax,byte [r12+r15+1]
    cmp al,'/'
    je .line_comment
    cmp al,'*'
    je .block_comment
.source_next:
    inc r15
    jmp .source_loop

.skip_text:
    lea rax,[r15+2]
    cmp rax,r13
    jae .text_single_open
    cmp byte [r12+r15+1],'"'
    jne .text_single_open
    cmp byte [r12+r15+2],'"'
    jne .text_single_open
    add r15,3
.text_triple_loop:
    cmp r15,r13
    jae .scan_publish
    cmp byte [r12+r15],10
    jne .text_triple_quote
    inc qword [rsp+536]
.text_triple_quote:
    lea rax,[r15+2]
    cmp rax,r13
    jae .text_triple_next
    cmp byte [r12+r15],'"'
    jne .text_triple_next
    cmp byte [r12+r15+1],'"'
    jne .text_triple_next
    cmp byte [r12+r15+2],'"'
    jne .text_triple_next
    add r15,3
    jmp .source_loop
.text_triple_next:
    inc r15
    jmp .text_triple_loop
.text_single_open:
    inc r15
.text_single_loop:
    cmp r15,r13
    jae .scan_publish
    movzx eax,byte [r12+r15]
    cmp al,10
    jne .text_single_not_line
    inc qword [rsp+536]
.text_single_not_line:
    cmp al,92
    jne .text_single_quote
    add r15,2
    cmp r15,r13
    jbe .text_single_loop
    mov r15,r13
    jmp .scan_publish
.text_single_quote:
    inc r15
    cmp al,'"'
    jne .text_single_loop
    jmp .source_loop

.skip_char:
    inc r15
.char_loop:
    cmp r15,r13
    jae .scan_publish
    movzx eax,byte [r12+r15]
    cmp al,10
    jne .char_not_line
    inc qword [rsp+536]
.char_not_line:
    cmp al,92
    jne .char_quote
    add r15,2
    cmp r15,r13
    jbe .char_loop
    mov r15,r13
    jmp .scan_publish
.char_quote:
    inc r15
    cmp al,39
    jne .char_loop
    jmp .source_loop

.line_comment:
    xor ebx,ebx
    mov edi,NEBOC_COMMENT_KIND_LINE
    mov rsi,r15
    xor edx,edx
    call .begin_record
    jc .scan_capacity_saved
    mov rbx,rax
    lea rcx,[r15+2]
    cmp rcx,r13
    jae .line_started
    cmp byte [r12+r15+2],'/'
    jne .line_started
    or qword [rbx+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_DOC_LIKE
.line_started:
    add r15,2
.line_loop:
    cmp r15,r13
    jae .line_done
    movzx eax,byte [r12+r15]
    cmp al,10
    je .line_done
    cmp al,13
    je .line_done
    call .classify_security
    inc r15
    jmp .line_loop
.line_done:
    mov [rbx+NEBOC_COMMENT_RECORD_END_OFFSET],r15
    mov rax,[rbx+NEBOC_COMMENT_RECORD_FLAGS_OFFSET]
    or [rsp+528],rax
    jmp .source_loop

.block_comment:
    xor ebx,ebx
.block_open:
    inc ebx
    cmp ebx,NEBOC_COMMENT_MAX_NESTING
    ja .scan_depth_saved
    xor edx,edx
    cmp ebx,1
    je .block_parent_ready
    mov rdx,[rsp+rbx*8-16]
    inc rdx
.block_parent_ready:
    mov edi,NEBOC_COMMENT_KIND_BLOCK
    mov rsi,r15
    call .begin_record
    jc .scan_capacity_saved
    mov rcx,[rsp+512]
    dec rcx
    mov [rsp+rbx*8-8],rcx
    cmp rbx,[rsp+520]
    jbe .block_max_ready
    mov [rsp+520],rbx
.block_max_ready:
    lea rcx,[r15+2]
    cmp rcx,r13
    jae .block_after_doclike
    cmp byte [r12+r15+2],'*'
    je .block_doclike
    cmp byte [r12+r15+2],'/'
    jne .block_after_doclike
.block_doclike:
    or qword [rax+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_DOC_LIKE
.block_after_doclike:
    add r15,2
.block_loop:
    cmp r15,r13
    jae .scan_unterminated_saved
    mov rcx,[rsp+rbx*8-8]
    imul rcx,NEBOC_COMMENT_RECORD_SIZE
    lea rcx,[r14+NEBOC_COMMENT_SCAN_HEADER_SIZE+rcx]
    cmp byte [r12+r15],10
    jne .block_security
    inc qword [rsp+536]
    or qword [rcx+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_MULTILINE
.block_security:
    push rbx
    mov rbx,rcx
    call .classify_security
    pop rbx
    lea rax,[r15+1]
    cmp rax,r13
    jae .block_advance
    cmp byte [r12+r15],'/'
    jne .block_maybe_close
    cmp byte [r12+r15+1],'*'
    je .block_open
.block_maybe_close:
    cmp byte [r12+r15],'*'
    jne .block_advance
    cmp byte [r12+r15+1],'/'
    jne .block_advance
    add r15,2
    mov rax,[rsp+rbx*8-8]
    imul rax,NEBOC_COMMENT_RECORD_SIZE
    lea rax,[r14+NEBOC_COMMENT_SCAN_HEADER_SIZE+rax]
    mov [rax+NEBOC_COMMENT_RECORD_END_OFFSET],r15
    mov rcx,[rax+NEBOC_COMMENT_RECORD_FLAGS_OFFSET]
    or [rsp+528],rcx
    dec ebx
    test ebx,ebx
    jnz .block_loop
    jmp .source_loop
.block_advance:
    inc r15
    jmp .block_loop

; EDI kind, RSI start, EDX parent+1. Returns RAX record, CF on capacity.
.begin_record:
    ; CALL placed its return address below the scanner frame.
    mov rax,[rsp+520]
    cmp rax,NEBOC_COMMENT_MAX_RECORDS
    jae .record_capacity
    mov rcx,rax
    inc rcx
    imul rcx,NEBOC_COMMENT_RECORD_SIZE
    add rcx,NEBOC_COMMENT_SCAN_HEADER_SIZE
    cmp rcx,rbp
    ja .record_capacity
    imul rax,NEBOC_COMMENT_RECORD_SIZE
    lea rax,[r14+NEBOC_COMMENT_SCAN_HEADER_SIZE+rax]
    mov [rax+NEBOC_COMMENT_RECORD_KIND_OFFSET],rdi
    mov [rax+NEBOC_COMMENT_RECORD_START_OFFSET],rsi
    mov qword [rax+NEBOC_COMMENT_RECORD_END_OFFSET],0
    mov [rax+NEBOC_COMMENT_RECORD_DEPTH_OFFSET],rbx
    mov [rax+NEBOC_COMMENT_RECORD_PARENT_OFFSET],rdx
    mov qword [rax+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],0
    test rsi,rsi
    jz .record_leading
    mov rcx,rsi
.record_back_line:
    test rcx,rcx
    jz .record_leading
    dec rcx
    movzx edi,byte [r12+rcx]
    cmp dil,10
    je .record_leading
    cmp dil,13
    je .record_leading
    cmp dil,' '
    je .record_back_line
    cmp dil,9
    je .record_back_line
    or qword [rax+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_TRAILING
    jmp .record_commit
.record_leading:
    or qword [rax+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_LEADING
    cmp rsi,2
    jb .record_commit
    mov rcx,rsi
    xor edi,edi
.record_detached_scan:
    test rcx,rcx
    jz .record_commit
    dec rcx
    movzx edx,byte [r12+rcx]
    cmp dl,10
    jne .record_detached_space
    inc edi
    cmp edi,2
    jb .record_detached_scan
    and qword [rax+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],~NEBOC_COMMENT_FLAG_LEADING
    or qword [rax+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_DETACHED
    jmp .record_commit
.record_detached_space:
    cmp dl,13
    je .record_detached_scan
    cmp dl,' '
    je .record_detached_scan
    cmp dl,9
    je .record_detached_scan
.record_commit:
    inc qword [rsp+520]
    clc
    ret
.record_capacity:
    stc
    ret

; RBX record address, R15 current byte.
.classify_security:
    movzx eax,byte [r12+r15]
    cmp al,0xce
    je .security_confusable
    cmp al,0xcf
    je .security_confusable
    cmp al,0xd0
    jb .security_e2
    cmp al,0xd3
    jbe .security_confusable
.security_e2:
    cmp al,0xe2
    jne .security_done
    lea rax,[r15+2]
    cmp rax,r13
    jae .security_done
    cmp byte [r12+r15+1],0x80
    jne .security_206x
    movzx eax,byte [r12+r15+2]
    cmp al,0xaa
    jb .security_invisible_range
    cmp al,0xae
    jbe .security_bidi
.security_invisible_range:
    cmp al,0x8b
    jb .security_done
    cmp al,0x8f
    jbe .security_invisible
    jmp .security_done
.security_206x:
    cmp byte [r12+r15+1],0x81
    jne .security_done
    movzx eax,byte [r12+r15+2]
    cmp al,0xa6
    jb .security_done
    cmp al,0xa9
    jbe .security_bidi
    jmp .security_done
.security_bidi:
    or qword [rbx+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_BIDI
    ret
.security_invisible:
    or qword [rbx+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_INVISIBLE
    ret
.security_confusable:
    or qword [rbx+NEBOC_COMMENT_RECORD_FLAGS_OFFSET],NEBOC_COMMENT_FLAG_CONFUSABLE
.security_done:
    ret

.scan_publish:
    mov rax,[rsp+512]
    imul rax,NEBOC_COMMENT_RECORD_SIZE
    add rax,NEBOC_COMMENT_SCAN_HEADER_SIZE
    mov rcx,NEBOC_COMMENT_SCAN_MAGIC
    mov [r14+NEBOC_COMMENT_SCAN_MAGIC_OFFSET],rcx
    mov qword [r14+NEBOC_COMMENT_SCAN_SCHEMA_OFFSET],NEBOC_COMMENT_SCAN_SCHEMA
    mov [r14+NEBOC_COMMENT_SCAN_SOURCE_LENGTH_OFFSET],r13
    mov rcx,[rsp+512]
    mov [r14+NEBOC_COMMENT_SCAN_COUNT_OFFSET],rcx
    mov rcx,[rsp+520]
    mov [r14+NEBOC_COMMENT_SCAN_MAX_DEPTH_OFFSET],rcx
    mov rcx,[rsp+528]
    mov [r14+NEBOC_COMMENT_SCAN_FLAGS_OFFSET],rcx
    mov rcx,[rsp+536]
    inc rcx
    mov [r14+NEBOC_COMMENT_SCAN_LINE_COUNT_OFFSET],rcx
    mov [r14+NEBOC_COMMENT_SCAN_OUTPUT_BYTES_OFFSET],rax
    add rsp,544
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    xor eax,eax
    xor edx,edx
    ret
.scan_encoding_saved:
    mov edx,eax
    mov eax,NEBOC_COMMENT_STATUS_ENCODING
    jmp .scan_fail_saved
.scan_unterminated_saved:
    mov edx,r15d
    mov eax,NEBOC_COMMENT_STATUS_UNTERMINATED
    jmp .scan_fail_saved
.scan_depth_saved:
    mov edx,r15d
    mov eax,NEBOC_COMMENT_STATUS_DEPTH
    jmp .scan_fail_saved
.scan_capacity_saved:
    mov edx,r15d
    mov eax,NEBOC_COMMENT_STATUS_CAPACITY
.scan_fail_saved:
    add rsp,544
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.scan_empty_ok:
    mov rax,NEBOC_COMMENT_SCAN_MAGIC
    mov [rdx+NEBOC_COMMENT_SCAN_MAGIC_OFFSET],rax
    mov qword [rdx+NEBOC_COMMENT_SCAN_SCHEMA_OFFSET],NEBOC_COMMENT_SCAN_SCHEMA
    mov qword [rdx+NEBOC_COMMENT_SCAN_SOURCE_LENGTH_OFFSET],0
    mov qword [rdx+NEBOC_COMMENT_SCAN_COUNT_OFFSET],0
    mov qword [rdx+NEBOC_COMMENT_SCAN_MAX_DEPTH_OFFSET],0
    mov qword [rdx+NEBOC_COMMENT_SCAN_FLAGS_OFFSET],0
    mov qword [rdx+NEBOC_COMMENT_SCAN_LINE_COUNT_OFFSET],1
    mov qword [rdx+NEBOC_COMMENT_SCAN_OUTPUT_BYTES_OFFSET],NEBOC_COMMENT_SCAN_HEADER_SIZE
    xor eax,eax
    xor edx,edx
    ret
.scan_argument:
    mov eax,NEBOC_COMMENT_STATUS_ARGUMENT
    mov edx,eax
    ret
.scan_length:
    mov eax,NEBOC_COMMENT_STATUS_LENGTH
    mov edx,eax
    ret
.scan_capacity:
    mov eax,NEBOC_COMMENT_STATUS_CAPACITY
    mov edx,eax
    ret

; Strict UTF-8 validation. EAX=0 success, otherwise EAX=bad byte offset+1.
align 16
neboc_comment_utf8_validate:
    xor ecx,ecx
.utf8_next:
    cmp rcx,rsi
    jae .utf8_ok
    movzx eax,byte [rdi+rcx]
    cmp al,0x80
    jb .utf8_one
    cmp al,0xc2
    jb .utf8_bad
    cmp al,0xdf
    jbe .utf8_two
    cmp al,0xe0
    je .utf8_e0
    cmp al,0xec
    jbe .utf8_three
    cmp al,0xed
    je .utf8_ed
    cmp al,0xef
    jbe .utf8_three
    cmp al,0xf0
    je .utf8_f0
    cmp al,0xf3
    jbe .utf8_four
    cmp al,0xf4
    je .utf8_f4
    jmp .utf8_bad
.utf8_one:
    inc rcx
    jmp .utf8_next
.utf8_two:
    lea r8,[rcx+1]
    cmp r8,rsi
    jae .utf8_bad
    movzx r9d,byte [rdi+r8]
    and r9d,0xc0
    cmp r9d,0x80
    jne .utf8_bad
    add rcx,2
    jmp .utf8_next
.utf8_e0:
    lea r8,[rcx+2]
    cmp r8,rsi
    jae .utf8_bad
    movzx r9d,byte [rdi+rcx+1]
    cmp r9d,0xa0
    jb .utf8_bad
    cmp r9d,0xbf
    ja .utf8_bad
    jmp .utf8_three_tail
.utf8_three:
    lea r8,[rcx+2]
    cmp r8,rsi
    jae .utf8_bad
    movzx r9d,byte [rdi+rcx+1]
    and r9d,0xc0
    cmp r9d,0x80
    jne .utf8_bad
    jmp .utf8_three_tail
.utf8_ed:
    lea r8,[rcx+2]
    cmp r8,rsi
    jae .utf8_bad
    movzx r9d,byte [rdi+rcx+1]
    cmp r9d,0x80
    jb .utf8_bad
    cmp r9d,0x9f
    ja .utf8_bad
.utf8_three_tail:
    movzx r9d,byte [rdi+rcx+2]
    and r9d,0xc0
    cmp r9d,0x80
    jne .utf8_bad
    add rcx,3
    jmp .utf8_next
.utf8_f0:
    lea r8,[rcx+3]
    cmp r8,rsi
    jae .utf8_bad
    movzx r9d,byte [rdi+rcx+1]
    cmp r9d,0x90
    jb .utf8_bad
    cmp r9d,0xbf
    ja .utf8_bad
    jmp .utf8_four_tail
.utf8_four:
    lea r8,[rcx+3]
    cmp r8,rsi
    jae .utf8_bad
    movzx r9d,byte [rdi+rcx+1]
    and r9d,0xc0
    cmp r9d,0x80
    jne .utf8_bad
    jmp .utf8_four_tail
.utf8_f4:
    lea r8,[rcx+3]
    cmp r8,rsi
    jae .utf8_bad
    movzx r9d,byte [rdi+rcx+1]
    cmp r9d,0x80
    jb .utf8_bad
    cmp r9d,0x8f
    ja .utf8_bad
.utf8_four_tail:
    movzx r9d,byte [rdi+rcx+2]
    and r9d,0xc0
    cmp r9d,0x80
    jne .utf8_bad
    movzx r9d,byte [rdi+rcx+3]
    and r9d,0xc0
    cmp r9d,0x80
    jne .utf8_bad
    add rcx,4
    jmp .utf8_next
.utf8_bad:
    lea rax,[rcx+1]
    ret
.utf8_ok:
    xor eax,eax
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
