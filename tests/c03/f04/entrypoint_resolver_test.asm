; C03-F04 persistent target-aware entrypoint resolver conformance.
bits 64
default rel

%include "compiler/semantic/modules/entrypoint_resolver.inc"

global _start
extern neboc_entrypoint_resolve

%define VALID_DIRECT (NEBOC_ENTRYPOINT_FLAG_VALID_SIGNATURE | NEBOC_ENTRYPOINT_FLAG_DIRECT_DECLARATION)
%macro CANDIDATE 8
 dq %1, %2, %3, %4, %5, %6, %7, %8
%endmacro

section .data
align 8
isolation:
 CANDIDATE 2,0,0,0,0,9,9,0
 CANDIDATE 1,20,3,90,1,40,47,VALID_DIRECT
duplicates_a:
 CANDIDATE 1,20,4,92,1,30,37,VALID_DIRECT
 CANDIDATE 1,10,2,91,1,20,27,VALID_DIRECT
duplicates_b:
 CANDIDATE 1,10,2,91,1,20,27,VALID_DIRECT
 CANDIDATE 1,20,4,92,1,30,37,VALID_DIRECT
invalid_and_valid:
 CANDIDATE 1,5,1,81,2,10,17,VALID_DIRECT
 CANDIDATE 1,20,3,90,1,40,47,VALID_DIRECT
ambiguous_and_valid:
 CANDIDATE 1,7,1,82,1,12,19,VALID_DIRECT | NEBOC_ENTRYPOINT_FLAG_IMPORTED
 CANDIDATE 1,20,3,90,1,40,47,VALID_DIRECT
one_valid:
 CANDIDATE 1,20,3,90,1,40,47,VALID_DIRECT
one_generated:
 CANDIDATE 1,22,5,94,1,50,57,VALID_DIRECT | NEBOC_ENTRYPOINT_FLAG_GENERATED
bad_span:
 CANDIDATE 1,6,2,88,1,30,30,VALID_DIRECT
unknown_flag:
 CANDIDATE 1,6,2,88,1,30,37,VALID_DIRECT | 32
other_target_duplicates:
 CANDIDATE 2,1,1,1,2,1,2,0
 CANDIDATE 2,2,2,2,2,2,3,0
 CANDIDATE 1,30,6,95,1,60,67,VALID_DIRECT

align 8
result: times NEBOC_ENTRYPOINT_RESULT_SIZE db 0
result_a: times NEBOC_ENTRYPOINT_RESULT_SIZE db 0
result_b: times NEBOC_ENTRYPOINT_RESULT_SIZE db 0

section .text
_start:
 ; One selected target declaration wins; malformed other-target data is inert.
 lea rdi,[rel isolation]
 mov esi,2
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 test eax,eax
 jnz .fail_1
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_MATCHED_COUNT],1
 jne .fail_1
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_SELECTED_SYMBOL_ID],1
 jne .fail_1
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_SELECTED_MODULE_ID],20
 jne .fail_1

 ; Missing executable entrypoint is a semantic failure with no fallback.
 xor edi,edi
 xor esi,esi
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_2
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_MISSING
 jne .fail_2

 ; Duplicate evidence is canonical under input permutation.
 lea rdi,[rel duplicates_a]
 mov esi,2
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result_a]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_3
 cmp qword [rel result_a+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_DUPLICATE
 jne .fail_3
 cmp qword [rel result_a+NEBOC_ENTRYPOINT_RESULT_PRIMARY_MODULE_ID],10
 jne .fail_3
 cmp qword [rel result_a+NEBOC_ENTRYPOINT_RESULT_RELATED_MODULE_ID],20
 jne .fail_3
 lea rdi,[rel duplicates_b]
 mov esi,2
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result_b]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_3
 lea rsi,[rel result_a]
 lea rdi,[rel result_b]
 mov ecx,NEBOC_ENTRYPOINT_RESULT_SIZE / 8
 repe cmpsq
 jne .fail_3

 ; Invalid structure precedes an otherwise valid declaration.
 lea rdi,[rel invalid_and_valid]
 mov esi,2
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_4
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_INVALID_SIGNATURE
 jne .fail_4
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_MODULE_ID],5
 jne .fail_4

 ; Imported/reexported start cannot become the target entrypoint.
 lea rdi,[rel ambiguous_and_valid]
 mov esi,2
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_5
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_AMBIGUOUS
 jne .fail_5
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_MODULE_ID],7
 jne .fail_5

 ; Library and test targets require zero declarations.
 xor edi,edi
 xor esi,esi
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_LIBRARY
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 test eax,eax
 jnz .fail_6
 lea rdi,[rel one_valid]
 mov esi,1
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_LIBRARY
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_6
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_FORBIDDEN_FOR_TARGET
 jne .fail_6
 lea rdi,[rel one_valid]
 mov esi,1
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_TEST
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_6

 ; Example and generated direct entrypoints share executable cardinality.
 lea rdi,[rel one_valid]
 mov esi,1
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXAMPLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 test eax,eax
 jnz .fail_7
 lea rdi,[rel one_generated]
 mov esi,1
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 test eax,eax
 jnz .fail_7
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_SELECTED_MODULE_ID],22
 jne .fail_7

 ; Invalid span and unknown flags fail closed.
 lea rdi,[rel bad_span]
 mov esi,1
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_8
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_INVALID_SIGNATURE
 jne .fail_8
 lea rdi,[rel unknown_flag]
 mov esi,1
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 cmp eax,4
 jne .fail_8

 ; Candidate limit and invalid arguments are atomic and bounded.
 mov qword [rel result+120],-1
 lea rdi,[rel one_valid]
 mov esi,NEBOC_ENTRYPOINT_MAX_CANDIDATES + 1
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 cmp eax,8
 jne .fail_9
 cmp qword [rel result+120],0
 jne .fail_9
 lea rdi,[rel one_valid]
 mov esi,1
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 xor r8d,r8d
 call neboc_entrypoint_resolve
 cmp eax,1
 jne .fail_9

 ; Multiple unselected declarations cannot create cross-target ambiguity.
 lea rdi,[rel other_target_duplicates]
 mov esi,3
 mov edx,1
 mov ecx,NEBOC_TARGET_KIND_EXECUTABLE
 lea r8,[rel result]
 call neboc_entrypoint_resolve
 test eax,eax
 jnz .fail_10
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_MATCHED_COUNT],1
 jne .fail_10
 cmp qword [rel result+NEBOC_ENTRYPOINT_RESULT_SELECTED_MODULE_ID],30
 jne .fail_10

 xor edi,edi
 jmp .exit
.fail_1: mov edi,1
 jmp .exit
.fail_2: mov edi,2
 jmp .exit
.fail_3: mov edi,3
 jmp .exit
.fail_4: mov edi,4
 jmp .exit
.fail_5: mov edi,5
 jmp .exit
.fail_6: mov edi,6
 jmp .exit
.fail_7: mov edi,7
 jmp .exit
.fail_8: mov edi,8
 jmp .exit
.fail_9: mov edi,9
 jmp .exit
.fail_10: mov edi,10
.exit:
 mov eax,60
 syscall
