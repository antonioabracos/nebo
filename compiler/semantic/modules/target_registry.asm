; C03-F02-A1 exact TargetId registry selection.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/target_registry.inc"

section .text

; target_registry_select(manifest*, selector*, selector_len) -> status.
NEBOC_ABI_FUNCTION neboc_target_registry_select
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid
 test rbx,7
 jnz .invalid
 mov qword [rbx+NEBOC_TARGET_MANIFEST_SELECTED_INDEX],-1
 mov qword [rbx+NEBOC_TARGET_MANIFEST_ERROR],NEBOC_TARGET_MANIFEST_ERROR_NONE
 mov r14,[rbx+NEBOC_TARGET_MANIFEST_COUNT]
 test r14,r14
 jz .invalid
 cmp r14,NEBOC_TARGET_MANIFEST_MAX_TARGETS
 ja .invalid
 mov r15,[rbx+NEBOC_TARGET_MANIFEST_RECORDS]
 test r15,r15
 jz .invalid

 test r13,r13
 jz .without_explicit
 test r12,r12
 jz .invalid_id
 mov rdi,r12
 mov rsi,r13
 call .validate_id
 test eax,eax
 jz .invalid_id
 jmp .find
.without_explicit:
 test r12,r12
 jnz .invalid
 mov r12,[rbx+NEBOC_TARGET_MANIFEST_DEFAULT_PTR]
 mov r13,[rbx+NEBOC_TARGET_MANIFEST_DEFAULT_LEN]
 test r13,r13
 jnz .find_default
 cmp r14,1
 jne .selection_required
 mov qword [rbx+NEBOC_TARGET_MANIFEST_SELECTED_INDEX],0
 xor eax,eax
 jmp .done

.find_default:
 xor ebp,ebp
.find_default_loop:
 cmp rbp,r14
 jae .default_unknown
 mov rax,rbp
 imul rax,NEBOC_TARGET_RECORD_SIZE
 add rax,r15
 cmp [rax+NEBOC_TARGET_RECORD_ID_LEN],r13
 jne .find_default_next
 mov rdi,[rax+NEBOC_TARGET_RECORD_ID_PTR]
 mov rsi,r12
 mov rcx,r13
 call .equal
 test eax,eax
 jnz .selected
.find_default_next:
 inc rbp
 jmp .find_default_loop

.find:
 xor ebp,ebp
.find_loop:
 cmp rbp,r14
 jae .unknown
 mov rax,rbp
 imul rax,NEBOC_TARGET_RECORD_SIZE
 add rax,r15
 cmp [rax+NEBOC_TARGET_RECORD_ID_LEN],r13
 jne .find_next
 mov rdi,[rax+NEBOC_TARGET_RECORD_ID_PTR]
 mov rsi,r12
 mov rcx,r13
 call .equal
 test eax,eax
 jnz .selected
.find_next:
 inc rbp
 jmp .find_loop
.selected:
 mov [rbx+NEBOC_TARGET_MANIFEST_SELECTED_INDEX],rbp
 xor eax,eax
 jmp .done
.invalid_id:
 mov qword [rbx+NEBOC_TARGET_MANIFEST_ERROR],NEBOC_TARGET_MANIFEST_ERROR_ID
 jmp .source
.unknown:
 mov qword [rbx+NEBOC_TARGET_MANIFEST_ERROR],NEBOC_TARGET_MANIFEST_ERROR_UNKNOWN_TARGET
 jmp .source
.default_unknown:
 mov qword [rbx+NEBOC_TARGET_MANIFEST_ERROR],NEBOC_TARGET_MANIFEST_ERROR_DEFAULT_UNKNOWN
 jmp .source
.selection_required:
 mov qword [rbx+NEBOC_TARGET_MANIFEST_ERROR],NEBOC_TARGET_MANIFEST_ERROR_SELECTION_REQUIRED
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

.equal:
 xor edx,edx
.equal_loop:
 cmp rdx,rcx
 jae .yes
 mov al,[rdi+rdx]
 cmp al,[rsi+rdx]
 jne .no
 inc rdx
 jmp .equal_loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

.validate_id:
 test rsi,rsi
 jz .no
 cmp rsi,NEBOC_TARGET_ID_MAX_BYTES
 ja .no
 xor ecx,ecx
 mov r8d,1
.id_loop:
 cmp rcx,rsi
 jae .id_end
 movzx eax,byte [rdi+rcx]
 cmp al,'a'
 jb .not_lower
 cmp al,'z'
 jbe .lower
.not_lower:
 test r8d,r8d
 jnz .no
 cmp al,'0'
 jb .hyphen
 cmp al,'9'
 jbe .id_next
.hyphen:
 cmp al,'-'
 jne .no
 mov r8d,1
 inc rcx
 jmp .id_loop
.lower:
 xor r8d,r8d
.id_next:
 inc rcx
 jmp .id_loop
.id_end:
 test r8d,r8d
 jnz .no
 mov eax,1
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
