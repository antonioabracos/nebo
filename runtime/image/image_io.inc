%ifndef NEBO_IMAGE_IO_INC
%define NEBO_IMAGE_IO_INC 1
%include "runtime/image/bmp.inc"
%include "runtime/filesystem/file.inc"
%define NEBO_IMAGE_IO_REQUEST_BYTES 64
%define NEBO_IMAGE_IO_E_FILE_BASE 256
%ifndef NEBO_IMAGE_IO_IMPLEMENTATION
extern nebo_image_load
extern nebo_image_save
%endif
%endif
