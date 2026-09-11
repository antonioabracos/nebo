; Typed composition adapter over canonical Option/Result tag/payload owners.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/scalars/option_result_runtime.inc"
extern neboc_runtime_store_zero_payload
extern neboc_runtime_store_integer
extern neboc_runtime_tag_test
extern neboc_runtime_unwrap_integer
extern neboc_runtime_validate_option
extern neboc_runtime_validate_result
extern nebo_collection_public_sret
extern nebo_runtime_trap_arithmetic_domain

section .text
; Operation, input value/receiver, exact private tagged TypeId, fallback,
; caller-owned 4272-byte destination. Every payload is typed before emission.
NEBOC_ABI_FUNCTION nebo_tagged_public
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov ebx,edi
 mov r12,rsi
 mov r13d,edx
 mov r14,rcx
 mov r15,r8
 cmp ebx,4
 jbe .constructor
 mov rdi,r12
 cmp r13d,35016
 jae .validate_result
 call neboc_runtime_validate_option
 mov esi,NEBO_RUNTIME_OPTION_SOME
 jmp .validated
.validate_result:
 call neboc_runtime_validate_result
 mov esi,NEBO_RUNTIME_RESULT_OK
.validated:
 test eax,eax
 jz .trap
 mov rdi,r12
 cmp ebx,5
 je .predicate
 cmp ebx,6
 je .not_predicate
 cmp ebx,9
 je .fallback
 cmp ebx,8
 jne .get
 xor esi,1
.get:
 cmp byte [r12],sil
 jne .trap
 mov rax,[r12+8]
 cmp ebx,8
 je .done
 jmp .owned_observation
 jmp .done
.predicate:
 call neboc_runtime_tag_test
 jmp .done
.not_predicate:
 call neboc_runtime_tag_test
 xor eax,1
 jmp .done
.fallback:
 mov rdx,r14
 call neboc_runtime_unwrap_integer
.owned_observation:
 mov edx,r13d
 sub edx,35000
 and edx,15
 cmp edx,5
 je .text_observation
 cmp edx,6
 jb .done
 ; A collection observation is an owned trivial-element snapshot. Chained
 ; temporary tagged values may be reclaimed as soon as this call completes.
 mov rsi,rax
 mov rdi,r15
 add edx,26
 call nebo_collection_public_sret
 test eax,eax
 jnz .trap
 mov rax,rdx
 jmp .done
.text_observation:
 mov rsi,rax
 mov rdi,r15
 call nebo_tagged_text_copy
 jmp .done
.constructor:
 cmp ebx,2
 je .none
 mov edx,r13d
 sub edx,35000
 and edx,15
 cmp ebx,4
 je .scalar
 cmp edx,5
 je .text_constructor
 cmp edx,6
 jb .scalar
 cmp ebx,4
 je .scalar
 add edx,26 ; native List/Dict/Set layout kind 32/33/34
 lea rdi,[r15+16]
 mov rsi,r12
 call nebo_collection_public_sret
 test eax,eax
 jnz .trap
 mov r12,rdx
 jmp .scalar
.text_constructor:
 lea rdi,[r15+16]
 mov rsi,r12
 call nebo_tagged_text_copy
 mov r12,rax
.scalar:
 xor esi,esi
 cmp ebx,3
 je .store
 mov esi,1
.store:
 mov rdi,r15
 mov rdx,r12
 call neboc_runtime_store_integer
 mov rax,r15
 jmp .done
.none:
 mov rdi,r15
 xor esi,esi
 call neboc_runtime_store_zero_payload
 mov rax,r15
 jmp .done
.trap:
 jmp nebo_runtime_trap_arithmetic_domain
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Immutable public Text relocation, independent of the source frame lifetime.
global nebo_tagged_text_copy
nebo_tagged_text_copy:
 mov r8,rdi
 cmp word [rsi+20],1
 jne .bad
 mov rcx,[rsi+8]
 cmp rcx,4096
 ja .bad
 mov rdx,rcx
 mov rsi,[rsi]
 lea rdi,[r8+32]
 mov [r8],rdi
 rep movsb
 mov [r8+8],rdx
 mov qword [r8+16],0
 mov word [r8+20],1
 mov qword [r8+24],0
 mov rax,r8
 ret
.bad:
 jmp nebo_runtime_trap_arithmetic_domain

; Re-materialize a tagged return using its actual variant and payload owner.
NEBOC_ABI_FUNCTION nebo_tagged_public_sret
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov [rsp],edx
 mov rdi,rsi
 cmp edx,35016
 jae .result
 call neboc_runtime_validate_option
 test eax,eax
 jz .bad
 mov edi,2
 cmp byte [r12],0
 je .construct
 mov edi,1
 jmp .construct
.result:
 call neboc_runtime_validate_result
 test eax,eax
 jz .bad
 mov edi,3
 cmp byte [r12],0
 je .construct
 mov edi,4
.construct:
 mov rsi,[r12+8]
 mov edx,[rsp]
 xor ecx,ecx
 mov r8,rbx
 call nebo_tagged_public
 mov rdx,rax
 xor eax,eax
 jmp .done
.bad:
 mov eax,1
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
