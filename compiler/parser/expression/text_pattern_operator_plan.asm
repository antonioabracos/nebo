; G141 Text/Pattern Registry slice.  Exact lexemes remain separate from typed
; admission, and all three operators require the bounded Text/Pattern profile.
bits 64
default rel

%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/parser/expression/operator_precedence.inc"

%define TEXT_PATTERN_ID 0
%define TEXT_PATTERN_TOKEN 8
%define TEXT_PATTERN_PROFILE 16
%define TEXT_PATTERN_FIXITY 24
%define TEXT_PATTERN_PRECEDENCE 32
%define TEXT_PATTERN_ASSOC 40
%define TEXT_PATTERN_FLAGS 48
%define TEXT_PATTERN_ENTRY_SIZE 56
%define TEXT_PATTERN_ENTRY_COUNT 3
%define TEXT_PATTERN_PROFILE_BOUNDED 1

section .rodata
align 8
text_pattern_entries:
 dq NEBOC_OPERATOR_ID_NSR_DOM_074,NEBOC_TOKEN_TEXT_CONCAT,TEXT_PATTERN_PROFILE_BOUNDED,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_ADDITIVE,NEBOC_OPERATOR_PARSE_ASSOC_LEFT,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_OPERATOR_ID_NSR_DOM_075,NEBOC_TOKEN_PATTERN_MATCH,TEXT_PATTERN_PROFILE_BOUNDED,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_EQUALITY,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_OPERATOR_ID_NSR_DOM_076,NEBOC_TOKEN_PATTERN_NON_MATCH,TEXT_PATTERN_PROFILE_BOUNDED,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_EQUALITY,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED

section .text
global nebo_text_pattern_operator_plan, nebo_text_pattern_registry_lookup

; edi=zero-based row, esi=profile. eax=stable plan id, edx=status.
; Status: 0 admitted, 1 domain gate, 2 invalid row.
nebo_text_pattern_operator_plan:
 cmp edi,TEXT_PATTERN_ENTRY_COUNT-1
 ja .row
 cmp esi,TEXT_PATTERN_PROFILE_BOUNDED
 jne .gate
 lea eax,[rdi+141001]
 xor edx,edx
 ret
.gate:
 xor eax,eax
 mov edx,1
 ret
.row:
 xor eax,eax
 mov edx,2
 ret

; rdi=Registry ID, rsi=profile. RAX=row or zero; the remaining outputs expose
; the immutable token/fixity/precedence/associativity/flag contract.
nebo_text_pattern_registry_lookup:
 lea rax,[rel text_pattern_entries]
 mov r11d,TEXT_PATTERN_ENTRY_COUNT
.loop:
 cmp [rax+TEXT_PATTERN_ID],rdi
 je .candidate
 add rax,TEXT_PATTERN_ENTRY_SIZE
 dec r11d
 jnz .loop
 jmp .miss
.candidate:
 cmp [rax+TEXT_PATTERN_PROFILE],rsi
 jne .miss
 mov edx,[rax+TEXT_PATTERN_TOKEN]
 mov ecx,[rax+TEXT_PATTERN_PROFILE]
 mov r8d,[rax+TEXT_PATTERN_FIXITY]
 mov r9d,[rax+TEXT_PATTERN_PRECEDENCE]
 mov r10d,[rax+TEXT_PATTERN_ASSOC]
 mov r11d,[rax+TEXT_PATTERN_FLAGS]
 ret
.miss:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
