bits 64
default rel
%include "compiler/compat/edition.inc"
extern nebo_edition_check
extern nebo_edition_migration_plan
extern nebo_edition_compat_report
section .bss
align 16
check resb NEBO_EDITION_CHECK_SIZE
migrate resb NEBO_MIGRATE_SIZE
report resb NEBO_COMPAT_SIZE
section .text
prepare_check:
 lea rdi,[check]
 mov ecx,NEBO_EDITION_CHECK_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [check+NEBO_EDITION_CHECK_EDITION],2
 mov qword [check+NEBO_EDITION_CHECK_MIN],1
 mov qword [check+NEBO_EDITION_CHECK_MAX],2
 mov qword [check+NEBO_EDITION_CHECK_FEATURES],0x31
 ret
global _start
_start:
 call prepare_check
 lea rdi,[check]
 call nebo_edition_check
 test eax,eax
 jnz .f1
 cmp qword [check+NEBO_EDITION_CHECK_REASON],0
 jne .f2
 mov qword [check+NEBO_EDITION_CHECK_EDITION],1
 lea rdi,[check]
 call nebo_edition_check
 test eax,eax
 jnz .f3
 cmp qword [check+NEBO_EDITION_CHECK_MIGRATION],1
 jne .f4
 call prepare_check
 mov qword [check+NEBO_EDITION_CHECK_EDITION],3
 lea rdi,[check]
 call nebo_edition_check
 cmp eax,NEBO_EDITION_STATUS_UNKNOWN_EDITION
 jne .f5
 call prepare_check
 mov qword [check+NEBO_EDITION_CHECK_MIN],3
 lea rdi,[check]
 call nebo_edition_check
 cmp eax,NEBO_EDITION_STATUS_VERSION_RANGE
 jne .f6
 call prepare_check
 mov qword [check+NEBO_EDITION_CHECK_ABI],1
 lea rdi,[check]
 call nebo_edition_check
 cmp eax,NEBO_EDITION_STATUS_ABI
 jne .f7
 call prepare_check
 mov qword [check+NEBO_EDITION_CHECK_RUNTIME],1
 lea rdi,[check]
 call nebo_edition_check
 cmp eax,NEBO_EDITION_STATUS_RUNTIME
 jne .f8
 call prepare_check
 mov qword [check+NEBO_EDITION_CHECK_FEATURES],0x10000
 lea rdi,[check]
 call nebo_edition_check
 cmp eax,NEBO_EDITION_STATUS_FEATURE
 jne .f9
 lea rdi,[migrate]
 mov ecx,NEBO_MIGRATE_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [migrate+NEBO_MIGRATE_FROM],1
 mov qword [migrate+NEBO_MIGRATE_TO],2
 mov qword [migrate+NEBO_MIGRATE_FEATURES],7
 lea rdi,[migrate]
 call nebo_edition_migration_plan
 test eax,eax
 jnz .f10
 cmp qword [migrate+NEBO_MIGRATE_STEPS],3
 jne .f11
 mov qword [migrate+NEBO_MIGRATE_UNSAFE],4
 lea rdi,[migrate]
 call nebo_edition_migration_plan
 cmp eax,NEBO_EDITION_STATUS_UNSAFE_MIGRATION
 jne .f12
 cmp qword [migrate+NEBO_MIGRATE_BREAKING],4
 jne .f13
 mov qword [migrate+NEBO_MIGRATE_UNSAFE],0
 mov qword [migrate+NEBO_MIGRATE_FROM],2
 lea rdi,[migrate]
 call nebo_edition_migration_plan
 cmp eax,NEBO_EDITION_STATUS_DIRECTION
 jne .f14
 lea rdi,[report]
 mov ecx,NEBO_COMPAT_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [report+NEBO_COMPAT_EDITION],1
 mov qword [report+NEBO_COMPAT_MIN],1
 mov qword [report+NEBO_COMPAT_MAX],2
 lea rdi,[report]
 call nebo_edition_compat_report
 test eax,eax
 jnz .f15
 cmp qword [report+NEBO_COMPAT_FLAGS],5
 jne .f16
 mov qword [report+NEBO_COMPAT_EDITION],2
 lea rdi,[report]
 call nebo_edition_compat_report
 test eax,eax
 jnz .f17
 cmp qword [report+NEBO_COMPAT_FLAGS],2
 jne .f18
 mov qword [report+NEBO_COMPAT_MAX],1
 lea rdi,[report]
 call nebo_edition_compat_report
 cmp eax,NEBO_EDITION_STATUS_VERSION_RANGE
 jne .f19
 mov qword [report+NEBO_COMPAT_MAX],2
 mov qword [report+NEBO_COMPAT_ABI],1
 lea rdi,[report]
 call nebo_edition_compat_report
 cmp eax,NEBO_EDITION_STATUS_ABI
 jne .f20
 xor edi,edi
 call nebo_edition_check
 cmp eax,NEBO_EDITION_STATUS_INVALID_ARGUMENT
 jne .f21
 xor edi,edi
 call nebo_edition_migration_plan
 cmp eax,NEBO_EDITION_STATUS_INVALID_ARGUMENT
 jne .f22
 xor edi,edi
 call nebo_edition_compat_report
 cmp eax,NEBO_EDITION_STATUS_INVALID_ARGUMENT
 jne .f23
 xor edi,edi
 mov eax,60
 syscall
%macro FAIL 1
.f%1: mov edi,%1
 mov eax,60
 syscall
%endmacro
%assign i 1
%rep 23
FAIL i
%assign i i+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
