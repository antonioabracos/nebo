; Nebo Assembly — Linux x86-64 host bootstrap adapter
;
; Function:
;   neboc_host_process_exit
;
; Purpose:
;   Terminate the current Linux process through the isolated host boundary.
;
; Inputs:
;   EDI = process exit status.
;
; Outputs:
;   None. The function does not return.
;
; Status:
;   Not applicable.
;
; Clobbers:
;   RAX, RCX, R11.
;
; Preserved:
;   Not observable because the process terminates.
;
; Stack:
;   Unchanged.
;
; Ownership:
;   None.
;
; Thread safety:
;   Process-terminal operation.
;
; Errors:
;   A successful Linux exit syscall does not return. UD2 traps if the syscall
;   unexpectedly returns.
;
; Tests:
;   scripts/mf002/validate.sh
;   scripts/mf004/validate.sh
;
; OS boundary:
;   Linux x86-64 syscall 60 is isolated in this host-specific module.

bits 64
default rel

global neboc_host_process_exit

section .text

neboc_host_process_exit:
    mov eax, 60
    syscall
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits
