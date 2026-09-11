bits 64
default rel
%include "runtime/tokenizer/tokenizer.inc"
section .data
header dq NEBO_TOKENIZER_MAGIC,NEBO_TOKENIZER_VERSION,NEBO_TOKENIZER_VOCAB,(NEBO_TOKENIZER_MAGIC ^ NEBO_TOKENIZER_VERSION ^ NEBO_TOKENIZER_VOCAB)
source db 'N','e','b','o',0,255
sentinel dq 0x55aa55aa55aa55aa
section .bss
state resq 3
tokens resq 256
decoded resb 256
count_out resq 1
scratch resq 1
section .text
global _start
_start:
 lea rdi,[rel header]
 mov esi,32
 lea rdx,[rel state]
 call nebo_tokenizer_load
 test eax,eax
 jne .fail1
 cmp qword [rel state],1
 jne .fail2
 cmp qword [rel state+8],256
 jne .fail3
 cmp qword [rel state+16],0
 jne .fail4
 lea rdi,[rel source]
 mov esi,6
 lea rdx,[rel tokens]
 mov ecx,256
 lea r8,[rel count_out]
 call nebo_tokenizer_encode
 test eax,eax
 jne .fail5
 cmp qword [rel count_out],6
 jne .fail6
 cmp qword [rel tokens],78
 jne .fail7
 cmp qword [rel tokens+32],0
 jne .fail8
 cmp qword [rel tokens+40],255
 jne .fail9
 lea rdi,[rel tokens]
 mov esi,6
 lea rdx,[rel decoded]
 mov ecx,256
 lea r8,[rel count_out]
 call nebo_tokenizer_decode
 test eax,eax
 jne .fail10
 mov eax,dword [rel source]
 cmp dword [rel decoded],eax
 jne .fail11
 mov ax,word [rel source+4]
 cmp word [rel decoded+4],ax
 jne .fail12
 mov qword [rel tokens],256
 mov rax,[rel sentinel]
 mov [rel scratch],rax
 lea rdi,[rel tokens]
 mov esi,1
 lea rdx,[rel decoded]
 mov ecx,256
 lea r8,[rel scratch]
 call nebo_tokenizer_decode
 cmp eax,NEBO_TOKENIZER_E_TOKEN
 jne .fail13
 mov rax,[rel sentinel]
 cmp [rel scratch],rax
 jne .fail14
 mov edi,257
 lea rsi,[rel count_out]
 call nebo_tokenizer_count
 cmp eax,NEBO_TOKENIZER_E_LIMIT
 jne .fail15
 lea rdi,[rel scratch]
 call nebo_tokenizer_vocabulary
 test eax,eax
 jne .fail16
 cmp qword [rel scratch],256
 jne .fail17
 mov edi,65
 lea rsi,[rel scratch]
 call nebo_tokenizer_special
 test eax,eax
 jne .fail18
 cmp qword [rel scratch],0
 jne .fail19
 mov ecx,5000
.repeat:
 lea rdi,[rel source]
 mov esi,6
 lea rdx,[rel tokens]
 mov r10,rcx
 mov ecx,256
 lea r8,[rel count_out]
 call nebo_tokenizer_encode
 mov rcx,r10
 test eax,eax
 jne .fail20
 cmp qword [rel count_out],6
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
