%ifndef NEBO_TEXT_INC
%define NEBO_TEXT_INC 1
%include "compiler/semantic/system/filesystem_contract.inc"
%define NEBO_TEXT_WRITE_TRUNCATE 0
%define NEBO_TEXT_WRITE_APPEND 1
%define NEBO_TEXT_WRITE_ATOMIC 2
extern nebo_utf8_validate
extern nebo_file_read_bytes
extern nebo_file_read_text
extern nebo_file_write_bytes
extern nebo_file_write_text
extern nebo_text_lines
extern nebo_file_read_line
%endif
