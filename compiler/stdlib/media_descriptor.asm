; MEDIA-IMAGEM-AUDIO-E-VIDEO-PF001..PF005 bounded synthetic-media metadata validator.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/media_descriptor.inc"

section .text
NEBOC_ABI_FUNCTION neboc_media_descriptor_validate
 test rdi,rdi
 jz .invalid_argument
 test rdi,7
 jnz .invalid_argument
 mov qword [rdi+NEBOC_MEDIA_DIAGNOSTIC_OFFSET],0
 mov qword [rdi+NEBOC_MEDIA_RESULT_OFFSET],0

 mov rax,[rdi+NEBOC_MEDIA_WIDTH_OFFSET]
 test rax,rax
 jz .type
 cmp rax,NEBOC_MEDIA_MAX_DIMENSION
 ja .type
 mov rdx,[rdi+NEBOC_MEDIA_HEIGHT_OFFSET]
 test rdx,rdx
 jz .type
 cmp rdx,NEBOC_MEDIA_MAX_DIMENSION
 ja .type
 imul rax,rdx
 jo .type
 mov r10,rax

 mov rax,[rdi+NEBOC_MEDIA_SAMPLE_RATE_OFFSET]
 cmp rax,NEBOC_MEDIA_MIN_SAMPLE_RATE
 jb .type
 cmp rax,NEBOC_MEDIA_MAX_SAMPLE_RATE
 ja .type
 mov rax,[rdi+NEBOC_MEDIA_CHANNELS_OFFSET]
 test rax,rax
 jz .type
 cmp rax,NEBOC_MEDIA_MAX_CHANNELS
 ja .type
 mov rax,[rdi+NEBOC_MEDIA_DURATION_MS_OFFSET]
 test rax,rax
 jz .type
 cmp rax,NEBOC_MEDIA_MAX_DURATION_MS
 ja .type

 mov rax,[rdi+NEBOC_MEDIA_DECLARED_BYTES_OFFSET]
 cmp rax,NEBOC_MEDIA_MAX_DECLARED_BYTES
 ja .resource
 mov rdx,[rdi+NEBOC_MEDIA_AVAILABLE_BYTES_OFFSET]
 cmp rdx,rax
 jb .truncated
 ja .malformed

 cmp qword [rdi+NEBOC_MEDIA_PRIVACY_FLAGS_OFFSET],NEBOC_MEDIA_REQUIRED_PRIVACY_FLAGS
 jne .security
 cmp qword [rdi+NEBOC_MEDIA_CAPABILITY_FLAGS_OFFSET],NEBOC_MEDIA_NO_CAPABILITIES
 jne .security

 mov rax,NEBOC_MEDIA_SEAL_MAGIC
 xor rax,[rdi+NEBOC_MEDIA_WIDTH_OFFSET]
 xor rax,[rdi+NEBOC_MEDIA_HEIGHT_OFFSET]
 xor rax,[rdi+NEBOC_MEDIA_SAMPLE_RATE_OFFSET]
 xor rax,[rdi+NEBOC_MEDIA_CHANNELS_OFFSET]
 xor rax,[rdi+NEBOC_MEDIA_DURATION_MS_OFFSET]
 xor rax,[rdi+NEBOC_MEDIA_DECLARED_BYTES_OFFSET]
 xor rax,[rdi+NEBOC_MEDIA_AVAILABLE_BYTES_OFFSET]
 xor rax,[rdi+NEBOC_MEDIA_PRIVACY_FLAGS_OFFSET]
 xor rax,[rdi+NEBOC_MEDIA_CAPABILITY_FLAGS_OFFSET]
 cmp rax,[rdi+NEBOC_MEDIA_SEAL_OFFSET]
 jne .security
 mov [rdi+NEBOC_MEDIA_RESULT_OFFSET],r10
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK

.malformed:
 mov eax,neboc_media_imagem_audio_e_video_DIAG_PARSE_stdlib
 jmp .source_failure
.type:
 mov eax,neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib
 jmp .source_failure
.resource:
.truncated:
 mov eax,neboc_media_imagem_audio_e_video_DIAG_RUNTIME_stdlib
 jmp .source_failure
.security:
 mov eax,neboc_media_imagem_audio_e_video_DIAG_SECURITY_stdlib
.source_failure:
 mov [rdi+NEBOC_MEDIA_DIAGNOSTIC_OFFSET],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid_argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
