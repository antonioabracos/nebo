; IDENTIDADE-DE-MODULOS-SOURCE-UNITS-ROOTS-E-MODULE-GRAPH-DETERMINISTICO-F01 canonical package/logical-path module identity.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/modules.inc"

section .text

; module_id(package*, package_len, path*, path_len, out_id*) -> status
; Inputs are borrowed. Output is caller-owned and published only after both
; strings validate. Absolute host paths and full-source bytes are not inputs.
NEBOC_ABI_FUNCTION neboc_module_id
 test rdi,rdi
 jz .invalid_argument
 test rdx,rdx
 jz .invalid_argument
 test r8,r8
 jz .invalid_argument
 test r8,7
 jnz .invalid_argument
 test rsi,rsi
 jz .invalid_source
 test rcx,rcx
 jz .invalid_source
 cmp rsi,NEBOC_MODULE_MAX_TEXT
 ja .limit
 cmp rcx,NEBOC_MODULE_MAX_TEXT
 ja .limit
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 ; Package accepts lowercase ASCII identifiers separated by '.', '-' or '_'.
 xor ebx,ebx
.package_loop:
 cmp rbx,r13
 jae .package_done
 movzx eax,byte [r12+rbx]
 cmp al,'a'
 jb .package_extra
 cmp al,'z'
 jbe .package_next
.package_extra:
 cmp al,'0'
 jb .package_separator
 cmp al,'9'
 jbe .package_next
.package_separator:
 cmp al,'.'
 je .package_sep_check
 cmp al,'-'
 je .package_sep_check
 cmp al,'_'
 jne .bad_source
.package_sep_check:
 test rbx,rbx
 jz .bad_source
 lea rax,[rbx+1]
 cmp rax,r13
 jae .bad_source
.package_next:
 inc rbx
 jmp .package_loop
.package_done:
 ; Logical path is lowercase ASCII segments separated by single dots.
 xor ebx,ebx
 mov r10d,1
.path_loop:
 cmp rbx,r15
 jae .path_done
 movzx eax,byte [r14+rbx]
 test r10d,r10d
 jz .path_body
 cmp al,'a'
 jb .bad_source
 cmp al,'z'
 ja .bad_source
 xor r10d,r10d
 jmp .path_next
.path_body:
 cmp al,'.'
 je .path_separator
 cmp al,'a'
 jb .path_digit
 cmp al,'z'
 jbe .path_next
.path_digit:
 cmp al,'0'
 jb .path_underscore
 cmp al,'9'
 jbe .path_next
.path_underscore:
 cmp al,'_'
 jne .bad_source
 jmp .path_next
.path_separator:
 mov r10d,1
.path_next:
 inc rbx
 jmp .path_loop
.path_done:
 test r10d,r10d
 jnz .bad_source
 ; FNV-1a over separate length-delimited fields.
 mov rdi,r12
 mov rsi,r13
 mov rdx,0xcbf29ce484222325
 call module_identity_hash_bytes
 mov r9,rax
 mov rdi,r14
 mov rsi,r15
 mov rdx,0xcbf29ce484222325
 call module_identity_hash_bytes
 mov r10,rax
 mov rax,r9
 rol rax,17
 xor rax,r10
 xor rax,r13
 rol rax,11
 xor rax,r15
 test rax,rax
 jnz .publish
 mov eax,1
.publish:
 mov [r8+NEBOC_MODULE_ID_PACKAGE_HASH],r9
 mov [r8+NEBOC_MODULE_ID_PATH_HASH],r10
 mov [r8+NEBOC_MODULE_ID_DIGEST],rax
 xor eax,eax
 jmp .done
.bad_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.invalid_source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; hash_bytes(bytes*, length, seed) -> hash
module_identity_hash_bytes:
 mov rax,rdx
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .return
 movzx rdx,byte [rdi+rcx]
 xor rax,rdx
 mov rdx,0x100000001b3
 imul rax,rdx
 inc rcx
 jmp .loop
.return:
 ret
