bits 64
default rel
%include "runtime/ml/quantization.inc"
section .data
samples dq -2.0,-1.0,0.0,1.0,2.0
zero_samples dq 0.0,0.0
saturate_samples dq -3.0,3.0
nonfinite_samples dq 0x7ff0000000000000,1.0
two dq 2.0
one dq 1.0
tolerance dq 0.008
strict_tolerance dq 0.001
section .bss
params resb NEBO_QUANT_PARAMS_SIZE
zero_params resb NEBO_QUANT_PARAMS_SIZE
quantized resb 16
dequantized resq 8
report resb NEBO_QUANT_REPORT_SIZE
features resq 2
section .text
global _start
_start:
 lea rdi,[rel samples]
 mov esi,5
 lea rdx,[rel params]
 call nebo_int8_calibrate
 test eax,eax
 jnz .fail1
 movsd xmm0,[rel params+NEBO_QUANT_PARAMS_MAX_ABS]
 ucomisd xmm0,[rel two]
 jne .fail2
 cmp qword [rel params+NEBO_QUANT_PARAMS_SAMPLES],5
 jne .fail3
 lea rdi,[rel samples]
 mov esi,5
 lea rdx,[rel params]
 lea rcx,[rel quantized]
 mov r8d,5
 call nebo_int8_quantize
 test eax,eax
 jnz .fail4
 cmp byte [rel quantized],-127
 jne .fail5
 cmp byte [rel quantized+1],-64
 jne .fail6
 cmp byte [rel quantized+2],0
 jne .fail7
 cmp byte [rel quantized+3],64
 jne .fail8
 cmp byte [rel quantized+4],127
 jne .fail9
 lea rdi,[rel quantized]
 mov esi,5
 lea rdx,[rel params]
 lea rcx,[rel dequantized]
 mov r8d,5
 call nebo_int8_dequantize
 test eax,eax
 jnz .fail10
 movsd xmm0,[rel dequantized]
 ucomisd xmm0,[rel samples]
 jne .fail11
 movsd xmm0,[rel dequantized+32]
 ucomisd xmm0,[rel samples+32]
 jne .fail12
 lea rdi,[rel samples]
 lea rsi,[rel dequantized]
 mov edx,5
 lea rcx,[rel report]
 lea r8,[rel tolerance]
 call nebo_int8_compare_accuracy
 test eax,eax
 jnz .fail13
 cmp qword [rel report+24],5
 jne .fail14
 cmp qword [rel report+32],1
 jne .fail15
 lea rdi,[rel samples]
 lea rsi,[rel dequantized]
 mov edx,5
 lea rcx,[rel report]
 lea r8,[rel strict_tolerance]
 call nebo_int8_compare_accuracy
 test eax,eax
 jnz .fail16
 cmp qword [rel report+32],0
 jne .fail17

 lea rdi,[rel zero_samples]
 mov esi,2
 lea rdx,[rel zero_params]
 call nebo_int8_calibrate
 test eax,eax
 jnz .fail18
 movsd xmm0,[rel zero_params+NEBO_QUANT_PARAMS_SCALE]
 ucomisd xmm0,[rel one]
 jne .fail19
 lea rdi,[rel saturate_samples]
 mov esi,2
 lea rdx,[rel params]
 lea rcx,[rel quantized]
 mov r8d,2
 call nebo_int8_quantize
 test eax,eax
 jnz .fail20
 cmp byte [rel quantized],-127
 jne .fail21
 cmp byte [rel quantized+1],127
 jne .fail22

 mov qword [rel params+NEBO_QUANT_PARAMS_SCALE],0
 mov byte [rel quantized],0x55
 lea rdi,[rel samples]
 mov esi,5
 lea rdx,[rel params]
 lea rcx,[rel quantized]
 mov r8d,5
 call nebo_int8_quantize
 cmp eax,NEBO_QUANT_E_SCALE
 jne .fail23
 cmp byte [rel quantized],0x55
 jne .fail24
 lea rdi,[rel samples]
 mov esi,5
 lea rdx,[rel params]
 call nebo_int8_calibrate
 test eax,eax
 jnz .fail25
 lea rdi,[rel nonfinite_samples]
 mov esi,2
 lea rdx,[rel zero_params]
 call nebo_int8_calibrate
 cmp eax,NEBO_QUANT_E_NONFINITE
 jne .fail26
 lea rdi,[rel samples]
 mov esi,5
 lea rdx,[rel params]
 lea rcx,[rel samples+8]
 mov r8d,5
 call nebo_int8_quantize
 cmp eax,NEBO_QUANT_E_OVERLAP
 jne .fail27
 lea rdi,[rel samples]
 mov esi,5
 lea rdx,[rel params]
 lea rcx,[rel quantized]
 mov r8d,4
 call nebo_int8_quantize
 cmp eax,NEBO_QUANT_E_CAPACITY
 jne .fail28
 lea rdi,[rel features]
 call nebo_int8_features
 test eax,eax
 jnz .fail29
 cmp qword [rel features],1
 jne .fail30
 cmp qword [rel features+8],1
 jne .fail31
 xor edi,edi
 jmp .exit
%assign i 1
%rep 31
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
