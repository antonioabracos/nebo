; Source-ordered, typed allocation effects. Storage and algorithms belong to
; the canonical system allocator and bounded arena, embedded here unchanged.
%include "runtime/memory/system_allocator.asm"
%include "runtime/memory/bounded_arena.asm"

section .text
global nebo_runtime_ownership_execute
; RDI=authenticated lowered event table, RSI=count, RDX=private arena backing,
; RCX=backing bytes. Slots are invocation-local; no persistent owner singleton.
nebo_runtime_ownership_execute:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,4240
 mov r12,rdi
 mov r13,rsi
 mov r15,rdx
 mov [rsp+4224],rcx
 mov r14,rsp
 mov rdi,r14
 mov ecx,528
 xor eax,eax
 rep stosq
 mov rdi,r14
 call neboc_system_allocator_init
 test eax,eax
 jnz .failed
 cmp r13,128
 ja .failed
.loop:
 test r13,r13
 jz .finish
 cmp qword [r12+8],32
 jae .failed
 cmp qword [r12+16],32
 jae .failed
 mov rax,[r12+8]
 shl rax,7
 lea rbx,[r14+rax+32]
 mov rax,[r12+16]
 shl rax,7
 lea rax,[r14+rax+32]
 mov [rsp+4200],rax
 mov qword [rsp+4184],0 ; actual arena cursor after this operation
 mov qword [rsp+4192],0 ; actual arena generation
 mov qword [rsp+4216],0 ; actual size acted on
 mov rax,[r12]
 cmp rax,1
 je .constructing
 cmp rax,3
 je .constructing
 cmp rax,4
 je .constructing
 cmp rax,7
 je .constructing
 cmp rax,8
 jne .dispatch
.constructing:
 ; Never overwrite an independently live native owner on a reused slot.
 cmp qword [rbx+120],1
 je .failed
 cmp qword [rbx+120],3
 je .failed
.dispatch:
 cmp rax,1
 je .allocate
 cmp rax,2
 je .deallocate
 cmp rax,3
 je .arena_init
 cmp rax,4
 je .arena_allocate
 cmp rax,5
 je .arena_reset
 cmp rax,6
 je .arena_drop
 cmp rax,7
 je .move
 cmp rax,8
 je .clone
 jmp .failed
.allocate:
 mov rax,[r12+24]
 mov [rsp+4128],rax
 mov qword [rsp+4136],8
 mov rdi,r14
 lea rsi,[rsp+4128]
 mov rdx,rbx
 call neboc_system_allocator_allocate
 test eax,eax
 jnz .failed
 mov qword [rbx+120],1
 mov rax,[rbx+NEBOC_SYSTEM_BLOCK_SIZE_OFFSET]
 mov [rsp+4216],rax
 jmp .observe
.deallocate:
 cmp qword [rbx+120],1
 jne .failed
 mov rax,[rbx+NEBOC_SYSTEM_BLOCK_SIZE_OFFSET]
 mov [rsp+4216],rax
 mov rdi,r14
 mov rsi,rbx
 call neboc_system_allocator_deallocate
 test eax,eax
 jnz .failed
 mov qword [rbx+120],0
 jmp .observe
.arena_init:
 mov rdx,[r12+24]
 test rdx,rdx
 jz .failed
 cmp rdx,[rsp+4224]
 ja .failed
 mov rdi,rbx
 mov rsi,r15
 call neboc_bounded_arena_init
 test eax,eax
 jnz .failed
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_ARENA_CAPACITY_OFFSET]
 mov [rsp+4216],rax
 add rax,15
 and rax,-16
 add r15,rax
 sub [rsp+4224],rax
 mov qword [rbx+120],3
 mov rax,rbx
 jmp .arena_observe
.arena_allocate:
 mov rax,[rsp+4200]
 cmp qword [rax+120],3
 jne .failed
 mov rdi,rax
 mov rax,[r12+24]
 mov [rsp+4128],rax
 mov qword [rsp+4136],8
 lea rsi,[rsp+4128]
 mov rdx,rbx
 call neboc_bounded_arena_allocate
 test eax,eax
 jnz .failed
 cmp qword [rbx+NEBOC_RESULT_TAG_OFFSET],0
 jne .failed
 mov qword [rbx+120],4
 mov rax,[r12+16]
 mov [rbx+112],rax
 mov rax,[rbx+NEBOC_RESULT_BLOCK_SIZE_OFFSET]
 mov [rsp+4216],rax
 mov rax,[rsp+4200]
 jmp .arena_observe
.arena_reset:
 cmp qword [rbx+120],3
 jne .failed
 mov rdi,rbx
 lea rsi,[rsp+4128]
 call neboc_bounded_arena_reset
 test eax,eax
 jnz .failed
 cmp qword [rsp+4128],0
 jne .failed
 mov rax,rbx
 jmp .arena_observe
.arena_drop:
 cmp qword [rbx+120],3
 jne .failed
 mov qword [rbx+120],0
 mov rax,rbx
 jmp .arena_observe
.move:
 mov rsi,[rsp+4200]
 mov rax,[rsi+120]
 test rax,rax
 jz .failed
 mov rdi,rbx
 mov ecx,16
 rep movsq
 mov rsi,[rsp+4200]
 mov qword [rsi+120],0
 jmp .transfer_observe
.clone:
 mov rax,[rsp+4200]
 cmp qword [rax+120],1
 je .clone_block
 cmp qword [rax+120],3
 jne .failed
 ; Clone an arena into its own backing and retain native cursor/generation.
 mov rdx,[rax+neboc_text_char_unicode_e_bytes_ARENA_CAPACITY_OFFSET]
 cmp rdx,[rsp+4224]
 ja .failed
 mov rdi,rbx
 mov rsi,r15
 call neboc_bounded_arena_init
 test eax,eax
 jnz .failed
 mov rax,[rsp+4200]
 mov rsi,[rax+neboc_text_char_unicode_e_bytes_ARENA_BASE_OFFSET]
 mov rdi,r15
 mov rcx,[rax+neboc_text_char_unicode_e_bytes_ARENA_CAPACITY_OFFSET]
 mov rdx,rcx
 add rdx,15
 and rdx,-16
 add r15,rdx
 sub [rsp+4224],rdx
 rep movsb
 mov rcx,[rax+NEBOC_ARENA_CURSOR_OFFSET]
 mov [rbx+NEBOC_ARENA_CURSOR_OFFSET],rcx
 mov rcx,[rax+neboc_text_char_unicode_e_bytes_ARENA_HIGH_WATER_OFFSET]
 mov [rbx+neboc_text_char_unicode_e_bytes_ARENA_HIGH_WATER_OFFSET],rcx
 mov rdi,rbx
 call rf27g04_arena_rehash
 mov qword [rbx+120],3
 jmp .transfer_observe
.clone_block:
 mov rcx,[rax+NEBOC_SYSTEM_BLOCK_SIZE_OFFSET]
 mov [rsp+4128],rcx
 mov qword [rsp+4136],8
 mov rdi,r14
 lea rsi,[rsp+4128]
 mov rdx,rbx
 call neboc_system_allocator_allocate
 test eax,eax
 jnz .failed
 mov rax,[rsp+4200]
 mov rsi,[rax+NEBOC_SYSTEM_BLOCK_POINTER_OFFSET]
 mov rdi,[rbx+NEBOC_SYSTEM_BLOCK_POINTER_OFFSET]
 mov rcx,[rbx+NEBOC_SYSTEM_BLOCK_SIZE_OFFSET]
 rep movsb
 mov qword [rbx+120],1
.transfer_observe:
 cmp qword [rbx+120],3
 je .transfer_arena
 mov rax,[rbx+NEBOC_SYSTEM_BLOCK_SIZE_OFFSET]
 mov [rsp+4216],rax
 jmp .observe
.transfer_arena:
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_ARENA_CAPACITY_OFFSET]
 mov [rsp+4216],rax
 mov rax,rbx
.arena_observe:
 mov rcx,[rax+NEBOC_ARENA_CURSOR_OFFSET]
 mov [rsp+4184],rcx
 mov rcx,[rax+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET]
 mov [rsp+4192],rcx
.observe:
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 ; This observer receives actual post-operation native state, never expected
 ; statuses, a source hash, filenames or native pointers.
 mov rdi,[r12]
 mov rsi,[r12+8]
 mov rdx,[r14+NEBOC_SYSTEM_ALLOCATOR_LIVE_OFFSET]
 mov rcx,[r14+NEBOC_SYSTEM_ALLOCATOR_BYTES_OFFSET]
 mov r8,[rsp+4184]
 mov r9,[rsp+4192]
 mov rax,[rsp+4216]
 call nebo_runtime_ownership_observe
%endif
 add r12,48
 dec r13
 jmp .loop
.finish:
 cmp qword [r14+NEBOC_SYSTEM_ALLOCATOR_LIVE_OFFSET],0
 jne .failed
 lea rax,[r14+32]
 mov ecx,32
.live_arenas:
 cmp qword [rax+120],3
 je .failed
 add rax,128
 dec ecx
 jnz .live_arenas
 xor eax,eax
 add rsp,4240
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.failed:
 ; A later allocation can fail after earlier native mappings were published.
 ; Release each still-live owner before the terminal adapter; successful
 ; deallocations already have state zero and cannot be repeated here.
 xor r13d,r13d
.failure_cleanup:
 cmp r13,32
 jae .failure_terminal
 mov rax,r13
 shl rax,7
 lea rbx,[r14+rax+32]
 cmp qword [rbx+120],1
 jne .failure_next
 mov rax,[rbx+NEBOC_SYSTEM_BLOCK_SIZE_OFFSET]
 mov [rsp+4216],rax
 mov rdi,r14
 mov rsi,rbx
 call neboc_system_allocator_deallocate
 test eax,eax
 jnz .failure_next
 mov qword [rbx+120],0
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 mov edi,2
 mov rsi,r13
 mov rdx,[r14+NEBOC_SYSTEM_ALLOCATOR_LIVE_OFFSET]
 mov rcx,[r14+NEBOC_SYSTEM_ALLOCATOR_BYTES_OFFSET]
 xor r8d,r8d
 xor r9d,r9d
 mov rax,[rsp+4216]
 call nebo_runtime_ownership_observe
%endif
.failure_next:
 inc r13
 jmp .failure_cleanup
.failure_terminal:
 mov edi,NEBO_RUNTIME_TRAP_INVALID_DESCRIPTOR
 jmp nebo_runtime_trap

%ifdef NEBO_RUNTIME_PRACTICAL_IO
section .rodata
runtime_ownership_trace_environment: db 'NEBO_OWNERSHIP_TRACE=1',0
runtime_ownership_trace_environment_len equ $-runtime_ownership_trace_environment
section .text
nebo_runtime_ownership_observe:
 sub rsp,88
 mov [rsp+56],rax
 mov rax,0x31574f4d4f42454e ; NEBOMOW1
 mov [rsp],rax
 mov [rsp+8],rdi
 mov [rsp+16],rsi
 mov [rsp+24],rdx
 mov [rsp+32],rcx
 mov [rsp+40],r8
 mov [rsp+48],r9
 lea rsi,[rel runtime_ownership_trace_environment]
 mov edx,runtime_ownership_trace_environment_len
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
 mov edi,NEBO_RUNTIME_TRAP_INVALID_DESCRIPTOR
 jmp nebo_runtime_trap
%endif
