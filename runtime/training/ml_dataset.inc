%ifndef NEBO_ML_DATASET_INC
%define NEBO_ML_DATASET_INC 1
%define NEBO_DATASET_OK 0
%define NEBO_DATASET_E_ARGUMENT 1
%define NEBO_DATASET_E_LIMIT 2
%define NEBO_DATASET_E_STATE 3
%define NEBO_DATASET_E_CAPACITY 4
%define NEBO_DATASET_E_NONFINITE 5
%define NEBO_DATASET_E_RATIO 6
%define NEBO_DATASET_E_BACKPRESSURE 7
%define NEBO_DATASET_E_CANCELLED 8
%define NEBO_DATASET_E_END 9
%define NEBO_DATASET_MAX_SAMPLES 4096
%define NEBO_DATASET_MAX_BATCH 64
%define NEBO_DATASET_MAX_PREFETCH 8
%ifndef NEBO_ML_DATASET_IMPLEMENTATION
extern nebo_dataset_init
extern nebo_dataset_shuffle
extern nebo_dataset_batch
extern nebo_dataset_split
extern nebo_dataset_augment_affine
extern nebo_dataset_prefetch_acquire
extern nebo_dataset_prefetch_release
%endif
%endif
