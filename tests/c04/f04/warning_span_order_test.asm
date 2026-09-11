bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/recovery.inc"

global _start
extern neboc_source_map_new
extern neboc_span_related_location
extern neboc_diagnostic_bag_new
extern neboc_diagnostic_bag_add_with_provenance
extern neboc_diagnostic_bag_deduplicate
extern neboc_diagnostic_bag_sort_canonical
extern neboc_host_process_exit

%define DIGEST_A 0x1111222233334444
%define DIGEST_B 0x5555666677778888
%define PROVENANCE_A 0x1010101010101010
%define PROVENANCE_B 0x2020202020202020

section .rodata
warning_id: db "NEBO-W0001"
warning_id_len equ $-warning_id
message_key: db "diagnostic.compatibility.warning"
message_key_len equ $-message_key

section .data
span_a:
 dq 1,4,8,32,DIGEST_A,7,0,0
 times (NEBOC_SPAN_SIZE-64)/8 dq 0
span_b:
 dq 2,10,14,48,DIGEST_B,9,0,0
 times (NEBOC_SPAN_SIZE-64)/8 dq 0

section .bss
source_map: resb NEBOC_SOURCE_MAP_SIZE
source_entries: resb NEBOC_SOURCE_ENTRY_SIZE
source_guard: resq 1
diag_a: resb NEBOC_DIAGNOSTIC_SIZE
diag_b: resb NEBOC_DIAGNOSTIC_SIZE
diag_c: resb NEBOC_DIAGNOSTIC_SIZE
diag_d: resb NEBOC_DIAGNOSTIC_SIZE
bag: resb NEBOC_DIAG_BAG_SIZE
entries: resb NEBOC_RECOVERY_DIAG_ENTRY_SIZE*4
scalar: resq 1

section .text
init_warning:
 mov [rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],rsi
 mov [rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET],rdx
 mov qword [rdi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 mov qword [rdi+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_PORTABILITY
 mov qword [rdi+NEBOC_DIAGNOSTIC_PHASE_OFFSET],NEBOC_DIAGNOSTIC_PHASE_TYPE
 lea rax,[rel message_key]
 mov [rdi+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET],rax
 mov qword [rdi+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET],message_key_len
 mov qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 mov qword [rdi+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 mov qword [rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],99
 mov qword [rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],4
 mov qword [rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET],8
 mov qword [rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET],32
 mov qword [rdi+NEBOC_DIAGNOSTIC_ARGUMENT_COUNT_OFFSET],1
 mov qword [rdi+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET+NEBOC_DIAGNOSTIC_ARGUMENT_TYPE_OFFSET],NEBOC_DIAGNOSTIC_ARGUMENT_UNSIGNED
 mov qword [rdi+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET+NEBOC_DIAGNOSTIC_ARGUMENT_VALUE_OFFSET],1
 ret

_start:
 ; SourceMap construction clears exactly entry storage, not the map or guard.
 mov rax,0x1122334455667788
 mov [rel source_entries],rax
 mov rax,0x8877665544332211
 mov [rel source_guard],rax
 lea rdi,[rel source_map]
 lea rsi,[rel source_entries]
 mov edx,1
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jne .fail1
 cmp qword [rel source_entries],0
 jne .fail2
 mov rax,0x8877665544332211
 cmp qword [rel source_guard],rax
 jne .fail3

 ; Related causal locations retain digest and generation provenance.
 lea rdi,[rel span_a]
 mov esi,NEBOC_RELATED_DECLARATION
 lea rdx,[rel span_b]
 call neboc_span_related_location
 test eax,eax
 jne .fail4
 mov rax,DIGEST_B
 cmp qword [rel span_a+NEBOC_SPAN_RELATED_OFFSET+NEBOC_RELATED_SPAN_OFFSET+NEBOC_SPAN_DIGEST_OFFSET],rax
 jne .fail5
 cmp qword [rel span_a+NEBOC_SPAN_RELATED_OFFSET+NEBOC_RELATED_SPAN_OFFSET+NEBOC_SPAN_GENERATION_OFFSET],9
 jne .fail6

 lea rdi,[rel diag_a]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 call init_warning
 lea rsi,[rel diag_a]
 lea rdi,[rel diag_b]
 mov ecx,NEBOC_DIAGNOSTIC_QWORDS
 rep movsq
 lea rsi,[rel diag_a]
 lea rdi,[rel diag_c]
 mov ecx,NEBOC_DIAGNOSTIC_QWORDS
 rep movsq
 mov qword [rel diag_c+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET+NEBOC_DIAGNOSTIC_ARGUMENT_VALUE_OFFSET],2
 lea rsi,[rel diag_a]
 lea rdi,[rel diag_d]
 mov ecx,NEBOC_DIAGNOSTIC_QWORDS
 rep movsq

 lea rdi,[rel bag]
 lea rsi,[rel entries]
 mov edx,4
 mov ecx,4
 mov r8d,400
 call neboc_diagnostic_bag_new
 test eax,eax
 jne .fail7
 lea rdi,[rel bag]
 lea rsi,[rel diag_a]
 mov edx,50
 xor ecx,ecx
 lea r8,[rel scalar]
 call neboc_diagnostic_bag_add_with_provenance
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail8
 cmp qword [rel bag+NEBOC_DIAG_BAG_COUNT_OFFSET],0
 jne .fail9

 ; Deliberately insert in noncanonical provenance order.
 lea rdi,[rel bag]
 lea rsi,[rel diag_d]
 mov edx,50
 mov rcx,PROVENANCE_B
 lea r8,[rel scalar]
 call neboc_diagnostic_bag_add_with_provenance
 test eax,eax
 jne .fail10
 lea rdi,[rel bag]
 lea rsi,[rel diag_c]
 mov edx,50
 mov rcx,PROVENANCE_A
 lea r8,[rel scalar]
 call neboc_diagnostic_bag_add_with_provenance
 test eax,eax
 jne .fail11
 lea rdi,[rel bag]
 lea rsi,[rel diag_b]
 mov edx,50
 mov rcx,PROVENANCE_A
 lea r8,[rel scalar]
 call neboc_diagnostic_bag_add_with_provenance
 test eax,eax
 jne .fail12
 lea rdi,[rel bag]
 lea rsi,[rel diag_a]
 mov edx,50
 mov rcx,PROVENANCE_A
 lea r8,[rel scalar]
 call neboc_diagnostic_bag_add_with_provenance
 test eax,eax
 jne .fail13

 ; Exact semantic duplicate is suppressed; differing arguments/provenance stay.
 lea rdi,[rel bag]
 mov esi,NEBOC_DIAG_DEDUP_STRUCTURAL
 lea rdx,[rel scalar]
 call neboc_diagnostic_bag_deduplicate
 test eax,eax
 jne .fail14
 cmp qword [rel scalar],1
 jne .fail15
 cmp qword [rel bag+NEBOC_DIAG_BAG_VISIBLE_COUNT_OFFSET],3
 jne .fail16

 lea rdi,[rel bag]
 call neboc_diagnostic_bag_sort_canonical
 test eax,eax
 jne .fail17
 lea rax,[rel diag_c]
 cmp qword [rel entries+NEBOC_DIAG_ENTRY_DIAGNOSTIC_OFFSET],rax
 jne .fail18
 mov rax,PROVENANCE_A
 cmp qword [rel entries+NEBOC_DIAG_ENTRY_PROVENANCE_KEY_OFFSET],rax
 jne .fail19
 lea rax,[rel diag_d]
 cmp qword [rel entries+NEBOC_RECOVERY_DIAG_ENTRY_SIZE*3+NEBOC_DIAG_ENTRY_DIAGNOSTIC_OFFSET],rax
 jne .fail20
 mov rax,PROVENANCE_B
 cmp qword [rel entries+NEBOC_RECOVERY_DIAG_ENTRY_SIZE*3+NEBOC_DIAG_ENTRY_PROVENANCE_KEY_OFFSET],rax
 jne .fail21

 xor edi,edi
 call neboc_host_process_exit

%assign n 1
%rep 21
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
