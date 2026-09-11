bits 64
default rel
%include "compiler/target/target_registry.inc"
%include "compiler/format/object_model.inc"
global _start
extern neboc_object_model_new,neboc_object_writer_for_format,neboc_object_writer_add_section
extern neboc_object_writer_add_symbol,neboc_object_writer_add_relocation,neboc_object_writer_emit
extern neboc_executable_writer_for_target,neboc_executable_writer_add_segment
extern neboc_object_inspector_open,neboc_object_inspector_validate
extern neboc_object_inspector_normalized_digest,neboc_cli_object_report,neboc_host_process_exit
section .data
target: dq 1,1,1,64,16,1,1,1,1,1,0x1f,0x1f,3
bad_target: dq 2,1,1,64,16,2,1,1,1,2,1,7,1
section_desc: dq 1,5,16,64
bad_section: dq 1,5,3,64
symbol_desc: dq 1,1,1,0,0
reloc_desc: dq 2,8,0,0
bad_reloc: dq 9,8,0,0
segment_desc: dq 5,4096,64,64
rwx_segment: dq 7,4096,64,64
section .bss align=16
model: resb NEBOC_OBJECT_SIZE
writer: resb NEBOC_WRITER_SIZE
exec_writer: resb NEBOC_WRITER_SIZE
inspector: resb NEBOC_INSPECTOR_SIZE
image: resb NEBOC_OBJECT_IMAGE_SIZE
image2: resb NEBOC_OBJECT_IMAGE_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel model]
 lea rsi,[rel target]
 call neboc_object_model_new
 test eax,eax
 jne .fail1
 lea rdi,[rel writer]
 lea rsi,[rel model]
 mov edx,1
 call neboc_object_writer_for_format
 test eax,eax
 jne .fail2
 lea rsi,[rel section_desc]
 call neboc_object_writer_add_section
 test eax,eax
 jne .fail3
 lea rsi,[rel bad_section]
 call neboc_object_writer_add_section
 cmp eax,4
 jne .fail4
 lea rsi,[rel symbol_desc]
 call neboc_object_writer_add_symbol
 test eax,eax
 jne .fail5
 lea rsi,[rel reloc_desc]
 call neboc_object_writer_add_relocation
 test eax,eax
 jne .fail6
 lea rsi,[rel bad_reloc]
 call neboc_object_writer_add_relocation
 cmp eax,4
 jne .fail7
 lea rsi,[rel image]
 mov edx,NEBOC_OBJECT_IMAGE_SIZE-1
 lea rcx,[rel out]
 call neboc_object_writer_emit
 cmp eax,8
 jne .fail8
 cmp qword [rel out],0
 jne .fail9
 mov edx,NEBOC_OBJECT_IMAGE_SIZE
 call neboc_object_writer_emit
 test eax,eax
 jne .fail10
 cmp qword [rel out],NEBOC_OBJECT_IMAGE_SIZE
 jne .fail11
 lea rdi,[rel exec_writer]
 lea rsi,[rel bad_target]
 call neboc_executable_writer_for_target
 cmp eax,6
 jne .fail12
 lea rsi,[rel target]
 call neboc_executable_writer_for_target
 test eax,eax
 jne .fail13
 lea rsi,[rel segment_desc]
 call neboc_executable_writer_add_segment
 test eax,eax
 jne .fail14
 lea rsi,[rel rwx_segment]
 call neboc_executable_writer_add_segment
 cmp eax,4
 jne .fail15
 lea rdi,[rel inspector]
 lea rsi,[rel image]
 mov edx,NEBOC_OBJECT_IMAGE_SIZE
 call neboc_object_inspector_open
 test eax,eax
 jne .fail16
 call neboc_object_inspector_validate
 test eax,eax
 jne .fail17
 lea rsi,[rel out]
 call neboc_object_inspector_normalized_digest
 test eax,eax
 jne .fail18
 mov rbx,[rel out]
 call neboc_cli_object_report
 test eax,eax
 jne .fail19
 cmp qword [rel out],1
 jne .fail20
 lea rdi,[rel writer]
 lea rsi,[rel image2]
 mov edx,NEBOC_OBJECT_IMAGE_SIZE
 lea rcx,[rel out]
 call neboc_object_writer_emit
 test eax,eax
 jne .fail21
 lea rsi,[rel image]
 lea rdi,[rel image2]
 mov ecx,NEBOC_OBJECT_IMAGE_SIZE/8
 repe cmpsq
 jne .fail22
 lea rdi,[rel inspector]
 mov qword [rel image],0
 call neboc_object_inspector_validate
 cmp eax,4
 jne .fail23
 test rbx,rbx
 jz .fail24
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 24
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
