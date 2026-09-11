; Structured diagnostics, safe renderer inspection and deterministic profiling.
bits 64
default rel
%define NEBO_G109_DIAGNOSTICS_IMPLEMENTATION 1
%include "runtime/console/diagnostics.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .rodata align=8
g109_mode_codes: dq 101,102,103,104,105,106,105,104,106

section .text
global nebo_g109_registry_lookup
global nebo_g109_diagnostic_build
global nebo_g109_explain
global nebo_g109_inspect
global nebo_g109_profiler
global nebo_g109_tooling_view
global nebo_g109_receipt_close

; RDI canonical RF52 catalog id, RSI caller-owned registry entry.
nebo_g109_registry_lookup:
    test rsi,rsi
    jz .invalid
    cmp rdi,NEBO_G109_CODE_VISUAL_LEX
    jb .unknown
    cmp rdi,NEBO_G109_CODE_VISUAL_SECURITY
    ja .unknown
    mov [rsi+NEBO_G109_REGISTRY_CODE],rdi
    mov qword [rsi+NEBO_G109_REGISTRY_SEVERITY],NEBO_G109_SEVERITY_ERROR
    mov rax,rdi
    sub rax,100
    mov [rsi+NEBO_G109_REGISTRY_PHASE],rax
    xor eax,eax
    ret
.unknown:
    mov eax,-NEBO_G109_ERROR_REGISTRY
    ret
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
    ret

; RDI input, RSI caller-owned receipt. Validation completes before publication.
nebo_g109_diagnostic_build:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov r8,[rdi+NEBO_G109_INPUT_MODE]
    cmp r8,1
    jb .range
    cmp r8,9
    ja .range
    mov r9,[rdi+NEBO_G109_INPUT_SEED]
    cmp r9,2900
    jb .range
    mov r10,[rdi+NEBO_G109_INPUT_DEPTH]
    cmp r10,1
    jb .range
    cmp r10,8
    ja .range
    mov r11,[rdi+NEBO_G109_INPUT_BUDGET]
    cmp r11,1
    jb .range
    cmp r11,64
    ja .range
    cmp r11,r10
    jb .limit
    cmp qword [rdi+NEBO_G109_INPUT_FLAGS],NEBO_G109_FLAGS_REQUIRED
    jne .privacy
    mov rax,[rdi+NEBO_G109_INPUT_CAPS]
    and rax,NEBO_G109_CAP_REQUIRED
    cmp rax,NEBO_G109_CAP_REQUIRED
    jne .capability
    mov rax,[rdi+NEBO_G109_INPUT_CAPS]
    test rax,~NEBO_G109_CAP_REQUIRED
    jnz .capability
    mov rcx,[rdi+NEBO_G109_INPUT_SPAN_START]
    mov rdx,[rdi+NEBO_G109_INPUT_SPAN_END]
    cmp rdx,rcx
    jbe .invalid
    mov rax,rdx
    sub rax,rcx
    cmp rax,r11
    ja .limit
    lea rdx,[rel g109_mode_codes]
    mov rax,[rdx+r8*8-8]
    mov qword [rsi+NEBO_G109_RECEIPT_STATE],NEBO_G109_STATE_READY
    mov [rsi+NEBO_G109_RECEIPT_CODE],rax
    mov qword [rsi+NEBO_G109_RECEIPT_SEVERITY],NEBO_G109_SEVERITY_ERROR
    mov rdx,rax
    sub rdx,100
    mov [rsi+NEBO_G109_RECEIPT_PHASE],rdx
    mov [rsi+NEBO_G109_RECEIPT_SEED],r9
    mov [rsi+NEBO_G109_RECEIPT_DEPTH],r10
    mov [rsi+NEBO_G109_RECEIPT_BUDGET],r11
    mov qword [rsi+NEBO_G109_RECEIPT_FLAGS],NEBO_G109_FLAGS_REQUIRED
    mov [rsi+NEBO_G109_RECEIPT_MODE],r8
    mov [rsi+NEBO_G109_RECEIPT_SPAN_START],rcx
    ; Restore the source span end after phase calculation.
    mov rdx,[rdi+NEBO_G109_INPUT_SPAN_END]
    mov [rsi+NEBO_G109_RECEIPT_SPAN_END],rdx
    mov rax,r9
    mov rdx,0x100000001b3
    imul rax,rdx
    xor rax,[rsi+NEBO_G109_RECEIPT_CODE]
    mov rdx,r10
    shl rdx,8
    xor rax,rdx
    mov rdx,r11
    shl rdx,16
    xor rax,rdx
    xor rax,NEBO_G109_FLAGS_REQUIRED
    mov [rsi+NEBO_G109_RECEIPT_FINGERPRINT],rax
    xor eax,eax
    ret
.range:
    mov eax,-NEBO_G109_ERROR_RANGE
    ret
.capability:
    mov eax,-NEBO_G109_ERROR_CAPABILITY
    ret
.privacy:
    mov eax,-NEBO_G109_ERROR_PRIVACY
    ret
.limit:
    mov eax,-NEBO_G109_ERROR_LIMIT
    ret
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
    ret

; Explain and fix-it are preview-only; no source bytes are ever modified.
nebo_g109_explain:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_G109_RECEIPT_STATE],NEBO_G109_STATE_READY
    jne .state
    mov rax,[rdi+NEBO_G109_RECEIPT_CODE]
    cmp rax,101
    jb .registry
    cmp rax,106
    ja .registry
    mov qword [rsi+NEBO_G109_EXPLAIN_STATE],NEBO_G109_OUTPUT_READY
    mov qword [rsi+NEBO_G109_EXPLAIN_VERSION],NEBO_G109_EXPLANATION_VERSION
    mov [rsi+NEBO_G109_EXPLAIN_CODE],rax
    mov qword [rsi+NEBO_G109_EXPLAIN_APPLICABILITY],NEBO_G109_FIXIT_MANUAL_ONLY
    cmp rax,NEBO_G109_CODE_VISUAL_PARSE
    jne .manual
    mov qword [rsi+NEBO_G109_EXPLAIN_APPLICABILITY],NEBO_G109_FIXIT_MACHINE_APPLICABLE
.manual:
    mov qword [rsi+NEBO_G109_EXPLAIN_EDIT_COUNT],1
    xor rax,[rdi+NEBO_G109_RECEIPT_FINGERPRINT]
    mov rdx,0x4558504c41494e31
    xor rax,rdx
    mov [rsi+NEBO_G109_EXPLAIN_CHECKSUM],rax
    xor eax,eax
    ret
.registry:
    mov eax,-NEBO_G109_ERROR_REGISTRY
    ret
.state:
    mov eax,-NEBO_G109_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
    ret

; Output layout intentionally contains no pointer or source/text field.
nebo_g109_inspect:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_G109_RECEIPT_STATE],NEBO_G109_STATE_READY
    jne .state
    mov rax,[rdi+NEBO_G109_RECEIPT_FLAGS]
    test rax,NEBO_G109_FLAG_INSPECT | NEBO_G109_FLAG_DEBUG
    jz .privacy
    mov qword [rsi+NEBO_G109_INSPECT_STATE],NEBO_G109_OUTPUT_READY
    mov rax,[rdi+NEBO_G109_RECEIPT_CODE]
    mov [rsi+NEBO_G109_INSPECT_CODE],rax
    mov rax,[rdi+NEBO_G109_RECEIPT_PHASE]
    mov [rsi+NEBO_G109_INSPECT_RENDERER],rax
    mov rax,[rdi+NEBO_G109_RECEIPT_DEPTH]
    mov [rsi+NEBO_G109_INSPECT_DEPTH],rax
    mov qword [rsi+NEBO_G109_INSPECT_SAFE_FLAGS],NEBO_G109_SAFE_FLAGS
    mov rax,[rdi+NEBO_G109_RECEIPT_FINGERPRINT]
    mov [rsi+NEBO_G109_INSPECT_FINGERPRINT],rax
    xor eax,eax
    ret
.privacy:
    mov eax,-NEBO_G109_ERROR_PRIVACY
    ret
.state:
    mov eax,-NEBO_G109_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
    ret

; Logical work is derived only from bounded source values, never wall time.
nebo_g109_profiler:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_G109_RECEIPT_STATE],NEBO_G109_STATE_READY
    jne .state
    mov qword [rsi+NEBO_G109_PROFILE_STATE],NEBO_G109_OUTPUT_READY
    mov rax,[rdi+NEBO_G109_RECEIPT_MODE]
    mov [rsi+NEBO_G109_PROFILE_EVENTS],rax
    mov rax,[rdi+NEBO_G109_RECEIPT_DEPTH]
    add rax,[rdi+NEBO_G109_RECEIPT_PHASE]
    imul rax,[rdi+NEBO_G109_RECEIPT_BUDGET]
    mov [rsi+NEBO_G109_PROFILE_WORK],rax
    mov rax,[rdi+NEBO_G109_RECEIPT_BUDGET]
    add rax,NEBO_G109_RECEIPT_SIZE+NEBO_G109_EXPLAIN_SIZE+NEBO_G109_INSPECT_SIZE+NEBO_G109_PROFILE_SIZE
    mov [rsi+NEBO_G109_PROFILE_PEAK],rax
    mov qword [rsi+NEBO_G109_PROFILE_DROPPED],0
    mov rax,[rdi+NEBO_G109_RECEIPT_FINGERPRINT]
    mov rdx,0x50524f46494c4531
    xor rax,rdx
    mov [rsi+NEBO_G109_PROFILE_STAMP],rax
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G109_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
    ret

; Formatter/linter/LSP consume one shared code/span/fix-it classification.
nebo_g109_tooling_view:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_G109_RECEIPT_STATE],NEBO_G109_STATE_READY
    jne .state
    mov qword [rsi+NEBO_G109_TOOLING_STATE],NEBO_G109_OUTPUT_READY
    mov rax,[rdi+NEBO_G109_RECEIPT_CODE]
    mov [rsi+NEBO_G109_TOOLING_CODE],rax
    mov rax,[rdi+NEBO_G109_RECEIPT_SPAN_START]
    mov [rsi+NEBO_G109_TOOLING_SPAN_START],rax
    mov rax,[rdi+NEBO_G109_RECEIPT_SPAN_END]
    mov [rsi+NEBO_G109_TOOLING_SPAN_END],rax
    mov qword [rsi+NEBO_G109_TOOLING_FIXIT],1
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G109_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
    ret

nebo_g109_receipt_close:
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_G109_RECEIPT_STATE],NEBO_G109_STATE_READY
    jne .state
    mov qword [rdi+NEBO_G109_RECEIPT_FINGERPRINT],0
    mov qword [rdi+NEBO_G109_RECEIPT_STATE],NEBO_G109_STATE_CLOSED
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G109_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
    ret
