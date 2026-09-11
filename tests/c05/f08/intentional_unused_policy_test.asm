; C05-F08 bounded naming/scoped suppression policy oracle.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/lint/unused_bindings.inc"
global _start
extern neboc_unused_intentional_policy
extern neboc_unused_apply_policy
extern neboc_host_process_exit
%define SNAPSHOT 0xC050F0800000001
section .rodata
intentional_name: db '_unused'
plain_name: db 'unused'
bad_name: db '_bad-name'
reason: db 'generated binding retained for side effects'
blank_reason: db '   '
section .data
candidate: dq SNAPSHOT,23,2300,0,NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL,0,0x99,130,140
policy: dq SNAPSHOT,NEBOC_UNUSED_POLICY_MODE_NAME,intentional_name,7,0,0,23,0,NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL
finding: dq 1,NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL,NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL,23,2300,130,140,0,1,0x99,SNAPSHOT,NEBOC_ANALYSIS_COMPLETE,NEBOC_UNUSED_REASON_NO_READS
section .bss align=16
record: resb NEBOC_UNUSED_POLICY_RECORD_SIZE
section .text
_start:
 sub rsp,8
 ; Canonical underscore-prefixed ASCII name.
 call .validate
 test eax,eax
 jne .fail1
 cmp qword [rel record+NEBOC_UNUSED_POLICY_RECORD_FLAGS_OFFSET],NEBOC_UNUSED_POLICY_FLAG_INTENTIONAL_NAME
 jne .fail2
 call .apply
 test eax,eax
 jne .fail3
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail4
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET],0x99
 jne .fail5
 ; Plain and punctuation-bearing names are rejected.
 lea rax,[rel plain_name]
 mov [rel policy+NEBOC_UNUSED_POLICY_NAME_OFFSET],rax
 mov qword [rel policy+NEBOC_UNUSED_POLICY_NAME_LENGTH_OFFSET],6
 call .validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail6
 lea rax,[rel bad_name]
 mov [rel policy+NEBOC_UNUSED_POLICY_NAME_OFFSET],rax
 mov qword [rel policy+NEBOC_UNUSED_POLICY_NAME_LENGTH_OFFSET],9
 call .validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail7
 ; Scoped suppression requires a nonblank single-line reason and scope.
 mov qword [rel policy+NEBOC_UNUSED_POLICY_MODE_OFFSET],NEBOC_UNUSED_POLICY_MODE_SCOPE
 mov qword [rel policy+NEBOC_UNUSED_POLICY_NAME_OFFSET],0
 mov qword [rel policy+NEBOC_UNUSED_POLICY_NAME_LENGTH_OFFSET],0
 lea rax,[rel reason]
 mov [rel policy+NEBOC_UNUSED_POLICY_REASON_OFFSET],rax
 mov qword [rel policy+NEBOC_UNUSED_POLICY_REASON_LENGTH_OFFSET],43
 mov qword [rel policy+NEBOC_UNUSED_POLICY_SCOPE_OFFSET],77
 call .validate
 test eax,eax
 jne .fail8
 cmp qword [rel record+NEBOC_UNUSED_POLICY_RECORD_FLAGS_OFFSET],NEBOC_UNUSED_POLICY_FLAG_SCOPED_SUPPRESSION
 jne .fail9
 lea rax,[rel blank_reason]
 mov [rel policy+NEBOC_UNUSED_POLICY_REASON_OFFSET],rax
 mov qword [rel policy+NEBOC_UNUSED_POLICY_REASON_LENGTH_OFFSET],3
 call .validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail10
 ; Wrong symbol and non-unused codes fail closed.
 lea rax,[rel reason]
 mov [rel policy+NEBOC_UNUSED_POLICY_REASON_OFFSET],rax
 mov qword [rel policy+NEBOC_UNUSED_POLICY_REASON_LENGTH_OFFSET],43
 mov qword [rel policy+NEBOC_UNUSED_POLICY_SYMBOL_OFFSET],24
 call .validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail11
 mov qword [rel policy+NEBOC_UNUSED_POLICY_SYMBOL_OFFSET],23
 mov qword [rel policy+NEBOC_UNUSED_POLICY_CODE_OFFSET],0xdead
 call .validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail12
 ; Applying to incomplete or mismatched findings never suppresses.
 mov qword [rel policy+NEBOC_UNUSED_POLICY_CODE_OFFSET],NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL
 call .validate
 test eax,eax
 jne .fail13
 mov qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 mov qword [rel finding+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 call .apply
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail14
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail15
 mov qword [rel finding+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov qword [rel record+NEBOC_UNUSED_POLICY_RECORD_SYMBOL_OFFSET],24
 call .apply
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail16
 cmp qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],23
 jne .fail17
 xor edi,edi
 call neboc_host_process_exit
.validate:
 lea rdi,[rel candidate]
 lea rsi,[rel policy]
 lea rdx,[rel record]
 call neboc_unused_intentional_policy
 ret
.apply:
 lea rdi,[rel finding]
 lea rsi,[rel record]
 call neboc_unused_apply_policy
 ret
%assign n 1
%rep 17
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
