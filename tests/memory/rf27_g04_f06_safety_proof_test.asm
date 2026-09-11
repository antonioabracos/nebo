; cli_driver-text_char_unicode_e_bytes-F06 native ownership safety/leak proof vectors
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/semantic/memory/move_copy_clone.inc"

extern neboc_ownership_safety_finalize
extern neboc_host_process_exit

section .bss align=16
request: resb neboc_text_char_unicode_e_bytes_SEM_REQUEST_SIZE_driver_cli_linux_x86_64_native_vertical
symbols: resb 2*NEBOC_SYMBOL_SIZE
tokens: resb NEBOC_TOKEN_SIZE

section .text
global _start
_start:
 call test_dropped_owner
 test eax,eax
 jnz test_fail_1
 call test_moved_owner
 test eax,eax
 jnz test_fail_2
 call test_live_owner_leak_span
 test eax,eax
 jnz test_fail_3
 call test_released_borrow
 test eax,eax
 jnz test_fail_4
 call test_live_borrow_leak
 test eax,eax
 jnz test_fail_5
 call test_missing_cleanup
 test eax,eax
 jnz test_fail_6
 xor edi,edi
 jmp neboc_host_process_exit
test_fail_1: mov edi,1
 jmp neboc_host_process_exit
test_fail_2: mov edi,2
 jmp neboc_host_process_exit
test_fail_3: mov edi,3
 jmp neboc_host_process_exit
test_fail_4: mov edi,4
 jmp neboc_host_process_exit
test_fail_5: mov edi,5
 jmp neboc_host_process_exit
test_fail_6: mov edi,6
 jmp neboc_host_process_exit

reset_fixture:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,neboc_text_char_unicode_e_bytes_SEM_REQUEST_QWORDS
 rep stosq
 lea rdi,[rel symbols]
 mov ecx,(2*NEBOC_SYMBOL_SIZE)/8
 rep stosq
 lea rdi,[rel tokens]
 mov ecx,NEBOC_TOKEN_QWORDS
 rep stosq
 lea rax,[rel symbols]
 mov [rel request+NEBOC_SEM_SYMBOLS_OFFSET],rax
 mov qword [rel request+NEBOC_SEM_SYMBOL_CAPACITY_OFFSET],2
 lea rax,[rel tokens]
 mov [rel request+NEBOC_SEM_TOKENS_OFFSET],rax
 mov qword [rel request+NEBOC_SEM_TOKEN_COUNT_OFFSET],1
 mov qword [rel tokens+NEBOC_TOKEN_START_OFFSET],10
 mov qword [rel tokens+NEBOC_TOKEN_END_OFFSET],15
 ret

set_owner:
 mov qword [rel symbols+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_OWNER
 mov qword [rel symbols+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET],NEBOC_CLEANUP_REQUIRED
 mov qword [rel request+NEBOC_SEM_SYMBOL_COUNT_OFFSET],1
 ret

test_dropped_owner:
 sub rsp,8
 call reset_fixture
 call set_owner
 mov qword [rel symbols+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_DROPPED
 mov qword [rel request+NEBOC_SEM_CLEANUP_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET],1
 lea rdi,[rel request]
 call neboc_ownership_safety_finalize
 test eax,eax
 jnz .fail
 cmp qword [rel request+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET],1
 jne .fail
 cmp qword [rel request+NEBOC_SEM_LIVE_OWNER_COUNT_OFFSET],0
 jne .fail
 cmp qword [rel request+NEBOC_SEM_SAFETY_PROOF_HASH_OFFSET],0
 je .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done: add rsp,8
 ret

test_moved_owner:
 sub rsp,8
 call reset_fixture
 call set_owner
 mov qword [rel symbols+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_MOVED
 lea rdi,[rel request]
 call neboc_ownership_safety_finalize
 test eax,eax
 jnz .fail
 cmp qword [rel request+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET],0
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done: add rsp,8
 ret

test_live_owner_leak_span:
 sub rsp,8
 call reset_fixture
 call set_owner
 mov qword [rel symbols+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 lea rdi,[rel request]
 call neboc_ownership_safety_finalize
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel request+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],NEBOC_DIAG_RESOURCE_LEAK_PATH
 jne .fail
 cmp qword [rel request+neboc_text_char_unicode_e_bytes_SEM_ERROR_START_OFFSET_semantic_memory_native_vertical],10
 jne .fail
 cmp qword [rel request+neboc_text_char_unicode_e_bytes_SEM_ERROR_END_OFFSET_semantic_memory_native_vertical],15
 jne .fail
 cmp qword [rel request+NEBOC_SEM_LIVE_OWNER_COUNT_OFFSET],1
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done: add rsp,8
 ret

test_released_borrow:
 sub rsp,8
 call reset_fixture
 mov qword [rel symbols+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_SHARED_BORROW
 mov qword [rel symbols+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_RELEASED
 mov qword [rel request+NEBOC_SEM_SYMBOL_COUNT_OFFSET],1
 lea rdi,[rel request]
 call neboc_ownership_safety_finalize
 test eax,eax
 jnz .fail
 cmp qword [rel request+NEBOC_SEM_LIVE_OWNER_COUNT_OFFSET],0
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done: add rsp,8
 ret

test_live_borrow_leak:
 sub rsp,8
 call reset_fixture
 mov qword [rel symbols+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_BORROW
 mov qword [rel symbols+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 mov qword [rel request+NEBOC_SEM_SYMBOL_COUNT_OFFSET],1
 lea rdi,[rel request]
 call neboc_ownership_safety_finalize
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel request+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],NEBOC_DIAG_RESOURCE_LEAK_PATH
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done: add rsp,8
 ret

test_missing_cleanup:
 sub rsp,8
 call reset_fixture
 call set_owner
 mov qword [rel symbols+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_DROPPED
 mov qword [rel request+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET],1
 lea rdi,[rel request]
 call neboc_ownership_safety_finalize
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel request+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],NEBOC_DIAG_RESOURCE_LEAK_PATH
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done: add rsp,8
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
