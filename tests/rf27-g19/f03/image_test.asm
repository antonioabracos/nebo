bits 64
default rel
%include "runtime/image/image.inc"
section .bss
align 16
desc resb 64
region resb 64
graydesc resb 64
pixels resb 64
graypixels resb 8
section .text
global _start
_start:
 lea rdi,[rel desc]
 lea rsi,[rel pixels]
 mov edx,48
 mov ecx,4
 mov r8d,3
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 test eax,eax
 jnz .fail1
 cmp qword [rel pixels],0
 jne .fail2
 lea rdi,[rel desc]
 call nebo_image_width
 cmp edx,4
 jne .fail3
 lea rdi,[rel desc]
 call nebo_image_height
 cmp edx,3
 jne .fail4
 lea rdi,[rel desc]
 call nebo_image_stride
 cmp edx,16
 jne .fail5
 lea rdi,[rel desc]
 mov esi,2
 mov edx,1
 mov ecx,0x44332211
 call nebo_image_set_pixel
 test eax,eax
 jnz .fail6
 lea rdi,[rel desc]
 mov esi,2
 mov edx,1
 call nebo_image_pixel
 test eax,eax
 jnz .fail7
 cmp edx,0x44332211
 jne .fail8
 lea rdi,[rel desc]
 mov esi,4
 xor edx,edx
 call nebo_image_pixel
 cmp eax,NEBO_MEDIA_E_BOUNDS
 jne .fail9
 lea rdi,[rel region]
 lea rsi,[rel desc]
 mov edx,1
 mov ecx,1
 mov r8d,2
 mov r9d,2
 call nebo_image_region
 test eax,eax
 jnz .fail10
 lea rdi,[rel region]
 mov esi,1
 xor edx,edx
 call nebo_image_pixel
 test eax,eax
 jnz .fail11
 cmp edx,0x44332211
 jne .fail12
 lea rdi,[rel desc]
 call nebo_image_close
 test eax,eax
 jnz .fail13
 lea rdi,[rel region]
 xor esi,esi
 xor edx,edx
 call nebo_image_pixel
 cmp eax,NEBO_MEDIA_E_STALE
 jne .fail14
 lea rdi,[rel desc]
 call nebo_image_close
 cmp eax,NEBO_MEDIA_E_STALE
 jne .fail15
 lea rdi,[rel graydesc]
 lea rsi,[rel graypixels]
 mov edx,6
 mov ecx,3
 mov r8d,2
 mov r9,NEBO_PIXEL_GRAY8
 shl r9,32
 or r9,3
 call nebo_image_wrap_mut
 test eax,eax
 jnz .fail16
 lea rdi,[rel graydesc]
 mov esi,2
 mov edx,1
 mov ecx,0xff0000ff
 call nebo_image_set_pixel
 test eax,eax
 jnz .fail17
 cmp byte [rel graypixels+5],54
 jne .fail18
 lea rdi,[rel graydesc]
 mov esi,2
 mov edx,1
 call nebo_image_pixel
 cmp edx,54
 jne .fail19
 mov rax,0xaaaaaaaaaaaaaaaa
 mov [rel desc],rax
 lea rdi,[rel desc]
 lea rsi,[rel pixels]
 mov edx,64
 xor ecx,ecx
 mov r8d,1
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 cmp eax,NEBO_MEDIA_E_LIMIT
 jne .fail20
 mov rax,0xaaaaaaaaaaaaaaaa
 cmp qword [rel desc],rax
 jne .fail21
 lea rdi,[rel region]
 lea rsi,[rel graydesc]
 mov edx,2
 mov ecx,1
 mov r8d,2
 mov r9d,1
 call nebo_image_region
 cmp eax,NEBO_MEDIA_E_BOUNDS
 jne .fail22
 xor edi,edi
 jmp .exit
%assign i 1
%rep 22
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
