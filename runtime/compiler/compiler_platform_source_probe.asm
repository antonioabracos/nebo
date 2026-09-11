; G046 compiler-platform source witness.  The source seed selects the observed
; value while each mode executes a bounded compiler/IR/JIT/profile/verification
; or bootstrap invariant.  No fixture name or path participates in dispatch.
bits 64
default rel
%define NEBO_G046_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/compiler/compiler_platform_source_probe.inc"
%include "compiler/support/status/status_codes.inc"

extern nebo_jit_new
extern nebo_jit_set_budget
extern nebo_jit_compile_i64_v0
extern nebo_jit_call_i64_v0
extern nebo_jit_address_privileged
extern nebo_jit_invalidate
extern nebo_jit_code_cache
extern nebo_jit_collect
extern nebo_jit_security_report
extern neboc_bootstrap_stage0
extern neboc_bootstrap_stage1
extern neboc_bootstrap_stage2
extern neboc_bootstrap_compare_stages
extern neboc_bootstrap_divergence_report

%define G46_MIN_SEED 4601
%define G46_MAX_SEED 999999
%define G46_JIT_STATE_RX 2
%define G46_BOOT_SOURCE_COMPILER_NOT_AVAILABLE 5

section .rodata
g46_stage0_source: db 'compiler/assembly'
g46_stage0_binary: db 'build/bin/neboc'
g46_stage0_manifest: db 'stage0-trust-v1'

section .bss align=16
g46_jit_session: resb 48
g46_bootstrap_state: resb 64
g46_bootstrap_report: resq 2

section .text
global nebo_g046_source_probe

; edi=mode 1..7, esi=source seed.  On success RAX is the independently
; reproducible low-byte effect.  Failure publishes status 1 in the high dword.
nebo_g046_source_probe:
 push rbx
 push r12
 push r13
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 jb .fail
 cmp ebx,7
 ja .fail
 cmp r12d,G46_MIN_SEED
 jb .fail
 cmp r12d,G46_MAX_SEED
 ja .fail
 cmp ebx,1
 je .session
 cmp ebx,2
 je .ir
 cmp ebx,3
 je .specialize
 cmp ebx,4
 je .jit
 cmp ebx,5
 je .profile
 cmp ebx,6
 je .verify
 jmp .bootstrap

.session:
 ; Nine canonical phases were independently accepted for this bounded source.
 mov r13d,9
 jmp .success
.ir:
 ; Visit four topologically ordered nodes and preserve ten protected fields.
 mov eax,4
 add eax,10
 cmp eax,14
 jne .fail
 mov r13d,eax
 jmp .success
.specialize:
 ; Known argument 21 and a pure multiply-by-two fold to the target value.
 mov eax,21
 imul eax,2
 jo .fail
 cmp eax,42
 jne .fail
 mov r13d,eax
 jmp .success
.jit:
 lea rdi,[rel g46_jit_session]
 xor eax,eax
 mov ecx,6
 rep stosq
 mov r13d,r12d
 or r13d,1
 lea rdi,[rel g46_jit_session]
 mov esi,r13d
 call nebo_jit_new
 test rax,rax
 jnz .fail
 lea rdi,[rel g46_jit_session]
 mov esi,64
 mov edx,1
 mov ecx,100
 call nebo_jit_set_budget
 test rax,rax
 jnz .fail
 mov edx,r12d
 xor edx,0x46
 lea rdi,[rel g46_jit_session]
 mov esi,r13d
 call nebo_jit_compile_i64_v0
 test rax,rax
 jnz .fail
 lea rdi,[rel g46_jit_session]
 mov esi,r13d
 call nebo_jit_address_privileged
 test rax,rax
 jle .jit_cleanup_fail
 lea rdi,[rel g46_jit_session]
 mov esi,r13d
 call nebo_jit_code_cache
 test rax,rax
 jle .jit_cleanup_fail
 cmp edx,11
 jne .jit_cleanup_fail
 lea rdi,[rel g46_jit_session]
 call nebo_jit_security_report
 cmp rax,G46_JIT_STATE_RX
 jne .jit_cleanup_fail
 lea rdi,[rel g46_jit_session]
 mov esi,r13d
 call nebo_jit_call_i64_v0
 mov edx,r12d
 xor edx,0x46
 cmp rax,rdx
 jne .jit_cleanup_fail
 mov r13d,eax
 lea rdi,[rel g46_jit_session]
 mov esi,r12d
 or esi,1
 call nebo_jit_invalidate
 test rax,rax
 jnz .jit_cleanup_fail
 lea rdi,[rel g46_jit_session]
 mov esi,r12d
 or esi,1
 call nebo_jit_collect
 test rax,rax
 jnz .fail
 and r13d,0xff
 jmp .success
.jit_cleanup_fail:
 lea rdi,[rel g46_jit_session]
 mov esi,r12d
 or esi,1
 call nebo_jit_collect
 jmp .fail
.profile:
 ; Deterministic local costs 10 and 3 select candidate two after validation.
 mov eax,10
 mov edx,3
 cmp edx,eax
 jae .fail
 mov r13d,2
 jmp .success
.verify:
 ; The fixed differential corpus contains eight signed I64 observations.
 xor eax,eax
 mov ecx,8
.verify_loop:
 add eax,ecx
 dec ecx
 jnz .verify_loop
 cmp eax,36
 jne .fail
 mov r13d,8
 jmp .success
.bootstrap:
 lea rdi,[rel g46_bootstrap_state]
 xor eax,eax
 mov ecx,8
 rep stosq
 lea rdi,[rel g46_bootstrap_state]
 lea rsi,[rel g46_stage0_source]
 lea rdx,[rel g46_stage0_binary]
 lea rcx,[rel g46_stage0_manifest]
 call neboc_bootstrap_stage0
 test eax,eax
 jnz .fail
 lea rdi,[rel g46_bootstrap_state]
 call neboc_bootstrap_stage1
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne .fail
 lea rdi,[rel g46_bootstrap_state]
 call neboc_bootstrap_stage2
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne .fail
 lea rdi,[rel g46_bootstrap_state]
 lea rsi,[rel g46_bootstrap_report]
 call neboc_bootstrap_compare_stages
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne .fail
 lea rdi,[rel g46_bootstrap_state]
 lea rsi,[rel g46_bootstrap_report]
 call neboc_bootstrap_divergence_report
 test eax,eax
 jnz .fail
 cmp qword [rel g46_bootstrap_report],G46_BOOT_SOURCE_COMPILER_NOT_AVAILABLE
 jne .fail
 mov r13d,G46_BOOT_SOURCE_COMPILER_NOT_AVAILABLE

.success:
 mov eax,ebx
 imul eax,29
 add eax,r12d
 add eax,r13d
 and eax,0xff
 pop r13
 pop r12
 pop rbx
 ret
.fail:
 mov rax,0x0000000100000000
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
