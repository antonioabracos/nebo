; TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-F04 borrowed Dict keys/values/entries views.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_validate
%define VIEW_MAGIC 0x5246385649455734

section .text
; init(view*, dict*, kind)
NEBOC_ABI_FUNCTION neboc_dict_view_init
 test rdi,rdi
 jz .init_invalid
 test rdi,7
 jnz .init_invalid
 cmp rdx,NEBO_DICT_VIEW_KEYS
 jb .init_invalid
 cmp rdx,NEBO_DICT_VIEW_ENTRIES
 ja .init_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,rsi
 call neboc_dict_validate
 test eax,eax
 jnz .init_done
 cmp dword [r13+NEBO_DICT_BORROW_COUNT],0xffffffff
 je .init_limit
 mov rdi,r12
 mov ecx,NEBO_DICT_ITERATOR_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_DICT_VIEW_OWNER],r13
 mov rax,[r13+NEBO_DICT_GENERATION]
 mov [r12+NEBO_DICT_VIEW_GENERATION],rax
 mov [r12+NEBO_DICT_VIEW_KIND],r14
 mov rdx,[r13+NEBO_DICT_LENGTH]
 mov [r12+NEBO_DICT_VIEW_REMAINING],rdx
 mov rcx,VIEW_MAGIC
 xor rax,r13
 xor rax,rcx
 mov [r12+NEBO_DICT_VIEW_TOKEN],rax
 inc dword [r13+NEBO_DICT_BORROW_COUNT]
 xor eax,eax
 jmp .init_done
.init_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.init_done:
 pop r14
 pop r13
 pop r12
 ret
.init_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; next(view*, key_out*, value_out*, found*)
NEBOC_ABI_FUNCTION neboc_dict_view_next
 test rdi,rdi
 jz .next_invalid
 test rsi,rsi
 jz .next_invalid
 test rdx,rdx
 jz .next_invalid
 test rcx,rcx
 jz .next_invalid
 mov qword [rsi],0
 mov qword [rdx],0
 mov qword [rcx],0
 cmp qword [rdi+NEBO_DICT_VIEW_RELEASED],0
 jne .next_stale
 mov r8,[rdi+NEBO_DICT_VIEW_OWNER]
 test r8,r8
 jz .next_stale
 mov r9,[rdi+NEBO_DICT_VIEW_GENERATION]
 cmp r9,[r8+NEBO_DICT_GENERATION]
 jne .next_stale
 mov r10,VIEW_MAGIC
 xor r9,r8
 xor r9,r10
 cmp r9,[rdi+NEBO_DICT_VIEW_TOKEN]
 jne .next_stale
 cmp qword [rdi+NEBO_DICT_VIEW_REMAINING],0
 je .next_ok
 mov r9,[rdi+NEBO_DICT_VIEW_INDEX]
.scan:
 cmp r9,[r8+NEBO_DICT_CAPACITY]
 jae .next_stale
 mov r10,r9
 shl r10,5
 add r10,[r8+NEBO_DICT_STORAGE]
 inc r9
 mov [rdi+NEBO_DICT_VIEW_INDEX],r9
 cmp qword [r10+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 jne .scan
 mov r11,[rdi+NEBO_DICT_VIEW_KIND]
 cmp r11,NEBO_DICT_VIEW_VALUES
 je .value_only
 mov rax,[r10+NEBO_DICT_SLOT_KEY]
 mov [rsi],rax
.value_only:
 cmp r11,NEBO_DICT_VIEW_KEYS
 je .publish
 mov rax,[r10+NEBO_DICT_SLOT_VALUE]
 mov [rdx],rax
.publish:
 mov qword [rcx],1
 dec qword [rdi+NEBO_DICT_VIEW_REMAINING]
.next_ok:
 xor eax,eax
 ret
.next_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.next_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_dict_view_release
 test rdi,rdi
 jz .release_invalid
 cmp qword [rdi+NEBO_DICT_VIEW_RELEASED],0
 jne .release_ok
 mov rax,[rdi+NEBO_DICT_VIEW_OWNER]
 test rax,rax
 jz .release_mark
 cmp dword [rax+NEBO_DICT_BORROW_COUNT],0
 je .release_mark
 dec dword [rax+NEBO_DICT_BORROW_COUNT]
.release_mark:
 mov qword [rdi+NEBO_DICT_VIEW_OWNER],0
 mov qword [rdi+NEBO_DICT_VIEW_TOKEN],0
 mov qword [rdi+NEBO_DICT_VIEW_RELEASED],1
.release_ok:
 xor eax,eax
 ret
.release_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
