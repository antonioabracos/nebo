bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/media_descriptor.inc"
extern neboc_media_descriptor_validate
extern neboc_host_process_exit

section .bss align=16
descriptor: resb NEBOC_MEDIA_SIZE

section .text
reset_valid:
 lea rdi,[rel descriptor]
 mov ecx,NEBOC_MEDIA_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel descriptor+NEBOC_MEDIA_WIDTH_OFFSET],640
 mov qword [rel descriptor+NEBOC_MEDIA_HEIGHT_OFFSET],480
 mov qword [rel descriptor+NEBOC_MEDIA_SAMPLE_RATE_OFFSET],48000
 mov qword [rel descriptor+NEBOC_MEDIA_CHANNELS_OFFSET],2
 mov qword [rel descriptor+NEBOC_MEDIA_DURATION_MS_OFFSET],1000
 mov qword [rel descriptor+NEBOC_MEDIA_DECLARED_BYTES_OFFSET],4096
 mov qword [rel descriptor+NEBOC_MEDIA_AVAILABLE_BYTES_OFFSET],4096
 mov qword [rel descriptor+NEBOC_MEDIA_PRIVACY_FLAGS_OFFSET],NEBOC_MEDIA_REQUIRED_PRIVACY_FLAGS
 mov qword [rel descriptor+NEBOC_MEDIA_CAPABILITY_FLAGS_OFFSET],NEBOC_MEDIA_NO_CAPABILITIES
 mov rax,NEBOC_MEDIA_SEAL_MAGIC
 xor rax,[rel descriptor+NEBOC_MEDIA_WIDTH_OFFSET]
 xor rax,[rel descriptor+NEBOC_MEDIA_HEIGHT_OFFSET]
 xor rax,[rel descriptor+NEBOC_MEDIA_SAMPLE_RATE_OFFSET]
 xor rax,[rel descriptor+NEBOC_MEDIA_CHANNELS_OFFSET]
 xor rax,[rel descriptor+NEBOC_MEDIA_DURATION_MS_OFFSET]
 xor rax,[rel descriptor+NEBOC_MEDIA_DECLARED_BYTES_OFFSET]
 xor rax,[rel descriptor+NEBOC_MEDIA_AVAILABLE_BYTES_OFFSET]
 xor rax,[rel descriptor+NEBOC_MEDIA_PRIVACY_FLAGS_OFFSET]
 xor rax,[rel descriptor+NEBOC_MEDIA_CAPABILITY_FLAGS_OFFSET]
 mov [rel descriptor+NEBOC_MEDIA_SEAL_OFFSET],rax
 ret

expect_ok:
 lea rdi,[rel descriptor]
 call neboc_media_descriptor_validate
 test eax,eax
 jnz fail
 ret

expect_failure:
 ; rsi = expected diagnostic
 lea rdi,[rel descriptor]
 call neboc_media_descriptor_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp [rel descriptor+NEBOC_MEDIA_DIAGNOSTIC_OFFSET],rsi
 jne fail
 cmp qword [rel descriptor+NEBOC_MEDIA_RESULT_OFFSET],0
 jne fail
 ret

%macro DOMAIN_NEGATIVE 3
 call reset_valid
 mov qword [rel descriptor+%1],%2
 mov esi,%3
 call expect_failure
%endmacro

global _start
_start:
 mov r15d,1
 xor edi,edi
 call neboc_media_descriptor_validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 mov r15d,2
 lea rdi,[rel descriptor+1]
 call neboc_media_descriptor_validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 mov r15d,3
 call reset_valid
 call expect_ok
 cmp qword [rel descriptor+NEBOC_MEDIA_RESULT_OFFSET],307200
 jne fail

 mov r15d,4
 call reset_valid
 mov qword [rel descriptor+NEBOC_MEDIA_WIDTH_OFFSET],1
 mov qword [rel descriptor+NEBOC_MEDIA_HEIGHT_OFFSET],1
 mov qword [rel descriptor+NEBOC_MEDIA_SAMPLE_RATE_OFFSET],8000
 mov qword [rel descriptor+NEBOC_MEDIA_CHANNELS_OFFSET],1
 mov qword [rel descriptor+NEBOC_MEDIA_DURATION_MS_OFFSET],1
 mov qword [rel descriptor+NEBOC_MEDIA_DECLARED_BYTES_OFFSET],0
 mov qword [rel descriptor+NEBOC_MEDIA_AVAILABLE_BYTES_OFFSET],0
 mov rax,NEBOC_MEDIA_SEAL_MAGIC
 xor rax,1
 xor rax,1
 xor rax,8000
 xor rax,1
 xor rax,1
 xor rax,NEBOC_MEDIA_REQUIRED_PRIVACY_FLAGS
 mov [rel descriptor+NEBOC_MEDIA_SEAL_OFFSET],rax
 call expect_ok

 mov r15d,10
 DOMAIN_NEGATIVE NEBOC_MEDIA_WIDTH_OFFSET,0,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_WIDTH_OFFSET,8193,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_HEIGHT_OFFSET,0,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_SAMPLE_RATE_OFFSET,7999,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_SAMPLE_RATE_OFFSET,192001,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_CHANNELS_OFFSET,0,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_CHANNELS_OFFSET,9,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_DURATION_MS_OFFSET,0,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_DURATION_MS_OFFSET,600001,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_DECLARED_BYTES_OFFSET,16777217,neboc_media_imagem_audio_e_video_DIAG_RUNTIME_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_AVAILABLE_BYTES_OFFSET,4095,neboc_media_imagem_audio_e_video_DIAG_RUNTIME_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_AVAILABLE_BYTES_OFFSET,4097,neboc_media_imagem_audio_e_video_DIAG_PARSE_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_PRIVACY_FLAGS_OFFSET,2,neboc_media_imagem_audio_e_video_DIAG_SECURITY_stdlib
 inc r15d
 DOMAIN_NEGATIVE NEBOC_MEDIA_CAPABILITY_FLAGS_OFFSET,1,neboc_media_imagem_audio_e_video_DIAG_SECURITY_stdlib
 inc r15d
 call reset_valid
 inc qword [rel descriptor+NEBOC_MEDIA_SEAL_OFFSET]
 mov esi,neboc_media_imagem_audio_e_video_DIAG_SECURITY_stdlib
 call expect_failure

 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r15d
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
