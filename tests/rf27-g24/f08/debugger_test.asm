bits 64
default rel
%include "runtime/tooling/debugger.inc"
extern nebo_capability_authority_init,nebo_capability_grant
extern nebo_debugger_init,nebo_debugger_control,nebo_debugger_snapshot
section .rodata
secret: times 32 db 0x48
section .bss
align 16
authority resb NEBO_AUTHORITY_SIZE
cap resb NEBO_CAPABILITY_SIZE
grant resb NEBO_CAPABILITY_GRANT_SIZE
state resb NEBO_DEBUGGER_STATE_SIZE
bps resb NEBO_DEBUGGER_BP_SIZE*4
init resb NEBO_DEBUGGER_INIT_SIZE
req resb NEBO_DEBUGGER_REQUEST_SIZE
snap resb NEBO_DEBUGGER_SNAPSHOT_SIZE
section .text
prep:
 lea rdi,[req]
 mov ecx,NEBO_DEBUGGER_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [req],rax
 mov qword [req+8],0xabc
 ret
global _start
_start:
 lea rdi,[authority]
 mov esi,0x2408
 lea rdx,[secret]
 call nebo_capability_authority_init
 test eax,eax
 jnz fail
 lea rdi,[grant]
 mov ecx,7
 xor eax,eax
 rep stosq
 lea rax,[authority]
 mov [grant],rax
 lea rax,[cap]
 mov [grant+8],rax
 mov qword [grant+16],NEBO_CAPABILITY_PROCESS
 mov qword [grant+24],NEBO_EFFECT_PROCESS
 mov qword [grant+32],1
 mov qword [grant+40],20
 mov qword [grant+48],8
 lea rdi,[grant]
 call nebo_capability_grant
 test eax,eax
 jnz fail
 lea rdi,[init]
 mov ecx,7
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [init],rax
 lea rax,[bps]
 mov [init+8],rax
 mov qword [init+16],4
 lea rax,[authority]
 mov [init+24],rax
 lea rax,[cap]
 mov [init+32],rax
 mov qword [init+40],8
 mov qword [init+48],1
 lea rdi,[init]
 call nebo_debugger_init
 test eax,eax
 jnz fail
 call prep
 mov qword [req+16],1234
 mov qword [req+24],NEBO_DEBUGGER_OP_LAUNCH
 lea rdi,[req]
 call nebo_debugger_control
 test eax,eax
 jnz fail
 call prep
 mov qword [req+24],NEBO_DEBUGGER_OP_STOP
 lea rdi,[req]
 call nebo_debugger_control
 test eax,eax
 jnz fail
 call prep
 mov qword [req+24],NEBO_DEBUGGER_OP_BREAKPOINT
 mov qword [req+32],0x401000
 lea rdi,[req]
 call nebo_debugger_control
 test eax,eax
 jnz fail
 lea rdi,[req]
 call nebo_debugger_control
 cmp eax,NEBO_DEBUGGER_STATUS_STATE
 jne fail
 lea rdi,[snap]
 mov ecx,8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [snap],rax
 mov qword [snap+8],0xabc
 mov qword [snap+16],1
 mov qword [snap+24],64
 mov qword [snap+32],256
 mov qword [snap+40],nebo_privacy_PRIVACY_SECRET
 lea rdi,[snap]
 call nebo_debugger_snapshot
 cmp eax,NEBO_DEBUGGER_STATUS_PRIVACY
 jne fail
 mov qword [snap+48],1
 lea rdi,[snap]
 call nebo_debugger_snapshot
 test eax,eax
 jnz fail
 call prep
 mov qword [req+8],0xdef
 mov qword [req+24],NEBO_DEBUGGER_OP_STEP
 lea rdi,[req]
 call nebo_debugger_control
 cmp eax,NEBO_DEBUGGER_STATUS_OWNERSHIP
 jne fail
 call prep
 mov qword [req+24],NEBO_DEBUGGER_OP_TERMINATE
 lea rdi,[req]
 call nebo_debugger_control
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_DEBUGGER_STATE_PID],0
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
