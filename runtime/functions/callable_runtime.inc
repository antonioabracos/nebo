; Canonical bounded scalar callable carrier, embedded by runtime_core.
; 64 bytes: capture value/pointer, live flag, last argument/result,
; actual call/drop counters, capture mode and argument TypeId.
; The capture payload is the existing 16-byte environment contract. The
; remaining fields belong to its runtime carrier and lifecycle observation.
section .text
global nebo_runtime_callable_init
global nebo_runtime_callable_invoke
global nebo_runtime_callable_capture
global nebo_runtime_callable_drop

; RDI=caller-owned carrier, RSI=capture mode, RDX=value or borrowed cell,
; RCX=argument TypeId. No allocation, global owner state or inferred output.
nebo_runtime_callable_init:
 test rdi,rdi
 jz nebo_runtime_callable_invalid
 cmp rsi,3
 ja nebo_runtime_callable_invalid
 cmp rcx,1
 jb nebo_runtime_callable_invalid
 cmp rcx,3
 ja nebo_runtime_callable_invalid
 mov [rdi],rdx
 mov qword [rdi+8],1
 mov qword [rdi+16],0
 mov qword [rdi+24],0
 mov qword [rdi+32],0
 mov qword [rdi+40],0
 mov [rdi+48],rsi
 mov [rdi+56],rcx
 xor eax,eax
 ret

; RDI=carrier, RSI=typed scalar argument, RDX=generated native body.
; The body receives the argument in RDI and its environment in RSI.
nebo_runtime_callable_invoke:
 cmp qword [rdi+8],1
 jne nebo_runtime_callable_invalid
 test rdx,rdx
 jz nebo_runtime_callable_invalid
 push rbx
 mov rbx,rdi
 mov [rbx+16],rsi
 mov rdi,rsi
 mov rsi,rbx
 call rdx
 mov [rbx+24],rax
 inc qword [rbx+32]
 pop rbx
 ret

nebo_runtime_callable_capture:
 cmp qword [rdi+8],1
 jne nebo_runtime_callable_invalid
 cmp qword [rdi+48],0
 je nebo_runtime_callable_invalid
 mov rax,[rdi]
 cmp qword [rdi+48],3
 jne .done
 mov rax,[rax] ; lexical borrow reads its original immutable capture cell
.done:
 ret

nebo_runtime_callable_drop:
 cmp qword [rdi+8],1
 jne nebo_runtime_callable_invalid
 mov qword [rdi+8],0
 mov qword [rdi],0 ; release our value/reference; never overwrite a borrow
 cmp qword [rdi+48],0
 je .released
 inc qword [rdi+40]
.released:
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 jmp nebo_runtime_callable_observe
%else
 ret
%endif

nebo_runtime_callable_invalid:
 mov edi,NEBO_RUNTIME_TRAP_INVALID_DESCRIPTOR
 jmp nebo_runtime_trap

%ifdef NEBO_RUNTIME_PRACTICAL_IO
section .rodata
runtime_callable_trace_environment: db 'NEBO_CALLABLE_TRACE=1',0
runtime_callable_trace_environment_len equ $-runtime_callable_trace_environment
section .text
; Observe actual released storage and counters, never expected values.
nebo_runtime_callable_observe:
 sub rsp,88
 mov rax,0x314c41434f42454e ; NEBOCAL1
 mov [rsp],rax
 mov rax,[rdi+48]
 mov [rsp+8],rax
 mov rax,[rdi]
 mov [rsp+16],rax
 mov rax,[rdi+16]
 mov [rsp+24],rax
 mov rax,[rdi+24]
 mov [rsp+32],rax
 mov rax,[rdi+32]
 mov [rsp+40],rax
 mov rax,[rdi+40]
 mov [rsp+48],rax
 mov rax,[rdi+56]
 mov [rsp+56],rax
 lea rsi,[rel runtime_callable_trace_environment]
 mov edx,runtime_callable_trace_environment_len
 call nebo_runtime_trace_setting
 test eax,eax
 jz .done
 mov rsi,rsp
 mov edx,64
 mov qword [rsp+64],64
.write:
 dec qword [rsp+64]
 jz .failed
 mov eax,1
 mov edi,1
 syscall
 cmp rax,-4
 je .write
 test rax,rax
 jle .failed
 add rsi,rax
 sub rdx,rax
 jnz .write
.done:
 add rsp,88
 ret
.failed:
 add rsp,88
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap
%endif
