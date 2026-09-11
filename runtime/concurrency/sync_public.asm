; Typed Int synchronization values reuse the canonical lock and atomic owners.
; Caller storage owns lock[48], payload[8], budget[24], or guard[32].
bits 64
default rel
%include "runtime/concurrency/sync.inc"
extern nebo_runtime_trap_arithmetic_domain
global nebo_sync_public
section .text
nebo_sync_public:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,77
 jae .lifecycle
 cmp ebx,62
 jbe .create
 cmp ebx,66
 jbe .acquire
 cmp ebx,71
 jae .observe
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 cmp ebx,67
 je .load
 cmp ebx,68
 je .store
 cmp ebx,69
 je .exchange
 cmp ebx,70
 jne .trap
 call nebo_atomic_fetch_add
 test eax,eax
 jnz .trap
 mov rax,r8
 jmp .done
.lifecycle:
 cmp ebx,78
 je .initialize_guard
 cmp ebx,77
 jne .trap
 cmp qword [r12+NEBO_GUARD_STATE],1
 jne .released
 mov rdi,r12
 jmp .release
.initialize_guard:
 mov rdi,r12
 xor eax,eax
 mov ecx,NEBO_MUTEX_GUARD_SIZE/8
 rep stosq
.released:
 xor eax,eax
 jmp .done
.create:
 mov rdi,r15
 xor eax,eax
 mov ecx,128/8
 cld
 rep stosq
 cmp ebx,62
 je .atomic
 lea rdi,[r15+64]
 mov esi,64
 mov edx,1000000
 call nebo_sync_budget_init
 test eax,eax
 jnz .trap
 mov [r15+48],r13
 mov rdi,r15
 lea rsi,[r15+64]
 cmp ebx,60
 jne .rwlock
 call nebo_mutex_init
 jmp .descriptor
.rwlock:
 call nebo_rwlock_init
 jmp .descriptor
.atomic:
 mov rdi,r15
 mov rsi,r13
 call nebo_atomic_init
 jmp .descriptor
.acquire:
 mov rdi,r15
 xor eax,eax
 mov ecx,NEBO_MUTEX_GUARD_SIZE/8
 rep stosq
 mov rdi,r12
 mov rsi,r15
 mov edx,64
 cmp ebx,63
 je .mutex
 cmp ebx,64
 jne .rw_acquire
 xor edx,edx
.mutex:
 call nebo_mutex_lock
 ; tryLock is observable without fabricating a live guard on failure.
 cmp ebx,64
 jne .descriptor
 xor eax,eax
 jmp .descriptor
.rw_acquire:
 cmp ebx,65
 jne .writer
 call nebo_rwlock_read
 jmp .descriptor
.writer:
 call nebo_rwlock_write
 jmp .descriptor
.load:
 call nebo_atomic_load
 test eax,eax
 jnz .trap
 mov rax,rdx
 jmp .done
.store:
 call nebo_atomic_store
 jmp .void
.exchange:
 mov rcx,r9
 call nebo_atomic_compare_exchange
 test eax,eax
 jnz .trap
 mov [r15],r8
 mov [r15+8],r9
 jmp .descriptor
.observe:
 cmp ebx,75
 je .swapped
 cmp ebx,76
 je .observed
 cmp ebx,71
 je .acquired
 cmp qword [r12+NEBO_GUARD_STATE],1
 jne .trap
 mov rdi,r12
 cmp ebx,74
 je .release
 mov eax,NEBO_LINUX_X86_64_SYS_GETTID
 syscall
 cmp rax,[r12+NEBO_GUARD_OWNER]
 jne .trap
.guard_value:
 mov rdx,[r12+NEBO_GUARD_LOCK]
 cmp ebx,72
 je .get
 cmp ebx,73
 jne .trap
 cmp qword [r12+NEBO_GUARD_KIND],2
 je .trap
 mov [rdx+48],r13
 xor eax,eax
 jmp .done
.get:
 mov rax,[rdx+48]
 jmp .done
.release:
 cmp qword [r12+NEBO_GUARD_KIND],1
 jne .release_rw
 call nebo_mutex_unlock
 jmp .void
.release_rw:
 call nebo_rwlock_unlock
 jmp .void
.acquired:
 xor eax,eax
 cmp qword [r12+NEBO_GUARD_STATE],1
 sete al
 jmp .done
.swapped:
 mov rax,[r12+8]
 jmp .done
.observed:
 mov rax,[r12]
 jmp .done
.descriptor:
 test eax,eax
 jnz .trap
 mov rax,r15
 jmp .done
.void:
 test eax,eax
 jnz .trap
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 jmp nebo_runtime_trap_arithmetic_domain
section .note.GNU-stack noalloc noexec nowrite progbits
