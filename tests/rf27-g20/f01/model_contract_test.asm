bits 64
default rel
%include "compiler/semantic/ml/model_contract.inc"
section .data
nodes:
 dd 0
 dw 1,NEBO_MODEL_DTYPE_F64
 dd 2,2,4,0,0,0
 dd 1
 dw 2,NEBO_MODEL_DTYPE_F64
 dd 2,2,3,0,0,0
 dd 2
 dw 3,NEBO_MODEL_DTYPE_F64
 dd 1,3,0,0,0,0
edges: dd 0,1, 1,2
section .bss
graph resb 64
summary resb 32
section .text
global _start
_start:
 lea rax,[rel nodes]
 mov [rel graph],rax
 mov qword [rel graph+8],3
 lea rax,[rel edges]
 mov [rel graph+16],rax
 mov qword [rel graph+24],2
 mov qword [rel graph+32],1
 mov qword [rel graph+40],24
 mov qword [rel graph+48],24
 mov qword [rel graph+56],0
 lea rdi,[rel graph]
 call nebo_model_validate
 test eax,eax
 jnz .fail1
 lea rdi,[rel graph]
 lea rsi,[rel summary]
 call nebo_model_summary
 test eax,eax
 jnz .fail2
 cmp qword [rel summary],3
 jne .fail3
 cmp qword [rel summary+8],2
 jne .fail4
 cmp qword [rel summary+16],24
 jne .fail5
 cmp qword [rel summary+24],2
 jne .fail6
 lea rdi,[rel graph]
 call nebo_model_eval_ready
 test eax,eax
 jnz .fail7
 mov dword [rel nodes+32],0
 lea rdi,[rel graph]
 call nebo_model_validate
 cmp eax,NEBO_MODEL_E_IDENTITY
 jne .fail8
 mov dword [rel nodes+32],1
 mov word [rel nodes+6],2
 lea rdi,[rel graph]
 call nebo_model_validate
 cmp eax,NEBO_MODEL_E_DTYPE
 jne .fail9
 mov word [rel nodes+6],NEBO_MODEL_DTYPE_F64
 mov dword [rel nodes+8],0
 lea rdi,[rel graph]
 call nebo_model_validate
 cmp eax,NEBO_MODEL_E_SHAPE
 jne .fail10
 mov dword [rel nodes+8],2
 mov dword [rel edges],1
 mov dword [rel edges+4],0
 lea rdi,[rel graph]
 call nebo_model_validate
 cmp eax,NEBO_MODEL_E_CYCLE
 jne .fail11
 mov dword [rel edges],0
 mov dword [rel edges+4],1
 mov dword [rel edges+8],0
 mov dword [rel edges+12],1
 lea rdi,[rel graph]
 call nebo_model_validate
 cmp eax,NEBO_MODEL_E_EDGE
 jne .fail12
 mov dword [rel edges+8],1
 mov dword [rel edges+12],2
 mov qword [rel graph+8],65
 lea rdi,[rel graph]
 call nebo_model_validate
 cmp eax,NEBO_MODEL_E_LIMIT
 jne .fail13
 mov qword [rel graph+8],3
 mov qword [rel graph+56],1
 lea rdi,[rel graph]
 call nebo_model_validate
 cmp eax,NEBO_MODEL_E_ARGUMENT
 jne .fail14
 mov qword [rel graph+56],0
 mov dword [rel nodes+12],65
 lea rdi,[rel graph]
 call nebo_model_validate
 cmp eax,NEBO_MODEL_E_SHAPE
 jne .fail15
 mov dword [rel nodes+12],2
 mov rax,0x5555555555555555
 mov [rel summary],rax
 mov qword [rel graph+24],129
 lea rdi,[rel graph]
 lea rsi,[rel summary]
 call nebo_model_summary
 cmp eax,NEBO_MODEL_E_LIMIT
 jne .fail16
 mov rax,0x5555555555555555
 cmp [rel summary],rax
 jne .fail17
 mov qword [rel graph+24],2
 lea rdi,[rel graph]
 xor esi,esi
 call nebo_model_summary
 cmp eax,NEBO_MODEL_E_ARGUMENT
 jne .fail18
 xor edi,edi
 jmp .exit
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
