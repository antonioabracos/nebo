%ifndef NEBO_VIDEO_PIPELINE_INC
%define NEBO_VIDEO_PIPELINE_INC 1
%include "runtime/image/image.inc"
%define NEBO_VIDEO_OK 0
%define NEBO_VIDEO_E_ARGUMENT 1
%define NEBO_VIDEO_E_LIMIT 2
%define NEBO_VIDEO_E_STATE 3
%define NEBO_VIDEO_E_FULL 4
%define NEBO_VIDEO_E_EMPTY 5
%define NEBO_VIDEO_E_TIMESTAMP 6
%define NEBO_VIDEO_E_CANCELLED 7
%define NEBO_VIDEO_E_CLOSED 8
%define NEBO_VIDEO_E_STALE_IMAGE 9
%define NEBO_VIDEO_FRAME_BYTES 40
%define NEBO_VIDEO_FRAME_FLAG_VALID 1
%define NEBO_VIDEO_FRAME_FLAG_TRANSFORMED 2
%define NEBO_VIDEO_PIPELINE_BYTES 96
%define NEBO_VIDEO_PIPELINE_ACTIVE 1
%define NEBO_VIDEO_PIPELINE_CANCELLED 2
%define NEBO_VIDEO_PIPELINE_CLOSED 3
%ifndef NEBO_VIDEO_PIPELINE_IMPLEMENTATION
extern nebo_video_frame_init
extern nebo_video_frame_transform_copy
extern nebo_video_pipeline_init
extern nebo_video_pipeline_push
extern nebo_video_pipeline_pop
extern nebo_video_pipeline_cancel
extern nebo_video_pipeline_close
%endif
%endif
