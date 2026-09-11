; G143 deterministic lowering for typed compile-time/runtime metadata.  It
; consumes only the validated caller-owned plan and publishes no partial state.
bits 64
default rel
%define NEBO_ANNOTATION_PLAN_IMPLEMENTATION 1
%include "compiler/parser/meta/annotation_plan.inc"

section .text
global nebo_annotation_metadata_lower

; RDI AnnotationPlan*. EAX=0 success, non-zero fail-closed.  Digests are
; bounded to 1..251 so they are directly observable through the native exit
; effect while remaining derived from source values.
nebo_annotation_metadata_lower:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_ANNOTATION_PLAN_VERSION_OFFSET],1
 jne .invalid
 cmp qword [rdi+NEBO_ANNOTATION_PLAN_LEVEL_OFFSET],63
 ja .invalid
 cmp qword [rdi+NEBO_ANNOTATION_PLAN_ENABLED_OFFSET],1
 ja .invalid
 cmp qword [rdi+NEBO_ANNOTATION_PLAN_ARGUMENT_COUNT_OFFSET],4
 ja .invalid
 cmp qword [rdi+NEBO_ANNOTATION_PLAN_PRIVACY_OFFSET],3
 ja .invalid
 cmp qword [rdi+NEBO_ANNOTATION_PLAN_SEED_OFFSET],1
 jb .invalid
 cmp qword [rdi+NEBO_ANNOTATION_PLAN_SEED_OFFSET],255
 ja .invalid
 mov rax,[rdi+NEBO_ANNOTATION_PLAN_FLAGS_OFFSET]
 test rax,NEBO_ANNOTATION_FLAG_RUNTIME
 jnz .privacy_ok
 cmp qword [rdi+NEBO_ANNOTATION_PLAN_PRIVACY_OFFSET],0
 jne .invalid
.privacy_ok:
 ; Stable source provenance.
 mov rax,[rdi+NEBO_ANNOTATION_PLAN_KIND_OFFSET]
 imul rax,17
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_TARGET_OFFSET]
 imul rcx,13
 add rax,rcx
 add rax,[rdi+NEBO_ANNOTATION_PLAN_SEED_OFFSET]
 add rax,[rdi+NEBO_ANNOTATION_PLAN_LABEL_HASH_OFFSET]
 add rax,[rdi+NEBO_ANNOTATION_PLAN_TARGET_NAME_HASH_OFFSET]
 xor edx,edx
 mov ecx,251
 div rcx
 inc rdx
 mov [rdi+NEBO_ANNOTATION_PLAN_PROVENANCE_OFFSET],rdx
 ; Compile-time digest includes every typed/defaulted argument.
 mov rax,80
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_KIND_OFFSET]
 imul rcx,3
 add rax,rcx
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_TARGET_OFFSET]
 imul rcx,5
 add rax,rcx
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_LEVEL_OFFSET]
 imul rcx,11
 add rax,rcx
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_ENABLED_OFFSET]
 imul rcx,13
 add rax,rcx
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_ARGUMENT_COUNT_OFFSET]
 imul rcx,17
 add rax,rcx
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_SEED_OFFSET]
 imul rcx,19
 add rax,rcx
 add rax,[rdi+NEBO_ANNOTATION_PLAN_LABEL_HASH_OFFSET]
 xor edx,edx
 mov ecx,251
 div rcx
 inc rdx
 mov [rdi+NEBO_ANNOTATION_PLAN_COMPILE_DIGEST_OFFSET],rdx
 ; Runtime metadata exists only for annotations that explicitly declare it.
 xor r8d,r8d
 mov rax,[rdi+NEBO_ANNOTATION_PLAN_FLAGS_OFFSET]
 test rax,NEBO_ANNOTATION_FLAG_RUNTIME
 jz .runtime_done
 mov rax,rdx
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_PRIVACY_OFFSET]
 imul rcx,29
 add rax,rcx
 mov rcx,[rdi+NEBO_ANNOTATION_PLAN_SEED_OFFSET]
 imul rcx,7
 add rax,rcx
 xor edx,edx
 mov ecx,251
 div rcx
 lea r8,[rdx+1]
.runtime_done:
 mov [rdi+NEBO_ANNOTATION_PLAN_RUNTIME_DIGEST_OFFSET],r8
 ; Tooling and reflection are metadata projections, never host evaluation.
 mov rax,[rdi+NEBO_ANNOTATION_PLAN_KIND_OFFSET]
 imul rax,10
 add rax,[rdi+NEBO_ANNOTATION_PLAN_ARGUMENT_COUNT_OFFSET]
 mov [rdi+NEBO_ANNOTATION_PLAN_TOOLING_CODE_OFFSET],rax
 mov rax,[rdi+NEBO_ANNOTATION_PLAN_FLAGS_OFFSET]
 test rax,NEBO_ANNOTATION_FLAG_PRIVATE
 jz .public_reflection
 mov qword [rdi+NEBO_ANNOTATION_PLAN_REFLECTION_CODE_OFFSET],0
 jmp .checksum
.public_reflection:
 mov rax,[rdi+NEBO_ANNOTATION_PLAN_KIND_OFFSET]
 shl rax,4
 add rax,[rdi+NEBO_ANNOTATION_PLAN_TARGET_OFFSET]
 mov [rdi+NEBO_ANNOTATION_PLAN_REFLECTION_CODE_OFFSET],rax
.checksum:
 mov rax,[rdi+NEBO_ANNOTATION_PLAN_PROVENANCE_OFFSET]
 add rax,[rdi+NEBO_ANNOTATION_PLAN_COMPILE_DIGEST_OFFSET]
 add rax,[rdi+NEBO_ANNOTATION_PLAN_RUNTIME_DIGEST_OFFSET]
 add rax,[rdi+NEBO_ANNOTATION_PLAN_TOOLING_CODE_OFFSET]
 add rax,[rdi+NEBO_ANNOTATION_PLAN_REFLECTION_CODE_OFFSET]
 xor edx,edx
 mov ecx,251
 div rcx
 inc rdx
 mov [rdi+NEBO_ANNOTATION_PLAN_CHECKSUM_OFFSET],rdx
 xor eax,eax
 ret
.invalid:
 mov eax,1
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
