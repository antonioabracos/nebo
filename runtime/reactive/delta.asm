; MEDIA-IMAGEM-AUDIO-E-VIDEO-F03 bounded reactive list deltas and exact inverses.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reactive/delta.inc"
section .text
NEBOC_ABI_FUNCTION nebo_list_init
 test rdi,rdi
 jz .invalid_init
 test rsi,rsi
 jz .invalid_init
 cmp rdx,NEBO_REACTIVE_LIST_MAX_ITEMS
 ja .limit_init
 cmp rcx,rdx
 ja .limit_init
 mov [rdi+NEBO_LIST_VALUES],rsi
 mov [rdi+NEBO_LIST_CAPACITY],rdx
 mov [rdi+NEBO_LIST_COUNT],rcx
 mov qword [rdi+NEBO_LIST_VERSION],1
 xor eax,eax
 ret
.invalid_init: mov eax,NEBO_DELTA_STATUS_INVALID
 ret
.limit_init: mov eax,NEBO_DELTA_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_list_patch
 ; list, delta
 test rdi,rdi
 jz .invalid_patch
 test rsi,rsi
 jz .invalid_patch
 mov r8,[rdi+NEBO_LIST_VALUES]
 mov rcx,[rdi+NEBO_LIST_COUNT]
 mov rax,[rsi+NEBO_DELTA_KIND]
 cmp rax,NEBO_DELTA_INSERT
 je .insert
 cmp rax,NEBO_DELTA_REMOVE
 je .remove
 cmp rax,NEBO_DELTA_UPDATE
 je .update
 cmp rax,NEBO_DELTA_MOVE
 je .move
 jmp .invalid_patch
.insert:
 cmp rcx,[rdi+NEBO_LIST_CAPACITY]
 jae .limit_patch
 mov rdx,[rsi+NEBO_DELTA_INDEX]
 cmp rdx,rcx
 ja .bounds_patch
 mov rax,rcx
.shift_right:
 cmp rax,rdx
 jbe .insert_store
 mov r9,[r8+rax*8-8]
 mov [r8+rax*8],r9
 dec rax
 jmp .shift_right
.insert_store:
 mov rax,[rsi+NEBO_DELTA_NEW_VALUE]
 mov [r8+rdx*8],rax
 inc rcx
 jmp .commit_count
.remove:
 mov rdx,[rsi+NEBO_DELTA_INDEX]
 cmp rdx,rcx
 jae .bounds_patch
 mov rax,[r8+rdx*8]
 cmp rax,[rsi+NEBO_DELTA_OLD_VALUE]
 jne .stale_patch
 mov rax,rdx
.shift_left:
 inc rax
 cmp rax,rcx
 jae .remove_done
 mov r9,[r8+rax*8]
 mov [r8+rax*8-8],r9
 jmp .shift_left
.remove_done: dec rcx
 jmp .commit_count
.update:
 mov rdx,[rsi+NEBO_DELTA_INDEX]
 cmp rdx,rcx
 jae .bounds_patch
 mov rax,[r8+rdx*8]
 cmp rax,[rsi+NEBO_DELTA_OLD_VALUE]
 jne .stale_patch
 mov rax,[rsi+NEBO_DELTA_NEW_VALUE]
 mov [r8+rdx*8],rax
 jmp .commit_version
.move:
 mov rdx,[rsi+NEBO_DELTA_INDEX]
 mov r9,[rsi+NEBO_DELTA_TO_INDEX]
 cmp rdx,rcx
 jae .bounds_patch
 cmp r9,rcx
 jae .bounds_patch
 mov rax,[r8+rdx*8]
 cmp rax,[rsi+NEBO_DELTA_OLD_VALUE]
 jne .stale_patch
 cmp rdx,r9
 je .commit_version
 jb .move_left
.move_right:
 mov r10,[r8+rdx*8-8]
 mov [r8+rdx*8],r10
 dec rdx
 cmp rdx,r9
 ja .move_right
 mov [r8+r9*8],rax
 jmp .commit_version
.move_left:
 mov r10,[r8+rdx*8+8]
 mov [r8+rdx*8],r10
 inc rdx
 cmp rdx,r9
 jb .move_left
 mov [r8+r9*8],rax
 jmp .commit_version
.commit_count: mov [rdi+NEBO_LIST_COUNT],rcx
.commit_version: inc qword [rdi+NEBO_LIST_VERSION]
 xor eax,eax
 ret
.invalid_patch: mov eax,NEBO_DELTA_STATUS_INVALID
 ret
.limit_patch: mov eax,NEBO_DELTA_STATUS_LIMIT
 ret
.bounds_patch: mov eax,NEBO_DELTA_STATUS_BOUNDS
 ret
.stale_patch: mov eax,NEBO_DELTA_STATUS_STALE
 ret

NEBOC_ABI_FUNCTION nebo_delta_invert
 test rsi,rsi
 jz .invalid_invert
 mov qword [rsi],0
 mov qword [rsi+8],0
 mov qword [rsi+16],0
 mov qword [rsi+24],0
 mov qword [rsi+32],0
 test rdi,rdi
 jz .invalid_invert
 mov rax,[rdi+NEBO_DELTA_KIND]
 cmp rax,NEBO_DELTA_INSERT
 je .to_remove
 cmp rax,NEBO_DELTA_REMOVE
 je .to_insert
 cmp rax,NEBO_DELTA_UPDATE
 je .same_kind
 cmp rax,NEBO_DELTA_MOVE
 je .invert_move
 jmp .invalid_invert
.to_remove: mov qword [rsi+NEBO_DELTA_KIND],NEBO_DELTA_REMOVE
 jmp .copy_swap
.to_insert: mov qword [rsi+NEBO_DELTA_KIND],NEBO_DELTA_INSERT
 jmp .copy_swap
.same_kind: mov [rsi+NEBO_DELTA_KIND],rax
.copy_swap:
 mov rax,[rdi+NEBO_DELTA_INDEX]
 mov [rsi+NEBO_DELTA_INDEX],rax
 mov rax,[rdi+NEBO_DELTA_TO_INDEX]
 mov [rsi+NEBO_DELTA_TO_INDEX],rax
 mov rax,[rdi+NEBO_DELTA_NEW_VALUE]
 mov [rsi+NEBO_DELTA_OLD_VALUE],rax
 mov rax,[rdi+NEBO_DELTA_OLD_VALUE]
 mov [rsi+NEBO_DELTA_NEW_VALUE],rax
 xor eax,eax
 ret
.invert_move:
 mov [rsi+NEBO_DELTA_KIND],rax
 mov rax,[rdi+NEBO_DELTA_TO_INDEX]
 mov [rsi+NEBO_DELTA_INDEX],rax
 mov rax,[rdi+NEBO_DELTA_INDEX]
 mov [rsi+NEBO_DELTA_TO_INDEX],rax
 mov rax,[rdi+NEBO_DELTA_OLD_VALUE]
 mov [rsi+NEBO_DELTA_OLD_VALUE],rax
 mov [rsi+NEBO_DELTA_NEW_VALUE],rax
 xor eax,eax
 ret
.invalid_invert: mov eax,NEBO_DELTA_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
