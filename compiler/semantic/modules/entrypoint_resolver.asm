; C03-F04 deterministic whole-target entrypoint resolution.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/entrypoint_resolver.inc"

%define EP_CLASS_ALL 0
%define EP_CLASS_INVALID 1
%define EP_CLASS_AMBIGUOUS 2
%define EP_CLASS_VALID 3

section .text

; entrypoint_resolve(candidates*, count, selected_target_id, target_kind,
;                    result*) -> status
;
; Only candidates belonging to selected_target_id participate. Executable and
; example targets require exactly one direct, valid StartDecl. Library and test
; targets require zero. Semantic failures return INVALID_SOURCE and publish a
; deterministic outcome plus primary/related locations. Invalid argument and
; capacity failures leave the already-cleared result atomic.
NEBOC_ABI_FUNCTION neboc_entrypoint_resolve
 test r8,r8
 jz .invalid_argument_no_result
 test r8,7
 jnz .invalid_argument_no_result
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,40
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbp,rcx
 mov rbx,r8

 ; Clear all public result fields before inspecting any other input.
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_ENTRYPOINT_RESULT_SIZE / 8
 rep stosq

 cmp r13,NEBOC_ENTRYPOINT_MAX_CANDIDATES
 ja .limit
 test r13,r13
 jz .candidate_pointer_valid
 test r12,r12
 jz .invalid_argument
 test r12,7
 jnz .invalid_argument
.candidate_pointer_valid:
 test r14,r14
 jz .invalid_argument
 cmp rbp,NEBOC_TARGET_KIND_EXECUTABLE
 jb .invalid_argument
 cmp rbp,NEBOC_TARGET_KIND_EXAMPLE
 ja .invalid_argument

 mov qword [rsp],0                 ; selected-target declarations
 mov qword [rsp+8],0               ; invalid signatures
 mov qword [rsp+16],0              ; imported/reexported ambiguity
 mov qword [rsp+24],0              ; direct valid declarations
 mov qword [rsp+32],0              ; scan index
.scan:
 mov rax,[rsp+32]
 cmp rax,r13
 jae .classify_target
 mov r11,rax
 shl r11,6
 add r11,r12
 cmp [r11+NEBOC_ENTRYPOINT_CANDIDATE_TARGET_ID],r14
 jne .scan_next
 inc qword [rsp]
 cmp rbp,NEBOC_TARGET_KIND_LIBRARY
 je .scan_next
 cmp rbp,NEBOC_TARGET_KIND_TEST
 je .scan_next
 mov rdi,r11
 call .candidate_class
 cmp eax,EP_CLASS_INVALID
 je .count_invalid
 cmp eax,EP_CLASS_AMBIGUOUS
 je .count_ambiguous
 inc qword [rsp+24]
 jmp .scan_next
.count_invalid:
 inc qword [rsp+8]
 jmp .scan_next
.count_ambiguous:
 inc qword [rsp+16]
.scan_next:
 inc qword [rsp+32]
 jmp .scan

.classify_target:
 mov rax,[rsp]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_MATCHED_COUNT],rax
 cmp rbp,NEBOC_TARGET_KIND_LIBRARY
 je .zero_entrypoint_target
 cmp rbp,NEBOC_TARGET_KIND_TEST
 je .zero_entrypoint_target
 cmp qword [rsp+8],0
 jne .invalid_signature
 cmp qword [rsp+16],0
 jne .ambiguous
 cmp qword [rsp+24],0
 je .missing
 cmp qword [rsp+24],1
 ja .duplicate

 ; The unique valid record is selected deterministically.
 mov ecx,EP_CLASS_VALID
 call .find_two
 test rax,rax
 jz .internal
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_SYMBOL_ID]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_SELECTED_SYMBOL_ID],r9
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_MODULE_ID]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_SELECTED_MODULE_ID],r9
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_PRIMARY_MODULE_ID],r9
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_SOURCE_UNIT_ID]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_SELECTED_SOURCE_UNIT_ID],r9
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID],r9
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_AST_NODE_ID]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_SELECTED_AST_NODE_ID],r9
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_START]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_SELECTED_SPAN_START],r9
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START],r9
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_END]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_SELECTED_SPAN_END],r9
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END],r9
 xor eax,eax
 jmp .done

.zero_entrypoint_target:
 cmp qword [rsp],0
 je .ok
 mov dword [rbx+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_FORBIDDEN_FOR_TARGET
 mov ecx,EP_CLASS_ALL
 call .find_two
 jmp .publish_failure_pair
.missing:
 mov dword [rbx+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_MISSING
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.duplicate:
 mov dword [rbx+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_DUPLICATE
 mov ecx,EP_CLASS_VALID
 call .find_two
 jmp .publish_failure_pair
.invalid_signature:
 mov dword [rbx+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_INVALID_SIGNATURE
 mov ecx,EP_CLASS_INVALID
 call .find_two
 jmp .publish_failure_pair
.ambiguous:
 mov dword [rbx+NEBOC_ENTRYPOINT_RESULT_OUTCOME],NEBOC_ENTRYPOINT_OUTCOME_AMBIGUOUS
 mov ecx,EP_CLASS_AMBIGUOUS
 call .find_two
.publish_failure_pair:
 test rax,rax
 jz .internal
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_MODULE_ID]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_PRIMARY_MODULE_ID],r9
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_SOURCE_UNIT_ID]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID],r9
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_START]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START],r9
 mov r9,[rax+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_END]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END],r9
 test rdx,rdx
 jz .semantic_failure
 mov r9,[rdx+NEBOC_ENTRYPOINT_CANDIDATE_MODULE_ID]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_RELATED_MODULE_ID],r9
 mov r9,[rdx+NEBOC_ENTRYPOINT_CANDIDATE_SOURCE_UNIT_ID]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_RELATED_SOURCE_UNIT_ID],r9
 mov r9,[rdx+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_START]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_START],r9
 mov r9,[rdx+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_END]
 mov [rbx+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_END],r9
.semantic_failure:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.invalid_argument_no_result:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Classify one selected-target candidate. Structural invalidity precedes
; import ambiguity; diagnostics remain the responsibility of C03-F05.
.candidate_class:
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_MODULE_ID]
 test rax,rax
 jz .class_invalid
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_SOURCE_UNIT_ID]
 test rax,rax
 jz .class_invalid
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_AST_NODE_ID]
 test rax,rax
 jz .class_invalid
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_END]
 cmp rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_START]
 jbe .class_invalid
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_FLAGS]
 mov rdx,rax
 and rdx,~NEBOC_ENTRYPOINT_FLAG_KNOWN_MASK
 jnz .class_invalid
 test rax,NEBOC_ENTRYPOINT_FLAG_VALID_SIGNATURE
 jz .class_invalid
 cmp qword [rdi+NEBOC_ENTRYPOINT_CANDIDATE_SYMBOL_ID],NEBOC_ENTRYPOINT_RESERVED_SYMBOL_ID
 jne .class_invalid
 test rax,NEBOC_ENTRYPOINT_FLAG_IMPORTED | NEBOC_ENTRYPOINT_FLAG_REEXPORTED
 jnz .class_ambiguous
 test rax,NEBOC_ENTRYPOINT_FLAG_DIRECT_DECLARATION
 jz .class_invalid
 mov eax,EP_CLASS_VALID
 ret
.class_ambiguous:
 mov eax,EP_CLASS_AMBIGUOUS
 ret
.class_invalid:
 mov eax,EP_CLASS_INVALID
 ret

; Return the two lexicographically smallest matching records in rax/rdx.
; Ordering is module, source unit, span start/end, AST node, SymbolId and is
; independent of source discovery or linker order.
.find_two:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov r15,rcx
 xor ebx,ebx                     ; minimum
 xor ebp,ebp                     ; second minimum
 mov qword [rsp],0
.find_loop:
 mov rax,[rsp]
 cmp rax,r13
 jae .find_done
 mov r11,rax
 shl r11,6
 add r11,r12
 cmp [r11+NEBOC_ENTRYPOINT_CANDIDATE_TARGET_ID],r14
 jne .find_next
 mov [rsp+8],r11
 test r15,r15
 jz .find_accept
 mov rdi,r11
 call .candidate_class
 cmp rax,r15
 jne .find_next
.find_accept:
 mov r11,[rsp+8]
 test rbx,rbx
 jz .new_minimum
 mov rdi,r11
 mov rsi,rbx
 call .candidate_less
 test eax,eax
 jnz .replace_minimum
 test rbp,rbp
 jz .new_second
 mov rdi,[rsp+8]
 mov rsi,rbp
 call .candidate_less
 test eax,eax
 jz .find_next
.new_second:
 mov rbp,[rsp+8]
 jmp .find_next
.replace_minimum:
 mov rbp,rbx
.new_minimum:
 mov rbx,[rsp+8]
.find_next:
 inc qword [rsp]
 jmp .find_loop
.find_done:
 mov rax,rbx
 mov rdx,rbp
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

.candidate_less:
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_MODULE_ID]
 cmp rax,[rsi+NEBOC_ENTRYPOINT_CANDIDATE_MODULE_ID]
 jb .less
 ja .not_less
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_SOURCE_UNIT_ID]
 cmp rax,[rsi+NEBOC_ENTRYPOINT_CANDIDATE_SOURCE_UNIT_ID]
 jb .less
 ja .not_less
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_START]
 cmp rax,[rsi+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_START]
 jb .less
 ja .not_less
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_END]
 cmp rax,[rsi+NEBOC_ENTRYPOINT_CANDIDATE_SPAN_END]
 jb .less
 ja .not_less
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_AST_NODE_ID]
 cmp rax,[rsi+NEBOC_ENTRYPOINT_CANDIDATE_AST_NODE_ID]
 jb .less
 ja .not_less
 mov rax,[rdi+NEBOC_ENTRYPOINT_CANDIDATE_SYMBOL_ID]
 cmp rax,[rsi+NEBOC_ENTRYPOINT_CANDIDATE_SYMBOL_ID]
 jb .less
.not_less:
 xor eax,eax
 ret
.less:
 mov eax,1
 ret
