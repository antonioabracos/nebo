; PLUGINS-FFI-E-EXTENSIBILIDADE-F04 exact-weight symmetric MH and systematic SMC resampling.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/probabilistic/mcmc_smc.inc"
section .text
; rdi=explicit xorshift state, rsi=current weight, rdx=proposal weight, rcx=accept u64.
NEBOC_ABI_FUNCTION nebo_prob_mh_accept_u64
    test rdi,rdi
    jz .mh_invalid
    test rcx,rcx
    jz .mh_invalid
    test rsi,rsi
    jz .mh_invalid
    test rdx,rdx
    jz .mh_invalid
    cmp qword [rdi],0
    je .mh_invalid
    cmp rdx,rsi
    jae .mh_yes
    mov r8,rdx                    ; proposal weight
    ; Unbiased draw in [0,current weight).
    xor eax,eax
    sub rax,rsi
    xor edx,edx
    div rsi
    mov r9,rdx                    ; rejection threshold
.mh_draw:
    mov rax,[rdi]
    mov rdx,rax
    shr rdx,12
    xor rax,rdx
    mov rdx,rax
    shl rdx,25
    xor rax,rdx
    mov rdx,rax
    shr rdx,27
    xor rax,rdx
    mov [rdi],rax
    mov rdx,0x2545f4914f6cdd1d
    imul rax,rdx
    cmp rax,r9
    jb .mh_draw
    xor edx,edx
    div rsi
    cmp rdx,r8
    jb .mh_yes
    mov qword [rcx],0
    xor eax,eax
    ret
.mh_yes:
    mov qword [rcx],1
    xor eax,eax
    ret
.mh_invalid: mov eax,NEBO_MC_INVALID
    ret

; rdi=positive weights, rsi=count, rdx=offset numerator (<total), rcx=out indices.
; Systematic positions are (offset + j*total)/count.
NEBOC_ABI_FUNCTION nebo_prob_smc_systematic_u64
    test rdi,rdi
    jz .smc_invalid
    test rcx,rcx
    jz .smc_invalid
    test rsi,rsi
    jz .smc_invalid
    cmp rsi,NEBO_MC_MAX_PARTICLES
    ja .smc_limit
    mov r11,rdx                    ; preserve offset through overflow preflight
    xor r8d,r8d                   ; total
    xor r9d,r9d
.smc_sum:
    mov rax,[rdi+r9*8]
    test rax,rax
    jz .smc_invalid
    add r8,rax
    jc .smc_limit
    inc r9
    cmp r9,rsi
    jb .smc_sum
    cmp r11,r8
    jae .smc_invalid
    ; Preflight ensures j*total and cumulative*count cannot overflow.
    mov rax,r8
    mul rsi
    test rdx,rdx
    jnz .smc_limit
    push r11
    xor r9d,r9d                   ; output particle j
    xor r10d,r10d                 ; source index
    mov r11,[rdi]                 ; cumulative weight
.smc_particle:
    mov rax,r9
    imul rax,r8
    add rax,[rsp]                 ; position numerator
.smc_advance:
    mov rdx,r11
    imul rdx,rsi                  ; cumulative numerator
    cmp rax,rdx
    jb .smc_store
    inc r10
    cmp r10,rsi
    jae .smc_abort
    add r11,[rdi+r10*8]
    jmp .smc_advance
.smc_store:
    mov [rcx+r9*8],r10
    inc r9
    cmp r9,rsi
    jb .smc_particle
    add rsp,8
    xor eax,eax
    ret
.smc_abort:
    add rsp,8
    jmp .smc_invalid
.smc_invalid: mov eax,NEBO_MC_INVALID
    ret
.smc_limit: mov eax,NEBO_MC_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
