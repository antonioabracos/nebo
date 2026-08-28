bits 64
default rel
%include "runtime/runtime_slicing.inc"
global _start
extern neboc_runtime_registry_component,neboc_cli_build_runtime
extern neboc_runtime_profile_manifest,neboc_host_process_exit
section .data
component: dq 1,1,10,1,NEBOC_RUNTIME_FLAG_BASE,64,1,1,100,0,0,0,0
section .bss align=16
context: resb NEBOC_RUNTIME_CONTEXT_SIZE
storage: resb NEBOC_RUNTIME_COMPONENT_SIZE
manifest: resb NEBOC_RUNTIME_MANIFEST_SIZE
section .text
_start:
 sub rsp,8
 lea rax,[rel storage]
 mov [rel context],rax
 mov qword [rel context+16],1
 lea rdi,[rel context]
 lea rsi,[rel component]
 call neboc_runtime_registry_component
 test eax,eax
 jne .done
 lea rdi,[rel context]
 mov esi,NEBOC_RUNTIME_PROFILE_MINIMAL
 call neboc_cli_build_runtime
 test eax,eax
 jne .done
 lea rdi,[rel context]
 lea rsi,[rel manifest]
 call neboc_runtime_profile_manifest
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
