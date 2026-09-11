bits 64
default rel
%include "runtime/audio/pcm.inc"
section .bss
align 16
dst resb 64
src resb 64
rdst resb 64
rsrc resb 64
dstdata resw 8
srcdata resw 8
rdstdata resw 8
rsrcdata resw 4
section .text
global _start
_start:
 lea rdi,[rel dst]
 lea rsi,[rel dstdata]
 mov edx,16
 mov ecx,4
 mov r8d,8000
 mov r9d,2
 call nebo_pcm_init
 test eax,eax
 jnz .fail1
 cmp qword [rel dstdata],0
 jne .fail2
 lea rdi,[rel dst]
 call nebo_pcm_duration_us
 test eax,eax
 jnz .fail3
 cmp edx,500
 jne .fail4
 lea rdi,[rel src]
 lea rsi,[rel srcdata]
 mov edx,16
 mov ecx,4
 mov r8d,8000
 mov r9d,2
 call nebo_pcm_init
 test eax,eax
 jnz .fail5
 mov word [rel dstdata],30000
 mov word [rel dstdata+2],-30000
 mov word [rel srcdata],10000
 mov word [rel srcdata+2],-10000
 lea rdi,[rel dst]
 lea rsi,[rel src]
 mov edx,16384
 call nebo_pcm_mix_into
 test eax,eax
 jnz .fail6
 cmp word [rel dstdata],32767
 jne .fail7
 cmp word [rel dstdata+2],-32768
 jne .fail8
 lea rdi,[rel dst]
 lea rsi,[rel src]
 mov edx,32769
 call nebo_pcm_mix_into
 cmp eax,NEBO_PCM_E_RANGE
 jne .fail9
 ; Mono 8kHz four-frame source to eight-frame 16kHz destination.
 lea rdi,[rel rsrc]
 lea rsi,[rel rsrcdata]
 mov edx,8
 mov ecx,4
 mov r8d,8000
 mov r9d,1
 call nebo_pcm_init
 test eax,eax
 jnz .fail10
 mov word [rel rsrcdata],0
 mov word [rel rsrcdata+2],1000
 mov word [rel rsrcdata+4],2000
 mov word [rel rsrcdata+6],3000
 lea rdi,[rel rdst]
 lea rsi,[rel rdstdata]
 mov edx,16
 mov ecx,8
 mov r8d,16000
 mov r9d,1
 call nebo_pcm_init
 test eax,eax
 jnz .fail11
 lea rdi,[rel rdst]
 lea rsi,[rel rsrc]
 call nebo_pcm_resample_linear_into
 test eax,eax
 jnz .fail12
 cmp word [rel rdstdata],0
 jne .fail13
 cmp word [rel rdstdata+2],500
 jne .fail14
 cmp word [rel rdstdata+6],1500
 jne .fail15
 cmp word [rel rdstdata+12],3000
 jne .fail16
 cmp word [rel rdstdata+14],3000
 jne .fail17
 ; Wrong destination frame count is refused without writes.
 mov dword [rel rdst+16],7
 mov word [rel rdstdata],0x5555
 lea rdi,[rel rdst]
 lea rsi,[rel rsrc]
 call nebo_pcm_resample_linear_into
 cmp eax,NEBO_PCM_E_MISMATCH
 jne .fail18
 cmp word [rel rdstdata],0x5555
 jne .fail19
 ; Init failure is atomic.
 mov rax,0x4444444444444444
 mov [rel rdst],rax
 lea rdi,[rel rdst]
 lea rsi,[rel rdstdata]
 mov edx,16
 mov ecx,8
 mov r8d,7999
 mov r9d,1
 call nebo_pcm_init
 cmp eax,NEBO_PCM_E_RANGE
 jne .fail20
 mov rax,0x4444444444444444
 cmp [rel rdst],rax
 jne .fail21
 ; Direct source/destination overlap is typed.
 lea rdi,[rel rdst]
 lea rsi,[rel rdstdata]
 mov edx,16
 mov ecx,8
 mov r8d,16000
 mov r9d,1
 call nebo_pcm_init
 lea rdi,[rel rdst]
 lea rsi,[rel rdst]
 call nebo_pcm_resample_linear_into
 cmp eax,NEBO_PCM_E_OVERLAP
 jne .fail22
 xor edi,edi
 jmp .exit
%assign i 1
%rep 22
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
