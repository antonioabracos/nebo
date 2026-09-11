; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F05 parser/semantic/lowering vectors for three real units.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/module_parser.inc"
%include "compiler/lowering/modules/module_plan.inc"

extern neboc_seguranca_numerica_conversoes_e_overflow_module_parse
extern neboc_module_analyze
extern neboc_module_lower
extern neboc_host_process_exit

section .rodata
unit_main: db 'module app import core import util start core.base + util.delta;',10
unit_main_len equ $-unit_main
unit_core: db 'module core export public base = 20;',10
unit_core_len equ $-unit_core
unit_util: db 'module util import core export public delta = 22;',10
unit_util_len equ $-unit_util
unit_private: db 'module core export private secret = 20;',10
unit_private_len equ $-unit_private
unit_private_main: db 'module app import core import util start core.secret + util.delta;',10
unit_private_main_len equ $-unit_private_main
unit_missing: db 'module util import ghost export public delta = 22;',10
unit_missing_len equ $-unit_missing
unit_cycle_main: db 'module app import core start core.base;',10
unit_cycle_main_len equ $-unit_cycle_main
unit_cycle_core: db 'module core import util export public base = 20;',10
unit_cycle_core_len equ $-unit_cycle_core
unit_cycle_util: db 'module util import app export public delta = 22;',10
unit_cycle_util_len equ $-unit_cycle_util
unit_duplicate: db 'module core export public delta = 22;',10
unit_duplicate_len equ $-unit_duplicate
unit_missing_export_main: db 'module app import core import util start core.nope + util.delta;',10
unit_missing_export_main_len equ $-unit_missing_export_main
unit_bad: db 'module app import core start core.;',10
unit_bad_len equ $-unit_bad

section .bss align=16
request: resb NEBOC_MODULE_REQUEST_SIZE
records: resb NEBOC_MODULE_MAX_UNITS*NEBOC_MODULE_RECORD_SIZE
plan: resb NEBOC_MODULE_PLAN_SIZE
saved_hash: resq 1

section .text
global _start

reset_valid:
 lea rdi,[rel request]
 mov ecx,NEBOC_MODULE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel records]
 mov ecx,(NEBOC_MODULE_MAX_UNITS*NEBOC_MODULE_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel plan]
 mov ecx,NEBOC_MODULE_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel unit_main]
 mov [rel request+NEBOC_MODULE_SOURCE0_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH0_OFFSET],unit_main_len
 lea rax,[rel unit_core]
 mov [rel request+NEBOC_MODULE_SOURCE1_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH1_OFFSET],unit_core_len
 lea rax,[rel unit_util]
 mov [rel request+NEBOC_MODULE_SOURCE2_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH2_OFFSET],unit_util_len
 lea rax,[rel records]
 mov [rel request+NEBOC_MODULE_RECORDS_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_CAPACITY_OFFSET],NEBOC_MODULE_MAX_UNITS
 ret

pipeline:
 lea rdi,[rel request]
 call neboc_seguranca_numerica_conversoes_e_overflow_module_parse
 test eax,eax
 jnz .done
 lea rdi,[rel request]
 call neboc_module_analyze
 test eax,eax
 jnz .done
 lea rdi,[rel request]
 lea rsi,[rel plan]
 call neboc_module_lower
.done:
 ret

analyze_only:
 lea rdi,[rel request]
 call neboc_seguranca_numerica_conversoes_e_overflow_module_parse
 test eax,eax
 jnz .done
 lea rdi,[rel request]
 call neboc_module_analyze
.done:
 ret

_start:
 ; V01: the three-unit public graph lowers to a pointerless result 42 plan.
 call reset_valid
 call pipeline
 test eax,eax
 jnz .fail1
 cmp qword [rel plan+NEBOC_MODULE_PLAN_RESULT_OFFSET],42
 jne .fail1
 cmp qword [rel plan+NEBOC_MODULE_PLAN_UNIT_COUNT_OFFSET],3
 jne .fail1
 cmp qword [rel plan+NEBOC_MODULE_PLAN_EDGE_COUNT_OFFSET],3
 jne .fail1
 mov rax,[rel plan+NEBOC_MODULE_PLAN_HASH_OFFSET]
 mov [rel saved_hash],rax

 ; V02: auxiliary argv order cannot change the authenticated plan.
 call reset_valid
 mov rax,[rel request+NEBOC_MODULE_SOURCE1_OFFSET]
 mov rdx,[rel request+NEBOC_MODULE_SOURCE2_OFFSET]
 mov [rel request+NEBOC_MODULE_SOURCE1_OFFSET],rdx
 mov [rel request+NEBOC_MODULE_SOURCE2_OFFSET],rax
 mov rax,[rel request+NEBOC_MODULE_LENGTH1_OFFSET]
 mov rdx,[rel request+NEBOC_MODULE_LENGTH2_OFFSET]
 mov [rel request+NEBOC_MODULE_LENGTH1_OFFSET],rdx
 mov [rel request+NEBOC_MODULE_LENGTH2_OFFSET],rax
 call pipeline
 test eax,eax
 jnz .fail2
 mov rax,[rel saved_hash]
 cmp rax,[rel plan+NEBOC_MODULE_PLAN_HASH_OFFSET]
 jne .fail2

 ; V03: private exports cannot cross a module boundary.
 call reset_valid
 lea rax,[rel unit_private_main]
 mov [rel request+NEBOC_MODULE_SOURCE0_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH0_OFFSET],unit_private_main_len
 lea rax,[rel unit_private]
 mov [rel request+NEBOC_MODULE_SOURCE1_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH1_OFFSET],unit_private_len
 call analyze_only
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail3
 cmp qword [rel request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_PRIVATE_ACCESS
 jne .fail3

 ; V04: every import must resolve to a supplied unit.
 call reset_valid
 lea rax,[rel unit_missing]
 mov [rel request+NEBOC_MODULE_SOURCE2_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH2_OFFSET],unit_missing_len
 call analyze_only
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail4
 cmp qword [rel request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_MISSING_UNIT
 jne .fail4

 ; V05: transitive three-node cycles are rejected deterministically.
 call reset_valid
 lea rax,[rel unit_cycle_main]
 mov [rel request+NEBOC_MODULE_SOURCE0_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH0_OFFSET],unit_cycle_main_len
 lea rax,[rel unit_cycle_core]
 mov [rel request+NEBOC_MODULE_SOURCE1_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH1_OFFSET],unit_cycle_core_len
 lea rax,[rel unit_cycle_util]
 mov [rel request+NEBOC_MODULE_SOURCE2_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH2_OFFSET],unit_cycle_util_len
 call analyze_only
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail5
 cmp qword [rel request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_IMPORT_CYCLE
 jne .fail5

 ; V06: duplicate canonical module identities collide.
 call reset_valid
 lea rax,[rel unit_duplicate]
 mov [rel request+NEBOC_MODULE_SOURCE2_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH2_OFFSET],unit_duplicate_len
 call analyze_only
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail6
 cmp qword [rel request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_IDENTITY_COLLISION
 jne .fail6

 ; V07: qualified lookup requires an exported symbol.
 call reset_valid
 lea rax,[rel unit_missing_export_main]
 mov [rel request+NEBOC_MODULE_SOURCE0_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH0_OFFSET],unit_missing_export_main_len
 call analyze_only
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail7
 cmp qword [rel request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_MISSING_EXPORT
 jne .fail7

 ; V08: malformed qualified references fail in the parser.
 call reset_valid
 lea rax,[rel unit_bad]
 mov [rel request+NEBOC_MODULE_SOURCE0_OFFSET],rax
 mov qword [rel request+NEBOC_MODULE_LENGTH0_OFFSET],unit_bad_len
 lea rdi,[rel request]
 call neboc_seguranca_numerica_conversoes_e_overflow_module_parse
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail8
 cmp qword [rel request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_SYNTAX
 jne .fail8

 ; V09: fewer than three record slots is an explicit bounded-capacity error.
 call reset_valid
 mov qword [rel request+NEBOC_MODULE_CAPACITY_OFFSET],2
 lea rdi,[rel request]
 call neboc_seguranca_numerica_conversoes_e_overflow_module_parse
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail9
 cmp qword [rel request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_CAPACITY
 jne .fail9

 ; V10: lowering authenticates the nonzero semantic summary.
 call reset_valid
 call pipeline
 test eax,eax
 jnz .fail10
 mov qword [rel request+NEBOC_MODULE_SEMANTIC_HASH_OFFSET],0
 lea rdi,[rel request]
 lea rsi,[rel plan]
 call neboc_module_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail10

 xor edi,edi
 jmp neboc_host_process_exit
.fail1: mov edi,1
 jmp neboc_host_process_exit
.fail2: mov edi,2
 jmp neboc_host_process_exit
.fail3: mov edi,3
 jmp neboc_host_process_exit
.fail4: mov edi,4
 jmp neboc_host_process_exit
.fail5: mov edi,5
 jmp neboc_host_process_exit
.fail6: mov edi,6
 jmp neboc_host_process_exit
.fail7: mov edi,7
 jmp neboc_host_process_exit
.fail8: mov edi,8
 jmp neboc_host_process_exit
.fail9: mov edi,9
 jmp neboc_host_process_exit
.fail10: mov edi,10
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
