; AST-HIR-LIR-PLANNER-E-OTIMIZACAO-F05: deterministic artifact plans derived from validated schemas.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/protocol/codegen.inc"
extern nebo_protocol_validate_schema
section .text

; rdi=API model, rsi=protocol descriptor, rdx=caller-computed canonical hash
NEBOC_ABI_FUNCTION nebo_api_from_protocol
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    push rdi
    push rsi
    push rdx
    mov rdi,rsi
    call nebo_protocol_validate_schema
    pop rdx
    pop rsi
    pop rdi
    test eax,eax
    jnz .done
    mov [rdi+NEBO_API_PROTOCOL],rsi
    mov [rdi+NEBO_API_SCHEMA_HASH],rdx
    mov qword [rdi+NEBO_API_FLAGS],0
.done:
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; Common: rdi=model, rsi=target, rdx=artifact report, r8=kind.
artifact_plan:
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp rsi,NEBO_GENERATED_TARGET_X86_64
    jne .unsupported
    cmp qword [rdi+NEBO_API_PROTOCOL],0
    je .invalid
    mov rax,[rdi+NEBO_API_SCHEMA_HASH]
    test rax,rax
    jz .invalid
    ; All validation precedes the first report write (failure atomicity).
    mov [rdx+NEBO_ARTIFACT_KIND],r8
    mov [rdx+NEBO_ARTIFACT_TARGET],rsi
    mov [rdx+NEBO_ARTIFACT_SCHEMA_HASH],rax
    mov rcx,r8
    imul rcx,64
    add rcx,128
    mov [rdx+NEBO_ARTIFACT_BYTES_REQUIRED],rcx
    mov qword [rdx+NEBO_ARTIFACT_STATUS],NEBO_OK
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.unsupported:
    mov eax,NEBO_UNSUPPORTED
    ret

NEBOC_ABI_FUNCTION nebo_api_generate_client
    mov r8,NEBO_GENERATED_CLIENT
    jmp artifact_plan
NEBOC_ABI_FUNCTION nebo_api_generate_server
    mov r8,NEBO_GENERATED_SERVER
    jmp artifact_plan
NEBOC_ABI_FUNCTION nebo_api_generate_mock
    mov r8,NEBO_GENERATED_MOCK
    jmp artifact_plan
NEBOC_ABI_FUNCTION nebo_api_generate_documentation
    mov r8,NEBO_GENERATED_DOCUMENTATION
    jmp artifact_plan
NEBOC_ABI_FUNCTION nebo_api_generate_conformance
    mov r8,NEBO_GENERATED_CONFORMANCE
    jmp artifact_plan

; rdi=model, rsi=contiguous reports, rdx=count (exactly five)
NEBOC_ABI_FUNCTION nebo_generated_verify
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rdx,5
    jne .mismatch
    mov r8,[rdi+NEBO_API_SCHEMA_HASH]
    test r8,r8
    jz .invalid
    xor ecx,ecx
.loop:
    cmp rcx,rdx
    jae .complete
    mov r10,rcx
    imul r10,NEBO_ARTIFACT_SIZE
    cmp qword [rsi+r10+NEBO_ARTIFACT_STATUS],NEBO_OK
    jne .mismatch
    cmp r8,[rsi+r10+NEBO_ARTIFACT_SCHEMA_HASH]
    jne .mismatch
    mov rax,[rsi+r10+NEBO_ARTIFACT_KIND]
    lea r11,[rcx+1]
    cmp rax,r11
    jne .mismatch
    inc rcx
    jmp .loop
.complete:
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.mismatch:
    mov eax,NEBO_GENERATED_MISMATCH
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
