bits 64
default rel
%include "runtime/protocol/codegen.inc"
extern nebo_field_required
extern nebo_protocol_define
extern nebo_api_from_protocol
extern nebo_api_generate_client
extern nebo_api_generate_server
extern nebo_api_generate_mock
extern nebo_api_generate_documentation
extern nebo_api_generate_conformance
extern nebo_generated_verify
section .bss
protocol resb NEBO_PROTOCOL_SIZE
field resb nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE
api resb NEBO_API_SIZE
reports resb NEBO_ARTIFACT_SIZE*5
section .text
global _start
_start:
    lea rdi,[field]
    mov esi,1
    mov edx,1
    call nebo_field_required
    test eax,eax
    jnz fail
    lea rdi,[protocol]
    mov esi,1
    lea rdx,[field]
    mov ecx,1
    xor r8d,r8d
    xor r9d,r9d
    call nebo_protocol_define
    test eax,eax
    jnz fail
    lea rdi,[api]
    lea rsi,[protocol]
    mov rdx,0x123456789abcdef0
    call nebo_api_from_protocol
    test eax,eax
    jnz fail
%macro PLAN 2
    lea rdi,[api]
    mov esi,NEBO_GENERATED_TARGET_X86_64
    lea rdx,[reports+NEBO_ARTIFACT_SIZE*%1]
    call %2
    test eax,eax
    jnz fail
%endmacro
    PLAN 0,nebo_api_generate_client
    PLAN 1,nebo_api_generate_server
    PLAN 2,nebo_api_generate_mock
    PLAN 3,nebo_api_generate_documentation
    PLAN 4,nebo_api_generate_conformance
    lea rdi,[api]
    lea rsi,[reports]
    mov edx,5
    call nebo_generated_verify
    test eax,eax
    jnz fail
    ; Corrupt one schema hash; verification must fail.
    inc qword [reports+NEBO_ARTIFACT_SIZE*3+NEBO_ARTIFACT_SCHEMA_HASH]
    lea rdi,[api]
    lea rsi,[reports]
    mov edx,5
    call nebo_generated_verify
    cmp eax,NEBO_GENERATED_MISMATCH
    jne fail
    ; Unsupported target leaves report untouched.
    mov qword [reports],0x7777
    lea rdi,[api]
    mov esi,2
    lea rdx,[reports]
    call nebo_api_generate_client
    cmp eax,NEBO_UNSUPPORTED
    jne fail
    cmp qword [reports],0x7777
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
