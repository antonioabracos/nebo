%ifndef nebo_sync_SYNC_INC_concurrency_native_vertical
%define nebo_sync_SYNC_INC_concurrency_native_vertical 1
%include "compiler/semantic/concurrency/concurrency_contract.inc"
%define NEBO_SYNC_STATE 0
%define NEBO_SYNC_OWNER 8
%define NEBO_SYNC_WAITERS 16
%define NEBO_SYNC_MAX_WAITERS 24
%define NEBO_SYNC_GENERATION 32
%define NEBO_SYNC_FLAGS 40
%define NEBO_GUARD_LOCK 0
%define NEBO_GUARD_KIND 8
%define NEBO_GUARD_OWNER 16
%define NEBO_GUARD_STATE 24
%define NEBO_ATOMIC_VALUE 0
%define NEBO_ATOMIC_GENERATION 8
%ifndef NEBO_SYNC_IMPLEMENTATION
extern nebo_sync_budget_init
extern nebo_mutex_init
extern nebo_mutex_lock
extern nebo_mutex_unlock
extern nebo_rwlock_init
extern nebo_rwlock_read
extern nebo_rwlock_write
extern nebo_rwlock_unlock
extern nebo_atomic_init
extern nebo_atomic_load
extern nebo_atomic_store
extern nebo_atomic_compare_exchange
extern nebo_atomic_fetch_add
%endif
%endif
