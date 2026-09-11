bits 64
default rel
%include "runtime/audio/audio_device.inc"
%include "runtime/video/video_pipeline.inc"
section .bss
align 16
image resb 64
pixels resb 4
frame1 resb 40
frame2 resb 40
mapped resb 40
out_frame resb 40
pipeline resb 96
slots resb 80
device resb 64
section .text
global _start
_start:
 mov rax,0x5555555555555555
 mov [rel device],rax
 lea rdi,[rel device]
 call nebo_audio_device_open
 cmp eax,NEBO_AUDIO_DEVICE_E_UNSUPPORTED_BACKEND
 jne .fail1
 mov rax,0x5555555555555555
 cmp [rel device],rax
 jne .fail2
 lea rax,[rel pixels]
 mov [rel image],rax
 mov qword [rel image+8],4
 mov dword [rel image+16],1
 mov dword [rel image+20],1
 mov dword [rel image+24],4
 mov word [rel image+28],NEBO_PIXEL_RGBA8
 mov word [rel image+30],NEBO_IMAGE_FLAG_OWNED
 mov qword [rel image+32],1
 lea rdi,[rel frame1]
 lea rsi,[rel image]
 mov edx,1000
 mov ecx,40
 call nebo_video_frame_init
 test eax,eax
 jnz .fail3
 lea rdi,[rel mapped]
 lea rsi,[rel frame1]
 lea rdx,[rel image]
 call nebo_video_frame_transform_copy
 test eax,eax
 jnz .fail4
 test dword [rel mapped+32],NEBO_VIDEO_FRAME_FLAG_TRANSFORMED
 jz .fail5
 lea rdi,[rel frame2]
 lea rsi,[rel image]
 mov edx,1040
 mov ecx,40
 call nebo_video_frame_init
 test eax,eax
 jnz .fail6
 lea rdi,[rel pipeline]
 lea rsi,[rel slots]
 mov edx,2
 call nebo_video_pipeline_init
 test eax,eax
 jnz .fail7
 lea rdi,[rel pipeline]
 lea rsi,[rel frame1]
 call nebo_video_pipeline_push
 test eax,eax
 jnz .fail8
 lea rdi,[rel pipeline]
 lea rsi,[rel frame2]
 call nebo_video_pipeline_push
 test eax,eax
 jnz .fail9
 cmp qword [rel pipeline+32],2
 jne .fail10
 lea rdi,[rel pipeline]
 lea rsi,[rel frame2]
 call nebo_video_pipeline_push
 cmp eax,NEBO_VIDEO_E_FULL
 jne .fail11
 lea rdi,[rel pipeline]
 lea rsi,[rel out_frame]
 call nebo_video_pipeline_pop
 test eax,eax
 jnz .fail12
 cmp qword [rel out_frame+8],1000
 jne .fail13
 cmp qword [rel out_frame+24],1
 jne .fail14
 lea rdi,[rel pipeline]
 call nebo_video_pipeline_cancel
 test eax,eax
 jnz .fail15
 cmp qword [rel pipeline+32],0
 jne .fail16
 cmp qword [rel slots],0
 jne .fail17
 lea rdi,[rel pipeline]
 lea rsi,[rel out_frame]
 call nebo_video_pipeline_pop
 cmp eax,NEBO_VIDEO_E_CANCELLED
 jne .fail18
 lea rdi,[rel pipeline]
 call nebo_video_pipeline_close
 test eax,eax
 jnz .fail19
 lea rdi,[rel pipeline]
 lea rsi,[rel frame1]
 call nebo_video_pipeline_push
 cmp eax,NEBO_VIDEO_E_CLOSED
 jne .fail20
 ; Fresh queue rejects timestamp regression atomically.
 lea rdi,[rel pipeline]
 lea rsi,[rel slots]
 mov edx,2
 call nebo_video_pipeline_init
 lea rdi,[rel pipeline]
 lea rsi,[rel frame2]
 call nebo_video_pipeline_push
 lea rdi,[rel pipeline]
 lea rsi,[rel frame1]
 call nebo_video_pipeline_push
 cmp eax,NEBO_VIDEO_E_TIMESTAMP
 jne .fail21
 cmp qword [rel pipeline+32],1
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
