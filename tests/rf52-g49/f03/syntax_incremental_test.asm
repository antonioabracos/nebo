bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/incremental/syntax_incremental.inc"
global _start
extern neboc_source_snapshot_new,neboc_text_edit_new
extern neboc_incremental_lexer_lex,neboc_incremental_parser_parse
extern neboc_syntax_tree_changed_ranges,neboc_syntax_tree_reuse_report
extern neboc_syntax_tree_validate_against_cold_parse,neboc_snapshot_compact
extern neboc_incremental_parser_set_budget,neboc_cli_incremental_report
extern neboc_cli_check_cold,neboc_cli_check_incremental
extern neboc_host_process_exit

section .data
source1: db "alpha beta gamma"
source1_end:
source2: db "alpha delta gamma"
source2_end:
source3: db "alpha delta gamma"
source3_end:
replacement: db "delta"

section .bss align=16
snapshot1: resb NEBOC_SNAPSHOT_SIZE
snapshot2: resb NEBOC_SNAPSHOT_SIZE
snapshot3: resb NEBOC_SNAPSHOT_SIZE
edit: resb NEBOC_EDIT_SIZE
overlap_edits: resb NEBOC_EDIT_SIZE*2
stale_edit: resb NEBOC_EDIT_SIZE
tokens1: resb NEBOC_SYNTAX_INCREMENTAL_TOKEN_SIZE*8
tokens2: resb NEBOC_SYNTAX_INCREMENTAL_TOKEN_SIZE*8
tokens2_cold: resb NEBOC_SYNTAX_INCREMENTAL_TOKEN_SIZE*8
tokens3: resb NEBOC_SYNTAX_INCREMENTAL_TOKEN_SIZE*8
lex1: resb NEBOC_LEX_RESULT_SIZE
lex2: resb NEBOC_LEX_RESULT_SIZE
lex2_cold: resb NEBOC_LEX_RESULT_SIZE
lex3: resb NEBOC_LEX_RESULT_SIZE
invalid_lex: resb NEBOC_LEX_RESULT_SIZE
lex_request1: resb NEBOC_LEX_REQUEST_SIZE
lex_request2: resb NEBOC_LEX_REQUEST_SIZE
lex_request2_cold: resb NEBOC_LEX_REQUEST_SIZE
lex_request3: resb NEBOC_LEX_REQUEST_SIZE
invalid_request: resb NEBOC_LEX_REQUEST_SIZE
budget: resb NEBOC_INCREMENTAL_BUDGET_SIZE
tree1: resb NEBOC_TREE_SIZE
tree2: resb NEBOC_TREE_SIZE
tree2_cold: resb NEBOC_TREE_SIZE
tree3: resb NEBOC_TREE_SIZE
tree_budget: resb NEBOC_TREE_SIZE
parse_request1: resb neboc_syntax_incremental_PARSE_REQUEST_SIZE
parse_request2: resb neboc_syntax_incremental_PARSE_REQUEST_SIZE
parse_request2_cold: resb neboc_syntax_incremental_PARSE_REQUEST_SIZE
parse_request3: resb neboc_syntax_incremental_PARSE_REQUEST_SIZE
parse_request_budget: resb neboc_syntax_incremental_PARSE_REQUEST_SIZE
changed: resb NEBOC_CHANGED_SIZE
reuse: resb NEBOC_REUSE_SIZE
report: resb NEBOC_INCREMENTAL_REPORT_SIZE
snapshot_list: resq 3
compact_report: resb NEBOC_COMPACT_REPORT_SIZE

section .text
set_lex_request:
 ; rdi=request, rsi=snapshot, rdx=previous, rcx=edits, r8=count,
 ; r9=tokens; result pointer follows at [rsp+8].
 mov [rdi+NEBOC_LEX_REQUEST_SNAPSHOT_OFFSET],rsi
 mov [rdi+NEBOC_LEX_REQUEST_PREVIOUS_OFFSET],rdx
 mov [rdi+NEBOC_LEX_REQUEST_EDITS_OFFSET],rcx
 mov [rdi+NEBOC_LEX_REQUEST_EDIT_COUNT_OFFSET],r8
 mov [rdi+NEBOC_LEX_REQUEST_TOKENS_OFFSET],r9
 mov qword [rdi+NEBOC_LEX_REQUEST_TOKEN_CAPACITY_OFFSET],8
 mov rax,[rsp+8]
 mov [rdi+NEBOC_LEX_REQUEST_RESULT_OFFSET],rax
 ret

set_parse_request:
 ; rdi=request, rsi=lex, rdx=previous tree, rcx=budget, r8=tree output.
 mov [rdi+NEBOC_PARSE_REQUEST_LEX_OFFSET],rsi
 mov [rdi+NEBOC_PARSE_REQUEST_PREVIOUS_OFFSET],rdx
 mov [rdi+NEBOC_PARSE_REQUEST_BUDGET_OFFSET],rcx
 mov [rdi+NEBOC_PARSE_REQUEST_TREE_OFFSET],r8
 ret

_start:
 sub rsp,8
 lea rdi,[rel snapshot1]
 mov esi,1
 lea rdx,[rel source1]
 mov ecx,source1_end-source1
 mov r8d,1
 call neboc_source_snapshot_new
 test eax,eax
 jne .fail1
 lea rdi,[rel snapshot2]
 mov esi,1
 lea rdx,[rel source2]
 mov ecx,source2_end-source2
 mov r8d,2
 call neboc_source_snapshot_new
 test eax,eax
 jne .fail2
 lea rdi,[rel snapshot3]
 mov esi,1
 lea rdx,[rel source3]
 mov ecx,source3_end-source3
 mov r8d,3
 call neboc_source_snapshot_new
 test eax,eax
 jne .fail3
 mov rax,[rel snapshot2+NEBOC_SNAPSHOT_DIGEST_OFFSET]
 cmp rax,[rel snapshot3+NEBOC_SNAPSHOT_DIGEST_OFFSET]
 jne .fail4
 cmp rax,[rel snapshot1+NEBOC_SNAPSHOT_DIGEST_OFFSET]
 je .fail5

 lea rdi,[rel budget]
 mov esi,100
 mov edx,NEBOC_INCREMENTAL_MAX_SOURCE_BYTES
 mov ecx,100
 call neboc_incremental_parser_set_budget
 test eax,eax
 jne .fail6

 ; Cold revision 1 is the reference token/tree identity.
 lea rdi,[rel lex_request1]
 lea rsi,[rel snapshot1]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 lea r9,[rel tokens1]
 lea rax,[rel lex1]
 push rax
 call set_lex_request
 add rsp,8
 lea rdi,[rel lex_request1]
 call neboc_incremental_lexer_lex
 test eax,eax
 jne .fail7
 cmp qword [rel lex1+NEBOC_LEX_RESULT_TOKEN_COUNT_OFFSET],3
 jne .fail8
 cmp qword [rel lex1+NEBOC_LEX_RESULT_FALLBACK_OFFSET],NEBOC_INCREMENTAL_FALLBACK_COLD
 jne .fail9
 lea rdi,[rel parse_request1]
 lea rsi,[rel lex1]
 xor edx,edx
 lea rcx,[rel budget]
 lea r8,[rel tree1]
 call set_parse_request
 lea rdi,[rel parse_request1]
 call neboc_incremental_parser_parse
 test eax,eax
 jne .fail10
 cmp qword [rel tree1+NEBOC_TREE_NODE_COUNT_OFFSET],4
 jne .fail11
 lea rdi,[rel lex1]
 lea rsi,[rel tree1]
 call neboc_syntax_tree_validate_against_cold_parse
 test eax,eax
 jne .fail12

 ; Replace beta with delta against the exact base revision.
 lea rdi,[rel edit]
 lea rsi,[rel snapshot1]
 mov edx,6
 mov ecx,10
 lea r8,[rel replacement]
 mov r9d,5
 call neboc_text_edit_new
 test eax,eax
 jne .fail13
 lea rdi,[rel lex_request2]
 lea rsi,[rel snapshot2]
 lea rdx,[rel lex1]
 lea rcx,[rel edit]
 mov r8d,1
 lea r9,[rel tokens2]
 lea rax,[rel lex2]
 push rax
 call set_lex_request
 add rsp,8
 lea rdi,[rel parse_request2]
 lea rsi,[rel lex2]
 lea rdx,[rel tree1]
 lea rcx,[rel budget]
 lea r8,[rel tree2]
 call set_parse_request
 lea rdi,[rel lex_request2]
 lea rsi,[rel parse_request2]
 call neboc_cli_check_incremental
 test eax,eax
 jne .fail14
 cmp qword [rel lex2+NEBOC_LEX_RESULT_REUSED_OFFSET],2
 jne .fail15
 cmp qword [rel lex2+NEBOC_LEX_RESULT_REBUILT_OFFSET],1
 jne .fail16
 cmp qword [rel lex2+NEBOC_LEX_RESULT_CHANGED_START_OFFSET],6
 jne .fail17
 cmp qword [rel lex2+NEBOC_LEX_RESULT_CHANGED_END_OFFSET],11
 jne .fail18
 cmp qword [rel tree2+NEBOC_TREE_REUSED_OFFSET],2
 jne .fail19
 cmp qword [rel tree2+NEBOC_TREE_REBUILT_OFFSET],2
 jne .fail20
 lea rdi,[rel lex2]
 lea rsi,[rel tree2]
 call neboc_syntax_tree_validate_against_cold_parse
 test eax,eax
 jne .fail21
 lea rdi,[rel tree2]
 lea rsi,[rel tree1]
 lea rdx,[rel changed]
 call neboc_syntax_tree_changed_ranges
 test eax,eax
 jne .fail22
 cmp qword [rel changed+NEBOC_CHANGED_COUNT_OFFSET],1
 jne .fail23
 cmp qword [rel changed+NEBOC_CHANGED_START_OFFSET],6
 jne .fail24
 cmp qword [rel changed+NEBOC_CHANGED_END_OFFSET],11
 jne .fail25
 lea rdi,[rel lex2]
 lea rsi,[rel tree2]
 lea rdx,[rel reuse]
 call neboc_syntax_tree_reuse_report
 test eax,eax
 jne .fail26
 cmp qword [rel reuse+NEBOC_REUSE_TOKENS_REUSED_OFFSET],2
 jne .fail27

 ; An independent forced-cold pass must normalize to the same tree.
 lea rdi,[rel lex_request2_cold]
 lea rsi,[rel snapshot2]
 lea rdx,[rel lex1]
 lea rcx,[rel edit]
 mov r8d,1
 lea r9,[rel tokens2_cold]
 lea rax,[rel lex2_cold]
 push rax
 call set_lex_request
 add rsp,8
 lea rdi,[rel parse_request2_cold]
 lea rsi,[rel lex2_cold]
 xor edx,edx
 lea rcx,[rel budget]
 lea r8,[rel tree2_cold]
 call set_parse_request
 lea rdi,[rel lex_request2_cold]
 lea rsi,[rel parse_request2_cold]
 call neboc_cli_check_cold
 test eax,eax
 jne .fail28
 mov rax,[rel tree2+NEBOC_TREE_TOKEN_DIGEST_OFFSET]
 cmp rax,[rel tree2_cold+NEBOC_TREE_TOKEN_DIGEST_OFFSET]
 jne .fail29
 mov rax,[rel tree2+NEBOC_TREE_SOURCE_DIGEST_OFFSET]
 cmp rax,[rel tree2_cold+NEBOC_TREE_SOURCE_DIGEST_OFFSET]
 jne .fail30
 cmp qword [rel lex_request2_cold+NEBOC_LEX_REQUEST_PREVIOUS_OFFSET],0
 je .fail31

 ; Unchanged revision 3 preserves all token and node identities.
 lea rdi,[rel lex_request3]
 lea rsi,[rel snapshot3]
 lea rdx,[rel lex2]
 xor ecx,ecx
 xor r8d,r8d
 lea r9,[rel tokens3]
 lea rax,[rel lex3]
 push rax
 call set_lex_request
 add rsp,8
 lea rdi,[rel parse_request3]
 lea rsi,[rel lex3]
 lea rdx,[rel tree2]
 lea rcx,[rel budget]
 lea r8,[rel tree3]
 call set_parse_request
 lea rdi,[rel lex_request3]
 lea rsi,[rel parse_request3]
 call neboc_cli_check_incremental
 test eax,eax
 jne .fail32
 cmp qword [rel lex3+NEBOC_LEX_RESULT_REUSED_OFFSET],3
 jne .fail33
 cmp qword [rel tree3+NEBOC_TREE_REUSED_OFFSET],4
 jne .fail34
 lea rdi,[rel tree3]
 lea rsi,[rel tree2]
 lea rdx,[rel changed]
 call neboc_syntax_tree_changed_ranges
 test eax,eax
 jne .fail35
 cmp qword [rel changed+NEBOC_CHANGED_COUNT_OFFSET],0
 jne .fail36
 lea rdi,[rel lex3]
 lea rsi,[rel tree3]
 lea rdx,[rel report]
 call neboc_cli_incremental_report
 test eax,eax
 jne .fail37
 cmp qword [rel report+NEBOC_INCREMENTAL_REPORT_TOKENS_REUSED_OFFSET],3
 jne .fail38

 ; A tight budget explicitly falls back to the cold normalized result.
 lea rdi,[rel budget]
 mov esi,2
 mov edx,NEBOC_INCREMENTAL_MAX_SOURCE_BYTES
 mov ecx,100
 call neboc_incremental_parser_set_budget
 test eax,eax
 jne .fail39
 lea rdi,[rel parse_request_budget]
 lea rsi,[rel lex3]
 lea rdx,[rel tree2]
 lea rcx,[rel budget]
 lea r8,[rel tree_budget]
 call set_parse_request
 lea rdi,[rel parse_request_budget]
 call neboc_incremental_parser_parse
 test eax,eax
 jne .fail40
 cmp qword [rel tree_budget+NEBOC_TREE_FALLBACK_OFFSET],NEBOC_INCREMENTAL_FALLBACK_BUDGET
 jne .fail41
 cmp qword [rel tree_budget+NEBOC_TREE_REUSED_OFFSET],0
 jne .fail42
 mov rax,[rel tree_budget+NEBOC_TREE_TOKEN_DIGEST_OFFSET]
 cmp rax,[rel tree3+NEBOC_TREE_TOKEN_DIGEST_OFFSET]
 jne .fail43

 ; Stale and overlapping edits reject without publishing a result.
 lea rsi,[rel edit]
 lea rdi,[rel stale_edit]
 mov ecx,NEBOC_EDIT_SIZE/8
 rep movsq
 mov qword [rel stale_edit+NEBOC_EDIT_BASE_REVISION_OFFSET],0
 lea rdi,[rel invalid_request]
 lea rsi,[rel snapshot2]
 lea rdx,[rel lex1]
 lea rcx,[rel stale_edit]
 mov r8d,1
 lea r9,[rel tokens2_cold]
 lea rax,[rel invalid_lex]
 push rax
 call set_lex_request
 add rsp,8
 mov qword [rel invalid_lex+NEBOC_LEX_RESULT_ACTIVE_OFFSET],0x77
 lea rdi,[rel invalid_request]
 call neboc_incremental_lexer_lex
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail44
 cmp qword [rel invalid_lex+NEBOC_LEX_RESULT_ACTIVE_OFFSET],0x77
 jne .fail45
 lea rdi,[rel overlap_edits]
 lea rsi,[rel snapshot1]
 mov edx,6
 mov ecx,10
 lea r8,[rel replacement]
 mov r9d,5
 call neboc_text_edit_new
 test eax,eax
 jne .fail46
 lea rdi,[rel overlap_edits+NEBOC_EDIT_SIZE]
 lea rsi,[rel snapshot1]
 mov edx,9
 mov ecx,11
 lea r8,[rel replacement]
 mov r9d,5
 call neboc_text_edit_new
 test eax,eax
 jne .fail47
 mov rax,[rel invalid_request+NEBOC_LEX_REQUEST_RESULT_OFFSET]
 mov qword [rax+NEBOC_LEX_RESULT_ACTIVE_OFFSET],0x66
 lea rax,[rel overlap_edits]
 mov [rel invalid_request+NEBOC_LEX_REQUEST_EDITS_OFFSET],rax
 mov qword [rel invalid_request+NEBOC_LEX_REQUEST_EDIT_COUNT_OFFSET],2
 lea rdi,[rel invalid_request]
 call neboc_incremental_lexer_lex
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail48
 cmp qword [rel invalid_lex+NEBOC_LEX_RESULT_ACTIVE_OFFSET],0x66
 jne .fail49

 ; Compaction preserves the latest snapshot and any live handle.
 lea rax,[rel snapshot1]
 mov [rel snapshot_list],rax
 lea rax,[rel snapshot2]
 mov [rel snapshot_list+8],rax
 lea rax,[rel snapshot3]
 mov [rel snapshot_list+16],rax
 mov qword [rel snapshot1+NEBOC_SNAPSHOT_HANDLES_OFFSET],1
 lea rdi,[rel snapshot_list]
 mov esi,3
 mov edx,1
 xor ecx,ecx
 lea r8,[rel compact_report]
 call neboc_snapshot_compact
 test eax,eax
 jne .fail50
 cmp qword [rel compact_report+NEBOC_COMPACT_RETAINED_OFFSET],2
 jne .fail51
 cmp qword [rel compact_report+NEBOC_COMPACT_REMOVED_OFFSET],1
 jne .fail52
 cmp qword [rel compact_report+NEBOC_COMPACT_PROTECTED_OFFSET],1
 jne .fail53
 cmp qword [rel snapshot1+NEBOC_SNAPSHOT_ACTIVE_OFFSET],1
 jne .fail54
 cmp qword [rel snapshot2+NEBOC_SNAPSHOT_ACTIVE_OFFSET],0
 jne .fail55
 cmp qword [rel snapshot3+NEBOC_SNAPSHOT_ACTIVE_OFFSET],1
 jne .fail56

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 56
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
