; G143 AnnotationRegistry: stable annotation identity, version and allowed
; declaration targets.  Unknown names, versions and targets fail closed.
bits 64
default rel
%define NEBO_ANNOTATION_PLAN_IMPLEMENTATION 1
%include "compiler/tokens/operator_registry.inc"
%include "compiler/parser/meta/annotation_plan.inc"

section .rodata
annotation_stable:      db 'stable'
annotation_stable_len equ $-annotation_stable
annotation_module_info: db 'moduleInfo'
annotation_module_info_len equ $-annotation_module_info
annotation_typed:       db 'typed'
annotation_typed_len equ $-annotation_typed
annotation_operator:    db 'operatorInfo'
annotation_operator_len equ $-annotation_operator
annotation_const_meta:  db 'constMeta'
annotation_const_meta_len equ $-annotation_const_meta
annotation_runtime:     db 'runtimeInfo'
annotation_runtime_len equ $-annotation_runtime
annotation_derive:      db 'deriveInfo'
annotation_derive_len equ $-annotation_derive
annotation_audit:       db 'audit'
annotation_audit_len equ $-annotation_audit

; name, bytes, identity, allowed-target mask, flags
align 8
annotation_registry:
 dq annotation_stable,annotation_stable_len,1,NEBO_ANNOTATION_TARGET_ALL,NEBO_ANNOTATION_FLAG_COMPILE_TIME|NEBO_ANNOTATION_FLAG_TOOLING
 dq annotation_module_info,annotation_module_info_len,2,NEBO_ANNOTATION_TARGET_MODULE,NEBO_ANNOTATION_FLAG_COMPILE_TIME|NEBO_ANNOTATION_FLAG_TOOLING
 dq annotation_typed,annotation_typed_len,3,NEBO_ANNOTATION_TARGET_DECLARATION|NEBO_ANNOTATION_TARGET_FUNCTION,NEBO_ANNOTATION_FLAG_COMPILE_TIME
 dq annotation_operator,annotation_operator_len,4,NEBO_ANNOTATION_TARGET_OPERATOR,NEBO_ANNOTATION_FLAG_COMPILE_TIME|NEBO_ANNOTATION_FLAG_TOOLING
 dq annotation_const_meta,annotation_const_meta_len,5,NEBO_ANNOTATION_TARGET_TYPE|NEBO_ANNOTATION_TARGET_FIELD,NEBO_ANNOTATION_FLAG_COMPILE_TIME|NEBO_ANNOTATION_FLAG_TOOLING
 dq annotation_runtime,annotation_runtime_len,6,NEBO_ANNOTATION_TARGET_MODULE|NEBO_ANNOTATION_TARGET_FUNCTION,NEBO_ANNOTATION_FLAG_COMPILE_TIME|NEBO_ANNOTATION_FLAG_RUNTIME|NEBO_ANNOTATION_FLAG_PRIVATE
 dq annotation_derive,annotation_derive_len,7,NEBO_ANNOTATION_TARGET_TYPE,NEBO_ANNOTATION_FLAG_COMPILE_TIME|NEBO_ANNOTATION_FLAG_TOOLING|NEBO_ANNOTATION_FLAG_DERIVE
 dq annotation_audit,annotation_audit_len,8,NEBO_ANNOTATION_TARGET_ALL,NEBO_ANNOTATION_FLAG_COMPILE_TIME|NEBO_ANNOTATION_FLAG_RUNTIME|NEBO_ANNOTATION_FLAG_PRIVATE|NEBO_ANNOTATION_FLAG_TOOLING
annotation_registry_count equ 8
annotation_registry_row_qwords equ 5

section .text
global nebo_annotation_registry_lookup

; RDI name bytes, RSI length, RDX target bit, RCX requested version,
; R8 caller-owned plan. EAX=0 success; 1 unknown, 2 version, 3 target,
; 4 invalid request. Failure leaves the output untouched.
nebo_annotation_registry_lookup:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 cmp r13,64
 ja .invalid
 test r8,r8
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,r14
 dec rax
 test rax,r14
 jnz .invalid
 test r14,NEBO_ANNOTATION_TARGET_ALL
 jz .invalid
 xor ebx,ebx
.row:
 cmp rbx,annotation_registry_count
 jae .unknown
 mov rax,rbx
 imul rax,annotation_registry_row_qwords*8
 lea r9,[rel annotation_registry]
 add r9,rax
 cmp r13,[r9+8]
 jne .next
 mov r10,[r9]
 xor ecx,ecx
.bytes:
 cmp rcx,r13
 jae .matched
 mov al,[r12+rcx]
 cmp al,[r10+rcx]
 jne .next
 inc rcx
 jmp .bytes
.matched:
 cmp r15,1
 jne .version
 mov rax,[r9+24]
 test rax,r14
 jz .target
 mov rdi,[rsp]
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_080
 mov [rdi+NEBO_ANNOTATION_PLAN_REGISTRY_ID_OFFSET],rax
 mov rax,[r9+16]
 mov [rdi+NEBO_ANNOTATION_PLAN_KIND_OFFSET],rax
 mov [rdi+NEBO_ANNOTATION_PLAN_VERSION_OFFSET],r15
 mov [rdi+NEBO_ANNOTATION_PLAN_TARGET_OFFSET],r14
 mov rax,[r9+24]
 mov [rdi+NEBO_ANNOTATION_PLAN_ALLOWED_TARGETS_OFFSET],rax
 mov rax,[r9+32]
 mov [rdi+NEBO_ANNOTATION_PLAN_FLAGS_OFFSET],rax
 xor eax,eax
 jmp .done
.next:
 inc rbx
 jmp .row
.unknown:
 mov eax,1
 jmp .done
.version:
 mov eax,2
 jmp .done
.target:
 mov eax,3
 jmp .done
.invalid:
 mov eax,4
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
