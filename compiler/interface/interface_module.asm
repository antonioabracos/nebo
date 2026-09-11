; Material typed constants in an additive optional NI-v1 section.
; This decoder shares the authenticated interface reader and module identity
; owner. It publishes the existing pointerless ModuleRecord, never reparses
; source text or recovers a value from a digest.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/interface/interface_v1.inc"
%include "compiler/parser/module_parser.inc"
%include "compiler/semantic/modules/modules.inc"
extern neboc_interface_read
extern neboc_module_id
section .rodata
ni_module_package: db 'workspace'
section .text
; rdi=NI bytes, rsi=size, rdx=128-byte output; output unchanged on failure.
NEBOC_ABI_FUNCTION neboc_interface_module_decode
 test rdi,rdi
 jz .argument
 test rdx,rdx
 jz .argument
 test rdx,7
 jnz .argument
 cmp rsi,NEBOC_MODULE_MAX_SOURCE_BYTES
 ja .argument
 mov rax,rdi
 add rax,rsi
 jc .argument
 mov rcx,rdx
 add rcx,NEBOC_MODULE_RECORD_SIZE
 jc .argument
 cmp rdx,rax
 jae .ranges
 cmp rdi,rcx
 jb .argument
.ranges:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,4200
 mov r12,rsi
 mov rbp,rdx
 ; Byte transports need not satisfy the native record alignment. Authenticate
 ; an aligned bounded copy before passing its sections to those same owners.
 mov rsi,rdi
 lea rbx,[rsp+104]
 mov rdi,rbx
 mov rcx,r12
 rep movsb
 mov rdi,rbx
 mov rsi,r12
 mov rdx,rsp
 call neboc_interface_read
 test eax,eax
 jnz .bad
 mov rax,0x05e02f6fb268332f ; canonical x86_64-systemv-elf-linux target
 cmp [rsp+40],rax
 jne .bad
 xor r13d,r13d
 xor r14d,r14d
 mov qword [rsp+88],0
 xor ecx,ecx
.sections:
 cmp rcx,[rsp]
 jae .payload
 mov rax,rcx
 shl rax,5
 lea rdx,[rbx+rax+64]
 cmp dword [rdx],NEBOC_NI_SECTION_MODULE_VALUE
 je .module
 cmp dword [rdx],NEBOC_NI_SECTION_METADATA
 je .metadata
 cmp dword [rdx],NEBOC_NI_SECTION_EXPORTS
 jne .next
 cmp qword [rdx+16],64
 jne .bad
 mov r14,[rdx+8]
 add r14,rbx
 jmp .next
.module:
 test r13,r13
 jnz .bad
 cmp dword [rdx+4],1
 jne .bad
 cmp qword [rdx+16],NEBOC_NI_MODULE_VALUE_SIZE
 jne .bad
 mov r13,[rdx+8]
 add r13,rbx
 jmp .next
.metadata:
 cmp qword [rdx+16],64
 jne .bad
 mov rax,[rdx+8]
 add rax,rbx
 mov [rsp+88],rax
.next:
 inc ecx
 jmp .sections
.payload:
 test r13,r13
 jz .bad
 test r14,r14
 jz .bad
 mov rax,NEBOC_NI_MODULE_VALUE_MAGIC
 cmp [r13],rax
 jne .bad
 mov rax,[r13+8]
 cmp rax,[r14]
 jne .bad
 cmp rax,[r14+8]
 jne .bad
 mov rax,0x100000003       ; public constant
 cmp [r14+16],rax
 jne .bad
 mov rax,0x41a91f19c98dd49e ; Int type digest
 cmp [r14+24],rax
 jne .bad
 cmp qword [r14+32],0
 jne .bad
 cmp qword [r14+56],6
 jne .bad
 mov rax,0x50c11edd8177fcc2 ; Int layout: 8-byte size and alignment
 cmp [r14+40],rax
 jne .bad
 mov rdx,[rsp+88]
 test rdx,rdx
 jz .bad
 mov rax,[r13+8]
 cmp [rdx],rax
 jne .bad
 cmp qword [rdx+8],0        ; a pure constant has no effects/capabilities
 jne .bad
 cmp qword [rdx+16],0
 jne .bad
 cmp dword [rdx+24],1
 jne .bad
 cmp qword [r13+16],255  ; existing bounded module constant profile
 ja .bad
 lea rdi,[r13+16]
 mov esi,8
 call ni_module_hash
 cmp rax,[r14+48]
 jne .bad
 mov r15,[r13+24]
 test r15,r15
 jz .bad
 cmp r15,32
 ja .bad
 xor ecx,ecx
.name:
 cmp rcx,r15
 jae .padding
 mov al,[r13+rcx+32]
 cmp al,'a'
 jb .extra
 cmp al,'z'
 jbe .char_ok
.extra:
 test rcx,rcx
 jz .bad
 cmp al,'_'
 je .char_ok
 cmp al,'0'
 jb .bad
 cmp al,'9'
 ja .bad
.char_ok:
 inc ecx
 jmp .name
.padding:
 cmp ecx,48              ; includes both reserved qwords
 jae .identity
 cmp byte [r13+rcx+32],0
 jne .bad
 inc ecx
 jmp .padding
.identity:
 lea rdi,[rel ni_module_package]
 mov esi,9
 lea rdx,[r13+32]
 mov rcx,r15
 lea r8,[rsp+64]
 call neboc_module_id
 test eax,eax
 jnz .bad
 mov rax,[rsp+64+NEBOC_MODULE_ID_DIGEST]
 cmp rax,[rsp+16]
 jne .bad
 ; Only after all integrity, type, identity and value checks may the common
 ; parser record be published. Name offsets still address the exact NI bytes.
 mov rdi,rbp
 mov ecx,NEBOC_MODULE_RECORD_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rsp+64+NEBOC_MODULE_ID_PATH_HASH]
 mov [rbp+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET],rax
 mov rax,[r13+8]
 mov [rbp+NEBOC_MODULE_RECORD_EXPORT_HASH_OFFSET],rax
 mov qword [rbp+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_PUBLIC
 mov rax,[r13+16]
 mov [rbp+NEBOC_MODULE_RECORD_EXPORT_VALUE_OFFSET],rax
 mov qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_EXPORT|NEBOC_MODULE_RECORD_MODERN_IMPORTS
 lea rax,[r13+32]
 sub rax,rbx
 shl r15,32
 or rax,r15
 mov [rbp+NEBOC_MODULE_RECORD_NAME_SPAN_OFFSET],rax
 mov rdi,rbx
 mov rsi,r12
 call ni_module_hash
 mov [rbp+NEBOC_MODULE_RECORD_SOURCE_HASH_OFFSET],rax
 xor eax,eax
 xor edx,edx
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 mov edx,NEBOC_MODULE_DIAG_INTERFACE
.done:
 add rsp,4200
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 mov edx,NEBOC_MODULE_DIAG_INTERFACE
 ret
ni_module_hash:
 mov rax,0xcbf29ce484222325
 mov r8,0x100000001b3
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .done
 movzx edx,byte [rdi+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .loop
.done:
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
