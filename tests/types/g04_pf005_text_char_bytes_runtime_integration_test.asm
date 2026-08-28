; TEXT-CHAR-UNICODE-E-BYTES-PF005 runtime_core integration scenarios
bits 64
default rel
%include "runtime/textual/text-char-bytes/text_char_bytes_runtime.inc"
extern nebo_runtime_textual_text_byte_length
extern nebo_runtime_textual_text_codepoint_count
extern nebo_runtime_textual_char_codepoint
extern nebo_runtime_textual_bytes_empty
extern nebo_runtime_textual_bytes_byte_length
global _start
section .rodata
ascii_data: db 'N','e','b','o'
ascii_desc: dq ascii_data,4,0
utf8_data: db 0x4e,0xc3,0xa9,0x62,0x6f,0xf0,0x9f,0x98,0x80
utf8_desc: dq utf8_data,9,0
empty_data: db 0
empty_text: dq empty_data,0,0
section .text
_start:
 mov rax,[rsp]
 cmp rax,2
 jne .fail
 mov rax,[rsp+16]
 cmp byte [rax+1],0
 jne .fail
 movzx ecx,byte [rax]
 cmp ecx,'1'
 je .s1
 cmp ecx,'2'
 je .s2
 cmp ecx,'3'
 je .s3
 cmp ecx,'4'
 je .s4
 cmp ecx,'5'
 je .s5
 cmp ecx,'6'
 je .s6
 cmp ecx,'7'
 je .s7
 cmp ecx,'8'
 je .s8
 cmp ecx,'9'
 je .s9
 cmp ecx,'A'
 je .s10
 cmp ecx,'B'
 je .s11
 cmp ecx,'C'
 je .s12
 cmp ecx,'D'
 je .s13
 cmp ecx,'E'
 je .s14
 cmp ecx,'F'
 je .s15
 cmp ecx,'G'
 je .s16
 jmp .fail
.s1: lea rdi,[rel ascii_desc]
 call nebo_runtime_textual_text_byte_length
 cmp rax,4
 jne .fail
 jmp .pass
.s2: lea rdi,[rel utf8_desc]
 call nebo_runtime_textual_text_byte_length
 cmp rax,9
 jne .fail
 jmp .pass
.s3: lea rdi,[rel ascii_desc]
 call nebo_runtime_textual_text_codepoint_count
 cmp rax,4
 jne .fail
 jmp .pass
.s4: lea rdi,[rel utf8_desc]
 call nebo_runtime_textual_text_codepoint_count
 cmp rax,5
 jne .fail
 jmp .pass
.s5: lea rdi,[rel empty_text]
 call nebo_runtime_textual_text_codepoint_count
 test rax,rax
 jne .fail
 jmp .pass
.s6: mov edi,65
 call nebo_runtime_textual_char_codepoint
 cmp rax,65
 jne .fail
 jmp .pass
.s7: mov edi,0x1f600
 call nebo_runtime_textual_char_codepoint
 cmp rax,0x1f600
 jne .fail
 jmp .pass
.s8: call nebo_runtime_textual_bytes_empty
 test rax,rax
 jz .fail
 cmp qword [rax+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET],0
 jne .fail
 jmp .pass
.s9: call nebo_runtime_textual_bytes_empty
 mov rdi,rax
 call nebo_runtime_textual_bytes_byte_length
 test rax,rax
 jne .fail
 jmp .pass
.s10: call nebo_runtime_textual_bytes_empty
 cmp dword [rax+NEBO_RUNTIME_BYTES_DESCRIPTOR_FLAGS_OFFSET],NEBO_RUNTIME_BYTES_FLAGS_EMPTY
 jne .fail
 jmp .pass
.s11: call nebo_runtime_textual_bytes_empty
 cmp word [rax+NEBO_RUNTIME_BYTES_DESCRIPTOR_ELEMENT_WIDTH_OFFSET],1
 jne .fail
 jmp .pass
.s12: call nebo_runtime_textual_bytes_empty
 cmp word [rax+NEBO_RUNTIME_BYTES_DESCRIPTOR_LIFETIME_OFFSET],1
 jne .fail
 jmp .pass
.s13: lea rdi,[rel utf8_desc]
 call nebo_runtime_textual_text_codepoint_count
 mov rbx,rax
 lea rdi,[rel utf8_desc]
 call nebo_runtime_textual_text_byte_length
 cmp rbx,rax
 ja .fail
 jmp .pass
.s14: mov edi,0x10ffff
 call nebo_runtime_textual_char_codepoint
 cmp rax,0x10ffff
 jne .fail
 jmp .pass
.s15: lea rdi,[rel empty_text]
 call nebo_runtime_textual_text_byte_length
 test rax,rax
 jne .fail
 jmp .pass
.s16: call nebo_runtime_textual_bytes_empty
 mov rbx,rax
 call nebo_runtime_textual_bytes_empty
 cmp rax,rbx
 jne .fail
 jmp .pass
.pass: mov eax,60
 xor edi,edi
 syscall
.fail: mov eax,60
 mov edi,1
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
