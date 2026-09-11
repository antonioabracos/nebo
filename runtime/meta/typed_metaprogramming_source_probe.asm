; G028 bounded typed metaprogramming runtime witnesses. All operations are pure,
; deterministic, allocation-free, caller-owned, and failure-atomic.
bits 64
default rel
%define NEBO_G028_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/meta/typed_metaprogramming_source_probe.inc"

global nebo_g028_source_probe
global nebo_g028_fragment_validate
global nebo_g028_fresh_name
global nebo_g028_capture_validate
global nebo_g028_reflect_summary
global nebo_g028_require_capability
global nebo_g028_derive_plan
global nebo_g028_compile_evaluate
global nebo_g028_compile_for_each
global nebo_g028_compile_assert
global nebo_g028_compile_resource
global nebo_g028_compile_environment
global nebo_g028_compile_cache_key
global nebo_g028_macro_expand
global nebo_g028_generated_origin

section .data align=16
g28_probe_fragment:
 dq 1,2,0x2801,7,96,0,0x280028
g28_probe_reflection:
 dq 3,5,2,48,8,0x7f
g28_probe_items: dq 3,5,7,11

section .bss align=16
g28_probe_out: resq 2

section .text
; fragment*, expected-kind, expected-owner, digest* -> status.
nebo_g028_fragment_validate:
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov rax,[rdi+G028_FRAGMENT_KIND]
 cmp rax,1
 jb .kind
 cmp rax,5
 ja .kind
 cmp rax,rsi
 jne .kind
 cmp qword [rdi+G028_FRAGMENT_ORIGIN],1
 jb .invalid
 cmp qword [rdi+G028_FRAGMENT_ORIGIN],3
 ja .invalid
 mov rax,[rdi+G028_FRAGMENT_OWNER]
 test rax,rax
 jz .invalid
 test rdx,rdx
 jz .owner_ready
 cmp rax,rdx
 jne .capture
.owner_ready:
 mov r8,[rdi+G028_FRAGMENT_NODES]
 test r8,r8
 jz .limit
 cmp r8,G028_MAX_NODES
 ja .limit
 mov r9,[rdi+G028_FRAGMENT_BYTES]
 test r9,r9
 jz .limit
 cmp r9,G028_MAX_BYTES
 ja .limit
 cmp qword [rdi+G028_FRAGMENT_SPAN],0
 je .invalid
 mov r10,[rdi+G028_FRAGMENT_EFFECTS]
 test r10,~0xff
 jnz .capability
 rol rax,11
 xor rax,r8
 rol rax,17
 xor rax,r9
 xor rax,[rdi+G028_FRAGMENT_SPAN]
 test rax,rax
 jnz .store
 mov eax,1
.store:
 mov [rcx],rax
 xor eax,eax
 ret
.invalid: mov eax,G028_STATUS_INVALID
 ret
.kind: mov eax,G028_STATUS_KIND
 ret
.capture: mov eax,G028_STATUS_CAPTURE
 ret
.capability: mov eax,G028_STATUS_CAPABILITY
 ret
.limit: mov eax,G028_STATUS_LIMIT
 ret

; seed, ordinal, output-name-id* -> status.
nebo_g028_fresh_name:
 test rdx,rdx
 jz .fresh_invalid
 test rdi,rdi
 jz .fresh_invalid
 cmp rsi,G028_MAX_NODES
 jae .fresh_limit
 mov rax,rdi
 rol rax,19
 xor rax,rsi
 mov r10,0x4e45424f47303238
 xor rax,r10
 test rax,rax
 jnz .fresh_store
 mov eax,1
.fresh_store:
 mov [rdx],rax
 xor eax,eax
 ret
.fresh_invalid: mov eax,G028_STATUS_INVALID
 ret
.fresh_limit: mov eax,G028_STATUS_LIMIT
 ret

; source owner, target owner, explicit-capture flag -> status.
nebo_g028_capture_validate:
 test rdi,rdi
 jz .capture_invalid
 test rsi,rsi
 jz .capture_invalid
 cmp rdi,rsi
 je .capture_ok
 cmp rdx,1
 jne .capture_denied
.capture_ok: xor eax,eax
 ret
.capture_invalid: mov eax,G028_STATUS_INVALID
 ret
.capture_denied: mov eax,G028_STATUS_CAPTURE
 ret

; reflection descriptor*, summary* -> status.
nebo_g028_reflect_summary:
 test rdi,rdi
 jz .reflect_invalid
 test rsi,rsi
 jz .reflect_invalid
 mov rax,[rdi+G028_REFLECT_FIELDS]
 cmp rax,G028_MAX_FIELDS
 ja .reflect_limit
 mov rcx,[rdi+G028_REFLECT_METHODS]
 cmp rcx,G028_MAX_FIELDS
 ja .reflect_limit
 mov rdx,[rdi+G028_REFLECT_VARIANTS]
 cmp rdx,G028_MAX_FIELDS
 ja .reflect_limit
 mov r8,[rdi+G028_REFLECT_SIZE]
 test r8,r8
 jz .reflect_invalid
 mov r9,[rdi+G028_REFLECT_ALIGN]
 test r9,r9
 jz .reflect_invalid
 mov r10,r9
 dec r10
 test r9,r10
 jnz .reflect_invalid
 xor rax,rcx
 rol rax,7
 xor rax,rdx
 rol rax,11
 xor rax,r8
 xor rax,r9
 xor rax,[rdi+G028_REFLECT_CAPABILITIES]
 test rax,rax
 jnz .reflect_store
 mov eax,1
.reflect_store: mov [rsi],rax
 xor eax,eax
 ret
.reflect_invalid: mov eax,G028_STATUS_INVALID
 ret
.reflect_limit: mov eax,G028_STATUS_LIMIT
 ret

; available capability mask, required single/multi mask -> status.
nebo_g028_require_capability:
 test rsi,rsi
 jz .require_invalid
 mov rax,rdi
 and rax,rsi
 cmp rax,rsi
 jne .require_denied
 xor eax,eax
 ret
.require_invalid: mov eax,G028_STATUS_INVALID
 ret
.require_denied: mov eax,G028_STATUS_CAPABILITY
 ret

; requested derive mask, field capability mask, plan* -> status.
nebo_g028_derive_plan:
 test rdx,rdx
 jz .derive_invalid
 test rdi,rdi
 jz .derive_invalid
 mov rax,rdi
 and rax,~G028_DERIVE_ALL
 jnz .derive_invalid
 mov rax,rsi
 and rax,rdi
 cmp rax,rdi
 jne .derive_capability
 mov [rdx],rdi
 xor eax,eax
 ret
.derive_invalid: mov eax,G028_STATUS_INVALID
 ret
.derive_capability: mov eax,G028_STATUS_CAPABILITY
 ret

; op (1 add, 2 sub, 3 multiply, 4 equal), lhs, rhs, budget, output*.
nebo_g028_compile_evaluate:
 test r8,r8
 jz .eval_invalid
 test rcx,rcx
 jz .eval_budget
 cmp rcx,1000000
 ja .eval_budget
 cmp rdi,1
 je .eval_add
 cmp rdi,2
 je .eval_sub
 cmp rdi,3
 je .eval_mul
 cmp rdi,4
 je .eval_equal
 jmp .eval_invalid
.eval_add: mov rax,rsi
 add rax,rdx
 jo .eval_limit
 jmp .eval_store
.eval_sub: mov rax,rsi
 sub rax,rdx
 jo .eval_limit
 jmp .eval_store
.eval_mul: mov rax,rsi
 imul rax,rdx
 jo .eval_limit
 jmp .eval_store
.eval_equal: xor eax,eax
 cmp rsi,rdx
 sete al
.eval_store: mov [r8],rax
 xor eax,eax
 ret
.eval_invalid: mov eax,G028_STATUS_INVALID
 ret
.eval_budget: mov eax,G028_STATUS_BUDGET
 ret
.eval_limit: mov eax,G028_STATUS_LIMIT
 ret

; items*, count, step budget, deterministic fold* -> status.
nebo_g028_compile_for_each:
 test rcx,rcx
 jz .foreach_invalid
 cmp rsi,G028_MAX_ITEMS
 ja .foreach_limit
 test rsi,rsi
 jz .foreach_empty
 test rdi,rdi
 jz .foreach_invalid
 cmp rdx,rsi
 jb .foreach_budget
 xor r8d,r8d
 xor r9d,r9d
.foreach_loop:
 cmp r8,rsi
 jae .foreach_store
 mov rax,[rdi+r8*8]
 rol r9,5
 xor r9,rax
 inc r8
 jmp .foreach_loop
.foreach_empty: xor r9d,r9d
.foreach_store: mov [rcx],r9
 xor eax,eax
 ret
.foreach_invalid: mov eax,G028_STATUS_INVALID
 ret
.foreach_limit: mov eax,G028_STATUS_LIMIT
 ret
.foreach_budget: mov eax,G028_STATUS_BUDGET
 ret

; condition, message-id -> status.
nebo_g028_compile_assert:
 test rsi,rsi
 jz .assert_invalid
 test rdi,rdi
 jz .assert_failed
 xor eax,eax
 ret
.assert_invalid: mov eax,G028_STATUS_INVALID
 ret
.assert_failed: mov eax,G028_STATUS_ASSERT
 ret

; path digest, byte size, media-type id, capability, descriptor digest*.
nebo_g028_compile_resource:
 test r8,r8
 jz .resource_invalid
 test rdi,rdi
 jz .resource_invalid
 test rsi,rsi
 jz .resource_invalid
 cmp rsi,G028_MAX_BYTES
 ja .resource_limit
 test rdx,rdx
 jz .resource_invalid
 cmp rcx,1
 jne .resource_capability
 mov rax,rdi
 rol rax,7
 xor rax,rsi
 rol rax,13
 xor rax,rdx
 xor rax,rcx
 mov [r8],rax
 xor eax,eax
 ret
.resource_invalid: mov eax,G028_STATUS_INVALID
 ret
.resource_limit: mov eax,G028_STATUS_LIMIT
 ret
.resource_capability: mov eax,G028_STATUS_CAPABILITY
 ret

; Explicit allowlisted target/toolchain ids -> deterministic descriptor.
nebo_g028_compile_environment:
 test rdx,rdx
 jz .environment_invalid
 cmp rdi,1
 jne .environment_capability
 cmp rsi,1
 jne .environment_capability
 mov rax,0x0001000100000028
 mov [rdx],rax
 xor eax,eax
 ret
.environment_invalid: mov eax,G028_STATUS_INVALID
 ret
.environment_capability: mov eax,G028_STATUS_CAPABILITY
 ret

; Explicit source, target, and policy digests -> stable nonzero cache key.
nebo_g028_compile_cache_key:
 mov rax,rdi
 xor rax,rsi
 rol rax,17
 xor rax,rdx
 rol rax,29
 test rax,rax
 jnz .cache_done
 mov eax,1
.cache_done: ret

; arity, depth, nodes, node budget, expansion digest* -> status.
nebo_g028_macro_expand:
 test r8,r8
 jz .macro_invalid
 cmp rdi,16
 ja .macro_limit
 test rsi,rsi
 jz .macro_invalid
 cmp rsi,G028_MAX_DEPTH
 ja .macro_limit
 test rdx,rdx
 jz .macro_invalid
 cmp rdx,rcx
 ja .macro_budget
 cmp rdx,G028_MAX_NODES
 ja .macro_limit
 mov rax,rdi
 rol rax,9
 xor rax,rsi
 rol rax,13
 xor rax,rdx
 mov r10,0x4d4143524f473238
 xor rax,r10
 mov [r8],rax
 xor eax,eax
 ret
.macro_invalid: mov eax,G028_STATUS_INVALID
 ret
.macro_limit: mov eax,G028_STATUS_LIMIT
 ret
.macro_budget: mov eax,G028_STATUS_BUDGET
 ret

; source span, expansion depth -> stable generated-origin token.
nebo_g028_generated_origin:
 test rdi,rdi
 jz .origin_invalid
 cmp rsi,G028_MAX_DEPTH
 ja .origin_invalid
 mov rax,rdi
 rol rax,23
 xor rax,rsi
 mov r10,0x4f524947494e3238
 xor rax,r10
 ret
.origin_invalid: xor eax,eax
 ret

; mode, seed -> bounded observable process result.
nebo_g028_source_probe:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 jb .probe_fail
 cmp ebx,6
 ja .probe_fail
 cmp r12d,G028_MIN_SEED
 jb .probe_fail
 cmp r12d,G028_MAX_SEED
 ja .probe_fail
 cmp ebx,1
 je .probe_s1
 cmp ebx,2
 je .probe_s2
 cmp ebx,3
 je .probe_s3
 cmp ebx,4
 je .probe_s4
 cmp ebx,5
 je .probe_s5
 ; S06 macro expansion and generated-origin provenance.
 mov edi,2
 mov esi,3
 mov edx,24
 mov ecx,64
 lea r8,[rel g28_probe_out]
 call nebo_g028_macro_expand
 test eax,eax
 jnz .probe_fail
 mov edi,r12d
 mov esi,3
 call nebo_g028_generated_origin
 test rax,rax
 jz .probe_fail
 jmp .probe_effect
.probe_s1:
 mov [rel g28_probe_fragment+G028_FRAGMENT_OWNER],r12
 lea rdi,[rel g28_probe_fragment]
 mov esi,1
 mov rdx,r12
 lea rcx,[rel g28_probe_out]
 call nebo_g028_fragment_validate
 test eax,eax
 jnz .probe_fail
 jmp .probe_effect
.probe_s2:
 mov edi,r12d
 mov esi,7
 lea rdx,[rel g28_probe_out]
 call nebo_g028_fresh_name
 test eax,eax
 jnz .probe_fail
 mov edi,r12d
 lea esi,[r12d+1]
 mov edx,1
 call nebo_g028_capture_validate
 test eax,eax
 jnz .probe_fail
 jmp .probe_effect
.probe_s3:
 lea rdi,[rel g28_probe_reflection]
 lea rsi,[rel g28_probe_out]
 call nebo_g028_reflect_summary
 test eax,eax
 jnz .probe_fail
 mov edi,0x7f
 mov esi,0x21
 call nebo_g028_require_capability
 test eax,eax
 jnz .probe_fail
 jmp .probe_effect
.probe_s4:
 mov edi,G028_DERIVE_ALL
 mov esi,G028_DERIVE_ALL
 lea rdx,[rel g28_probe_out]
 call nebo_g028_derive_plan
 test eax,eax
 jnz .probe_fail
 jmp .probe_effect
.probe_s5:
 mov edi,1
 mov esi,r12d
 mov edx,28
 mov ecx,4
 lea r8,[rel g28_probe_out]
 call nebo_g028_compile_evaluate
 test eax,eax
 jnz .probe_fail
 lea rdi,[rel g28_probe_items]
 mov esi,4
 mov edx,4
 lea rcx,[rel g28_probe_out+8]
 call nebo_g028_compile_for_each
 test eax,eax
 jnz .probe_fail
 mov edi,1
 mov esi,0x2805
 call nebo_g028_compile_assert
 test eax,eax
 jnz .probe_fail
 mov edi,r12d
 mov esi,128
 mov edx,1
 mov ecx,1
 lea r8,[rel g28_probe_out]
 call nebo_g028_compile_resource
 test eax,eax
 jnz .probe_fail
 mov edi,1
 mov esi,1
 lea rdx,[rel g28_probe_out+8]
 call nebo_g028_compile_environment
 test eax,eax
 jnz .probe_fail
 mov edi,r12d
 mov esi,1
 mov edx,0x28
 call nebo_g028_compile_cache_key
 test rax,rax
 jz .probe_fail
.probe_effect:
 mov eax,r12d
 imul ecx,ebx,17
 add eax,ecx
 and eax,255
 test eax,eax
 jnz .probe_done
 mov eax,1
 jmp .probe_done
.probe_fail: mov eax,70
.probe_done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
