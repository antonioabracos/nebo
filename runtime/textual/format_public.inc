%ifndef NEBO_TEXT_FORMAT_PUBLIC_INC
%define NEBO_TEXT_FORMAT_PUBLIC_INC 1
; Compiler/runtime private frame. Public PercentRequest/Node/Argument layouts
; retain their canonical owners. Output is sized separately after evaluation.
%define TEXT_FORMAT_TEMPLATE 0
%define TEXT_FORMAT_ARG_COUNT 8
%define TEXT_FORMAT_POLICY 16
%define TEXT_FORMAT_SAVED_FRAME 24
%define TEXT_FORMAT_REQUEST 32
%define TEXT_FORMAT_RESULT 128
%define TEXT_FORMAT_NODE_COUNT 168
; A fallible result has tag/diagnostic and an inline public Text payload.
%define TEXT_FORMAT_NODES 176
%define TEXT_FORMAT_ARGS 9392
%define TEXT_FORMAT_FRAME_SIZE 11440
%define TEXT_FORMAT_ERROR_ALLOCATION 9
%endif
