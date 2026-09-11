bits 64
default rel
%include "compiler/optimizer/data_footprint.inc"
global _start
extern neboc_data_footprint_analyze,neboc_arena_sizer_from_program
extern neboc_arena_sizer_right_size,neboc_arena_sizer_lazy_reserve
extern neboc_constant_pool_merge_identical,neboc_string_table_compact
extern neboc_static_table_compress_encoding,neboc_workspace_planner_share_non_overlapping
extern neboc_data_footprint_page_touch_report,neboc_data_footprint_limit_report
extern neboc_cli_data_footprint,neboc_host_process_exit
section .data
context:
 dq 100,80,4096,0,512,2048,8192,0,7,10,6,200,256
 dq (0 << 32)|10,(10 << 32)|20,8193,NEBOC_DATA_FLAG_SINGLE_THREAD,0
section .bss align=16
report: resb NEBOC_DATA_REPORT_SIZE
small: resq 3
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_data_footprint_analyze
 test eax,eax
 jne .fail1
 cmp qword [rel report+16],4096
 jne .fail2
 lea rdi,[rel context]
 mov esi,4096
 mov edx,8192
 call neboc_arena_sizer_from_program
 test eax,eax
 jne .fail3
 lea rdi,[rel context]
 mov esi,7
 mov edx,3072
 call neboc_arena_sizer_right_size
 test eax,eax
 jne .fail4
 lea rdi,[rel context]
 mov esi,8
 mov edx,1024
 call neboc_arena_sizer_right_size
 test eax,eax
 jz .fail5
 lea rdi,[rel context]
 call neboc_arena_sizer_lazy_reserve
 test eax,eax
 jne .fail6
 lea rdi,[rel context]
 mov esi,1
 call neboc_constant_pool_merge_identical
 test eax,eax
 jne .fail7
 cmp qword [rel context+NEBOC_DATA_CONSTANT_TOTAL_OFFSET],7
 jne .fail8
 lea rdi,[rel context]
 mov esi,1
 mov edx,120
 call neboc_string_table_compact
 test eax,eax
 jne .fail9
 lea rdi,[rel context]
 mov esi,128
 mov edx,16
 call neboc_static_table_compress_encoding
 test eax,eax
 jne .fail10
 lea rdi,[rel context]
 call neboc_workspace_planner_share_non_overlapping
 test eax,eax
 jne .fail11
 cmp qword [rel context+NEBOC_DATA_WORKSPACE_OFFSET],1024
 jne .fail12
 mov qword [rel context+NEBOC_DATA_TOUCHED_OFFSET],8193
 lea rdi,[rel context]
 lea rsi,[rel small]
 call neboc_data_footprint_page_touch_report
 test eax,eax
 jne .fail13
 cmp qword [rel small+8],3
 jne .fail14
 lea rdi,[rel context]
 lea rsi,[rel small]
 call neboc_data_footprint_limit_report
 test eax,eax
 jne .fail15
 cmp qword [rel small],8192
 jne .fail16
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_cli_data_footprint
 test eax,eax
 jne .fail17
 ; Demand above the explicit ceiling has a defined failure path.
 lea rdi,[rel context]
 mov esi,9000
 mov edx,8192
 call neboc_arena_sizer_from_program
 test eax,eax
 jz .fail18
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 18
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
