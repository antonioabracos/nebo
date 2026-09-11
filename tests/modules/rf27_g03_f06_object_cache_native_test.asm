; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F06 authenticated object-plan and bounded-cache vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/module_parser.inc"
%include "compiler/lowering/modules/module_plan.inc"
%include "compiler/lowering/modules/object_plan.inc"

extern neboc_seguranca_numerica_conversoes_e_overflow_module_parse
extern neboc_module_analyze
extern neboc_module_lower
extern neboc_object_plan_build
extern neboc_object_cache_seal
extern neboc_object_cache_validate
extern neboc_host_process_exit

section .rodata
unit_main: db 'module app import core import util start core.base + util.delta;',10
unit_main_len equ $-unit_main
unit_core: db 'module core export public base = 20;',10
unit_core_len equ $-unit_core
unit_util: db 'module util import core export public delta = 22;',10
unit_util_len equ $-unit_util

section .bss align=16
request: resb NEBOC_MODULE_REQUEST_SIZE
records: resb NEBOC_MODULE_MAX_UNITS*NEBOC_MODULE_RECORD_SIZE
module_plan: resb NEBOC_MODULE_PLAN_SIZE
object_plan: resb NEBOC_OBJECT_PLAN_SIZE
cache_record: resb NEBOC_CACHE_SIZE
saved_object_hash: resq 1
saved_bundle_key: resq 1

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
 lea rdi,[rel module_plan]
 mov ecx,NEBOC_MODULE_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel object_plan]
 mov ecx,NEBOC_OBJECT_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cache_record]
 mov ecx,NEBOC_CACHE_QWORDS
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

module_pipeline:
 lea rdi,[rel request]
 call neboc_seguranca_numerica_conversoes_e_overflow_module_parse
 test eax,eax
 jnz .done
 lea rdi,[rel request]
 call neboc_module_analyze
 test eax,eax
 jnz .done
 lea rdi,[rel request]
 lea rsi,[rel module_plan]
 call neboc_module_lower
.done:
 ret

object_pipeline:
 call module_pipeline
 test eax,eax
 jnz .done
 lea rdi,[rel module_plan]
 lea rsi,[rel records]
 lea rdx,[rel object_plan]
 call neboc_object_plan_build
.done:
 ret

seal_cache:
 lea rdi,[rel object_plan]
 lea rsi,[rel cache_record]
 jmp neboc_object_cache_seal

validate_cache:
 lea rdi,[rel object_plan]
 lea rsi,[rel cache_record]
 jmp neboc_object_cache_validate

test_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rsi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

_start:
 ; V01: a valid semantic module plan becomes a canonical 136-byte object plan.
 call reset_valid
 call object_pipeline
 test eax,eax
 jnz .fail1
 cmp qword [rel object_plan+NEBOC_OBJECT_MODULE_COUNT_OFFSET],3
 jne .fail1
 cmp qword [rel object_plan+NEBOC_OBJECT_CACHE_MAX_OFFSET],12
 jne .fail1
 cmp qword [rel object_plan+NEBOC_OBJECT_FLAGS_OFFSET],NEBOC_OBJECT_FLAG_CANONICAL_STATIC
 jne .fail1
 cmp qword [rel object_plan+NEBOC_OBJECT_BUNDLE_KEY_OFFSET],0
 je .fail1
 lea rsi,[rel object_plan]
 mov ecx,NEBOC_OBJECT_PLAN_HASHED_BYTES
 call test_hash
 cmp rax,[rel object_plan+NEBOC_OBJECT_HASH_OFFSET]
 jne .fail24

 ; V02: a sealed four-object cache record authenticates exactly.
 call seal_cache
 test eax,eax
 jnz .fail21
 call validate_cache
 test eax,eax
 jnz .fail22
 cmp qword [rel cache_record+NEBOC_CACHE_OBJECT_COUNT_OFFSET],4
 jne .fail23

 ; V03: object-byte drift is a stale cache entry, never a cache hit.
 call seal_cache
 test eax,eax
 jnz .fail3
 xor qword [rel cache_record+NEBOC_CACHE_OBJECT1_HASH_OFFSET],1
 call validate_cache
 cmp eax,NEBOC_OBJECT_DIAG_STALE_CACHE
 jne .fail3
 cmp qword [rel cache_record+NEBOC_CACHE_DIAGNOSTIC_OFFSET],NEBOC_OBJECT_DIAG_STALE_CACHE
 jne .fail3

 ; V04: cached objects carry an exact target ABI identity.
 call seal_cache
 test eax,eax
 jnz .fail4
 xor qword [rel cache_record+NEBOC_CACHE_ABI_HASH_OFFSET],1
 call validate_cache
 cmp eax,NEBOC_OBJECT_DIAG_ABI_MISMATCH
 jne .fail4
 cmp qword [rel cache_record+NEBOC_CACHE_DIAGNOSTIC_OFFSET],NEBOC_OBJECT_DIAG_ABI_MISMATCH
 jne .fail4

 ; V05: a cache entry cannot be reused for a different bundle key.
 call seal_cache
 test eax,eax
 jnz .fail5
 xor qword [rel cache_record+NEBOC_CACHE_BUNDLE_KEY_OFFSET],1
 call validate_cache
 cmp eax,NEBOC_OBJECT_DIAG_STALE_CACHE
 jne .fail5

 ; V06: partial object sets are never accepted.
 call seal_cache
 test eax,eax
 jnz .fail6
 mov qword [rel cache_record+NEBOC_CACHE_OBJECT_COUNT_OFFSET],3
 call validate_cache
 cmp eax,NEBOC_OBJECT_DIAG_STALE_CACHE
 jne .fail6

 ; V07: only complete cache records are reusable.
 call seal_cache
 test eax,eax
 jnz .fail7
 mov qword [rel cache_record+NEBOC_CACHE_FLAGS_OFFSET],0
 call validate_cache
 cmp eax,NEBOC_OBJECT_DIAG_STALE_CACHE
 jne .fail7

 ; V08: an unauthenticated object plan is a partial-artifact failure.
 call seal_cache
 test eax,eax
 jnz .fail8
 xor qword [rel object_plan+NEBOC_OBJECT_HASH_OFFSET],1
 call validate_cache
 cmp eax,NEBOC_OBJECT_DIAG_PARTIAL_ARTIFACT
 jne .fail8
 cmp qword [rel cache_record+NEBOC_CACHE_DIAGNOSTIC_OFFSET],NEBOC_OBJECT_DIAG_PARTIAL_ARTIFACT
 jne .fail8

 ; V09: duplicate strong module identities cannot enter object emission.
 call reset_valid
 call module_pipeline
 test eax,eax
 jnz .fail9
 mov rax,[rel records+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 mov [rel records+NEBOC_MODULE_RECORD_SIZE+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET],rax
 lea rdi,[rel module_plan]
 lea rsi,[rel records]
 lea rdx,[rel object_plan]
 call neboc_object_plan_build
 cmp eax,NEBOC_OBJECT_DIAG_DUPLICATE_SYMBOL
 jne .fail9

 ; V10: auxiliary argv order cannot change object or bundle identity.
 call reset_valid
 call object_pipeline
 test eax,eax
 jnz .fail10
 mov rax,[rel object_plan+NEBOC_OBJECT_HASH_OFFSET]
 mov [rel saved_object_hash],rax
 mov rax,[rel object_plan+NEBOC_OBJECT_BUNDLE_KEY_OFFSET]
 mov [rel saved_bundle_key],rax
 call reset_valid
 mov rax,[rel request+NEBOC_MODULE_SOURCE1_OFFSET]
 mov rdx,[rel request+NEBOC_MODULE_SOURCE2_OFFSET]
 mov [rel request+NEBOC_MODULE_SOURCE1_OFFSET],rdx
 mov [rel request+NEBOC_MODULE_SOURCE2_OFFSET],rax
 mov rax,[rel request+NEBOC_MODULE_LENGTH1_OFFSET]
 mov rdx,[rel request+NEBOC_MODULE_LENGTH2_OFFSET]
 mov [rel request+NEBOC_MODULE_LENGTH1_OFFSET],rdx
 mov [rel request+NEBOC_MODULE_LENGTH2_OFFSET],rax
 call object_pipeline
 test eax,eax
 jnz .fail10
 mov rax,[rel saved_object_hash]
 cmp rax,[rel object_plan+NEBOC_OBJECT_HASH_OFFSET]
 jne .fail10
 mov rax,[rel saved_bundle_key]
 cmp rax,[rel object_plan+NEBOC_OBJECT_BUNDLE_KEY_OFFSET]
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
.fail21: mov edi,21
 jmp neboc_host_process_exit
.fail22: mov edi,22
 jmp neboc_host_process_exit
.fail23: mov edi,23
 jmp neboc_host_process_exit
.fail24: mov edi,24
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
