bits 64
default rel
%include "runtime/image/image.inc"
%include "runtime/image/image_transform.inc"
section .bss
align 16
src resb 64
dst resb 64
aux resb 64
gray resb 64
srcbuf resb 16
dstbuf resb 64
auxbuf resb 64
graybuf resb 4
section .text
global _start
init_src:
 lea rdi,[rel src]
 lea rsi,[rel srcbuf]
 mov edx,16
 mov ecx,2
 mov r8d,2
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 ret
set4:
 lea rdi,[rel src]
 xor esi,esi
 xor edx,edx
 mov ecx,0xff000000
 call nebo_image_set_pixel
 lea rdi,[rel src]
 mov esi,1
 xor edx,edx
 mov ecx,0xff0000ff
 call nebo_image_set_pixel
 lea rdi,[rel src]
 xor esi,esi
 mov edx,1
 mov ecx,0xff00ff00
 call nebo_image_set_pixel
 lea rdi,[rel src]
 mov esi,1
 mov edx,1
 mov ecx,0xffffffff
 call nebo_image_set_pixel
 ret
_start:
 call init_src
 test eax,eax
 jnz .fail1
 call set4
 lea rdi,[rel dst]
 lea rsi,[rel dstbuf]
 mov edx,4
 mov ecx,1
 mov r8d,1
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 lea rdi,[rel src]
 lea rsi,[rel dst]
 mov edx,1
 xor ecx,ecx
 call nebo_image_crop_into
 test eax,eax
 jnz .fail2
 lea rdi,[rel dst]
 xor esi,esi
 xor edx,edx
 call nebo_image_pixel
 cmp edx,0xff0000ff
 jne .fail3
 lea rdi,[rel dst]
 lea rsi,[rel dstbuf]
 mov edx,16
 mov ecx,2
 mov r8d,2
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 lea rdi,[rel src]
 lea rsi,[rel dst]
 call nebo_image_flip_horizontal_into
 test eax,eax
 jnz .fail4
 lea rdi,[rel dst]
 xor esi,esi
 xor edx,edx
 call nebo_image_pixel
 cmp edx,0xff0000ff
 jne .fail5
 lea rdi,[rel src]
 lea rsi,[rel dst]
 call nebo_image_flip_vertical_into
 test eax,eax
 jnz .fail6
 lea rdi,[rel dst]
 xor esi,esi
 xor edx,edx
 call nebo_image_pixel
 cmp edx,0xff00ff00
 jne .fail7
 lea rdi,[rel src]
 lea rsi,[rel dst]
 mov edx,1
 call nebo_image_rotate90_into
 test eax,eax
 jnz .fail8
 lea rdi,[rel dst]
 mov esi,1
 xor edx,edx
 call nebo_image_pixel
 cmp edx,0xff000000
 jne .fail9
 lea rdi,[rel aux]
 lea rsi,[rel auxbuf]
 mov edx,64
 mov ecx,4
 mov r8d,4
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 lea rdi,[rel src]
 lea rsi,[rel aux]
 mov edx,NEBO_IMAGE_FILTER_NEAREST
 call nebo_image_resize_into
 test eax,eax
 jnz .fail10
 lea rdi,[rel aux]
 mov esi,3
 mov edx,3
 call nebo_image_pixel
 cmp edx,0xffffffff
 jne .fail11
 lea rdi,[rel aux]
 lea rsi,[rel auxbuf]
 mov edx,36
 mov ecx,3
 mov r8d,3
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 lea rdi,[rel src]
 lea rsi,[rel aux]
 mov edx,NEBO_IMAGE_FILTER_BILINEAR
 call nebo_image_resize_into
 test eax,eax
 jnz .fail12
 lea rdi,[rel aux]
 mov esi,1
 mov edx,1
 call nebo_image_pixel
 cmp edx,0xff408080
 jne .fail13
 lea rdi,[rel gray]
 lea rsi,[rel graybuf]
 mov edx,4
 mov ecx,2
 mov r8d,2
 mov r9d,NEBO_PIXEL_GRAY8
 call nebo_image_init
 lea rdi,[rel src]
 lea rsi,[rel gray]
 call nebo_image_convert_into
 test eax,eax
 jnz .fail14
 cmp byte [rel graybuf+1],54
 jne .fail15
 lea rdi,[rel src]
 lea rsi,[rel dst]
 mov edx,99
 call nebo_image_resize_into
 cmp eax,NEBO_MEDIA_E_ARGUMENT
 jne .fail16
 lea rdi,[rel dst]
 lea rsi,[rel dstbuf]
 mov edx,16
 mov ecx,2
 mov r8d,2
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 lea rdi,[rel dst]
 xor esi,esi
 xor edx,edx
 mov ecx,0xffff0000
 call nebo_image_set_pixel
 lea rdi,[rel src]
 xor esi,esi
 xor edx,edx
 mov ecx,0x800000ff
 call nebo_image_set_pixel
 lea rdi,[rel dst]
 lea rsi,[rel src]
 xor edx,edx
 xor ecx,ecx
 call nebo_image_composite_over
 test eax,eax
 jnz .fail17
 lea rdi,[rel dst]
 xor esi,esi
 xor edx,edx
 call nebo_image_pixel
 cmp edx,0xff7f0080
 jne .fail18
 xor edi,edi
 jmp .exit
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
