; BIBLIOTECA-PADRAO-POR-DOMINIOS-F03 versioned native ABI/runtime/object metadata compatibility.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/abi/abi_versioning.inc"
section .text
NEBOC_ABI_FUNCTION nebo_abi_metadata_init
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_ABI_INIT_RESULT],0
 mov rsi,[rdi+NEBO_ABI_INIT_OUTPUT]
 test rsi,rsi
 jz .bad
 cmp qword [rdi+NEBO_ABI_INIT_CAPACITY],NEBO_ABI_METADATA_SIZE
 jb .limit
 mov r8,[rdi+NEBO_ABI_INIT_FEATURES]
 mov rax,r8
 and rax,~NEBO_ABI_FEATURE_KNOWN_MASK
 jnz .feature
 mov r9,rdi
 mov rdi,rsi
 mov ecx,NEBO_ABI_METADATA_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_ABI_METADATA_MAGIC
 mov [rsi+NEBO_ABI_METADATA_MAGIC_OFF],rax
 mov qword [rsi+NEBO_ABI_METADATA_SCHEMA],NEBO_ABI_SCHEMA_VERSION
 mov rax,NEBO_ABI_TARGET_X86_64_SYSTEMV_ELF_LINUX
 mov [rsi+NEBO_ABI_METADATA_TARGET],rax
 mov qword [rsi+NEBO_ABI_METADATA_ABI_MAJOR],NEBO_ABI_CURRENT_MAJOR
 mov qword [rsi+NEBO_ABI_METADATA_ABI_MINOR],NEBO_ABI_CURRENT_MINOR
 mov qword [rsi+NEBO_ABI_METADATA_RUNTIME_MAJOR],NEBO_RUNTIME_CURRENT_MAJOR
 mov qword [rsi+NEBO_ABI_METADATA_RUNTIME_MINOR],NEBO_RUNTIME_CURRENT_MINOR
 mov qword [rsi+NEBO_ABI_METADATA_OBJECT_VERSION],NEBO_OBJECT_METADATA_VERSION
 mov [rsi+NEBO_ABI_METADATA_REQUIRED_FEATURES],r8
 mov qword [rsi+NEBO_ABI_METADATA_DATALAYOUT],NEBO_ABI_DATALAYOUT_X86_64_SYSTEMV_ELF
 mov qword [r9+NEBO_ABI_INIT_RESULT],NEBO_ABI_METADATA_SIZE
 xor eax,eax
 ret
.limit: mov eax,NEBO_ABI_STATUS_LIMIT
 ret
.feature: mov eax,NEBO_ABI_STATUS_FEATURE
 ret
.bad: mov eax,NEBO_ABI_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_abi_validate
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_ABI_VALIDATE_RESULT],0
 mov r10,rdi
 mov rsi,[r10+NEBO_ABI_VALIDATE_METADATA]
 mov rdx,[r10+NEBO_ABI_VALIDATE_REPORT]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 cmp qword [r10+NEBO_ABI_VALIDATE_CAPACITY],NEBO_ABI_REPORT_SIZE
 jb .limit
 mov rax,NEBO_ABI_METADATA_MAGIC
 cmp [rsi+NEBO_ABI_METADATA_MAGIC_OFF],rax
 jne .corrupt
 cmp qword [rsi+NEBO_ABI_METADATA_SCHEMA],NEBO_ABI_SCHEMA_VERSION
 jne .schema
 mov rax,NEBO_ABI_TARGET_X86_64_SYSTEMV_ELF_LINUX
 cmp [rsi+NEBO_ABI_METADATA_TARGET],rax
 jne .target
 cmp qword [rsi+NEBO_ABI_METADATA_ABI_MAJOR],NEBO_ABI_CURRENT_MAJOR
 jne .abi
 cmp qword [rsi+NEBO_ABI_METADATA_ABI_MINOR],NEBO_ABI_CURRENT_MINOR
 ja .abi
 cmp qword [rsi+NEBO_ABI_METADATA_RUNTIME_MAJOR],NEBO_RUNTIME_CURRENT_MAJOR
 jne .runtime
 cmp qword [rsi+NEBO_ABI_METADATA_RUNTIME_MINOR],NEBO_RUNTIME_CURRENT_MINOR
 ja .runtime
 cmp qword [rsi+NEBO_ABI_METADATA_OBJECT_VERSION],NEBO_OBJECT_METADATA_VERSION
 jne .object
 mov r8,[rsi+NEBO_ABI_METADATA_REQUIRED_FEATURES]
 mov rax,r8
 and rax,~NEBO_ABI_FEATURE_KNOWN_MASK
 jnz .feature
 mov rax,[r10+NEBO_ABI_VALIDATE_SUPPORTED]
 mov r9,rax
 and rax,~NEBO_ABI_FEATURE_KNOWN_MASK
 jnz .feature
 not r9
 and r9,r8
 jnz .feature
 cmp qword [rsi+NEBO_ABI_METADATA_DATALAYOUT],NEBO_ABI_DATALAYOUT_X86_64_SYSTEMV_ELF
 jne .layout
 mov rdi,rdx
 mov ecx,NEBO_ABI_REPORT_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_ABI_REPORT_MAGIC
 mov [rdx+NEBO_ABI_REPORT_MAGIC_OFF],rax
 mov qword [rdx+NEBO_ABI_REPORT_SCHEMA],NEBO_ABI_SCHEMA_VERSION
 mov qword [rdx+NEBO_ABI_REPORT_OBJECT_COUNT],1
 mov rax,[rsi+NEBO_ABI_METADATA_TARGET]
 mov [rdx+NEBO_ABI_REPORT_TARGET],rax
 mov rax,[rsi+NEBO_ABI_METADATA_ABI_MAJOR]
 mov [rdx+NEBO_ABI_REPORT_ABI_MAJOR],rax
 mov rax,[rsi+NEBO_ABI_METADATA_ABI_MINOR]
 mov [rdx+NEBO_ABI_REPORT_ABI_MINOR],rax
 mov rax,[rsi+NEBO_ABI_METADATA_RUNTIME_MAJOR]
 mov [rdx+NEBO_ABI_REPORT_RUNTIME_MAJOR],rax
 mov rax,[rsi+NEBO_ABI_METADATA_RUNTIME_MINOR]
 mov [rdx+NEBO_ABI_REPORT_RUNTIME_MINOR],rax
 mov rax,[rsi+NEBO_ABI_METADATA_OBJECT_VERSION]
 mov [rdx+NEBO_ABI_REPORT_OBJECT_VERSION],rax
 mov [rdx+NEBO_ABI_REPORT_FEATURES],r8
 mov rax,[rsi+NEBO_ABI_METADATA_DATALAYOUT]
 mov [rdx+NEBO_ABI_REPORT_DATALAYOUT],rax
 mov qword [r10+NEBO_ABI_VALIDATE_RESULT],NEBO_ABI_REPORT_SIZE
 xor eax,eax
 ret
.limit: mov eax,NEBO_ABI_STATUS_LIMIT
 ret
.corrupt: mov eax,NEBO_ABI_STATUS_CORRUPT
 ret
.schema: mov eax,NEBO_ABI_STATUS_SCHEMA
 ret
.target: mov eax,NEBO_ABI_STATUS_TARGET
 ret
.abi: mov eax,NEBO_ABI_STATUS_ABI_VERSION
 ret
.runtime: mov eax,NEBO_ABI_STATUS_RUNTIME_VERSION
 ret
.object: mov eax,NEBO_ABI_STATUS_OBJECT_VERSION
 ret
.feature: mov eax,NEBO_ABI_STATUS_FEATURE
 ret
.layout: mov eax,NEBO_ABI_STATUS_DATALAYOUT
 ret
.bad: mov eax,NEBO_ABI_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_abi_link_check
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_ABI_LINK_RESULT],0
 mov r10,rdi
 mov rsi,[r10+NEBO_ABI_LINK_OBJECTS]
 mov rcx,[r10+NEBO_ABI_LINK_COUNT]
 mov rdx,[r10+NEBO_ABI_LINK_STRIDE]
 test rsi,rsi
 jz .bad
 test rcx,rcx
 jz .bad
 cmp rcx,NEBO_ABI_MAX_LINK_OBJECTS
 ja .limit
 cmp rdx,NEBO_ABI_METADATA_SIZE
 jb .limit
 mov rdi,[r10+NEBO_ABI_LINK_REPORT]
 test rdi,rdi
 jz .bad
 cmp qword [r10+NEBO_ABI_LINK_CAPACITY],NEBO_ABI_REPORT_SIZE
 jb .limit
 mov r11,[r10+NEBO_ABI_LINK_SUPPORTED]
 mov rax,r11
 and rax,~NEBO_ABI_FEATURE_KNOWN_MASK
 jnz .feature
 xor r8d,r8d
 xor r9d,r9d
.loop:
 cmp r8,rcx
 jae .emit
 mov rax,r8
 imul rax,rdx
 add rax,rsi
 mov rdi,NEBO_ABI_METADATA_MAGIC
 cmp [rax+NEBO_ABI_METADATA_MAGIC_OFF],rdi
 jne .corrupt
 cmp qword [rax+NEBO_ABI_METADATA_SCHEMA],NEBO_ABI_SCHEMA_VERSION
 jne .schema
 mov rdi,NEBO_ABI_TARGET_X86_64_SYSTEMV_ELF_LINUX
 cmp [rax+NEBO_ABI_METADATA_TARGET],rdi
 jne .target
 cmp qword [rax+NEBO_ABI_METADATA_ABI_MAJOR],NEBO_ABI_CURRENT_MAJOR
 jne .abi
 cmp qword [rax+NEBO_ABI_METADATA_ABI_MINOR],NEBO_ABI_CURRENT_MINOR
 ja .abi
 cmp qword [rax+NEBO_ABI_METADATA_RUNTIME_MAJOR],NEBO_RUNTIME_CURRENT_MAJOR
 jne .runtime
 cmp qword [rax+NEBO_ABI_METADATA_RUNTIME_MINOR],NEBO_RUNTIME_CURRENT_MINOR
 ja .runtime
 cmp qword [rax+NEBO_ABI_METADATA_OBJECT_VERSION],NEBO_OBJECT_METADATA_VERSION
 jne .object
 cmp qword [rax+NEBO_ABI_METADATA_DATALAYOUT],NEBO_ABI_DATALAYOUT_X86_64_SYSTEMV_ELF
 jne .layout
 mov rdi,[rax+NEBO_ABI_METADATA_REQUIRED_FEATURES]
 mov rax,rdi
 and rax,~NEBO_ABI_FEATURE_KNOWN_MASK
 jnz .feature
 mov rax,r11
 not rax
 and rax,rdi
 jnz .feature
 or r9,rdi
 inc r8
 jmp .loop
.emit:
 mov rdi,[r10+NEBO_ABI_LINK_REPORT]
 mov ecx,NEBO_ABI_REPORT_SIZE/8
 xor eax,eax
 rep stosq
 mov rdi,[r10+NEBO_ABI_LINK_REPORT]
 mov rax,NEBO_ABI_REPORT_MAGIC
 mov [rdi+NEBO_ABI_REPORT_MAGIC_OFF],rax
 mov qword [rdi+NEBO_ABI_REPORT_SCHEMA],NEBO_ABI_SCHEMA_VERSION
 mov rax,[r10+NEBO_ABI_LINK_COUNT]
 mov [rdi+NEBO_ABI_REPORT_OBJECT_COUNT],rax
 mov rax,NEBO_ABI_TARGET_X86_64_SYSTEMV_ELF_LINUX
 mov [rdi+NEBO_ABI_REPORT_TARGET],rax
 mov qword [rdi+NEBO_ABI_REPORT_ABI_MAJOR],NEBO_ABI_CURRENT_MAJOR
 mov qword [rdi+NEBO_ABI_REPORT_ABI_MINOR],NEBO_ABI_CURRENT_MINOR
 mov qword [rdi+NEBO_ABI_REPORT_RUNTIME_MAJOR],NEBO_RUNTIME_CURRENT_MAJOR
 mov qword [rdi+NEBO_ABI_REPORT_RUNTIME_MINOR],NEBO_RUNTIME_CURRENT_MINOR
 mov qword [rdi+NEBO_ABI_REPORT_OBJECT_VERSION],NEBO_OBJECT_METADATA_VERSION
 mov [rdi+NEBO_ABI_REPORT_FEATURES],r9
 mov qword [rdi+NEBO_ABI_REPORT_DATALAYOUT],NEBO_ABI_DATALAYOUT_X86_64_SYSTEMV_ELF
 mov qword [r10+NEBO_ABI_LINK_RESULT],NEBO_ABI_REPORT_SIZE
 xor eax,eax
 ret
.limit: mov eax,NEBO_ABI_STATUS_LIMIT
 ret
.corrupt: mov eax,NEBO_ABI_STATUS_CORRUPT
 ret
.schema: mov eax,NEBO_ABI_STATUS_SCHEMA
 ret
.target: mov eax,NEBO_ABI_STATUS_TARGET
 ret
.abi: mov eax,NEBO_ABI_STATUS_ABI_VERSION
 ret
.runtime: mov eax,NEBO_ABI_STATUS_RUNTIME_VERSION
 ret
.object: mov eax,NEBO_ABI_STATUS_OBJECT_VERSION
 ret
.feature: mov eax,NEBO_ABI_STATUS_FEATURE
 ret
.layout: mov eax,NEBO_ABI_STATUS_DATALAYOUT
 ret
.bad: mov eax,NEBO_ABI_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
