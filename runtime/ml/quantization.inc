%ifndef NEBO_QUANTIZATION_INC
%define NEBO_QUANTIZATION_INC 1
%define NEBO_QUANT_OK 0
%define NEBO_QUANT_E_ARGUMENT 1
%define NEBO_QUANT_E_LIMIT 2
%define NEBO_QUANT_E_NONFINITE 3
%define NEBO_QUANT_E_SCALE 4
%define NEBO_QUANT_E_CAPACITY 5
%define NEBO_QUANT_E_OVERLAP 6
%define NEBO_QUANT_MAX_ELEMENTS 4096
%define NEBO_QUANT_PARAMS_SIZE 32
%define NEBO_QUANT_PARAMS_SCALE 0
%define NEBO_QUANT_PARAMS_INVERSE 8
%define NEBO_QUANT_PARAMS_MAX_ABS 16
%define NEBO_QUANT_PARAMS_SAMPLES 24
%define NEBO_QUANT_REPORT_SIZE 40
%ifndef NEBO_QUANTIZATION_IMPLEMENTATION
extern nebo_int8_calibrate
extern nebo_int8_quantize
extern nebo_int8_dequantize
extern nebo_int8_compare_accuracy
extern nebo_int8_features
%endif
%endif
