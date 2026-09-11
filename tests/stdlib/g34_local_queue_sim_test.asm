bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "runtime/stdlib/local_queue_sim.inc"
extern neboc_local_queue_simulate
extern neboc_host_process_exit
section .bss align=16
s: resb SIZE
section .text
reset:
 lea rdi,[rel s]
 mov ecx,QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel s+SEQ],10
 mov qword [rel s+EXPECTED],10
 mov qword [rel s+QUEUE_LEN],2
 mov qword [rel s+local_queue_sim_CAPACITY],4
 mov qword [rel s+RETRY_BUDGET],2
 mov qword [rel s+TIMEOUT],10
 mov qword [rel s+ELAPSED],1
 mov qword [rel s+ACK],1
 mov qword [rel s+CLEANUP],1
 call seal
 ret
seal:
 mov rax,SEAL_MAGIC
 lea rdi,[rel s]
 xor edx,edx
 mov ecx,12
.l: xor rax,[rdi+rdx*8]
 inc edx
 loop .l
 mov [rel s+SEAL],rax
 ret
run_ok:
 lea rdi,[rel s]
 call neboc_local_queue_simulate
 test eax,eax
 jnz fail
 ret
run_bad:
 lea rdi,[rel s]
 call neboc_local_queue_simulate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp [rel s+DIAG],rsi
 jne fail
 ret
global _start
_start:
 mov r15d,1
 xor edi,edi
 call neboc_local_queue_simulate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 mov r15d,2
 call reset
 call run_ok
 cmp qword [rel s+RESULT],RESULT_ORDERED
 jne fail
 mov r15d,3
 call reset
 mov qword [rel s+SEQ],9
 mov qword [rel s+DUPLICATES],1
 call seal
 call run_ok
 cmp qword [rel s+RESULT],RESULT_DUPLICATE_DROPPED
 jne fail
 mov r15d,4
 call reset
 mov qword [rel s+SEQ],11
 mov qword [rel s+LOSSES],1
 mov qword [rel s+RETRIES],1
 call seal
 call run_ok
 cmp qword [rel s+RESULT],RESULT_LOSS_RETRIED
 jne fail
 mov r15d,10
 call reset
 mov qword [rel s+QUEUE_LEN],5
 call seal
 mov esi,DIAG_RUNTIME
 call run_bad
 inc r15d
 call reset
 mov qword [rel s+RETRIES],3
 call seal
 mov esi,DIAG_RUNTIME
 call run_bad
 inc r15d
 call reset
 mov qword [rel s+ELAPSED],11
 call seal
 mov esi,DIAG_RUNTIME
 call run_bad
 inc r15d
 call reset
 mov qword [rel s+ACK],0
 call seal
 mov esi,DIAG_RUNTIME
 call run_bad
 inc r15d
 call reset
 mov qword [rel s+CLEANUP],0
 call seal
 mov esi,DIAG_SECURITY
 call run_bad
 inc r15d
 call reset
 inc qword [rel s+SEAL]
 mov esi,DIAG_SECURITY
 call run_bad
 inc r15d
 call reset
 mov qword [rel s+SEQ],11
 call seal
 mov esi,DIAG_RUNTIME
 call run_bad
 xor edi,edi
 jmp neboc_host_process_exit
fail: mov edi,r15d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
