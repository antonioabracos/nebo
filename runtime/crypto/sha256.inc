%ifndef NEBO_SHA256_INC
%define NEBO_SHA256_INC 1
%include "compiler/semantic/system/system_contract.inc"
%define NEBO_SHA256_CONTEXT_SIZE 112
%define NEBO_SHA256_STATE 0
%define NEBO_SHA256_BUFFER 32
%define NEBO_SHA256_TOTAL 96
%define NEBO_SHA256_BUFFERED 104
%define NEBO_SHA256_DIGEST_SIZE 32
%define NEBO_SECRET_DATA 0
%define NEBO_SECRET_LENGTH 8
%define NEBO_SECRET_CAPACITY 16
%define NEBO_SECRET_STATE 24
%define NEBO_SECRET_STATE_ACTIVE 1
%define NEBO_SECRET_STATE_ZEROIZED 2
%ifndef NEBO_SHA256_IMPLEMENTATION
 extern nebo_sha256_init
 extern nebo_sha256_update
 extern nebo_sha256_final
 extern nebo_sha256_hash
 extern nebo_hmac_sha256
 extern nebo_secret_init
 extern nebo_secret_zeroize
%endif
%endif
