bits 64
default rel
%include "compiler/formatter/formatter.inc"

section .rodata
source_whole: db 'start() {',32,32,13,10,'}',9,13,10
source_whole_len equ $-source_whole
expected_whole: db 'start() {',10,'}',10
expected_whole_len equ $-expected_whole
source_range: db 'a',32,32,10,'b',32,32,10
source_range_len equ $-source_range
expected_range: db 'a',10,'b',32,32,10
expected_range_len equ $-expected_range
empty_source: db 0

section .bss
align 16
contract resb NEBO_TOOLING_CONTRACT_SIZE
request resb NEBO_FORMATTER_REQUEST_SIZE
output_a resb 256
output_b resb 256

section .text
global _start
_start:
    lea rdi,[contract]
    call nebo_tooling_contract_init
    test eax,eax
    jnz .fail1

    lea rax,[source_whole]
    mov [request+NEBO_FORMATTER_REQUEST_SOURCE_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_SOURCE_LEN],source_whole_len
    lea rax,[output_a]
    mov [request+NEBO_FORMATTER_REQUEST_OUTPUT_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_CAP],256
    mov qword [request+NEBO_FORMATTER_REQUEST_RANGE_START],0
    mov qword [request+NEBO_FORMATTER_REQUEST_RANGE_END],0
    mov qword [request+NEBO_FORMATTER_REQUEST_FLAGS],0
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],0
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    test eax,eax
    jnz .fail2
    cmp qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],expected_whole_len
    jne .fail3
    lea rsi,[output_a]
    lea rdi,[expected_whole]
    mov ecx,expected_whole_len
    repe cmpsb
    jne .fail4

    ; Formatting canonical output again is byte-identical.
    lea rax,[output_a]
    mov [request+NEBO_FORMATTER_REQUEST_SOURCE_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_SOURCE_LEN],expected_whole_len
    lea rax,[output_b]
    mov [request+NEBO_FORMATTER_REQUEST_OUTPUT_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],0
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    test eax,eax
    jnz .fail5
    lea rsi,[output_a]
    lea rdi,[output_b]
    mov ecx,expected_whole_len
    repe cmpsb
    jne .fail6

    ; A complete-line range changes only its selected prefix line.
    lea rax,[source_range]
    mov [request+NEBO_FORMATTER_REQUEST_SOURCE_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_SOURCE_LEN],source_range_len
    lea rax,[output_a]
    mov [request+NEBO_FORMATTER_REQUEST_OUTPUT_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_RANGE_START],0
    mov qword [request+NEBO_FORMATTER_REQUEST_RANGE_END],4
    mov qword [request+NEBO_FORMATTER_REQUEST_FLAGS],NEBO_FORMATTER_FLAG_RANGE
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],0
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    test eax,eax
    jnz .fail7
    cmp qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],expected_range_len
    jne .fail8
    lea rsi,[output_a]
    lea rdi,[expected_range]
    mov ecx,expected_range_len
    repe cmpsb
    jne .fail9

    ; Non-line range fails without touching output or output_len.
    mov byte [output_a],0x5a
    mov qword [request+NEBO_FORMATTER_REQUEST_RANGE_START],1
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],0x5a
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    cmp eax,NEBO_FORMATTER_ERROR_RANGE
    jne .fail10
    cmp byte [output_a],0x5a
    jne .fail10
    cmp qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],0x5a
    jne .fail10

    ; Insufficient output capacity is validated before mutation.
    mov qword [request+NEBO_FORMATTER_REQUEST_RANGE_START],0
    mov qword [request+NEBO_FORMATTER_REQUEST_RANGE_END],0
    mov qword [request+NEBO_FORMATTER_REQUEST_FLAGS],0
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_CAP],5
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    cmp eax,NEBO_FORMATTER_ERROR_CAPACITY
    jne .fail11
    cmp byte [output_a],0x5a
    jne .fail16

    ; Source/output aliasing is forbidden.
    lea rax,[source_range]
    mov [request+NEBO_FORMATTER_REQUEST_OUTPUT_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_CAP],source_range_len
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    cmp eax,NEBO_FORMATTER_ERROR_ALIAS
    jne .fail12

    ; Formatter refuses a forged parser catalog contract.
    lea rax,[output_a]
    mov [request+NEBO_FORMATTER_REQUEST_OUTPUT_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_CAP],256
    inc qword [contract+NEBO_TOOLING_CONTRACT_PARSER]
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    cmp eax,NEBO_FORMATTER_ERROR_CONTRACT
    jne .fail13
    dec qword [contract+NEBO_TOOLING_CONTRACT_PARSER]

    ; Empty whole-file source has the unique canonical representation "\n".
    lea rax,[empty_source]
    mov [request+NEBO_FORMATTER_REQUEST_SOURCE_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_SOURCE_LEN],0
    lea rax,[output_a]
    mov [request+NEBO_FORMATTER_REQUEST_OUTPUT_PTR],rax
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_CAP],1
    mov qword [request+NEBO_FORMATTER_REQUEST_FLAGS],0
    mov qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],0
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    test eax,eax
    jnz .fail14
    cmp qword [request+NEBO_FORMATTER_REQUEST_OUTPUT_LEN],1
    jne .fail14
    cmp byte [output_a],10
    jne .fail14

    mov qword [request+NEBO_FORMATTER_REQUEST_FLAGS],2
    lea rdi,[contract]
    lea rsi,[request]
    call nebo_formatter_format
    cmp eax,NEBO_FORMATTER_ERROR_ARGUMENT
    jne .fail15

    xor edi,edi
    jmp .exit
%assign i 1
%rep 16
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall
