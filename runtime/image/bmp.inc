%ifndef NEBO_BMP_INC
%define NEBO_BMP_INC 1
%include "runtime/image/image.inc"
%define NEBO_BMP_E_MAGIC 8
%define NEBO_BMP_E_HEADER 9
%define NEBO_BMP_E_TRUNCATED 10
%define NEBO_BMP_E_UNSUPPORTED 11
%define NEBO_BMP_E_CAPACITY 12
%define NEBO_BMP_META_BYTES 32
%define NEBO_BMP_HEADER_BYTES 54
%ifndef NEBO_BMP_IMPLEMENTATION
extern nebo_bmp_inspect
extern nebo_bmp_decode
extern nebo_bmp_encode
%endif
%endif
