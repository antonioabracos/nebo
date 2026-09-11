; IDENTIDADE-DE-MODULOS-SOURCE-UNITS-ROOTS-E-MODULE-GRAPH-DETERMINISTICO-F05 fail-closed logical module path security.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/modules.inc"
section .text

; validate_path(bytes*, length, out_ascii_fold_hash*) -> status
NEBOC_ABI_FUNCTION neboc_module_path_validate
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test rdx,7
 jnz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_MODULE_MAX_TEXT
 ja .limit
 mov r8,rdi
 add r8,rsi
 jc .arg
 mov r9,rdx
 add r9,8
 jc .arg
 cmp rdi,r9
 jae .range_ok
 cmp rdx,r8
 jb .arg
.range_ok:
 mov rax,0xcbf29ce484222325
 xor ecx,ecx
 mov r8d,1
.loop:
 cmp rcx,rsi
 jae .done_scan
 movzx r9d,byte [rdi+rcx]
 test r8d,r8d
 jz .body
 cmp r9b,'a'
 jb .source
 cmp r9b,'z'
 ja .source
 xor r8d,r8d
 jmp .hash
.body:
 cmp r9b,'.'
 je .separator
 cmp r9b,'a'
 jb .digit
 cmp r9b,'z'
 jbe .hash
.digit:
 cmp r9b,'0'
 jb .underscore
 cmp r9b,'9'
 jbe .hash
.underscore:
 cmp r9b,'_'
 jne .source
 jmp .hash
.separator:
 mov r8d,1
.hash:
 xor rax,r9
 mov r10,0x100000001b3
 imul rax,r10
 inc rcx
 jmp .loop
.done_scan:
 test r8d,r8d
 jnz .source
 test rax,rax
 jnz .publish
 mov eax,1
.publish:
 mov [rdx],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; collision(left*, left_len, right*, right_len, out_equal*) -> status.
; Non-canonical case/Unicode spellings fail closed before equality is published.
NEBOC_ABI_FUNCTION neboc_module_path_collision
 test rdi,rdi
 jz .collision_arg
 test rdx,rdx
 jz .collision_arg
 test r8,r8
 jz .collision_arg
 test r8,7
 jnz .collision_arg
 cmp rsi,NEBOC_MODULE_MAX_TEXT
 ja .collision_limit
 cmp rcx,NEBOC_MODULE_MAX_TEXT
 ja .collision_limit
 mov r9,rdi
 add r9,rsi
 jc .collision_arg
 mov r10,rdx
 add r10,rcx
 jc .collision_arg
 mov r11,r8
 add r11,8
 jc .collision_arg
 cmp rdi,r11
 jae .collision_left_ok
 cmp r8,r9
 jb .collision_arg
.collision_left_ok:
 cmp rdx,r11
 jae .collision_ranges_ok
 cmp r8,r10
 jb .collision_arg
.collision_ranges_ok:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbp,rcx
 mov rbx,r8
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 call neboc_module_path_validate
 test eax,eax
 jnz .collision_done
 mov rdi,r14
 mov rsi,rbp
 lea rdx,[rsp+8]
 call neboc_module_path_validate
 test eax,eax
 jnz .collision_done
 xor r10d,r10d
 cmp r13,rbp
 jne .collision_publish
 mov rax,[rsp]
 cmp rax,[rsp+8]
 jne .collision_publish
 xor ecx,ecx
.collision_compare:
 cmp rcx,r13
 jae .collision_equal
 mov al,[r12+rcx]
 cmp al,[r14+rcx]
 jne .collision_publish
 inc rcx
 jmp .collision_compare
.collision_equal:
 mov r10d,1
.collision_publish:
 mov [rbx],r10
 xor eax,eax
.collision_done:
 add rsp,16
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.collision_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.collision_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
