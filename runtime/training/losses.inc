%ifndef NEBO_LOSSES_INC
%define NEBO_LOSSES_INC 1
%define NEBO_LOSS_OK 0
%define NEBO_LOSS_E_ARGUMENT 1
%define NEBO_LOSS_E_LIMIT 2
%define NEBO_LOSS_E_SHAPE 3
%define NEBO_LOSS_E_TARGET 4
%define NEBO_LOSS_E_NONFINITE 5
%define NEBO_LOSS_E_CAPACITY 6
%define NEBO_LOSS_E_OVERLAP 7
%define NEBO_LOSS_MAX_SAMPLES 4096
%define NEBO_LOSS_MAX_CLASSES 64
%ifndef NEBO_LOSSES_IMPLEMENTATION
extern nebo_loss_mse
extern nebo_loss_cross_entropy
extern nebo_loss_binary_cross_entropy
extern nebo_loss_nll
extern nebo_metric_accuracy
extern nebo_metric_precision_recall
extern nebo_metric_confusion_matrix
%endif
%endif
