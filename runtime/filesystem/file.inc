%ifndef NEBO_FILE_INC
%define NEBO_FILE_INC 1

%include "compiler/semantic/system/filesystem_contract.inc"

extern nebo_file_capability_init
extern nebo_file_open
extern nebo_file_create
extern nebo_file_read
extern nebo_file_read_exact
extern nebo_file_write
extern nebo_file_write_all
extern nebo_file_flush
extern nebo_file_seek
extern nebo_file_metadata
extern nebo_file_set_length
extern nebo_path_metadata
extern nebo_path_exists
extern nebo_path_is_file
extern nebo_path_is_directory
extern nebo_file_close

%endif
