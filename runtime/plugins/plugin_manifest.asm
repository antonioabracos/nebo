; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-F02 local hash-allowlisted plugin manifest verification.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/plugins/plugin_manifest.inc"
section .text
NEBOC_ABI_FUNCTION nebo_plugin_manifest_verify
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_PLUGIN_REQ_RESULT],0
 mov r10,rdi
 mov rsi,[r10+NEBO_PLUGIN_REQ_MANIFEST]
 mov rdx,[r10+NEBO_PLUGIN_REQ_ALLOWLIST]
 mov rcx,[r10+NEBO_PLUGIN_REQ_ALLOWLIST_COUNT]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 test rcx,rcx
 jz .hash_mismatch
 cmp rcx,NEBO_PLUGIN_MAX_ALLOWLIST
 ja .limit
 cmp qword [r10+NEBO_PLUGIN_REQ_CAPACITY],NEBO_PLUGIN_REPORT_SIZE
 jb .limit
 mov rax,NEBO_PLUGIN_MAGIC
 cmp [rsi+NEBO_PLUGIN_MAN_MAGIC],rax
 jne .corrupt
 cmp qword [rsi+NEBO_PLUGIN_MAN_SCHEMA],NEBO_PLUGIN_SCHEMA
 jne .schema
 cmp qword [rsi+NEBO_PLUGIN_MAN_SIZE],NEBO_PLUGIN_MANIFEST_SIZE
 jne .corrupt
 cmp qword [rsi+NEBO_PLUGIN_MAN_IDENTITY],0
 je .unknown
 mov rax,NEBO_PLUGIN_TARGET
 cmp [rsi+NEBO_PLUGIN_MAN_TARGET],rax
 jne .abi_target
 cmp qword [rsi+NEBO_PLUGIN_MAN_ABI],0
 jne .abi_target
 cmp qword [rsi+NEBO_PLUGIN_MAN_RUNTIME],0
 jne .abi_target
 cmp qword [rsi+NEBO_PLUGIN_MAN_EXPORTS],NEBO_PLUGIN_MAX_EXPORTS
 ja .limit
 mov rax,[rsi+NEBO_PLUGIN_MAN_EFFECTS]
 and rax,~NEBO_PLUGIN_EFFECT_MASK
 jnz .unknown
 mov rax,[rsi+NEBO_PLUGIN_MAN_CAPS]
 and rax,~NEBO_PLUGIN_CAP_MASK
 jnz .unknown
 cmp qword [rsi+NEBO_PLUGIN_MAN_MEMORY],0
 je .budget
 cmp qword [rsi+NEBO_PLUGIN_MAN_MEMORY],NEBO_PLUGIN_MAX_MEMORY
 ja .budget
 cmp qword [rsi+NEBO_PLUGIN_MAN_CALLS],0
 je .budget
 cmp qword [rsi+NEBO_PLUGIN_MAN_CALLS],NEBO_PLUGIN_MAX_CALLS
 ja .budget
 cmp qword [rsi+NEBO_PLUGIN_MAN_LIFECYCLE],NEBO_PLUGIN_LIFECYCLE_V1
 jne .unknown
 cmp qword [rsi+NEBO_PLUGIN_MAN_RESERVED],0
 jne .unknown
 mov rax,[rsi+NEBO_PLUGIN_MAN_HASH0]
 or rax,[rsi+NEBO_PLUGIN_MAN_HASH1]
 or rax,[rsi+NEBO_PLUGIN_MAN_HASH2]
 or rax,[rsi+NEBO_PLUGIN_MAN_HASH3]
 jz .unsigned
 xor r8d,r8d
.scan:
 cmp r8,rcx
 jae .hash_mismatch
 mov rax,r8
 shl rax,5
 add rax,rdx
 mov r9,[rsi+NEBO_PLUGIN_MAN_HASH0]
 cmp [rax],r9
 jne .next
 mov r9,[rsi+NEBO_PLUGIN_MAN_HASH1]
 cmp [rax+8],r9
 jne .next
 mov r9,[rsi+NEBO_PLUGIN_MAN_HASH2]
 cmp [rax+16],r9
 jne .next
 mov r9,[rsi+NEBO_PLUGIN_MAN_HASH3]
 cmp [rax+24],r9
 je .emit
.next:
 inc r8
 jmp .scan
.emit:
 mov rdx,[r10+NEBO_PLUGIN_REQ_REPORT]
 test rdx,rdx
 jz .bad
 mov rdi,rdx
 mov ecx,NEBO_PLUGIN_REPORT_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_PLUGIN_REPORT_MAGIC
 mov [rdx+NEBO_PLUGIN_REPORT_MAGIC_OFF],rax
 mov qword [rdx+NEBO_PLUGIN_REPORT_SCHEMA],NEBO_PLUGIN_SCHEMA
 mov rax,[rsi+NEBO_PLUGIN_MAN_IDENTITY]
 mov [rdx+NEBO_PLUGIN_REPORT_IDENTITY],rax
 mov rax,[rsi+NEBO_PLUGIN_MAN_EXPORTS]
 mov [rdx+NEBO_PLUGIN_REPORT_EXPORTS],rax
 mov rax,[rsi+NEBO_PLUGIN_MAN_EFFECTS]
 mov [rdx+NEBO_PLUGIN_REPORT_EFFECTS],rax
 mov rax,[rsi+NEBO_PLUGIN_MAN_CAPS]
 mov [rdx+NEBO_PLUGIN_REPORT_CAPS],rax
 mov rax,[rsi+NEBO_PLUGIN_MAN_MEMORY]
 mov [rdx+NEBO_PLUGIN_REPORT_MEMORY],rax
 mov rax,[rsi+NEBO_PLUGIN_MAN_CALLS]
 mov [rdx+NEBO_PLUGIN_REPORT_CALLS],rax
 mov qword [r10+NEBO_PLUGIN_REQ_RESULT],NEBO_PLUGIN_REPORT_SIZE
 xor eax,eax
 ret
.corrupt: mov eax,NEBO_PLUGIN_STATUS_CORRUPT
 ret
.schema: mov eax,NEBO_PLUGIN_STATUS_SCHEMA
 ret
.unsigned: mov eax,NEBO_PLUGIN_STATUS_UNSIGNED
 ret
.hash_mismatch: mov eax,NEBO_PLUGIN_STATUS_HASH_MISMATCH
 ret
.abi_target: mov eax,NEBO_PLUGIN_STATUS_ABI_TARGET
 ret
.budget: mov eax,NEBO_PLUGIN_STATUS_BUDGET
 ret
.unknown: mov eax,NEBO_PLUGIN_STATUS_UNKNOWN_FIELD
 ret
.limit: mov eax,NEBO_PLUGIN_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_PLUGIN_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
