; STARTUP-F08 bounded startup/lazy-init/footprint model.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/startup.inc"
section .text
startup_find:
 mov r8,[rdi+NEBOC_STARTUP_CTX_COMPONENTS_OFFSET]
 xor r9d,r9d
.loop:
 cmp r9,[rdi+NEBOC_STARTUP_CTX_COUNT_OFFSET]
 jae .absent
 cmp [r8+NEBOC_STARTUP_COMP_ID_OFFSET],rsi
 je .found
 add r8,NEBOC_STARTUP_COMP_SIZE
 inc r9
 jmp .loop
.found: mov rax,r8
 ret
.absent: xor eax,eax
 ret
NEBOC_ABI_FUNCTION neboc_startup_graph_build
 ; rdi=context; canonical topological id contract detects cycles.
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_STARTUP_CTX_COUNT_OFFSET]
 cmp rax,NEBOC_STARTUP_MAX_COMPONENTS
 ja .limit
 mov r8,[rdi+NEBOC_STARTUP_CTX_DEPS_OFFSET]
 xor r9d,r9d
.deps:
 cmp r9,[rdi+NEBOC_STARTUP_CTX_DEP_COUNT_OFFSET]
 jae .components
 mov rax,[r8]
 cmp rax,[r8+8]
 jbe .source
 add r8,NEBOC_STARTUP_DEP_SIZE
 inc r9
 jmp .deps
.components:
 mov r8,[rdi+NEBOC_STARTUP_CTX_COMPONENTS_OFFSET]
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
.component_loop:
 cmp r9,[rdi+NEBOC_STARTUP_CTX_COUNT_OFFSET]
 jae .done
 test qword [r8+NEBOC_STARTUP_COMP_FLAGS_OFFSET],NEBOC_STARTUP_FLAG_EAGER
 jz .lazy
 inc r10
 jmp .next
.lazy:
 test qword [r8+NEBOC_STARTUP_COMP_FLAGS_OFFSET],NEBOC_STARTUP_FLAG_LAZY
 jz .source
 inc r11
.next:
 mov [r8+NEBOC_STARTUP_COMP_ORDER_OFFSET],r9
 add r8,NEBOC_STARTUP_COMP_SIZE
 inc r9
 jmp .component_loop
.done:
 mov [rdi+NEBOC_STARTUP_CTX_EAGER_OFFSET],r10
 mov [rdi+NEBOC_STARTUP_CTX_LAZY_OFFSET],r11
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%macro STARTUP_COUNT_REPORT 2
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 mov rax,[rdi+%2]
 mov [rsi],rax
 xor eax,eax
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
STARTUP_COUNT_REPORT neboc_startup_graph_eager_components,NEBOC_STARTUP_CTX_EAGER_OFFSET
STARTUP_COUNT_REPORT neboc_startup_graph_lazy_components,NEBOC_STARTUP_CTX_LAZY_OFFSET
NEBOC_ABI_FUNCTION neboc_startup_graph_defer
 ; rdi=context rsi=id rdx=guard proof.
 test rdi,rdi
 jz .invalid
 test rdx,NEBOC_STARTUP_FLAG_GUARD_PROVED
 jz .source
 push rbx
 mov rbx,rdi
 call startup_find
 test rax,rax
 jz .absent
 test qword [rax+NEBOC_STARTUP_COMP_FLAGS_OFFSET],NEBOC_STARTUP_FLAG_EAGER
 jz .mark
 dec qword [rbx+NEBOC_STARTUP_CTX_EAGER_OFFSET]
 inc qword [rbx+NEBOC_STARTUP_CTX_LAZY_OFFSET]
.mark:
 and qword [rax+NEBOC_STARTUP_COMP_FLAGS_OFFSET],~NEBOC_STARTUP_FLAG_EAGER
 or qword [rax+NEBOC_STARTUP_COMP_FLAGS_OFFSET],NEBOC_STARTUP_FLAG_LAZY|NEBOC_STARTUP_FLAG_GUARD_PROVED
 pop rbx
 xor eax,eax
 ret
.absent: pop rbx
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
NEBOC_ABI_FUNCTION neboc_startup_graph_measure
 ; rdi=context rsi=samples rdx=environment manifest token.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,1024
 ja .limit
 test rdx,rdx
 jz .invalid
 mov [rdi+NEBOC_STARTUP_CTX_SAMPLES_OFFSET],rsi
 mov [rdi+NEBOC_STARTUP_CTX_ENV_OFFSET],rdx
 mov rax,[rdi+NEBOC_STARTUP_CTX_EAGER_OFFSET]
 imul rax,rsi
 mov [rdi+NEBOC_STARTUP_CTX_TIME_OFFSET],rax
 mov [rdi+NEBOC_STARTUP_CTX_SYSCALLS_OFFSET],rax
 mov rax,[rdi+NEBOC_STARTUP_CTX_EAGER_OFFSET]
 mov [rdi+NEBOC_STARTUP_CTX_PAGES_OFFSET],rax
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_runtime_init_once
 ; rdi=context rsi=id.
 test rdi,rdi
 jz .invalid
 push rbx
 mov rbx,rdi
 call startup_find
 test rax,rax
 jz .absent
 cmp qword [rax+NEBOC_STARTUP_COMP_STATE_OFFSET],NEBOC_STARTUP_STATE_FAILED
 je .failed
 cmp qword [rax+NEBOC_STARTUP_COMP_STATE_OFFSET],NEBOC_STARTUP_STATE_INITIALIZED
 je .ok
 mov qword [rax+NEBOC_STARTUP_COMP_STATE_OFFSET],NEBOC_STARTUP_STATE_INITIALIZED
 inc qword [rax+NEBOC_STARTUP_COMP_INIT_COUNT_OFFSET]
 inc qword [rbx+NEBOC_STARTUP_CTX_INITIALIZED_OFFSET]
.ok: pop rbx
 xor eax,eax
 ret
.failed: pop rbx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.absent: pop rbx
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_runtime_init_failure
 ; rdi=context rsi=id rdx=error, always leaves no initialized handle.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 push rbx
 mov rbx,rdi
 call startup_find
 test rax,rax
 jz .absent
 cmp qword [rax+NEBOC_STARTUP_COMP_STATE_OFFSET],NEBOC_STARTUP_STATE_INITIALIZED
 jne .record
 dec qword [rbx+NEBOC_STARTUP_CTX_INITIALIZED_OFFSET]
.record:
 mov qword [rax+NEBOC_STARTUP_COMP_STATE_OFFSET],NEBOC_STARTUP_STATE_FAILED
 mov [rax+NEBOC_STARTUP_COMP_ERROR_OFFSET],rdx
 inc qword [rbx+NEBOC_STARTUP_CTX_FAILED_OFFSET]
 pop rbx
 xor eax,eax
 ret
.absent: pop rbx
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_runtime_exit_cleanup_graph
 ; rdi=context. Cleanup order is reverse init order, initialized only.
 test rdi,rdi
 jz .invalid
 mov r8,[rdi+NEBOC_STARTUP_CTX_COMPONENTS_OFFSET]
 mov r9,[rdi+NEBOC_STARTUP_CTX_COUNT_OFFSET]
 xor r10d,r10d
.loop:
 test r9,r9
 jz .done
 dec r9
 mov rax,r9
 imul rax,NEBOC_STARTUP_COMP_SIZE
 lea r11,[r8+rax]
 cmp qword [r11+NEBOC_STARTUP_COMP_STATE_OFFSET],NEBOC_STARTUP_STATE_INITIALIZED
 jne .loop
 inc r10
 mov [r11+NEBOC_STARTUP_COMP_CLEANUP_OFFSET],r10
 mov qword [r11+NEBOC_STARTUP_COMP_STATE_OFFSET],NEBOC_STARTUP_STATE_COLD
 jmp .loop
.done:
 mov qword [rdi+NEBOC_STARTUP_CTX_INITIALIZED_OFFSET],0
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_footprint_rss_report
 ; rdi=context rsi=5-qword estimated report plus environment.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_STARTUP_CTX_EAGER_OFFSET]
 imul rax,4096
 mov [rsi],rax
 mov rax,[rdi+NEBOC_STARTUP_CTX_COUNT_OFFSET]
 imul rax,4096
 mov [rsi+8],rax
 mov qword [rsi+16],4096
 mov rax,[rdi+NEBOC_STARTUP_CTX_PAGES_OFFSET]
 mov [rsi+24],rax
 mov rax,[rdi+NEBOC_STARTUP_CTX_ENV_OFFSET]
 mov [rsi+32],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_footprint_compare
 ; rdi=left report rsi=right report rdx=noise bytes rcx=result (-1/0/1).
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov rax,[rdi]
 sub rax,[rsi]
 jns .absolute
 neg rax
.absolute:
 cmp rax,rdx
 jbe .equal
 mov rax,[rdi]
 cmp rax,[rsi]
 ja .greater
 mov qword [rcx],-1
 xor eax,eax
 ret
.greater: mov qword [rcx],1
 xor eax,eax
 ret
.equal: mov qword [rcx],0
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_startup_report
 jmp neboc_footprint_rss_report
section .note.GNU-stack noalloc noexec nowrite progbits
