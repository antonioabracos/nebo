; Confirmation is a second actual source response. ScanPlan validates the
; primary value before requesting confirmation; no binding exists yet.
section .text
sp_confirm_secret:
 push rbx
 mov rbx,rdi
 test qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_CONFIRM
 jz .ok
 mov qword [rbx+SP_SKIP_WIPE],1
 mov rdi,rbx
 call sp_public_complete
 mov qword [rbx+SP_SKIP_WIPE],0
 test eax,eax
 jnz .invalid
 mov rdi,rbx
 call sp_public_request
 test eax,eax
 jnz .invalid
 mov rdi,rbx
 call sp_read_source
 test eax,eax
 jnz .done
 mov rdi,rdx
 mov rsi,rcx
 lea rdx,[rbx+12288]
 mov ecx,4096
 mov r8,[rbx+SP_FLAGS]
 call neboc_scan_normalize_ascii
 test rax,rax
 js .invalid
 mov rcx,rax
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 lea rdx,[rbx+12288]
 call nebo_g077_secret_confirm
 test eax,eax
 jnz .mismatch
.ok:
 xor eax,eax
 jmp .done
.mismatch:
 mov eax,SCAN_E_VALIDATE
 jmp .done
.invalid:
 mov eax,SCAN_E_INVALID
.done:
 pop rbx
 ret

; Preserve the usable returned value in its own result region before forgetting
; mutable input/confirmation buffers. The source's immutable mock literal is
; never modified. RDI frame, RSI raw return -> RAX raw return/owned Text value.
sp_secret_prepare_result:
 mov rax,rsi
 test qword [rdi+SP_SECURITY],NEBO_G105_SECURITY_FORGET
 jz .done
 cmp qword [rdi+SP_ERROR],0
 jne .done
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,[r12+8]
 cmp r13,4096
 ja .bad
 lea rdi,[rbx+12288]
 mov rsi,[r12]
 mov rcx,r13
 rep movsb
 lea rax,[rbx+1088]
 lea rdx,[rbx+12288]
 mov [rax],rdx
 mov [rax+8],r13
 mov dword [rax+16],5
 mov word [rax+20],1
 mov word [rax+22],0
 pop r13
 pop r12
 pop rbx
.done:
 ret
.bad:
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Forget only owned input storage and consumed replay bytes. A later retry can
; still read the unread tail. Native zeroization and an actual byte scan supply
; independent evidence; an asserted zeroized flag alone is insufficient.
sp_secret_wipe:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 test qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_FORGET
 jz .ok
 cmp qword [rbx+SP_SKIP_WIPE],0
 jne .ok
 cmp qword [rbx+SP_SECRET_WIPED],0
 jne .ok
 lea rdi,[rbx+1120]
 mov esi,4096
 lea rdx,[rbx+SP_RESPONSE]
 lea rcx,[rbx+SP_EVIDENCE]
 call nebo_scan_console_zeroize
 test eax,eax
 jnz .done
 mov r12d,4096
 cmp qword [rbx+SP_REPLAY],0
 je .source
 mov r12,[rbx+SP_SOURCE_CURSOR]
 cmp r12,4096
 ja .bad
.source:
 lea rdi,[rbx+5216]
 mov rsi,r12
 call nebo_g077_secret_forget
 test eax,eax
 jnz .done
 cmp qword [rbx+SP_ERROR],0
 je .witness
 lea rdi,[rbx+12288]
 mov esi,4096
 call nebo_g077_secret_forget
 test eax,eax
 jnz .done
.witness:
 xor r13d,r13d
 xor ecx,ecx
.normalized:
 movzx eax,byte [rbx+rcx+1120]
 or r13,rax
 inc rcx
 cmp rcx,4096
 jb .normalized
 xor ecx,ecx
.source_bytes:
 cmp rcx,r12
 jae .confirmation_witness
 movzx eax,byte [rbx+rcx+5216]
 or r13,rax
 inc rcx
 jmp .source_bytes
.confirmation_witness:
 cmp qword [rbx+SP_ERROR],0
 je .commit
 xor ecx,ecx
.confirmation_bytes:
 movzx eax,byte [rbx+rcx+12288]
 or r13,rax
 inc rcx
 cmp rcx,4096
 jb .confirmation_bytes
.commit:
 mov [rbx+SP_ZERO_REMAINS],r13
 mov qword [rbx+SP_SECRET_WIPED],1
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,SCAN_E_LIMIT
.done:
 pop r13
 pop r12
 pop rbx
 ret
section .text
