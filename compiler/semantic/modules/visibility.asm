; G152 module/package visibility authority shared by compiler and tooling.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/selective_import_parser.inc"

section .text

; Visibility.check(record, requester_module, requester_package,
;                  requested_reexport, out_visible)
; Visibility is explicit and never inferred from a symbol name. Imports do
; not grant capabilities; this routine only answers namespace reachability.
NEBOC_ABI_FUNCTION neboc_visibility_check
 test rdi,rdi
 jz .argument
 test r8,r8
 jz .argument
 test rdi,7
 jnz .argument
 test r8,7
 jnz .argument
 mov qword [r8],0
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 cmp rcx,1
 ja .source
 mov rax,[rdi+NEBOC_VIS_RECORD_VISIBILITY_OFFSET]
 cmp rax,NEBOC_VIS_PUBLIC
 je .public
 cmp rax,NEBOC_VIS_INTERNAL
 je .internal
 cmp rax,NEBOC_VIS_PRIVATE
 je .private
 jmp .source
.public:
 test rcx,rcx
 jz .visible
 test qword [rdi+NEBOC_VIS_RECORD_FLAGS_OFFSET],NEBOC_VIS_FLAG_EXPLICIT_REEXPORT
 jz .source
 jmp .visible
.internal:
 test rcx,rcx
 jnz .source
 cmp rdx,[rdi+NEBOC_VIS_RECORD_OWNER_PACKAGE_OFFSET]
 jne .source
 jmp .visible
.private:
 test rcx,rcx
 jnz .source
 cmp rsi,[rdi+NEBOC_VIS_RECORD_OWNER_MODULE_OFFSET]
 jne .source
.visible:
 mov qword [r8],1
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
