; OPTION-RESULT-RANGES-MATEMATICOS-E-LATERAL-FLOW bounded mathematical ranges using the single U+2026 ellipsis.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

%define NEBOC_RANGE_INCLUSIVE 1
%define NEBOC_RANGE_EXCLUSIVE_END 2
%define NEBOC_RANGE_EXCLUSIVE_START 3
%define NEBOC_RANGE_EXCLUSIVE 4
%define NEBOC_RANGE_MAX_EAGER_CARDINALITY 1048576
%define NEBOC_RANGE_START_OFFSET 0
%define NEBOC_RANGE_END_OFFSET 8
%define NEBOC_RANGE_STEP_OFFSET 16
%define NEBOC_RANGE_CARDINALITY_OFFSET 24
%define NEBOC_RANGE_INCLUDE_START_OFFSET 32
%define NEBOC_RANGE_INCLUDE_END_OFFSET 40
%define NEBOC_RANGE_START_EVALUATIONS_OFFSET 48
%define NEBOC_RANGE_END_EVALUATIONS_OFFSET 56
%define NEBOC_RANGE_PLAN_SIZE 64

section .text
; mathematical_range_plan(kind, start, end, out_plan*)
NEBOC_ABI_FUNCTION neboc_mathematical_range_plan
 test rcx,rcx
 jz .invalid
 cmp rdi,NEBOC_RANGE_INCLUSIVE
 jb .source
 cmp rdi,NEBOC_RANGE_EXCLUSIVE
 ja .source
 mov r8,rdx
 sub r8,rsi
 jo .limit
 mov r9,1
 test r8,r8
 jns .distance
 neg r8
 jo .limit
 mov r9,-1
.distance:
 inc r8
 jo .limit
 mov r10,1
 mov r11,1
 cmp rdi,NEBOC_RANGE_EXCLUSIVE_END
 je .exclude_end
 cmp rdi,NEBOC_RANGE_EXCLUSIVE_START
 je .exclude_start
 cmp rdi,NEBOC_RANGE_EXCLUSIVE
 jne .bounded
 xor r10d,r10d
 xor r11d,r11d
 sub r8,2
 jmp .nonnegative
.exclude_end:
 xor r11d,r11d
 dec r8
 jmp .nonnegative
.exclude_start:
 xor r10d,r10d
 dec r8
.nonnegative:
 test r8,r8
 jns .bounded
 xor r8d,r8d
.bounded:
 cmp r8,NEBOC_RANGE_MAX_EAGER_CARDINALITY
 ja .limit
 mov [rcx+NEBOC_RANGE_START_OFFSET],rsi
 mov [rcx+NEBOC_RANGE_END_OFFSET],rdx
 mov [rcx+NEBOC_RANGE_STEP_OFFSET],r9
 mov [rcx+NEBOC_RANGE_CARDINALITY_OFFSET],r8
 mov [rcx+NEBOC_RANGE_INCLUDE_START_OFFSET],r10
 mov [rcx+NEBOC_RANGE_INCLUDE_END_OFFSET],r11
 mov qword [rcx+NEBOC_RANGE_START_EVALUATIONS_OFFSET],1
 mov qword [rcx+NEBOC_RANGE_END_EVALUATIONS_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
