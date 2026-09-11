; Internal bounded title/icon API test plus real practical-runtime live harness.
bits 64
default rel

%include "runtime/console/live/live_console.inc"

extern nebo_runtime_live_console_set_title
extern nebo_runtime_live_console_set_icon
extern nebo_runtime_live_console_metadata_snapshot
extern nebo_runtime_console_publish_text
extern nebo_runtime_start

global _start

%define SYS_EXIT 60

section .rodata align=8
title_first: db "FIRST"
title_first_len equ $-title_first
title_final: db "NEBO TYPES TEST"
title_final_len equ $-title_final
default_title: db "NEBO CONSOLE"
default_title_len equ $-default_title
test_text: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ",10
 db "abcdefghijklmnopqrstuvwxyz",10
 db "0123456789 true false",10
 db "! ? . , : ; + - * / ( ) [ ] { }"
test_text_len equ $-test_text
align 8
test_text_descriptor:
 dq test_text
 dq test_text_len
 dd 0
 dw 1
 dw 1

section .bss align=64
snapshot: resb NEBO_LIVE_CONFIG_SIZE
icon_pixels: resb NEBO_LIVE_ICON_BYTES

section .text
_start:
 mov r15,rsp
 cmp qword [rsp],2
 jne .usage
 mov rax,[rsp+16]
 cmp byte [rax],'1'
 je .scenario_one
 cmp byte [rax],'2'
 je .scenario_two
.usage:
 mov edi,2
 jmp process_exit

.scenario_one:
 call scenario_metadata_bounds
 mov edi,eax
 jmp process_exit

.scenario_two:
 call build_test_icon
 lea rdi,[rel title_first]
 mov esi,title_first_len
 call nebo_runtime_live_console_set_title
 test eax,eax
 jnz .scenario_two_fail
 lea rdi,[rel title_final]
 mov esi,title_final_len
 call nebo_runtime_live_console_set_title
 test eax,eax
 jnz .scenario_two_fail
 lea rdi,[rel icon_pixels]
 mov esi,8
 mov edx,8
 mov ecx,NEBO_LIVE_ICON_MAX_WIDTH*4
 call nebo_runtime_live_console_set_icon
 test eax,eax
 jnz .scenario_two_fail
 lea rdi,[rel icon_pixels]
 mov esi,NEBO_LIVE_ICON_MAX_WIDTH
 mov edx,NEBO_LIVE_ICON_MAX_HEIGHT
 mov ecx,NEBO_LIVE_ICON_MAX_WIDTH*4
 call nebo_runtime_live_console_set_icon
 test eax,eax
 jnz .scenario_two_fail
 lea rdi,[rel test_program]
 mov rsi,r15
 call nebo_runtime_start
 ud2
.scenario_two_fail:
 mov edi,1
 jmp process_exit

scenario_metadata_bounds:
 push rbx
 lea rdi,[rel snapshot]
 call nebo_runtime_live_console_metadata_snapshot
 test eax,eax
 jnz .metadata_fail
 cmp qword [rel snapshot+NEBO_LIVE_CONFIG_WIDTH_OFFSET],NEBO_LIVE_DEFAULT_WIDTH
 jne .metadata_fail
 cmp qword [rel snapshot+NEBO_LIVE_CONFIG_HEIGHT_OFFSET],NEBO_LIVE_DEFAULT_HEIGHT
 jne .metadata_fail
 cmp qword [rel snapshot+NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET],default_title_len
 jne .metadata_fail
 mov rdi,[rel snapshot+NEBO_LIVE_CONFIG_TITLE_PTR_OFFSET]
 lea rsi,[rel default_title]
 mov ecx,default_title_len
 cld
 repe cmpsb
 jne .metadata_fail
 cmp qword [rel snapshot+NEBO_LIVE_CONFIG_REVISION_OFFSET],1
 jne .metadata_fail

 xor edi,edi
 mov esi,1
 call nebo_runtime_live_console_set_title
 cmp eax,NEBO_LIVE_METADATA_STATUS_INVALID_ARGUMENT
 jne .metadata_fail
 lea rdi,[rel title_first]
 mov esi,NEBO_LIVE_TITLE_MAX_BYTES+1
 call nebo_runtime_live_console_set_title
 cmp eax,NEBO_LIVE_METADATA_STATUS_LIMIT
 jne .metadata_fail
 lea rdi,[rel title_first]
 mov esi,title_first_len
 call nebo_runtime_live_console_set_title
 test eax,eax
 jnz .metadata_fail
 xor edi,edi
 xor esi,esi
 call nebo_runtime_live_console_set_title
 test eax,eax
 jnz .metadata_fail

 xor edi,edi
 mov esi,1
 mov edx,1
 mov ecx,4
 call nebo_runtime_live_console_set_icon
 cmp eax,NEBO_LIVE_METADATA_STATUS_INVALID_ARGUMENT
 jne .metadata_fail
 call build_test_icon
 lea rdi,[rel icon_pixels]
 mov esi,8
 mov edx,8
 mov ecx,NEBO_LIVE_ICON_MAX_WIDTH*4
 call nebo_runtime_live_console_set_icon
 test eax,eax
 jnz .metadata_fail
 lea rdi,[rel icon_pixels]
 mov esi,NEBO_LIVE_ICON_MAX_WIDTH
 mov edx,NEBO_LIVE_ICON_MAX_HEIGHT
 mov ecx,NEBO_LIVE_ICON_MAX_WIDTH*4
 call nebo_runtime_live_console_set_icon
 test eax,eax
 jnz .metadata_fail
 lea rdi,[rel icon_pixels]
 mov esi,NEBO_LIVE_ICON_MAX_WIDTH+1
 mov edx,1
 mov ecx,(NEBO_LIVE_ICON_MAX_WIDTH+1)*4
 call nebo_runtime_live_console_set_icon
 cmp eax,NEBO_LIVE_METADATA_STATUS_LIMIT
 jne .metadata_fail

 lea rdi,[rel snapshot]
 call nebo_runtime_live_console_metadata_snapshot
 test eax,eax
 jnz .metadata_fail
 cmp qword [rel snapshot+NEBO_LIVE_CONFIG_REVISION_OFFSET],5
 jne .metadata_fail
 cmp qword [rel snapshot+NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET],default_title_len
 jne .metadata_fail
 cmp qword [rel snapshot+NEBO_LIVE_CONFIG_ICON_WIDTH_OFFSET],NEBO_LIVE_ICON_MAX_WIDTH
 jne .metadata_fail
 cmp qword [rel snapshot+NEBO_LIVE_CONFIG_ICON_HEIGHT_OFFSET],NEBO_LIVE_ICON_MAX_HEIGHT
 jne .metadata_fail
 mov rax,[rel snapshot+NEBO_LIVE_CONFIG_ICON_PTR_OFFSET]
 cmp dword [rax],0xffd69b36
 jne .metadata_fail
 xor eax,eax
 jmp .metadata_done
.metadata_fail:
 mov eax,1
.metadata_done:
 pop rbx
 ret

; Opaque 16x16 deterministic test asset. The strip-colored background avoids
; external image parsing; two diagonals and a blue core form the Nebo mark.
build_test_icon:
 lea rdi,[rel icon_pixels]
 xor r8d,r8d
.icon_y:
 cmp r8d,NEBO_LIVE_ICON_MAX_HEIGHT
 jae .icon_ready
 xor r9d,r9d
.icon_x:
 cmp r9d,NEBO_LIVE_ICON_MAX_WIDTH
 jae .icon_next_y
 mov eax,0xff202b3d
 cmp r9d,r8d
 je .icon_gold
 mov r10d,NEBO_LIVE_ICON_MAX_WIDTH-1
 sub r10d,r8d
 cmp r9d,r10d
 je .icon_gold
 cmp r9d,5
 jb .icon_store
 cmp r9d,10
 ja .icon_store
 cmp r8d,5
 jb .icon_store
 cmp r8d,10
 ja .icon_store
 mov eax,0xff78a9ff
 jmp .icon_store
.icon_gold:
 mov eax,0xffd69b36
.icon_store:
 mov r10d,r8d
 imul r10d,NEBO_LIVE_ICON_MAX_WIDTH
 add r10d,r9d
 mov [rdi+r10*4],eax
 inc r9d
 jmp .icon_x
.icon_next_y:
 inc r8d
 jmp .icon_y
.icon_ready:
 ret

test_program:
 push rbp
 mov rbp,rsp
 lea rdi,[rel test_text_descriptor]
 call nebo_runtime_console_publish_text
 mov rsp,rbp
 pop rbp
 xor eax,eax
 ret

process_exit:
 mov eax,SYS_EXIT
 syscall
 ud2

section .note.GNU-stack noalloc noexec nowrite progbits
