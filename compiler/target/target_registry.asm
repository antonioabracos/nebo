; TARGET-REGISTRY-F02 bounded local target registry and DataLayout.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/target_registry.inc"
section .text
NEBOC_ABI_FUNCTION neboc_target_registry_load
 ; rdi=registry rsi=packs rdx=count rcx=policy.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_TARGET_MAX
 ja .limit
 test rcx,rcx
 jz .invalid
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_target_registry_get
 ; rdi=registry rsi=triple token rdx=descriptor ptr output.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov r8,[rdi]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+8]
 jae .unsupported
 cmp [r8+NEBOC_TARGET_TRIPLE_OFFSET],rsi
 je .found
 add r8,NEBOC_TARGET_SIZE
 inc r9
 jmp .loop
.found: mov [rdx],r8
 xor eax,eax
 ret
.unsupported: mov qword [rdx],0
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%macro TARGET_GETTER 2
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 mov rax,[rdi+%2]
 mov [rsi],rax
%if %2 = NEBOC_TARGET_ENDIAN_OFFSET
 mov rax,[rdi+NEBOC_TARGET_POINTER_OFFSET]
 mov [rsi+8],rax
 mov rax,[rdi+NEBOC_TARGET_ALIGNMENT_OFFSET]
 mov [rsi+16],rax
%endif
 xor eax,eax
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
TARGET_GETTER neboc_target_descriptor_data_layout,NEBOC_TARGET_ENDIAN_OFFSET
TARGET_GETTER neboc_target_calling_convention,NEBOC_TARGET_CALLING_OFFSET
TARGET_GETTER neboc_target_object_format,NEBOC_TARGET_OBJECT_OFFSET
TARGET_GETTER neboc_target_executable_format,NEBOC_TARGET_EXECUTABLE_OFFSET
TARGET_GETTER neboc_target_syscall_model,NEBOC_TARGET_SYSCALL_OFFSET
TARGET_GETTER neboc_target_cpu_baseline,NEBOC_TARGET_CPU_OFFSET
TARGET_GETTER neboc_target_optional_features,NEBOC_TARGET_FEATURES_OFFSET
TARGET_GETTER neboc_target_capabilities,NEBOC_TARGET_CAPABILITIES_OFFSET
NEBOC_ABI_FUNCTION neboc_target_validate_feature_set
 ; rdi=descriptor rsi=requested mask.
 test rdi,rdi
 jz .invalid
 mov rax,rsi
 not rax
 and rax,[rdi+NEBOC_TARGET_CPU_OFFSET]
 test rax,rax
 jnz .source
 mov rax,rsi
 not rax
 and rax,[rdi+NEBOC_TARGET_FEATURES_OFFSET]
 ; Required CPU baseline is always included; requested optional subset must be known.
 mov rax,rsi
 mov rdx,[rdi+NEBOC_TARGET_CPU_OFFSET]
 or rdx,[rdi+NEBOC_TARGET_FEATURES_OFFSET]
 not rdx
 and rax,rdx
 jnz .source
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_targets
 ; rdi=registry rsi=count output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+8]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_target_report
 ; descriptor report is the 13-qword record.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rdx,rsi
 mov rsi,rdi
 mov ecx,NEBOC_TARGET_SIZE/8
.copy: mov rax,[rsi]
 mov [rdx],rax
 add rsi,8
 add rdx,8
 loop .copy
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
