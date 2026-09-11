bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"

global _start
extern neboc_source_map_new
extern neboc_source_map_add_file
extern neboc_source_map_line_column
extern neboc_source_map_resolve
extern neboc_source_map_snippet
extern neboc_source_map_display_path
extern neboc_span_merge
extern neboc_span_related_location
extern neboc_span_add_expansion
extern neboc_span_expansion_trace
extern neboc_span_source_digest
extern neboc_source_map_invalidate
extern neboc_host_process_exit

%define DIGEST 0x1122334455667788
section .rodata
path: db "workspace/src/main.no"
path_len equ $-path
bad_path: db "/private/main.no"
bad_path_len equ $-bad_path
source: db "a",9,"e",0xcc,0x81," ",0xf0,0x9f,0x98,0x80,10,"next",10
source_len equ $-source

section .data
request: dq path,path_len,source,source_len,DIGEST
bad_request: dq bad_path,bad_path_len,source,source_len,DIGEST
span:
 dq 1,6,10,source_len
 dq DIGEST,1,0,0
 times (NEBOC_SPAN_SIZE-64)/8 dq 0
span_first:
 dq 1,2,5,source_len
 dq DIGEST,1,0,0
 times (NEBOC_SPAN_SIZE-64)/8 dq 0
span_last:
 dq 1,6,10,source_len
 dq DIGEST,1,0,0
 times (NEBOC_SPAN_SIZE-64)/8 dq 0

section .bss align=16
source_map: resb NEBOC_SOURCE_MAP_SIZE
entries: resb NEBOC_SOURCE_ENTRY_SIZE*4
location: resb NEBOC_SOURCE_MAP_SOURCE_LOCATION_SIZE
resolved: resb NEBOC_RESOLVED_SIZE
snippet: resb NEBOC_SOURCE_MAP_SNIPPET_SIZE
slice: resb neboc_recovery_SLICE_SIZE
merged: resb NEBOC_SPAN_SIZE
file_id: resq 1
scalar: resq 1

section .text
_start:
 sub rsp,8
 lea rdi,[rel source_map]
 lea rsi,[rel entries]
 mov edx,4
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jne .fail1
 lea rdi,[rel source_map]
 lea rsi,[rel bad_request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail2
 cmp qword [rel source_map+NEBOC_SOURCE_MAP_COUNT_OFFSET],0
 jne .fail3
 lea rdi,[rel source_map]
 lea rsi,[rel request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 test eax,eax
 jne .fail4
 cmp qword [rel file_id],1
 jne .fail5

 lea rdi,[rel source_map]
 mov esi,1
 mov edx,6
 lea rcx,[rel location]
 call neboc_source_map_line_column
 test eax,eax
 jne .fail6
 cmp qword [rel location+NEBOC_MACHINE_SOURCE_LOCATION_LINE_OFFSET],1
 jne .fail7
 cmp qword [rel location+NEBOC_SOURCE_LOCATION_BYTE_COLUMN_OFFSET],7
 jne .fail8
 cmp qword [rel location+NEBOC_SOURCE_LOCATION_SCALAR_COLUMN_OFFSET],6
 jne .fail9
 cmp qword [rel location+NEBOC_SOURCE_LOCATION_DISPLAY_COLUMN_OFFSET],7
 jne .fail10
 lea rdi,[rel source_map]
 mov esi,1
 mov edx,4
 lea rcx,[rel location]
 call neboc_source_map_line_column
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail11

 lea rdi,[rel source_map]
 lea rsi,[rel span]
 lea rdx,[rel resolved]
 call neboc_source_map_resolve
 test eax,eax
 jne .fail12
 cmp qword [rel resolved+NEBOC_RESOLVED_END_OFFSET+NEBOC_SOURCE_LOCATION_DISPLAY_COLUMN_OFFSET],9
 jne .fail13
 lea rdi,[rel source_map]
 lea rsi,[rel span]
 mov edx,1
 lea rcx,[rel snippet]
 call neboc_source_map_snippet
 test eax,eax
 jne .fail14
 cmp qword [rel snippet+NEBOC_SOURCE_MAP_SNIPPET_HIGHLIGHT_START_OFFSET],6
 jne .fail15

 lea rdi,[rel source_map]
 mov esi,1
 mov edx,NEBOC_PATH_STYLE_BASENAME
 lea rcx,[rel slice]
 call neboc_source_map_display_path
 test eax,eax
 jne .fail16
 cmp qword [rel slice+neboc_recovery_SLICE_LENGTH_OFFSET],7
 jne .fail17

 lea rdi,[rel merged]
 lea rsi,[rel span_first]
 lea rdx,[rel span_last]
 call neboc_span_merge
 test eax,eax
 jne .fail18
 cmp qword [rel merged+NEBOC_SOURCE_SPAN_START_OFFSET],2
 jne .fail19
 cmp qword [rel merged+NEBOC_SOURCE_SPAN_END_OFFSET],10
 jne .fail20
 lea rdi,[rel merged]
 mov esi,NEBOC_RELATED_DECLARATION
 lea rdx,[rel span_first]
 call neboc_span_related_location
 test eax,eax
 jne .fail21
 lea rdi,[rel merged]
 mov esi,NEBOC_RELATED_EXPANSION
 lea rdx,[rel span_last]
 call neboc_span_add_expansion
 test eax,eax
 jne .fail22
 lea rdi,[rel merged]
 lea rsi,[rel slice]
 call neboc_span_expansion_trace
 test eax,eax
 jne .fail23
 cmp qword [rel slice+neboc_recovery_SLICE_LENGTH_OFFSET],1
 jne .fail24
 lea rdi,[rel merged]
 lea rsi,[rel scalar]
 call neboc_span_source_digest
 test eax,eax
 jne .fail25
 mov rax,DIGEST
 cmp [rel scalar],rax
 jne .fail26

 lea rdi,[rel source_map]
 mov esi,1
 mov rdx,0x2233445566778899
 call neboc_source_map_invalidate
 test eax,eax
 jne .fail27
 lea rdi,[rel source_map]
 lea rsi,[rel span]
 lea rdx,[rel resolved]
 call neboc_source_map_resolve
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail28

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 28
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
