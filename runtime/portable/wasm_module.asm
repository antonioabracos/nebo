; RESOLVER-TYPECHECKER-E-SEMANTICA-F01: ordered canonical WebAssembly section descriptors.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/portable/wasm_module.inc"
section .text
; rdi=record qwords, rsi=count, rdx=56-byte report. Output is failure-atomic.
NEBOC_ABI_FUNCTION nebo_wasm_module_evaluate
    push rbx
    push r12
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,NEBO_WASM_MODULE_MAX_RECORDS
    ja .limit
    xor ecx,ecx
    xor r8d,r8d
    mov r9,0xcbf29ce484222325
    mov rax,NEBO_WASM_MODULE_PROFILE_TAG
    xor r9,rax
    mov r10,-1
    xor r11d,r11d
    xor ebx,ebx
    mov r12,0x100000001b3
.scan:
    mov rax,[rdi+rcx*8]
    cmp rax,NEBO_WASM_MODULE_ITEM_MAX
    ja .invalid
    test rcx,rcx
    jz .ordered
    cmp rax,rbx
    jb .order
.ordered:
    mov rbx,rax
    add r8,rax
    jc .limit
    cmp rax,r10
    cmovb r10,rax
    cmp rax,r11
    cmova r11,rax
    xor r9,rax
    imul r9,r12
    inc rcx
    cmp rcx,rsi
    jb .scan
    mov qword [rdx+NEBO_WASM_MODULE_REPORT_STATUS],NEBO_WASM_MODULE_STATUS_OK
    mov [rdx+NEBO_WASM_MODULE_REPORT_COUNT],rsi
    mov [rdx+NEBO_WASM_MODULE_REPORT_SUM],r8
    mov [rdx+NEBO_WASM_MODULE_REPORT_HASH],r9
    mov [rdx+NEBO_WASM_MODULE_REPORT_MIN],r10
    mov [rdx+NEBO_WASM_MODULE_REPORT_MAX],r11
    mov rax,NEBO_WASM_MODULE_PROFILE_TAG
    mov [rdx+NEBO_WASM_MODULE_REPORT_PROFILE],rax
    xor eax,eax
    pop r12
    pop rbx
    ret
.invalid:
    mov eax,NEBO_WASM_MODULE_STATUS_INVALID
    pop r12
    pop rbx
    ret
.limit:
    mov eax,NEBO_WASM_MODULE_STATUS_LIMIT
    pop r12
    pop rbx
    ret
.order:
    mov eax,NEBO_WASM_MODULE_STATUS_ORDER
    pop r12
    pop rbx
    ret

; rdi=module bytes, rsi=byte count, rdx=56-byte report.
; Validates the deterministic bounded MVP structural envelope. It deliberately
; does not claim instruction validation or execution by a WebAssembly runtime.
NEBOC_ABI_FUNCTION nebo_wasm_validate
    push rbx
    push r12
    push r13
    push r14
    push r15
    test rdi,rdi
    jz .wasm_invalid
    test rdx,rdx
    jz .wasm_invalid
    cmp rsi,8
    jb .wasm_malformed
    cmp rsi,NEBO_WASM_MODULE_MAX_BYTES
    ja .wasm_limit
    cmp dword [rdi],0x6d736100
    jne .wasm_malformed
    cmp dword [rdi+4],1
    jne .wasm_unsupported
    mov r13,rdi
    mov r14,rsi
    mov r15,rdx
    mov r8d,8
    xor r9d,r9d
    xor r10d,r10d
    xor r12d,r12d
.wasm_section:
    cmp r8,r14
    je .wasm_validated
    ja .wasm_malformed
    movzx ebx,byte [r13+r8]
    inc r8
    cmp ebx,NEBO_WASM_MODULE_MAX_STANDARD_SECTION
    ja .wasm_unsupported
    test ebx,ebx
    jz .wasm_id_ok
    cmp ebx,r10d
    jbe .wasm_order
    mov r10d,ebx
.wasm_id_ok:
    inc r9
    cmp r9,NEBO_WASM_MODULE_MAX_SECTIONS
    ja .wasm_limit
    xor eax,eax
    xor ecx,ecx
    xor edx,edx
.wasm_leb:
    cmp r8,r14
    jae .wasm_malformed
    movzx esi,byte [r13+r8]
    inc r8
    inc edx
    cmp edx,4
    ja .wasm_noncanonical
    mov edi,esi
    and edi,0x7f
    shl rdi,cl
    or rax,rdi
    test esi,0x80
    jz .wasm_leb_done
    add ecx,7
    jmp .wasm_leb
.wasm_leb_done:
    cmp edx,1
    je .wasm_leb_canonical
    test edi,edi
    jz .wasm_noncanonical
.wasm_leb_canonical:
    cmp rax,NEBO_WASM_MODULE_MAX_BYTES
    ja .wasm_limit
    add r12,rax
    cmp r12,NEBO_WASM_MODULE_MAX_BYTES
    ja .wasm_limit
    mov rcx,r8
    add rcx,rax
    jc .wasm_malformed
    cmp rcx,r14
    ja .wasm_malformed
    mov r8,rcx
    jmp .wasm_section
.wasm_validated:
    xor r8d,r8d
    mov r11,0xcbf29ce484222325
    mov rax,NEBO_WASM_MODULE_PROFILE_TAG
    xor r11,rax
    mov rbx,0x100000001b3
.wasm_hash:
    movzx eax,byte [r13+r8]
    xor r11,rax
    imul r11,rbx
    inc r8
    cmp r8,r14
    jb .wasm_hash
    mov qword [r15+NEBO_WASM_VALIDATE_STATUS],NEBO_WASM_MODULE_STATUS_OK
    mov [r15+NEBO_WASM_VALIDATE_SECTION_COUNT],r9
    mov [r15+NEBO_WASM_VALIDATE_MODULE_BYTES],r14
    mov [r15+NEBO_WASM_VALIDATE_HASH],r11
    mov [r15+NEBO_WASM_VALIDATE_LAST_SECTION],r10
    mov [r15+NEBO_WASM_VALIDATE_PAYLOAD_BYTES],r12
    mov rax,NEBO_WASM_MODULE_PROFILE_TAG
    mov [r15+NEBO_WASM_VALIDATE_PROFILE],rax
    xor eax,eax
    jmp .wasm_return
.wasm_invalid:
    mov eax,NEBO_WASM_MODULE_STATUS_INVALID
    jmp .wasm_return
.wasm_limit:
    mov eax,NEBO_WASM_MODULE_STATUS_LIMIT
    jmp .wasm_return
.wasm_malformed:
    mov eax,NEBO_WASM_MODULE_STATUS_MALFORMED
    jmp .wasm_return
.wasm_unsupported:
    mov eax,NEBO_WASM_MODULE_STATUS_UNSUPPORTED
    jmp .wasm_return
.wasm_noncanonical:
    mov eax,NEBO_WASM_MODULE_STATUS_NONCANONICAL
    jmp .wasm_return
.wasm_order:
    mov eax,NEBO_WASM_MODULE_STATUS_ORDER
.wasm_return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
