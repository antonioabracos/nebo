; G107 sink routing. All multi-target observations are staged before the
; caller-owned result is committed; the optional file adapter delegates to the
; existing sandboxed filesystem owner.
bits 64
default rel
%define NEBO_G107_CONSOLE_ROUTING_IMPLEMENTATION 1
%include "runtime/console_routing.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .text
global nebo_g107_route_plan_init
global nebo_g107_route_plan_validate
global nebo_g107_route_execute
global nebo_g107_route_close
global nebo_g107_file_publish
global nebo_g107_status_diagnostic

; RAX sink mask, R9 file mode -> RDX capability mask.
g107_required_caps:
    xor edx,edx
    test eax,NEBO_G107_SINK_STDOUT|NEBO_G107_SINK_STDERR
    jz .ansi
    or edx,NEBO_G107_CAP_PLAIN
.ansi:
    test eax,NEBO_G107_SINK_ANSI
    jz .file
    or edx,NEBO_G107_CAP_ANSI
.file:
    test eax,NEBO_G107_SINK_FILE
    jz .visual
    or edx,NEBO_G107_CAP_FILE
    cmp r9d,NEBO_G107_FILE_ATOMIC
    jne .visual
    or edx,NEBO_G107_CAP_ATOMIC
.visual:
    test eax,NEBO_G107_SINK_VISUAL
    jz .panel
    or edx,NEBO_G107_CAP_VISUAL
.panel:
    test eax,NEBO_G107_SINK_PANEL
    jz .done
    or edx,NEBO_G107_CAP_PANEL
.done:
    ret

; RDI bytes, ECX qwords -> RAX stable digest.
g107_digest_qwords:
    mov rax,0x47524f5554453137
.loop:
    xor rax,[rdi]
    rol rax,13
    imul rax,rax,0x45d9f3b
    add rdi,8
    dec ecx
    jnz .loop
    ret

; RDI payload, RSI length -> RAX content digest.
g107_digest_bytes:
    mov rax,0x73524f5554453137
    mov r8,0x100000001b3
.loop:
    test rsi,rsi
    jz .done
    movzx rdx,byte [rdi]
    xor rax,rdx
    imul rax,r8
    inc rdi
    dec rsi
    jmp .loop
.done:
    ret

; RDI plan, RSI requested, RDX available, RCX provided capabilities,
; R8 fallback policy, R9 file mode. EAX=0 or negative typed error.
nebo_g107_route_plan_init:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,104
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbp,r8
    mov rbx,r9
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r13,~NEBO_G107_SINK_ALL
    jnz .invalid
    test r14,~NEBO_G107_SINK_ALL
    jnz .invalid
    test r15,~NEBO_G107_CAP_ALL
    jnz .invalid
    cmp rbp,NEBO_G107_FALLBACK_MAX
    ja .invalid
    cmp rbx,NEBO_G107_FILE_MODE_MAX
    ja .invalid

    mov rax,r13
    mov rcx,r14
    not rcx
    and rax,rcx
    and rax,NEBO_G107_SINK_ALL
    mov r10,rax
    mov r11,r13
    mov qword [rsp+96],0
    test r10,r10
    jz .effective_ready
    cmp rbp,NEBO_G107_FALLBACK_TEXT
    jb .target
    cmp rbp,NEBO_G107_FALLBACK_SUMMARY
    ja .target
    test r14,NEBO_G107_SINK_STDOUT
    jz .target
    mov r11,r13
    and r11,r14
    or r11,NEBO_G107_SINK_STDOUT
    mov qword [rsp+96],1
.effective_ready:
    mov [rsp+88],r11
    mov rax,r11
    mov r9,rbx
    call g107_required_caps
    mov [rsp+32],rdx
    mov rax,r15
    and rax,rdx
    cmp rax,rdx
    jne .capability

    ; Reuse G072 target-token validators instead of minting a second target
    ; vocabulary. G072 requires the fallback policy to be explicit.
    mov rdi,RENDER_TARGET_TOKEN_ROUTER
    mov rsi,[rsp+88]
    and rsi,RENDER_ROUTER_MAX_MASK
    test rsi,rsi
    jz .skip_router
    mov rdx,RENDER_FLAG_FALLBACK
    call neboc_render_target_token_validate
    test eax,eax
    jnz .invalid
.skip_router:
    mov r11,[rsp+88]
    test r11,NEBO_G107_SINK_STDOUT|NEBO_G107_SINK_STDERR|NEBO_G107_SINK_ANSI
    jz .skip_output
    mov rdi,RENDER_TARGET_TOKEN_OUTPUT
    mov rsi,RENDER_TARGET_PLAIN
    test r11,NEBO_G107_SINK_ANSI
    jz .output_target_ready
    mov rsi,RENDER_TARGET_ANSI
.output_target_ready:
    mov rdx,RENDER_FLAG_FALLBACK
    call neboc_render_target_token_validate
    test eax,eax
    jnz .invalid
.skip_output:
    mov r11,[rsp+88]
    test r11,NEBO_G107_SINK_FILE
    jz .skip_file
    mov rdi,RENDER_TARGET_TOKEN_FILE
    mov rsi,RENDER_FILE_OVERWRITE
    cmp ebx,NEBO_G107_FILE_ATOMIC
    jne .file_target_ready
    mov rsi,RENDER_FILE_ATOMIC
.file_target_ready:
    mov rdx,RENDER_FLAG_FALLBACK
    call neboc_render_target_token_validate
    test eax,eax
    jnz .invalid
.skip_file:
    mov r11,[rsp+88]
    test r11,NEBO_G107_SINK_VISUAL|NEBO_G107_SINK_PANEL
    jz .skip_visual
    mov rdi,RENDER_TARGET_TOKEN_VISUAL
    mov rsi,RENDER_VISUAL_TEXT
    mov rdx,RENDER_FLAG_FALLBACK
    call neboc_render_target_token_validate
    test eax,eax
    jnz .invalid
.skip_visual:
    test rbp,rbp
    jz .policy_ready
    mov rdi,RENDER_POLICY_FALLBACK
    mov rsi,RENDER_TARGET_PLAIN
    cmp rbp,NEBO_G107_FALLBACK_TABLE
    jne .not_table
    mov rsi,RENDER_TARGET_MARKDOWN
.not_table:
    cmp rbp,NEBO_G107_FALLBACK_SUMMARY
    jne .policy_call
    mov rsi,RENDER_TARGET_HEADLESS
.policy_call:
    mov rdx,RENDER_FLAG_FALLBACK
    call neboc_render_policy_token_validate
    test eax,eax
    jnz .invalid
.policy_ready:
    mov rax,NEBO_G107_PLAN_MAGIC_VALUE
    mov [rsp+NEBO_G107_PLAN_MAGIC],rax
    mov [rsp+NEBO_G107_PLAN_REQUESTED],r13
    mov [rsp+NEBO_G107_PLAN_AVAILABLE],r14
    mov rax,[rsp+88]
    mov [rsp+NEBO_G107_PLAN_EFFECTIVE],rax
    mov rax,[rsp+32]
    mov [rsp+NEBO_G107_PLAN_REQUIRED_CAPS],rax
    mov [rsp+NEBO_G107_PLAN_PROVIDED_CAPS],r15
    mov [rsp+NEBO_G107_PLAN_FALLBACK],rbp
    mov [rsp+NEBO_G107_PLAN_FILE_MODE],rbx
    mov qword [rsp+NEBO_G107_PLAN_GENERATION],1
    mov rax,[rsp+96]
    mov [rsp+NEBO_G107_PLAN_FALLBACK_USED],rax
    mov rdi,rsp
    mov ecx,10
    call g107_digest_qwords
    mov [rsp+NEBO_G107_PLAN_DIGEST],rax
    mov rsi,rsp
    mov rdi,r12
    mov ecx,NEBO_G107_PLAN_QWORDS
    rep movsq
    xor eax,eax
    jmp .done
.target:
    mov eax,-NEBO_G107_ERROR_TARGET
    jmp .done
.capability:
    mov eax,-NEBO_G107_ERROR_CAPABILITY
    jmp .done
.invalid:
    mov eax,-NEBO_G107_ERROR_INVALID
.done:
    add rsp,104
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; RDI plan -> EAX typed status.
nebo_g107_route_plan_validate:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G107_PLAN_MAGIC_VALUE
    cmp [rdi+NEBO_G107_PLAN_MAGIC],rax
    jne .invalid
    cmp qword [rdi+NEBO_G107_PLAN_GENERATION],1
    jne .state
    push rdi
    mov ecx,10
    call g107_digest_qwords
    pop rdi
    cmp rax,[rdi+NEBO_G107_PLAN_DIGEST]
    jne .invalid
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G107_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G107_ERROR_INVALID
    ret

; RDI plan, RSI payload, RDX byte length, RCX result. Publication is all-or-none.
nebo_g107_route_execute:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,136
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    test r13,r13
    jz .invalid
    test r15,r15
    jz .invalid
    test r14,r14
    jz .invalid
    cmp r14,NEBO_G107_MAX_PAYLOAD
    ja .limit
    mov rdi,r12
    call nebo_g107_route_plan_validate
    test eax,eax
    jnz .done
    mov rax,[r12+NEBO_G107_PLAN_PROVIDED_CAPS]
    mov rdx,[r12+NEBO_G107_PLAN_REQUIRED_CAPS]
    and rax,rdx
    cmp rax,rdx
    jne .capability
    mov rdi,r13
    mov rsi,r14
    call g107_digest_bytes
    mov rbp,rax
    xor eax,eax
    mov ecx,NEBO_G107_RESULT_QWORDS
    mov rdi,rsp
    rep stosq
    mov rax,NEBO_G107_RESULT_MAGIC_VALUE
    mov [rsp+NEBO_G107_RESULT_MAGIC],rax
    mov rbx,[r12+NEBO_G107_PLAN_EFFECTIVE]
    mov [rsp+NEBO_G107_RESULT_COMMITTED],rbx
    mov [rsp+NEBO_G107_RESULT_PAYLOAD_DIGEST],rbp
    mov rax,[r12+NEBO_G107_PLAN_FALLBACK_USED]
    mov [rsp+NEBO_G107_RESULT_FALLBACK_USED],rax
    mov qword [rsp+NEBO_G107_RESULT_RECEIVER_EVALS],1
    mov qword [rsp+NEBO_G107_RESULT_GENERATION],1
    mov rax,[r12+NEBO_G107_PLAN_DIGEST]
    mov [rsp+NEBO_G107_RESULT_PLAN_DIGEST],rax
    xor eax,eax
    test rbx,NEBO_G107_SINK_STDOUT
    jz .stderr
    mov [rsp+NEBO_G107_RESULT_STDOUT_BYTES],r14
    add rax,r14
.stderr:
    test rbx,NEBO_G107_SINK_STDERR
    jz .file
    mov [rsp+NEBO_G107_RESULT_STDERR_BYTES],r14
    add rax,r14
.file:
    test rbx,NEBO_G107_SINK_FILE
    jz .ansi
    mov [rsp+NEBO_G107_RESULT_FILE_BYTES],r14
    add rax,r14
.ansi:
    test rbx,NEBO_G107_SINK_ANSI
    jz .visual
    mov [rsp+NEBO_G107_RESULT_ANSI_BYTES],r14
    add rax,r14
.visual:
    test rbx,NEBO_G107_SINK_VISUAL
    jz .panel
    mov [rsp+NEBO_G107_RESULT_VISUAL_BYTES],r14
    add rax,r14
.panel:
    test rbx,NEBO_G107_SINK_PANEL
    jz .commit
    mov [rsp+NEBO_G107_RESULT_PANEL_BYTES],r14
    add rax,r14
.commit:
    mov [rsp+NEBO_G107_RESULT_TOTAL_BYTES],rax
    mov rsi,rsp
    mov rdi,r15
    mov ecx,NEBO_G107_RESULT_QWORDS
    rep movsq
    xor eax,eax
    jmp .done
.capability:
    mov eax,-NEBO_G107_ERROR_CAPABILITY
    jmp .done
.limit:
    mov eax,-NEBO_G107_ERROR_LIMIT
    jmp .done
.invalid:
    mov eax,-NEBO_G107_ERROR_INVALID
.done:
    add rsp,136
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; RDI result. Close is explicit and exactly once.
nebo_g107_route_close:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G107_RESULT_MAGIC_VALUE
    cmp [rdi+NEBO_G107_RESULT_MAGIC],rax
    jne .invalid
    cmp qword [rdi+NEBO_G107_RESULT_CLOSED],0
    jne .state
    mov rax,[rdi+NEBO_G107_RESULT_COMMITTED]
    mov [rdi+NEBO_G107_RESULT_CLOSED],rax
    inc qword [rdi+NEBO_G107_RESULT_GENERATION]
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G107_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G107_ERROR_INVALID
    ret

; RDI filesystem capability, RSI relative path, RDX path length, RCX payload,
; R8 payload length, R9 G107 file mode. Uses the canonical sandboxed writer.
nebo_g107_file_publish:
    cmp r9,NEBO_G107_FILE_MODE_MAX
    ja .invalid
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    push r9
    sub rsp,8
    mov rdi,RENDER_TARGET_TOKEN_FILE
    mov rsi,RENDER_FILE_OVERWRITE
    cmp r9,NEBO_G107_FILE_ATOMIC
    jne .target_ready
    mov rsi,RENDER_FILE_ATOMIC
.target_ready:
    mov rdx,RENDER_FLAG_FALLBACK
    call neboc_render_target_token_validate
    test eax,eax
    jnz .target_error
    add rsp,8
    pop r9
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    jmp nebo_file_write_text
.target_error:
    add rsp,56
    mov eax,-NEBO_G107_ERROR_INVALID
    ret
.invalid:
    mov eax,-NEBO_G107_ERROR_INVALID
    ret

; EDI signed status -> stable diagnostic ID, zero for success.
nebo_g107_status_diagnostic:
    test edi,edi
    jz .ok
    neg edi
    cmp edi,NEBO_G107_ERROR_INVALID
    jb .unknown
    cmp edi,NEBO_G107_ERROR_FILESYSTEM
    ja .unknown
    lea eax,[rdi+10700]
    ret
.unknown:
    mov eax,10799
    ret
.ok:
    xor eax,eax
    ret
