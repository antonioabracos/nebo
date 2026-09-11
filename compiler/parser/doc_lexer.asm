; RF166-G155 canonical bounded lexer, CST and DocBlockAst parser.
; The module parser, CLI probe and compatibility entries all call this owner.
bits 64
default rel

%include "compiler/parser/doc.inc"

global neboc_doc_parse
global neboc_doc_keyword

section .rodata
doc_word: db 'doc'
docs_word: db 'docs'
field_title: db 'title'
field_summary: db 'summary'
field_parameters: db 'parameters'
field_returns: db 'returns'
field_errors: db 'errors'
field_effects: db 'effects'
field_capabilities: db 'capabilities'
field_ownership: db 'ownership'
field_complexity: db 'complexity'
field_risks: db 'risks'
field_since: db 'since'
field_deprecated: db 'deprecated'
field_example: db 'example'
field_law: db 'law'
target_module: db 'module'
target_type: db 'type'
target_alias: db 'alias'
target_struct: db 'struct'
target_enum: db 'enum'
target_fn: db 'fn'
target_function: db 'function'
target_const: db 'const'
target_constant: db 'constant'

section .text
align 16
; parse(source, length, caller_result) -> eax status.
; Failure leaves caller_result byte-identical, returns a stable reason in EDX,
; and a packed primary span in RCX. There is no allocation, I/O or effect.
neboc_doc_parse:
    test rdi,rdi
    jz .argument_direct
    test rdx,rdx
    jz .argument_direct
    test rdx,NEBOC_DOC_RESULT_ALIGNMENT-1
    jnz .argument_direct
    test rsi,rsi
    jz .length_direct
    cmp rsi,NEBOC_DOC_MAX_SOURCE_BYTES
    ja .limit_direct
    lea rax,[rdi+rsi]
    cmp rax,rdi
    jb .length_direct

    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,648
    mov r15,rsp
    mov [r15+576],rdx             ; caller result
    mov r12,rdi                   ; source base
    mov r13,rdi                   ; cursor
    lea r14,[rdi+rsi]             ; exclusive end
    lea rdi,[r15]
    mov ecx,NEBOC_DOC_RESULT_QWORDS
    xor eax,eax
    rep stosq

    mov rdi,r12
    mov rsi,r14
    sub rsi,r12
    call doc_utf8_validate
    jc .utf8
    call doc_skip_trivia
    jc .syntax
    cmp r13,r14
    jae .keyword
    mov rbx,r13
    mov rax,r13
    sub rax,r12
    mov [r15+NEBOC_DOC_SPAN_START_OFFSET],rax
    call doc_read_identifier
    jc .keyword
    mov rdx,docs_word
    mov ecx,4
    call doc_bytes_equal
    test eax,eax
    jnz .docs_keyword
    mov rdx,doc_word
    mov ecx,3
    call doc_bytes_equal
    test eax,eax
    jz .keyword_span
    call doc_skip_trivia
    jc .syntax
    cmp r13,r14
    jae .syntax
    cmp byte [r13],'{'
    jne .syntax
    inc r13
    xor ebp,ebp

.field_loop:
    call doc_skip_trivia
    jc .syntax
    cmp r13,r14
    jae .syntax
    cmp byte [r13],'}'
    je .doc_close
    call doc_read_identifier
    jc .syntax
    mov [r15+584],rdi             ; diagnostic token pointer
    mov [r15+592],rsi             ; diagnostic token length
    mov [r15+608],rdi             ; DocFieldAst start
    mov qword [r15+624],0         ; typed payload span
    mov qword [r15+632],0         ; example/law label span
    call doc_field_kind
    test eax,eax
    jz .unknown_field
    mov r9d,eax
    mov [r15+616],rax             ; stable field kind
    mov ecx,eax
    dec ecx
    mov rax,1
    shl rax,cl
    mov r11,rax
    test rbp,r11
    jnz .duplicate_field
    or rbp,r11
    mov [r15+NEBOC_DOC_FIELD_MASK_OFFSET],rbp
    inc qword [r15+NEBOC_DOC_FIELD_COUNT_OFFSET]
    cmp r9d,NEBOC_DOC_FIELD_TITLE
    je .scalar
    cmp r9d,NEBOC_DOC_FIELD_SUMMARY
    je .scalar
    cmp r9d,NEBOC_DOC_FIELD_SINCE
    je .scalar
    cmp r9d,NEBOC_DOC_FIELD_DEPRECATED
    je .scalar
    cmp r9d,NEBOC_DOC_FIELD_EXAMPLE
    je .example
    cmp r9d,NEBOC_DOC_FIELD_LAW
    je .law

    call doc_skip_trivia
    jc .syntax
    cmp r13,r14
    jae .syntax
    cmp byte [r13],'{'
    jne .syntax
    inc r13
    call doc_scan_block
    jc .syntax
    mov [r15+624],rax
    jmp .field_done

.scalar:
    call doc_skip_trivia
    jc .syntax
    cmp r13,r14
    jae .syntax
    cmp byte [r13],':'
    jne .syntax
    inc r13
    call doc_skip_trivia
    jc .syntax
    call doc_scan_string
    jc .syntax
    mov [r15+624],rax
    call doc_skip_trivia
    jc .syntax
    cmp r13,r14
    jae .syntax
    cmp byte [r13],';'
    jne .syntax
    inc r13
    jmp .field_complete

.example:
    inc qword [r15+NEBOC_DOC_EXAMPLE_COUNT_OFFSET]
    call doc_named_code_block
    jc .malformed_example
    mov [r15+624],rax
    cmp qword [r15+NEBOC_DOC_EXAMPLE_SPAN_OFFSET],0
    jne .field_done
    mov [r15+NEBOC_DOC_EXAMPLE_SPAN_OFFSET],rax
    jmp .field_done
.law:
    inc qword [r15+NEBOC_DOC_LAW_COUNT_OFFSET]
    call doc_named_code_block
    jc .malformed_example
    mov [r15+624],rax
    cmp qword [r15+NEBOC_DOC_LAW_SPAN_OFFSET],0
    jne .field_done
    mov [r15+NEBOC_DOC_LAW_SPAN_OFFSET],rax

.field_done:
    call doc_publish_field_record
    call doc_skip_trivia
    jc .syntax
    cmp r13,r14
    jae .syntax
    cmp byte [r13],';'
    jne .field_loop
    inc r13
    jmp .field_loop
.field_complete:
    call doc_publish_field_record
    jmp .field_loop

.doc_close:
    inc r13
    mov rax,r13
    sub rax,r12
    mov [r15+NEBOC_DOC_SPAN_END_OFFSET],rax
    cmp qword [r15+NEBOC_DOC_FIELD_COUNT_OFFSET],0
    je .syntax
    call doc_skip_trivia
    jc .syntax
    cmp r13,r14
    jae .orphan
    mov [r15+600],r13             ; attachment keyword start
    call doc_read_identifier
    jc .orphan
    mov [r15+584],rdi
    mov [r15+592],rsi
    mov rdx,doc_word
    mov ecx,3
    call doc_bytes_equal
    test eax,eax
    jnz .duplicate_doc_saved
    mov rdi,[r15+584]
    mov rsi,[r15+592]
    mov rdx,docs_word
    mov ecx,4
    call doc_bytes_equal
    test eax,eax
    jnz .duplicate_doc_saved
    mov rdi,[r15+584]
    mov rsi,[r15+592]
    call doc_target_kind
    test eax,eax
    jz .orphan_saved
    mov [r15+NEBOC_DOC_ATTACHMENT_KIND_OFFSET],rax
    call doc_skip_trivia
    jc .syntax
    call doc_read_identifier
    jc .orphan
    cmp qword [r15+NEBOC_DOC_ATTACHMENT_KIND_OFFSET],NEBOC_DOC_ATTACHMENT_TYPE
    jne .target_name
    mov rdx,target_alias
    mov ecx,5
    call doc_bytes_equal
    test eax,eax
    jz .target_name
    call doc_skip_trivia
    jc .syntax
    call doc_read_identifier
    jc .orphan
.target_name:
    mov r10,rdi
    mov r11,rsi
    mov rax,rdi
    sub rax,r12
    mov rcx,rsi
    shl rcx,32
    or rax,rcx
    mov [r15+NEBOC_DOC_ATTACHMENT_NAME_SPAN_OFFSET],rax
    mov rdi,r10
    mov rsi,r11
    call doc_hash_bytes
    test rax,rax
    jnz .symbol_ready
    inc rax
.symbol_ready:
    mov [r15+NEBOC_DOC_ATTACHMENT_SYMBOL_ID_OFFSET],rax
    mov rax,[r15+600]
    sub rax,r12
    mov [r15+NEBOC_DOC_CONSUMED_OFFSET],rax

    mov rdi,r12
    add rdi,[r15+NEBOC_DOC_SPAN_START_OFFSET]
    mov rsi,[r15+600]
    sub rsi,rdi
    call doc_hash_bytes
    mov [r15+NEBOC_DOC_CST_DIGEST_OFFSET],rax
    mov rdi,r12
    add rdi,[r15+NEBOC_DOC_SPAN_START_OFFSET]
    mov rsi,r12
    add rsi,[r15+NEBOC_DOC_SPAN_END_OFFSET]
    call doc_hash_ast
    mov [r15+NEBOC_DOC_AST_DIGEST_OFFSET],rax
    mov rax,NEBOC_DOC_FLAG_PARSED
    cmp qword [r15+NEBOC_DOC_COMMENT_COUNT_OFFSET],0
    je .flags_ready
    or rax,NEBOC_DOC_FLAG_HAS_TRIVIA
.flags_ready:
    mov [r15+NEBOC_DOC_FLAGS_OFFSET],rax
    mov rdi,[r15+576]
    mov rsi,r15
    mov ecx,NEBOC_DOC_RESULT_QWORDS
    rep movsq
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    jmp .done

.unknown_field:
    mov edx,NEBOC_DOC_DIAG_UNKNOWN_FIELD
    jmp .saved_token_error
.duplicate_field:
    mov edx,NEBOC_DOC_DIAG_DUPLICATE_FIELD
.saved_token_error:
    mov rdi,[r15+584]
    mov rsi,[r15+592]
    jmp .fail_span
.duplicate_doc_saved:
    mov rdi,[r15+584]
    mov rsi,[r15+592]
    mov edx,NEBOC_DOC_DIAG_DUPLICATE_DOC
    jmp .fail_span
.orphan_saved:
    mov rdi,[r15+584]
    mov rsi,[r15+592]
    mov edx,NEBOC_DOC_DIAG_ORPHAN_ATTACHMENT
    jmp .fail_span
.malformed_example:
    mov edx,NEBOC_DOC_DIAG_MALFORMED_EXAMPLE
    jmp .cursor_error
.syntax:
    mov edx,NEBOC_DOC_DIAG_SYNTAX
    jmp .cursor_error
.orphan:
    mov edx,NEBOC_DOC_DIAG_ORPHAN_ATTACHMENT
    jmp .cursor_error
.keyword:
    mov rdi,r13
    mov rsi,1
    mov edx,NEBOC_DOC_DIAG_DOCS_KEYWORD
    jmp .fail_span
.keyword_span:
    mov rdi,rbx
    mov rsi,r13
    sub rsi,rbx
    mov edx,NEBOC_DOC_DIAG_DOCS_KEYWORD
    jmp .fail_span
.docs_keyword:
    mov rdi,rbx
    mov rsi,4
    mov edx,NEBOC_DOC_DIAG_DOCS_KEYWORD
    jmp .fail_span
.utf8:
    mov edx,NEBOC_DOC_DIAG_UTF8
    lea rdi,[r12+rax]
    mov rsi,1
    jmp .fail_span
.cursor_error:
    mov rdi,r13
    mov rsi,1
    cmp rdi,r14
    jb .fail_span
    mov rdi,r14
    cmp rdi,r12
    je .fail_span
    dec rdi
.fail_span:
    mov rax,rdi
    sub rax,r12
    mov rcx,rsi
    shl rcx,32
    or rcx,rax
    mov eax,1
.done:
    add rsp,648
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

.argument_direct:
    mov eax,1
    mov edx,NEBOC_DOC_DIAG_ARGUMENT
    xor ecx,ecx
    ret
.length_direct:
    mov eax,1
    mov edx,NEBOC_DOC_DIAG_LENGTH
    xor ecx,ecx
    ret
.limit_direct:
    mov eax,1
    mov edx,NEBOC_DOC_DIAG_LIMIT
    xor ecx,ecx
    ret

; Historical lexer entry is now an exact alias of the canonical parser.
neboc_doc_keyword:
    jmp neboc_doc_parse

; Consume whitespace plus line/block comments, retaining comments as CST
; trivia. CF reports an unterminated block comment.
doc_skip_trivia:
.again:
    cmp r13,r14
    jae .ok
    mov al,[r13]
    cmp al,' '
    je .space
    cmp al,9
    je .space
    cmp al,10
    je .space
    cmp al,13
    je .space
    cmp al,'/'
    jne .ok
    lea rax,[r13+1]
    cmp rax,r14
    jae .ok
    cmp byte [r13+1],'/'
    je .line
    cmp byte [r13+1],'*'
    je .block
    jmp .ok
.space:
    inc r13
    jmp .again
.line:
    inc qword [r15+NEBOC_DOC_COMMENT_COUNT_OFFSET]
    add r13,2
.line_loop:
    cmp r13,r14
    jae .ok
    cmp byte [r13],10
    je .again
    inc r13
    jmp .line_loop
.block:
    inc qword [r15+NEBOC_DOC_COMMENT_COUNT_OFFSET]
    mov edx,1
    add r13,2
.block_loop:
    cmp r13,r14
    jae .bad
    cmp byte [r13],'/'
    jne .block_maybe_close
    lea rax,[r13+1]
    cmp rax,r14
    jae .bad
    cmp byte [r13+1],'*'
    jne .block_next
    inc edx
    cmp edx,64
    ja .bad
    inc qword [r15+NEBOC_DOC_COMMENT_COUNT_OFFSET]
    add r13,2
    jmp .block_loop
.block_maybe_close:
    cmp byte [r13],'*'
    jne .block_next
    lea rax,[r13+1]
    cmp rax,r14
    jae .bad
    cmp byte [r13+1],'/'
    je .block_done
.block_next:
    inc r13
    jmp .block_loop
.block_done:
    add r13,2
    dec edx
    jnz .block_loop
    jmp .again
.ok:
    clc
    ret
.bad:
    stc
    ret

; Read [A-Za-z_][A-Za-z0-9_]*. RDI/RSI identify the consumed token.
doc_read_identifier:
    cmp r13,r14
    jae .bad
    movzx eax,byte [r13]
    cmp al,'A'
    jb .first_lower
    cmp al,'Z'
    jbe .first_ok
.first_lower:
    cmp al,'a'
    jb .first_underscore
    cmp al,'z'
    jbe .first_ok
.first_underscore:
    cmp al,'_'
    jne .bad
.first_ok:
    mov rdi,r13
    inc r13
.loop:
    cmp r13,r14
    jae .done
    movzx eax,byte [r13]
    cmp al,'A'
    jb .lower
    cmp al,'Z'
    jbe .take
.lower:
    cmp al,'a'
    jb .digit
    cmp al,'z'
    jbe .take
.digit:
    cmp al,'0'
    jb .underscore
    cmp al,'9'
    jbe .take
.underscore:
    cmp al,'_'
    jne .done
.take:
    inc r13
    jmp .loop
.done:
    mov rsi,r13
    sub rsi,rdi
    cmp rsi,64
    ja .bad
    clc
    ret
.bad:
    stc
    ret

; RDI/RSI token, RDX/RCX literal. EAX=1 iff byte-identical.
doc_bytes_equal:
    cmp rsi,rcx
    jne .no
    xor r8d,r8d
.loop:
    cmp r8,rcx
    jae .yes
    mov al,[rdi+r8]
    cmp al,[rdx+r8]
    jne .no
    inc r8
    jmp .loop
.yes:
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

%macro DOC_KIND_TEST 3
    mov rdx,%2
    mov ecx,%3
    call doc_bytes_equal
    test eax,eax
    jnz %1
%endmacro
doc_field_kind:
    DOC_KIND_TEST .k_title,field_title,5
    DOC_KIND_TEST .k_summary,field_summary,7
    DOC_KIND_TEST .k_parameters,field_parameters,10
    DOC_KIND_TEST .k_returns,field_returns,7
    DOC_KIND_TEST .k_errors,field_errors,6
    DOC_KIND_TEST .k_effects,field_effects,7
    DOC_KIND_TEST .k_capabilities,field_capabilities,12
    DOC_KIND_TEST .k_ownership,field_ownership,9
    DOC_KIND_TEST .k_complexity,field_complexity,10
    DOC_KIND_TEST .k_risks,field_risks,5
    DOC_KIND_TEST .k_since,field_since,5
    DOC_KIND_TEST .k_deprecated,field_deprecated,10
    DOC_KIND_TEST .k_example,field_example,7
    DOC_KIND_TEST .k_law,field_law,3
    xor eax,eax
    ret
.k_title: mov eax,NEBOC_DOC_FIELD_TITLE
    ret
.k_summary: mov eax,NEBOC_DOC_FIELD_SUMMARY
    ret
.k_parameters: mov eax,NEBOC_DOC_FIELD_PARAMETERS
    ret
.k_returns: mov eax,NEBOC_DOC_FIELD_RETURNS
    ret
.k_errors: mov eax,NEBOC_DOC_FIELD_ERRORS
    ret
.k_effects: mov eax,NEBOC_DOC_FIELD_EFFECTS
    ret
.k_capabilities: mov eax,NEBOC_DOC_FIELD_CAPABILITIES
    ret
.k_ownership: mov eax,NEBOC_DOC_FIELD_OWNERSHIP
    ret
.k_complexity: mov eax,NEBOC_DOC_FIELD_COMPLEXITY
    ret
.k_risks: mov eax,NEBOC_DOC_FIELD_RISKS
    ret
.k_since: mov eax,NEBOC_DOC_FIELD_SINCE
    ret
.k_deprecated: mov eax,NEBOC_DOC_FIELD_DEPRECATED
    ret
.k_example: mov eax,NEBOC_DOC_FIELD_EXAMPLE
    ret
.k_law: mov eax,NEBOC_DOC_FIELD_LAW
    ret

; Publish one pointerless DocFieldAst only after its complete payload parsed.
; Records preserve source order and expose both the whole field and typed
; payload coordinates; example/law records additionally expose their label.
doc_publish_field_record:
    mov rax,[r15+NEBOC_DOC_FIELD_COUNT_OFFSET]
    test rax,rax
    jz .done
    dec rax
    cmp rax,NEBOC_DOC_MAX_FIELDS
    jae .done
    imul rax,NEBOC_DOC_FIELD_RECORD_BYTES
    lea rdx,[r15+NEBOC_DOC_FIELD_RECORDS_OFFSET]
    add rdx,rax
    mov rax,[r15+616]
    mov [rdx+NEBOC_DOC_FIELD_RECORD_KIND_OFFSET],rax
    mov rax,[r15+608]
    sub rax,r12
    mov rcx,r13
    sub rcx,[r15+608]
    shl rcx,32
    or rax,rcx
    mov [rdx+NEBOC_DOC_FIELD_RECORD_SPAN_OFFSET],rax
    mov rax,[r15+624]
    mov [rdx+NEBOC_DOC_FIELD_RECORD_PAYLOAD_SPAN_OFFSET],rax
    mov rax,[r15+632]
    mov [rdx+NEBOC_DOC_FIELD_RECORD_LABEL_SPAN_OFFSET],rax
.done:
    ret

doc_target_kind:
    DOC_KIND_TEST .module,target_module,6
    DOC_KIND_TEST .type,target_type,4
    DOC_KIND_TEST .struct,target_struct,6
    DOC_KIND_TEST .enum,target_enum,4
    DOC_KIND_TEST .fn,target_fn,2
    DOC_KIND_TEST .function,target_function,8
    DOC_KIND_TEST .constant,target_const,5
    DOC_KIND_TEST .constant,target_constant,8
    xor eax,eax
    ret
.module: mov eax,NEBOC_DOC_ATTACHMENT_MODULE
    ret
.type: mov eax,NEBOC_DOC_ATTACHMENT_TYPE
    ret
.struct: mov eax,NEBOC_DOC_ATTACHMENT_STRUCT
    ret
.enum: mov eax,NEBOC_DOC_ATTACHMENT_ENUM
    ret
.fn: mov eax,NEBOC_DOC_ATTACHMENT_FUNCTION
    ret
.function: mov eax,NEBOC_DOC_ATTACHMENT_FUNCTION
    ret
.constant: mov eax,NEBOC_DOC_ATTACHMENT_CONSTANT
    ret
%unmacro DOC_KIND_TEST 3

; Quoted UTF-8 string with byte escapes. Returns packed content span in RAX.
doc_scan_string:
    cmp r13,r14
    jae .bad
    cmp byte [r13],'"'
    jne .bad
    inc r13
    mov r10,r13
.loop:
    cmp r13,r14
    jae .bad
    mov al,[r13]
    cmp al,10
    je .bad
    cmp al,13
    je .bad
    cmp al,92
    je .escape
    cmp al,'"'
    je .done
    inc r13
    jmp .loop
.escape:
    add r13,2
    cmp r13,r14
    ja .bad
    jmp .loop
.done:
    mov rax,r10
    sub rax,r12
    mov rcx,r13
    sub rcx,r10
    shl rcx,32
    or rax,rcx
    inc r13
    clc
    ret
.bad:
    stc
    ret

; Balanced code/schema block. R13 begins after the opening brace.
doc_scan_block:
    mov r11,r13
    mov r8d,1
.loop:
    cmp r13,r14
    jae .bad
    mov al,[r13]
    cmp al,'"'
    je .string
    cmp al,'/'
    je .slash
    cmp al,'{'
    je .open
    cmp al,'}'
    je .close
    inc r13
    jmp .loop
.string:
    inc r13
.string_loop:
    cmp r13,r14
    jae .bad
    mov al,[r13]
    cmp al,92
    je .string_escape
    inc r13
    cmp al,'"'
    jne .string_loop
    jmp .loop
.string_escape:
    add r13,2
    cmp r13,r14
    ja .bad
    jmp .string_loop
.slash:
    lea rax,[r13+1]
    cmp rax,r14
    jae .ordinary
    cmp byte [r13+1],'/'
    je .line_comment
    cmp byte [r13+1],'*'
    je .block_comment
.ordinary:
    inc r13
    jmp .loop
.line_comment:
    inc qword [r15+NEBOC_DOC_COMMENT_COUNT_OFFSET]
    add r13,2
.line_scan:
    cmp r13,r14
    jae .bad
    cmp byte [r13],10
    je .loop
    inc r13
    jmp .line_scan
.block_comment:
    inc qword [r15+NEBOC_DOC_COMMENT_COUNT_OFFSET]
    add r13,2
.block_scan:
    cmp r13,r14
    jae .bad
    cmp byte [r13],'*'
    jne .block_next
    lea rax,[r13+1]
    cmp rax,r14
    jae .bad
    cmp byte [r13+1],'/'
    je .block_done
.block_next:
    inc r13
    jmp .block_scan
.block_done:
    add r13,2
    jmp .loop
.open:
    inc r8d
    cmp r8d,32
    ja .bad
    inc r13
    jmp .loop
.close:
    dec r8d
    jz .done
    inc r13
    jmp .loop
.done:
    mov rax,r11
    sub rax,r12
    mov rcx,r13
    sub rcx,r11
    shl rcx,32
    or rax,rcx
    inc r13
    clc
    ret
.bad:
    stc
    ret

doc_named_code_block:
    call doc_skip_trivia
    jc .bad
    call doc_scan_string
    jc .bad
    mov [r15+632],rax
    call doc_skip_trivia
    jc .bad
    cmp r13,r14
    jae .bad
    cmp byte [r13],'{'
    jne .bad
    inc r13
    call doc_scan_block
    ret
.bad:
    stc
    ret

doc_hash_bytes:
    mov rax,14695981039346656037
    mov r10,1099511628211
    xor r8d,r8d
.loop:
    cmp r8,rsi
    jae .done
    movzx edx,byte [rdi+r8]
    xor rax,rdx
    imul rax,r10
    inc r8
    jmp .loop
.done:
    ret

; Hash semantic tokens while discarding whitespace and comments outside text.
doc_hash_ast:
    mov rax,14695981039346656037
    mov r10,1099511628211
    mov r8,rdi
    xor r11d,r11d
.loop:
    cmp r8,rsi
    jae .done
    movzx edx,byte [r8]
    test r11d,r11d
    jnz .quoted
    cmp dl,' '
    je .next
    cmp dl,9
    je .next
    cmp dl,10
    je .next
    cmp dl,13
    je .next
    cmp dl,'/'
    je .slash
    cmp dl,'"'
    jne .take
    mov r11d,1
    jmp .take
.quoted:
    cmp dl,92
    je .escaped
    cmp dl,'"'
    jne .take
    xor r11d,r11d
    jmp .take
.escaped:
    xor rax,rdx
    imul rax,r10
    inc r8
    cmp r8,rsi
    jae .done
    movzx edx,byte [r8]
    jmp .take
.slash:
    lea rcx,[r8+1]
    cmp rcx,rsi
    jae .take
    cmp byte [r8+1],'/'
    je .skip_line
    cmp byte [r8+1],'*'
    je .skip_block
    jmp .take
.skip_line:
    add r8,2
.skip_line_loop:
    cmp r8,rsi
    jae .done
    cmp byte [r8],10
    je .loop
    inc r8
    jmp .skip_line_loop
.skip_block:
    add r8,2
.skip_block_loop:
    cmp r8,rsi
    jae .done
    cmp byte [r8],'*'
    jne .skip_block_next
    lea rcx,[r8+1]
    cmp rcx,rsi
    jae .done
    cmp byte [r8+1],'/'
    je .skip_block_done
.skip_block_next:
    inc r8
    jmp .skip_block_loop
.skip_block_done:
    add r8,2
    jmp .loop
.take:
    xor rax,rdx
    imul rax,r10
.next:
    inc r8
    jmp .loop
.done:
    ret

; Strict UTF-8 validation with overlong, surrogate and scalar upper bounds.
doc_utf8_validate:
    xor r8d,r8d
.loop:
    cmp r8,rsi
    jae .ok
    movzx r9d,byte [rdi+r8]
    test r9b,r9b
    jz .bad
    cmp r9b,0x7f
    jbe .one
    cmp r9b,0xc2
    jb .bad
    cmp r9b,0xdf
    jbe .two
    cmp r9b,0xe0
    je .three_e0
    cmp r9b,0xed
    je .three_ed
    cmp r9b,0xef
    jbe .three
    cmp r9b,0xf0
    je .four_f0
    cmp r9b,0xf3
    jbe .four
    cmp r9b,0xf4
    je .four_f4
    jmp .bad
.one:
    inc r8
    jmp .loop
.two:
    lea r10,[r8+1]
    cmp r10,rsi
    jae .bad
    movzx r11d,byte [rdi+r10]
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    add r8,2
    jmp .loop
.three_e0:
    lea r10,[r8+2]
    cmp r10,rsi
    jae .bad
    movzx r11d,byte [rdi+r8+1]
    cmp r11b,0xa0
    jb .bad
    cmp r11b,0xbf
    ja .bad
    jmp .three_last
.three_ed:
    lea r10,[r8+2]
    cmp r10,rsi
    jae .bad
    movzx r11d,byte [rdi+r8+1]
    cmp r11b,0x80
    jb .bad
    cmp r11b,0x9f
    ja .bad
    jmp .three_last
.three:
    lea r10,[r8+2]
    cmp r10,rsi
    jae .bad
    movzx r11d,byte [rdi+r8+1]
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
.three_last:
    movzx r11d,byte [rdi+r8+2]
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    add r8,3
    jmp .loop
.four_f0:
    lea r10,[r8+3]
    cmp r10,rsi
    jae .bad
    movzx r11d,byte [rdi+r8+1]
    cmp r11b,0x90
    jb .bad
    cmp r11b,0xbf
    ja .bad
    jmp .four_tail
.four_f4:
    lea r10,[r8+3]
    cmp r10,rsi
    jae .bad
    movzx r11d,byte [rdi+r8+1]
    cmp r11b,0x80
    jb .bad
    cmp r11b,0x8f
    ja .bad
    jmp .four_tail
.four:
    lea r10,[r8+3]
    cmp r10,rsi
    jae .bad
    movzx r11d,byte [rdi+r8+1]
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
.four_tail:
    movzx r11d,byte [rdi+r8+2]
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    movzx r11d,byte [rdi+r8+3]
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    add r8,4
    jmp .loop
.ok:
    clc
    ret
.bad:
    mov rax,r8
    stc
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
