; LINK-LAYOUT-F06 bounded static ELF layout and relaxation model.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/linker/link_layout.inc"
section .text
NEBOC_ABI_FUNCTION neboc_link_layout_new
 ; rdi=context rsi=target rdx=profile rcx=alignment r8=security flags.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov rax,rcx
 dec rax
 test rcx,rax
 jnz .invalid
 mov r9,rdi
 mov r10,rcx
 xor eax,eax
 mov ecx,NEBOC_LINK_SIZE/8
 rep stosq
 mov [r9+NEBOC_LINK_TARGET_OFFSET],rsi
 mov [r9+NEBOC_LINK_PROFILE_OFFSET],rdx
 mov [r9+NEBOC_LINK_ALIGNMENT_OFFSET],r10
 mov [r9+NEBOC_LINK_FLAGS_OFFSET],r8
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_order_sections
 ; rdi=context rsi=policy rdx=section count.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,64
 ja .limit
 mov [rdi+NEBOC_LINK_POLICY_OFFSET],rsi
 mov [rdi+NEBOC_LINK_SECTION_COUNT_OFFSET],rdx
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_relax_branches
 ; rdi=context rsi=eligible branches, bounded 3-byte saving each.
 test rdi,rdi
 jz .invalid
 cmp rsi,4096
 ja .limit
 lea rax,[rsi+rsi*2]
 mov [rdi+NEBOC_LINK_BRANCH_SAVED_OFFSET],rax
 sub [rdi+NEBOC_LINK_BYTES_AFTER_OFFSET],rax
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_relax_relocations
 test rdi,rdi
 jz .invalid
 cmp rsi,4096
 ja .limit
 lea rax,[rsi*8]
 mov [rdi+NEBOC_LINK_RELOC_SAVED_OFFSET],rax
 sub [rdi+NEBOC_LINK_BYTES_AFTER_OFFSET],rax
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_merge_strings
 ; rdi=context rsi=identical bytes rdx=identity-observable bytes.
 test rdi,rdi
 jz .invalid
 cmp rdx,rsi
 ja .source
 sub rsi,rdx
 mov [rdi+NEBOC_LINK_STRING_SAVED_OFFSET],rsi
 sub [rdi+NEBOC_LINK_BYTES_AFTER_OFFSET],rsi
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_localize_symbols
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov [rdi+NEBOC_LINK_LOCALIZED_OFFSET],rsi
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_strip_sections
 ; rdi=context rsi=explicit strip mask, alloc sections bit 63 forbidden.
 test rdi,rdi
 jz .invalid
 bt rsi,63
 jc .source
 mov [rdi+NEBOC_LINK_STRIPPED_OFFSET],rsi
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_split_debug
 ; rdi=context rsi=nonzero local path token rdx=artifact digest.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov [rdi+NEBOC_LINK_DEBUG_DIGEST_OFFSET],rdx
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_build_id
 ; content-derived stable id; rsi=content digest rdx=policy (0 omit,1 content).
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .omit
 cmp rdx,1
 jne .invalid
 mov rax,rsi
 mov rcx,0x9e3779b97f4a7c15
 xor rax,rcx
 rol rax,17
 mov [rdi+NEBOC_LINK_BUILD_ID_OFFSET],rax
 xor eax,eax
 ret
.omit:
 mov qword [rdi+NEBOC_LINK_BUILD_ID_OFFSET],0
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_security_report
 ; rdi=context rsi=2-qword output flags,pass.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_LINK_FLAGS_OFFSET]
 mov [rsi],rax
 and eax,NEBOC_LINK_REQUIRED_SECURITY
 cmp eax,NEBOC_LINK_REQUIRED_SECURITY
 jne .failed
 mov qword [rsi+8],1
 xor eax,eax
 ret
.failed:
 mov qword [rsi+8],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_link_layout_map_file
 ; rdi=context rsi=8-qword bounded map summary.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_LINK_SECTION_COUNT_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_LINK_BYTES_BEFORE_OFFSET]
 mov [rsi+8],rax
 mov rax,[rdi+NEBOC_LINK_BYTES_AFTER_OFFSET]
 mov [rsi+16],rax
 mov rax,[rdi+NEBOC_LINK_BRANCH_SAVED_OFFSET]
 mov [rsi+24],rax
 mov rax,[rdi+NEBOC_LINK_RELOC_SAVED_OFFSET]
 mov [rsi+32],rax
 mov rax,[rdi+NEBOC_LINK_STRING_SAVED_OFFSET]
 mov [rsi+40],rax
 mov rax,[rdi+NEBOC_LINK_BUILD_ID_OFFSET]
 mov [rsi+48],rax
 mov rax,[rdi+NEBOC_LINK_FLAGS_OFFSET]
 mov [rsi+56],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_link_report
 jmp neboc_link_layout_map_file
section .note.GNU-stack noalloc noexec nowrite progbits
