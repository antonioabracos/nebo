; RUNTIME-SLICING-F04 bounded capability-driven runtime slicing model.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/runtime_slicing.inc"

section .text

; rdi=context, rsi=id. Returns component pointer in rax, zero when absent.
find_component:
 mov r8,[rdi+NEBOC_RUNTIME_CONTEXT_COMPONENTS_OFFSET]
 xor r9d,r9d
.find_loop:
 cmp r9,[rdi+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 jae .find_absent
 cmp [r8+NEBOC_RUNTIME_COMPONENT_ID_OFFSET],rsi
 je .find_found
 add r8,NEBOC_RUNTIME_COMPONENT_SIZE
 inc r9
 jmp .find_loop
.find_found:
 mov rax,r8
 ret
.find_absent:
 xor eax,eax
 ret

; rdi=context, rsi=component pointer, rdx=reason, rcx=parent id.
select_component:
 mov rax,[rsi+NEBOC_RUNTIME_COMPONENT_ID_OFFSET]
 cmp rax,[rdi+NEBOC_RUNTIME_CONTEXT_FORBIDDEN_OFFSET]
 je .select_forbidden
 cmp qword [rsi+NEBOC_RUNTIME_COMPONENT_SELECTED_OFFSET],0
 jne .select_ok
 mov qword [rsi+NEBOC_RUNTIME_COMPONENT_SELECTED_OFFSET],1
 mov [rsi+NEBOC_RUNTIME_COMPONENT_REASON_OFFSET],rdx
 mov [rsi+NEBOC_RUNTIME_COMPONENT_PARENT_OFFSET],rcx
 inc qword [rdi+NEBOC_RUNTIME_CONTEXT_SELECTED_COUNT_OFFSET]
 mov rax,[rsi+NEBOC_RUNTIME_COMPONENT_BYTES_OFFSET]
 add [rdi+NEBOC_RUNTIME_CONTEXT_SELECTED_BYTES_OFFSET],rax
.select_ok:
 xor eax,eax
 ret
.select_forbidden:
 mov [rdi+NEBOC_RUNTIME_CONTEXT_LAST_COMPONENT_OFFSET],rax
 mov [rdi+NEBOC_RUNTIME_CONTEXT_LAST_REASON_OFFSET],rdx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; rdi=context. Clear selection state and summary.
reset_selection:
 mov r8,[rdi+NEBOC_RUNTIME_CONTEXT_COMPONENTS_OFFSET]
 xor r9d,r9d
.reset_loop:
 cmp r9,[rdi+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 jae .reset_done
 mov qword [r8+NEBOC_RUNTIME_COMPONENT_SELECTED_OFFSET],0
 mov qword [r8+NEBOC_RUNTIME_COMPONENT_PARENT_OFFSET],0
 mov qword [r8+NEBOC_RUNTIME_COMPONENT_REASON_OFFSET],0
 add r8,NEBOC_RUNTIME_COMPONENT_SIZE
 inc r9
 jmp .reset_loop
.reset_done:
 mov qword [rdi+NEBOC_RUNTIME_CONTEXT_SELECTED_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_RUNTIME_CONTEXT_SELECTED_BYTES_OFFSET],0
 mov qword [rdi+NEBOC_RUNTIME_CONTEXT_LAST_REASON_OFFSET],0
 mov qword [rdi+NEBOC_RUNTIME_CONTEXT_LAST_COMPONENT_OFFSET],0
 ret

NEBOC_ABI_FUNCTION neboc_runtime_registry_component
 ; rdi=context, rsi=caller-owned component record.
 test rdi,rdi
 jz .component_invalid
 test rsi,rsi
 jz .component_invalid
 cmp qword [rsi+NEBOC_RUNTIME_COMPONENT_ID_OFFSET],0
 je .component_invalid
 cmp qword [rsi+NEBOC_RUNTIME_COMPONENT_VERSION_OFFSET],0
 je .component_invalid
 mov rax,[rdi+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_RUNTIME_CONTEXT_CAPACITY_OFFSET]
 jae .component_limit
 cmp rax,NEBOC_RUNTIME_MAX_COMPONENTS
 jae .component_limit
 push rbx
 mov rbx,rsi
 mov rsi,[rbx+NEBOC_RUNTIME_COMPONENT_ID_OFFSET]
 call find_component
 test rax,rax
 jnz .component_duplicate
 mov rax,[rdi+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 imul rax,NEBOC_RUNTIME_COMPONENT_SIZE
 add rax,[rdi+NEBOC_RUNTIME_CONTEXT_COMPONENTS_OFFSET]
 mov rdx,rax
 mov rsi,rbx
 mov ecx,NEBOC_RUNTIME_COMPONENT_SIZE/8
.component_copy:
 mov rax,[rsi]
 mov [rdx],rax
 add rsi,8
 add rdx,8
 loop .component_copy
 inc qword [rdi+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 pop rbx
 xor eax,eax
 ret
.component_duplicate:
 pop rbx
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.component_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.component_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_registry_resolve
 ; rdi=context rsi=api token rdx=target bit rcx=profile.
 test rdi,rdi
 jz .resolve_invalid
 test rsi,rsi
 jz .resolve_invalid
 test rdx,rdx
 jz .resolve_invalid
 mov r8,[rdi+NEBOC_RUNTIME_CONTEXT_COMPONENTS_OFFSET]
 xor r9d,r9d
 xor r10d,r10d
.resolve_loop:
 cmp r9,[rdi+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 jae .resolve_absent
 cmp [r8+NEBOC_RUNTIME_COMPONENT_API_OFFSET],rsi
 jne .resolve_next
 mov r10d,1
 mov rax,[r8+NEBOC_RUNTIME_COMPONENT_TARGET_OFFSET]
 test rax,rdx
 jz .resolve_next
 mov [rdi+NEBOC_RUNTIME_CONTEXT_PROFILE_OFFSET],rcx
 mov [rdi+NEBOC_RUNTIME_CONTEXT_TARGET_OFFSET],rdx
 push rbx
 mov rbx,rdi
 mov rsi,r8
 mov edx,NEBOC_RUNTIME_REASON_API
 xor ecx,ecx
 call select_component
 pop rbx
 ret
.resolve_next:
 add r8,NEBOC_RUNTIME_COMPONENT_SIZE
 inc r9
 jmp .resolve_loop
.resolve_absent:
 test r10d,r10d
 jnz .resolve_target
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.resolve_target:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.resolve_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_registry_dependency_closure
 ; Dependencies use canonical topological ids: from_id must be greater than to_id.
 test rdi,rdi
 jz .closure_invalid
 mov rax,[rdi+NEBOC_RUNTIME_CONTEXT_DEPENDENCY_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_RUNTIME_CONTEXT_DEPENDENCY_CAPACITY_OFFSET]
 ja .closure_limit
 cmp rax,NEBOC_RUNTIME_MAX_DEPENDENCIES
 ja .closure_limit
 push rbx
 push r12
 push r13
 sub rsp,8
 mov rbx,rdi
 xor r12d,r12d
.closure_pass:
 cmp r12,[rbx+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 jae .closure_done
 mov r13,[rbx+NEBOC_RUNTIME_CONTEXT_DEPENDENCIES_OFFSET]
 xor r11d,r11d
.closure_dep:
 cmp r11,[rbx+NEBOC_RUNTIME_CONTEXT_DEPENDENCY_COUNT_OFFSET]
 jae .closure_next_pass
 mov rax,[r13+NEBOC_RUNTIME_DEPENDENCY_FROM_OFFSET]
 mov rdx,[r13+NEBOC_RUNTIME_DEPENDENCY_TO_OFFSET]
 cmp rax,rdx
 jbe .closure_cycle
 mov rdi,rbx
 mov rsi,rax
 call find_component
 test rax,rax
 jz .closure_bad_source
 cmp qword [rax+NEBOC_RUNTIME_COMPONENT_SELECTED_OFFSET],0
 je .closure_next_dep
 mov rcx,[rax+NEBOC_RUNTIME_COMPONENT_ID_OFFSET]
 mov rdi,rbx
 mov rsi,[r13+NEBOC_RUNTIME_DEPENDENCY_TO_OFFSET]
 call find_component
 test rax,rax
 jz .closure_bad_source
 mov rdi,rbx
 mov rsi,rax
 mov edx,NEBOC_RUNTIME_REASON_DEPENDENCY
 call select_component
 test eax,eax
 jne .closure_return
.closure_next_dep:
 add r13,NEBOC_RUNTIME_DEPENDENCY_SIZE
 inc r11
 jmp .closure_dep
.closure_next_pass:
 inc r12
 jmp .closure_pass
.closure_done:
 xor eax,eax
.closure_return:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret
.closure_cycle:
 mov qword [rbx+NEBOC_RUNTIME_CONTEXT_LAST_REASON_OFFSET],NEBOC_RUNTIME_REASON_DEPENDENCY
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .closure_return
.closure_bad_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .closure_return
.closure_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.closure_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_registry_explain
 ; rdi=context rsi=component id rdx=3-qword output.
 test rdi,rdi
 jz .explain_invalid
 test rdx,rdx
 jz .explain_invalid
 push rbx
 mov rbx,rdx
 call find_component
 test rax,rax
 jz .explain_absent
 mov rcx,[rax+NEBOC_RUNTIME_COMPONENT_SELECTED_OFFSET]
 mov [rbx],rcx
 mov rcx,[rax+NEBOC_RUNTIME_COMPONENT_PARENT_OFFSET]
 mov [rbx+8],rcx
 mov rcx,[rax+NEBOC_RUNTIME_COMPONENT_REASON_OFFSET]
 mov [rbx+16],rcx
 pop rbx
 xor eax,eax
 ret
.explain_absent:
 pop rbx
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.explain_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_profile_minimal
 test rdi,rdi
 jz .minimal_invalid
 push rbx
 mov rbx,rdi
 call reset_selection
 mov qword [rbx+NEBOC_RUNTIME_CONTEXT_PROFILE_OFFSET],NEBOC_RUNTIME_PROFILE_MINIMAL
 mov r8,[rbx+NEBOC_RUNTIME_CONTEXT_COMPONENTS_OFFSET]
 xor r9d,r9d
.minimal_loop:
 cmp r9,[rbx+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 jae .minimal_done
 test qword [r8+NEBOC_RUNTIME_COMPONENT_FLAGS_OFFSET],NEBOC_RUNTIME_FLAG_BASE
 jz .minimal_next
 mov rdi,rbx
 mov rsi,r8
 mov edx,NEBOC_RUNTIME_REASON_BASE
 xor ecx,ecx
 call select_component
 test eax,eax
 jne .minimal_return
.minimal_next:
 add r8,NEBOC_RUNTIME_COMPONENT_SIZE
 inc r9
 jmp .minimal_loop
.minimal_done:
 mov rdi,rbx
 call neboc_runtime_registry_dependency_closure
.minimal_return:
 pop rbx
 ret
.minimal_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_profile_standard
 test rdi,rdi
 jz .standard_invalid
 push rbx
 mov rbx,rdi
 call reset_selection
 mov qword [rbx+NEBOC_RUNTIME_CONTEXT_PROFILE_OFFSET],NEBOC_RUNTIME_PROFILE_STANDARD
 mov r8,[rbx+NEBOC_RUNTIME_CONTEXT_COMPONENTS_OFFSET]
 xor r9d,r9d
.standard_loop:
 cmp r9,[rbx+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 jae .standard_done
 test qword [r8+NEBOC_RUNTIME_COMPONENT_FLAGS_OFFSET],NEBOC_RUNTIME_FLAG_BASE|NEBOC_RUNTIME_FLAG_STANDARD
 jz .standard_next
 mov rdi,rbx
 mov rsi,r8
 mov edx,NEBOC_RUNTIME_REASON_STANDARD
 xor ecx,ecx
 call select_component
 test eax,eax
 jne .standard_return
.standard_next:
 add r8,NEBOC_RUNTIME_COMPONENT_SIZE
 inc r9
 jmp .standard_loop
.standard_done:
 mov rdi,rbx
 call neboc_runtime_registry_dependency_closure
.standard_return:
 pop rbx
 ret
.standard_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_profile_forbid
 test rdi,rdi
 jz .forbid_invalid
 test rsi,rsi
 jz .forbid_invalid
 push rbx
 mov rbx,rdi
 call find_component
 test rax,rax
 jz .forbid_absent
 cmp qword [rax+NEBOC_RUNTIME_COMPONENT_SELECTED_OFFSET],0
 jne .forbid_required
 mov [rbx+NEBOC_RUNTIME_CONTEXT_FORBIDDEN_OFFSET],rsi
 pop rbx
 xor eax,eax
 ret
.forbid_required:
 pop rbx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.forbid_absent:
 pop rbx
.forbid_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_profile_require
 test rdi,rdi
 jz .require_invalid
 test rsi,rsi
 jz .require_invalid
 push rbx
 mov rbx,rdi
 call find_component
 test rax,rax
 jz .require_absent
 mov rdi,rbx
 mov rsi,rax
 mov edx,NEBOC_RUNTIME_REASON_ROOT
 xor ecx,ecx
 call select_component
 test eax,eax
 jne .require_return
 mov rdi,rbx
 call neboc_runtime_registry_dependency_closure
.require_return:
 pop rbx
 ret
.require_absent:
 pop rbx
.require_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_profile_manifest
 ; rdi=context rsi=4-qword output.
 test rdi,rdi
 jz .manifest_invalid
 test rsi,rsi
 jz .manifest_invalid
 mov rax,[rdi+NEBOC_RUNTIME_CONTEXT_SELECTED_COUNT_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_RUNTIME_CONTEXT_SELECTED_BYTES_OFFSET]
 mov [rsi+8],rax
 mov r8,[rdi+NEBOC_RUNTIME_CONTEXT_COMPONENTS_OFFSET]
 xor r9d,r9d
 mov rax,1469598103934665603
.manifest_loop:
 cmp r9,[rdi+NEBOC_RUNTIME_CONTEXT_COUNT_OFFSET]
 jae .manifest_done
 cmp qword [r8+NEBOC_RUNTIME_COMPONENT_SELECTED_OFFSET],0
 je .manifest_next
 xor rax,[r8+NEBOC_RUNTIME_COMPONENT_ID_OFFSET]
 mov r10,1099511628211
 imul rax,r10
 xor rax,[r8+NEBOC_RUNTIME_COMPONENT_VERSION_OFFSET]
 imul rax,r10
.manifest_next:
 add r8,NEBOC_RUNTIME_COMPONENT_SIZE
 inc r9
 jmp .manifest_loop
.manifest_done:
 mov [rdi+NEBOC_RUNTIME_CONTEXT_MANIFEST_OFFSET],rax
 mov [rsi+16],rax
 mov rax,[rdi+NEBOC_RUNTIME_CONTEXT_PROFILE_OFFSET]
 mov [rsi+24],rax
 xor eax,eax
 ret
.manifest_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_runtime_component_self_test
 ; rdi=component record. Init and cleanup must be paired; diagnostics are mandatory.
 test rdi,rdi
 jz .self_invalid
 cmp qword [rdi+NEBOC_RUNTIME_COMPONENT_ID_OFFSET],0
 je .self_invalid
 cmp qword [rdi+NEBOC_RUNTIME_COMPONENT_VERSION_OFFSET],0
 je .self_invalid
 cmp qword [rdi+NEBOC_RUNTIME_COMPONENT_BYTES_OFFSET],0
 je .self_invalid
 cmp qword [rdi+NEBOC_RUNTIME_COMPONENT_DIAGNOSTIC_OFFSET],0
 je .self_invalid
 mov rax,[rdi+NEBOC_RUNTIME_COMPONENT_INIT_OFFSET]
 mov rdx,[rdi+NEBOC_RUNTIME_COMPONENT_CLEANUP_OFFSET]
 test rax,rax
 setnz al
 test rdx,rdx
 setnz dl
 cmp al,dl
 jne .self_invalid_source
 mov qword [rdi+NEBOC_RUNTIME_COMPONENT_SELF_TEST_OFFSET],1
 xor eax,eax
 ret
.self_invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.self_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_build_runtime
 ; rdi=context rsi=profile selector.
 cmp rsi,NEBOC_RUNTIME_PROFILE_MINIMAL
 je neboc_runtime_profile_minimal
 cmp rsi,NEBOC_RUNTIME_PROFILE_STANDARD
 je neboc_runtime_profile_standard
 cmp rsi,NEBOC_RUNTIME_PROFILE_CUSTOM
 jne .cli_invalid
 test rdi,rdi
 jz .cli_invalid
 mov qword [rdi+NEBOC_RUNTIME_CONTEXT_PROFILE_OFFSET],NEBOC_RUNTIME_PROFILE_CUSTOM
 jmp neboc_runtime_registry_dependency_closure
.cli_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_runtime_graph
 ; Bounded graph output is the stable manifest tuple.
 jmp neboc_runtime_profile_manifest

section .note.GNU-stack noalloc noexec nowrite progbits
