; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-F01 shared bounded extension ABI contract.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/plugins/extension_abi.inc"
section .text
NEBOC_ABI_FUNCTION nebo_extension_validate
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_EXTENSION_REQ_RESULT],0
 mov r10,rdi
 mov rsi,[r10+NEBO_EXTENSION_REQ_DESC]
 mov rdx,[r10+NEBO_EXTENSION_REQ_REPORT]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 cmp qword [r10+NEBO_EXTENSION_REQ_CAPACITY],NEBO_EXTENSION_REPORT_SIZE
 jb .layout
 mov rax,NEBO_EXTENSION_MAGIC
 cmp [rsi+NEBO_EXTENSION_DESC_MAGIC],rax
 jne .corrupt
 cmp qword [rsi+NEBO_EXTENSION_DESC_SCHEMA],NEBO_EXTENSION_SCHEMA
 jne .schema
 mov r8,[rsi+NEBO_EXTENSION_DESC_KIND]
 cmp r8,NEBO_EXTENSION_KIND_PLUGIN
 jb .kind
 cmp r8,NEBO_EXTENSION_KIND_PROTOCOL
 ja .kind
 mov rax,NEBO_EXTENSION_TARGET
 cmp [rsi+NEBO_EXTENSION_DESC_TARGET],rax
 jne .target
 cmp qword [rsi+NEBO_EXTENSION_DESC_ABI],NEBO_EXTENSION_ABI_MAJOR
 jne .abi
 cmp qword [rsi+NEBO_EXTENSION_DESC_RUNTIME],NEBO_EXTENSION_RUNTIME_MAJOR
 jne .abi
 mov r9,[rsi+NEBO_EXTENSION_DESC_EFFECTS]
 mov rax,r9
 and rax,~NEBO_EXTENSION_EFFECT_MASK
 jnz .effect
 mov r11,[rsi+NEBO_EXTENSION_DESC_CAPABILITIES]
 mov rax,r11
 and rax,~NEBO_EXTENSION_CAPABILITY_MASK
 jnz .capability
 mov rcx,[rsi+NEBO_EXTENSION_DESC_FEATURES]
 mov rax,rcx
 and rax,~NEBO_EXTENSION_FEATURE_MASK
 jnz .feature
 cmp qword [rsi+NEBO_EXTENSION_DESC_RECORD_SIZE],NEBO_EXTENSION_DESC_SIZE
 jne .layout
 cmp qword [rsi+NEBO_EXTENSION_DESC_RESERVED],0
 jne .layout
 mov rdi,rdx
 mov ecx,NEBO_EXTENSION_REPORT_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_EXTENSION_REPORT_MAGIC
 mov [rdx+NEBO_EXTENSION_REPORT_MAGIC_OFF],rax
 mov qword [rdx+NEBO_EXTENSION_REPORT_SCHEMA],NEBO_EXTENSION_SCHEMA
 mov [rdx+NEBO_EXTENSION_REPORT_KIND],r8
 mov [rdx+NEBO_EXTENSION_REPORT_EFFECTS],r9
 mov [rdx+NEBO_EXTENSION_REPORT_CAPABILITIES],r11
 mov rax,[rsi+NEBO_EXTENSION_DESC_FEATURES]
 mov [rdx+NEBO_EXTENSION_REPORT_FEATURES],rax
 mov qword [rdx+NEBO_EXTENSION_REPORT_ABI],NEBO_EXTENSION_ABI_MAJOR
 mov qword [rdx+NEBO_EXTENSION_REPORT_RUNTIME],NEBO_EXTENSION_RUNTIME_MAJOR
 mov qword [r10+NEBO_EXTENSION_REQ_RESULT],NEBO_EXTENSION_REPORT_SIZE
 xor eax,eax
 ret
.corrupt: mov eax,NEBO_EXTENSION_STATUS_CORRUPT
 ret
.schema: mov eax,NEBO_EXTENSION_STATUS_SCHEMA
 ret
.kind: mov eax,NEBO_EXTENSION_STATUS_KIND
 ret
.target: mov eax,NEBO_EXTENSION_STATUS_TARGET
 ret
.abi: mov eax,NEBO_EXTENSION_STATUS_ABI_RUNTIME
 ret
.effect: mov eax,NEBO_EXTENSION_STATUS_EFFECT
 ret
.capability: mov eax,NEBO_EXTENSION_STATUS_CAPABILITY
 ret
.feature: mov eax,NEBO_EXTENSION_STATUS_FEATURE
 ret
.layout: mov eax,NEBO_EXTENSION_STATUS_LAYOUT
 ret
.bad: mov eax,NEBO_EXTENSION_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
