%ifndef NEBOC_MEDIA_DESCRIPTOR_INC
%define NEBOC_MEDIA_DESCRIPTOR_INC 1

; media_imagem_audio_e_video bounded internal contract. It describes synthetic metadata only: no
; payload ownership, filesystem, codec, capture device, or external service.
%define NEBOC_MEDIA_WIDTH_OFFSET 0
%define NEBOC_MEDIA_HEIGHT_OFFSET 8
%define NEBOC_MEDIA_SAMPLE_RATE_OFFSET 16
%define NEBOC_MEDIA_CHANNELS_OFFSET 24
%define NEBOC_MEDIA_DURATION_MS_OFFSET 32
%define NEBOC_MEDIA_DECLARED_BYTES_OFFSET 40
%define NEBOC_MEDIA_AVAILABLE_BYTES_OFFSET 48
%define NEBOC_MEDIA_PRIVACY_FLAGS_OFFSET 56
%define NEBOC_MEDIA_CAPABILITY_FLAGS_OFFSET 64
%define NEBOC_MEDIA_SEAL_OFFSET 72
%define NEBOC_MEDIA_DIAGNOSTIC_OFFSET 80
%define NEBOC_MEDIA_RESULT_OFFSET 88
%define NEBOC_MEDIA_QWORDS 12
%define NEBOC_MEDIA_SIZE 96

%define NEBOC_MEDIA_MAX_DIMENSION 8192
%define NEBOC_MEDIA_MIN_SAMPLE_RATE 8000
%define NEBOC_MEDIA_MAX_SAMPLE_RATE 192000
%define NEBOC_MEDIA_MAX_CHANNELS 8
%define NEBOC_MEDIA_MAX_DURATION_MS 600000
%define NEBOC_MEDIA_MAX_DECLARED_BYTES 16777216

%define NEBOC_MEDIA_PRIVACY_REDACTED 1
%define NEBOC_MEDIA_SYNTHETIC 2
%define NEBOC_MEDIA_REQUIRED_PRIVACY_FLAGS 3
%define NEBOC_MEDIA_NO_CAPABILITIES 0
%define NEBOC_MEDIA_SEAL_MAGIC 0x4733314d45444941

%define neboc_media_imagem_audio_e_video_DIAG_LEX_stdlib 107
%define neboc_media_imagem_audio_e_video_DIAG_PARSE_stdlib 108
%define neboc_media_imagem_audio_e_video_DIAG_TYPE_stdlib 109
%define neboc_media_imagem_audio_e_video_DIAG_CODEGEN_stdlib 110
%define neboc_media_imagem_audio_e_video_DIAG_RUNTIME_stdlib 111
%define neboc_media_imagem_audio_e_video_DIAG_SECURITY_stdlib 112

%endif
