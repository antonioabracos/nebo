; IDENTIDADE-DE-MODULOS-SOURCE-UNITS-ROOTS-E-MODULE-GRAPH-DETERMINISTICO-F02 bounded workspace/module-root validation.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/modules.inc"

section .text

; root_discover(workspace*, workspace_len, root*, root_len, out*) -> status
; The host supplies already-resolved path bytes. This layer proves containment
; and emits a relative identity; it never performs implicit filesystem I/O.
NEBOC_ABI_FUNCTION neboc_module_root_discover
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
 cmp rsi,NEBOC_MODULE_MAX_TEXT
 ja .limit
 cmp rcx,rsi
 jb .escape
 cmp rcx,NEBOC_MODULE_MAX_TEXT
 ja .limit
 xor r9d,r9d
.prefix:
 cmp r9,rsi
 jae .prefix_done
 mov al,[rdi+r9]
 cmp al,[rdx+r9]
 jne .escape
 inc r9
 jmp .prefix
.prefix_done:
 mov r10,rsi
 cmp rcx,rsi
 je .relative_ready
 cmp byte [rdx+rsi],'/'
 jne .escape
 inc r10
.relative_ready:
 mov r11,rcx
 sub r11,r10
 ; Reject NUL, backslash, duplicate slash and dot/dot-dot components.
 xor r9d,r9d
 xor esi,esi
.scan:
 cmp r9,rcx
 jae .scan_done
 movzx eax,byte [rdx+r9]
 test al,al
 jz .bad_source
 cmp al,92
 je .bad_source
 cmp al,'/'
 jne .not_slash
 test esi,esi
 jnz .bad_source
 mov esi,1
 inc r9
 jmp .scan
.not_slash:
 test esi,esi
 jz .scan_next
 cmp al,'.'
 jne .component_started
 lea rax,[r9+1]
 cmp rax,rcx
 je .bad_source
 cmp byte [rdx+rax],'/'
 je .bad_source
 cmp byte [rdx+rax],'.'
 jne .component_started
 inc rax
 cmp rax,rcx
 je .bad_source
 cmp byte [rdx+rax],'/'
 je .bad_source
.component_started:
 xor esi,esi
.scan_next:
 inc r9
 jmp .scan
.scan_done:
 test esi,esi
 jnz .bad_source
.hash:
 mov rax,0xcbf29ce484222325
 xor r9d,r9d
.hash_loop:
 cmp r9,r11
 jae .publish
 mov rsi,r10
 add rsi,r9
 movzx rsi,byte [rdx+rsi]
 xor rax,rsi
 mov rsi,0x100000001b3
 imul rax,rsi
 inc r9
 jmp .hash_loop
.publish:
 test rax,rax
 jnz .store
 mov eax,1
.store:
 mov [r8+NEBOC_ROOT_RELATIVE_OFFSET],r10
 mov [r8+NEBOC_ROOT_RELATIVE_LENGTH],r11
 mov [r8+NEBOC_ROOT_DIGEST],rax
 xor eax,eax
 ret
.invalid_argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.invalid_source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.bad_source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.escape:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
