%ifndef NEBO_TRAINER_INC
%define NEBO_TRAINER_INC 1
%define NEBO_TRAINER_OK 0
%define NEBO_TRAINER_E_ARGUMENT 1
%define NEBO_TRAINER_E_LIMIT 2
%define NEBO_TRAINER_E_STATE 3
%define NEBO_TRAINER_E_REENTRY 4
%define NEBO_TRAINER_E_CANCELLED 5
%define NEBO_TRAINER_E_NONFINITE 6
%define NEBO_TRAINER_E_CALLBACK 7
%define NEBO_TRAINER_E_OVERFLOW 8
%define NEBO_TRAINER_STATE_EMPTY 0
%define NEBO_TRAINER_STATE_READY 1
%define NEBO_TRAINER_STATE_ACTIVE 2
%define NEBO_TRAINER_STATE_CLOSED 3
%define NEBO_TRAINER_OUTCOME_COMPLETED 0
%define NEBO_TRAINER_OUTCOME_EARLY_STOP 1
%define NEBO_TRAINER_OUTCOME_CANCELLED 2
%define NEBO_TRAINER_OUTCOME_CALLBACK 3
%define NEBO_TRAINER_MAX_EPOCHS 1024
%define NEBO_TRAINER_MAX_BATCH 4096
%ifndef NEBO_TRAINER_IMPLEMENTATION
extern nebo_trainer_init
extern nebo_trainer_fit
extern nebo_trainer_train_batch
extern nebo_trainer_evaluate
extern nebo_trainer_cancel
extern nebo_trainer_progress
extern nebo_trainer_close
%endif
%endif
