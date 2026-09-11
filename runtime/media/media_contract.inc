%ifndef NEBO_MEDIA_CONTRACT_INC
%define NEBO_MEDIA_CONTRACT_INC 1

%define NEBO_MEDIA_CODEC_BMP 1
%define NEBO_MEDIA_CODEC_PNG 2
%define NEBO_PNG_BYTES_1X1_RGBA8 73
%define NEBO_MEDIA_AUDIO_DEVICE_BYTES 64
%define NEBO_MEDIA_AUDIO_DEVICE_OPEN 1
%define NEBO_MEDIA_AUDIO_DEVICE_CLOSED 2
%define NEBO_MEDIA_AUDIO_E_BACKPRESSURE 65
%define NEBO_MEDIA_PIPELINE_BYTES 64
%define NEBO_MEDIA_PIPELINE_DECODING 1
%define NEBO_MEDIA_PIPELINE_ENCODED 2

%ifndef NEBO_MEDIA_CONTRACT_IMPLEMENTATION
 extern nebo_png_inspect
 extern nebo_png_decode
 extern nebo_png_encode
 extern nebo_codec_inspect
 extern nebo_audio_channels
 extern nebo_audio_frame_count
 extern nebo_media_audio_device_open
 extern nebo_media_audio_device_write
 extern nebo_media_audio_device_progress
 extern nebo_media_audio_device_close
 extern nebo_video_frame_image
 extern nebo_video_frame_timestamp
 extern nebo_video_stream_frames
 extern nebo_media_pipeline_decode
 extern nebo_media_pipeline_transform
 extern nebo_media_pipeline_encode
 extern nebo_media_pipeline_progress
%endif
%endif
