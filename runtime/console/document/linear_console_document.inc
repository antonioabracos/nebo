%ifndef NEBO_LINEAR_CONSOLE_DOCUMENT_INC
%define NEBO_LINEAR_CONSOLE_DOCUMENT_INC 1
%define NEBO_CONSOLE_MAX_TEXT 4096
%define NEBO_CONSOLE_MAX_LINES 1024
%define NEBO_CONSOLE_MAX_TITLE 256
%define NEBO_CONSOLE_STATE_OPEN 1
%define NEBO_CONSOLE_STATE_CLOSED 2
%define NEBO_CONSOLE_OK 0
%define NEBO_CONSOLE_ERROR_ARGUMENT 1
%define NEBO_CONSOLE_ERROR_STATE 2
%define NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT 3
%define NEBO_CONSOLE_ERROR_STYLE 4
%define NEBO_CONSOLE_STATE 0
%define NEBO_CONSOLE_TEXT 8
%define NEBO_CONSOLE_CAPACITY 16
%define NEBO_CONSOLE_LENGTH 24
%define NEBO_CONSOLE_LINES 32
%define NEBO_CONSOLE_TITLE 40
%define NEBO_CONSOLE_TITLE_CAPACITY 48
%define NEBO_CONSOLE_TITLE_LENGTH 56
%define NEBO_CONSOLE_STYLE 64
%define NEBO_CONSOLE_SCROLL 72
%define NEBO_CONSOLE_REVISION 80
%define NEBO_CONSOLE_SIZE 88
%ifndef NEBO_CONSOLE_DOCUMENT_IMPLEMENTATION
extern nebo_console_init
extern nebo_console_set_title
extern nebo_console_set_style
extern nebo_console_append
extern nebo_console_append_line
extern nebo_console_clear
extern nebo_console_scroll
extern nebo_console_size_query
extern nebo_console_close
%endif
%endif
