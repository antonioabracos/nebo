bits 64
default rel
%include "runtime/gpu/gpu_diagnostics.inc"
section .data
sentinel dq 0x55aa55aa55aa55aa
section .bss
report resq 6
scratch resq 2
section .text
global _start
_start:
 mov edi,7
 lea rsi,[rel report]
 call nebo_gpu_error_report
 test eax,eax
 jne .fail1
 cmp qword [rel report],NEBO_GPU_DIAG_DOMAIN
 jne .fail2
 cmp qword [rel report+8],NEBO_GPU_DIAG_E_UNSUPPORTED
 jne .fail3
 cmp qword [rel report+16],7
 jne .fail4
 cmp qword [rel report+24],0
 jne .fail5
 cmp qword [rel report+32],0
 jne .fail6
 cmp qword [rel report+40],0
 jne .fail7
 mov edi,7
 xor esi,esi
 call nebo_gpu_error_report
 cmp eax,NEBO_GPU_DIAG_E_ARGUMENT
 jne .fail8
 mov rax,[rel sentinel]
 mov [rel scratch],rax
 lea rdi,[rel scratch]
 call nebo_gpu_profile_begin
 cmp eax,NEBO_GPU_DIAG_E_UNSUPPORTED
 jne .fail9
 mov rax,[rel sentinel]
 cmp [rel scratch],rax
 jne .fail10
 xor edi,edi
 call nebo_gpu_profile_begin
 cmp eax,NEBO_GPU_DIAG_E_ARGUMENT
 jne .fail11
 xor edi,edi
 lea rsi,[rel scratch]
 call nebo_gpu_profile_read
 cmp eax,NEBO_GPU_DIAG_E_UNSUPPORTED
 jne .fail12
 mov rax,[rel sentinel]
 cmp [rel scratch],rax
 jne .fail13
 lea rdi,[rel scratch]
 call nebo_gpu_memory_budget
 cmp eax,NEBO_GPU_DIAG_E_UNSUPPORTED
 jne .fail14
 mov rax,[rel sentinel]
 cmp [rel scratch],rax
 jne .fail15
 mov edi,3
 lea rsi,[rel scratch]
 call nebo_gpu_failure_inject
 cmp eax,NEBO_GPU_DIAG_E_UNSUPPORTED
 jne .fail16
 mov rax,[rel sentinel]
 cmp [rel scratch],rax
 jne .fail17
 mov ecx,10000
.repeat:
 mov edi,31
 lea rsi,[rel report]
 call nebo_gpu_error_report
 test eax,eax
 jne .fail18
 cmp qword [rel report],NEBO_GPU_DIAG_DOMAIN
 jne .fail19
 cmp qword [rel report+8],NEBO_GPU_DIAG_E_UNSUPPORTED
 jne .fail20
 cmp qword [rel report+16],31
 jne .fail21
 cmp qword [rel report+24],0
 jne .fail22
 cmp qword [rel report+32],0
 jne .fail23
 cmp qword [rel report+40],0
 jne .fail24
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 24
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
