%ifndef NEBO_GRADCHECK_INC
%define NEBO_GRADCHECK_INC 1
%define NEBO_GRADVERIFY_OK 0
%define NEBO_GRADVERIFY_E_ARGUMENT 1
%define NEBO_GRADVERIFY_E_LIMIT 2
%define NEBO_GRADVERIFY_E_NONFINITE 3
%define NEBO_GRADVERIFY_E_STEP 4
%define NEBO_GRADVERIFY_E_CAPACITY 5
%define NEBO_GRADVERIFY_E_OVERLAP 6
%define NEBO_GRADVERIFY_MAX_ELEMENTS 4096
%ifndef NEBO_GRADCHECK_IMPLEMENTATION
extern nebo_grad_check
extern nebo_gradient_clip_value
extern nebo_gradient_clip_norm
extern nebo_gradient_checkpoint
%endif
%endif
