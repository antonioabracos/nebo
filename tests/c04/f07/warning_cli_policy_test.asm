bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/driver/cli/linux-x86_64/cli_driver.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/warning_cli_policy.inc"

global _start
extern neboc_warning_baseline_new
extern neboc_warning_baseline_add
extern neboc_warning_baseline_classify
extern neboc_warning_cli_decide
extern neboc_host_process_exit

section .bss align=16
baseline: resb NEBOC_WARNING_BASELINE_SIZE
entries: resb NEBOC_WARNING_BASELINE_ENTRY_SIZE*2
baseline_class: resq 1
request: resb NEBOC_WARNING_CLI_REQUEST_SIZE
decision: resb NEBOC_WARNING_CLI_DECISION_SIZE

section .text

; decide(level, warnings_as_errors, cap_lints, baseline_class)
decide:
 mov [rel request+NEBOC_WARNING_CLI_REQUEST_LEVEL_OFFSET],rdi
 mov [rel request+NEBOC_WARNING_CLI_REQUEST_WARNINGS_AS_ERRORS_OFFSET],rsi
 mov [rel request+NEBOC_WARNING_CLI_REQUEST_CAP_LINTS_OFFSET],rdx
 mov [rel request+NEBOC_WARNING_CLI_REQUEST_BASELINE_CLASS_OFFSET],rcx
 lea rdi,[rel request]
 lea rsi,[rel decision]
 jmp neboc_warning_cli_decide

_start:
 ; Default visible warning succeeds and keeps its canonical level.
 mov edi,NEBOC_WARNING_LEVEL_WARN
 xor esi,esi
 xor edx,edx
 mov ecx,NEBOC_WARNING_BASELINE_NONE
 call decide
 test eax,eax
 jne .fail1
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_ORIGINAL_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_WARN
 jne .fail2
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EFFECTIVE_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_WARN
 jne .fail3
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EMIT_OFFSET],1
 jne .fail4
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_FAIL_OFFSET],0
 jne .fail5
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EXIT_CODE_OFFSET],NEBOC_CLI_EXIT_SUCCESS
 jne .fail6

 ; warnings-as-errors changes exit policy, not the original diagnostic.
 mov edi,NEBOC_WARNING_LEVEL_WARN
 mov esi,1
 xor edx,edx
 mov ecx,NEBOC_WARNING_BASELINE_NONE
 call decide
 test eax,eax
 jne .fail7
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_ORIGINAL_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_WARN
 jne .fail8
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EFFECTIVE_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_DENY
 jne .fail9
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_FAIL_OFFSET],1
 jne .fail10
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EXIT_CODE_OFFSET],NEBOC_CLI_EXIT_SOURCE_ERROR
 jne .fail11
 test qword [rel decision+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],NEBOC_WARNING_CLI_FLAG_PROMOTED
 jz .fail12

 ; cap-lints is applied after promotion; the decision records both operations.
 mov edi,NEBOC_WARNING_LEVEL_WARN
 mov esi,1
 mov edx,NEBOC_WARNING_LEVEL_WARN
 mov ecx,NEBOC_WARNING_BASELINE_NONE
 call decide
 test eax,eax
 jne .fail13
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EFFECTIVE_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_WARN
 jne .fail14
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_FAIL_OFFSET],0
 jne .fail15
 mov rax,[rel decision+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET]
 and eax,NEBOC_WARNING_CLI_FLAG_PROMOTED|NEBOC_WARNING_CLI_FLAG_CAPPED
 cmp eax,NEBOC_WARNING_CLI_FLAG_PROMOTED|NEBOC_WARNING_CLI_FLAG_CAPPED
 jne .fail16

 ; Forbid is monotonic even under an allow cap.
 mov edi,NEBOC_WARNING_LEVEL_FORBID
 xor esi,esi
 mov edx,NEBOC_WARNING_LEVEL_ALLOW
 mov ecx,NEBOC_WARNING_BASELINE_MATCHED
 call decide
 test eax,eax
 jne .fail17
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EFFECTIVE_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_FORBID
 jne .fail18
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_FAIL_OFFSET],1
 jne .fail19
 test qword [rel decision+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],NEBOC_WARNING_CLI_FLAG_CAPPED
 jnz .fail20

 ; Construct an exact bounded baseline for snapshot 0xc04f07.
 lea rdi,[rel baseline]
 lea rsi,[rel entries]
 mov edx,2
 mov ecx,0xc04f07
 call neboc_warning_baseline_new
 test eax,eax
 jne .fail21
 lea rdi,[rel baseline]
 mov esi,0x1111
 call neboc_warning_baseline_add
 test eax,eax
 jne .fail22
 lea rdi,[rel baseline]
 mov esi,0x1111
 call neboc_warning_baseline_add
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail23

 lea rdi,[rel baseline]
 mov esi,0x1111
 mov edx,0xc04f07
 lea rcx,[rel baseline_class]
 call neboc_warning_baseline_classify
 test eax,eax
 jne .fail24
 cmp qword [rel baseline_class],NEBOC_WARNING_BASELINE_MATCHED
 jne .fail25
 lea rdi,[rel baseline]
 mov esi,0x2222
 mov edx,0xc04f07
 lea rcx,[rel baseline_class]
 call neboc_warning_baseline_classify
 test eax,eax
 jne .fail26
 cmp qword [rel baseline_class],NEBOC_WARNING_BASELINE_NEW
 jne .fail27
 lea rdi,[rel baseline]
 mov esi,0x1111
 mov edx,0xc04f08
 lea rcx,[rel baseline_class]
 call neboc_warning_baseline_classify
 test eax,eax
 jne .fail28
 cmp qword [rel baseline_class],NEBOC_WARNING_BASELINE_STALE
 jne .fail29

 ; Only an exact, current match can suppress a final WARN.
 mov edi,NEBOC_WARNING_LEVEL_WARN
 xor esi,esi
 xor edx,edx
 mov ecx,NEBOC_WARNING_BASELINE_MATCHED
 call decide
 test eax,eax
 jne .fail30
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EMIT_OFFSET],0
 jne .fail31
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_FAIL_OFFSET],0
 jne .fail32
 test qword [rel decision+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],NEBOC_WARNING_CLI_FLAG_BASELINE_SUPPRESSED
 jz .fail33

 ; A new warning is visible; a stale baseline is visible and auditable.
 mov edi,NEBOC_WARNING_LEVEL_WARN
 xor esi,esi
 xor edx,edx
 mov ecx,NEBOC_WARNING_BASELINE_NEW
 call decide
 test eax,eax
 jne .fail34
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EMIT_OFFSET],1
 jne .fail35
 mov edi,NEBOC_WARNING_LEVEL_WARN
 xor esi,esi
 xor edx,edx
 mov ecx,NEBOC_WARNING_BASELINE_STALE
 call decide
 test eax,eax
 jne .fail36
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_EMIT_OFFSET],1
 jne .fail37
 test qword [rel decision+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],NEBOC_WARNING_CLI_FLAG_BASELINE_STALE
 jz .fail38

 ; Exact baselines never suppress deny.
 mov edi,NEBOC_WARNING_LEVEL_DENY
 xor esi,esi
 xor edx,edx
 mov ecx,NEBOC_WARNING_BASELINE_MATCHED
 call decide
 test eax,eax
 jne .fail39
 cmp qword [rel decision+NEBOC_WARNING_CLI_DECISION_FAIL_OFFSET],1
 jne .fail40

 ; Malformed policy values and invalid baseline identities fail closed.
 xor edi,edi
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call decide
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail41
 mov edi,NEBOC_WARNING_LEVEL_WARN
 mov esi,2
 xor edx,edx
 xor ecx,ecx
 call decide
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail42
 lea rdi,[rel baseline]
 xor esi,esi
 call neboc_warning_baseline_add
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail43

 xor edi,edi
 call neboc_host_process_exit

%assign n 1
%rep 43
.fail %+ n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
