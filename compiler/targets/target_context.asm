; BIBLIOTECA-PADRAO-POR-DOMINIOS-F02 bounded factual TargetContext registry.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/targets/target_context.inc"
section .text
NEBOC_ABI_FUNCTION nebo_target_registry_init
 test rdi,rdi
 jz .bad
 mov rsi,[rdi+NEBO_TARGET_INIT_STATE]
 mov rdx,[rdi+NEBO_TARGET_INIT_ENTRIES]
 mov rcx,[rdi+NEBO_TARGET_INIT_CAPACITY]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 test rcx,rcx
 jz .bad
 cmp rcx,NEBO_TARGET_MAX
 ja .limit
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_TARGET_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_TARGET_MAGIC
 mov [rsi+NEBO_TARGET_STATE_MAGIC],rax
 mov [rsi+NEBO_TARGET_STATE_ENTRIES],rdx
 mov rax,[r8+NEBO_TARGET_INIT_CAPACITY]
 mov [rsi+NEBO_TARGET_STATE_CAPACITY],rax
 xor eax,eax
 ret
.limit: mov eax,NEBO_TARGET_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_TARGET_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_target_register
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_TARGET_REGISTER_RESULT],0
 mov rsi,[rdi+NEBO_TARGET_REGISTER_STATE]
 mov rdx,[rdi+NEBO_TARGET_REGISTER_CONTEXT]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 mov rax,NEBO_TARGET_MAGIC
 cmp [rsi+NEBO_TARGET_STATE_MAGIC],rax
 jne .bad
 cmp qword [rdx+NEBO_TARGET_CTX_TRIPLE],0
 je .missing
 cmp qword [rdx+NEBO_TARGET_CTX_OBJECT],0
 je .missing
 cmp qword [rdx+NEBO_TARGET_CTX_CALLING],0
 je .missing
 cmp qword [rdx+NEBO_TARGET_CTX_POINTER_BITS],0
 je .missing
 cmp qword [rdx+NEBO_TARGET_CTX_ENDIAN],0
 je .missing
 cmp qword [rdx+NEBO_TARGET_CTX_DATALAYOUT],0
 je .missing
 cmp qword [rdx+NEBO_TARGET_CTX_ABI_VERSION],NEBO_TARGET_VERSION
 jne .version
 mov r8,[rdx+NEBO_TARGET_CTX_MATURITY]
 test r8,r8
 jz .missing
 cmp r8,NEBO_TARGET_MATURITY_CERTIFIED
 ja .bad
 cmp r8,NEBO_TARGET_MATURITY_CERTIFIED
 jne .scan
 mov rax,NEBO_TARGET_TRIPLE_X86_64_SYSTEMV_ELF_LINUX
 cmp [rdx+NEBO_TARGET_CTX_TRIPLE],rax
 jne .fake
 cmp qword [rdx+NEBO_TARGET_CTX_OBJECT],NEBO_TARGET_OBJECT_ELF
 jne .fake
 cmp qword [rdx+NEBO_TARGET_CTX_CALLING],NEBO_TARGET_CC_SYSTEMV
 jne .fake
 cmp qword [rdx+NEBO_TARGET_CTX_POINTER_BITS],64
 jne .fake
 cmp qword [rdx+NEBO_TARGET_CTX_ENDIAN],NEBO_TARGET_ENDIAN_LITTLE
 jne .fake
 mov rax,[rdx+NEBO_TARGET_CTX_COMPONENTS]
 and eax,NEBO_TARGET_CERTIFIED_COMPONENTS
 cmp eax,NEBO_TARGET_CERTIFIED_COMPONENTS
 jne .fake
.scan:
 xor ecx,ecx
.scan_loop:
 cmp rcx,[rsi+NEBO_TARGET_STATE_COUNT]
 jae .store_check
 imul rax,rcx,NEBO_TARGET_CTX_SIZE
 add rax,[rsi+NEBO_TARGET_STATE_ENTRIES]
 mov r9,[rdx+NEBO_TARGET_CTX_TRIPLE]
 cmp [rax+NEBO_TARGET_CTX_TRIPLE],r9
 je .duplicate
 inc rcx
 jmp .scan_loop
.store_check:
 cmp rcx,[rsi+NEBO_TARGET_STATE_CAPACITY]
 jae .limit
 imul rax,rcx,NEBO_TARGET_CTX_SIZE
 add rax,[rsi+NEBO_TARGET_STATE_ENTRIES]
 push rdi
 push rsi
 mov rdi,rax
 mov rsi,rdx
 mov ecx,NEBO_TARGET_CTX_SIZE/8
 rep movsq
 pop rsi
 pop rdi
 inc qword [rsi+NEBO_TARGET_STATE_COUNT]
 cmp r8,NEBO_TARGET_MATURITY_CERTIFIED
 jne .success
 inc qword [rsi+NEBO_TARGET_STATE_CERTIFIED]
.success:
 mov qword [rdi+NEBO_TARGET_REGISTER_RESULT],1
 xor eax,eax
 ret
.missing: mov eax,NEBO_TARGET_STATUS_MISSING_FIELD
 ret
.fake: mov eax,NEBO_TARGET_STATUS_FAKE_CERTIFIED
 ret
.duplicate: mov eax,NEBO_TARGET_STATUS_DUPLICATE
 ret
.limit: mov eax,NEBO_TARGET_STATUS_LIMIT
 ret
.version: mov eax,NEBO_TARGET_STATUS_VERSION
 ret
.bad: mov eax,NEBO_TARGET_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_target_query
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_TARGET_QUERY_RESULT],0
 mov rsi,[rdi+NEBO_TARGET_QUERY_STATE]
 mov rdx,[rdi+NEBO_TARGET_QUERY_OUTPUT]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 xor ecx,ecx
.loop:
 cmp rcx,[rsi+NEBO_TARGET_STATE_COUNT]
 jae .unknown
 imul rax,rcx,NEBO_TARGET_CTX_SIZE
 add rax,[rsi+NEBO_TARGET_STATE_ENTRIES]
 mov r8,[rdi+NEBO_TARGET_QUERY_TRIPLE]
 cmp [rax+NEBO_TARGET_CTX_TRIPLE],r8
 je .copy
 inc rcx
 jmp .loop
.copy:
 push rdi
 push rsi
 mov rsi,rax
 mov rdi,rdx
 mov ecx,NEBO_TARGET_CTX_SIZE/8
 rep movsq
 pop rsi
 pop rdi
 mov qword [rdi+NEBO_TARGET_QUERY_RESULT],1
 xor eax,eax
 ret
.unknown: mov eax,NEBO_TARGET_STATUS_UNKNOWN
 ret
.bad: mov eax,NEBO_TARGET_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_target_report
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_TARGET_REPORT_RESULT],0
 mov rsi,[rdi+NEBO_TARGET_REPORT_STATE]
 mov rdx,[rdi+NEBO_TARGET_REPORT_OUTPUT]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 cmp qword [rdi+NEBO_TARGET_REPORT_VERSION],NEBO_TARGET_VERSION
 jne .version
 cmp qword [rdi+NEBO_TARGET_REPORT_CAPACITY],NEBO_TARGET_REPORT_OUT_SIZE
 jb .limit
 mov rax,NEBO_TARGET_REPORT_MAGIC
 mov [rdx+NEBO_TARGET_REPORT_OUT_MAGIC],rax
 mov qword [rdx+NEBO_TARGET_REPORT_OUT_VERSION],NEBO_TARGET_VERSION
 mov rax,[rsi+NEBO_TARGET_STATE_COUNT]
 mov [rdx+NEBO_TARGET_REPORT_OUT_COUNT],rax
 mov rax,[rsi+NEBO_TARGET_STATE_CERTIFIED]
 mov [rdx+NEBO_TARGET_REPORT_OUT_CERTIFIED],rax
 mov qword [rdx+NEBO_TARGET_REPORT_OUT_CERTIFIED_TRIPLE],0
 mov qword [rdx+NEBO_TARGET_REPORT_OUT_COMPONENTS],0
 mov qword [rdx+NEBO_TARGET_REPORT_OUT_POINTER_BITS],0
 mov qword [rdx+NEBO_TARGET_REPORT_OUT_MATURITY],0
 xor ecx,ecx
.report_loop:
 cmp rcx,[rsi+NEBO_TARGET_STATE_COUNT]
 jae .done_report
 imul rax,rcx,NEBO_TARGET_CTX_SIZE
 add rax,[rsi+NEBO_TARGET_STATE_ENTRIES]
 cmp qword [rax+NEBO_TARGET_CTX_MATURITY],NEBO_TARGET_MATURITY_CERTIFIED
 je .certified
 inc rcx
 jmp .report_loop
.certified:
 mov r8,[rax+NEBO_TARGET_CTX_TRIPLE]
 mov [rdx+NEBO_TARGET_REPORT_OUT_CERTIFIED_TRIPLE],r8
 mov r8,[rax+NEBO_TARGET_CTX_COMPONENTS]
 mov [rdx+NEBO_TARGET_REPORT_OUT_COMPONENTS],r8
 mov r8,[rax+NEBO_TARGET_CTX_POINTER_BITS]
 mov [rdx+NEBO_TARGET_REPORT_OUT_POINTER_BITS],r8
 mov r8,[rax+NEBO_TARGET_CTX_MATURITY]
 mov [rdx+NEBO_TARGET_REPORT_OUT_MATURITY],r8
.done_report:
 mov qword [rdi+NEBO_TARGET_REPORT_RESULT],NEBO_TARGET_REPORT_OUT_SIZE
 xor eax,eax
 ret
.version: mov eax,NEBO_TARGET_STATUS_VERSION
 ret
.limit: mov eax,NEBO_TARGET_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_TARGET_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
