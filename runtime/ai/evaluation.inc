%ifndef NEBO_EVALUATION_INC
%define NEBO_EVALUATION_INC 1
%define NEBO_EVAL_OK 0
%define NEBO_EVAL_E_ARGUMENT 1
%define NEBO_EVAL_E_LIMIT 2
%define NEBO_EVAL_E_PROVENANCE 3
%define NEBO_EVAL_E_POLICY 4
%define NEBO_EVAL_MAX_CASES 256
%define NEBO_EVAL_MAX_TRACE 65536
%ifndef NEBO_EVALUATION_IMPLEMENTATION
extern nebo_eval_init
extern nebo_eval_record
extern nebo_eval_report
extern nebo_eval_provenance
extern nebo_eval_policy_case
%endif
%endif
