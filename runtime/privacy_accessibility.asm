; G106 privacy/accessibility policy composition.  This module binds the
; canonical Text privacy metadata and RenderPlan policy validators before any
; visual capability is exposed.  It owns no payload bytes and allocates none.
bits 64
default rel
%define NEBO_G106_PRIVACY_ACCESSIBILITY_IMPLEMENTATION 1
%include "runtime/privacy_accessibility.inc"
%include "runtime/textual/text_core.inc"

extern neboc_trust_zone_valid
extern neboc_quality_score_valid
extern neboc_text_as_trusted
extern neboc_text_with_quality
extern neboc_text_with_confidence
extern neboc_text_with_lineage
extern neboc_text_with_privacy_label
extern neboc_privacy_redact
extern neboc_privacy_sink_check
extern neboc_render_policy_token_validate

section .note.GNU-stack noalloc noexec nowrite progbits

section .rodata
g106_empty_byte: db 0
align 8
g106_empty_text:
    dq g106_empty_byte,0
    dq NEBO_TEXT_FLAG_STATIC|NEBO_TEXT_FLAG_VALID_UTF8|NEBO_TEXT_FLAG_ASCII
    dq NEBO_TEXT_STORAGE_STATIC

section .text
global nebo_g106_policy_init
global nebo_g106_policy_quality_lineage
global nebo_g106_policy_trust
global nebo_g106_policy_accessibility
global nebo_g106_policy_evaluate
global nebo_g106_plan_validate
global nebo_g106_audit_validate
global nebo_g106_status_diagnostic

; RDI policy, RSI privacy class, RDX action, RCX maximum sink label.
nebo_g106_policy_init:
    test rdi,rdi
    jz .invalid
    cmp rsi,NEBO_PRIVACY_LABEL_MAX
    ja .invalid
    cmp rdx,NEBO_G106_ACTION_ALLOW
    jb .invalid
    cmp rdx,NEBO_G106_ACTION_MAX
    ja .invalid
    cmp rcx,NEBO_PRIVACY_LABEL_MAX
    ja .invalid
    mov r8,rcx
    push rdi
    mov rcx,NEBO_G106_POLICY_QWORDS
    xor eax,eax
    rep stosq
    pop rdi
    mov [rdi+NEBO_G106_POLICY_CLASS],rsi
    mov [rdi+NEBO_G106_POLICY_ACTION],rdx
    mov [rdi+NEBO_G106_POLICY_SINK_MAX],r8
    mov qword [rdi+NEBO_G106_POLICY_TRUST],NEBO_TRUST_VERIFIED
    mov eax,NEBO_TRUST_VALIDATION_TOKEN_BASE|NEBO_TRUST_VERIFIED
    mov [rdi+NEBO_G106_POLICY_TOKEN],rax
    mov qword [rdi+NEBO_G106_POLICY_QUALITY],9000
    mov qword [rdi+NEBO_G106_POLICY_CONFIDENCE],8500
    mov qword [rdi+NEBO_G106_POLICY_LINEAGE],1
    mov qword [rdi+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_TEXT_FALLBACK
    mov qword [rdi+NEBO_G106_POLICY_STYLE],NEBO_G106_STYLE_ALL
    mov qword [rdi+NEBO_G106_POLICY_MASK_WIDTH],4
    mov rax,NEBO_G106_CAPABILITY_V1
    mov [rdi+NEBO_G106_POLICY_CAPABILITY],rax
    mov qword [rdi+NEBO_G106_POLICY_CONFIGURED],1
    xor eax,eax
    ret
.invalid:
    mov eax,-NEBO_G106_ERROR_INVALID
    ret

; RDI policy, RSI quality, RDX confidence, RCX non-zero lineage.
nebo_g106_policy_quality_lineage:
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_G106_POLICY_CONFIGURED],1
    jne .state
    cmp rsi,NEBO_SCORE_MAX
    ja .quality
    cmp rdx,NEBO_SCORE_MAX
    ja .quality
    test rcx,rcx
    jz .lineage
    mov [rdi+NEBO_G106_POLICY_QUALITY],rsi
    mov [rdi+NEBO_G106_POLICY_CONFIDENCE],rdx
    mov [rdi+NEBO_G106_POLICY_LINEAGE],rcx
    xor eax,eax
    ret
.invalid: mov eax,-NEBO_G106_ERROR_INVALID
    ret
.state: mov eax,-NEBO_G106_ERROR_STATE
    ret
.quality: mov eax,-NEBO_G106_ERROR_QUALITY
    ret
.lineage: mov eax,-NEBO_G106_ERROR_LINEAGE
    ret

; RDI policy, RSI trust zone, RDX explicit validation token.
nebo_g106_policy_trust:
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_G106_POLICY_CONFIGURED],1
    jne .state
    mov r8d,NEBO_TRUST_VALIDATION_TOKEN_BASE
    or r8d,esi
    cmp edx,r8d
    jne .trust
    push rdi
    push rsi
    sub rsp,8
    mov edi,esi
    call neboc_trust_zone_valid
    add rsp,8
    pop rsi
    pop rdi
    test eax,eax
    jz .trust
    mov [rdi+NEBO_G106_POLICY_TRUST],rsi
    mov [rdi+NEBO_G106_POLICY_TOKEN],rdx
    xor eax,eax
    ret
.invalid: mov eax,-NEBO_G106_ERROR_INVALID
    ret
.state: mov eax,-NEBO_G106_ERROR_STATE
    ret
.trust: mov eax,-NEBO_G106_ERROR_TRUST
    ret

; RDI policy, RSI accessibility bits, RDX style bits, RCX mask width.
nebo_g106_policy_accessibility:
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_G106_POLICY_CONFIGURED],1
    jne .state
    test rsi,NEBO_G106_ACCESS_TEXT_FALLBACK
    jz .access
    mov rax,rsi
    and rax,~NEBO_G106_ACCESS_ALL
    jnz .access
    test rsi,NEBO_G106_ACCESS_SCREEN_READER
    jz .access_bits_ok
    test rsi,NEBO_G106_ACCESS_NO_COLOR
    jz .access
.access_bits_ok:
    mov rax,rdx
    and rax,~NEBO_G106_STYLE_ALL
    jnz .access
    test rcx,rcx
    jz .limit
    cmp rcx,32
    ja .limit
    mov [rdi+NEBO_G106_POLICY_ACCESS],rsi
    mov [rdi+NEBO_G106_POLICY_STYLE],rdx
    mov [rdi+NEBO_G106_POLICY_MASK_WIDTH],rcx
    xor eax,eax
    ret
.invalid: mov eax,-NEBO_G106_ERROR_INVALID
    ret
.state: mov eax,-NEBO_G106_ERROR_STATE
    ret
.access: mov eax,-NEBO_G106_ERROR_ACCESSIBILITY
    ret
.limit: mov eax,-NEBO_G106_ERROR_LIMIT
    ret

; RDI plan.  Returns zero only for a complete, internally consistent plan.
nebo_g106_plan_validate:
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_G106_PLAN_ACTION],NEBO_G106_ACTION_ALLOW
    jb .invalid
    cmp qword [rdi+NEBO_G106_PLAN_ACTION],NEBO_G106_ACTION_MAX
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_CLASS],NEBO_PRIVACY_LABEL_MAX
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_SINK_MAX],NEBO_PRIVACY_LABEL_MAX
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_POLICY_TOKEN],RENDER_POLICY_PRIVACY
    jne .invalid
    test qword [rdi+NEBO_G106_PLAN_RENDER_FLAGS],RENDER_FLAG_FALLBACK
    jz .invalid
    mov rax,[rdi+NEBO_G106_PLAN_RENDER_FLAGS]
    and rax,~(RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE|RENDER_FLAG_REDACT)
    jnz .invalid
    cmp qword [rdi+NEBO_G106_PLAN_QUALITY],NEBO_SCORE_MAX
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_CONFIDENCE],NEBO_SCORE_MAX
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_LINEAGE],0
    je .invalid
    cmp qword [rdi+NEBO_G106_PLAN_TRUST],NEBO_TRUST_EXTERNAL
    jb .invalid
    cmp qword [rdi+NEBO_G106_PLAN_TRUST],NEBO_TRUST_MAX
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_PUBLIC
    jb .invalid
    cmp qword [rdi+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_DENIED
    ja .invalid
    test qword [rdi+NEBO_G106_PLAN_ACCESS],NEBO_G106_ACCESS_TEXT_FALLBACK
    jz .invalid
    mov rax,[rdi+NEBO_G106_PLAN_ACCESS]
    and rax,~NEBO_G106_ACCESS_ALL
    jnz .invalid
    cmp qword [rdi+NEBO_G106_PLAN_MASK_WIDTH],1
    jb .invalid
    cmp qword [rdi+NEBO_G106_PLAN_MASK_WIDTH],32
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_COLOR],1
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_STYLE],1
    ja .invalid
    cmp qword [rdi+NEBO_G106_PLAN_FALLBACK],1
    jne .invalid
    mov rax,[rdi+NEBO_G106_PLAN_ACTION]
    cmp rax,NEBO_G106_ACTION_ALLOW
    jne .plan_redact
    cmp qword [rdi+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_PUBLIC
    jne .invalid
    jmp .privacy_shape
.plan_redact:
    cmp rax,NEBO_G106_ACTION_REDACT
    jne .plan_mask
    cmp qword [rdi+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_REDACTED
    jne .invalid
    jmp .privacy_shape
.plan_mask:
    cmp rax,NEBO_G106_ACTION_MASK
    jne .plan_deny
    cmp qword [rdi+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_MASKED
    jne .invalid
    jmp .privacy_shape
.plan_deny:
    cmp qword [rdi+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_DENIED
    jne .invalid
.privacy_shape:
    test qword [rdi+NEBO_G106_PLAN_ACCESS],NEBO_G106_ACCESS_NO_COLOR
    jz .screen
    cmp qword [rdi+NEBO_G106_PLAN_COLOR],0
    jne .invalid
.screen:
    test qword [rdi+NEBO_G106_PLAN_ACCESS],NEBO_G106_ACCESS_SCREEN_READER
    jz .digest
    test qword [rdi+NEBO_G106_PLAN_ACCESS],NEBO_G106_ACCESS_NO_COLOR
    jz .invalid
.digest:
    cmp qword [rdi+NEBO_G106_PLAN_DIGEST],0
    je .invalid
    xor eax,eax
    ret
.invalid:
    mov eax,-NEBO_G106_ERROR_INVALID
    ret

; RDI audit.  Zero state is valid before first evaluation.
nebo_g106_audit_validate:
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_G106_AUDIT_MATURITY],NEBO_G106_MATURITY_PUBLIC_PRIVACY_AWARE_CONSOLE_GREEN
    ja .invalid
    cmp qword [rdi+NEBO_G106_AUDIT_LAST_DECISION],NEBO_G106_VISIBILITY_DENIED
    ja .invalid
    mov rax,[rdi+NEBO_G106_AUDIT_ALLOWED]
    add rax,[rdi+NEBO_G106_AUDIT_DENIED]
    add rax,[rdi+NEBO_G106_AUDIT_REDACTED]
    add rax,[rdi+NEBO_G106_AUDIT_MASKED]
    cmp rax,[rdi+NEBO_G106_AUDIT_EVALUATED]
    jne .invalid
    mov rax,[rdi+NEBO_G106_AUDIT_EVALUATED]
    cmp [rdi+NEBO_G106_AUDIT_ACCESSIBLE],rax
    jne .invalid
    cmp [rdi+NEBO_G106_AUDIT_LINEAGE_BOUND],rax
    jne .invalid
    cmp [rdi+NEBO_G106_AUDIT_NO_COLOR],rax
    ja .invalid
    cmp [rdi+NEBO_G106_AUDIT_HIGH_CONTRAST],rax
    ja .invalid
    cmp [rdi+NEBO_G106_AUDIT_SCREEN_READER],rax
    ja .invalid
    test rax,rax
    jz .empty
    cmp qword [rdi+NEBO_G106_AUDIT_MATURITY],NEBO_G106_MATURITY_PUBLIC_PRIVACY_AWARE_CONSOLE_GREEN
    jne .invalid
    cmp qword [rdi+NEBO_G106_AUDIT_LAST_DECISION],NEBO_G106_VISIBILITY_PUBLIC
    jb .invalid
    cmp qword [rdi+NEBO_G106_AUDIT_LAST_DIAGNOSTIC],0
    jne .invalid
    cmp qword [rdi+NEBO_G106_AUDIT_LAST_DIGEST],0
    je .invalid
    jmp .valid
.empty:
    cmp qword [rdi+NEBO_G106_AUDIT_MATURITY],NEBO_G106_MATURITY_CONTRACT
    jne .invalid
    cmp qword [rdi+NEBO_G106_AUDIT_LAST_DECISION],0
    jne .invalid
    cmp qword [rdi+NEBO_G106_AUDIT_LAST_DIAGNOSTIC],0
    jne .invalid
    cmp qword [rdi+NEBO_G106_AUDIT_LAST_DIGEST],0
    jne .invalid
.valid:
    xor eax,eax
    ret
.invalid:
    mov eax,-NEBO_G106_ERROR_INVALID
    ret

; RDI policy, RSI out plan, RDX in/out audit.  Failed evaluation is atomic:
; neither caller-owned output record changes before every canonical gate passes.
nebo_g106_policy_evaluate:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,408
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    test rbx,rbx
    jz .invalid
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    cmp qword [rbx+NEBO_G106_POLICY_CONFIGURED],1
    jne .state
    mov rax,NEBO_G106_CAPABILITY_V1
    cmp [rbx+NEBO_G106_POLICY_CAPABILITY],rax
    jne .state
    mov rdi,r13
    call nebo_g106_audit_validate
    test eax,eax
    jnz .state

    mov edi,dword [rbx+NEBO_G106_POLICY_TRUST]
    call neboc_trust_zone_valid
    test eax,eax
    jz .trust
    mov r14d,NEBO_TRUST_VALIDATION_TOKEN_BASE
    or r14d,dword [rbx+NEBO_G106_POLICY_TRUST]
    cmp r14,[rbx+NEBO_G106_POLICY_TOKEN]
    jne .trust
    mov edi,dword [rbx+NEBO_G106_POLICY_QUALITY]
    call neboc_quality_score_valid
    test eax,eax
    jz .quality
    mov edi,dword [rbx+NEBO_G106_POLICY_CONFIDENCE]
    call neboc_quality_score_valid
    test eax,eax
    jz .quality
    cmp qword [rbx+NEBO_G106_POLICY_LINEAGE],0
    je .lineage
    cmp qword [rbx+NEBO_G106_POLICY_CLASS],NEBO_PRIVACY_LABEL_MAX
    ja .privacy
    cmp qword [rbx+NEBO_G106_POLICY_SINK_MAX],NEBO_PRIVACY_LABEL_MAX
    ja .privacy
    cmp qword [rbx+NEBO_G106_POLICY_ACTION],NEBO_G106_ACTION_ALLOW
    jb .invalid
    cmp qword [rbx+NEBO_G106_POLICY_ACTION],NEBO_G106_ACTION_MAX
    ja .invalid
    mov rax,[rbx+NEBO_G106_POLICY_ACCESS]
    test rax,NEBO_G106_ACCESS_TEXT_FALLBACK
    jz .access
    and rax,~NEBO_G106_ACCESS_ALL
    jnz .access
    test qword [rbx+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_SCREEN_READER
    jz .access_ok
    test qword [rbx+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_NO_COLOR
    jz .access
.access_ok:
    mov rax,[rbx+NEBO_G106_POLICY_STYLE]
    and rax,~NEBO_G106_STYLE_ALL
    jnz .access
    cmp qword [rbx+NEBO_G106_POLICY_MASK_WIDTH],1
    jb .limit
    cmp qword [rbx+NEBO_G106_POLICY_MASK_WIDTH],32
    ja .limit

    ; Build canonical metadata through every semantic owner.
    lea rdi,[rel g106_empty_text]
    mov esi,dword [rbx+NEBO_G106_POLICY_TRUST]
    mov rdx,[rbx+NEBO_G106_POLICY_TOKEN]
    lea rcx,[rsp+240]
    call neboc_text_as_trusted
    test eax,eax
    jnz .trust
    lea rdi,[rsp+240]
    mov rsi,[rbx+NEBO_G106_POLICY_QUALITY]
    lea rdx,[rsp+304]
    call neboc_text_with_quality
    test eax,eax
    jnz .quality
    lea rdi,[rsp+304]
    mov rsi,[rbx+NEBO_G106_POLICY_CONFIDENCE]
    lea rdx,[rsp+240]
    call neboc_text_with_confidence
    test eax,eax
    jnz .quality
    lea rdi,[rsp+240]
    mov rsi,[rbx+NEBO_G106_POLICY_LINEAGE]
    lea rdx,[rsp+304]
    call neboc_text_with_lineage
    test eax,eax
    jnz .lineage
    lea rdi,[rsp+304]
    mov rsi,[rbx+NEBO_G106_POLICY_CLASS]
    lea rdx,[rsp+240]
    call neboc_text_with_privacy_label
    test eax,eax
    jnz .privacy

    mov r15,[rbx+NEBO_G106_POLICY_ACTION]
    cmp r15,NEBO_G106_ACTION_DENY
    je .privacy_done
    cmp r15,NEBO_G106_ACTION_ALLOW
    je .sink_original
    lea rdi,[rsp+240]
    mov esi,NEBO_REDACTION_POLICY_FULL
    lea rdx,[rsp+304]
    call neboc_privacy_redact
    test eax,eax
    jnz .privacy
    lea rdi,[rsp+304]
    jmp .sink
.sink_original:
    lea rdi,[rsp+240]
.sink:
    mov esi,dword [rbx+NEBO_G106_POLICY_SINK_MAX]
    lea rdx,[rsp+368]
    call neboc_privacy_sink_check
    test eax,eax
    jnz .privacy
.privacy_done:

    ; Canonical RenderPlan gates validate privacy and accessibility metadata.
    mov esi,RENDER_PRIVACY_PUBLIC
    mov rax,[rbx+NEBO_G106_POLICY_CLASS]
    cmp rax,nebo_text_privacy_PRIVACY_SENSITIVE
    jne .render_secret
    mov esi,RENDER_PRIVACY_SENSITIVE
.render_secret:
    cmp rax,nebo_text_privacy_PRIVACY_SECRET
    jne .render_personal
    mov esi,RENDER_PRIVACY_SECRET
.render_personal:
    cmp rax,NEBO_PRIVACY_PERSONAL_DATA
    jne .render_flags
    mov esi,RENDER_PRIVACY_PERSONAL
.render_flags:
    mov edx,RENDER_FLAG_FALLBACK
    cmp rax,NEBO_PRIVACY_PERSONAL_DATA
    jb .render_redact
    or edx,RENDER_FLAG_PRIVATE
.render_redact:
    cmp r15,NEBO_G106_ACTION_REDACT
    je .set_redact
    cmp r15,NEBO_G106_ACTION_MASK
    jne .render_validate
.set_redact:
    or edx,RENDER_FLAG_REDACT
.render_validate:
    mov edi,RENDER_POLICY_PRIVACY
    call neboc_render_policy_token_validate
    test eax,eax
    jnz .privacy
    mov edi,RENDER_POLICY_ACCESSIBILITY
    mov esi,RENDER_ACCESS_TEXT
    test qword [rbx+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_HIGH_CONTRAST
    jz .render_ascii
    or esi,RENDER_ACCESS_HIGH_CONTRAST
.render_ascii:
    test qword [rbx+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_NO_COLOR
    jz .render_access
    or esi,RENDER_ACCESS_ASCII
.render_access:
    mov edx,RENDER_FLAG_FALLBACK
    call neboc_render_policy_token_validate
    test eax,eax
    jnz .access

    ; Prepare complete temporary records before committing to caller memory.
    lea rdi,[rsp]
    mov rcx,NEBO_G106_PLAN_QWORDS
    xor eax,eax
    rep stosq
    lea rdi,[rsp+128]
    mov rsi,r13
    mov rcx,NEBO_G106_AUDIT_QWORDS
    rep movsq
    mov rax,[rbx+NEBO_G106_POLICY_CLASS]
    mov [rsp+NEBO_G106_PLAN_CLASS],rax
    mov rax,[rbx+NEBO_G106_POLICY_ACTION]
    mov [rsp+NEBO_G106_PLAN_ACTION],rax
    mov rax,[rbx+NEBO_G106_POLICY_SINK_MAX]
    mov [rsp+NEBO_G106_PLAN_SINK_MAX],rax
    mov qword [rsp+NEBO_G106_PLAN_POLICY_TOKEN],RENDER_POLICY_PRIVACY
    mov rax,RENDER_FLAG_FALLBACK
    cmp qword [rbx+NEBO_G106_POLICY_CLASS],NEBO_PRIVACY_PERSONAL_DATA
    jb .plan_redact
    or rax,RENDER_FLAG_PRIVATE
.plan_redact:
    cmp r15,NEBO_G106_ACTION_REDACT
    je .plan_set_redact
    cmp r15,NEBO_G106_ACTION_MASK
    jne .plan_flags
.plan_set_redact:
    or rax,RENDER_FLAG_REDACT
.plan_flags:
    mov [rsp+NEBO_G106_PLAN_RENDER_FLAGS],rax
    mov rax,[rbx+NEBO_G106_POLICY_ACCESS]
    mov [rsp+NEBO_G106_PLAN_ACCESS],rax
    mov rax,[rbx+NEBO_G106_POLICY_QUALITY]
    mov [rsp+NEBO_G106_PLAN_QUALITY],rax
    mov rax,[rbx+NEBO_G106_POLICY_CONFIDENCE]
    mov [rsp+NEBO_G106_PLAN_CONFIDENCE],rax
    mov rax,[rbx+NEBO_G106_POLICY_LINEAGE]
    mov [rsp+NEBO_G106_PLAN_LINEAGE],rax
    mov rax,[rbx+NEBO_G106_POLICY_TRUST]
    mov [rsp+NEBO_G106_PLAN_TRUST],rax
    mov rax,[rbx+NEBO_G106_POLICY_MASK_WIDTH]
    mov [rsp+NEBO_G106_PLAN_MASK_WIDTH],rax
    mov qword [rsp+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_PUBLIC
    cmp r15,NEBO_G106_ACTION_REDACT
    jne .visibility_mask
    mov qword [rsp+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_REDACTED
.visibility_mask:
    cmp r15,NEBO_G106_ACTION_MASK
    jne .visibility_deny
    mov qword [rsp+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_MASKED
.visibility_deny:
    cmp r15,NEBO_G106_ACTION_DENY
    jne .visual_caps
    mov qword [rsp+NEBO_G106_PLAN_VISIBILITY],NEBO_G106_VISIBILITY_DENIED
.visual_caps:
    mov rax,1
    test qword [rbx+NEBO_G106_POLICY_STYLE],NEBO_G106_STYLE_COLOR
    jz .no_color
    test qword [rbx+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_NO_COLOR
    jz .color_done
.no_color:
    xor eax,eax
.color_done:
    mov [rsp+NEBO_G106_PLAN_COLOR],rax
    mov rax,[rbx+NEBO_G106_POLICY_STYLE]
    and rax,NEBO_G106_STYLE_SEMANTIC
    setnz al
    movzx eax,al
    mov [rsp+NEBO_G106_PLAN_STYLE],rax
    mov qword [rsp+NEBO_G106_PLAN_FALLBACK],1

    ; Stable source-independent evidence digest over the policy decision.
    mov rax,[rbx+NEBO_G106_POLICY_LINEAGE]
    rol rax,17
    xor rax,[rbx+NEBO_G106_POLICY_CLASS]
    mov rcx,1099511628211
    imul rax,rcx
    xor rax,[rbx+NEBO_G106_POLICY_ACTION]
    rol rax,11
    xor rax,[rbx+NEBO_G106_POLICY_ACCESS]
    xor rax,[rbx+NEBO_G106_POLICY_QUALITY]
    or rax,1
    mov [rsp+NEBO_G106_PLAN_DIGEST],rax

    inc qword [rsp+128+NEBO_G106_AUDIT_EVALUATED]
    cmp r15,NEBO_G106_ACTION_ALLOW
    jne .audit_redact
    inc qword [rsp+128+NEBO_G106_AUDIT_ALLOWED]
    jmp .audit_access
.audit_redact:
    cmp r15,NEBO_G106_ACTION_REDACT
    jne .audit_mask
    inc qword [rsp+128+NEBO_G106_AUDIT_REDACTED]
    jmp .audit_access
.audit_mask:
    cmp r15,NEBO_G106_ACTION_MASK
    jne .audit_deny
    inc qword [rsp+128+NEBO_G106_AUDIT_MASKED]
    jmp .audit_access
.audit_deny:
    inc qword [rsp+128+NEBO_G106_AUDIT_DENIED]
.audit_access:
    inc qword [rsp+128+NEBO_G106_AUDIT_ACCESSIBLE]
    test qword [rbx+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_NO_COLOR
    jz .audit_contrast
    inc qword [rsp+128+NEBO_G106_AUDIT_NO_COLOR]
.audit_contrast:
    test qword [rbx+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_HIGH_CONTRAST
    jz .audit_reader
    inc qword [rsp+128+NEBO_G106_AUDIT_HIGH_CONTRAST]
.audit_reader:
    test qword [rbx+NEBO_G106_POLICY_ACCESS],NEBO_G106_ACCESS_SCREEN_READER
    jz .audit_lineage
    inc qword [rsp+128+NEBO_G106_AUDIT_SCREEN_READER]
.audit_lineage:
    inc qword [rsp+128+NEBO_G106_AUDIT_LINEAGE_BOUND]
    mov rax,[rsp+NEBO_G106_PLAN_VISIBILITY]
    mov [rsp+128+NEBO_G106_AUDIT_LAST_DECISION],rax
    mov qword [rsp+128+NEBO_G106_AUDIT_LAST_DIAGNOSTIC],0
    mov rax,[rsp+NEBO_G106_PLAN_DIGEST]
    mov [rsp+128+NEBO_G106_AUDIT_LAST_DIGEST],rax
    mov qword [rsp+128+NEBO_G106_AUDIT_MATURITY],NEBO_G106_MATURITY_PUBLIC_PRIVACY_AWARE_CONSOLE_GREEN

    lea rdi,[rsp]
    call nebo_g106_plan_validate
    test eax,eax
    jnz .state
    lea rdi,[rsp+128]
    call nebo_g106_audit_validate
    test eax,eax
    jnz .state
    mov rdi,r12
    lea rsi,[rsp]
    mov rcx,NEBO_G106_PLAN_QWORDS
    rep movsq
    mov rdi,r13
    lea rsi,[rsp+128]
    mov rcx,NEBO_G106_AUDIT_QWORDS
    rep movsq
    xor eax,eax
    jmp .done
.invalid: mov eax,-NEBO_G106_ERROR_INVALID
    jmp .done
.trust: mov eax,-NEBO_G106_ERROR_TRUST
    jmp .done
.quality: mov eax,-NEBO_G106_ERROR_QUALITY
    jmp .done
.lineage: mov eax,-NEBO_G106_ERROR_LINEAGE
    jmp .done
.privacy: mov eax,-NEBO_G106_ERROR_PRIVACY
    jmp .done
.access: mov eax,-NEBO_G106_ERROR_ACCESSIBILITY
    jmp .done
.limit: mov eax,-NEBO_G106_ERROR_LIMIT
    jmp .done
.state: mov eax,-NEBO_G106_ERROR_STATE
.done:
    add rsp,408
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

; EDI positive or negative status, EAX stable diagnostic (zero on success).
nebo_g106_status_diagnostic:
    mov eax,edi
    test eax,eax
    jz .ok
    jns .positive
    neg eax
.positive:
    cmp eax,NEBO_G106_ERROR_STATE
    ja .invalid
    lea rdx,[rel .table]
    mov eax,[rdx+rax*4]
    ret
.invalid:
    mov eax,NEBO_G106_DIAG_INVALID
    ret
.ok:
    xor eax,eax
    ret
align 4
.table:
    dd 0,NEBO_G106_DIAG_INVALID,NEBO_G106_DIAG_LIMIT,NEBO_G106_DIAG_TRUST
    dd NEBO_G106_DIAG_QUALITY,NEBO_G106_DIAG_LINEAGE,NEBO_G106_DIAG_PRIVACY
    dd NEBO_G106_DIAG_ACCESSIBILITY,NEBO_G106_DIAG_STATE

; Frozen RF116 compatibility surface.  These symbols keep their historical
; three-field validator ABI but are excluded from G106 source-to-effect proof.
%macro G106_COMPAT 1
global %1
%1:
    cmp rdi,1
    jl %%bad
    cmp rdi,32
    jg %%bad
    cmp rsi,0
    jl %%bad
    cmp rsi,15
    jg %%bad
    cmp rdx,0
    jl %%bad
    cmp rdx,3
    jg %%bad
    xor eax,eax
    ret
%%bad:
    mov eax,-1
    ret
%endmacro
G106_COMPAT nebo_privacy_classification_validate
G106_COMPAT nebo_redact_mask_validate
G106_COMPAT nebo_allow_deny_policy_validate
G106_COMPAT nebo_quality_lineage_validate
G106_COMPAT nebo_trust_zones_validate
G106_COMPAT nebo_safe_display_validate
G106_COMPAT nebo_accessibility_validate
G106_COMPAT nebo_contrast_reader_validate
G106_COMPAT nebo_audit_report_validate
G106_COMPAT nebo_privacy_trust_quality_lineage_e_acessibilidade_closeout_contract_validate
