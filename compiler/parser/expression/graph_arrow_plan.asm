; G140 graph/workflow/statechart Registry slice.  Recognition is exact while
; semantic admission requires the row's explicit domain profile.
bits 64
default rel

%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/parser/expression/operator_precedence.inc"

%define GRAPH_ID 0
%define GRAPH_TOKEN 8
%define GRAPH_PROFILE 16
%define GRAPH_FIXITY 24
%define GRAPH_PRECEDENCE 32
%define GRAPH_ASSOC 40
%define GRAPH_FLAGS 48
%define GRAPH_ENTRY_SIZE 56
%define GRAPH_ENTRY_COUNT 4

%define GRAPH_PROFILE_GRAPH 1
%define GRAPH_PROFILE_WORKFLOW 2
%define GRAPH_PROFILE_STATECHART 3

section .rodata
align 8
graph_entries:
 dq NEBOC_OPERATOR_ID_NSR_DOM_070,NEBOC_TOKEN_GRAPH_DIRECTED,GRAPH_PROFILE_GRAPH,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_RELATIONAL,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_CONTEXTUAL|NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_OPERATOR_ID_NSR_DOM_071,NEBOC_TOKEN_GRAPH_BIDIRECTIONAL,GRAPH_PROFILE_GRAPH,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_RELATIONAL,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_CONTEXTUAL|NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_OPERATOR_ID_NSR_DOM_072,NEBOC_TOKEN_GRAPH_ASYNC,GRAPH_PROFILE_WORKFLOW,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_RELATIONAL,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_CONTEXTUAL|NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 dq NEBOC_OPERATOR_ID_NSR_DOM_073,NEBOC_TOKEN_STATE_TRANSITION,GRAPH_PROFILE_STATECHART,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_RELATIONAL,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT|NEBOC_OPERATOR_PARSE_FLAG_CONTEXTUAL|NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE|NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED

section .text
global nebo_graph_arrow_plan, nebo_graph_arrow_registry_lookup

; edi=zero-based row, esi=domain profile. eax=0 admitted, 1 gate, 2 row.
; On admission RDX is the immutable Registry row.
nebo_graph_arrow_plan:
 cmp edi,GRAPH_ENTRY_COUNT-1
 ja .row
 mov eax,edi
 imul rax,GRAPH_ENTRY_SIZE
 lea rdx,[rel graph_entries]
 add rdx,rax
 cmp [rdx+GRAPH_PROFILE],rsi
 jne .gate
 xor eax,eax
 ret
.gate:
 mov eax,1
 xor edx,edx
 ret
.row:
 mov eax,2
 xor edx,edx
 ret

; rdi=Registry ID, rsi=domain profile. RAX=row or zero; output fields mirror
; the row and keep the semantic profile visible to tooling.
nebo_graph_arrow_registry_lookup:
 lea rax,[rel graph_entries]
 mov r11d,GRAPH_ENTRY_COUNT
.loop:
 cmp [rax+GRAPH_ID],rdi
 je .candidate
 add rax,GRAPH_ENTRY_SIZE
 dec r11d
 jnz .loop
 jmp .miss
.candidate:
 cmp [rax+GRAPH_PROFILE],rsi
 jne .miss
 mov edx,[rax+GRAPH_TOKEN]
 mov ecx,[rax+GRAPH_PROFILE]
 mov r8d,[rax+GRAPH_FIXITY]
 mov r9d,[rax+GRAPH_PRECEDENCE]
 mov r10d,[rax+GRAPH_ASSOC]
 mov r11d,[rax+GRAPH_FLAGS]
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
