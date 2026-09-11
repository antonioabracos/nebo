bits 64
default rel
%include "compiler/target/conformance.inc"
global _start
extern neboc_target_conformance_suite_for_target,neboc_conformance_compile_corpus
extern neboc_conformance_run_corpus,neboc_conformance_abi_vectors
extern neboc_conformance_object_vectors,neboc_conformance_runtime_vectors
extern neboc_conformance_cross_host_reproducibility,neboc_target_maturity_classify
extern neboc_conformance_report,neboc_cli_conformance_target,neboc_cli_target_matrix
extern neboc_cli_conformance_report,neboc_host_process_exit
section .bss align=16
suite: resb NEBOC_CONF_SIZE
suite2: resb NEBOC_CONF_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel suite]
 mov esi,1
 call neboc_target_conformance_suite_for_target
 test eax,eax
 jne .fail1
 call neboc_conformance_compile_corpus
 test eax,eax
 jne .fail2
 mov esi,3
 call neboc_conformance_run_corpus
 test eax,eax
 jne .fail3
 call neboc_conformance_abi_vectors
 test eax,eax
 jne .fail4
 call neboc_conformance_object_vectors
 test eax,eax
 jne .fail5
 call neboc_conformance_runtime_vectors
 test eax,eax
 jne .fail6
 mov esi,1
 call neboc_conformance_cross_host_reproducibility
 cmp eax,6
 jne .fail7
 lea rsi,[rel out]
 call neboc_target_maturity_classify
 test eax,eax
 jne .fail8
 cmp qword [rel out],4
 jne .fail9
 call neboc_conformance_report
 test eax,eax
 jne .fail10
 cmp qword [rel out+16],0x1f
 jne .fail11
 lea rdi,[rel suite2]
 mov esi,2
 call neboc_target_conformance_suite_for_target
 test eax,eax
 jne .fail12
 call neboc_conformance_compile_corpus
 cmp eax,6
 jne .fail13
 lea rsi,[rel out]
 call neboc_target_maturity_classify
 cmp qword [rel out],1
 jne .fail14
 lea rdi,[rel suite]
 mov esi,3
 lea rdx,[rel out]
 call neboc_cli_conformance_target
 test eax,eax
 jne .fail15
 cmp qword [rel out],4
 jne .fail16
 lea rdi,[rel out]
 call neboc_cli_target_matrix
 test eax,eax
 jne .fail17
 cmp qword [rel out+8],4
 jne .fail18
 lea rdi,[rel suite]
 lea rsi,[rel out]
 call neboc_cli_conformance_report
 test eax,eax
 jne .fail19
 cmp qword [rel out],1
 jne .fail20
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 20
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
