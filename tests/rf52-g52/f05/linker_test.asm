bits 64
default rel
%include "compiler/linker/internal_linker.inc"
global _start
extern neboc_internal_linker_new,neboc_linker_add_object,neboc_linker_add_archive
extern neboc_linker_resolve_symbols,neboc_linker_build_reachability,neboc_linker_layout
extern neboc_linker_apply_relocations,neboc_linker_emit_executable,neboc_linker_map_file
extern neboc_linker_verify,neboc_linker_compare_external_oracle,neboc_cli_link_internal
extern neboc_host_process_exit
section .bss align=16
linker: resb NEBOC_LINK_SIZE
object: resb 64
image: resb NEBOC_LINK_IMAGE_SIZE
out: resq 12
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
 test eax,eax
 jne .f1
 lea rdi,[rel linker]
 lea rsi,[rel object]
 mov edx,64
 mov ecx,0x1234
 call neboc_linker_add_object
 test eax,eax
 jne .f2
 lea rdi,[rel linker]
 call neboc_linker_resolve_symbols
 test eax,eax
 jne .f3
 lea rdi,[rel linker]
 mov esi,1
 call neboc_linker_build_reachability
 test eax,eax
 jne .f4
 lea rdi,[rel linker]
 mov esi,1
 call neboc_linker_layout
 test eax,eax
 jne .f5
 lea rdi,[rel linker]
 call neboc_linker_apply_relocations
 test eax,eax
 jne .f6
 lea rdi,[rel linker]
 lea rsi,[rel image]
 mov edx,NEBOC_LINK_IMAGE_SIZE
 lea rcx,[rel out]
 call neboc_linker_emit_executable
 test eax,eax
 jne .f7
 cmp qword [rel out],NEBOC_LINK_IMAGE_SIZE
 jne .f8
 cmp word [rel image+16],2
 jne .f9
 cmp dword [rel image+68],5
 jne .f10
 lea rdi,[rel linker]
 lea rsi,[rel image]
 mov edx,NEBOC_LINK_IMAGE_SIZE
 call neboc_linker_verify
 test eax,eax
 jne .f11
 lea rdi,[rel linker]
 lea rsi,[rel out]
 call neboc_linker_map_file
 cmp qword [rel out+24],1
 jne .f12
 lea rdi,[rel linker]
 mov esi,0x77
 mov edx,0x77
 lea rcx,[rel out]
 call neboc_linker_compare_external_oracle
 cmp qword [rel out],1
 jne .f13
 lea rdi,[rel linker]
 lea rsi,[rel image]
 mov edx,128
 lea rcx,[rel out]
 call neboc_cli_link_internal
 cmp eax,8
 jne .f14
 lea rdi,[rel linker]
 xor esi,esi
 mov edx,1
 call neboc_linker_add_archive
 cmp eax,4
 jne .f15
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 15
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
