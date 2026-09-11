; Contextual choice variants share the existing ScanPlan membership, unique
; prefix, finite yes/no and multiple-selection mask owners.
%include "runtime/textual/scan_validation_source_probe.inc"
section .text
sp_choice_option:
 mov rax,[rsi]
 sub rax,68
 lea rdx,[rel sp_choice_flags]
 mov rdx,[rdx+rax*8]
 mov [rdi+SP_CHOICE_FLAGS],rdx
 cmp rax,6
 jae .boolean
 mov rdx,[rsi+8]
 mov [rdi+SP_CHOICES],rdx
 cmp rax,3
 jne .ok
 mov qword [rdi+SP_KIND],SCAN_KIND_INT
 jmp .ok
.boolean:
 mov qword [rdi+SP_KIND],SCAN_KIND_BOOL
.ok:
 xor eax,eax
 ret

; A bounded headless multi-selection carries the native 32-bit selection mask
; as an Int value. Exact comma-separated labels resolve through the canonical
; membership owner; duplicate, empty and unknown selections never commit.
sp_multi_selection:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,[rbx+SP_INPUT]
 mov r13,[rbx+SP_LENGTH]
 xor r14d,r14d
 xor r15d,r15d
 mov qword [rsp],0
.scan:
 cmp r14,r13
 jae .label
 cmp byte [r12+r14],','
 je .label
 inc r14
 jmp .scan
.label:
 cmp r15,32
 jae .bad
 mov rsi,r14
 sub rsi,[rsp]
 jz .bad
 mov rdi,r12
 add rdi,[rsp]
 lea rdx,[rbx+9888]
 lea rcx,[rbx+10144]
 mov rax,[rbx+SP_CHOICES]
 mov r8,[rax]
 call neboc_scan_choice_index
 test rax,rax
 js .bad
 mov [rbx+r15+10544],al
 inc r15
 cmp r14,r13
 jae .mask
 inc r14
 mov [rsp],r14
 jmp .scan
.mask:
 lea rdi,[rbx+10544]
 mov rsi,r15
 mov rax,[rbx+SP_CHOICES]
 mov rdx,[rax]
 lea rcx,[rbx+SP_VALUE]
 call nebo_g076_multiselect_mask
 test eax,eax
 jnz .done
 mov [rbx+SP_SELECTION_COUNT],r15
 jmp .done
.bad:
 mov eax,SCAN_E_VALIDATE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
align 8
sp_choice_flags:
 dq NEBO_G105_CHOICE_ONE_OF,NEBO_G105_CHOICE_MENU,NEBO_G105_CHOICE_SELECT
 dq NEBO_G105_CHOICE_MULTI,NEBO_G105_CHOICE_ENUM,NEBO_G105_CHOICE_AUTOCOMPLETE
 dq NEBO_G105_CHOICE_BOOLEAN,NEBO_G105_CHOICE_CONFIRM
section .text
