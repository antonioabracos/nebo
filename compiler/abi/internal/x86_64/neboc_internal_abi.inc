%ifndef NEBOC_INTERNAL_ABI_X86_64_INC
%define NEBOC_INTERNAL_ABI_X86_64_INC 1

%define NEBOC_INTERNAL_ABI_VERSION 0

%define NEBOC_ABI_STACK_ALIGNMENT 16
%define NEBOC_ABI_RED_ZONE_BYTES 0
%define NEBOC_ABI_INTEGER_ARGUMENT_REGISTERS 6

%define NEBOC_ABI_ARG0 rdi
%define NEBOC_ABI_ARG1 rsi
%define NEBOC_ABI_ARG2 rdx
%define NEBOC_ABI_ARG3 rcx
%define NEBOC_ABI_ARG4 r8
%define NEBOC_ABI_ARG5 r9

%define NEBOC_ABI_STATUS_REGISTER eax
%define NEBOC_ABI_SCALAR_RETURN_REGISTER rax

%macro NEBOC_ABI_FUNCTION 1
    global %1
    align 16
%1:
    cld
%endmacro

%macro NEBOC_ABI_CHECK_ENTRY_ALIGNMENT 1
    lea rax, [rsp + 8]
    test rax, NEBOC_ABI_STACK_ALIGNMENT - 1
    jnz %1
%endmacro

%macro NEBOC_ABI_RETURN_STATUS 1
    mov eax, %1
    cld
    ret
%endmacro

; Establish the System V pre-call invariant without changing flags or registers.
%macro NEBOC_ABI_ALIGNED_CALL 1
    lea rsp, [rsp - 8]
    call %1
    lea rsp, [rsp + 8]
%endmacro

; Lexical adapter used only in R03-frozen function scopes.
%macro NEBOC_ABI_FUNCTION_SCOPED_CALL 1
    %undef call
    NEBOC_ABI_ALIGNED_CALL %1
    %define call NEBOC_ABI_FUNCTION_SCOPED_CALL
%endmacro

%endif
