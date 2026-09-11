bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/ml_forward_profile.inc"
extern neboc_ml_forward_validate_execute
extern neboc_host_process_exit
section .bss align=16
p: resb NEBOC_ML_SIZE
section .text
reset:
 lea rdi,[rel p]
 mov ecx,NEBOC_ML_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel p+NEBOC_ML_BATCH_OFFSET],1
 mov qword [rel p+NEBOC_ML_INPUT_DIM_OFFSET],1
 mov qword [rel p+NEBOC_ML_OUTPUT_DIM_OFFSET],1
 mov qword [rel p+NEBOC_ML_DTYPE_OFFSET],NEBOC_ML_DTYPE_INT64_BOUNDED
 mov qword [rel p+NEBOC_ML_INPUT_OFFSET],7
 mov qword [rel p+NEBOC_ML_WEIGHT_OFFSET],6
 mov qword [rel p+NEBOC_ML_BIAS_OFFSET],-2
 mov qword [rel p+NEBOC_ML_OP_BUDGET_OFFSET],3
 mov qword [rel p+NEBOC_ML_WEIGHTS_HASH_OFFSET],0x1234
 mov qword [rel p+NEBOC_ML_LINEAGE_HASH_OFFSET],0x5678
 mov qword [rel p+NEBOC_ML_PRIVACY_FLAGS_OFFSET],NEBOC_ML_REQUIRED_PRIVACY_FLAGS
 mov qword [rel p+NEBOC_ML_OWNERSHIP_FLAGS_OFFSET],NEBOC_ML_REQUIRED_OWNERSHIP_FLAGS
 mov qword [rel p+NEBOC_ML_DEVICE_OFFSET],NEBOC_ML_DEVICE_CPU_LOCAL
 call reseal
 ret
reseal:
 mov rax,NEBOC_ML_SEAL_MAGIC
 lea rdi,[rel p]
 mov ecx,13
 xor edx,edx
.l: xor rax,[rdi+rdx*8]
 inc edx
 loop .l
 mov [rel p+NEBOC_ML_SEAL_OFFSET],rax
 ret
fail_expected:
 ; esi diagnostic
 lea rdi,[rel p]
 call neboc_ml_forward_validate_execute
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp [rel p+NEBOC_ML_DIAGNOSTIC_OFFSET],rsi
 jne fail
 ret
%macro BAD 3
 call reset
 mov qword [rel p+%1],%2
 call reseal
 mov esi,%3
 call fail_expected
%endmacro
global _start
_start:
 mov r15d,1
 xor edi,edi
 call neboc_ml_forward_validate_execute
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 mov r15d,2
 call reset
 lea rdi,[rel p]
 call neboc_ml_forward_validate_execute
 test eax,eax
 jnz fail
 cmp qword [rel p+NEBOC_ML_RESULT_OFFSET],40
 jne fail
 mov r15d,10
 BAD NEBOC_ML_BATCH_OFFSET,0,neboc_machine_learning_neuron_network_e_model_DIAG_TYPE_stdlib
 inc r15d
 BAD NEBOC_ML_INPUT_DIM_OFFSET,33,neboc_machine_learning_neuron_network_e_model_DIAG_TYPE_stdlib
 inc r15d
 BAD NEBOC_ML_OUTPUT_DIM_OFFSET,0,neboc_machine_learning_neuron_network_e_model_DIAG_TYPE_stdlib
 inc r15d
 BAD NEBOC_ML_DTYPE_OFFSET,2,neboc_machine_learning_neuron_network_e_model_DIAG_TYPE_stdlib
 inc r15d
 BAD NEBOC_ML_INPUT_OFFSET,1025,neboc_machine_learning_neuron_network_e_model_DIAG_TYPE_stdlib
 inc r15d
 BAD NEBOC_ML_WEIGHT_OFFSET,-1025,neboc_machine_learning_neuron_network_e_model_DIAG_TYPE_stdlib
 inc r15d
 BAD NEBOC_ML_OP_BUDGET_OFFSET,2,neboc_machine_learning_neuron_network_e_model_DIAG_RUNTIME_stdlib
 inc r15d
 BAD NEBOC_ML_OP_BUDGET_OFFSET,4097,neboc_machine_learning_neuron_network_e_model_DIAG_RUNTIME_stdlib
 inc r15d
 BAD NEBOC_ML_WEIGHTS_HASH_OFFSET,0,neboc_machine_learning_neuron_network_e_model_DIAG_SECURITY_stdlib
 inc r15d
 BAD NEBOC_ML_LINEAGE_HASH_OFFSET,0,neboc_machine_learning_neuron_network_e_model_DIAG_SECURITY_stdlib
 inc r15d
 BAD NEBOC_ML_PRIVACY_FLAGS_OFFSET,0,neboc_machine_learning_neuron_network_e_model_DIAG_SECURITY_stdlib
 inc r15d
 BAD NEBOC_ML_OWNERSHIP_FLAGS_OFFSET,0,neboc_machine_learning_neuron_network_e_model_DIAG_SECURITY_stdlib
 inc r15d
 BAD NEBOC_ML_DEVICE_OFFSET,2,neboc_machine_learning_neuron_network_e_model_DIAG_SECURITY_stdlib
 inc r15d
 call reset
 inc qword [rel p+NEBOC_ML_SEAL_OFFSET]
 mov esi,neboc_machine_learning_neuron_network_e_model_DIAG_SECURITY_stdlib
 call fail_expected
 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r15d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
