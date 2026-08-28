bits 64
default rel
%include "compiler/source/source_map.inc"
global _start
extern neboc_source_map_new
extern neboc_source_map_add_file
extern neboc_source_map_line_column
extern neboc_host_process_exit
section .rodata
path: db "src/example.no"
path_len equ $-path
bytes: db "main",10
bytes_len equ $-bytes
section .data
request: dq path,path_len,bytes,bytes_len,0x51525354
section .bss
map: resb NEBOC_SOURCE_MAP_SIZE
entries: resb NEBOC_SOURCE_ENTRY_SIZE*2
location: resb NEBOC_SOURCE_MAP_SOURCE_LOCATION_SIZE
file_id: resq 1
section .text
_start:
 sub rsp,8
 lea rdi,[rel map]
 lea rsi,[rel entries]
 mov edx,2
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jne .fail
 lea rdi,[rel map]
 lea rsi,[rel request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 test eax,eax
 jne .fail
 lea rdi,[rel map]
 mov esi,1
 mov edx,4
 lea rcx,[rel location]
 call neboc_source_map_line_column
 test eax,eax
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
