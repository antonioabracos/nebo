%ifndef NEBO_HTTP_INC
%define NEBO_HTTP_INC 1
%include "runtime/network/socket.inc"
%define NEBO_HTTP_RESPONSE_STATUS 0
%define NEBO_HTTP_RESPONSE_BODY 8
%define NEBO_HTTP_RESPONSE_BODY_LENGTH 16
%define NEBO_HTTP_RESPONSE_FLAGS 24
%define NEBO_HTTP_FLAG_CONTENT_LENGTH 1
%define NEBO_HTTP_FLAG_CHUNKED 2
%ifndef NEBO_HTTP_IMPLEMENTATION
extern nebo_http_encode_get
extern nebo_http_parse_response
extern nebo_http_decode_chunked
%endif
%endif
