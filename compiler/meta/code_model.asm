
; FILESYSTEM-PATHS-E-FORMATOS-F01 typed structural code-fragment and expansion-boundary contract.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/meta/code_model.inc"
section .text

NEBOC_ABI_FUNCTION nebo_meta_budget_validate
 test rdi,rdi
 jz .bad
 mov rax,[rdi+NEBO_META_BUDGET_DEPTH]
 test rax,rax
 jz .depth
 cmp rax,NEBO_META_MAX_DEPTH
 ja .depth
 mov rax,[rdi+NEBO_META_BUDGET_NODES]
 test rax,rax
 jz .nodes
 cmp rax,NEBO_META_MAX_NODES
 ja .nodes
 mov rax,[rdi+NEBO_META_BUDGET_BYTES]
 test rax,rax
 jz .bytes
 cmp rax,NEBO_META_MAX_BYTES
 ja .bytes
 mov rax,[rdi+NEBO_META_BUDGET_STEPS]
 test rax,rax
 jz .steps
 cmp rax,NEBO_META_MAX_STEPS
 ja .steps
 mov rax,[rdi+NEBO_META_BUDGET_MEMORY]
 test rax,rax
 jz .memory
 cmp rax,NEBO_META_MAX_MEMORY
 ja .memory
 xor eax,eax
 ret
.bad: mov eax,NEBO_META_STATUS_INVALID_ARGUMENT
 ret
.depth: mov eax,NEBO_META_STATUS_DEPTH_LIMIT
 ret
.nodes: mov eax,NEBO_META_STATUS_NODE_LIMIT
 ret
.bytes: mov eax,NEBO_META_STATUS_BYTE_LIMIT
 ret
.steps: mov eax,NEBO_META_STATUS_STEP_LIMIT
 ret
.memory: mov eax,NEBO_META_STATUS_MEMORY_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_meta_kind_compatible
 cmp rdi,NEBO_META_KIND_EXPRESSION
 jb .kind
 cmp rdi,NEBO_META_KIND_MAX
 ja .kind
 mov ecx,edi
 dec ecx
 mov rax,1
 shl rax,cl
 test rax,rsi
 jz .kind
 xor eax,eax
 ret
.kind: mov eax,NEBO_META_STATUS_BAD_KIND
 ret

NEBOC_ABI_FUNCTION nebo_meta_fragment_validate
 test rdi,rdi
 jz .bad
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 mov rax,NEBO_META_MAGIC
 cmp [rdi+NEBO_META_FRAGMENT_MAGIC],rax
 jne .magic
 cmp qword [rdi+NEBO_META_FRAGMENT_VERSION],NEBO_META_VERSION
 jne .version
 mov rcx,[rdi+NEBO_META_FRAGMENT_KIND]
 cmp rcx,NEBO_META_KIND_EXPRESSION
 jb .kind
 cmp rcx,NEBO_META_KIND_MAX
 ja .kind
 mov r8,[rdi+NEBO_META_FRAGMENT_ORIGIN]
 cmp r8,NEBO_META_ORIGIN_HUMAN
 jb .origin
 cmp r8,NEBO_META_ORIGIN_MAX
 ja .origin
 cmp qword [rdi+NEBO_META_FRAGMENT_SPAN_ID],0
 je .span
 mov r8,1
 dec ecx
 shl r8,cl
 test r8,[rsi+NEBO_META_CONTEXT_KIND_MASK]
 jz .kind
 mov r8,[rdi+NEBO_META_FRAGMENT_EFFECT_MASK]
 mov r9,[rsi+NEBO_META_CONTEXT_EFFECT_MASK]
 not r9
 test r8,r9
 jnz .effects
 mov r8,[rsi+NEBO_META_CONTEXT_OWNER_ID]
 test r8,r8
 jz .budget
 cmp r8,[rdi+NEBO_META_FRAGMENT_OWNER_ID]
 jne .owner
.budget:
 cmp qword [rdx+NEBO_META_BUDGET_DEPTH],0
 je .depth
 mov r8,[rdx+NEBO_META_BUDGET_DEPTH]
 cmp r8,NEBO_META_MAX_DEPTH
 ja .depth
 mov r8,[rdx+NEBO_META_BUDGET_NODES]
 test r8,r8
 jz .nodes
 cmp r8,NEBO_META_MAX_NODES
 ja .nodes
 cmp [rdi+NEBO_META_FRAGMENT_NODE_COUNT],r8
 ja .nodes
 mov r8,[rdx+NEBO_META_BUDGET_BYTES]
 test r8,r8
 jz .bytes
 cmp r8,NEBO_META_MAX_BYTES
 ja .bytes
 cmp [rdi+NEBO_META_FRAGMENT_BYTE_COUNT],r8
 ja .bytes
 mov r8,[rdx+NEBO_META_BUDGET_STEPS]
 test r8,r8
 jz .steps
 cmp r8,NEBO_META_MAX_STEPS
 ja .steps
 mov r8,[rdx+NEBO_META_BUDGET_MEMORY]
 test r8,r8
 jz .memory
 cmp r8,NEBO_META_MAX_MEMORY
 ja .memory
 xor eax,eax
 ret
.bad: mov eax,NEBO_META_STATUS_INVALID_ARGUMENT
 ret
.magic: mov eax,NEBO_META_STATUS_BAD_MAGIC
 ret
.version: mov eax,NEBO_META_STATUS_BAD_VERSION
 ret
.kind: mov eax,NEBO_META_STATUS_BAD_KIND
 ret
.origin: mov eax,NEBO_META_STATUS_BAD_ORIGIN
 ret
.span: mov eax,NEBO_META_STATUS_MISSING_SPAN
 ret
.nodes: mov eax,NEBO_META_STATUS_NODE_LIMIT
 ret
.bytes: mov eax,NEBO_META_STATUS_BYTE_LIMIT
 ret
.depth: mov eax,NEBO_META_STATUS_DEPTH_LIMIT
 ret
.steps: mov eax,NEBO_META_STATUS_STEP_LIMIT
 ret
.memory: mov eax,NEBO_META_STATUS_MEMORY_LIMIT
 ret
.effects: mov eax,NEBO_META_STATUS_EFFECT_DENIED
 ret
.owner: mov eax,NEBO_META_STATUS_OWNER_MISMATCH
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
