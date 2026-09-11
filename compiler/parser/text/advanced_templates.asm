bits 64
default rel
%define NEBO_ADVANCED_TEMPLATES_IMPLEMENTATION 1
%include "compiler/parser/text/advanced_templates.inc"
%include "runtime/textual/tagged_templates.inc"

section .text
global neboc_advanced_text_parse
global neboc_tagged_template_lower

; rdi=complete source lexeme, rsi=byte length, rdx=caller-owned AST.
; Content is an immutable borrowed source span.  The AST is committed only
; after delimiter, bounds, tag maturity and line/indent checks all succeed.
neboc_advanced_text_parse:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .invalid
 test r14,r14
 jz .invalid
 cmp r13,3
 jb .syntax
 cmp r13,ADVANCED_TEXT_MAX_INPUT
 ja .limit
 xor ebx,ebx                       ; kind
 xor r15d,r15d                     ; tag
 mov qword [rsp],0                 ; flags
 mov qword [rsp+8],0               ; content offset
 mov qword [rsp+16],0              ; content length
 mov qword [rsp+24],TEXT_DEDENT_PRESERVE
 mov qword [rsp+32],TEXT_NEWLINE_PRESERVE
 cmp byte [r12],'r'
 jne .not_raw
 cmp byte [r12+1],'"'
 jne .tagged
 cmp r13,3
 jb .syntax
 cmp r13,7
 jb .raw_single
 cmp byte [r12+2],'"'
 jne .raw_single
 cmp byte [r12+3],'"'
 jne .raw_single
 cmp byte [r12+r13-1],'"'
 jne .syntax
 cmp byte [r12+r13-2],'"'
 jne .syntax
 cmp byte [r12+r13-3],'"'
 jne .syntax
 mov ebx,ADVANCED_TEXT_RAW_MULTILINE
 mov qword [rsp],ADVANCED_TEXT_FLAG_RAW | ADVANCED_TEXT_FLAG_MULTILINE | ADVANCED_TEXT_FLAG_SLASH_OFF
 mov qword [rsp+8],4
 mov rax,r13
 sub rax,7
 mov [rsp+16],rax
 mov qword [rsp+24],TEXT_DEDENT_COMMON
 mov qword [rsp+32],TEXT_NEWLINE_LF
 jmp .scan_policy
.raw_single:
 cmp byte [r12+r13-1],'"'
 jne .syntax
 mov ebx,ADVANCED_TEXT_RAW_SINGLE
 mov qword [rsp],ADVANCED_TEXT_FLAG_RAW | ADVANCED_TEXT_FLAG_SLASH_OFF
 mov qword [rsp+8],2
 mov rax,r13
 sub rax,3
 mov [rsp+16],rax
 jmp .scan_single
.not_raw:
 cmp byte [r12],'"'
 jne .tagged
 cmp r13,6
 jb .syntax
 cmp byte [r12+1],'"'
 jne .syntax
 cmp byte [r12+2],'"'
 jne .syntax
 cmp byte [r12+r13-1],'"'
 jne .syntax
 cmp byte [r12+r13-2],'"'
 jne .syntax
 cmp byte [r12+r13-3],'"'
 jne .syntax
 mov ebx,ADVANCED_TEXT_MULTILINE
 mov qword [rsp],ADVANCED_TEXT_FLAG_MULTILINE | ADVANCED_TEXT_FLAG_INTERPOLABLE
 mov qword [rsp+8],3
 mov rax,r13
 sub rax,6
 mov [rsp+16],rax
 mov qword [rsp+24],TEXT_DEDENT_COMMON
 mov qword [rsp+32],TEXT_NEWLINE_LF
 jmp .scan_policy
.tagged:
 xor ecx,ecx
.tag_name:
 cmp rcx,r13
 jae .syntax
 mov al,[r12+rcx]
 cmp al,'a'
 jb .tag_end
 cmp al,'z'
 ja .tag_end
 inc rcx
 cmp rcx,16
 ja .syntax
 jmp .tag_name
.tag_end:
 test rcx,rcx
 jz .syntax
 lea rax,[rcx+6]
 cmp rax,r13
 ja .syntax
 cmp byte [r12+rcx],'"'
 jne .syntax
 cmp byte [r12+rcx+1],'"'
 jne .syntax
 cmp byte [r12+rcx+2],'"'
 jne .syntax
 cmp byte [r12+r13-1],'"'
 jne .syntax
 cmp byte [r12+r13-2],'"'
 jne .syntax
 cmp byte [r12+r13-3],'"'
 jne .syntax
 mov [rsp+40],rcx
 lea rdx,[rsp+48]
 mov rdi,r12
 mov rsi,rcx
 call neboc_template_tag_lookup
 test eax,eax
 jnz .security
 cmp qword [rsp+48+TEMPLATE_TAG_RECORD_MATURITY],TEMPLATE_TAG_MATURITY_EXTERNAL
 je .external
 mov r15,[rsp+48+TEMPLATE_TAG_RECORD_ID]
 mov ebx,ADVANCED_TEXT_TAGGED
 mov qword [rsp],ADVANCED_TEXT_FLAG_MULTILINE | ADVANCED_TEXT_FLAG_INTERPOLABLE | ADVANCED_TEXT_FLAG_TAGGED
 mov rax,[rsp+40]
 add rax,3
 mov [rsp+8],rax
 mov rax,r13
 sub rax,[rsp+40]
 sub rax,6
 mov [rsp+16],rax
 mov qword [rsp+24],TEXT_DEDENT_COMMON
 mov qword [rsp+32],TEXT_NEWLINE_LF
.scan_policy:
 xor ecx,ecx                       ; lines after first
 xor edx,edx                       ; indentation run
 mov r8,[rsp+8]
 mov r9,[rsp+16]
 xor eax,eax                       ; line-start flag
 inc eax
.policy_loop:
 cmp r9,0
 je .commit
 mov dil,[r12+r8]
 cmp dil,10
 je .policy_newline
 cmp dil,13
 je .policy_cr
 test eax,eax
 jz .policy_next
 cmp dil,' '
 jne .policy_content
 inc edx
 cmp edx,ADVANCED_TEXT_MAX_INDENT
 ja .limit
 jmp .policy_next
.policy_content:
 xor eax,eax
 jmp .policy_next
.policy_newline:
 inc ecx
 cmp ecx,ADVANCED_TEXT_MAX_LINES
 jae .limit
 mov eax,1
 xor edx,edx
 jmp .policy_next
.policy_cr:
 inc ecx
 cmp ecx,ADVANCED_TEXT_MAX_LINES
 jae .limit
 mov eax,1
 xor edx,edx
 ; CRLF is one logical newline, not two budget units.
 cmp r9,1
 jbe .policy_next
 cmp byte [r12+r8+1],10
 jne .policy_next
 inc r8
 dec r9
.policy_next:
 inc r8
 dec r9
 jmp .policy_loop
.scan_single:
 mov rcx,[rsp+8]
 mov rax,[rsp+16]
.single_loop:
 test rax,rax
 jz .commit
 cmp byte [r12+rcx],10
 je .syntax
 cmp byte [r12+rcx],13
 je .syntax
 inc rcx
 dec rax
 jmp .single_loop
.commit:
 mov [r14+ADVANCED_TEXT_AST_KIND],rbx
 mov [r14+ADVANCED_TEXT_AST_TAG],r15
 mov rax,[rsp+8]
 add rax,r12
 mov [r14+ADVANCED_TEXT_AST_CONTENT],rax
 mov rax,[rsp+16]
 mov [r14+ADVANCED_TEXT_AST_LENGTH],rax
 mov rax,[rsp]
 mov [r14+ADVANCED_TEXT_AST_FLAGS],rax
 mov qword [r14+ADVANCED_TEXT_AST_VERSION],TEMPLATE_TAG_VERSION
 mov rax,[rsp+24]
 mov [r14+ADVANCED_TEXT_AST_DEDENT],rax
 mov rax,[rsp+32]
 mov [r14+ADVANCED_TEXT_AST_NEWLINE],rax
 xor eax,eax
 jmp .done
.invalid: mov eax,ADVANCED_TEXT_E_INVALID
 jmp .done
.syntax: mov eax,ADVANCED_TEXT_E_SYNTAX
 jmp .done
.limit: mov eax,ADVANCED_TEXT_E_LIMIT
 jmp .done
.security: mov eax,ADVANCED_TEXT_E_SECURITY
 jmp .done
.external: mov eax,ADVANCED_TEXT_E_EXTERNAL
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=validated AST, rsi=caller-owned specific FormatPlan. Failure atomic.
neboc_tagged_template_lower:
 test rdi,rdi
 jz .lower_invalid
 test rsi,rsi
 jz .lower_invalid
 cmp qword [rdi+ADVANCED_TEXT_AST_KIND],ADVANCED_TEXT_TAGGED
 jne .lower_invalid
 mov rax,[rdi+ADVANCED_TEXT_AST_TAG]
 cmp rax,TEMPLATE_TAG_HTML
 jb .lower_invalid
 cmp rax,TEMPLATE_TAG_CONSOLE
 ja .lower_external
 cmp qword [rdi+ADVANCED_TEXT_AST_VERSION],TEMPLATE_TAG_VERSION
 jne .lower_invalid
 mov qword [rsi+TAGGED_PLAN_KIND],ADVANCED_TEXT_TAGGED
 mov [rsi+TAGGED_PLAN_TAG],rax
 mov rax,[rdi+ADVANCED_TEXT_AST_CONTENT]
 mov [rsi+TAGGED_PLAN_CONTENT],rax
 mov rax,[rdi+ADVANCED_TEXT_AST_LENGTH]
 mov [rsi+TAGGED_PLAN_LENGTH],rax
 mov rax,[rdi+ADVANCED_TEXT_AST_FLAGS]
 mov [rsi+TAGGED_PLAN_FLAGS],rax
 mov qword [rsi+TAGGED_PLAN_VERSION],TEMPLATE_TAG_VERSION
 xor eax,eax
 ret
.lower_invalid: mov eax,ADVANCED_TEXT_E_INVALID
 ret
.lower_external: mov eax,ADVANCED_TEXT_E_EXTERNAL
 ret
