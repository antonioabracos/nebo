bits 64
default rel
%include "runtime/replication/sync.inc"
extern nebo_sync_plan_batch
section .bss
send resq 1
resume resq 1
section .text
global _start
_start:
 mov edi,600
 mov esi,12000
 mov edx,250
 mov ecx,256
 lea r8,[send]
 lea r9,[resume]
 call nebo_sync_plan_batch
 test eax,eax
 jnz fail
 cmp qword [send],256
 jne fail
 cmp qword [resume],506
 jne fail
 mov edi,600
 mov esi,12000
 mov edx,590
 mov ecx,256
 lea r8,[send]
 lea r9,[resume]
 call nebo_sync_plan_batch
 cmp qword [send],10
 jne fail
 mov edi,4097
 xor esi,esi
 xor edx,edx
 mov ecx,1
 lea r8,[send]
 lea r9,[resume]
 call nebo_sync_plan_batch
 cmp eax,NEBO_SYNC_LIMIT
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
