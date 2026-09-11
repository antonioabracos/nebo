; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F04 exact A0 Slice descriptor and bounded Array/Bytes owner proof.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/collections/slice_view_layout.inc"

%if neboc_option_result_null_externo_e_erros_tipados_SLICE_SIZE != 40
 %error "OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F04 Slice A0 descriptor must remain exactly 40 bytes"
%endif
%if NEBOC_SLICE_OWNER_SIZE != 48
 %error "OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F04 test owner state must remain exactly 48 bytes"
%endif

extern neboc_slice_owner_init
extern neboc_slice_view_create
extern neboc_slice_view_validate
extern neboc_slice_view_at
extern neboc_slice_view_subslice
extern neboc_slice_view_release
extern neboc_slice_owner_mutate
extern neboc_host_process_exit

section .data align=16
array_data: dq 10,20,30,40
bytes_data: db 1,2,3,4

section .bss align=16
array_owner: resb NEBOC_SLICE_OWNER_SIZE
bytes_owner: resb NEBOC_SLICE_OWNER_SIZE
root_view: resb neboc_option_result_null_externo_e_erros_tipados_SLICE_SIZE
derived_view: resb neboc_option_result_null_externo_e_erros_tipados_SLICE_SIZE
out_pointer: resq 1

section .text
global _start

_start:
 ; Array<Int,4> owner and a checked [1,4) lexical view.
 lea rdi,[rel array_owner]
 lea rsi,[rel array_data]
 mov edx,4
 mov ecx,8
 mov r8d,1
 call neboc_slice_owner_init
 test eax,eax
 jnz .fail1
 lea rdi,[rel root_view]
 lea rsi,[rel array_owner]
 mov edx,1
 mov ecx,4
 mov r8d,0xA041
 call neboc_slice_view_create
 test eax,eax
 jnz .fail1
 cmp qword [rel root_view+neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET],3
 jne .fail1
 cmp qword [rel root_view+NEBOC_SLICE_STRIDE_OFFSET],8
 jne .fail1
 cmp qword [rel root_view+NEBOC_SLICE_VIEW_LAYOUT_SLICE_GENERATION_OFFSET],1
 jne .fail1

 ; Read and subslice preserve bounds, stride, generation and token.
 lea rdi,[rel root_view]
 lea rsi,[rel array_owner]
 mov edx,0xA041
 mov ecx,1
 lea r8,[rel out_pointer]
 call neboc_slice_view_at
 test eax,eax
 jnz .fail21
 mov rax,[rel out_pointer]
 cmp qword [rax],30
 jne .fail22
 lea rdi,[rel derived_view]
 lea rsi,[rel root_view]
 lea rdx,[rel array_owner]
 mov ecx,1
 mov r8d,3
 call neboc_slice_view_subslice
 test eax,eax
 jnz .fail23
 cmp qword [rel derived_view+neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET],2
 jne .fail24
 lea rdi,[rel derived_view]
 lea rsi,[rel array_owner]
 mov edx,0xA041
 xor ecx,ecx
 lea r8,[rel out_pointer]
 call neboc_slice_view_at
 test eax,eax
 jnz .fail25
 mov rax,[rel out_pointer]
 cmp qword [rax],30
 jne .fail26

 ; A live token blocks mutation and every public access is bounds checked.
 lea rdi,[rel array_owner]
 call neboc_slice_owner_mutate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail31
 lea rdi,[rel derived_view]
 lea rsi,[rel array_owner]
 mov edx,0xA041
 mov ecx,2
 lea r8,[rel out_pointer]
 call neboc_slice_view_at
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail32
 lea rdi,[rel derived_view]
 lea rsi,[rel root_view]
 lea rdx,[rel array_owner]
 xor ecx,ecx
 mov r8d,4
 call neboc_slice_view_subslice
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail33

 ; Releasing the lexical token makes parent and derived views stale.
 lea rdi,[rel root_view]
 lea rsi,[rel array_owner]
 mov edx,0xA041
 call neboc_slice_view_release
 test eax,eax
 jnz .fail4
 lea rdi,[rel derived_view]
 lea rsi,[rel array_owner]
 mov edx,0xA041
 call neboc_slice_view_validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail4
 lea rdi,[rel array_owner]
 call neboc_slice_owner_mutate
 test eax,eax
 jnz .fail4
 cmp qword [rel array_owner+neboc_option_result_null_externo_e_erros_tipados_SLICE_OWNER_GENERATION_OFFSET],2
 jne .fail4

 ; Empty views are valid; invalid token and owner bounds are rejected.
 lea rdi,[rel root_view]
 lea rsi,[rel array_owner]
 xor edx,edx
 xor ecx,ecx
 mov r8d,0xA042
 call neboc_slice_view_create
 test eax,eax
 jnz .fail5
 cmp qword [rel root_view+neboc_option_result_null_externo_e_erros_tipados_SLICE_LENGTH_OFFSET],0
 jne .fail5
 lea rdi,[rel root_view]
 lea rsi,[rel array_owner]
 mov edx,0xA042
 call neboc_slice_view_release
 test eax,eax
 jnz .fail5
 lea rdi,[rel root_view]
 lea rsi,[rel array_owner]
 xor edx,edx
 mov ecx,5
 mov r8d,0xA043
 call neboc_slice_view_create
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail5
 lea rdi,[rel root_view]
 lea rsi,[rel array_owner]
 xor edx,edx
 mov ecx,1
 xor r8d,r8d
 call neboc_slice_view_create
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail5

 ; Bytes uses the same exact descriptor with stride one and no ownership.
 lea rdi,[rel bytes_owner]
 lea rsi,[rel bytes_data]
 mov edx,4
 mov ecx,1
 mov r8d,9
 call neboc_slice_owner_init
 test eax,eax
 jnz .fail6
 lea rdi,[rel root_view]
 lea rsi,[rel bytes_owner]
 mov edx,1
 mov ecx,4
 mov r8d,0xB041
 call neboc_slice_view_create
 test eax,eax
 jnz .fail6
 lea rdi,[rel root_view]
 lea rsi,[rel bytes_owner]
 mov edx,0xB041
 mov ecx,1
 lea r8,[rel out_pointer]
 call neboc_slice_view_at
 test eax,eax
 jnz .fail6
 mov rax,[rel out_pointer]
 cmp byte [rax],3
 jne .fail6

 ; Forged stride and base cannot escape the owner extent.
 mov qword [rel root_view+NEBOC_SLICE_STRIDE_OFFSET],2
 lea rdi,[rel root_view]
 lea rsi,[rel bytes_owner]
 mov edx,0xB041
 call neboc_slice_view_validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail7
 mov qword [rel root_view+NEBOC_SLICE_STRIDE_OFFSET],1
 lea rax,[rel bytes_data]
 dec rax
 mov [rel root_view+NEBOC_SLICE_BASE_OFFSET],rax
 lea rdi,[rel root_view]
 lea rsi,[rel bytes_owner]
 mov edx,0xB041
 call neboc_slice_view_validate
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail7

 xor edi,edi
 jmp neboc_host_process_exit
.fail1: mov edi,1
 jmp neboc_host_process_exit
.fail21: mov edi,21
 jmp neboc_host_process_exit
.fail22: mov edi,22
 jmp neboc_host_process_exit
.fail23: mov edi,23
 jmp neboc_host_process_exit
.fail24: mov edi,24
 jmp neboc_host_process_exit
.fail25: mov edi,25
 jmp neboc_host_process_exit
.fail26: mov edi,26
 jmp neboc_host_process_exit
.fail31: mov edi,31
 jmp neboc_host_process_exit
.fail32: mov edi,32
 jmp neboc_host_process_exit
.fail33: mov edi,33
 jmp neboc_host_process_exit
.fail4: mov edi,4
 jmp neboc_host_process_exit
.fail5: mov edi,5
 jmp neboc_host_process_exit
.fail6: mov edi,6
 jmp neboc_host_process_exit
.fail7: mov edi,7
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
