; Bounded deterministic adapters for the corrected public media contract.
; PNG is a real 1x1 RGBA8, filter-0, zlib stored-block profile: no external
; codec, allocation, hidden copy, device, network or user-data dependency.
bits 64
default rel
%define NEBO_MEDIA_CONTRACT_IMPLEMENTATION 1
%include "runtime/media/media_contract.inc"
%include "runtime/image/image.inc"
%include "runtime/image/bmp.inc"
%include "runtime/audio/pcm.inc"
%include "runtime/video/video_pipeline.inc"

section .rodata
png_signature: db 0x89,'PNG',13,10,26,10
png_ihdr: db 'IHDR'
png_idat: db 'IDAT'
png_iend: db 'IEND'

section .text
global nebo_png_inspect
global nebo_png_decode
global nebo_png_encode
global nebo_codec_inspect
global nebo_audio_channels
global nebo_audio_frame_count
global nebo_media_audio_device_open
global nebo_media_audio_device_write
global nebo_media_audio_device_progress
global nebo_media_audio_device_close
global nebo_video_frame_image
global nebo_video_frame_timestamp
global nebo_video_stream_frames
global nebo_media_pipeline_decode
global nebo_media_pipeline_transform
global nebo_media_pipeline_encode
global nebo_media_pipeline_progress

; rdi=bytes rsi=len -> eax=crc32
media_crc32:
 mov eax,0xffffffff
 xor r8d,r8d
.byte:
 cmp r8,rsi
 jae .done
 movzx ecx,byte [rdi+r8]
 xor eax,ecx
 mov ecx,8
.bit:
 mov edx,eax
 and edx,1
 neg edx
 shr eax,1
 and edx,0xedb88320
 xor eax,edx
 dec ecx
 jnz .bit
 inc r8
 jmp .byte
.done:
 not eax
 ret

; eax=host u32 -> eax=big endian
media_be32:
 bswap eax
 ret

; rdi=5 raw bytes -> eax=Adler32 host order
media_adler5:
 mov eax,1
 xor edx,edx
 xor ecx,ecx
.loop:
 cmp ecx,5
 jae .done
 movzx r8d,byte [rdi+rcx]
 add eax,r8d
 cmp eax,65521
 jb .s2
 sub eax,65521
.s2:
 add edx,eax
 cmp edx,65521
 jb .next
 sub edx,65521
.next:
 inc ecx
 jmp .loop
.done:
 shl edx,16
 or eax,edx
 ret

; rdi=bytes rsi=len rdx=meta[32]
; meta: width:u32 height:u32 format:u32 codec:u32 payload:u64 total:u64
nebo_png_inspect:
 test rdi,rdi
 jz .argument
 test rdx,rdx
 jz .argument
 cmp rsi,NEBO_PNG_BYTES_1X1_RGBA8
 jne .truncated
 lea r8,[rel png_signature]
 xor ecx,ecx
.sig:
 cmp ecx,8
 jae .layout
 mov al,[rdi+rcx]
 cmp al,[r8+rcx]
 jne .magic
 inc ecx
 jmp .sig
.layout:
 cmp dword [rdi+8],0x0d000000
 jne .unsupported
 cmp dword [rdi+12],0x52444849
 jne .unsupported
 cmp dword [rdi+16],0x01000000
 jne .limit
 cmp dword [rdi+20],0x01000000
 jne .limit
 cmp byte [rdi+24],8
 jne .unsupported
 cmp byte [rdi+25],6
 jne .unsupported
 cmp byte [rdi+26],0
 jne .unsupported
 cmp byte [rdi+27],0
 jne .unsupported
 cmp byte [rdi+28],0
 jne .unsupported
 cmp dword [rdi+33],0x10000000
 jne .unsupported
 cmp dword [rdi+37],0x54414449
 jne .unsupported
 cmp byte [rdi+41],0x78
 jne .unsupported
 cmp byte [rdi+42],0x01
 jne .unsupported
 cmp byte [rdi+43],0x01
 jne .unsupported
 cmp word [rdi+44],0x0005
 jne .unsupported
 cmp word [rdi+46],0xfffa
 jne .unsupported
 cmp byte [rdi+48],0
 jne .unsupported
 mov rax,0x444e454900000000
 cmp qword [rdi+61],rax
 jne .unsupported
 cmp dword [rdi+69],0x826042ae
 jne .unsupported
 ; Validate all CRCs before publishing metadata.
 push rdi
 push rsi
 push rdx
 lea rdi,[rdi+12]
 mov esi,17
 call media_crc32
 pop rdx
 pop rsi
 pop rdi
 bswap eax
 cmp eax,[rdi+29]
 jne .header
 push rdi
 push rsi
 push rdx
 lea rdi,[rdi+37]
 mov esi,20
 call media_crc32
 pop rdx
 pop rsi
 pop rdi
 bswap eax
 cmp eax,[rdi+57]
 jne .header
 push rdi
 push rsi
 push rdx
 lea rdi,[rdi+48]
 call media_adler5
 pop rdx
 pop rsi
 pop rdi
 bswap eax
 cmp eax,[rdi+53]
 jne .header
 mov dword [rdx],1
 mov dword [rdx+4],1
 mov dword [rdx+8],NEBO_PIXEL_RGBA8
 mov dword [rdx+12],NEBO_MEDIA_CODEC_PNG
 mov qword [rdx+16],4
 mov qword [rdx+24],NEBO_PNG_BYTES_1X1_RGBA8
 xor eax,eax
 ret
.argument: mov eax,NEBO_MEDIA_E_ARGUMENT
 ret
.magic: mov eax,NEBO_BMP_E_MAGIC
 ret
.header: mov eax,NEBO_BMP_E_HEADER
 ret
.truncated: mov eax,NEBO_BMP_E_TRUNCATED
 ret
.unsupported: mov eax,NEBO_BMP_E_UNSUPPORTED
 ret
.limit: mov eax,NEBO_MEDIA_E_LIMIT
 ret

; rdi=bytes rsi=len rdx=out Image rcx=out pixels r8=capacity
nebo_png_decode:
 push r12
 push r13
 push r14
 sub rsp,40
 mov r12,rdx
 mov r13,rcx
 mov r14,r8
 test r12,r12
 jz .argument
 test r13,r13
 jz .argument
 lea rdx,[rsp]
 call nebo_png_inspect
 test eax,eax
 jnz .done
 cmp r14,4
 jb .capacity
 mov eax,[rdi+49]
 mov [r13],eax
 mov [r12],r13
 mov qword [r12+8],4
 mov dword [r12+16],1
 mov dword [r12+20],1
 mov dword [r12+24],4
 mov word [r12+28],NEBO_PIXEL_RGBA8
 mov word [r12+30],NEBO_IMAGE_FLAG_OWNED|NEBO_IMAGE_FLAG_MUTABLE
 mov qword [r12+32],1
 mov qword [r12+40],0
 mov qword [r12+48],0
 mov qword [r12+56],0
 xor eax,eax
 jmp .done
.argument: mov eax,NEBO_MEDIA_E_ARGUMENT
 jmp .done
.capacity: mov eax,NEBO_BMP_E_CAPACITY
.done:
 add rsp,40
 pop r14
 pop r13
 pop r12
 ret

; rdi=Image rsi=out bytes rdx=capacity rcx=out length
nebo_png_encode:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rcx
 test r12,r12
 jz .argument
 test r13,r13
 jz .argument
 test r14,r14
 jz .argument
 cmp rdx,NEBO_PNG_BYTES_1X1_RGBA8
 jb .capacity
 cmp qword [r12],0
 je .stale
 test word [r12+30],NEBO_IMAGE_FLAG_CLOSED
 jnz .stale
 cmp dword [r12+16],1
 jne .limit
 cmp dword [r12+20],1
 jne .limit
 cmp dword [r12+24],4
 jb .format
 cmp word [r12+28],NEBO_PIXEL_RGBA8
 jne .format
 mov r15,[r12]
 lea rdi,[r13]
 xor eax,eax
 mov ecx,NEBO_PNG_BYTES_1X1_RGBA8
 rep stosb
 lea rsi,[rel png_signature]
 lea rdi,[r13]
 mov ecx,8
 rep movsb
 mov dword [r13+8],0x0d000000
 mov dword [r13+12],0x52444849
 mov dword [r13+16],0x01000000
 mov dword [r13+20],0x01000000
 mov byte [r13+24],8
 mov byte [r13+25],6
 lea rdi,[r13+12]
 mov esi,17
 call media_crc32
 bswap eax
 mov [r13+29],eax
 mov dword [r13+33],0x10000000
 mov dword [r13+37],0x54414449
 mov word [r13+41],0x0178
 mov byte [r13+43],1
 mov word [r13+44],0x0005
 mov word [r13+46],0xfffa
 mov byte [r13+48],0
 mov eax,[r15]
 mov [r13+49],eax
 lea rdi,[r13+48]
 call media_adler5
 bswap eax
 mov [r13+53],eax
 lea rdi,[r13+37]
 mov esi,20
 call media_crc32
 bswap eax
 mov [r13+57],eax
 mov rax,0x444e454900000000
 mov qword [r13+61],rax
 mov dword [r13+69],0x826042ae
 mov qword [r14],NEBO_PNG_BYTES_1X1_RGBA8
 xor eax,eax
 jmp .done
.argument: mov eax,NEBO_MEDIA_E_ARGUMENT
 jmp .done
.capacity: mov eax,NEBO_BMP_E_CAPACITY
 jmp .done
.stale: mov eax,NEBO_MEDIA_E_STALE
 jmp .done
.format: mov eax,NEBO_MEDIA_E_FORMAT
 jmp .done
.limit: mov eax,NEBO_MEDIA_E_LIMIT
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=bytes rsi=len rdx=meta. Dispatch is explicit and bounded.
nebo_codec_inspect:
 test rdi,rdi
 jz .argument
 test rdx,rdx
 jz .argument
 cmp rsi,2
 jb .truncated
 cmp word [rdi],0x4d42
 je nebo_bmp_inspect
 cmp rsi,8
 jb .truncated
 cmp dword [rdi],0x474e5089
 jne .unsupported
 jmp nebo_png_inspect
.argument: mov eax,NEBO_MEDIA_E_ARGUMENT
 ret
.truncated: mov eax,NEBO_BMP_E_TRUNCATED
 ret
.unsupported: mov eax,NEBO_BMP_E_UNSUPPORTED
 ret

nebo_audio_channels:
 test rdi,rdi
 jz media_audio_argument
 cmp qword [rdi],0
 je media_audio_stale
 movzx edx,word [rdi+24]
 xor eax,eax
 ret
nebo_audio_frame_count:
 test rdi,rdi
 jz media_audio_argument
 cmp qword [rdi],0
 je media_audio_stale
 mov edx,[rdi+16]
 xor eax,eax
 ret
media_audio_argument: mov eax,NEBO_PCM_E_ARGUMENT
 ret
media_audio_stale: mov eax,NEBO_PCM_E_STALE
 ret

; Offline sink: rdi=device[64], rsi=capacity frames.
nebo_media_audio_device_open:
 test rdi,rdi
 jz media_adev_arg
 test rsi,rsi
 jz media_adev_arg
 cmp rsi,4096
 ja media_adev_arg
 mov r8,rdi
 xor eax,eax
 mov ecx,8
 rep stosq
 mov qword [r8],NEBO_MEDIA_AUDIO_DEVICE_OPEN
 mov [r8+8],rsi
 xor eax,eax
 ret
nebo_media_audio_device_write:
 test rdi,rdi
 jz media_adev_arg
 test rsi,rsi
 jz media_adev_arg
 cmp qword [rdi],NEBO_MEDIA_AUDIO_DEVICE_OPEN
 jne media_adev_state
 mov eax,[rsi+16]
 test eax,eax
 jz media_adev_arg
 mov rdx,[rdi+16]
 add rdx,rax
 cmp rdx,[rdi+8]
 ja media_adev_backpressure
 mov [rdi+16],rdx
 inc qword [rdi+24]
 xor eax,eax
 ret
nebo_media_audio_device_progress:
 test rdi,rdi
 jz media_adev_arg
 cmp qword [rdi],NEBO_MEDIA_AUDIO_DEVICE_OPEN
 jne media_adev_state
 mov rdx,[rdi+16]
 add [rdi+32],rdx
 mov qword [rdi+16],0
 xor eax,eax
 ret
nebo_media_audio_device_close:
 test rdi,rdi
 jz media_adev_arg
 cmp qword [rdi],NEBO_MEDIA_AUDIO_DEVICE_OPEN
 jne media_adev_state
 mov qword [rdi],NEBO_MEDIA_AUDIO_DEVICE_CLOSED
 mov qword [rdi+16],0
 xor eax,eax
 ret
media_adev_arg: mov eax,NEBO_PCM_E_ARGUMENT
 ret
media_adev_state: mov eax,NEBO_PCM_E_STALE
 ret
media_adev_backpressure: mov eax,NEBO_MEDIA_AUDIO_E_BACKPRESSURE
 ret

nebo_video_frame_image:
 test rdi,rdi
 jz media_video_argument
 test dword [rdi+32],NEBO_VIDEO_FRAME_FLAG_VALID
 jz media_video_argument
 mov rdx,[rdi]
 xor eax,eax
 ret
nebo_video_frame_timestamp:
 test rdi,rdi
 jz media_video_argument
 test dword [rdi+32],NEBO_VIDEO_FRAME_FLAG_VALID
 jz media_video_argument
 mov rdx,[rdi+8]
 xor eax,eax
 ret
nebo_video_stream_frames:
 test rdi,rdi
 jz media_video_argument
 cmp qword [rdi],0
 je media_video_argument
 mov rdx,[rdi+32]
 xor eax,eax
 ret
media_video_argument: mov eax,NEBO_VIDEO_E_ARGUMENT
 ret

; Bounded source-transform-sink state: rdi=contract[64].
nebo_media_pipeline_decode:
 test rdi,rdi
 jz media_pipeline_argument
 test rsi,rsi
 jz media_pipeline_argument
 mov r8,rdi
 xor eax,eax
 mov ecx,8
 rep stosq
 mov qword [r8],NEBO_MEDIA_PIPELINE_DECODING
 mov qword [r8+8],25
 mov [r8+16],rsi
 xor eax,eax
 ret
nebo_media_pipeline_transform:
 test rdi,rdi
 jz media_pipeline_argument
 test rsi,rsi
 jz media_pipeline_argument
 cmp qword [rdi],NEBO_MEDIA_PIPELINE_DECODING
 jne media_pipeline_state
 mov qword [rdi+8],60
 mov [rdi+24],rsi
 xor eax,eax
 ret
nebo_media_pipeline_encode:
 test rdi,rdi
 jz media_pipeline_argument
 test rsi,rsi
 jz media_pipeline_argument
 test rdx,rdx
 jz media_pipeline_argument
 cmp qword [rdi],NEBO_MEDIA_PIPELINE_DECODING
 jne media_pipeline_state
 cmp qword [rdi+8],60
 jne media_pipeline_state
 mov qword [rdi],NEBO_MEDIA_PIPELINE_ENCODED
 mov qword [rdi+8],100
 mov [rdi+32],rsi
 mov [rdi+40],rdx
 xor eax,eax
 ret
nebo_media_pipeline_progress:
 test rdi,rdi
 jz media_pipeline_argument
 mov rdx,[rdi+8]
 cmp rdx,100
 ja media_pipeline_state
 xor eax,eax
 ret
media_pipeline_argument: mov eax,NEBO_VIDEO_E_ARGUMENT
 ret
media_pipeline_state: mov eax,NEBO_VIDEO_E_STATE
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
