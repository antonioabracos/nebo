; Corrected G019 source-to-effect probe. Each mode reaches concrete bounded
; media owners and returns the source seed only after independent observations.
bits 64
default rel
%define NEBO_G019_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/media/media_source_probe.inc"
%include "runtime/media/color.inc"
%include "runtime/media/media_contract.inc"
%include "runtime/image/image.inc"
%include "runtime/image/image_transform.inc"
%include "runtime/image/bmp.inc"
%include "runtime/image/image_io.inc"
%include "runtime/audio/pcm.inc"
%include "runtime/audio/audio_device.inc"
%include "runtime/video/video_pipeline.inc"

section .rodata
align 4
g19_bmp_fixture:
 db 0x42,0x4d,0x3a,0,0,0,0,0,0,0,0x36,0,0,0
 dd 40,1,1
 dw 1,32
 dd 0,4,0,0,0,0
 db 0x63,0x47,0x2b,0x9d
g19_bmp_fixture_end:

section .bss align=16
g19_image_a: resb 64
g19_image_b: resb 64
g19_image_c: resb 64
g19_image_d: resb 64
g19_pixels_a: resb 128
g19_pixels_b: resb 128
g19_pixels_c: resb 128
g19_pixels_d: resb 128
g19_bmp: resb 80
g19_png: resb 80
g19_encoded_len: resq 1
g19_meta: resb 32
g19_pcm_a: resb 64
g19_pcm_b: resb 64
g19_pcm_c: resb 64
g19_samples_a: resw 32
g19_samples_b: resw 32
g19_samples_c: resw 32
g19_device: resb 64
g19_frame_a: resb 40
g19_frame_b: resb 40
g19_video: resb 96
g19_video_slots: resb 80
g19_stage: resb 64

section .text
global nebo_g019_source_probe
global nebo_g019_negative_probe

g19_mode_1:
 mov edi,17
 mov esi,34
 mov edx,51
 call nebo_color_rgb_media_native_vertical
 test eax,eax
 jnz .fail
 cmp edx,0xff332211
 jne .fail
 mov edi,19
 mov esi,37
 mov edx,73
 mov ecx,149
 call nebo_color_rgba_media_native_vertical
 test eax,eax
 jnz .fail
 mov r10d,edx
 mov edi,128
 call nebo_color_to_linear_u8
 test eax,eax
 jnz .fail
 mov edi,edx
 call nebo_color_to_srgb_q16
 test eax,eax
 jnz .fail
 cmp edx,128
 jne .fail
 call nebo_pixel_format_rgba8
 cmp rax,NEBO_PIXEL_FORMAT_RGBA8_VALUE
 jne .fail
 call nebo_pixel_format_gray8
 cmp rax,NEBO_PIXEL_FORMAT_GRAY8_VALUE
 jne .fail
 mov edi,r10d
 mov esi,NEBO_PIXEL_RGBA8
 call nebo_pixel_pack
 test eax,eax
 jnz .fail
 cmp edx,r10d
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,1
 ret

g19_mode_2:
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_pixels_a]
 mov edx,16
 mov ecx,2
 mov r8d,2
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_image_b]
 lea rsi,[rel g19_pixels_b]
 mov edx,16
 mov ecx,2
 mov r8d,2
 mov r9,NEBO_PIXEL_RGBA8
 shl r9,32
 or r9,8
 call nebo_image_wrap_mut
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_image_a]
 call nebo_image_width
 test eax,eax
 jnz .fail
 cmp edx,2
 jne .fail
 lea rdi,[rel g19_image_a]
 call nebo_image_height
 test eax,eax
 jnz .fail
 cmp edx,2
 jne .fail
 lea rdi,[rel g19_image_a]
 call nebo_image_stride
 test eax,eax
 jnz .fail
 cmp edx,8
 jne .fail
 lea rdi,[rel g19_image_a]
 mov esi,1
 xor edx,edx
 mov ecx,0xff795331
 call nebo_image_set_pixel
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_image_a]
 mov esi,1
 xor edx,edx
 call nebo_image_pixel
 test eax,eax
 jnz .fail
 cmp edx,0xff795331
 jne .fail
 lea rdi,[rel g19_image_c]
 lea rsi,[rel g19_image_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,1
 mov r9d,1
 call nebo_image_region
 test eax,eax
 jnz .fail
 cmp dword [rel g19_image_c+16],1
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,2
 ret

g19_init_transform_images:
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_pixels_a]
 mov edx,16
 mov ecx,2
 mov r8d,2
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 test eax,eax
 jnz .done
 mov dword [rel g19_pixels_a],0xff000011
 mov dword [rel g19_pixels_a+4],0xff000022
 mov dword [rel g19_pixels_a+8],0xff000033
 mov dword [rel g19_pixels_a+12],0xff000044
.done:
 ret

g19_init_b_rgba_2x2:
 lea rdi,[rel g19_image_b]
 lea rsi,[rel g19_pixels_b]
 mov edx,16
 mov ecx,2
 mov r8d,2
 mov r9d,NEBO_PIXEL_RGBA8
 jmp nebo_image_init

g19_mode_3:
 call g19_init_transform_images
 test eax,eax
 jnz .fail
 ; resize
 lea rdi,[rel g19_image_b]
 lea rsi,[rel g19_pixels_b]
 mov edx,4
 mov ecx,1
 mov r8d,1
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_image_b]
 mov edx,NEBO_IMAGE_FILTER_NEAREST
 call nebo_image_resize_into
 test eax,eax
 jnz .fail
 ; crop
 lea rdi,[rel g19_image_b]
 lea rsi,[rel g19_pixels_b]
 mov edx,4
 mov ecx,1
 mov r8d,1
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_image_b]
 mov edx,1
 mov ecx,1
 call nebo_image_crop_into
 test eax,eax
 jnz .fail
 cmp dword [rel g19_pixels_b],0xff000044
 jne .fail
 ; horizontal, vertical and three quarter-turn variants share exact owners.
 call g19_init_b_rgba_2x2
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_image_b]
 call nebo_image_flip_horizontal_into
 test eax,eax
 jnz .fail
 call g19_init_b_rgba_2x2
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_image_b]
 call nebo_image_flip_vertical_into
 test eax,eax
 jnz .fail
 call g19_init_b_rgba_2x2
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_image_b]
 mov edx,1
 call nebo_image_rotate90_into
 test eax,eax
 jnz .fail
 ; explicit RGBA8 to GRAY8 conversion.
 lea rdi,[rel g19_image_c]
 lea rsi,[rel g19_pixels_c]
 mov edx,4
 mov ecx,2
 mov r8d,2
 mov r9d,NEBO_PIXEL_GRAY8
 call nebo_image_init
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_image_c]
 call nebo_image_convert_into
 test eax,eax
 jnz .fail
 ; straight-alpha source-over composition.
 call g19_init_b_rgba_2x2
 lea rdi,[rel g19_image_b]
 lea rsi,[rel g19_image_a]
 xor edx,edx
 xor ecx,ecx
 call nebo_image_composite_over
 test eax,eax
 jnz .fail
 xor eax,eax
 ret
.fail: mov eax,3
 ret

g19_mode_4:
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_pixels_a]
 mov edx,4
 mov ecx,1
 mov r8d,1
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 test eax,eax
 jnz .fail
 mov dword [rel g19_pixels_a],0x9d63472b
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_bmp]
 mov edx,58
 lea rcx,[rel g19_encoded_len]
 call nebo_bmp_encode
 test eax,eax
 jnz .fail
 cmp qword [rel g19_encoded_len],58
 jne .fail
 ; Decode an independent canonical BMP fixture so the source probe proves
 ; both codec directions without using an encoder result as its own oracle.
 lea rdi,[rel g19_bmp_fixture]
 mov esi,g19_bmp_fixture_end-g19_bmp_fixture
 lea rdx,[rel g19_meta]
 call nebo_bmp_inspect
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_bmp_fixture]
 mov esi,g19_bmp_fixture_end-g19_bmp_fixture
 lea rdx,[rel g19_image_b]
 lea rcx,[rel g19_pixels_b]
 mov r8d,4
 call nebo_bmp_decode
 test eax,eax
 jnz .fail
 cmp dword [rel g19_pixels_b],0x9d63472b
 jne .fail
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_png]
 mov edx,NEBO_PNG_BYTES_1X1_RGBA8
 lea rcx,[rel g19_encoded_len]
 call nebo_png_encode
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_png]
 mov esi,NEBO_PNG_BYTES_1X1_RGBA8
 lea rdx,[rel g19_meta]
 call nebo_png_inspect
 test eax,eax
 jnz .fail
 cmp dword [rel g19_meta+12],NEBO_MEDIA_CODEC_PNG
 jne .fail
 lea rdi,[rel g19_png]
 mov esi,NEBO_PNG_BYTES_1X1_RGBA8
 lea rdx,[rel g19_image_c]
 lea rcx,[rel g19_pixels_c]
 mov r8d,4
 call nebo_png_decode
 test eax,eax
 jnz .fail
 cmp dword [rel g19_pixels_c],0x9d63472b
 jne .fail
 lea rdi,[rel g19_png]
 mov esi,NEBO_PNG_BYTES_1X1_RGBA8
 lea rdx,[rel g19_meta]
 call nebo_codec_inspect
 test eax,eax
 jnz .fail
 ; Image.load/save are real File-capability adapters. Their null-request path
 ; is exercised here for stable failure atomicity; focused native tests prove
 ; positive scratch-file round trips.
 xor edi,edi
 call nebo_image_load
 cmp eax,NEBO_MEDIA_E_ARGUMENT
 jne .fail
 xor edi,edi
 call nebo_image_save
 cmp eax,NEBO_MEDIA_E_ARGUMENT
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,4
 ret

g19_mode_5:
 lea rdi,[rel g19_pcm_a]
 lea rsi,[rel g19_samples_a]
 mov edx,8
 mov ecx,4
 mov r8d,8000
 mov r9d,1
 call nebo_pcm_init
 test eax,eax
 jnz .fail
 mov word [rel g19_samples_a],-12000
 mov word [rel g19_samples_a+2],-3000
 mov word [rel g19_samples_a+4],4000
 mov word [rel g19_samples_a+6],15000
 lea rdi,[rel g19_pcm_a]
 call nebo_audio_channels
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 lea rdi,[rel g19_pcm_a]
 call nebo_audio_frame_count
 test eax,eax
 jnz .fail
 cmp edx,4
 jne .fail
 lea rdi,[rel g19_pcm_a]
 call nebo_pcm_duration_us
 test eax,eax
 jnz .fail
 cmp edx,500
 jne .fail
 lea rdi,[rel g19_pcm_b]
 lea rsi,[rel g19_samples_b]
 mov edx,16
 mov ecx,8
 mov r8d,16000
 mov r9d,1
 call nebo_pcm_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_pcm_b]
 lea rsi,[rel g19_pcm_a]
 call nebo_pcm_resample_linear_into
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_pcm_c]
 lea rsi,[rel g19_samples_c]
 mov edx,16
 mov ecx,8
 mov r8d,16000
 mov r9d,1
 call nebo_pcm_init
 test eax,eax
 jnz .fail
 mov word [rel g19_samples_c],2000
 lea rdi,[rel g19_pcm_b]
 lea rsi,[rel g19_pcm_c]
 mov edx,16384
 call nebo_pcm_mix_into
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_device]
 mov esi,8
 call nebo_media_audio_device_open
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_device]
 lea rsi,[rel g19_pcm_b]
 call nebo_media_audio_device_write
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_device]
 lea rsi,[rel g19_pcm_b]
 call nebo_media_audio_device_write
 cmp eax,NEBO_MEDIA_AUDIO_E_BACKPRESSURE
 jne .fail
 lea rdi,[rel g19_device]
 call nebo_media_audio_device_progress
 test eax,eax
 jnz .fail
 cmp edx,8
 jne .fail
 lea rdi,[rel g19_device]
 call nebo_media_audio_device_close
 test eax,eax
 jnz .fail
 ; A real host device remains truthfully target-gated.
 xor edi,edi
 call nebo_audio_device_open
 cmp eax,NEBO_AUDIO_DEVICE_E_UNSUPPORTED_BACKEND
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,5
 ret

g19_mode_6:
 lea rdi,[rel g19_image_a]
 lea rsi,[rel g19_pixels_a]
 mov edx,4
 mov ecx,1
 mov r8d,1
 mov r9d,NEBO_PIXEL_RGBA8
 call nebo_image_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_frame_a]
 lea rsi,[rel g19_image_a]
 mov edx,1900
 mov ecx,40
 call nebo_video_frame_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_frame_a]
 call nebo_video_frame_image
 test eax,eax
 jnz .fail
 lea rax,[rel g19_image_a]
 cmp rdx,rax
 jne .fail
 lea rdi,[rel g19_frame_a]
 call nebo_video_frame_timestamp
 test eax,eax
 jnz .fail
 cmp edx,1900
 jne .fail
 lea rdi,[rel g19_video]
 lea rsi,[rel g19_video_slots]
 mov edx,2
 call nebo_video_pipeline_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_video]
 lea rsi,[rel g19_frame_a]
 call nebo_video_pipeline_push
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_video]
 call nebo_video_stream_frames
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 lea rdi,[rel g19_video]
 lea rsi,[rel g19_frame_b]
 call nebo_video_pipeline_pop
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_stage]
 mov esi,1
 call nebo_media_pipeline_decode
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_stage]
 mov esi,7
 call nebo_media_pipeline_transform
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_stage]
 mov esi,11
 mov edx,NEBO_MEDIA_CODEC_PNG
 call nebo_media_pipeline_encode
 test eax,eax
 jnz .fail
 lea rdi,[rel g19_stage]
 call nebo_media_pipeline_progress
 test eax,eax
 jnz .fail
 cmp edx,100
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,6
 ret

nebo_g019_source_probe:
 push rbx
 mov ebx,esi
 cmp edi,1
 je .s01
 cmp edi,2
 je .s02
 cmp edi,3
 je .s03
 cmp edi,4
 je .s04
 cmp edi,5
 je .s05
 cmp edi,6
 je .s06
 mov eax,19
 jmp .done
.s01: call g19_mode_1
 jmp .observed
.s02: call g19_mode_2
 jmp .observed
.s03: call g19_mode_3
 jmp .observed
.s04: call g19_mode_4
 jmp .observed
.s05: call g19_mode_5
 jmp .observed
.s06: call g19_mode_6
.observed:
 test eax,eax
 jnz .done
 mov eax,ebx
.done:
 pop rbx
 ret

nebo_g019_negative_probe:
 mov edi,256
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call nebo_color_rgba_media_native_vertical
 cmp eax,NEBO_MEDIA_E_ARGUMENT
 jne .fail
 mov rax,0x5a5a5a5a5a5a5a5a
 mov qword [rel g19_meta],rax
 lea rdi,[rel g19_png]
 mov esi,72
 lea rdx,[rel g19_meta]
 call nebo_png_inspect
 cmp eax,NEBO_BMP_E_TRUNCATED
 jne .fail
 mov rax,0x5a5a5a5a5a5a5a5a
 cmp qword [rel g19_meta],rax
 jne .fail
 lea rdi,[rel g19_stage]
 mov esi,1
 call nebo_media_pipeline_transform
 cmp eax,NEBO_VIDEO_E_STATE
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,1
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
