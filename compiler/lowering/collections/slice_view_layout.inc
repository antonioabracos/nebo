%ifndef NEBOC_SLICE_VIEW_LAYOUT_INC
%define NEBOC_SLICE_VIEW_LAYOUT_INC 1

; Frozen F01 A0 descriptor: no owner pointer and no ownership of storage.
%define NEBOC_SLICE_BASE_OFFSET 0
%define neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET 8
%define NEBOC_SLICE_STRIDE_OFFSET 16
%define NEBOC_SLICE_VIEW_LAYOUT_SLICE_GENERATION_OFFSET 24
%define NEBOC_SLICE_TOKEN_OFFSET 32
%define neboc_option_result_null_externo_e_erros_tipados_SLICE_SIZE 40
%define NEBOC_SLICE_QWORDS 5

%define NEBOC_SLICE_OWNER_BASE_OFFSET 0
%define NEBOC_SLICE_OWNER_LENGTH_OFFSET 8
%define NEBOC_SLICE_OWNER_STRIDE_OFFSET 16
%define neboc_option_result_null_externo_e_erros_tipados_SLICE_OWNER_GENERATION_OFFSET 24
%define NEBOC_SLICE_OWNER_BORROWS_OFFSET 32
%define NEBOC_SLICE_OWNER_ACTIVE_OFFSET 40
%define NEBOC_SLICE_OWNER_SIZE 48
%define NEBOC_SLICE_OWNER_QWORDS 6

%endif
