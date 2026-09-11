; C05-F09 fix preview, false-positive and incremental parity oracle.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"
%include "compiler/lint/unused_bindings.inc"
global _start
extern neboc_unused_fix_preview
extern neboc_unused_finding_parity
extern neboc_unused_incremental_key
extern neboc_host_process_exit
%define SNAPSHOT 0xC050F0900000001
section .data
function: dq SNAPSHOT,94,0,1,0,0,0,0,0,0
plan: dq 0,0,0,0,0,1,100,SNAPSHOT,1,2,NEBOC_ANALYSIS_COMPLETE
candidate: dq SNAPSHOT,24,2400,0,NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL,0,0,150,170
finding_a: dq 1,NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL,NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL,24,2400,150,170,0,1,0,SNAPSHOT,NEBOC_ANALYSIS_COMPLETE,NEBOC_UNUSED_REASON_NO_READS
finding_b: dq 1,NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL,NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL,24,2400,150,170,0,1,0,SNAPSHOT,NEBOC_ANALYSIS_COMPLETE,NEBOC_UNUSED_REASON_NO_READS
source_sentinel: dq 0x1122334455667788,0x99aabbccddeeff00
section .bss align=16
fix: resb NEBOC_UNUSED_FIX_SIZE
key_a: resb NEBOC_UNUSED_INCREMENTAL_SIZE
key_b: resb NEBOC_UNUSED_INCREMENTAL_SIZE
section .text
_start:
 sub rsp,8
 ; Pure local full-span removal is machine-applicable and nonmutating.
 call .fix
 test eax,eax
 jne .fail1
 cmp qword [rel fix+NEBOC_UNUSED_FIX_ACTIVE_OFFSET],1
 jne .fail2
 cmp qword [rel fix+NEBOC_UNUSED_FIX_APPLICABILITY_OFFSET],NEBOC_UNUSED_FIX_MACHINE_APPLICABLE
 jne .fail3
 cmp qword [rel fix+NEBOC_UNUSED_FIX_START_OFFSET],150
 jne .fail4
 cmp qword [rel fix+NEBOC_UNUSED_FIX_END_OFFSET],170
 jne .fail5
 cmp qword [rel fix+NEBOC_UNUSED_FIX_REPLACEMENT_LENGTH_OFFSET],0
 jne .fail6
 mov rax,0x1122334455667788
 cmp [rel source_sentinel],rax
 jne .fail7
 ; Effects force manual review.
 mov qword [rel finding_a+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET],5
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_INITIALIZER_EFFECTS_OFFSET],5
 call .fix
 test eax,eax
 jne .fail8
 cmp qword [rel fix+NEBOC_UNUSED_FIX_APPLICABILITY_OFFSET],NEBOC_UNUSED_FIX_MANUAL_ONLY
 jne .fail9
 ; Signature-affecting inputs are manual even when pure.
 mov qword [rel finding_a+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET],0
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_INITIALIZER_EFFECTS_OFFSET],0
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_PARAMETER
 call .fix
 test eax,eax
 jne .fail10
 cmp qword [rel fix+NEBOC_UNUSED_FIX_APPLICABILITY_OFFSET],NEBOC_UNUSED_FIX_MANUAL_ONLY
 jne .fail11
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL
 ; A suppressed/absent finding has no fix.
 mov qword [rel finding_a+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 call .fix
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail12
 mov qword [rel finding_a+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 ; Clean and incremental semantic findings are byte-parity exact.
 lea rdi,[rel finding_a]
 lea rsi,[rel finding_b]
 call neboc_unused_finding_parity
 test eax,eax
 jne .fail13
 mov qword [rel finding_b+NEBOC_UNUSED_FINDING_SYMBOL_OFFSET],25
 lea rdi,[rel finding_a]
 lea rsi,[rel finding_b]
 call neboc_unused_finding_parity
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail14
 mov qword [rel finding_b+NEBOC_UNUSED_FINDING_SYMBOL_OFFSET],24
 ; Identical snapshot dependencies produce an identical incremental key.
 call .key_a
 test eax,eax
 jne .fail15
 call .key_b
 test eax,eax
 jne .fail16
 mov rax,[rel key_a+NEBOC_UNUSED_INCREMENTAL_DIGEST_OFFSET]
 cmp rax,[rel key_b+NEBOC_UNUSED_INCREMENTAL_DIGEST_OFFSET]
 jne .fail17
 ; Dependency changes alter the key; incomplete plans refuse a key.
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_BLOCK_COUNT_OFFSET],2
 call .key_b
 test eax,eax
 jne .fail18
 mov rax,[rel key_a+NEBOC_UNUSED_INCREMENTAL_DIGEST_OFFSET]
 cmp rax,[rel key_b+NEBOC_UNUSED_INCREMENTAL_DIGEST_OFFSET]
 je .fail19
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 call .key_b
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail20
 mov rax,0x99aabbccddeeff00
 cmp [rel source_sentinel+8],rax
 jne .fail21
 xor edi,edi
 call neboc_host_process_exit
.fix:
 lea rdi,[rel finding_a]
 lea rsi,[rel candidate]
 lea rdx,[rel fix]
 call neboc_unused_fix_preview
 ret
.key_a:
 lea rdi,[rel function]
 lea rsi,[rel plan]
 lea rdx,[rel candidate]
 lea rcx,[rel key_a]
 call neboc_unused_incremental_key
 ret
.key_b:
 lea rdi,[rel function]
 lea rsi,[rel plan]
 lea rdx,[rel candidate]
 lea rcx,[rel key_b]
 call neboc_unused_incremental_key
 ret
%assign n 1
%rep 21
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
