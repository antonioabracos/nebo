; C03-F07 pre-fix-sensitive strict manifest/TargetId/path native assertions.
bits 64
default rel

%include "compiler/parser/target_manifest.inc"
%include "compiler/semantic/modules/target_path.inc"
%include "compiler/support/status/status_codes.inc"

global _start
extern neboc_target_manifest_parse
extern neboc_target_registry_select
extern neboc_target_path_validate_bytes
extern neboc_host_process_exit

section .rodata
good:
 db 'nebo-target-manifest 1',10
 db 'default app-alpha',10
 db 'target app-alpha executable alpha.no - -',10
 db 'target app-beta executable beta.no - -',10
 db 'target checks test checks.no - case_pass',10
 db 'target core library core.no - -',10
good_len equ $-good
reordered:
 db 'nebo-target-manifest 1',10
 db 'target beta executable beta.no - -',10
 db 'target alpha executable alpha.no - -',10
reordered_len equ $-reordered
duplicate:
 db 'nebo-target-manifest 1',10
 db 'target alpha executable alpha.no - -',10
 db 'target alpha library core.no - -',10
duplicate_len equ $-duplicate
unicode_id:
 db 'nebo-target-manifest 1',10
 db 'target ',0xc3,0xa1,' executable alpha.no - -',10
unicode_id_len equ $-unicode_id
selector_beta: db 'app-beta'
selector_unknown: db 'app'
safe_path: db 'src/core.no'
escape_path: db '../core.no'
repeat_path: db 'src//core.no'
absolute_path: db '/core.no'
depth16_path: db 'a/a/a/a/a/a/a/a/a/a/a/a/a/a/a/x.no'
depth16_path_len equ $-depth16_path
depth17_path: db 'a/a/a/a/a/a/a/a/a/a/a/a/a/a/a/a/x.no'
depth17_path_len equ $-depth17_path
id31_manifest:
 db 'nebo-target-manifest 1',10
 db 'target a123456789012345678901234567890 executable alpha.no - -',10
id31_manifest_len equ $-id31_manifest
id32_manifest:
 db 'nebo-target-manifest 1',10
 db 'target a1234567890123456789012345678901 executable alpha.no - -',10
id32_manifest_len equ $-id32_manifest

section .bss
align 8
request: resb NEBOC_TARGET_MANIFEST_SIZE
records: resb NEBOC_TARGET_MANIFEST_MAX_TARGETS*NEBOC_TARGET_RECORD_SIZE

section .text
_start:
 mov r12d,1
 lea rdi,[rel good]
 mov esi,good_len
 call parse
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_TARGET_MANIFEST_COUNT],4
 jne fail

 mov r12d,2
 lea rdi,[rel request]
 lea rsi,[rel selector_beta]
 mov edx,8
 call neboc_target_registry_select
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_TARGET_MANIFEST_SELECTED_INDEX],1
 jne fail

 mov r12d,3
 lea rdi,[rel request]
 xor esi,esi
 xor edx,edx
 call neboc_target_registry_select
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_TARGET_MANIFEST_SELECTED_INDEX],0
 jne fail

 mov r12d,4
 lea rdi,[rel request]
 lea rsi,[rel selector_unknown]
 mov edx,3
 call neboc_target_registry_select
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_TARGET_MANIFEST_ERROR],NEBOC_TARGET_MANIFEST_ERROR_UNKNOWN_TARGET
 jne fail

 mov r12d,5
 lea rdi,[rel reordered]
 mov esi,reordered_len
 call parse
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_TARGET_MANIFEST_ERROR],NEBOC_TARGET_MANIFEST_ERROR_DUPLICATE_OR_ORDER
 jne fail

 mov r12d,6
 lea rdi,[rel duplicate]
 mov esi,duplicate_len
 call parse
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail

 mov r12d,7
 lea rdi,[rel unicode_id]
 mov esi,unicode_id_len
 call parse
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail

 mov r12d,8
 lea rdi,[rel safe_path]
 mov esi,11
 mov edx,NEBOC_TARGET_PATH_SUFFIX_SOURCE
 call neboc_target_path_validate_bytes
 test eax,eax
 jnz fail
 lea rdi,[rel escape_path]
 mov esi,10
 mov edx,NEBOC_TARGET_PATH_SUFFIX_SOURCE
 call neboc_target_path_validate_bytes
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 lea rdi,[rel repeat_path]
 mov esi,12
 mov edx,NEBOC_TARGET_PATH_SUFFIX_SOURCE
 call neboc_target_path_validate_bytes
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail

 mov r12d,9
 lea rdi,[rel absolute_path]
 mov esi,8
 mov edx,NEBOC_TARGET_PATH_SUFFIX_SOURCE
 call neboc_target_path_validate_bytes
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 lea rdi,[rel depth16_path]
 mov esi,depth16_path_len
 mov edx,NEBOC_TARGET_PATH_SUFFIX_SOURCE
 call neboc_target_path_validate_bytes
 test eax,eax
 jnz fail
 lea rdi,[rel depth17_path]
 mov esi,depth17_path_len
 mov edx,NEBOC_TARGET_PATH_SUFFIX_SOURCE
 call neboc_target_path_validate_bytes
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail

 mov r12d,10
 lea rdi,[rel id31_manifest]
 mov esi,id31_manifest_len
 call parse
 test eax,eax
 jnz fail
 lea rdi,[rel id32_manifest]
 mov esi,id32_manifest_len
 call parse
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail

 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r12d
 jmp neboc_host_process_exit

; rdi bytes, rsi length -> parser status.
parse:
 push rbx
 mov rbx,rdi
 mov r8,rsi
 lea rdi,[rel request]
 mov ecx,NEBOC_TARGET_MANIFEST_QWORDS
 xor eax,eax
 rep stosq
 mov [rel request+NEBOC_TARGET_MANIFEST_BYTES],rbx
 mov [rel request+NEBOC_TARGET_MANIFEST_LENGTH],r8
 lea rax,[rel records]
 mov [rel request+NEBOC_TARGET_MANIFEST_RECORDS],rax
 mov qword [rel request+NEBOC_TARGET_MANIFEST_CAPACITY],NEBOC_TARGET_MANIFEST_MAX_TARGETS
 lea rdi,[rel request]
 call neboc_target_manifest_parse
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
