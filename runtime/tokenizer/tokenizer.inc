%ifndef NEBO_TOKENIZER_INC
%define NEBO_TOKENIZER_INC 1
%define NEBO_TOKENIZER_OK 0
%define NEBO_TOKENIZER_E_ARGUMENT 1
%define NEBO_TOKENIZER_E_FORMAT 2
%define NEBO_TOKENIZER_E_LIMIT 3
%define NEBO_TOKENIZER_E_TOKEN 4
%define NEBO_TOKENIZER_MAGIC 0x314b5442
%define NEBO_TOKENIZER_VERSION 1
%define NEBO_TOKENIZER_VOCAB 256
%define NEBO_TOKENIZER_MAX_TOKENS 256
%ifndef NEBO_TOKENIZER_IMPLEMENTATION
extern nebo_tokenizer_load
extern nebo_tokenizer_encode
extern nebo_tokenizer_decode
extern nebo_tokenizer_count
extern nebo_tokenizer_vocabulary
extern nebo_tokenizer_special
%endif
%endif
