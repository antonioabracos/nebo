%ifndef NEBO_CHECKPOINT_INC
%define NEBO_CHECKPOINT_INC 1
%define NEBO_CHECKPOINT_OK 0
%define NEBO_CHECKPOINT_E_ARGUMENT 1
%define NEBO_CHECKPOINT_E_LIMIT 2
%define NEBO_CHECKPOINT_E_MAGIC 3
%define NEBO_CHECKPOINT_E_VERSION 4
%define NEBO_CHECKPOINT_E_SIZE 5
%define NEBO_CHECKPOINT_E_CHECKSUM 6
%define NEBO_CHECKPOINT_E_CAPACITY 7
%define NEBO_CHECKPOINT_E_OVERLAP 8
%define NEBO_CHECKPOINT_E_IO 9
%define NEBO_CHECKPOINT_MAGIC 0x314b4354
%define NEBO_CHECKPOINT_VERSION 1
%define NEBO_CHECKPOINT_HEADER_SIZE 64
%define NEBO_CHECKPOINT_MAX_BYTES 1048576
%define NEBO_CHECKPOINT_MAX_ROTATIONS 8
%ifndef NEBO_CHECKPOINT_IMPLEMENTATION
extern nebo_checkpoint_pack
extern nebo_checkpoint_inspect
extern nebo_checkpoint_restore
extern nebo_checkpoint_save
extern nebo_checkpoint_load
extern nebo_checkpoint_compare
extern nebo_checkpoint_rotate
extern nebo_checkpoint_seed_all
%endif
%endif
