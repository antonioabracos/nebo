bits 64
default rel
%include "compiler/targets/target_context.inc"
extern nebo_target_registry_init,nebo_target_register,nebo_target_query,nebo_target_report
section .bss
align 16
state resb NEBO_TARGET_STATE_SIZE
entries resb NEBO_TARGET_CTX_SIZE*2
context resb NEBO_TARGET_CTX_SIZE
output resb NEBO_TARGET_CTX_SIZE
init resb NEBO_TARGET_INIT_SIZE
request resb NEBO_TARGET_REGISTER_SIZE
query resb NEBO_TARGET_QUERY_SIZE
report_req resb NEBO_TARGET_REPORT_SIZE
report_out resb NEBO_TARGET_REPORT_OUT_SIZE
section .text
prepare_context:
 lea rdi,[context]
 mov ecx,NEBO_TARGET_CTX_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_TARGET_TRIPLE_X86_64_SYSTEMV_ELF_LINUX
 mov [context+NEBO_TARGET_CTX_TRIPLE],rax
 mov qword [context+NEBO_TARGET_CTX_OBJECT],NEBO_TARGET_OBJECT_ELF
 mov qword [context+NEBO_TARGET_CTX_CALLING],NEBO_TARGET_CC_SYSTEMV
 mov qword [context+NEBO_TARGET_CTX_POINTER_BITS],64
 mov qword [context+NEBO_TARGET_CTX_ENDIAN],NEBO_TARGET_ENDIAN_LITTLE
 mov qword [context+NEBO_TARGET_CTX_FEATURES],0x17
 mov qword [context+NEBO_TARGET_CTX_SYSCALL_PROFILE],0x2701
 mov qword [context+NEBO_TARGET_CTX_LINKER],0x6c64
 mov qword [context+NEBO_TARGET_CTX_MATURITY],NEBO_TARGET_MATURITY_CERTIFIED
 mov qword [context+NEBO_TARGET_CTX_DATALAYOUT],0x400801
 mov qword [context+NEBO_TARGET_CTX_COMPONENTS],NEBO_TARGET_CERTIFIED_COMPONENTS
 mov qword [context+NEBO_TARGET_CTX_ABI_VERSION],NEBO_TARGET_VERSION
 ret
register_context:
 lea rdi,[request]
 mov ecx,NEBO_TARGET_REGISTER_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [request+NEBO_TARGET_REGISTER_STATE],rax
 lea rax,[context]
 mov [request+NEBO_TARGET_REGISTER_CONTEXT],rax
 lea rdi,[request]
 jmp nebo_target_register
global _start
_start:
 lea rdi,[init]
 mov ecx,NEBO_TARGET_INIT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [init+NEBO_TARGET_INIT_STATE],rax
 lea rax,[entries]
 mov [init+NEBO_TARGET_INIT_ENTRIES],rax
 mov qword [init+NEBO_TARGET_INIT_CAPACITY],2
 lea rdi,[init]
 call nebo_target_registry_init
 test eax,eax
 jnz fail
 call prepare_context
 call register_context
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_TARGET_STATE_COUNT],1
 jne fail
 cmp qword [state+NEBO_TARGET_STATE_CERTIFIED],1
 jne fail
 call register_context
 cmp eax,NEBO_TARGET_STATUS_DUPLICATE
 jne fail
 cmp qword [state+NEBO_TARGET_STATE_COUNT],1
 jne fail
 lea rdi,[query]
 mov ecx,NEBO_TARGET_QUERY_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [query+NEBO_TARGET_QUERY_STATE],rax
 mov rax,NEBO_TARGET_TRIPLE_X86_64_SYSTEMV_ELF_LINUX
 mov [query+NEBO_TARGET_QUERY_TRIPLE],rax
 lea rax,[output]
 mov [query+NEBO_TARGET_QUERY_OUTPUT],rax
 lea rdi,[query]
 call nebo_target_query
 test eax,eax
 jnz fail
 cmp qword [output+NEBO_TARGET_CTX_MATURITY],NEBO_TARGET_MATURITY_CERTIFIED
 jne fail
 mov qword [query+NEBO_TARGET_QUERY_TRIPLE],0xdead
 lea rdi,[query]
 call nebo_target_query
 cmp eax,NEBO_TARGET_STATUS_UNKNOWN
 jne fail
 call prepare_context
 mov rax,NEBO_TARGET_TRIPLE_AARCH64_ELF_LINUX
 mov [context+NEBO_TARGET_CTX_TRIPLE],rax
 call register_context
 cmp eax,NEBO_TARGET_STATUS_FAKE_CERTIFIED
 jne fail
 cmp qword [state+NEBO_TARGET_STATE_COUNT],1
 jne fail
 mov qword [context+NEBO_TARGET_CTX_MATURITY],NEBO_TARGET_MATURITY_UNAVAILABLE
 mov qword [context+NEBO_TARGET_CTX_COMPONENTS],0
 call register_context
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_TARGET_STATE_COUNT],2
 jne fail
 cmp qword [state+NEBO_TARGET_STATE_CERTIFIED],1
 jne fail
 call prepare_context
 mov qword [context+NEBO_TARGET_CTX_TRIPLE],0x7777
 mov qword [context+NEBO_TARGET_CTX_MATURITY],NEBO_TARGET_MATURITY_UNAVAILABLE
 mov qword [context+NEBO_TARGET_CTX_COMPONENTS],0
 call register_context
 cmp eax,NEBO_TARGET_STATUS_LIMIT
 jne fail
 lea rdi,[report_req]
 mov ecx,NEBO_TARGET_REPORT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [report_req+NEBO_TARGET_REPORT_STATE],rax
 lea rax,[report_out]
 mov [report_req+NEBO_TARGET_REPORT_OUTPUT],rax
 mov qword [report_req+NEBO_TARGET_REPORT_CAPACITY],NEBO_TARGET_REPORT_OUT_SIZE
 mov qword [report_req+NEBO_TARGET_REPORT_VERSION],NEBO_TARGET_VERSION
 lea rdi,[report_req]
 call nebo_target_report
 test eax,eax
 jnz fail
 cmp qword [report_out+NEBO_TARGET_REPORT_OUT_COUNT],2
 jne fail
 cmp qword [report_out+NEBO_TARGET_REPORT_OUT_CERTIFIED],1
 jne fail
 mov rax,NEBO_TARGET_TRIPLE_X86_64_SYSTEMV_ELF_LINUX
 cmp [report_out+NEBO_TARGET_REPORT_OUT_CERTIFIED_TRIPLE],rax
 jne fail
 cmp qword [report_out+NEBO_TARGET_REPORT_OUT_COMPONENTS],NEBO_TARGET_CERTIFIED_COMPONENTS
 jne fail
 cmp qword [report_out+NEBO_TARGET_REPORT_OUT_POINTER_BITS],64
 jne fail
 mov qword [report_req+NEBO_TARGET_REPORT_VERSION],2
 lea rdi,[report_req]
 call nebo_target_report
 cmp eax,NEBO_TARGET_STATUS_VERSION
 jne fail
 call prepare_context
 mov qword [context+NEBO_TARGET_CTX_DATALAYOUT],0
 mov qword [state+NEBO_TARGET_STATE_COUNT],1
 call register_context
 cmp eax,NEBO_TARGET_STATUS_MISSING_FIELD
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
