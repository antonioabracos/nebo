; Canonical public-source owner for bounded image, audio, video and media
; pipelines. Selection is token-only and independent of fixture identity.
%define G19_FAMILY_KEY 0x5246323034473139

section .rodata
%macro G19_NAME 2
g19_n_%1: db %2
g19_n_%1_len equ $-g19_n_%1
%endmacro
G19_NAME color_type,'Color'
G19_NAME pixel_format_type,'PixelFormat'
G19_NAME image_type,'Image'
G19_NAME bmp_type,'Bmp'
G19_NAME png_type,'Png'
G19_NAME codec_type,'codec'
G19_NAME audio_buffer_type,'AudioBuffer'
G19_NAME audio_device_type,'AudioDevice'
G19_NAME video_frame_type,'VideoFrame'
G19_NAME video_stream_type,'VideoStream'
G19_NAME pipeline_type,'pipeline'
G19_NAME rgb,'rgb'
G19_NAME rgba,'rgba'
G19_NAME to_linear,'toLinear'
G19_NAME to_srgb,'toSrgb'
G19_NAME rgba8,'rgba8'
G19_NAME gray8,'gray8'
G19_NAME pack,'pack'
G19_NAME new,'new'
G19_NAME from_buffer,'fromBuffer'
G19_NAME width,'width'
G19_NAME height,'height'
G19_NAME stride,'stride'
G19_NAME pixel,'pixel'
G19_NAME set_pixel,'setPixel'
G19_NAME region,'region'
G19_NAME resize,'resize'
G19_NAME crop,'crop'
G19_NAME flip_horizontal,'flipHorizontal'
G19_NAME flip_vertical,'flipVertical'
G19_NAME rotate90,'rotate90'
G19_NAME convert,'convert'
G19_NAME composite,'composite'
G19_NAME decode,'decode'
G19_NAME encode,'encode'
G19_NAME load,'load'
G19_NAME save,'save'
G19_NAME inspect,'inspect'
G19_NAME channels,'channels'
G19_NAME frame_count,'frameCount'
G19_NAME duration,'duration'
G19_NAME resample,'resample'
G19_NAME mix,'mix'
G19_NAME open,'open'
G19_NAME write,'write'
G19_NAME image,'image'
G19_NAME timestamp,'timestamp'
G19_NAME frames,'frames'
G19_NAME transform,'transform'
G19_NAME progress,'progress'
%undef G19_NAME

section .bss align=16
g19_mode: resq 1
g19_seed: resq 1
g19_seed_seen: resq 1

section .text
%macro G19_REQUIRE 2
 lea rsi,[rel g19_n_%1]
 mov edx,g19_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g19_is_program:
%macro G19_ROOT 1
 lea rsi,[rel g19_n_%1]
 mov edx,g19_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .root
%endmacro
 G19_ROOT color_type
 G19_ROOT pixel_format_type
 G19_ROOT image_type
 G19_ROOT bmp_type
 G19_ROOT png_type
 G19_ROOT audio_buffer_type
 G19_ROOT audio_device_type
 G19_ROOT video_frame_type
 G19_ROOT video_stream_type
 G19_ROOT pipeline_type
 jmp .no
.root:
%macro G19_WITNESS 1
 lea rsi,[rel g19_n_%1]
 mov edx,g19_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G19_WITNESS to_linear
 G19_WITNESS from_buffer
 G19_WITNESS flip_horizontal
 G19_WITNESS inspect
 G19_WITNESS frame_count
 G19_WITNESS timestamp
 G19_WITNESS progress
 jmp .no
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret
%undef G19_WITNESS
%undef G19_ROOT

g19_count_atom:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rsi
 mov r13d,edx
 xor ebx,ebx
 xor r14d,r14d
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 mov rsi,r12
 mov edx,r13d
 call ls_token_match
 add r14d,eax
 inc rbx
 jmp .scan
.done:
 mov eax,r14d
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g19_known_call:
 push rbx
 mov rbx,rdi
%macro G19_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g19_n_%1]
 mov edx,g19_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G19_KNOWN rgb
 G19_KNOWN rgba
 G19_KNOWN to_linear
 G19_KNOWN to_srgb
 G19_KNOWN rgba8
 G19_KNOWN gray8
 G19_KNOWN pack
 G19_KNOWN new
 G19_KNOWN from_buffer
 G19_KNOWN width
 G19_KNOWN height
 G19_KNOWN stride
 G19_KNOWN pixel
 G19_KNOWN set_pixel
 G19_KNOWN region
 G19_KNOWN resize
 G19_KNOWN crop
 G19_KNOWN flip_horizontal
 G19_KNOWN flip_vertical
 G19_KNOWN rotate90
 G19_KNOWN convert
 G19_KNOWN composite
 G19_KNOWN decode
 G19_KNOWN encode
 G19_KNOWN load
 G19_KNOWN save
 G19_KNOWN inspect
 G19_KNOWN channels
 G19_KNOWN frame_count
 G19_KNOWN duration
 G19_KNOWN resample
 G19_KNOWN mix
 G19_KNOWN open
 G19_KNOWN write
 G19_KNOWN image
 G19_KNOWN timestamp
 G19_KNOWN frames
 G19_KNOWN transform
 G19_KNOWN progress
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G19_KNOWN

g19_select_mode:
 G19_REQUIRE video_frame_type,.not_s06
 G19_REQUIRE video_stream_type,.not_s06
 G19_REQUIRE pipeline_type,.not_s06
 G19_REQUIRE new,.not_s06
 G19_REQUIRE image,.not_s06
 G19_REQUIRE timestamp,.not_s06
 G19_REQUIRE frames,.not_s06
 G19_REQUIRE decode,.not_s06
 G19_REQUIRE transform,.not_s06
 G19_REQUIRE encode,.not_s06
 G19_REQUIRE progress,.not_s06
 mov eax,6
 ret
.not_s06:
 G19_REQUIRE audio_buffer_type,.not_s05
 G19_REQUIRE audio_device_type,.not_s05
 G19_REQUIRE new,.not_s05
 G19_REQUIRE channels,.not_s05
 G19_REQUIRE frame_count,.not_s05
 G19_REQUIRE duration,.not_s05
 G19_REQUIRE resample,.not_s05
 G19_REQUIRE mix,.not_s05
 G19_REQUIRE open,.not_s05
 G19_REQUIRE write,.not_s05
 mov eax,5
 ret
.not_s05:
 G19_REQUIRE bmp_type,.not_s04
 G19_REQUIRE png_type,.not_s04
 G19_REQUIRE codec_type,.not_s04
 G19_REQUIRE image_type,.not_s04
 G19_REQUIRE decode,.not_s04
 G19_REQUIRE encode,.not_s04
 G19_REQUIRE load,.not_s04
 G19_REQUIRE save,.not_s04
 G19_REQUIRE inspect,.not_s04
 lea rsi,[rel g19_n_decode]
 mov edx,g19_n_decode_len
 call g19_count_atom
 cmp eax,2
 jb .not_s04
 lea rsi,[rel g19_n_encode]
 mov edx,g19_n_encode_len
 call g19_count_atom
 cmp eax,2
 jb .not_s04
 mov eax,4
 ret
.not_s04:
 G19_REQUIRE image_type,.not_s03
 G19_REQUIRE resize,.not_s03
 G19_REQUIRE crop,.not_s03
 G19_REQUIRE flip_horizontal,.not_s03
 G19_REQUIRE flip_vertical,.not_s03
 G19_REQUIRE rotate90,.not_s03
 G19_REQUIRE convert,.not_s03
 G19_REQUIRE composite,.not_s03
 mov eax,3
 ret
.not_s03:
 G19_REQUIRE image_type,.not_s02
 G19_REQUIRE new,.not_s02
 G19_REQUIRE from_buffer,.not_s02
 G19_REQUIRE width,.not_s02
 G19_REQUIRE height,.not_s02
 G19_REQUIRE stride,.not_s02
 G19_REQUIRE pixel,.not_s02
 G19_REQUIRE set_pixel,.not_s02
 G19_REQUIRE region,.not_s02
 mov eax,2
 ret
.not_s02:
 G19_REQUIRE color_type,.not_s01
 G19_REQUIRE pixel_format_type,.not_s01
 G19_REQUIRE rgb,.not_s01
 G19_REQUIRE rgba,.not_s01
 G19_REQUIRE to_linear,.not_s01
 G19_REQUIRE to_srgb,.not_s01
 G19_REQUIRE rgba8,.not_s01
 G19_REQUIRE gray8,.not_s01
 G19_REQUIRE pack,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g19_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g19_seed_seen],0
 jne .next
 mov qword [rel g19_seed_seen],1
 mov [rel g19_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g19_known_call
 test eax,eax
 jz .unsupported
.next:
 inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g19_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.unsupported:
 mov eax,24
.return:
 pop rbx
 ret

neboc_g019_source_parse:
 mov qword [rel g19_mode],0
 mov qword [rel g19_seed],0
 mov qword [rel g19_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g19_select_mode
 test eax,eax
 jz .syntax
 mov [rel g19_mode],rax
 call g19_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g19_mode]
 shl rax,32
 mov edi,dword [rel g19_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G19_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G19_REQUIRE
