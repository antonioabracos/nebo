; AUTONOMIA-CONTROLADA-E-AGENTES-F07 versioned context digest and bounded benchmark summary.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/scientific/reproducibility.inc"
section .text
; rdi=context bytes, rsi=length, rdx=out u64. FNV-1a-64, fixed versioned bytes.
NEBOC_ABI_FUNCTION nebo_scientific_context_digest
    test rdi,rdi
    jz .digest_invalid
    test rdx,rdx
    jz .digest_invalid
    test rsi,rsi
    jz .digest_invalid
    cmp rsi,NEBO_REPRO_MAX_CONTEXT_BYTES
    ja .digest_limit
    mov rax,0xcbf29ce484222325
    mov r8,0x100000001b3
    xor ecx,ecx
.digest_loop:
    movzx r9d,byte [rdi+rcx]
    xor rax,r9
    imul rax,r8
    inc rcx
    cmp rcx,rsi
    jb .digest_loop
    mov [rdx],rax
    xor eax,eax
    ret
.digest_invalid:
    mov eax,NEBO_REPRO_INVALID
    ret
.digest_limit:
    mov eax,NEBO_REPRO_LIMIT
    ret

; rdi=sorted u64 samples, rsi=count, rdx=report. Median uses lower middle.
NEBOC_ABI_FUNCTION nebo_scientific_benchmark_report_u64
    test rdi,rdi
    jz .report_invalid
    test rdx,rdx
    jz .report_invalid
    test rsi,rsi
    jz .report_invalid
    cmp rsi,NEBO_REPRO_MAX_SAMPLES
    ja .report_limit
    mov rcx,1
.sorted:
    cmp rcx,rsi
    jae .emit
    mov rax,[rdi+rcx*8-8]
    cmp rax,[rdi+rcx*8]
    ja .report_invalid
    inc rcx
    jmp .sorted
.emit:
    mov rax,[rdi]
    mov [rdx+NEBO_REPRO_REPORT_MIN],rax
    mov rcx,rsi
    dec rcx
    shr rcx,1
    mov rax,[rdi+rcx*8]
    mov [rdx+NEBO_REPRO_REPORT_MEDIAN],rax
    mov rax,[rdi+rsi*8-8]
    mov [rdx+NEBO_REPRO_REPORT_MAX],rax
    mov [rdx+NEBO_REPRO_REPORT_COUNT],rsi
    xor eax,eax
    ret
.report_invalid:
    mov eax,NEBO_REPRO_INVALID
    ret
.report_limit:
    mov eax,NEBO_REPRO_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
