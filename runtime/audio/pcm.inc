%ifndef NEBO_PCM_INC
%define NEBO_PCM_INC 1
%define NEBO_PCM_OK 0
%define NEBO_PCM_E_ARGUMENT 1
%define NEBO_PCM_E_FORMAT 2
%define NEBO_PCM_E_RANGE 3
%define NEBO_PCM_E_LIMIT 4
%define NEBO_PCM_E_OVERFLOW 5
%define NEBO_PCM_E_MISMATCH 6
%define NEBO_PCM_E_STALE 7
%define NEBO_PCM_E_OVERLAP 8
%define NEBO_PCM_FORMAT_S16LE 1
%define NEBO_PCM_FLAG_OWNED 1
%define NEBO_PCM_FLAG_MUTABLE 2
%define NEBO_PCM_FLAG_CLOSED 4
%define NEBO_PCM_DESC_BYTES 64
%ifndef NEBO_PCM_IMPLEMENTATION
extern nebo_pcm_init
extern nebo_pcm_duration_us
extern nebo_pcm_mix_into
extern nebo_pcm_resample_linear_into
%endif
%endif
