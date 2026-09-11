bits 64
default rel
%include "compiler/profiler/profiler.inc"
extern nebo_capability_authority_init,nebo_capability_grant
extern nebo_profiler_init,nebo_profiler_record,nebo_profiler_emit_report
section .rodata
secret: times 32 db 0x49
section .bss
align 16
authority resb NEBO_AUTHORITY_SIZE
capability resb NEBO_CAPABILITY_SIZE
grant resb NEBO_CAPABILITY_GRANT_SIZE
state resb NEBO_PROFILER_STATE_SIZE
events resb NEBO_PROFILER_EVENT_SIZE*128
init resb NEBO_PROFILER_INIT_SIZE
record resb NEBO_PROFILER_RECORD_SIZE
report_req resb NEBO_PROFILER_REPORT_SIZE
report_out resb NEBO_PROFILER_OUTPUT_SIZE
section .text
prepare_record:
 lea rdi,[record]
 mov ecx,NEBO_PROFILER_RECORD_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [record+NEBO_PROFILER_RECORD_STATE],rax
 mov qword [record+NEBO_PROFILER_RECORD_PHASE],NEBO_PROFILER_PHASE_HIR
 mov qword [record+NEBO_PROFILER_RECORD_UNIT],0x101
 mov qword [record+NEBO_PROFILER_RECORD_START],10
 mov qword [record+NEBO_PROFILER_RECORD_END],30
 mov qword [record+NEBO_PROFILER_RECORD_MEMORY],100
 mov qword [record+NEBO_PROFILER_RECORD_STACK],0xaaa
 ret
prepare_report:
 lea rdi,[report_req]
 mov ecx,NEBO_PROFILER_REPORT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [report_req+NEBO_PROFILER_REPORT_STATE],rax
 lea rax,[report_out]
 mov [report_req+NEBO_PROFILER_REPORT_OUTPUT],rax
 mov qword [report_req+NEBO_PROFILER_REPORT_CAPACITY],NEBO_PROFILER_OUTPUT_SIZE
 mov qword [report_req+NEBO_PROFILER_REPORT_VERSION],NEBO_PROFILER_VERSION
 ret
global _start
_start:
 lea rdi,[authority]
 mov esi,0x2409
 lea rdx,[secret]
 call nebo_capability_authority_init
 test eax,eax
 jnz fail
 lea rdi,[grant]
 mov ecx,NEBO_CAPABILITY_GRANT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[authority]
 mov [grant+NEBO_CAPABILITY_GRANT_AUTHORITY_OFFSET],rax
 lea rax,[capability]
 mov [grant+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET],rax
 mov qword [grant+NEBO_CAPABILITY_GRANT_KIND_OFFSET],NEBO_CAPABILITY_CLOCK
 mov qword [grant+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_CLOCK
 mov qword [grant+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],1
 mov qword [grant+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],100
 mov qword [grant+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],9
 lea rdi,[grant]
 call nebo_capability_grant
 test eax,eax
 jnz fail
 lea rdi,[init]
 mov ecx,NEBO_PROFILER_INIT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [init+NEBO_PROFILER_INIT_STATE],rax
 lea rax,[events]
 mov [init+NEBO_PROFILER_INIT_EVENTS],rax
 mov qword [init+NEBO_PROFILER_INIT_CAPACITY],128
 lea rax,[authority]
 mov [init+NEBO_PROFILER_INIT_AUTHORITY],rax
 lea rax,[capability]
 mov [init+NEBO_PROFILER_INIT_CAPABILITY],rax
 mov qword [init+NEBO_PROFILER_INIT_SCOPE],9
 lea rdi,[init]
 call nebo_profiler_init
 test eax,eax
 jnz fail
 call prepare_record
 lea rdi,[record]
 call nebo_profiler_record
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_PROFILER_STATE_COUNT],1
 jne fail
 cmp qword [state+NEBO_PROFILER_STATE_TOTAL_TIME],20
 jne fail
 cmp qword [state+NEBO_PROFILER_STATE_PEAK_MEMORY],100
 jne fail
 cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],99
 jne fail
 call prepare_record
 mov qword [record+NEBO_PROFILER_RECORD_PHASE],NEBO_PROFILER_PHASE_LIR
 mov qword [record+NEBO_PROFILER_RECORD_START],20
 mov qword [record+NEBO_PROFILER_RECORD_END],50
 mov qword [record+NEBO_PROFILER_RECORD_MEMORY],200
 mov qword [record+NEBO_PROFILER_RECORD_STACK],0xbbb
 mov qword [record+NEBO_PROFILER_RECORD_CLASS],nebo_privacy_PRIVACY_SECRET
 lea rdi,[record]
 call nebo_profiler_record
 cmp eax,NEBO_PROFILER_STATUS_PRIVACY
 jne fail
 cmp qword [state+NEBO_PROFILER_STATE_COUNT],1
 jne fail
 cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],99
 jne fail
 mov qword [record+NEBO_PROFILER_RECORD_REDACTED],1
 lea rdi,[record]
 call nebo_profiler_record
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_PROFILER_STATE_TOTAL_TIME],50
 jne fail
 cmp qword [state+NEBO_PROFILER_STATE_PEAK_MEMORY],200
 jne fail
 call prepare_report
 lea rdi,[report_req]
 call nebo_profiler_emit_report
 test eax,eax
 jnz fail
 mov rax,NEBO_PROFILER_REPORT_MAGIC
 cmp [report_out+NEBO_PROFILER_OUTPUT_MAGIC],rax
 jne fail
 cmp qword [report_out+NEBO_PROFILER_OUTPUT_VERSION],1
 jne fail
 cmp qword [report_out+NEBO_PROFILER_OUTPUT_EVENTS],2
 jne fail
 cmp qword [report_out+NEBO_PROFILER_OUTPUT_TOTAL_TIME],50
 jne fail
 cmp qword [report_out+NEBO_PROFILER_OUTPUT_PEAK_MEMORY],200
 jne fail
 cmp qword [report_out+NEBO_PROFILER_OUTPUT_REDACTED],1
 jne fail
 cmp qword [report_out+NEBO_PROFILER_OUTPUT_FLAME_STACKS],2
 jne fail
 cmp qword [report_out+NEBO_PROFILER_OUTPUT_PHASE_COUNTS],1
 jne fail
 cmp qword [report_out+NEBO_PROFILER_OUTPUT_PHASE_COUNTS+8],1
 jne fail
 call prepare_record
 mov qword [record+NEBO_PROFILER_RECORD_START],31
 mov qword [record+NEBO_PROFILER_RECORD_END],30
 lea rdi,[record]
 call nebo_profiler_record
 cmp eax,NEBO_PROFILER_STATUS_TIMING
 jne fail
 cmp qword [state+NEBO_PROFILER_STATE_COUNT],2
 jne fail
 mov r15,2
.fill_stacks:
 call prepare_record
 mov [record+NEBO_PROFILER_RECORD_UNIT],r15
 mov rax,r15
 add rax,0x1000
 mov [record+NEBO_PROFILER_RECORD_STACK],rax
 mov qword [record+NEBO_PROFILER_RECORD_START],0
 mov qword [record+NEBO_PROFILER_RECORD_END],1
 lea rdi,[record]
 call nebo_profiler_record
 test eax,eax
 jnz fail
 inc r15
 cmp r15,64
 jb .fill_stacks
 cmp qword [state+NEBO_PROFILER_STATE_STACK_COUNT],64
 jne fail
 call prepare_record
 mov qword [record+NEBO_PROFILER_RECORD_STACK],0xdead
 lea rdi,[record]
 call nebo_profiler_record
 cmp eax,NEBO_PROFILER_STATUS_CARDINALITY
 jne fail
 call prepare_record
 lea rdi,[record]
 call nebo_profiler_record
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_PROFILER_STATE_STACK_COUNT],64
 jne fail
 call prepare_report
 mov qword [report_req+NEBO_PROFILER_REPORT_CAPACITY],127
 lea rdi,[report_req]
 call nebo_profiler_emit_report
 cmp eax,NEBO_PROFILER_STATUS_LIMIT
 jne fail
 call prepare_report
 mov qword [report_req+NEBO_PROFILER_REPORT_VERSION],2
 lea rdi,[report_req]
 call nebo_profiler_emit_report
 cmp eax,NEBO_PROFILER_STATUS_VERSION
 jne fail
 call prepare_record
 mov qword [record+NEBO_PROFILER_RECORD_PHASE],5
 lea rdi,[record]
 call nebo_profiler_record
 cmp eax,NEBO_PROFILER_STATUS_PHASE
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
