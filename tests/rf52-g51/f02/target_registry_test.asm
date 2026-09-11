bits 64
default rel
%include "compiler/target/target_registry.inc"
global _start
extern neboc_target_registry_load,neboc_target_registry_get,neboc_target_descriptor_data_layout
extern neboc_target_calling_convention,neboc_target_object_format,neboc_target_executable_format
extern neboc_target_syscall_model,neboc_target_cpu_baseline,neboc_target_optional_features
extern neboc_target_capabilities,neboc_target_validate_feature_set,neboc_cli_targets
extern neboc_cli_target_report,neboc_host_process_exit
section .data
targets:
 dq 1,1,1,64,16,1,1,1,1,1,3,0x1f,3
 dq 2,1,1,64,16,2,1,1,1,2,1,0x07,1
registry: dq 0,0,0
section .bss align=16
target_ptr: resq 1
out: resq 13
section .text
_start:
 sub rsp,8
 lea rdi,[rel registry]
 lea rsi,[rel targets]
 mov edx,2
 mov ecx,1
 call neboc_target_registry_load
 test eax,eax
 jne .fail1
 lea rdi,[rel registry]
 mov esi,1
 lea rdx,[rel target_ptr]
 call neboc_target_registry_get
 test eax,eax
 jne .fail2
 mov rbx,[rel target_ptr]
%macro GET 2
 mov rdi,rbx
 lea rsi,[rel out]
 call %1
 test eax,eax
 jne .fail%2
%endmacro
GET neboc_target_descriptor_data_layout,3
cmp qword [rel out+8],64
jne .fail4
GET neboc_target_calling_convention,5
GET neboc_target_object_format,6
GET neboc_target_executable_format,7
GET neboc_target_syscall_model,8
GET neboc_target_cpu_baseline,9
GET neboc_target_optional_features,10
GET neboc_target_capabilities,11
mov rdi,rbx
mov esi,3
call neboc_target_validate_feature_set
test eax,eax
jne .fail12
mov rdi,rbx
mov esi,0x80
call neboc_target_validate_feature_set
test eax,eax
jz .fail13
lea rdi,[rel registry]
lea rsi,[rel out]
call neboc_cli_targets
cmp qword [rel out],2
jne .fail14
mov rdi,rbx
lea rsi,[rel out]
call neboc_cli_target_report
test eax,eax
jne .fail15
cmp qword [rel out+NEBOC_TARGET_MATURITY_OFFSET],3
jne .fail16
lea rdi,[rel registry]
mov esi,99
lea rdx,[rel target_ptr]
call neboc_target_registry_get
cmp eax,6
jne .fail17
xor edi,edi
call neboc_host_process_exit
%assign n 1
%rep 17
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
