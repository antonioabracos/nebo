bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"

extern nebo_path_parse
extern nebo_path_join
extern nebo_path_is_absolute
extern nebo_path_parent
extern nebo_path_filename
extern nebo_path_extension

section .rodata
p1 db 'a/./b//c'
p1_len equ $-p1
p2 db '/a//b/../c'
p2_len equ $-p2
p3 db '../a'
p3_len equ $-p3
p4 db 'root/a'
p4_len equ $-p4
p5 db '../b'
p5_len equ $-p5
p6 db '/escape'
p6_len equ $-p6
p7 db 'dir/file.txt'
p7_len equ $-p7
p8 db 'bad',0,'path'
p8_len equ $-p8

section .bss
path_buffer resb 128

section .text
global _start
_start:
 lea rdi,[p1]
 mov esi,p1_len
 lea rdx,[path_buffer]
 mov ecx,128
 call nebo_path_parse
 test eax,eax
 jnz .fail1
 cmp rdx,5
 jne .fail2
 cmp dword [path_buffer],0x2f622f61
 jne .fail3
 cmp byte [path_buffer+4],'c'
 jne .fail4
 cmp rcx,3
 jne .fail5

 lea rdi,[p2]
 mov esi,p2_len
 lea rdx,[path_buffer]
 mov ecx,128
 call nebo_path_parse
 test eax,eax
 jnz .fail6
 cmp rdx,4
 jne .fail7
 cmp dword [path_buffer],0x632f612f
 jne .fail8
 test r8,NEBO_PATH_FLAG_ABSOLUTE
 jz .fail9

 lea rdi,[p3]
 mov esi,p3_len
 lea rdx,[path_buffer]
 mov ecx,128
 call nebo_path_parse
 cmp eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jne .fail10

 lea rdi,[p4]
 mov esi,p4_len
 lea rdx,[p5]
 mov ecx,p5_len
 lea r8,[path_buffer]
 mov r9d,128
 call nebo_path_join
 test eax,eax
 jnz .fail11
 cmp rdx,6
 jne .fail12
 cmp dword [path_buffer],0x746f6f72
 jne .fail13
 cmp word [path_buffer+4],0x622f
 jne .fail14

 lea rdi,[p4]
 mov esi,p4_len
 lea rdx,[p6]
 mov ecx,p6_len
 lea r8,[path_buffer]
 mov r9d,128
 call nebo_path_join
 cmp eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jne .fail15

 lea rdi,[p7]
 mov esi,p7_len
 call nebo_path_parent
 test rax,rax
 jnz .fail16
 cmp rdx,3
 jne .fail17
 lea rdi,[p7]
 mov esi,p7_len
 call nebo_path_filename
 cmp rax,4
 jne .fail18
 cmp rdx,8
 jne .fail19
 lea rdi,[p7]
 mov esi,p7_len
 call nebo_path_extension
 cmp rax,9
 jne .fail20
 cmp rdx,3
 jne .fail21
 lea rdi,[p2]
 mov esi,p2_len
 call nebo_path_is_absolute
 cmp eax,1
 jne .fail22

 lea rdi,[p8]
 mov esi,p8_len
 lea rdx,[path_buffer]
 mov ecx,128
 call nebo_path_parse
 cmp eax,NEBO_FILE_ERROR_INVALID_PATH
 jne .fail23
 xor edi,edi
 jmp .exit
.fail1: mov edi,1
 jmp .exit
.fail2: mov edi,2
 jmp .exit
.fail3: mov edi,3
 jmp .exit
.fail4: mov edi,4
 jmp .exit
.fail5: mov edi,5
 jmp .exit
.fail6: mov edi,6
 jmp .exit
.fail7: mov edi,7
 jmp .exit
.fail8: mov edi,8
 jmp .exit
.fail9: mov edi,9
 jmp .exit
.fail10: mov edi,10
 jmp .exit
.fail11: mov edi,11
 jmp .exit
.fail12: mov edi,12
 jmp .exit
.fail13: mov edi,13
 jmp .exit
.fail14: mov edi,14
 jmp .exit
.fail15: mov edi,15
 jmp .exit
.fail16: mov edi,16
 jmp .exit
.fail17: mov edi,17
 jmp .exit
.fail18: mov edi,18
 jmp .exit
.fail19: mov edi,19
 jmp .exit
.fail20: mov edi,20
 jmp .exit
.fail21: mov edi,21
 jmp .exit
.fail22: mov edi,22
 jmp .exit
.fail23: mov edi,23
.exit:
 mov eax,60
 syscall
