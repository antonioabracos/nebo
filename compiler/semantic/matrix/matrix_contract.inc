%ifndef NEBO_MATRIX_CONTRACT_INC
%define NEBO_MATRIX_CONTRACT_INC 1
%include "compiler/semantic/numeric/numeric_contract.inc"
%define NEBO_MATRIX_MAGIC 0x4d41545246313531
%define NEBO_MATRIX_DTYPE_I64 1
%define NEBO_MATRIX_DTYPE_F64 2
%define NEBO_MATRIX_FLAG_OWNED 1
%define NEBO_MATRIX_FLAG_VIEW 2
%define NEBO_MATRIX_FLAG_READONLY 4
%define NEBO_MATRIX_FLAG_CONTIGUOUS 8
%define NEBO_MATRIX_MAGIC_OFF 0
%define NEBO_MATRIX_DTYPE 8
%define NEBO_MATRIX_ROWS 16
%define NEBO_MATRIX_COLS 24
%define NEBO_MATRIX_ROW_STRIDE 32
%define NEBO_MATRIX_COL_STRIDE 40
%define NEBO_MATRIX_DATA 48
%define NEBO_MATRIX_CAPACITY 56
%define NEBO_MATRIX_STORAGE_ID 64
%define NEBO_MATRIX_GENERATION 72
%define NEBO_MATRIX_FLAGS 80
%define NEBO_MATRIX_SIZE 88
%define NEBO_MATRIX_MAX_ROWS 64
%define NEBO_MATRIX_MAX_COLS 64
%ifndef NEBO_MATRIX_CONTRACT_IMPLEMENTATION
extern nebo_matrix_init_owned
extern nebo_matrix_validate
extern nebo_matrix_validate_finite_f64
extern nebo_matrix_validate_view_owner
%endif
%endif
