bits 64
default rel
%include "runtime/gpu/gpu_fallback.inc"
section .data
sentinel dq 0x55aa55aa55aa55aa
section .bss
plan_out resq 3
section .text
global _start
_start:
 mov rax,[rel sentinel]
 mov [rel plan_out],rax
 xor edi,edi
 lea rsi,[rel plan_out]
 call nebo_gpu_device_select
 test eax,eax
 jne .fail1
 cmp qword [rel plan_out],NEBO_GPU_DEVICE_CPU
 jne .fail2
 mov rax,[rel sentinel]
 mov [rel plan_out],rax
 mov edi,NEBO_GPU_DEVICE_GPU
 lea rsi,[rel plan_out]
 call nebo_gpu_device_select
 cmp eax,NEBO_GPU_FALLBACK_E_UNSUPPORTED
 jne .fail3
 mov rax,[rel sentinel]
 cmp [rel plan_out],rax
 jne .fail4
 xor edi,edi
 mov esi,4096
 lea rdx,[rel plan_out]
 call nebo_gpu_transfer_plan
 test eax,eax
 jne .fail5
 cmp qword [rel plan_out],0
 jne .fail6
 cmp qword [rel plan_out+8],0
 jne .fail7
 cmp qword [rel plan_out+16],0
 jne .fail8
 xor edi,edi
 mov rsi,NEBO_GPU_FALLBACK_MAX_BYTES+1
 lea rdx,[rel plan_out]
 call nebo_gpu_transfer_plan
 cmp eax,NEBO_GPU_FALLBACK_E_LIMIT
 jne .fail9
 mov edi,NEBO_GPU_DEVICE_GPU
 lea rsi,[rel plan_out]
 call nebo_gpu_fallback_to_cpu
 test eax,eax
 jne .fail10
 cmp qword [rel plan_out],0
 jne .fail11
 cmp qword [rel plan_out+8],1
 jne .fail12
 mov rax,[rel sentinel]
 mov [rel plan_out],rax
 mov edi,NEBO_GPU_DEVICE_GPU
 lea rsi,[rel plan_out]
 call nebo_gpu_pin
 cmp eax,NEBO_GPU_FALLBACK_E_UNSUPPORTED
 jne .fail13
 mov rax,[rel sentinel]
 cmp [rel plan_out],rax
 jne .fail14
 xor edi,edi
 lea rsi,[rel plan_out]
 call nebo_gpu_supported_on
 test eax,eax
 jne .fail15
 cmp qword [rel plan_out],1
 jne .fail16
 mov edi,NEBO_GPU_DEVICE_GPU
 lea rsi,[rel plan_out]
 call nebo_gpu_supported_on
 test eax,eax
 jne .fail17
 cmp qword [rel plan_out],0
 jne .fail18
 mov ecx,5000
.repeat:
 mov edi,NEBO_GPU_DEVICE_GPU
 lea rsi,[rel plan_out]
 call nebo_gpu_fallback_to_cpu
 test eax,eax
 jne .fail19
 cmp qword [rel plan_out],0
 jne .fail20
 cmp qword [rel plan_out+8],1
 jne .fail21
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 21
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
