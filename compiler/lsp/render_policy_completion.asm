; Bounded RenderPlan policy completion registry for G074.
; The table exposes only migrated policy spellings. Deferred supplemental
; proposals are deliberately absent, so completion cannot activate them.
bits 64
default rel
%define NEBOC_RENDER_POLICY_COMPLETION_IMPLEMENTATION 1
%include "compiler/lsp/render_policy_completion.inc"

section .rodata
%macro G74_COMPLETION_NAME 3
g74_completion_name_%1: db %2
g74_completion_name_%1_len equ $-g74_completion_name_%1
%endmacro
G74_COMPLETION_NAME 1,'strict',0
G74_COMPLETION_NAME 2,'loose',0
G74_COMPLETION_NAME 3,'allowCoerce',0
G74_COMPLETION_NAME 4,'noCoerce',0
G74_COMPLETION_NAME 5,'validateOnly',0
G74_COMPLETION_NAME 6,'formatOnly',0
G74_COMPLETION_NAME 7,'placeholderMode',0
G74_COMPLETION_NAME 8,'unknownPlaceholder',0
G74_COMPLETION_NAME 9,'missingArgs',0
G74_COMPLETION_NAME 10,'extraArgs',0
G74_COMPLETION_NAME 11,'render',0
G74_COMPLETION_NAME 12,'allowSlash',0
G74_COMPLETION_NAME 13,'disableSlash',0
G74_COMPLETION_NAME 14,'strictSlash',0
G74_COMPLETION_NAME 15,'unknownSlashAsText',0
G74_COMPLETION_NAME 16,'slashFallback',0
%undef G74_COMPLETION_NAME

; name, length, stable id, minimum args, maximum args, maturity.
g74_completion_table:
 dq g74_completion_name_1,g74_completion_name_1_len,1,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_2,g74_completion_name_2_len,2,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_3,g74_completion_name_3_len,3,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_4,g74_completion_name_4_len,4,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_5,g74_completion_name_5_len,5,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_6,g74_completion_name_6_len,6,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_7,g74_completion_name_7_len,7,1,1,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_8,g74_completion_name_8_len,8,1,1,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_9,g74_completion_name_9_len,9,1,1,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_10,g74_completion_name_10_len,10,1,1,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_11,g74_completion_name_11_len,11,1,1,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_12,g74_completion_name_12_len,12,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_13,g74_completion_name_13_len,13,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_14,g74_completion_name_14_len,14,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_15,g74_completion_name_15_len,15,0,0,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 dq g74_completion_name_16,g74_completion_name_16_len,16,1,1,NEBOC_G074_MATURITY_PUBLIC_BOUNDED
g74_completion_row_size equ 48

section .text
global neboc_render_policy_complete
global neboc_render_policy_completion_resolve

; RDI prefix, RSI byte length, RDX caller-owned qword IDs, RCX capacity.
; Returns the stable match count, or a negative typed error. It performs a
; counting pass before publishing IDs, so capacity failure is atomic.
neboc_render_policy_complete:
 push rbx
 push r12
 push r13
 push r14
 push r15
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,NEBOC_G074_COMPLETION_MAX_PREFIX
 ja .limit
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 xor r15d,r15d
 lea r8,[rel g74_completion_table]
 mov r9d,NEBOC_G074_COMPLETION_COUNT
.count_row:
 test r9d,r9d
 jz .counted
 cmp r12,[r8+8]
 ja .count_next
 xor r10d,r10d
.count_bytes:
 cmp r10,r12
 jae .count_match
 mov al,[rbx+r10]
 mov r11,[r8]
 cmp al,[r11+r10]
 jne .count_next
 inc r10
 jmp .count_bytes
.count_match:
 inc r15
.count_next:
 add r8,g74_completion_row_size
 dec r9d
 jmp .count_row
.counted:
 test r15,r15
 jz .success
 test r13,r13
 jz .invalid
 cmp r14,r15
 jb .capacity
 lea r8,[rel g74_completion_table]
 mov r9d,NEBOC_G074_COMPLETION_COUNT
 xor ecx,ecx
.write_row:
 test r9d,r9d
 jz .success
 cmp r12,[r8+8]
 ja .write_next
 xor r10d,r10d
.write_bytes:
 cmp r10,r12
 jae .write_match
 mov al,[rbx+r10]
 mov r11,[r8]
 cmp al,[r11+r10]
 jne .write_next
 inc r10
 jmp .write_bytes
.write_match:
 mov rax,[r8+16]
 mov [r13+rcx*8],rax
 inc rcx
.write_next:
 add r8,g74_completion_row_size
 dec r9d
 jmp .write_row
.success:
 mov rax,r15
 jmp .done
.invalid:
 mov rax,-NEBOC_G074_COMPLETION_INVALID
 jmp .done
.limit:
 mov rax,-NEBOC_G074_COMPLETION_LIMIT
 jmp .done
.capacity:
 mov rax,-NEBOC_G074_COMPLETION_CAPACITY
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI stable candidate id, RSI caller-owned 24-byte result.
neboc_render_policy_completion_resolve:
 test rsi,rsi
 jz .resolve_invalid
 test rdi,rdi
 jz .resolve_unknown
 cmp rdi,NEBOC_G074_COMPLETION_COUNT
 ja .resolve_unknown
 dec rdi
 imul rax,rdi,g74_completion_row_size
 lea rdx,[rel g74_completion_table]
 add rdx,rax
 mov rax,[rdx+24]
 mov [rsi+NEBOC_G074_COMPLETION_MIN_ARGS],rax
 mov rax,[rdx+32]
 mov [rsi+NEBOC_G074_COMPLETION_MAX_ARGS],rax
 mov rax,[rdx+40]
 mov [rsi+NEBOC_G074_COMPLETION_MATURITY],rax
 xor eax,eax
 ret
.resolve_invalid:
 mov eax,NEBOC_G074_COMPLETION_INVALID
 ret
.resolve_unknown:
 mov eax,NEBOC_G074_COMPLETION_UNKNOWN
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
