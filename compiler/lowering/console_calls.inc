%ifndef NEBOC_CONSOLE_CALL_LOWERING_INC
%define NEBOC_CONSOLE_CALL_LOWERING_INC 1
%define NEBOC_OPTION_EVALUATION_FAILED 6
%define NEBOC_EVALUATOR_FUNCTION_OFFSET 0
%define NEBOC_EVALUATOR_CONTEXT_OFFSET 8
; A successful evaluator transfers its value to the pending plan.  If a later
; evaluator fails, this optional callback releases the earlier value exactly
; once in reverse source order before the plan is abandoned.
%define NEBOC_EVALUATOR_CLEANUP_OFFSET 16
%define NEBOC_EVALUATOR_SIZE 24
%define NEBOC_EVALUATION_PLAN_VALUES_OFFSET 0
%define NEBOC_EVALUATION_PLAN_COUNT_OFFSET 8
%define NEBOC_EVALUATION_PLAN_STEPS_OFFSET 16
%define NEBOC_EVALUATION_PLAN_STATE_OFFSET 24
%define NEBOC_EVALUATION_PLAN_SIZE 32
%define NEBOC_EVALUATION_PLAN_READY 1
%endif
