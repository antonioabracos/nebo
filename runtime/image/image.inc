%ifndef NEBO_IMAGE_INC
%define NEBO_IMAGE_INC 1
%define NEBO_MEDIA_OK 0
%define NEBO_MEDIA_E_ARGUMENT 1
%define NEBO_MEDIA_E_FORMAT 2
%define NEBO_MEDIA_E_RANGE 3
%define NEBO_MEDIA_E_LIMIT 4
%define NEBO_MEDIA_E_OVERFLOW 5
%define NEBO_MEDIA_E_BOUNDS 6
%define NEBO_MEDIA_E_STALE 7
%define NEBO_PIXEL_RGBA8 1
%define NEBO_PIXEL_GRAY8 2
%define NEBO_IMAGE_FLAG_OWNED 1
%define NEBO_IMAGE_FLAG_BORROWED 2
%define NEBO_IMAGE_FLAG_MUTABLE 4
%define NEBO_IMAGE_FLAG_CLOSED 8
%define NEBO_IMAGE_DESC_BYTES 64
%ifndef NEBO_IMAGE_IMPLEMENTATION
extern nebo_image_init
extern nebo_image_wrap_mut
extern nebo_image_width
extern nebo_image_height
extern nebo_image_stride
extern nebo_image_pixel
extern nebo_image_set_pixel
extern nebo_image_region
extern nebo_image_close
%endif
%endif
