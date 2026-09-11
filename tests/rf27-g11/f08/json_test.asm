bits 64
default rel
%include "runtime/serialization/json.inc"

section .rodata
valid db '{"a": [true, false, null], "b": "x\u00e9", "c": -12.5e2}'
valid_len equ $-valid
canonical db '{"a":[true,false,null],"b":"x\u00e9","c":-12.5e2}'
canonical_len equ $-canonical
duplicate db '{"a":1,"a":2}'
duplicate_len equ $-duplicate
unsorted db '{"b":1,"a":2}'
unsorted_len equ $-unsorted
deep db '[[[0]]]'
deep_len equ $-deep
entries db '[1,2,3]'
entries_len equ $-entries
bad_escape db '"\q"'
bad_escape_len equ $-bad_escape
bad_surrogate db '"\uD800x"'
bad_surrogate_len equ $-bad_surrogate
bad_zero db '01'
bad_zero_len equ $-bad_zero
bad_exp db '1e309'
bad_exp_len equ $-bad_exp
trailing db 'true false'
trailing_len equ $-trailing
bad_utf8 db '"',0xc0,0x80,'"'
bad_utf8_len equ $-bad_utf8

section .bss
output resb 128

section .text
global _start
_start:
 lea rdi,[valid]
 mov esi,valid_len
 mov edx,8
 mov ecx,32
 call nebo_json_validate
 test eax,eax
 jnz .fail1
 cmp edx,7
 jne .fail2
 lea rdi,[valid]
 mov esi,valid_len
 lea rdx,[output]
 mov ecx,128
 mov r8d,8
 mov r9d,32
 call nebo_json_canonical_copy
 test eax,eax
 jnz .fail3
 cmp edx,canonical_len
 jne .fail4
 xor ecx,ecx
.compare:
 cmp ecx,canonical_len
 jae .compare_done
 mov al,[output+rcx]
 cmp al,[canonical+rcx]
 jne .fail5
 inc ecx
 jmp .compare
.compare_done:
 lea rdi,[duplicate]
 mov esi,duplicate_len
 mov edx,8
 mov ecx,16
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail6
 lea rdi,[unsorted]
 mov esi,unsorted_len
 mov edx,8
 mov ecx,16
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail7
 lea rdi,[deep]
 mov esi,deep_len
 mov edx,2
 mov ecx,16
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jne .fail8
 lea rdi,[entries]
 mov esi,entries_len
 mov edx,8
 mov ecx,3
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jne .fail9
 lea rdi,[bad_escape]
 mov esi,bad_escape_len
 mov edx,8
 mov ecx,8
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail10
 lea rdi,[bad_surrogate]
 mov esi,bad_surrogate_len
 mov edx,8
 mov ecx,8
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail11
 lea rdi,[bad_zero]
 mov esi,bad_zero_len
 mov edx,8
 mov ecx,8
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail12
 lea rdi,[bad_exp]
 mov esi,bad_exp_len
 mov edx,8
 mov ecx,8
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail13
 lea rdi,[trailing]
 mov esi,trailing_len
 mov edx,8
 mov ecx,8
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail14
 lea rdi,[bad_utf8]
 mov esi,bad_utf8_len
 mov edx,8
 mov ecx,8
 call nebo_json_validate
 cmp eax,NEBO_FILE_ERROR_INVALID_ENCODING
 jne .fail15
 lea rdi,[valid]
 mov esi,valid_len
 lea rdx,[output]
 mov ecx,8
 mov r8d,8
 mov r9d,32
 call nebo_json_canonical_copy
 cmp eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jne .fail16
 xor edi,edi
 jmp .exit
.fail1: mov edi,1
 jmp .exit
.fail2: mov edi,2
 jmp .exit
.fail3: mov edi,3
 jmp .exit
.fail4: mov edi,4
 jmp .exit
.fail5: mov edi,5
 jmp .exit
.fail6: mov edi,6
 jmp .exit
.fail7: mov edi,7
 jmp .exit
.fail8: mov edi,8
 jmp .exit
.fail9: mov edi,9
 jmp .exit
.fail10: mov edi,10
 jmp .exit
.fail11: mov edi,11
 jmp .exit
.fail12: mov edi,12
 jmp .exit
.fail13: mov edi,13
 jmp .exit
.fail14: mov edi,14
 jmp .exit
.fail15: mov edi,15
 jmp .exit
.fail16: mov edi,16
.exit:
 mov eax,60
 syscall
