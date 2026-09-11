bits 64
default rel
%include "runtime/runtime_slicing.inc"
global _start
extern neboc_runtime_registry_component,neboc_runtime_registry_resolve
extern neboc_runtime_registry_dependency_closure,neboc_runtime_registry_explain
extern neboc_runtime_profile_minimal,neboc_runtime_profile_standard
extern neboc_runtime_profile_forbid,neboc_runtime_profile_require
extern neboc_runtime_profile_manifest,neboc_runtime_component_self_test
extern neboc_cli_build_runtime,neboc_cli_runtime_graph,neboc_host_process_exit
section .data
component_records:
 dq 1,1,10,1,NEBOC_RUNTIME_FLAG_BASE|NEBOC_RUNTIME_FLAG_SELF_TEST,64,1,1,100,0,0,0,0
 dq 2,1,20,1,NEBOC_RUNTIME_FLAG_STANDARD|NEBOC_RUNTIME_FLAG_SELF_TEST,96,1,1,101,0,0,0,0
 dq 3,2,30,1,NEBOC_RUNTIME_FLAG_SELF_TEST,128,0,0,102,0,0,0,0
 dq 4,1,40,2,NEBOC_RUNTIME_FLAG_STANDARD|NEBOC_RUNTIME_FLAG_SELF_TEST,256,1,1,103,0,0,0,0
dependencies: dq 2,1,3,2
bad_dependencies: dq 1,2
section .bss align=16
context: resb NEBOC_RUNTIME_CONTEXT_SIZE
storage: resb NEBOC_RUNTIME_COMPONENT_SIZE*NEBOC_RUNTIME_MAX_COMPONENTS
manifest: resb NEBOC_RUNTIME_MANIFEST_SIZE
minimal_manifest: resb NEBOC_RUNTIME_MANIFEST_SIZE
explanation: resb NEBOC_RUNTIME_EXPLANATION_SIZE
section .text
_start:
 sub rsp,8
 lea rax,[rel storage]
 mov [rel context+NEBOC_RUNTIME_CONTEXT_COMPONENTS_OFFSET],rax
 mov qword [rel context+NEBOC_RUNTIME_CONTEXT_CAPACITY_OFFSET],4
 lea rax,[rel dependencies]
 mov [rel context+NEBOC_RUNTIME_CONTEXT_DEPENDENCIES_OFFSET],rax
 mov qword [rel context+NEBOC_RUNTIME_CONTEXT_DEPENDENCY_COUNT_OFFSET],2
 mov qword [rel context+NEBOC_RUNTIME_CONTEXT_DEPENDENCY_CAPACITY_OFFSET],2
 mov qword [rel context+NEBOC_RUNTIME_CONTEXT_TARGET_OFFSET],1
 xor ebx,ebx
.register:
 cmp ebx,4
 jae .registered
 lea rdi,[rel context]
 imul rsi,rbx,NEBOC_RUNTIME_COMPONENT_SIZE
 lea rax,[rel component_records]
 add rsi,rax
 call neboc_runtime_registry_component
 test eax,eax
 jne .fail1
 inc ebx
 jmp .register
.registered:
 ; Duplicate registrations are rejected.
 lea rdi,[rel context]
 lea rsi,[rel component_records]
 call neboc_runtime_registry_component
 test eax,eax
 jz .fail2
 ; Component conformance preserves paired init/cleanup and diagnostics.
 lea rdi,[rel storage]
 call neboc_runtime_component_self_test
 test eax,eax
 jne .fail3
 ; Minimal includes base only.
 lea rdi,[rel context]
 call neboc_runtime_profile_minimal
 test eax,eax
 jne .fail4
 lea rdi,[rel context]
 lea rsi,[rel minimal_manifest]
 call neboc_runtime_profile_manifest
 test eax,eax
 jne .fail5
 cmp qword [rel minimal_manifest],1
 jne .fail6
 cmp qword [rel minimal_manifest+8],64
 jne .fail7
 ; Standard selects component 2 and its base dependency.
 lea rdi,[rel context]
 mov esi,NEBOC_RUNTIME_PROFILE_STANDARD
 call neboc_cli_build_runtime
 test eax,eax
 jne .fail8
 lea rdi,[rel context]
 lea rsi,[rel manifest]
 call neboc_cli_runtime_graph
 test eax,eax
 jne .fail9
 cmp qword [rel manifest],3
 jne .fail10
 cmp qword [rel manifest+8],416
 jne .fail11
 cmp qword [rel manifest+8],64
 jbe .fail12
 ; Explicit API resolution plus closure records the dependency cause.
 lea rdi,[rel context]
 call neboc_runtime_profile_minimal
 lea rdi,[rel context]
 mov esi,30
 mov edx,1
 mov ecx,NEBOC_RUNTIME_PROFILE_CUSTOM
 call neboc_runtime_registry_resolve
 test eax,eax
 jne .fail13
 lea rdi,[rel context]
 call neboc_runtime_registry_dependency_closure
 test eax,eax
 jne .fail14
 lea rdi,[rel context]
 mov esi,2
 lea rdx,[rel explanation]
 call neboc_runtime_registry_explain
 test eax,eax
 jne .fail15
 cmp qword [rel explanation],1
 jne .fail16
 cmp qword [rel explanation+8],3
 jne .fail17
 cmp qword [rel explanation+16],NEBOC_RUNTIME_REASON_DEPENDENCY
 jne .fail18
 ; A source-required forbidden component fails without a partial selection.
 lea rdi,[rel context]
 call neboc_runtime_profile_minimal
 lea rdi,[rel context]
 mov esi,3
 call neboc_runtime_profile_forbid
 test eax,eax
 jne .fail19
 lea rdi,[rel context]
 mov esi,3
 call neboc_runtime_profile_require
 test eax,eax
 jz .fail20
 ; Target mismatch is not mislabeled as source absence.
 lea rdi,[rel context]
 mov esi,40
 mov edx,1
 mov ecx,NEBOC_RUNTIME_PROFILE_CUSTOM
 call neboc_runtime_registry_resolve
 cmp eax,6
 jne .fail21
 ; Canonical topological-id violation rejects a potential cycle deterministically.
 lea rax,[rel bad_dependencies]
 mov [rel context+NEBOC_RUNTIME_CONTEXT_DEPENDENCIES_OFFSET],rax
 mov qword [rel context+NEBOC_RUNTIME_CONTEXT_DEPENDENCY_COUNT_OFFSET],1
 mov qword [rel context+NEBOC_RUNTIME_CONTEXT_DEPENDENCY_CAPACITY_OFFSET],1
 lea rdi,[rel context]
 call neboc_runtime_registry_dependency_closure
 test eax,eax
 jz .fail22
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 22
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
