; G164 native conformance: nested comments, trivia records, failure atomicity,
; literal isolation, nesting boundary and every public wrapper surface.
bits 64
default rel
%include "compiler/parser/block_comment.inc"
global _start
extern neboc_block_comment_registry
extern neboc_block_comment_lexer
extern neboc_trivia_store
extern neboc_comment_source_map
extern neboc_trivia_formatter
extern neboc_comment_ranges
extern neboc_comment_security

%define SENTINEL 0xa5a5a5a5a5a5a5a5

section .text
_start:
    mov byte [rel stage],1
    ; One block scanner consumes only the comment and reports nested facts.
    lea rdi,[rel nested]
    mov esi,nested_len
    lea rdx,[rel block_result]
    call neboc_block_comment_lexer
    test eax,eax
    jnz fail
    cmp qword [rel block_result+NEBOC_BLOCK_RESULT_CONSUMED_OFFSET],nested_comment_len
    jne fail
    cmp qword [rel block_result+NEBOC_BLOCK_RESULT_MAX_DEPTH_OFFSET],2
    jne fail
    cmp qword [rel block_result+NEBOC_BLOCK_RESULT_COMMENT_COUNT_OFFSET],2
    jne fail

    ; Unterminated input cannot publish a partial result.
    mov byte [rel stage],2
    mov rax,SENTINEL
    lea rdi,[rel block_atomic]
    mov ecx,NEBOC_BLOCK_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel unterminated]
    mov esi,unterminated_len
    lea rdx,[rel block_atomic]
    call neboc_block_comment_lexer
    cmp eax,NEBOC_COMMENT_STATUS_UNTERMINATED
    jne fail
    mov rax,SENTINEL
    lea rdi,[rel block_atomic]
    mov ecx,NEBOC_BLOCK_RESULT_SIZE/8
.atomic_loop:
    cmp [rdi],rax
    jne fail
    add rdi,8
    loop .atomic_loop

    ; Exactly 64 nested comments pass; a 65th fails at the opening delimiter.
    mov byte [rel stage],3
    mov edi,64
    call make_nested
    lea rdi,[rel depth_source]
    mov esi,256
    lea rdx,[rel block_result]
    call neboc_block_comment_lexer
    test eax,eax
    jnz fail
    cmp qword [rel block_result+NEBOC_BLOCK_RESULT_MAX_DEPTH_OFFSET],64
    jne fail
    mov byte [rel stage],4
    mov edi,65
    call make_nested
    lea rdi,[rel depth_source]
    mov esi,260
    lea rdx,[rel block_result]
    call neboc_block_comment_lexer
    cmp eax,NEBOC_COMMENT_STATUS_DEPTH
    jne fail

    ; The full-source owner ignores comment delimiters inside Text and emits
    mov byte [rel stage],5
    ; line/outer/nested records with exact half-open spans and hierarchy.
    lea rdi,[rel source]
    mov esi,source_len
    lea rdx,[rel scan_result]
    mov ecx,scan_result_size
    call neboc_block_comment_registry
    test eax,eax
    jnz fail
    mov byte [rel stage],51
    mov rax,NEBOC_COMMENT_SCAN_MAGIC
    cmp qword [rel scan_result+NEBOC_COMMENT_SCAN_MAGIC_OFFSET],rax
    jne fail
    mov byte [rel stage],52
    cmp qword [rel scan_result+NEBOC_COMMENT_SCAN_COUNT_OFFSET],3
    jne fail
    mov byte [rel stage],53
    cmp qword [rel scan_result+NEBOC_COMMENT_SCAN_MAX_DEPTH_OFFSET],2
    jne fail
    mov byte [rel stage],54
    lea r8,[rel scan_result+NEBOC_COMMENT_SCAN_HEADER_SIZE]
    cmp qword [r8+NEBOC_COMMENT_RECORD_KIND_OFFSET],NEBOC_COMMENT_KIND_LINE
    jne fail
    cmp qword [r8+NEBOC_COMMENT_RECORD_START_OFFSET],line_start
    jne fail
    cmp qword [r8+NEBOC_COMMENT_RECORD_END_OFFSET],line_end
    jne fail
    mov byte [rel stage],55
    add r8,NEBOC_COMMENT_RECORD_SIZE
    cmp qword [r8+NEBOC_COMMENT_RECORD_START_OFFSET],outer_start
    jne fail
    cmp qword [r8+NEBOC_COMMENT_RECORD_END_OFFSET],outer_end
    jne fail
    cmp qword [r8+NEBOC_COMMENT_RECORD_DEPTH_OFFSET],1
    jne fail
    mov byte [rel stage],56
    add r8,NEBOC_COMMENT_RECORD_SIZE
    cmp qword [r8+NEBOC_COMMENT_RECORD_START_OFFSET],inner_start
    jne fail
    cmp qword [r8+NEBOC_COMMENT_RECORD_END_OFFSET],inner_end
    jne fail
    cmp qword [r8+NEBOC_COMMENT_RECORD_DEPTH_OFFSET],2
    jne fail
    cmp qword [r8+NEBOC_COMMENT_RECORD_PARENT_OFFSET],2
    jne fail

    ; Tooling facades are exact aliases, preventing model drift.
    mov byte [rel stage],60
    lea rbx,[rel surfaces]
.surface_loop:
    mov rax,[rbx]
    test rax,rax
    jz pass
    lea rdi,[rel source]
    mov esi,source_len
    lea rdx,[rel scan_result]
    mov ecx,scan_result_size
    call rax
    test eax,eax
    jnz fail
    cmp qword [rel scan_result+NEBOC_COMMENT_SCAN_COUNT_OFFSET],3
    jne fail
    add rbx,8
    jmp .surface_loop

pass:
    xor edi,edi
    jmp exit
fail:
    movzx edi,byte [rel stage]
exit:
    mov eax,60
    syscall

; EDI = depth. Produces depth opens followed by depth closes.
make_nested:
    lea r8,[rel depth_source]
    xor ecx,ecx
.open:
    cmp ecx,edi
    jae .close_setup
    mov word [r8+rcx*2],0x2a2f
    inc ecx
    jmp .open
.close_setup:
    mov edx,edi
.close:
    test edx,edx
    jz .done
    mov word [r8+rcx*2],0x2f2a
    inc ecx
    dec edx
    jmp .close
.done:
    ret

section .rodata
nested: db '/*a/*b*/c*/'
nested_comment_len equ $-nested
        db 'start'
nested_len equ $-nested
unterminated: db '/* outer /* inner */'
unterminated_len equ $-unterminated
source: db 'start(){ Text value = "/*text*/"; '
line_start equ $-source
        db '// line'
line_end equ $-source
        db 10
outer_start equ $-source
        db '/* outer',10
inner_start equ $-source
        db '/* inner */'
inner_end equ $-source
        db 10,'end */'
outer_end equ $-source
        db 'return 7;}',10
source_len equ $-source
surfaces: dq neboc_trivia_store,neboc_comment_source_map,neboc_trivia_formatter
          dq neboc_comment_ranges,neboc_comment_security,0

section .bss
align 16
block_result: resb NEBOC_BLOCK_RESULT_SIZE
block_atomic: resb NEBOC_BLOCK_RESULT_SIZE
depth_source: resb 260
resb 12
scan_result_size equ NEBOC_COMMENT_SCAN_HEADER_SIZE+16*NEBOC_COMMENT_RECORD_SIZE
scan_result: resb scan_result_size
stage: resb 1

section .note.GNU-stack noalloc noexec nowrite progbits
