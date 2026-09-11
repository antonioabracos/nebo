bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/warning_config.inc"

global _start
extern neboc_diagnostic_new
extern neboc_warning_policy_new
extern neboc_warning_policy_set
extern neboc_warning_config_new
extern neboc_warning_config_set_layer
extern neboc_warning_config_resolve
extern neboc_host_process_exit

section .rodata
warning_id: db "NEBO-W0001"
warning_id_len equ $-warning_id
unknown_id: db "NEBO-W9999"
warning_key: db "diagnostic.compatibility.warning"
warning_key_len equ $-warning_key

section .data
warning_request:
 dq warning_id,warning_id_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq warning_key,warning_key_len
 dq 0,0,0

section .bss
warning: resb NEBOC_DIAGNOSTIC_SIZE
config: resb NEBOC_WARNING_CONFIG_SIZE
workspace: resb NEBOC_WARNING_POLICY_SIZE
package: resb NEBOC_WARNING_POLICY_SIZE
module: resb NEBOC_WARNING_POLICY_SIZE
source: resb NEBOC_WARNING_POLICY_SIZE
cli: resb NEBOC_WARNING_POLICY_SIZE
empty: resb NEBOC_WARNING_POLICY_SIZE
workspace_rules: resb NEBOC_WARNING_RULE_SIZE*2
package_rules: resb NEBOC_WARNING_RULE_SIZE*2
module_rules: resb NEBOC_WARNING_RULE_SIZE*2
source_rules: resb NEBOC_WARNING_RULE_SIZE*2
cli_rules: resb NEBOC_WARNING_RULE_SIZE*2
empty_rules: resb NEBOC_WARNING_RULE_SIZE*2
resolution: resb NEBOC_WARNING_CONFIG_RESOLUTION_SIZE

section .text
_start:
 lea rdi,[rel warning]
 lea rsi,[rel warning_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail1

 lea rdi,[rel workspace]
 lea rsi,[rel workspace_rules]
 mov edx,2
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail2
 lea rdi,[rel package]
 lea rsi,[rel package_rules]
 mov edx,2
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail3
 lea rdi,[rel module]
 lea rsi,[rel module_rules]
 mov edx,2
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail4
 lea rdi,[rel source]
 lea rsi,[rel source_rules]
 mov edx,2
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail5
 lea rdi,[rel cli]
 lea rsi,[rel cli_rules]
 mov edx,2
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail6
 lea rdi,[rel empty]
 lea rsi,[rel empty_rules]
 mov edx,2
 mov ecx,NEBOC_WARNING_LEVEL_ALLOW
 call neboc_warning_policy_new
 test eax,eax
 jne .fail7

 lea rdi,[rel workspace]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_set
 test eax,eax
 jne .fail8
 lea rdi,[rel package]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 mov ecx,NEBOC_WARNING_LEVEL_DENY
 call neboc_warning_policy_set
 test eax,eax
 jne .fail9
 lea rdi,[rel module]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_set
 test eax,eax
 jne .fail10
 lea rdi,[rel source]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 mov ecx,NEBOC_WARNING_LEVEL_ALLOW
 call neboc_warning_policy_set
 test eax,eax
 jne .fail11
 lea rdi,[rel cli]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 mov ecx,NEBOC_WARNING_LEVEL_DENY
 call neboc_warning_policy_set
 test eax,eax
 jne .fail12

 ; All layers: CLI is the deterministic winner.
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_PROFILE_DEVELOPMENT
 call neboc_warning_config_new
 test eax,eax
 jne .fail13
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_WORKSPACE
 lea rdx,[rel workspace]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail14
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_PACKAGE
 lea rdx,[rel package]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail15
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_MODULE
 lea rdx,[rel module]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail16
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_SOURCE
 lea rdx,[rel source]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail17
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_CLI
 lea rdx,[rel cli]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail18
 lea rdi,[rel config]
 lea rsi,[rel warning]
 lea rdx,[rel resolution]
 call neboc_warning_config_resolve
 test eax,eax
 jne .fail19
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_DENY
 jne .fail20
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_ORIGIN_OFFSET],NEBOC_WARNING_CONFIG_LAYER_CLI
 jne .fail21

 ; Duplicate layers fail closed.
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_CLI
 lea rdx,[rel cli]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail22

 ; Empty layer defaults are opt-in; otherwise the registry default survives.
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_PROFILE_DEVELOPMENT
 call neboc_warning_config_new
 test eax,eax
 jne .fail23
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_SOURCE
 lea rdx,[rel empty]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail24
 lea rdi,[rel config]
 lea rsi,[rel warning]
 lea rdx,[rel resolution]
 call neboc_warning_config_resolve
 test eax,eax
 jne .fail25
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_WARN
 jne .fail26
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_ORIGIN_OFFSET],NEBOC_WARNING_CONFIG_ORIGIN_REGISTRY
 jne .fail27
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_PROFILE_DEVELOPMENT
 call neboc_warning_config_new
 test eax,eax
 jne .fail28
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_SOURCE
 lea rdx,[rel empty]
 mov ecx,1
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail29
 lea rdi,[rel config]
 lea rsi,[rel warning]
 lea rdx,[rel resolution]
 call neboc_warning_config_resolve
 test eax,eax
 jne .fail30
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_ALLOW
 jne .fail31
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_USED_DEFAULT_OFFSET],1
 jne .fail32

 ; CI profile promotes a registry-default warn to deny.
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_PROFILE_CI
 call neboc_warning_config_new
 test eax,eax
 jne .fail33
 lea rdi,[rel config]
 lea rsi,[rel warning]
 lea rdx,[rel resolution]
 call neboc_warning_config_resolve
 test eax,eax
 jne .fail34
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_DENY
 jne .fail35

 ; Workspace forbid cannot be lowered by the highest-precedence CLI layer.
 lea rdi,[rel workspace]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 mov ecx,NEBOC_WARNING_LEVEL_FORBID
 call neboc_warning_policy_set
 test eax,eax
 jne .fail36
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_PROFILE_DEVELOPMENT
 call neboc_warning_config_new
 test eax,eax
 jne .fail37
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_WORKSPACE
 lea rdx,[rel workspace]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail38
 lea rdi,[rel config]
 mov esi,NEBOC_WARNING_CONFIG_LAYER_CLI
 lea rdx,[rel source]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 test eax,eax
 jne .fail39
 lea rdi,[rel config]
 lea rsi,[rel warning]
 lea rdx,[rel resolution]
 call neboc_warning_config_resolve
 test eax,eax
 jne .fail40
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_FORBID
 jne .fail41
 cmp qword [rel resolution+NEBOC_WARNING_CONFIG_RESOLUTION_ORIGIN_OFFSET],NEBOC_WARNING_CONFIG_LAYER_WORKSPACE
 jne .fail42

 ; Unknown profile/layer and unregistered diagnostic identity fail closed.
 lea rdi,[rel config]
 mov esi,3
 call neboc_warning_config_new
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail43
 lea rdi,[rel config]
 mov esi,6
 lea rdx,[rel source]
 xor ecx,ecx
 call neboc_warning_config_set_layer
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail44
 lea rax,[rel unknown_id]
 mov [rel warning+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],rax
 lea rdi,[rel config]
 lea rsi,[rel warning]
 lea rdx,[rel resolution]
 call neboc_warning_config_resolve
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail45

 xor edi,edi
 call neboc_host_process_exit

%assign n 1
%rep 45
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
