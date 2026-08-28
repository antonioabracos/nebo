; cli_driver-pattern_matching_e_destructuring compact offline media composition example
bits 64
default rel
%include "runtime/media/color.inc"
%include "runtime/image/image.inc"
%include "runtime/image/bmp.inc"
%include "runtime/audio/pcm.inc"
%include "runtime/audio/audio_device.inc"
%include "runtime/video/video_pipeline.inc"
section .bss
align 16
image resb 64
pixel resb 4
bmp resb 58
bmp_len resq 1
pcm resb 64
samples resw 4
frame resb 40
out_frame resb 40
pipeline resb 96
slot resb 40
section .text
global _start
_start:
 mov edi,255
 xor esi,esi
 xor edx,edx
 mov ecx,255
 call nebo_color_rgba_media_native_vertical
 test eax,eax
 jnz .fail1
 mov r10d,edx
 lea rdi,[rel image]
 lea rsi,[rel pixel]
 mov edx,4
 mov ecx,1
 mov r8d,1
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 test eax,eax
 jnz .fail2
 lea rdi,[rel image]
 xor esi,esi
 xor edx,edx
 mov ecx,r10d
 call nebo_image_set_pixel
 test eax,eax
 jnz .fail3
 lea rdi,[rel image]
 lea rsi,[rel bmp]
 mov edx,58
 lea rcx,[rel bmp_len]
 call nebo_bmp_encode
 test eax,eax
 jnz .fail4
 cmp qword [rel bmp_len],58
 jne .fail5
 lea rdi,[rel pcm]
 lea rsi,[rel samples]
 mov edx,8
 mov ecx,4
 mov r8d,8000
 mov r9d,1
 call nebo_pcm_init
 test eax,eax
 jnz .fail6
 lea rdi,[rel pcm]
 call nebo_pcm_duration_us
 test eax,eax
 jnz .fail7
 cmp edx,500
 jne .fail8
 lea rdi,[rel frame]
 lea rsi,[rel image]
 xor edx,edx
 mov ecx,40
 call nebo_video_frame_init
 test eax,eax
 jnz .fail9
 lea rdi,[rel pipeline]
 lea rsi,[rel slot]
 mov edx,1
 call nebo_video_pipeline_init
 test eax,eax
 jnz .fail10
 lea rdi,[rel pipeline]
 lea rsi,[rel frame]
 call nebo_video_pipeline_push
 test eax,eax
 jnz .fail11
 lea rdi,[rel pipeline]
 lea rsi,[rel out_frame]
 call nebo_video_pipeline_pop
 test eax,eax
 jnz .fail12
 cmp qword [rel out_frame+24],1
 jne .fail13
 xor edi,edi
 call nebo_audio_device_open
 cmp eax,NEBO_AUDIO_DEVICE_E_UNSUPPORTED_BACKEND
 jne .fail14
 lea rdi,[rel pipeline]
 call nebo_video_pipeline_close
 test eax,eax
 jnz .fail15
 xor edi,edi
 jmp .exit
%assign i 1
%rep 15
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
