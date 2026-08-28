bits 64
default rel
%include "compiler/target/target_registry.inc"
%include "compiler/format/object_model.inc"
global _start
extern neboc_object_model_new,neboc_object_writer_for_format,neboc_object_writer_emit
extern neboc_object_inspector_open,neboc_cli_object_report,neboc_host_process_exit
section .data
target: dq 1,1,1,64,16,1,1,1,1,1,0x1f,0x1f,3
section .bss align=16
model: resb NEBOC_OBJECT_SIZE
writer: resb NEBOC_WRITER_SIZE
inspector: resb NEBOC_INSPECTOR_SIZE
image: resb NEBOC_OBJECT_IMAGE_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel model]
 lea rsi,[rel target]
 call neboc_object_model_new
 test eax,eax
 jne .done
 lea rdi,[rel writer]
 lea rsi,[rel model]
 mov edx,1
 call neboc_object_writer_for_format
 test eax,eax
 jne .done
 lea rsi,[rel image]
 mov edx,NEBOC_OBJECT_IMAGE_SIZE
 lea rcx,[rel out]
 call neboc_object_writer_emit
 test eax,eax
 jne .done
 lea rdi,[rel inspector]
 lea rsi,[rel image]
 mov edx,NEBOC_OBJECT_IMAGE_SIZE
 call neboc_object_inspector_open
 test eax,eax
 jne .done
 lea rsi,[rel out]
 call neboc_cli_object_report
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
