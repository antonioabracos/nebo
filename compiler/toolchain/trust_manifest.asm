; TRUST-MANIFEST-F09 local trust/provenance manifest; no key material accepted or read.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/toolchain/trust_manifest.inc"
section .text
NEBOC_ABI_FUNCTION neboc_trust_manifest_new
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov ecx,8
 lea rdi,[rdi+16]
 xor eax,eax
 rep stosq
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_add_component
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 test rcx,rcx
 jz .source
 cmp qword [rdi+16],NEBOC_TRUST_MAX_COMPONENTS
 jae .limit
 inc qword [rdi+16]
 mov rax,rsi
 rol rax,11
 xor rax,rdx
 xor rax,rcx
 xor [rdi+64],rax
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_add_environment
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 test rcx,rcx
 jz .source
 mov qword [rdi+24],1
 mov rax,rsi
 xor rax,rdx
 xor rax,rcx
 xor [rdi+64],rax
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_add_license
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 inc qword [rdi+32]
 xor [rdi+64],rdx
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_add_review
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rdx,2
 ja .source
 test rcx,rcx
 jz .source
 inc qword [rdi+40]
 xor [rdi+64],rcx
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_add_build_input
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 inc qword [rdi+48]
 xor [rdi+64],rdx
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_add_reproducibility
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jb .source
 cmp rsi,4
 ja .source
 mov [rdi+56],rsi
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_tcb
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+16]
 mov [rsi],rax
 mov qword [rsi+8],7
 mov qword [rsi+16],3
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_diff
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rdi+64]
 xor rax,[rsi+64]
 mov [rdx],rax
 setnz al
 movzx rax,al
 mov [rdx+8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_sign
 ; Signing requires an external provider/capability and is not invoked here.
 test rdi,rdi
 jz .invalid
 mov qword [rdi+72],NEBOC_TRUST_UNSIGNED
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_trust_manifest_verify
 ; rsi=expected digest, rdx=report. Unsigned verification checks hashes offline.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rdi+64]
 cmp rax,rsi
 jne .source
 mov qword [rdx],1
 mov rax,[rdi+72]
 mov [rdx+8],rax
 xor eax,eax
 ret
.source: mov qword [rdx],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_trust_manifest
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov ecx,10
.copy:
 mov rax,[rdi]
 mov [rsi],rax
 add rdi,8
 add rsi,8
 loop .copy
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_provenance_verify
 jmp neboc_trust_manifest_verify
section .note.GNU-stack noalloc noexec nowrite progbits
