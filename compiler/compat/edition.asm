bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/compat/edition.inc"
section .text
NEBOC_ABI_FUNCTION nebo_edition_check
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 mov qword [rdi+NEBO_EDITION_CHECK_REASON],0
 mov qword [rdi+NEBO_EDITION_CHECK_MIGRATION],0
 mov rax,[rdi+NEBO_EDITION_CHECK_EDITION]
 cmp rax,1
 jb .unknown
 cmp rax,2
 ja .unknown
 mov rcx,[rdi+NEBO_EDITION_CHECK_MIN]
 mov rdx,[rdi+NEBO_EDITION_CHECK_MAX]
 cmp rcx,rdx
 ja .range
 cmp rax,rcx
 jb .range
 cmp rax,rdx
 ja .range
 cmp qword [rdi+NEBO_EDITION_CHECK_ABI],0
 jne .abi
 cmp qword [rdi+NEBO_EDITION_CHECK_RUNTIME],0
 jne .runtime
 mov rcx,[rdi+NEBO_EDITION_CHECK_FEATURES]
 test rcx,0xffffffffffff0000
 jnz .feature
 cmp rax,1
 jne .ok
 mov qword [rdi+NEBO_EDITION_CHECK_REASON],1
 mov qword [rdi+NEBO_EDITION_CHECK_MIGRATION],1
.ok: xor eax,eax
 ret
.unknown: mov eax,NEBO_EDITION_STATUS_UNKNOWN_EDITION
 jmp .reason
.range: mov eax,NEBO_EDITION_STATUS_VERSION_RANGE
 jmp .reason
.abi: mov eax,NEBO_EDITION_STATUS_ABI
 jmp .reason
.runtime: mov eax,NEBO_EDITION_STATUS_RUNTIME
 jmp .reason
.feature: mov eax,NEBO_EDITION_STATUS_FEATURE
.reason: mov [rdi+NEBO_EDITION_CHECK_REASON],rax
 ret
.invalid: mov eax,NEBO_EDITION_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION nebo_edition_migration_plan
 test rdi,rdi
 jz .m_invalid
 test rdi,7
 jnz .m_invalid
 mov qword [rdi+NEBO_MIGRATE_STEPS],0
 mov qword [rdi+NEBO_MIGRATE_BREAKING],0
 cmp qword [rdi+NEBO_MIGRATE_FROM],1
 jne .direction
 cmp qword [rdi+NEBO_MIGRATE_TO],2
 jne .direction
 cmp qword [rdi+NEBO_MIGRATE_UNSAFE],0
 jne .unsafe
 mov rax,[rdi+NEBO_MIGRATE_FEATURES]
 test rax,0xffffffffffff0000
 jnz .m_feature
 xor ecx,ecx
.count: test rax,rax
 jz .counted
 mov rdx,rax
 dec rax
 and rax,rdx
 inc rcx
 jmp .count
.counted: mov [rdi+NEBO_MIGRATE_STEPS],rcx
 xor eax,eax
 ret
.direction: mov eax,NEBO_EDITION_STATUS_DIRECTION
 ret
.unsafe: mov rax,[rdi+NEBO_MIGRATE_UNSAFE]
 mov [rdi+NEBO_MIGRATE_BREAKING],rax
 mov eax,NEBO_EDITION_STATUS_UNSAFE_MIGRATION
 ret
.m_feature: mov eax,NEBO_EDITION_STATUS_FEATURE
 ret
.m_invalid: mov eax,NEBO_EDITION_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION nebo_edition_compat_report
 test rdi,rdi
 jz .c_invalid
 test rdi,7
 jnz .c_invalid
 mov qword [rdi+NEBO_COMPAT_FLAGS],0
 mov rax,[rdi+NEBO_COMPAT_EDITION]
 cmp rax,1
 jb .c_unknown
 cmp rax,2
 ja .c_unknown
 mov rcx,[rdi+NEBO_COMPAT_MIN]
 mov rdx,[rdi+NEBO_COMPAT_MAX]
 cmp rcx,rdx
 ja .c_range
 cmp rax,rcx
 jb .c_range
 cmp rax,rdx
 ja .c_range
 cmp qword [rdi+NEBO_COMPAT_ABI],0
 jne .c_abi
 cmp qword [rdi+NEBO_COMPAT_RUNTIME],0
 jne .c_runtime
 cmp rax,1
 jne .c_current
 mov qword [rdi+NEBO_COMPAT_FLAGS],5
 xor eax,eax
 ret
.c_current: mov qword [rdi+NEBO_COMPAT_FLAGS],2
 xor eax,eax
 ret
.c_unknown: mov eax,NEBO_EDITION_STATUS_UNKNOWN_EDITION
 ret
.c_range: mov eax,NEBO_EDITION_STATUS_VERSION_RANGE
 ret
.c_abi: mov eax,NEBO_EDITION_STATUS_ABI
 ret
.c_runtime: mov eax,NEBO_EDITION_STATUS_RUNTIME
 ret
.c_invalid: mov eax,NEBO_EDITION_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
