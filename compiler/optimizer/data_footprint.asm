; DATA-FOOTPRINT-F05 bounded data/BSS/arena/workspace minimization model.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/optimizer/data_footprint.inc"
section .text
NEBOC_ABI_FUNCTION neboc_data_footprint_analyze
 ; rdi=context rsi=8-qword output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,rsi
 xor r9d,r9d
.copy:
 cmp r9,6
 jae .summary
 mov rax,[rdi+r9*8]
 mov [r8+r9*8],rax
 inc r9
 jmp .copy
.summary:
 mov rax,[rdi+NEBOC_DATA_ARENA_OFFSET]
 mov [r8+48],rax
 mov rax,[rdi+NEBOC_DATA_TOUCHED_OFFSET]
 mov [r8+56],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arena_sizer_from_program
 ; rdi=context rsi=proved demand rdx=explicit ceiling.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,rdx
 ja .limit
 mov [rdi+NEBOC_DATA_LIMIT_OFFSET],rdx
 mov [rdi+NEBOC_DATA_ARENA_OFFSET],rsi
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arena_sizer_right_size
 ; rdi=context rsi=registered profile version rdx=profile demand.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_DATA_PROFILE_VERSION_OFFSET]
 jne .source
 cmp rdx,[rdi+NEBOC_DATA_LIMIT_OFFSET]
 ja .limit
 mov [rdi+NEBOC_DATA_ARENA_OFFSET],rdx
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arena_sizer_lazy_reserve
 ; Bounded profile is explicitly single-threaded.
 test rdi,rdi
 jz .invalid
 test qword [rdi+NEBOC_DATA_FLAGS_OFFSET],NEBOC_DATA_FLAG_SINGLE_THREAD
 jz .unsupported
 or qword [rdi+NEBOC_DATA_FLAGS_OFFSET],NEBOC_DATA_FLAG_LAZY
 mov qword [rdi+NEBOC_DATA_TOUCHED_OFFSET],0
 xor eax,eax
 ret
.unsupported: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_constant_pool_merge_identical
 ; rdi=context rsi=identity-observable count.
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_DATA_CONSTANT_TOTAL_OFFSET]
 mov rdx,[rdi+NEBOC_DATA_CONSTANT_UNIQUE_OFFSET]
 add rdx,rsi
 cmp rdx,rax
 ja .source
 sub rax,rdx
 add [rdi+NEBOC_DATA_SAVED_OFFSET],rax
 mov [rdi+NEBOC_DATA_CONSTANT_TOTAL_OFFSET],rdx
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_string_table_compact
 ; rdi=context rsi=profile (1 release, 2 debug) rdx=required diagnostic bytes.
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 je .release
 cmp rsi,2
 je .debug
 jmp .invalid
.release:
 mov rax,[rdi+NEBOC_DATA_STRING_BYTES_OFFSET]
 cmp rdx,rax
 ja .source
 sub rax,rdx
 add [rdi+NEBOC_DATA_SAVED_OFFSET],rax
 mov [rdi+NEBOC_DATA_STRING_BYTES_OFFSET],rdx
.debug: xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_static_table_compress_encoding
 ; rdi=context rsi=encoded bytes rdx=bounded decode work.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,64
 ja .limit
 mov rax,[rdi+NEBOC_DATA_STATIC_BYTES_OFFSET]
 cmp rsi,rax
 jae .source
 sub rax,rsi
 add [rdi+NEBOC_DATA_SAVED_OFFSET],rax
 mov [rdi+NEBOC_DATA_STATIC_BYTES_OFFSET],rsi
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_workspace_planner_share_non_overlapping
 ; lifetimes packed as start<<32|end. Overlap is rejected.
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_DATA_LIFE_A_OFFSET]
 mov rcx,rax
 shr rcx,32
 and eax,0xffffffff
 mov r8,[rdi+NEBOC_DATA_LIFE_B_OFFSET]
 mov r9,r8
 shr r9,32
 and r8d,0xffffffff
 cmp rax,r9
 jbe .share
 cmp r8,rcx
 jbe .share
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.share:
 mov rax,[rdi+NEBOC_DATA_WORKSPACE_OFFSET]
 shr rax,1
 add [rdi+NEBOC_DATA_SAVED_OFFSET],rax
 sub [rdi+NEBOC_DATA_WORKSPACE_OFFSET],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_data_footprint_page_touch_report
 ; rdi=context rsi=2-qword output: bytes, ceil(pages).
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_DATA_TOUCHED_OFFSET]
 mov [rsi],rax
 add rax,4095
 shr rax,12
 mov [rsi+8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_data_footprint_limit_report
 ; rdi=context rsi=3-qword output: ceiling, arena, saved.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_DATA_LIMIT_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_DATA_ARENA_OFFSET]
 mov [rsi+8],rax
 mov rax,[rdi+NEBOC_DATA_SAVED_OFFSET]
 mov [rsi+16],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_data_footprint
 jmp neboc_data_footprint_analyze
section .note.GNU-stack noalloc noexec nowrite progbits
