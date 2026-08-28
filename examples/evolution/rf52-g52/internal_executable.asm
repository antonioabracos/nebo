; Emits the bounded internal-linker ELF64 static executable to stdout.
bits 64
default rel
%include "compiler/linker/internal_linker.inc"
global _start
extern neboc_internal_linker_new,neboc_linker_add_object,neboc_linker_resolve_symbols
extern neboc_linker_build_reachability,neboc_linker_layout,neboc_linker_apply_relocations
extern neboc_linker_emit_executable,neboc_host_process_exit
section .bss align=16
linker: resb NEBOC_LINK_SIZE
object: resb 64
image: resb NEBOC_LINK_IMAGE_SIZE
written: resq 1
section .text
_start:
 sub rsp,8
 mov dword [rel object],0x464c457f
 mov byte [rel object+4],2
 mov word [rel object+16],1
 mov word [rel object+18],62
 lea rdi,[rel linker]
 mov esi,1
 mov edx,1
 mov ecx,4
 call neboc_internal_linker_new
 lea rdi,[rel linker]
 lea rsi,[rel object]
 mov edx,64
 mov ecx,0x1234
 call neboc_linker_add_object
 lea rdi,[rel linker]
 call neboc_linker_resolve_symbols
 lea rdi,[rel linker]
 mov esi,1
 call neboc_linker_build_reachability
 lea rdi,[rel linker]
 mov esi,1
 call neboc_linker_layout
 lea rdi,[rel linker]
 call neboc_linker_apply_relocations
 lea rdi,[rel linker]
 lea rsi,[rel image]
 mov edx,NEBOC_LINK_IMAGE_SIZE
 lea rcx,[rel written]
 call neboc_linker_emit_executable
 test eax,eax
 jne .fail
 mov eax,1
 mov edi,1
 lea rsi,[rel image]
 mov edx,NEBOC_LINK_IMAGE_SIZE
 syscall
 cmp rax,NEBOC_LINK_IMAGE_SIZE
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail: mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
