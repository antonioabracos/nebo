bits 64
default rel
%include "runtime/gpu/gpu_unsupported.inc"
section .data
sentinel dq 0x55aa55aa55aa55aa
section .bss
count resq 1
report resq 4
handle resq 1
properties resq 4
section .text
global _start
_start:
 lea rdi,[rel count]
 call nebo_gpu_enumerate
 test eax,eax
 jnz .fail1
 cmp qword [rel count],0
 jne .fail2
 xor edi,edi
 call nebo_gpu_enumerate
 cmp eax,NEBO_GPU_E_ARGUMENT
 jne .fail3
 lea rdi,[rel report]
 call nebo_gpu_backend_status
 test eax,eax
 jnz .fail4
 cmp qword [rel report],NEBO_GPU_BACKEND_NONE
 jne .fail5
 cmp qword [rel report+8],0
 jne .fail6
 cmp qword [rel report+16],NEBO_GPU_STATE_UNAVAILABLE
 jne .fail7
 cmp qword [rel report+24],NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail8
 mov rax,[rel sentinel]
 mov [rel handle],rax
 xor edi,edi
 lea rsi,[rel handle]
 call nebo_gpu_context_create
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail9
 mov rax,[rel sentinel]
 cmp [rel handle],rax
 jne .fail10
 xor edi,edi
 xor esi,esi
 call nebo_gpu_context_create
 cmp eax,NEBO_GPU_E_ARGUMENT
 jne .fail11
 mov rax,[rel sentinel]
 mov [rel properties],rax
 xor edi,edi
 lea rsi,[rel properties]
 call nebo_gpu_context_properties
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail12
 mov rax,[rel sentinel]
 cmp [rel properties],rax
 jne .fail13
 xor edi,edi
 call nebo_gpu_context_synchronize
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail14
 xor edi,edi
 call nebo_gpu_context_close
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail15
 mov ecx,10000
.repeat:
 lea rdi,[rel count]
 call nebo_gpu_enumerate
 test eax,eax
 jnz .fail16
 cmp qword [rel count],0
 jne .fail17
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 17
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
