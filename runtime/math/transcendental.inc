%ifndef NEBO_TRANSCENDENTAL_INC
%define NEBO_TRANSCENDENTAL_INC 1
%include "compiler/semantic/numeric/numeric_contract.inc"
%define NEBO_FLOAT_FINITE 1
%define NEBO_FLOAT_NAN 2
%define NEBO_FLOAT_INFINITE 4
%define NEBO_FLOAT_NEGATIVE_ZERO 8
%define NEBO_FLOAT_SUBNORMAL 16
%ifndef NEBO_TRANSCENDENTAL_IMPLEMENTATION
extern nebo_math_sin_f64
extern nebo_math_cos_f64
extern nebo_math_tan_f64
extern nebo_math_exp_f64
extern nebo_math_log_f64
extern nebo_math_atan2_f64
extern nebo_math_floor_f64
extern nebo_math_ceil_f64
extern nebo_math_round_f64
extern nebo_float_classify_f64
extern nebo_float_approx_equal_f64
%endif
%endif
