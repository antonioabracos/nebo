; Nebo CONTROLO-DE-FLUXO-ESTRUTURADO-F06 — bounded Canvas presentation bridge for direct X11
bits 64
default rel

%define NEBO_CANVAS_X11_IMPLEMENTATION 1
%include "runtime/canvas/canvas_x11.inc"

extern nebo_x11_adapter_present

global nebo_canvas_present_x11

section .text

; present_x11(canvas*, x11_runtime*, WindowHandle, owner_context, result*)
; The existing direct-X11 adapter consumes the Canvas SoftwareSurface prefix.
; Binding to the native window record is scoped to the adapter call and is
; restored before returning, including every backend failure path.
nebo_canvas_present_x11:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,104
    mov r12,rdi                    ; canvas
    mov r13,rsi                    ; x11 runtime
    mov r14,rdx                    ; generational handle
    mov r15,rcx                    ; owner context
    mov rbx,r8                     ; result
    mov dword [rsp+100],0          ; canvas validated flag

    test rbx,rbx
    jz .invalid
    test rbx,7
    jnz .invalid
    test r15,r15
    jz .owner
    mov rdi,r12
    call nebo_canvas_validate
    test eax,eax
    jnz .return
    mov dword [rsp+100],1
    cmp dword [r12+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
    jne .closed

    test r13,r13
    jz .invalid
    test r13,7
    jnz .invalid
    mov rax,NEBO_X11_RUNTIME_MAGIC
    cmp [r13+NEBO_X11_RUNTIME_MAGIC_OFFSET],rax
    jne .invalid
    mov eax,[r13+NEBO_X11_RUNTIME_FLAGS_OFFSET]
    test eax,~NEBO_X11_RUNTIME_KNOWN_FLAGS
    jnz .invalid
    mov edx,NEBO_X11_RUNTIME_FLAG_READY | NEBO_X11_RUNTIME_FLAG_LIVE
    and eax,edx
    cmp eax,edx
    jne .backend
    test dword [r13+NEBO_X11_RUNTIME_FLAGS_OFFSET],NEBO_X11_RUNTIME_FLAG_DISCONNECTED
    jnz .backend
    cmp qword [r13+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET],0
    je .invalid
    cmp qword [r13+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET],0
    je .invalid
    cmp qword [r13+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET],0
    je .invalid
    mov rax,[r13+NEBO_X11_RUNTIME_CAPACITY_OFFSET]
    test rax,rax
    jz .invalid
    cmp rax,NEBO_WINDOW_MAX_WINDOWS
    ja .invalid

    test r14,r14
    jz .stale
    mov ecx,r14d
    test ecx,ecx
    jz .stale
    cmp rcx,[r13+NEBO_X11_RUNTIME_CAPACITY_OFFSET]
    ja .stale
    mov r9,r14
    shr r9,NEBO_WINDOW_HANDLE_GENERATION_SHIFT
    test r9d,r9d
    jz .stale
    dec ecx
    mov [rsp+96],rcx               ; zero-based slot

    mov rax,rcx
    imul rax,NEBO_WINDOW_SIZE
    add rax,[r13+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    mov [rsp],rax                  ; canonical record
    cmp [rax+NEBO_WINDOW_HANDLE_OFFSET],r14
    jne .stale
    cmp [rax+nebo_canvas_WINDOW_GENERATION_OFFSET],r9
    jne .stale
    cmp [rax+NEBO_WINDOW_OWNER_CONTEXT_OFFSET],r15
    jne .owner
    cmp dword [rax+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_VISIBLE
    jne .bad_state
    cmp dword [rax+NEBO_WINDOW_BACKEND_OFFSET],NEBO_WINDOW_BACKEND_X11_DIRECT
    jne .bad_state
    cmp [rax+NEBO_WINDOW_BACKEND_CONTEXT_PTR_OFFSET],r13
    jne .bad_state
    mov rdx,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    cmp [rax+NEBO_WINDOW_WIDTH_OFFSET],rdx
    jne .dimension
    mov rdx,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    cmp [rax+NEBO_WINDOW_HEIGHT_OFFSET],rdx
    jne .dimension

    mov rcx,[rsp+96]
    imul rcx,NEBO_X11_WINDOW_SIZE
    add rcx,[r13+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET]
    mov [rsp+8],rcx                ; native record
    mov rdx,[r13+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    cmp [rcx+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET],rdx
    jne .bad_state
    cmp [rcx+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET],r14
    jne .stale
    cmp dword [rcx+NEBO_X11_WINDOW_STATE_OFFSET],NEBO_X11_WINDOW_STATE_MAPPED
    jne .bad_state
    cmp dword [rcx+NEBO_X11_WINDOW_XID_OFFSET],0
    je .bad_state
    mov rax,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    cmp [rcx+NEBO_X11_WINDOW_WIDTH_OFFSET],rax
    jne .dimension
    mov rax,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    cmp [rcx+NEBO_X11_WINDOW_HEIGHT_OFFSET],rax
    jne .dimension

    mov rax,[r12+NEBO_CANVAS_OWNER_CONTEXT_OFFSET]
    test rax,rax
    jz .canvas_owner_ready
    cmp rax,r15
    jne .owner
.canvas_owner_ready:
    cmp qword [r12+NEBO_CANVAS_FRAME_SEQUENCE_OFFSET],-1
    je .frame_exhausted
    cmp qword [r12+NEBO_CANVAS_PRESENT_COUNT_OFFSET],-1
    je .frame_exhausted

    ; Scope the adapter's required window.surface_ptr binding.
    mov rcx,[rsp+8]
    mov rax,[rcx+NEBO_X11_WINDOW_SURFACE_PTR_OFFSET]
    mov [rsp+16],rax
    mov [rcx+NEBO_X11_WINDOW_SURFACE_PTR_OFFSET],r12
    lea rdi,[rsp+32]
    xor eax,eax
    mov ecx,8
    cld
    rep stosq
    mov rdi,[r13+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi,[rsp+8]
    mov rdx,r12
    lea rcx,[rsp+32]
    call nebo_x11_adapter_present
    mov [rsp+96],eax
    mov rcx,[rsp+8]
    mov rax,[rsp+16]
    mov [rcx+NEBO_X11_WINDOW_SURFACE_PTR_OFFSET],rax
    cmp dword [rsp+96],0
    jne .backend

    lea rsi,[rsp+24]
    mov rdi,r12
    call nebo_canvas_state_hash
    test eax,eax
    jnz .return

    mov rax,[r12+NEBO_CANVAS_FRAME_SEQUENCE_OFFSET]
    inc rax
    mov [rbx+NEBO_CANVAS_PRESENT_FRAME_SEQUENCE_OFFSET],rax
    mov rdx,[rsp+24]
    mov [rbx+NEBO_CANVAS_PRESENT_FRAME_HASH_OFFSET],rdx
    mov rcx,[r12+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    mov [rbx+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET],rcx
    mov [r12+NEBO_CANVAS_LAST_FRAME_COMMAND_COUNT_OFFSET],rcx
    mov [r12+NEBO_CANVAS_FRAME_SEQUENCE_OFFSET],rax
    inc qword [r12+NEBO_CANVAS_PRESENT_COUNT_OFFSET]
    mov [r12+NEBO_CANVAS_LAST_FRAME_HASH_OFFSET],rdx
    cmp qword [r12+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0
    jne .owner_bound
    mov [r12+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],r15
.owner_bound:
    mov qword [r12+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0
    and dword [r12+NEBO_CANVAS_FLAGS_OFFSET],~NEBO_CANVAS_FLAG_DIRTY
    or dword [r12+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_PRESENTED
    mov rax,[rsp]
    and dword [rax+NEBO_WINDOW_FLAGS_OFFSET],~NEBO_HEADLESS_FLAG_REDRAW_PENDING
    mov qword [r12+NEBO_CANVAS_LAST_STATUS_OFFSET],0
    mov qword [r12+NEBO_CANVAS_LAST_ERROR_OFFSET],0
    mov qword [r12+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET],0
    mov qword [r12+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET],0
    xor eax,eax
    jmp .return

.frame_exhausted:
    mov eax,NEBO_CANVAS_ERROR_FRAME_EXHAUSTED
    jmp .error
.dimension:
    mov eax,NEBO_CANVAS_ERROR_DIMENSION_MISMATCH
    jmp .error
.owner:
    mov eax,NEBO_CANVAS_ERROR_OWNER_MISMATCH
    jmp .error
.stale:
    mov eax,NEBO_CANVAS_ERROR_STALE_WINDOW
    jmp .error
.bad_state:
    mov eax,NEBO_CANVAS_ERROR_BAD_STATE
    jmp .error
.closed:
    mov eax,NEBO_CANVAS_ERROR_CLOSED
    jmp .error
.backend:
    mov eax,NEBO_CANVAS_ERROR_BACKEND_FAILURE
    jmp .error
.invalid:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
.error:
    cmp dword [rsp+100],0
    je .return
    mov [r12+NEBO_CANVAS_LAST_STATUS_OFFSET],rax
    mov [r12+NEBO_CANVAS_LAST_ERROR_OFFSET],rax
    mov [r12+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET],rax
    mov [r12+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET],rax
.return:
    add rsp,104
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
