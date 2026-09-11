bits 64
default rel
%include "compiler/linker/link_layout.inc"
global _start
extern neboc_link_layout_new,neboc_link_layout_order_sections
extern neboc_link_layout_relax_branches,neboc_link_layout_relax_relocations
extern neboc_link_layout_merge_strings,neboc_link_layout_localize_symbols
extern neboc_link_layout_strip_sections,neboc_link_layout_split_debug
extern neboc_link_layout_build_id,neboc_link_layout_security_report
extern neboc_link_layout_map_file,neboc_cli_link_report,neboc_host_process_exit
section .bss align=16
context: resb NEBOC_LINK_SIZE
report: resb NEBOC_LINK_REPORT_SIZE
security: resq 2
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 mov esi,1
 mov edx,2
 mov ecx,4096
 mov r8d,NEBOC_LINK_REQUIRED_SECURITY
 call neboc_link_layout_new
 test eax,eax
 jne .fail1
 mov qword [rel context+NEBOC_LINK_BYTES_BEFORE_OFFSET],4096
 mov qword [rel context+NEBOC_LINK_BYTES_AFTER_OFFSET],4096
 lea rdi,[rel context]
 mov esi,1
 mov edx,8
 call neboc_link_layout_order_sections
 test eax,eax
 jne .fail2
 lea rdi,[rel context]
 mov esi,10
 call neboc_link_layout_relax_branches
 test eax,eax
 jne .fail3
 lea rdi,[rel context]
 mov esi,4
 call neboc_link_layout_relax_relocations
 test eax,eax
 jne .fail4
 lea rdi,[rel context]
 mov esi,100
 mov edx,20
 call neboc_link_layout_merge_strings
 test eax,eax
 jne .fail5
 lea rdi,[rel context]
 mov esi,7
 call neboc_link_layout_localize_symbols
 test eax,eax
 jne .fail6
 lea rdi,[rel context]
 mov esi,3
 call neboc_link_layout_strip_sections
 test eax,eax
 jne .fail7
 lea rdi,[rel context]
 mov esi,1
 mov edx,0xabc
 call neboc_link_layout_split_debug
 test eax,eax
 jne .fail8
 lea rdi,[rel context]
 mov esi,0xabc
 mov edx,1
 call neboc_link_layout_build_id
 test eax,eax
 jne .fail9
 lea rdi,[rel context]
 lea rsi,[rel security]
 call neboc_link_layout_security_report
 test eax,eax
 jne .fail10
 cmp qword [rel security+8],1
 jne .fail11
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_link_layout_map_file
 test eax,eax
 jne .fail12
 cmp qword [rel report+8],4096
 jne .fail13
 cmp qword [rel report+16],3954
 jne .fail14
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_cli_link_report
 test eax,eax
 jne .fail15
 ; Allocated-section stripping request is rejected.
 lea rdi,[rel context]
 mov rsi,0x8000000000000000
 call neboc_link_layout_strip_sections
 test eax,eax
 jz .fail16
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 16
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
