; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-F09 deterministic local compiler profiler and explain report.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/profiler/profiler.inc"
extern nebo_capability_precheck
section .text
profiler_authorize:
 mov rdi,[r13+NEBO_PROFILER_STATE_AUTHORITY]
 mov rsi,[r13+NEBO_PROFILER_STATE_CAPABILITY]
 mov edx,NEBO_EFFECT_CLOCK
 mov ecx,1
 mov r8,[r13+NEBO_PROFILER_STATE_SCOPE]
 mov r9d,1
 jmp nebo_capability_precheck

NEBOC_ABI_FUNCTION nebo_profiler_init
 test rdi,rdi
 jz .bad
 mov rsi,[rdi+NEBO_PROFILER_INIT_STATE]
 mov rdx,[rdi+NEBO_PROFILER_INIT_EVENTS]
 mov rcx,[rdi+NEBO_PROFILER_INIT_CAPACITY]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 test rcx,rcx
 jz .bad
 cmp rcx,NEBO_PROFILER_MAX_EVENTS
 ja .limit
 cmp qword [rdi+NEBO_PROFILER_INIT_AUTHORITY],0
 je .bad
 cmp qword [rdi+NEBO_PROFILER_INIT_CAPABILITY],0
 je .bad
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_PROFILER_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_PROFILER_MAGIC
 mov [rsi+NEBO_PROFILER_STATE_MAGIC],rax
 mov [rsi+NEBO_PROFILER_STATE_EVENTS],rdx
 mov rax,[r8+NEBO_PROFILER_INIT_CAPACITY]
 mov [rsi+NEBO_PROFILER_STATE_CAPACITY],rax
 mov rax,[r8+NEBO_PROFILER_INIT_AUTHORITY]
 mov [rsi+NEBO_PROFILER_STATE_AUTHORITY],rax
 mov rax,[r8+NEBO_PROFILER_INIT_CAPABILITY]
 mov [rsi+NEBO_PROFILER_STATE_CAPABILITY],rax
 mov rax,[r8+NEBO_PROFILER_INIT_SCOPE]
 mov [rsi+NEBO_PROFILER_STATE_SCOPE],rax
 xor eax,eax
 ret
.limit: mov eax,NEBO_PROFILER_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_PROFILER_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_profiler_record
 test rdi,rdi
 jz .bad
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov qword [r12+NEBO_PROFILER_RECORD_RESULT],0
 mov qword [r12+NEBO_PROFILER_RECORD_SEQUENCE],0
 mov r13,[r12+NEBO_PROFILER_RECORD_STATE]
 test r13,r13
 jz .bad_saved
 mov rax,NEBO_PROFILER_MAGIC
 cmp [r13+NEBO_PROFILER_STATE_MAGIC],rax
 jne .bad_saved
 mov rbx,[r12+NEBO_PROFILER_RECORD_PHASE]
 test rbx,rbx
 jz .phase
 cmp rbx,NEBO_PROFILER_PHASES
 ja .phase
 cmp qword [r12+NEBO_PROFILER_RECORD_UNIT],0
 je .bad_saved
 mov rax,[r12+NEBO_PROFILER_RECORD_END]
 sub rax,[r12+NEBO_PROFILER_RECORD_START]
 jc .timing
 mov r14,rax
 mov rax,[r12+NEBO_PROFILER_RECORD_CLASS]
 test rax,~NEBO_PRIVACY_CLASS_MASK
 jnz .bad_saved
 cmp qword [r12+NEBO_PROFILER_RECORD_REDACTED],1
 ja .bad_saved
 test rax,rax
 jz .privacy_ok
 cmp qword [r12+NEBO_PROFILER_RECORD_REDACTED],1
 jne .privacy
.privacy_ok:
 mov rax,[r13+NEBO_PROFILER_STATE_TOTAL_TIME]
 add rax,r14
 jc .overflow
 mov rax,[r13+NEBO_PROFILER_STATE_COUNT]
 cmp rax,[r13+NEBO_PROFILER_STATE_CAPACITY]
 jae .limit
 mov rdx,[r12+NEBO_PROFILER_RECORD_STACK]
 test rdx,rdx
 jz .bad_saved
 xor r15d,r15d
.stack_scan:
 cmp r15,[r13+NEBO_PROFILER_STATE_STACK_COUNT]
 jae .stack_new
 cmp [r13+NEBO_PROFILER_STATE_STACK_KEYS+r15*8],rdx
 je .stack_ok
 inc r15
 jmp .stack_scan
.stack_new:
 cmp r15,NEBO_PROFILER_MAX_STACKS
 jae .cardinality
 bts r15,63
.stack_ok:
 call profiler_authorize
 test eax,eax
 jnz .capability
 test r15,r15
 jns .store
 btr r15,63
 mov rax,[r12+NEBO_PROFILER_RECORD_STACK]
 mov [r13+NEBO_PROFILER_STATE_STACK_KEYS+r15*8],rax
 inc qword [r13+NEBO_PROFILER_STATE_STACK_COUNT]
.store:
 mov rax,[r13+NEBO_PROFILER_STATE_COUNT]
 shl rax,6
 add rax,[r13+NEBO_PROFILER_STATE_EVENTS]
 mov [rax+NEBO_PROFILER_EVENT_PHASE],rbx
 mov rdx,[r12+NEBO_PROFILER_RECORD_UNIT]
 mov [rax+NEBO_PROFILER_EVENT_UNIT],rdx
 mov [rax+NEBO_PROFILER_EVENT_DURATION],r14
 mov rdx,[r12+NEBO_PROFILER_RECORD_MEMORY]
 mov [rax+NEBO_PROFILER_EVENT_MEMORY],rdx
 mov rcx,[r12+NEBO_PROFILER_RECORD_STACK]
 mov [rax+NEBO_PROFILER_EVENT_STACK],rcx
 mov rcx,[r12+NEBO_PROFILER_RECORD_CLASS]
 mov [rax+NEBO_PROFILER_EVENT_CLASS],rcx
 mov rcx,[r12+NEBO_PROFILER_RECORD_REDACTED]
 mov [rax+NEBO_PROFILER_EVENT_REDACTED],rcx
 inc qword [r13+NEBO_PROFILER_STATE_SEQUENCE]
 mov rcx,[r13+NEBO_PROFILER_STATE_SEQUENCE]
 mov [rax+NEBO_PROFILER_EVENT_SEQUENCE],rcx
 mov [r12+NEBO_PROFILER_RECORD_SEQUENCE],rcx
 inc qword [r13+NEBO_PROFILER_STATE_COUNT]
 add [r13+NEBO_PROFILER_STATE_TOTAL_TIME],r14
 cmp rdx,[r13+NEBO_PROFILER_STATE_PEAK_MEMORY]
 jbe .success
 mov [r13+NEBO_PROFILER_STATE_PEAK_MEMORY],rdx
.success:
 mov qword [r12+NEBO_PROFILER_RECORD_RESULT],1
 xor eax,eax
 jmp .done
.phase: mov eax,NEBO_PROFILER_STATUS_PHASE
 jmp .done
.timing: mov eax,NEBO_PROFILER_STATUS_TIMING
 jmp .done
.privacy: mov eax,NEBO_PROFILER_STATUS_PRIVACY
 jmp .done
.limit: mov eax,NEBO_PROFILER_STATUS_LIMIT
 jmp .done
.cardinality: mov eax,NEBO_PROFILER_STATUS_CARDINALITY
 jmp .done
.overflow: mov eax,NEBO_PROFILER_STATUS_OVERFLOW
 jmp .done
.capability: mov eax,NEBO_PROFILER_STATUS_CAPABILITY
 jmp .done
.bad_saved: mov eax,NEBO_PROFILER_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.bad: mov eax,NEBO_PROFILER_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_profiler_emit_report
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_PROFILER_REPORT_RESULT],0
 mov rsi,[rdi+NEBO_PROFILER_REPORT_STATE]
 mov rdx,[rdi+NEBO_PROFILER_REPORT_OUTPUT]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 mov rax,NEBO_PROFILER_MAGIC
 cmp [rsi+NEBO_PROFILER_STATE_MAGIC],rax
 jne .bad
 cmp qword [rdi+NEBO_PROFILER_REPORT_VERSION],NEBO_PROFILER_VERSION
 jne .version
 cmp qword [rdi+NEBO_PROFILER_REPORT_CAPACITY],NEBO_PROFILER_OUTPUT_SIZE
 jb .limit_report
 push rbx
 push r12
 mov r12,rdi
 mov rdi,rdx
 mov ecx,NEBO_PROFILER_OUTPUT_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_PROFILER_REPORT_MAGIC
 mov [rdx+NEBO_PROFILER_OUTPUT_MAGIC],rax
 mov qword [rdx+NEBO_PROFILER_OUTPUT_VERSION],NEBO_PROFILER_VERSION
 mov rax,[rsi+NEBO_PROFILER_STATE_COUNT]
 mov [rdx+NEBO_PROFILER_OUTPUT_EVENTS],rax
 mov rax,[rsi+NEBO_PROFILER_STATE_TOTAL_TIME]
 mov [rdx+NEBO_PROFILER_OUTPUT_TOTAL_TIME],rax
 mov rax,[rsi+NEBO_PROFILER_STATE_PEAK_MEMORY]
 mov [rdx+NEBO_PROFILER_OUTPUT_PEAK_MEMORY],rax
 mov rax,[rsi+NEBO_PROFILER_STATE_STACK_COUNT]
 mov [rdx+NEBO_PROFILER_OUTPUT_FLAME_STACKS],rax
 xor ebx,ebx
.report_loop:
 cmp rbx,[rsi+NEBO_PROFILER_STATE_COUNT]
 jae .report_done
 mov rax,rbx
 shl rax,6
 add rax,[rsi+NEBO_PROFILER_STATE_EVENTS]
 cmp qword [rax+NEBO_PROFILER_EVENT_REDACTED],0
 je .not_redacted
 inc qword [rdx+NEBO_PROFILER_OUTPUT_REDACTED]
.not_redacted:
 mov rcx,[rax+NEBO_PROFILER_EVENT_PHASE]
 dec rcx
 inc qword [rdx+NEBO_PROFILER_OUTPUT_PHASE_COUNTS+rcx*8]
 mov rdi,[rax+NEBO_PROFILER_EVENT_DURATION]
 add [rdx+NEBO_PROFILER_OUTPUT_PHASE_TIMES+rcx*8],rdi
 inc rbx
 jmp .report_loop
.report_done:
 mov qword [r12+NEBO_PROFILER_REPORT_RESULT],NEBO_PROFILER_OUTPUT_SIZE
 xor eax,eax
 pop r12
 pop rbx
 ret
.version: mov eax,NEBO_PROFILER_STATUS_VERSION
 ret
.limit_report: mov eax,NEBO_PROFILER_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_PROFILER_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
