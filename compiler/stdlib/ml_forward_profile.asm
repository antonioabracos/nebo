; Deterministic bounded CPU-only affine forward profile: y=x*w+b.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/ml_forward_profile.inc"
section .text
NEBOC_ABI_FUNCTION neboc_ml_forward_validate_execute
 test rdi,rdi
 jz .arg
 test rdi,7
 jnz .arg
 mov qword [rdi+NEBOC_ML_DIAGNOSTIC_OFFSET],0
 mov qword [rdi+NEBOC_ML_RESULT_OFFSET],0
 mov rax,[rdi+NEBOC_ML_BATCH_OFFSET]
 test rax,rax
 jz .type
 cmp rax,NEBOC_ML_MAX_DIM
 ja .type
 mov rax,[rdi+NEBOC_ML_INPUT_DIM_OFFSET]
 test rax,rax
 jz .type
 cmp rax,NEBOC_ML_MAX_DIM
 ja .type
 mov rax,[rdi+NEBOC_ML_OUTPUT_DIM_OFFSET]
 test rax,rax
 jz .type
 cmp rax,NEBOC_ML_MAX_DIM
 ja .type
 cmp qword [rdi+NEBOC_ML_DTYPE_OFFSET],NEBOC_ML_DTYPE_INT64_BOUNDED
 jne .type
 cmp qword [rdi+NEBOC_ML_DEVICE_OFFSET],NEBOC_ML_DEVICE_CPU_LOCAL
 jne .security
 mov rax,[rdi+NEBOC_ML_OP_BUDGET_OFFSET]
 cmp rax,3
 jb .runtime
 cmp rax,NEBOC_ML_MAX_OP_BUDGET
 ja .runtime
 cmp qword [rdi+NEBOC_ML_WEIGHTS_HASH_OFFSET],0
 je .security
 cmp qword [rdi+NEBOC_ML_LINEAGE_HASH_OFFSET],0
 je .security
 cmp qword [rdi+NEBOC_ML_PRIVACY_FLAGS_OFFSET],NEBOC_ML_REQUIRED_PRIVACY_FLAGS
 jne .security
 cmp qword [rdi+NEBOC_ML_OWNERSHIP_FLAGS_OFFSET],NEBOC_ML_REQUIRED_OWNERSHIP_FLAGS
 jne .security
 mov rax,NEBOC_ML_SEAL_MAGIC
 mov ecx,13
 xor edx,edx
.seal_loop:
 xor rax,[rdi+rdx*8]
 inc edx
 loop .seal_loop
 cmp rax,[rdi+NEBOC_ML_SEAL_OFFSET]
 jne .security
 mov rax,[rdi+NEBOC_ML_INPUT_OFFSET]
 call abs_bound
 jc .type
 mov rax,[rdi+NEBOC_ML_WEIGHT_OFFSET]
 call abs_bound
 jc .type
 mov rax,[rdi+NEBOC_ML_BIAS_OFFSET]
 call abs_bound
 jc .type
 mov rax,[rdi+NEBOC_ML_INPUT_OFFSET]
 imul rax,[rdi+NEBOC_ML_WEIGHT_OFFSET]
 jo .runtime
 add rax,[rdi+NEBOC_ML_BIAS_OFFSET]
 jo .runtime
 mov [rdi+NEBOC_ML_RESULT_OFFSET],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.type:
 mov eax,neboc_machine_learning_neuron_network_e_model_DIAG_TYPE_stdlib
 jmp .fail
.runtime:
 mov eax,neboc_machine_learning_neuron_network_e_model_DIAG_RUNTIME_stdlib
 jmp .fail
.security:
 mov eax,neboc_machine_learning_neuron_network_e_model_DIAG_SECURITY_stdlib
.fail:
 mov [rdi+NEBOC_ML_DIAGNOSTIC_OFFSET],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
abs_bound:
 cmp rax,NEBOC_ML_MAX_ABS_SCALAR
 jg .bad
 cmp rax,-NEBOC_ML_MAX_ABS_SCALAR
 jl .bad
 clc
 ret
.bad:
 stc
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
