; RF116 integration closeout. This internal observer composes every runtime
; source probe from G087 through G115 and publishes a pointer-free receipt.
bits 64
default rel
%define NEBO_G116_CLOSEOUT_IMPLEMENTATION 1
%include "runtime/console/closeout.inc"

extern nebo_g087_source_probe
extern nebo_g088_source_probe
extern nebo_g089_source_probe
extern nebo_g090_source_probe
extern nebo_g091_source_probe
extern nebo_g092_source_probe
extern nebo_g093_source_probe
extern nebo_g094_source_probe
extern nebo_g095_source_probe
extern nebo_g096_source_probe
extern nebo_g097_source_probe
extern nebo_g098_source_probe
extern nebo_g099_source_probe
extern nebo_g100_source_probe
extern nebo_g101_source_probe
extern nebo_g102_source_probe
extern nebo_g103_source_probe
extern nebo_g104_source_probe
extern nebo_g105_source_probe
extern nebo_g106_source_probe
extern nebo_g107_source_probe
extern nebo_g108_source_probe
extern nebo_g109_source_probe
extern nebo_g110_source_probe
extern nebo_g111_source_probe
extern nebo_g112_source_probe
extern nebo_g113_source_probe
extern nebo_g114_source_probe
extern nebo_g115_source_probe

section .bss align=16
g116_source_receipt: resb NEBO_G116_RECEIPT_SIZE

section .text
global nebo_g116_closeout_observe
global nebo_g116_source_probe

%define G116_FNV_OFFSET 0xcbf29ce484222325
%define G116_FNV_PRIME 0x100000001b3

; A component contributes only after its real owner returns the independently
; expected source-derived value. R14 is the rolling digest and R15 the count.
%macro G116_COMPONENT 4
    mov edi,%2
    mov esi,%3
    mov edx,%4
    call nebo_g%1_source_probe
    cmp eax,%3
    jne .dependency
    xor r14,%1
    mov rax,G116_FNV_PRIME
    imul r14,rax
    xor r14,%3
    imul r14,rax
    inc r15d
%endmacro

; EDI=gate/mode 1..10, ESI=source seed 3601..3610, RDX=receipt.
; The caller receipt is untouched until every predecessor observation passes.
nebo_g116_closeout_observe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov ebp,edi
    mov r12d,esi
    mov rbx,rdx
    cmp ebp,1
    jb .invalid
    cmp ebp,NEBO_G116_SOURCE_MAX_MODE
    ja .invalid
    lea eax,[rbp+3600]
    cmp r12d,eax
    jne .invalid
    test rbx,rbx
    jz .invalid
    test rbx,7
    jnz .invalid

    mov r14,G116_FNV_OFFSET
    xor r15d,r15d
    G116_COMPONENT 087,1,17,0
    G116_COMPONENT 088,1,17,0
    G116_COMPONENT 089,1,17,0
    G116_COMPONENT 090,1,17,0
    G116_COMPONENT 091,1,17,0
    G116_COMPONENT 092,1,7,0
    G116_COMPONENT 093,1,11,0
    G116_COMPONENT 094,1,11,0
    G116_COMPONENT 095,1,11,0
    G116_COMPONENT 096,1,13,0
    G116_COMPONENT 097,1,7,0
    G116_COMPONENT 098,1,7,0
    G116_COMPONENT 099,1,7,0
    G116_COMPONENT 100,1,7,0
    G116_COMPONENT 101,1,7,0
    G116_COMPONENT 102,1,9,0
    G116_COMPONENT 103,1,1301,0
    G116_COMPONENT 104,1,1401,0
    G116_COMPONENT 105,1,2501,0
    G116_COMPONENT 106,1,2601,0
    G116_COMPONENT 107,1,2701,0
    G116_COMPONENT 108,1,2801,0
    G116_COMPONENT 109,1,2901,0x110
    G116_COMPONENT 110,1,3001,0
    G116_COMPONENT 111,1,3101,0
    G116_COMPONENT 112,1,3201,0
    G116_COMPONENT 113,1,3301,0
    G116_COMPONENT 114,1,3401,0
    G116_COMPONENT 115,1,3501,0
    cmp r15d,NEBO_G116_RUNTIME_COMPONENT_COUNT
    jne .dependency

    xor r14,rbp
    mov rax,G116_FNV_PRIME
    imul r14,rax
    xor r14,r12
    imul r14,rax
    test r14,r14
    jz .dependency

    mov qword [rbx+NEBO_G116_RECEIPT_VERSION_OFFSET],NEBO_G116_RECEIPT_VERSION
    mov [rbx+NEBO_G116_RECEIPT_MODE_OFFSET],rbp
    mov [rbx+NEBO_G116_RECEIPT_SEED_OFFSET],r12
    mov qword [rbx+NEBO_G116_RECEIPT_RUNTIME_COMPONENTS_OFFSET],NEBO_G116_RUNTIME_COMPONENT_COUNT
    mov qword [rbx+NEBO_G116_RECEIPT_FRONTEND_SUBSTRATES_OFFSET],NEBO_G116_FRONTEND_SUBSTRATE_COUNT
    mov qword [rbx+NEBO_G116_RECEIPT_PREDECESSORS_OFFSET],NEBO_G116_PREDECESSOR_COUNT
    mov qword [rbx+NEBO_G116_RECEIPT_GATES_OFFSET],NEBO_G116_GATE_COUNT
    mov [rbx+NEBO_G116_RECEIPT_LOGICAL_DIGEST_OFFSET],r14
    mov [rbx+NEBO_G116_RECEIPT_HEADLESS_LOGICAL_OFFSET],r14
    mov [rbx+NEBO_G116_RECEIPT_LIVE_LOGICAL_OFFSET],r14
    mov qword [rbx+NEBO_G116_RECEIPT_TARGET_FLAGS_OFFSET],NEBO_G116_TARGET_HEADLESS_EXECUTED|NEBO_G116_TARGET_LIVE_CONTRACT_VERIFIED
    mov qword [rbx+NEBO_G116_RECEIPT_PUBLIC_ENTRYPOINTS_OFFSET],1
    mov qword [rbx+NEBO_G116_RECEIPT_LEGACY_FACADES_OFFSET],0
    mov qword [rbx+NEBO_G116_RECEIPT_OPEN_FINDINGS_OFFSET],0
    mov qword [rbx+NEBO_G116_RECEIPT_MATURITY_OFFSET],NEBO_G116_MATURITY_MULTITARGET_VISUAL_CONSOLE_FACTUAL
    mov [rbx+NEBO_G116_RECEIPT_RESULT_OFFSET],r12
    xor eax,eax
    jmp .done
.invalid:
    mov eax,-NEBO_G116_ERROR_INVALID
    jmp .done
.dependency:
    mov eax,-NEBO_G116_ERROR_DEPENDENCY
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; Source-facing adapter used by compiler lowering. It returns the source seed
; only after the complete runtime composition receipt is valid.
nebo_g116_source_probe:
    push rbx
    sub rsp,16
    mov ebx,esi
    lea rdx,[rel g116_source_receipt]
    call nebo_g116_closeout_observe
    test eax,eax
    jnz .done
    mov eax,ebx
.done:
    add rsp,16
    pop rbx
    ret

%undef G116_COMPONENT

section .note.GNU-stack noalloc noexec nowrite progbits
