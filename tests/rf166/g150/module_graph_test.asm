; RF166-G150 native owner conformance: identity, roots, units, graph and cache.
bits 64
default rel
%include "compiler/semantic/modules/modules.inc"
global _start
extern neboc_module_id
extern neboc_module_id_parse
extern neboc_module_id_digest
extern neboc_module_root_discover
extern neboc_source_unit_discover
extern neboc_module_add_unit
extern neboc_source_units_sort
extern neboc_module_graph_build
extern neboc_module_graph_order
extern neboc_module_graph_detect_cycles
extern neboc_module_graph_explain
extern neboc_module_path_validate
extern neboc_module_path_collision
extern neboc_module_diagnostic
extern neboc_module_graph_invalidate
extern neboc_module_graph_cache_key

section .rodata
package: db 'nebo.core'
path: db 'std.math'
identity_text: db 'nebo.core:std.math'
bad_package: db 'nebo..core'
workspace: db '/work'
root: db '/work/src'
escaped_root: db '/workbench/src'
filesystem_workspace: db '/'
filesystem_root: db '/srv/nebo'
unit_path: db 'src.main'
same_path: db 'std.math'
other_path: db 'std.algebra'
bad_path: db 'Std.math'
bad_unicode_path: db 'std.m',0xc3,0xa1,'th'

section .data
align 8
units: dq 2,3,1, 1,2,1, 1,1,2, 0,0,0, 0,0,0
candidate: dq 1,4,3
duplicate_candidate: dq 2,4,1
nodes: dq 30,10,20
edges: dq 1,2, 2,0
cycle: dq 0,1, 1,0
dependents: dq 2,4,0
bad_dependents: dq 8,0,0
id_a: times 3 dq 0
id_b: times 3 dq 0
unit_discovered: times 3 dq 0
explain: times 4 dq 0
out: times 16 dq 0

section .text
_start:
 lea rdi,[rel package]
 mov esi,9
 lea rdx,[rel path]
 mov ecx,8
 lea r8,[rel id_a]
 call neboc_module_id
 test eax,eax
 jnz .f1
 lea rdi,[rel identity_text]
 mov esi,18
 lea rdx,[rel id_b]
 call neboc_module_id_parse
 test eax,eax
 jnz .f2
 mov rax,[rel id_a+NEBOC_MODULE_ID_DIGEST]
 cmp rax,[rel id_b+NEBOC_MODULE_ID_DIGEST]
 jne .f3
 lea rdi,[rel id_a]
 lea rsi,[rel out]
 call neboc_module_id_digest
 test eax,eax
 jnz .f4
 mov rax,[rel id_a+NEBOC_MODULE_ID_DIGEST]
 cmp rax,[rel out]
 jne .f5
 mov qword [rel out],0x11223344
 lea rdi,[rel bad_package]
 mov esi,10
 lea rdx,[rel path]
 mov ecx,8
 lea r8,[rel out]
 call neboc_module_id
 cmp eax,4
 jne .f6
 cmp qword [rel out],0x11223344
 jne .f7

 lea rdi,[rel workspace]
 mov esi,5
 lea rdx,[rel root]
 mov ecx,9
 lea r8,[rel out]
 call neboc_module_root_discover
 test eax,eax
 jnz .f8
 cmp qword [rel out+NEBOC_ROOT_RELATIVE_OFFSET],6
 jne .f9
 mov qword [rel out],0x55667788
 lea rdi,[rel workspace]
 mov esi,5
 lea rdx,[rel escaped_root]
 mov ecx,14
 lea r8,[rel out]
 call neboc_module_root_discover
 cmp eax,4
 jne .f10
 cmp qword [rel out],0x55667788
 jne .f11
 lea rdi,[rel filesystem_workspace]
 mov esi,1
 lea rdx,[rel filesystem_root]
 mov ecx,9
 lea r8,[rel out]
 call neboc_module_root_discover
 test eax,eax
 jnz .f55
 cmp qword [rel out+NEBOC_ROOT_RELATIVE_OFFSET],1
 jne .f56

 lea rdi,[rel same_path]
 mov esi,8
 lea rdx,[rel path]
 mov ecx,8
 lea r8,[rel out]
 call neboc_module_path_collision
 test eax,eax
 jnz .f12
 cmp qword [rel out],1
 jne .f13
 lea rdi,[rel same_path]
 mov esi,8
 lea rdx,[rel other_path]
 mov ecx,11
 lea r8,[rel out]
 call neboc_module_path_collision
 test eax,eax
 jnz .f14
 cmp qword [rel out],0
 jne .f15
 mov qword [rel out],0x99
 lea rdi,[rel bad_path]
 mov esi,8
 lea rdx,[rel out]
 call neboc_module_path_validate
 cmp eax,4
 jne .f16
 cmp qword [rel out],0x99
 jne .f17

 mov rdi,[rel id_a+NEBOC_MODULE_ID_DIGEST]
 lea rsi,[rel unit_path]
 mov edx,8
 mov ecx,7
 lea r8,[rel unit_discovered]
 call neboc_source_unit_discover
 test eax,eax
 jnz .f18
 cmp qword [rel unit_discovered+NEBOC_SOURCE_UNIT_REVISION],7
 jne .f19
 lea rdi,[rel units]
 mov esi,3
 mov edx,5
 lea rcx,[rel candidate]
 call neboc_module_add_unit
 test eax,eax
 jnz .f20
 lea rdi,[rel units]
 mov esi,4
 mov edx,5
 lea rcx,[rel duplicate_candidate]
 call neboc_module_add_unit
 cmp eax,4
 jne .f21
 lea rdi,[rel units]
 mov esi,4
 lea rdx,[rel out]
 mov ecx,16
 call neboc_source_units_sort
 test eax,eax
 jnz .f22
 cmp qword [rel out],2
 jne .f23
 cmp qword [rel out+8],1
 jne .f24
 cmp qword [rel out+16],3
 jne .f25
 cmp qword [rel out+24],0
 jne .f26

 lea rdi,[rel nodes]
 mov esi,3
 lea rdx,[rel edges]
 mov ecx,2
 lea r8,[rel out]
 call neboc_module_graph_build
 test eax,eax
 jnz .f27
 cmp qword [rel out],0
 je .f28
 lea rdi,[rel nodes]
 mov esi,3
 lea rdx,[rel edges]
 mov ecx,2
 lea r8,[rel out+8]
 mov r9d,15
 call neboc_module_graph_order
 test eax,eax
 jnz .f29
 cmp qword [rel out+8],1
 jne .f30
 cmp qword [rel out+16],2
 jne .f31
 cmp qword [rel out+24],0
 jne .f32
 lea rdi,[rel nodes]
 mov esi,3
 lea rdx,[rel edges]
 mov ecx,2
 mov r8d,20
 lea r9,[rel explain]
 call neboc_module_graph_explain
 test eax,eax
 jnz .f33
 cmp qword [rel explain+NEBOC_MODULE_EXPLAIN_TOPOLOGICAL_RANK],1
 jne .f34
 cmp qword [rel explain+NEBOC_MODULE_EXPLAIN_INCOMING],1
 jne .f35
 cmp qword [rel explain+NEBOC_MODULE_EXPLAIN_OUTGOING],1
 jne .f36
 lea rdi,[rel nodes]
 mov esi,3
 lea rdx,[rel cycle]
 mov ecx,2
 call neboc_module_graph_detect_cycles
 cmp eax,4
 jne .f37

 lea rdi,[rel dependents]
 mov esi,3
 mov edx,1
 lea r8,[rel out]
 call neboc_module_graph_invalidate
 test eax,eax
 jnz .f38
 cmp qword [rel out],7
 jne .f39
 mov qword [rel out],0xabcdef
 lea rdi,[rel bad_dependents]
 mov esi,3
 mov edx,1
 lea r8,[rel out]
 call neboc_module_graph_invalidate
 cmp eax,4
 jne .f40
 cmp qword [rel out],0xabcdef
 jne .f41
 mov rdi,101
 mov esi,7
 mov edx,303
 lea rcx,[rel out]
 call neboc_module_graph_cache_key
 test eax,eax
 jnz .f42
 mov r12,[rel out]
 mov rdi,101
 mov esi,8
 mov edx,303
 lea rcx,[rel out+8]
 call neboc_module_graph_cache_key
 test eax,eax
 jnz .f43
 cmp r12,[rel out+8]
 je .f44

 ; Every caller-owned result rejects partial or exact aliases with inputs.
 lea rdi,[rel id_a]
 lea rsi,[rel id_a]
 call neboc_module_id_digest
 cmp eax,1
 jne .f47
 lea rdi,[rel same_path]
 mov esi,8
 lea rdx,[rel other_path]
 mov ecx,11
 lea r8,[rel same_path]
 call neboc_module_path_collision
 cmp eax,1
 jne .f48
 mov rdi,[rel id_a+NEBOC_MODULE_ID_DIGEST]
 lea rsi,[rel unit_path]
 mov edx,8
 mov ecx,7
 lea r8,[rel unit_path]
 call neboc_source_unit_discover
 cmp eax,1
 jne .f49
 lea rdi,[rel units]
 mov esi,3
 mov edx,5
 lea rcx,[rel units]
 call neboc_module_add_unit
 cmp eax,1
 jne .f50
 lea rdi,[rel nodes]
 mov esi,3
 lea rdx,[rel edges]
 mov ecx,2
 lea r8,[rel nodes]
 call neboc_module_graph_build
 cmp eax,1
 jne .f51
 lea rdi,[rel nodes]
 mov esi,3
 lea rdx,[rel edges]
 mov ecx,2
 mov r8d,20
 lea r9,[rel nodes]
 call neboc_module_graph_explain
 cmp eax,1
 jne .f52
 mov eax,0xdeadbeef
 mov [rel out],rax
 lea rdi,[rel bad_unicode_path]
 mov esi,9
 lea rdx,[rel out]
 call neboc_module_path_validate
 cmp eax,4
 jne .f53
 mov rax,[rel out]
 mov edx,0xdeadbeef
 cmp rax,rdx
 jne .f54

 mov edi,5
 lea rsi,[rel out]
 call neboc_module_diagnostic
 test eax,eax
 jnz .f45
 cmp dword [rel out],16615005
 jne .f46
 xor edi,edi
 jmp .exit

%assign failure_code 1
%rep 56
.f%+ failure_code:
 mov edi,failure_code
 jmp .exit
%assign failure_code failure_code+1
%endrep
.exit:
 mov eax,60
 syscall
