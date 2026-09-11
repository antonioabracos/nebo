bits 64
default rel
%include "compiler/lowering/textual/format_ir.inc"
%include "compiler/parser/text/interpolation_plan.inc"
section .text
global neboc_format_lower_literal
global neboc_interpolation_lower_to_format_plan
; rdi=destination node, rsi=bytes, rdx=len; constructs canonical FormatPlan IR.
neboc_format_lower_literal:
    test rdi, rdi
    jz .bad
    test rsi, rsi
    jz .bad
    cmp rdx, FORMAT_MAX_OUTPUT
    ja .bad
    mov qword [rdi + FORMAT_NODE_KIND], FORMAT_NODE_LITERAL
    mov [rdi + FORMAT_NODE_DATA], rsi
    mov [rdi + FORMAT_NODE_LENGTH], rdx
    mov qword [rdi + FORMAT_NODE_PROFILE], 0
    xor eax, eax
    ret
.bad:
    mov eax, FORMAT_E_INVALID
    ret

; rdi=InterpolationSegment[], rsi=count, rdx=InterpolationValue[], rcx=value
; count, r8=FormatNode[], r9=node capacity.  EAX=status, RDX=exact evaluation
; count, RCX=joined privacy label.  Validation is a complete first pass, so a
; failing request leaves the destination node array byte-identical.
neboc_interpolation_lower_to_format_plan:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov [rsp], r8
    mov [rsp+8], r9
    test r12, r12
    jz .lower_invalid
    test r13, r13
    jz .lower_invalid
    cmp r13, INTERPOLATION_MAX_SEGMENTS
    ja .lower_limit
    test r8, r8
    jz .lower_invalid
    cmp r9, r13
    jb .lower_capacity
    xor ebx, ebx                      ; segment index
    xor r10d, r10d                    ; expression count
    xor r11d, r11d                    ; joined privacy
.lower_validate:
    cmp rbx, r13
    jae .lower_validate_done
    mov rax, rbx
    shl rax, 5
    add rax, r12
    mov rdx, [rax+INTERPOLATION_SEGMENT_KIND]
    cmp rdx, INTERPOLATION_SEGMENT_LITERAL
    je .lower_literal_valid
    cmp rdx, INTERPOLATION_SEGMENT_EXPRESSION
    jne .lower_invalid
    cmp r10, r15
    jae .lower_invalid
    test r14, r14
    jz .lower_invalid
    mov rdx, r10
    shl rdx, 5
    add rdx, r14
    mov rcx, [rdx+INTERPOLATION_VALUE_PROFILE]
    cmp rcx, [rax+INTERPOLATION_SEGMENT_PROFILE]
    jne .lower_invalid
    mov rcx, [rdx+INTERPOLATION_VALUE_LENGTH]
    test rcx, rcx
    jz .lower_expr_privacy
    cmp qword [rdx+INTERPOLATION_VALUE_DATA], 0
    je .lower_invalid
.lower_expr_privacy:
    mov rcx, [rdx+INTERPOLATION_VALUE_PRIVACY]
    cmp rcx, r11
    cmova r11, rcx
    inc r10
    jmp .lower_validate_next
.lower_literal_valid:
    cmp qword [rax+INTERPOLATION_SEGMENT_PROFILE], 0
    jne .lower_invalid
    mov rcx, [rax+INTERPOLATION_SEGMENT_LENGTH]
    test rcx, rcx
    jz .lower_validate_next
    cmp qword [rax+INTERPOLATION_SEGMENT_DATA], 0
    je .lower_invalid
.lower_validate_next:
    inc rbx
    jmp .lower_validate
.lower_validate_done:
    cmp r10, r15
    jne .lower_invalid
    xor ebx, ebx
    xor r10d, r10d
.lower_publish:
    cmp rbx, r13
    jae .lower_ok
    mov rax, rbx
    shl rax, 5
    lea rdi, [r12+rax]
    mov rsi, [rsp]
    add rsi, rax
    cmp qword [rdi+INTERPOLATION_SEGMENT_KIND], INTERPOLATION_SEGMENT_LITERAL
    jne .lower_publish_expression
    mov qword [rsi+FORMAT_NODE_KIND], FORMAT_NODE_LITERAL
    mov rax, [rdi+INTERPOLATION_SEGMENT_DATA]
    mov [rsi+FORMAT_NODE_DATA], rax
    mov rax, [rdi+INTERPOLATION_SEGMENT_LENGTH]
    mov [rsi+FORMAT_NODE_LENGTH], rax
    mov qword [rsi+FORMAT_NODE_PROFILE], 0
    jmp .lower_publish_next
.lower_publish_expression:
    mov rax, r10
    shl rax, 5
    lea rdx, [r14+rax]
    mov qword [rsi+FORMAT_NODE_KIND], FORMAT_NODE_VALUE
    mov rax, [rdx+INTERPOLATION_VALUE_DATA]
    mov [rsi+FORMAT_NODE_DATA], rax
    mov rax, [rdx+INTERPOLATION_VALUE_LENGTH]
    mov [rsi+FORMAT_NODE_LENGTH], rax
    mov rax, [rdx+INTERPOLATION_VALUE_PROFILE]
    mov [rsi+FORMAT_NODE_PROFILE], rax
    inc r10
.lower_publish_next:
    inc rbx
    jmp .lower_publish
.lower_ok:
    mov rdx, r10
    mov rcx, r11
    xor eax, eax
    jmp .lower_done
.lower_invalid:
    xor edx, edx
    xor ecx, ecx
    mov eax, FORMAT_E_INVALID
    jmp .lower_done
.lower_limit:
    xor edx, edx
    xor ecx, ecx
    mov eax, FORMAT_E_LIMIT
    jmp .lower_done
.lower_capacity:
    xor edx, edx
    xor ecx, ecx
    mov eax, FORMAT_E_CAPACITY
.lower_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
