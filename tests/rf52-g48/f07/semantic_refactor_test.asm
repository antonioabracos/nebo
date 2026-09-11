bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/refactor/semantic_refactor.inc"

global _start
extern neboc_fix_plan_new,neboc_fix_plan_add,neboc_fix_plan_order_canonical
extern neboc_refactor_rename,neboc_refactor_extract_function
extern neboc_refactor_inline_function,neboc_refactor_extract_binding
extern neboc_refactor_move_item,neboc_refactor_change_signature
extern neboc_refactor_organize_imports,neboc_refactor_convert_copy_to_borrow
extern neboc_refactor_convert_if_to_match,neboc_refactor_affected_files
extern neboc_refactor_public_api_impact,neboc_cli_refactor
extern neboc_host_process_exit

%define DIGEST1 0x4701
%define DIGEST2 0x4702
%define DIGEST3 0x4703
%define SEMANTIC_SNAPSHOT 0x48070001

section .data
source1_bytes: db 'foo foo'
source2_bytes: db 'foo bar'
source3_bytes: db 'foo baz'
backup1: times 7 db 0
backup2: times 7 db 0
backup3: times 7 db 0
replacement: db 'qux'
sources:
 dq 1,DIGEST1,DIGEST1,source1_bytes,7,backup1,7
 dq 2,DIGEST2,DIGEST2,source2_bytes,7,backup2,7
 dq 3,DIGEST3,DIGEST3,source3_bytes,7,backup3,7
source_set: dq sources,3
edit_use: dq 1,4,7,replacement,3,DIGEST1,NEBOC_FIXIT_MACHINE_APPLICABLE
edit_import: dq 2,0,3,replacement,3,DIGEST2,NEBOC_FIXIT_MACHINE_APPLICABLE
edit_declaration: dq 1,0,3,replacement,3,DIGEST1,NEBOC_FIXIT_MACHINE_APPLICABLE
affected_ids: dq 1,2
request:
 dq 0,0x1001,0x2001,SEMANTIC_SNAPSHOT,SEMANTIC_SNAPSHOT
 dq NEBOC_REFACTOR_PROOF_ALL,plan,affected_ids,2
 dq NEBOC_REFACTOR_API_COMPATIBLE,0,0,0,0
unsafe_request:
 dq 0,0x1001,0x2001,SEMANTIC_SNAPSHOT,SEMANTIC_SNAPSHOT
 dq NEBOC_REFACTOR_PROOF_IDENTITY,plan,affected_ids,2
 dq NEBOC_REFACTOR_API_COMPATIBLE,0,0,0,0
stale_request:
 dq 0,0x1001,0x2001,SEMANTIC_SNAPSHOT,0xdead
 dq NEBOC_REFACTOR_PROOF_ALL,plan,affected_ids,2
 dq NEBOC_REFACTOR_API_COMPATIBLE,0,0,0,0
ambiguous_request:
 dq 0,0,0x2001,SEMANTIC_SNAPSHOT,SEMANTIC_SNAPSHOT
 dq NEBOC_REFACTOR_PROOF_ALL,plan,affected_ids,2
 dq NEBOC_REFACTOR_API_COMPATIBLE,0,0,0,0

section .bss align=16
plan: resb NEBOC_FIX_PLAN_SIZE
edits: resb NEBOC_FIX_EDIT_SIZE*4
journal: resb NEBOC_FIX_JOURNAL_SIZE*3
preview: resb NEBOC_FIX_PREVIEW_SIZE
preview_edits: resb NEBOC_FIX_EDIT_SIZE*4
affected_result: resb NEBOC_REFACTOR_FILES_SIZE
affected_output: resq 2
impact_output: resq 1

section .text
_start:
 sub rsp,8
 lea rdi,[rel plan]
 lea rsi,[rel source_set]
 lea rdx,[rel edits]
 mov ecx,4
 lea r8,[rel journal]
 mov r9d,3
 call neboc_fix_plan_new
 test eax,eax
 jne .fail1
 lea rdi,[rel plan]
 lea rsi,[rel edit_import]
 call neboc_fix_plan_add
 test eax,eax
 jne .fail2
 lea rdi,[rel plan]
 lea rsi,[rel edit_declaration]
 call neboc_fix_plan_add
 test eax,eax
 jne .fail3
 lea rdi,[rel plan]
 lea rsi,[rel edit_use]
 call neboc_fix_plan_add
 test eax,eax
 jne .fail4
 lea rdi,[rel plan]
 call neboc_fix_plan_order_canonical
 test eax,eax
 jne .fail5

 ; Every public operation consumes semantic facts, not source text.
 lea rdi,[rel request]
 call neboc_refactor_rename
 test eax,eax
 jne .fail6
 cmp qword [rel request+NEBOC_REFACTOR_REQUEST_OPERATION_OFFSET],NEBOC_REFACTOR_RENAME
 jne .fail7
 lea rdi,[rel request]
 call neboc_refactor_extract_function
 test eax,eax
 jne .fail8
 lea rdi,[rel request]
 call neboc_refactor_inline_function
 test eax,eax
 jne .fail9
 lea rdi,[rel request]
 call neboc_refactor_extract_binding
 test eax,eax
 jne .fail10
 lea rdi,[rel request]
 call neboc_refactor_move_item
 test eax,eax
 jne .fail11
 lea rdi,[rel request]
 call neboc_refactor_change_signature
 test eax,eax
 jne .fail12
 lea rdi,[rel request]
 call neboc_refactor_organize_imports
 test eax,eax
 jne .fail13
 lea rdi,[rel request]
 call neboc_refactor_convert_copy_to_borrow
 test eax,eax
 jne .fail14
 lea rdi,[rel request]
 call neboc_refactor_convert_if_to_match
 test eax,eax
 jne .fail15

 ; Unsafe, stale, and identity-ambiguous requests fail before mutation.
 lea rdi,[rel unsafe_request]
 call neboc_refactor_extract_function
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail16
 lea rdi,[rel stale_request]
 call neboc_refactor_rename
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail17
 lea rdi,[rel ambiguous_request]
 call neboc_refactor_rename
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail18
 cmp dword [rel source1_bytes],0x206f6f66
 jne .fail19

 ; Rename is the selected plan. Apply is forbidden until both reviews occur.
 lea rdi,[rel request]
 call neboc_refactor_rename
 test eax,eax
 jne .fail20
 lea rdi,[rel request]
 mov esi,NEBOC_REFACTOR_CLI_APPLY
 xor edx,edx
 mov ecx,NEBOC_FIX_CAPABILITY_APPLY
 mov r8d,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 call neboc_cli_refactor
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail21

 lea rax,[rel affected_output]
 mov [rel affected_result+NEBOC_REFACTOR_FILES_ITEMS_OFFSET],rax
 mov qword [rel affected_result+NEBOC_REFACTOR_FILES_CAPACITY_OFFSET],1
 lea rdi,[rel request]
 lea rsi,[rel affected_result]
 call neboc_refactor_affected_files
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail22
 mov qword [rel affected_result+NEBOC_REFACTOR_FILES_CAPACITY_OFFSET],2
 lea rdi,[rel request]
 lea rsi,[rel affected_result]
 call neboc_refactor_affected_files
 test eax,eax
 jne .fail23
 cmp qword [rel affected_result+NEBOC_REFACTOR_FILES_COUNT_OFFSET],2
 jne .fail24
 cmp qword [rel affected_output],1
 jne .fail25
 cmp qword [rel affected_output+8],2
 jne .fail26

 lea rdi,[rel request]
 lea rsi,[rel impact_output]
 call neboc_refactor_public_api_impact
 test eax,eax
 jne .fail27
 cmp qword [rel impact_output],NEBOC_REFACTOR_API_COMPATIBLE
 jne .fail28

 ; Preview is the CLI default and remains write-free.
 lea rax,[rel preview_edits]
 mov [rel preview+NEBOC_FIX_PREVIEW_EDITS_OFFSET],rax
 mov qword [rel preview+NEBOC_FIX_PREVIEW_CAPACITY_OFFSET],4
 lea rdi,[rel request]
 mov esi,NEBOC_REFACTOR_CLI_PREVIEW
 lea rdx,[rel preview]
 xor ecx,ecx
 xor r8d,r8d
 call neboc_cli_refactor
 test eax,eax
 jne .fail29
 cmp qword [rel preview+NEBOC_FIX_PREVIEW_COUNT_OFFSET],3
 jne .fail30
 cmp dword [rel source1_bytes],0x206f6f66
 jne .fail31
 cmp dword [rel source2_bytes],0x206f6f66
 jne .fail32
 cmp dword [rel source3_bytes],0x206f6f66
 jne .fail33

 ; A breaking public API classification cannot be applied by this profile.
 mov qword [rel request+NEBOC_REFACTOR_REQUEST_API_IMPACT_OFFSET],NEBOC_REFACTOR_API_BREAKING
 lea rdi,[rel request]
 lea rsi,[rel impact_output]
 call neboc_refactor_public_api_impact
 test eax,eax
 jne .fail34
 lea rdi,[rel request]
 mov esi,NEBOC_REFACTOR_CLI_APPLY
 xor edx,edx
 mov ecx,NEBOC_FIX_CAPABILITY_APPLY
 mov r8d,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 call neboc_cli_refactor
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail35
 mov qword [rel request+NEBOC_REFACTOR_REQUEST_API_IMPACT_OFFSET],NEBOC_REFACTOR_API_COMPATIBLE
 lea rdi,[rel request]
 lea rsi,[rel impact_output]
 call neboc_refactor_public_api_impact
 test eax,eax
 jne .fail36

 ; Injected mid-plan failure restores every caller buffer.
 mov qword [rel plan+NEBOC_FIX_PLAN_FAILURE_AFTER_OFFSET],1
 lea rdi,[rel request]
 mov esi,NEBOC_REFACTOR_CLI_APPLY
 xor edx,edx
 mov ecx,NEBOC_FIX_CAPABILITY_APPLY
 mov r8d,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 call neboc_cli_refactor
 cmp eax,NEBOC_STATUS_IO_ERROR
 jne .fail37
 cmp dword [rel source1_bytes],0x206f6f66
 jne .fail38
 cmp dword [rel source2_bytes],0x206f6f66
 jne .fail39
 cmp dword [rel source3_bytes],0x206f6f66
 jne .fail40

 ; Successful apply changes only linked identities; the homonym stays intact.
 mov qword [rel plan+NEBOC_FIX_PLAN_FAILURE_AFTER_OFFSET],0
 lea rdi,[rel request]
 mov esi,NEBOC_REFACTOR_CLI_APPLY
 xor edx,edx
 mov ecx,NEBOC_FIX_CAPABILITY_APPLY
 mov r8d,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 call neboc_cli_refactor
 test eax,eax
 jne .fail41
 cmp dword [rel source1_bytes],0x20787571
 jne .fail42
 cmp dword [rel source1_bytes+3],0x78757120
 jne .fail43
 cmp dword [rel source2_bytes],0x20787571
 jne .fail44
 cmp dword [rel source3_bytes],0x206f6f66
 jne .fail45
 cmp qword [rel request+NEBOC_REFACTOR_REQUEST_APPLIED_OFFSET],1
 jne .fail46

 xor edi,edi
 call neboc_host_process_exit

%assign n 1
%rep 46
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
