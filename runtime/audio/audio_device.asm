; PATTERN-MATCHING-E-DESTRUCTURING-F09 truthful live-audio capability boundary.
bits 64
default rel
%define NEBO_AUDIO_DEVICE_IMPLEMENTATION 1
%include "runtime/audio/audio_device.inc"
section .text
global nebo_audio_device_open
global nebo_audio_device_write
global nebo_audio_device_close
nebo_audio_device_open:
nebo_audio_device_write:
nebo_audio_device_close:
    mov eax,NEBO_AUDIO_DEVICE_E_UNSUPPORTED_BACKEND
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
