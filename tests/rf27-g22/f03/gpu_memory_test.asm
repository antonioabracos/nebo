bits 64
default rel
%include "runtime/gpu/gpu_unsupported.inc"
section .data
sentinel dq 0x55aa55aa55aa55aa
host_tensor dq 1.0,2.0,3.0,4.0
section .bss
handle resq 1
transfer_out resq 1
pinned_out resq 1
section .text
global _start
_start:
 mov rax,[rel sentinel]
 mov [rel handle],rax
 xor edi,edi
 mov esi,1024
 lea rdx,[rel handle]
 call nebo_gpu_buffer_create
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail1
 mov rax,[rel sentinel]
 cmp [rel handle],rax
 jne .fail2
 xor edi,edi
 xor esi,esi
 xor edx,edx
 call nebo_gpu_buffer_create
 cmp eax,NEBO_GPU_E_ARGUMENT
 jne .fail3
 xor edi,edi
 call nebo_gpu_buffer_close
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail4
 xor edi,edi
 lea rsi,[rel host_tensor]
 mov edx,32
 call nebo_gpu_copy_to_device
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail5
 mov rax,0x3ff0000000000000
 cmp [rel host_tensor],rax
 jne .fail6
 xor edi,edi
 lea rsi,[rel host_tensor]
 mov edx,32
 call nebo_gpu_copy_to_host
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail7
 mov rax,0x4000000000000000
 cmp [rel host_tensor+8],rax
 jne .fail8
 mov rax,[rel sentinel]
 mov [rel transfer_out],rax
 lea rdi,[rel host_tensor]
 mov esi,4
 xor edx,edx
 lea rcx,[rel transfer_out]
 call nebo_gpu_tensor_transfer
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail9
 mov rax,[rel sentinel]
 cmp [rel transfer_out],rax
 jne .fail10
 lea rdi,[rel host_tensor]
 mov esi,4
 xor edx,edx
 xor ecx,ecx
 call nebo_gpu_tensor_transfer
 cmp eax,NEBO_GPU_E_ARGUMENT
 jne .fail11
 mov rax,[rel sentinel]
 mov [rel pinned_out],rax
 lea rdi,[rel host_tensor]
 mov esi,32
 lea rdx,[rel pinned_out]
 call nebo_gpu_pin_host
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail12
 mov rax,[rel sentinel]
 cmp [rel pinned_out],rax
 jne .fail13
 mov ecx,10000
.repeat:
 xor edi,edi
 mov esi,-1
 lea rdx,[rel handle]
 call nebo_gpu_buffer_create
 cmp eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 jne .fail14
 mov rax,[rel sentinel]
 cmp [rel handle],rax
 jne .fail15
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 15
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
