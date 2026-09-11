bits 64
default rel
%include "runtime/plugins/plugin_manifest.inc"
extern nebo_plugin_manifest_verify
section .bss
manifest resb NEBO_PLUGIN_MANIFEST_SIZE
allowlist resb 64
report resb NEBO_PLUGIN_REPORT_SIZE
req resb NEBO_PLUGIN_REQ_SIZE
section .text
global _start
_start:
 lea rdi,[manifest]
 mov ecx,NEBO_PLUGIN_MANIFEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_PLUGIN_MAGIC
 mov [manifest+NEBO_PLUGIN_MAN_MAGIC],rax
 mov qword [manifest+NEBO_PLUGIN_MAN_SCHEMA],1
 mov qword [manifest+NEBO_PLUGIN_MAN_SIZE],NEBO_PLUGIN_MANIFEST_SIZE
 mov qword [manifest+NEBO_PLUGIN_MAN_IDENTITY],0x2602
 mov rax,NEBO_PLUGIN_TARGET
 mov [manifest+NEBO_PLUGIN_MAN_TARGET],rax
 mov qword [manifest+NEBO_PLUGIN_MAN_EXPORTS],4
 mov qword [manifest+NEBO_PLUGIN_MAN_EFFECTS],3
 mov qword [manifest+NEBO_PLUGIN_MAN_CAPS],1
 mov qword [manifest+NEBO_PLUGIN_MAN_MEMORY],0x100000
 mov qword [manifest+NEBO_PLUGIN_MAN_CALLS],128
 mov qword [manifest+NEBO_PLUGIN_MAN_LIFECYCLE],1
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH0],0x11
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH1],0x22
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH2],0x33
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH3],0x44
 mov qword [allowlist],0x11
 mov qword [allowlist+8],0x22
 mov qword [allowlist+16],0x33
 mov qword [allowlist+24],0x44
 lea rax,[manifest]
 mov [req+NEBO_PLUGIN_REQ_MANIFEST],rax
 lea rax,[allowlist]
 mov [req+NEBO_PLUGIN_REQ_ALLOWLIST],rax
 mov qword [req+NEBO_PLUGIN_REQ_ALLOWLIST_COUNT],1
 lea rax,[report]
 mov [req+NEBO_PLUGIN_REQ_REPORT],rax
 mov qword [req+NEBO_PLUGIN_REQ_CAPACITY],NEBO_PLUGIN_REPORT_SIZE
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 test eax,eax
 jnz fail
 cmp qword [req+NEBO_PLUGIN_REQ_RESULT],NEBO_PLUGIN_REPORT_SIZE
 jne fail
 cmp qword [report+NEBO_PLUGIN_REPORT_IDENTITY],0x2602
 jne fail
 mov qword [report],0x55
 inc qword [allowlist]
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 cmp eax,NEBO_PLUGIN_STATUS_HASH_MISMATCH
 jne fail
 cmp qword [report],0x55
 jne fail
 dec qword [allowlist]
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH0],0
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH1],0
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH2],0
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH3],0
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 cmp eax,NEBO_PLUGIN_STATUS_UNSIGNED
 jne fail
 mov qword [manifest+NEBO_PLUGIN_MAN_HASH0],0x11
 mov qword [manifest+NEBO_PLUGIN_MAN_SCHEMA],2
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 cmp eax,NEBO_PLUGIN_STATUS_SCHEMA
 jne fail
 mov qword [manifest+NEBO_PLUGIN_MAN_SCHEMA],1
 mov qword [manifest+NEBO_PLUGIN_MAN_ABI],1
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 cmp eax,NEBO_PLUGIN_STATUS_ABI_TARGET
 jne fail
 mov qword [manifest+NEBO_PLUGIN_MAN_ABI],0
 mov qword [manifest+NEBO_PLUGIN_MAN_MEMORY],0
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 cmp eax,NEBO_PLUGIN_STATUS_BUDGET
 jne fail
 mov qword [manifest+NEBO_PLUGIN_MAN_MEMORY],0x100000
 mov qword [manifest+NEBO_PLUGIN_MAN_EFFECTS],0x4000
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 cmp eax,NEBO_PLUGIN_STATUS_UNKNOWN_FIELD
 jne fail
 mov qword [manifest+NEBO_PLUGIN_MAN_EFFECTS],3
 mov qword [manifest+NEBO_PLUGIN_MAN_EXPORTS],65
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 cmp eax,NEBO_PLUGIN_STATUS_LIMIT
 jne fail
 mov qword [manifest+NEBO_PLUGIN_MAN_EXPORTS],4
 mov qword [manifest+NEBO_PLUGIN_MAN_MAGIC],0
 lea rdi,[req]
 call nebo_plugin_manifest_verify
 cmp eax,NEBO_PLUGIN_STATUS_CORRUPT
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
