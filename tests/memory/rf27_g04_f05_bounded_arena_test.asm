; TEXT-CHAR-UNICODE-E-BYTES-F05 fixed-arena success, failure and atomicity proof
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "runtime/memory/bounded_arena.inc"

extern neboc_bounded_arena_init
extern neboc_layout_check
extern neboc_bounded_arena_allocate
extern neboc_bounded_arena_reset
extern neboc_arena_borrow_begin
extern neboc_arena_borrow_end
extern neboc_arena_deallocate
extern neboc_host_process_exit

section .bss align=4096
reservation: resb 16
arena: resb neboc_text_char_unicode_e_bytes_ARENA_SIZE
layout: resb neboc_text_char_unicode_e_bytes_LAYOUT_SIZE
result: resb neboc_text_char_unicode_e_bytes_RESULT_SIZE
block_result: resb neboc_text_char_unicode_e_bytes_RESULT_SIZE
snapshot: resq 6

section .text

take_snapshot:
 mov rax,[rel arena+NEBOC_ARENA_CURSOR_OFFSET]
 mov [rel snapshot],rax
 mov rax,[rel arena+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET]
 mov [rel snapshot+8],rax
 mov rax,[rel arena+NEBOC_BOUNDED_ARENA_ALLOCATION_COUNT_OFFSET]
 mov [rel snapshot+16],rax
 mov rax,[rel arena+neboc_text_char_unicode_e_bytes_ARENA_HIGH_WATER_OFFSET]
 mov [rel snapshot+24],rax
 mov rax,[rel arena+NEBOC_ARENA_LIVE_BORROWS_OFFSET]
 mov [rel snapshot+32],rax
 mov rax,[rel arena+NEBOC_ARENA_STATE_HASH_OFFSET]
 mov [rel snapshot+40],rax
 ret

assert_snapshot:
 mov rax,[rel snapshot]
 cmp [rel arena+NEBOC_ARENA_CURSOR_OFFSET],rax
 jne fail
 mov rax,[rel snapshot+8]
 cmp [rel arena+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET],rax
 jne fail
 mov rax,[rel snapshot+16]
 cmp [rel arena+NEBOC_BOUNDED_ARENA_ALLOCATION_COUNT_OFFSET],rax
 jne fail
 mov rax,[rel snapshot+24]
 cmp [rel arena+neboc_text_char_unicode_e_bytes_ARENA_HIGH_WATER_OFFSET],rax
 jne fail
 mov rax,[rel snapshot+32]
 cmp [rel arena+NEBOC_ARENA_LIVE_BORROWS_OFFSET],rax
 jne fail
 mov rax,[rel snapshot+40]
 cmp [rel arena+NEBOC_ARENA_STATE_HASH_OFFSET],rax
 jne fail
 ret

set_layout:
 mov [rel layout+neboc_text_char_unicode_e_bytes_LAYOUT_SIZE_OFFSET],rdi
 mov [rel layout+neboc_text_char_unicode_e_bytes_LAYOUT_ALIGNMENT_OFFSET],rsi
 ret

allocate:
 lea rdi,[rel arena]
 lea rsi,[rel layout]
 lea rdx,[rel result]
 jmp neboc_bounded_arena_allocate

expect_error:
 ; EDI=status, ESI=diagnostic
 cmp eax,edi
 jne fail
 cmp qword [rel result+NEBOC_RESULT_TAG_OFFSET],neboc_text_char_unicode_e_bytes_RESULT_ERR
 jne fail
 cmp [rel result+neboc_text_char_unicode_e_bytes_RESULT_DIAGNOSTIC_OFFSET],rsi
 jne fail
 call assert_snapshot
 ret

global _start
_start:
 mov dword [rel fail_code],1
 lea rdi,[rel arena]
 lea rsi,[rel reservation]
 mov edx,1024
 call neboc_bounded_arena_init
 test eax,eax
 jnz fail

 ; Aligned allocations: offset 0/1 then 8/8, cursor 16.
 mov edi,1
 mov esi,1
 call set_layout
 call allocate
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_RESULT_BLOCK_OFFSET_OFFSET],0
 jne fail
 cmp qword [rel result+NEBOC_RESULT_END_OFFSET],1
 jne fail
 mov edi,8
 mov esi,8
 call set_layout
 call allocate
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_RESULT_BLOCK_OFFSET_OFFSET],8
 jne fail
 cmp qword [rel result+NEBOC_RESULT_END_OFFSET],16
 jne fail
 cmp qword [rel arena+NEBOC_BOUNDED_ARENA_ALLOCATION_COUNT_OFFSET],2
 jne fail
 cmp qword [rel arena+neboc_text_char_unicode_e_bytes_ARENA_HIGH_WATER_OFFSET],16
 jne fail

 ; Reset increments generation and clears cursor/count without lowering HWM.
 mov dword [rel fail_code],2
 mov rax,[rel arena+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET]
 mov [rel saved_generation],rax
 lea rdi,[rel arena]
 lea rsi,[rel result]
 call neboc_bounded_arena_reset
 test eax,eax
 jnz fail
 cmp qword [rel arena+NEBOC_ARENA_CURSOR_OFFSET],0
 jne fail
 cmp qword [rel arena+NEBOC_BOUNDED_ARENA_ALLOCATION_COUNT_OFFSET],0
 jne fail
 cmp qword [rel arena+neboc_text_char_unicode_e_bytes_ARENA_HIGH_WATER_OFFSET],16
 jne fail
 mov rax,[rel saved_generation]
 inc rax
 cmp [rel arena+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET],rax
 jne fail

 ; Maximum request and alignment fit in the maximum fixed reservation.
 mov dword [rel fail_code],3
 lea rdi,[rel arena]
 lea rsi,[rel reservation]
 mov edx,NEBOC_MAX_ARENA_CAPACITY
 call neboc_bounded_arena_init
 test eax,eax
 jnz fail
 mov edi,NEBOC_MAX_REQUEST
 mov esi,NEBOC_MAX_ALIGNMENT
 call set_layout
 call allocate
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_RESULT_BLOCK_OFFSET_OFFSET],0
 jne fail
 cmp qword [rel result+NEBOC_RESULT_END_OFFSET],NEBOC_MAX_REQUEST
 jne fail

 ; Reinitialize a 1024-byte arena and position cursor at 1000.
 mov dword [rel fail_code],4
 lea rdi,[rel arena]
 lea rsi,[rel reservation]
 mov edx,1024
 call neboc_bounded_arena_init
 test eax,eax
 jnz fail
 mov edi,1000
 mov esi,1
 call set_layout
 call allocate
 test eax,eax
 jnz fail

 ; Invalid size is atomic.
 call take_snapshot
 xor edi,edi
 mov esi,8
 call set_layout
 call allocate
 mov edi,NEBOC_STATUS_INVALID_ARGUMENT
 mov esi,NEBOC_ARENA_DIAG_SIZE
 call expect_error
 mov edi,65537
 mov esi,8
 call set_layout
 call allocate
 mov edi,NEBOC_STATUS_INVALID_ARGUMENT
 mov esi,NEBOC_ARENA_DIAG_SIZE
 call expect_error

 ; Invalid alignment is atomic.
 mov edi,8
 mov esi,3
 call set_layout
 call allocate
 mov edi,NEBOC_STATUS_INVALID_ARGUMENT
 mov esi,NEBOC_ARENA_DIAG_ALIGNMENT
 call expect_error
 mov edi,8
 mov esi,8192
 call set_layout
 call allocate
 mov edi,NEBOC_STATUS_INVALID_ARGUMENT
 mov esi,NEBOC_ARENA_DIAG_ALIGNMENT
 call expect_error

 ; Aligned end exceeds capacity: Result.Err(OOM), unchanged arena.
 mov edi,64
 mov esi,16
 call set_layout
 call allocate
 mov edi,NEBOC_STATUS_OUT_OF_MEMORY
 mov esi,NEBOC_ARENA_DIAG_EXHAUSTED
 call expect_error

 ; Pure layout arithmetic detects u64 wrap before any arena can mutate.
 mov edi,32
 mov esi,16
 call set_layout
 lea rdi,[rel layout]
 mov rsi,-8
 mov rdx,-1
 lea rcx,[rel result]
 call neboc_layout_check
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 cmp qword [rel result+neboc_text_char_unicode_e_bytes_RESULT_DIAGNOSTIC_OFFSET],NEBOC_ARENA_DIAG_OVERFLOW
 jne fail
 call assert_snapshot

 ; A live borrow blocks reset atomically; release permits reset.
 mov dword [rel fail_code],5
 lea rdi,[rel arena]
 call neboc_arena_borrow_begin
 test eax,eax
 jnz fail
 call take_snapshot
 lea rdi,[rel arena]
 lea rsi,[rel result]
 call neboc_bounded_arena_reset
 mov edi,NEBOC_STATUS_INVALID_ARGUMENT
 mov esi,NEBOC_ARENA_DIAG_RESET_BORROWED
 call expect_error
 lea rdi,[rel arena]
 call neboc_arena_borrow_end
 test eax,eax
 jnz fail
 lea rdi,[rel arena]
 lea rsi,[rel result]
 call neboc_bounded_arena_reset
 test eax,eax
 jnz fail

 ; Individual free and repeated free both reject without cursor rewind.
 mov dword [rel fail_code],6
 mov edi,16
 mov esi,16
 call set_layout
 lea rdi,[rel arena]
 lea rsi,[rel layout]
 lea rdx,[rel block_result]
 call neboc_bounded_arena_allocate
 test eax,eax
 jnz fail
 call take_snapshot
 lea rdi,[rel arena]
 lea rsi,[rel block_result]
 lea rdx,[rel result]
 call neboc_arena_deallocate
 mov edi,NEBOC_STATUS_INVALID_ARGUMENT
 mov esi,NEBOC_ARENA_DIAG_DOUBLE_FREE
 call expect_error
 lea rdi,[rel arena]
 lea rsi,[rel block_result]
 lea rdx,[rel result]
 call neboc_arena_deallocate
 mov edi,NEBOC_STATUS_INVALID_ARGUMENT
 mov esi,NEBOC_ARENA_DIAG_DOUBLE_FREE
 call expect_error

 xor edi,edi
 call neboc_host_process_exit

fail:
 mov edi,[rel fail_code]
 call neboc_host_process_exit

section .data
fail_code: dd 99
align 8
saved_generation: dq 0

section .note.GNU-stack noalloc noexec nowrite progbits
