; Nebo Console Runtime ABI v0 — physical generational handle helpers
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"

global nebo_console_handle_pack
global nebo_console_handle_unpack
global nebo_console_handle_is_valid

section .text

; nebo_console_handle_pack(slot_index u32, generation u32) -> RAX handle or zero.
nebo_console_handle_pack:
    test esi, esi
    jz .pack_invalid
    mov eax, edi
    mov edx, esi
    shl rdx, NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
    or rax, rdx
    ret
.pack_invalid:
    xor eax, eax
    ret

; nebo_console_handle_unpack(handle, out_slot_index_u32*, out_generation_u32*)
; Returns a Console Runtime status in EAX and zeroes both outputs on failure.
nebo_console_handle_unpack:
    test rsi, rsi
    jz .unpack_invalid_no_outputs
    test rdx, rdx
    jz .unpack_invalid_no_outputs
    mov dword [rsi], 0
    mov dword [rdx], 0
    test rdi, rdi
    jz .unpack_invalid
    mov eax, edi
    mov [rsi], eax
    shr rdi, NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
    test edi, edi
    jz .unpack_invalid
    mov [rdx], edi
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.unpack_invalid:
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    ret
.unpack_invalid_no_outputs:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; nebo_console_handle_is_valid(handle) -> EAX 0/1.
nebo_console_handle_is_valid:
    xor eax, eax
    test rdi, rdi
    jz .valid_done
    mov rdx, rdi
    shr rdx, NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
    test edx, edx
    setnz al
.valid_done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
