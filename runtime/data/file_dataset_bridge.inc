%ifndef NEBO_FILE_DATASET_BRIDGE_INC
%define NEBO_FILE_DATASET_BRIDGE_INC 1

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
%include "compiler/semantic/system/filesystem_contract.inc"

%define NEBO_FILE_DATASET_BRIDGE_SIZE 64
%define NEBO_FILE_DATASET_BRIDGE_CAPABILITY 0
%define NEBO_FILE_DATASET_BRIDGE_DATASET 8
%define NEBO_FILE_DATASET_BRIDGE_CAP_GENERATION 16
%define NEBO_FILE_DATASET_BRIDGE_DATA_GENERATION 24
%define NEBO_FILE_DATASET_BRIDGE_ROW_LIMIT 32
%define NEBO_FILE_DATASET_BRIDGE_BYTE_LIMIT 40
%define NEBO_FILE_DATASET_BRIDGE_PARTITION_INDEX 48
%define NEBO_FILE_DATASET_BRIDGE_STATE 56
%define NEBO_FILE_DATASET_BRIDGE_READY 1

%ifndef NEBO_FILE_DATASET_BRIDGE_IMPLEMENTATION
 extern nebo_file_dataset_bridge_init
 extern nebo_file_dataset_bridge_validate
 extern nebo_file_dataset_bridge_scan_next
%endif

%endif
