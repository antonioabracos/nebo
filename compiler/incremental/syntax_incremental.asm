; SYNTAX-INCREMENTAL-F03 bounded immutable snapshots and incremental syntax identities.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/incremental/syntax_incremental.inc"

%define FNV64_OFFSET 0xcbf29ce484222325
%define FNV64_PRIME 0x100000001b3

section .text
NEBOC_ABI_FUNCTION neboc_source_snapshot_new
 ; rdi=context, rsi=file id, rdx=immutable bytes, rcx=length, r8=revision.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp rcx,NEBOC_INCREMENTAL_MAX_SOURCE_BYTES
 ja .limit
 test rcx,rcx
 jz .bytes_ok
 test rdx,rdx
 jz .invalid
.bytes_ok:
 mov rax,FNV64_OFFSET
 mov r10,FNV64_PRIME
 xor r9d,r9d
.digest:
 cmp r9,rcx
 jae .store
 movzx r11d,byte [rdx+r9]
 xor rax,r11
 imul rax,r10
 inc r9
 jmp .digest
.store:
 mov [rdi+NEBOC_SNAPSHOT_FILE_OFFSET],rsi
 mov [rdi+NEBOC_SNAPSHOT_BYTES_OFFSET],rdx
 mov [rdi+NEBOC_SNAPSHOT_LENGTH_OFFSET],rcx
 mov [rdi+NEBOC_SNAPSHOT_REVISION_OFFSET],r8
 mov [rdi+NEBOC_SNAPSHOT_DIGEST_OFFSET],rax
 mov qword [rdi+NEBOC_SNAPSHOT_HANDLES_OFFSET],0
 mov qword [rdi+NEBOC_SNAPSHOT_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_text_edit_new
 ; rdi=edit, rsi=base snapshot, rdx=start, rcx=end, r8=replacement, r9=length.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_SNAPSHOT_ACTIVE_OFFSET],1
 jne .invalid
 cmp rdx,rcx
 ja .invalid
 cmp rcx,[rsi+NEBOC_SNAPSHOT_LENGTH_OFFSET]
 ja .invalid
 cmp r9,NEBOC_INCREMENTAL_MAX_SOURCE_BYTES
 ja .limit
 test r9,r9
 jz .replacement_ok
 test r8,r8
 jz .invalid
.replacement_ok:
 mov rax,[rsi+NEBOC_SNAPSHOT_FILE_OFFSET]
 mov [rdi+NEBOC_EDIT_FILE_OFFSET],rax
 mov rax,[rsi+NEBOC_SNAPSHOT_REVISION_OFFSET]
 mov [rdi+NEBOC_EDIT_BASE_REVISION_OFFSET],rax
 mov [rdi+NEBOC_EDIT_START_OFFSET],rdx
 mov [rdi+NEBOC_EDIT_END_OFFSET],rcx
 mov [rdi+NEBOC_EDIT_REPLACEMENT_OFFSET],r8
 mov [rdi+NEBOC_EDIT_REPLACEMENT_LENGTH_OFFSET],r9
 mov qword [rdi+NEBOC_EDIT_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_incremental_lexer_lex
 ; rdi=request; output token storage is caller-owned and preflighted.
 test rdi,rdi
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,[rbx+NEBOC_LEX_REQUEST_SNAPSHOT_OFFSET]
 test r12,r12
 jz .invalid
 cmp qword [r12+NEBOC_SNAPSHOT_ACTIVE_OFFSET],1
 jne .invalid
 mov r13,[rbx+NEBOC_LEX_REQUEST_TOKENS_OFFSET]
 mov r14,[rbx+NEBOC_LEX_REQUEST_TOKEN_CAPACITY_OFFSET]
 mov r15,[rbx+NEBOC_LEX_REQUEST_RESULT_OFFSET]
 test r15,r15
 jz .invalid
 cmp r14,NEBOC_INCREMENTAL_MAX_TOKENS
 ja .limit
 mov rax,[r12+NEBOC_SNAPSHOT_LENGTH_OFFSET]
 cmp rax,NEBOC_INCREMENTAL_MAX_SOURCE_BYTES
 ja .limit
 mov [rsp+24],rax
 mov [rsp+32],rax
 mov qword [rsp+40],NEBOC_INCREMENTAL_FALLBACK_NONE
 mov rax,[rbx+NEBOC_LEX_REQUEST_PREVIOUS_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_LEX_REQUEST_EDITS_OFFSET]
 mov [rsp+8],rax
 mov rax,[rbx+NEBOC_LEX_REQUEST_EDIT_COUNT_OFFSET]
 mov [rsp+16],rax
 cmp rax,NEBOC_INCREMENTAL_MAX_EDITS
 ja .limit
 mov rdi,[rsp]
 test rdi,rdi
 jnz .validate_previous
 cmp qword [rsp+16],0
 jne .invalid_source
 mov qword [rsp+24],0
 mov rax,[r12+NEBOC_SNAPSHOT_LENGTH_OFFSET]
 mov [rsp+32],rax
 mov qword [rsp+40],NEBOC_INCREMENTAL_FALLBACK_COLD
 jmp .count_tokens
.validate_previous:
 cmp qword [rdi+NEBOC_LEX_RESULT_ACTIVE_OFFSET],1
 jne .invalid_source
 mov rax,[rdi+NEBOC_LEX_RESULT_SNAPSHOT_OFFSET]
 test rax,rax
 jz .invalid_source
 mov rcx,[rax+NEBOC_SNAPSHOT_FILE_OFFSET]
 cmp rcx,[r12+NEBOC_SNAPSHOT_FILE_OFFSET]
 jne .invalid_source
 mov rcx,[rdi+NEBOC_LEX_RESULT_REVISION_OFFSET]
 cmp rcx,[r12+NEBOC_SNAPSHOT_REVISION_OFFSET]
 jae .invalid_source
 cmp qword [rsp+16],0
 je .no_edits
 cmp qword [rsp+8],0
 je .invalid
 mov qword [rsp+24],-1
 mov qword [rsp+32],0
 xor r11d,r11d
 xor ecx,ecx
.validate_edits:
 cmp rcx,[rsp+16]
 jae .edit_ranges_ready
 imul rax,rcx,NEBOC_EDIT_SIZE
 add rax,[rsp+8]
 cmp qword [rax+NEBOC_EDIT_ACTIVE_OFFSET],1
 jne .invalid_source
 mov rdx,[rax+NEBOC_EDIT_FILE_OFFSET]
 cmp rdx,[r12+NEBOC_SNAPSHOT_FILE_OFFSET]
 jne .invalid_source
 mov rdx,[rax+NEBOC_EDIT_BASE_REVISION_OFFSET]
 cmp rdx,[rdi+NEBOC_LEX_RESULT_REVISION_OFFSET]
 jne .invalid_source
 mov rdx,[rax+NEBOC_EDIT_START_OFFSET]
 mov r8,[rax+NEBOC_EDIT_END_OFFSET]
 cmp rdx,r8
 ja .invalid_source
 cmp r8,[rdi+NEBOC_LEX_RESULT_SOURCE_LENGTH_OFFSET]
 ja .invalid_source
 cmp rdx,r11
 jb .invalid_source
 mov r11,r8
 cmp rdx,[rsp+24]
 jae .start_done
 mov [rsp+24],rdx
.start_done:
 mov r9,[rax+NEBOC_EDIT_REPLACEMENT_LENGTH_OFFSET]
 test r9,r9
 jz .replacement_valid
 cmp qword [rax+NEBOC_EDIT_REPLACEMENT_OFFSET],0
 je .invalid_source
.replacement_valid:
 add r9,rdx
 jc .limit
 cmp r8,r9
 cmova r9,r8
 cmp r9,[rsp+32]
 jbe .end_done
 mov [rsp+32],r9
.end_done:
 inc rcx
 jmp .validate_edits
.edit_ranges_ready:
 mov rax,[r12+NEBOC_SNAPSHOT_LENGTH_OFFSET]
 cmp [rsp+32],rax
 jbe .count_tokens
 mov [rsp+32],rax
 jmp .count_tokens
.no_edits:
 mov rax,[r12+NEBOC_SNAPSHOT_LENGTH_OFFSET]
 mov [rsp+24],rax
 mov [rsp+32],rax
.count_tokens:
 mov r8,[r12+NEBOC_SNAPSHOT_BYTES_OFFSET]
 mov r9,[r12+NEBOC_SNAPSHOT_LENGTH_OFFSET]
 xor eax,eax
 xor ecx,ecx
.count_skip:
 cmp rcx,r9
 jae .count_done
 movzx edx,byte [r8+rcx]
 cmp dl,32
 ja .count_word
 inc rcx
 jmp .count_skip
.count_word:
 inc rax
.count_word_loop:
 inc rcx
 cmp rcx,r9
 jae .count_done
 movzx edx,byte [r8+rcx]
 cmp dl,32
 ja .count_word_loop
 jmp .count_skip
.count_done:
 cmp rax,NEBOC_INCREMENTAL_MAX_TOKENS
 ja .limit
 cmp rax,r14
 ja .limit
 test rax,rax
 jz .storage_ready
 test r13,r13
 jz .invalid
.storage_ready:
 xor ebx,ebx
 xor r10d,r10d
 xor ecx,ecx
.fill_skip:
 cmp rcx,r9
 jae .fill_done
 movzx edx,byte [r8+rcx]
 cmp dl,32
 ja .fill_word
 inc rcx
 jmp .fill_skip
.fill_word:
 mov rdx,rcx
.fill_word_loop:
 inc rcx
 cmp rcx,r9
 jae .word_end
 movzx eax,byte [r8+rcx]
 cmp al,32
 ja .fill_word_loop
.word_end:
 mov rsi,rcx
 sub rsi,rdx
 mov rax,FNV64_OFFSET
 mov r11,FNV64_PRIME
 xor edi,edi
.token_digest:
 cmp rdi,rsi
 jae .token_digest_done
 mov r9,rdx
 add r9,rdi
 movzx r9d,byte [r8+r9]
 xor rax,r9
 imul rax,r11
 inc rdi
 jmp .token_digest
.token_digest_done:
 mov rdi,r10
 shl rdi,5
 add rdi,r13
 mov [rdi+NEBOC_SYNTAX_INCREMENTAL_TOKEN_START_OFFSET],rdx
 mov [rdi+NEBOC_TOKEN_LENGTH_OFFSET],rsi
 mov [rdi+NEBOC_TOKEN_DIGEST_OFFSET],rax
 lea r11,[r10+1]
 mov [rdi+NEBOC_TOKEN_STABLE_ID_OFFSET],r11
 mov r11,[rsp]
 test r11,r11
 jz .token_rebuilt
 cmp r10,[r11+NEBOC_LEX_RESULT_TOKEN_COUNT_OFFSET]
 jae .token_rebuilt
 cmp rcx,[rsp+24]
 jbe .outside_change
 cmp rdx,[rsp+32]
 jb .token_rebuilt
.outside_change:
 mov r9,r10
 shl r9,5
 add r9,[r11+NEBOC_LEX_RESULT_TOKENS_OFFSET]
 cmp rsi,[r9+NEBOC_TOKEN_LENGTH_OFFSET]
 jne .token_rebuilt
 cmp rax,[r9+NEBOC_TOKEN_DIGEST_OFFSET]
 jne .token_rebuilt
 mov rax,[r9+NEBOC_TOKEN_STABLE_ID_OFFSET]
 mov [rdi+NEBOC_TOKEN_STABLE_ID_OFFSET],rax
 inc rbx
.token_rebuilt:
 inc r10
 mov r8,[r12+NEBOC_SNAPSHOT_BYTES_OFFSET]
 mov r9,[r12+NEBOC_SNAPSHOT_LENGTH_OFFSET]
 jmp .fill_skip
.fill_done:
 mov [r15+NEBOC_LEX_RESULT_SNAPSHOT_OFFSET],r12
 mov [r15+NEBOC_LEX_RESULT_TOKENS_OFFSET],r13
 mov [r15+NEBOC_LEX_RESULT_TOKEN_COUNT_OFFSET],r10
 mov [r15+NEBOC_LEX_RESULT_REUSED_OFFSET],rbx
 mov rax,r10
 sub rax,rbx
 mov [r15+NEBOC_LEX_RESULT_REBUILT_OFFSET],rax
 mov rax,[rsp+24]
 mov [r15+NEBOC_LEX_RESULT_CHANGED_START_OFFSET],rax
 mov rax,[rsp+32]
 mov [r15+NEBOC_LEX_RESULT_CHANGED_END_OFFSET],rax
 mov rax,[r12+NEBOC_SNAPSHOT_DIGEST_OFFSET]
 mov [r15+NEBOC_LEX_RESULT_SOURCE_DIGEST_OFFSET],rax
 mov rax,[r12+NEBOC_SNAPSHOT_LENGTH_OFFSET]
 mov [r15+NEBOC_LEX_RESULT_SOURCE_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_SNAPSHOT_REVISION_OFFSET]
 mov [r15+NEBOC_LEX_RESULT_REVISION_OFFSET],rax
 mov rax,[rsp+40]
 mov [r15+NEBOC_LEX_RESULT_FALLBACK_OFFSET],rax
 mov qword [r15+NEBOC_LEX_RESULT_ACTIVE_OFFSET],1
 xor eax,eax
 jmp .done
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_incremental_parser_parse
 ; rdi=request containing lex result, optional previous tree, budget and output.
 test rdi,rdi
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,[rdi+NEBOC_PARSE_REQUEST_LEX_OFFSET]
 mov r12,[rdi+NEBOC_PARSE_REQUEST_PREVIOUS_OFFSET]
 mov r13,[rdi+NEBOC_PARSE_REQUEST_BUDGET_OFFSET]
 mov r14,[rdi+NEBOC_PARSE_REQUEST_TREE_OFFSET]
 test rbx,rbx
 jz .invalid_saved
 test r13,r13
 jz .invalid_saved
 test r14,r14
 jz .invalid_saved
 cmp qword [rbx+NEBOC_LEX_RESULT_ACTIVE_OFFSET],1
 jne .invalid_saved
 cmp qword [r13+NEBOC_INCREMENTAL_BUDGET_ACTIVE_OFFSET],1
 jne .invalid_saved
 test r12,r12
 jz .previous_ok
 cmp qword [r12+NEBOC_TREE_ACTIVE_OFFSET],1
 jne .invalid_source
 mov rax,[r12+NEBOC_TREE_REVISION_OFFSET]
 cmp rax,[rbx+NEBOC_LEX_RESULT_REVISION_OFFSET]
 jae .invalid_source
.previous_ok:
 mov r15,FNV64_OFFSET
 mov r11,FNV64_PRIME
 xor ecx,ecx
 mov r8,[rbx+NEBOC_LEX_RESULT_TOKENS_OFFSET]
.digest:
 cmp rcx,[rbx+NEBOC_LEX_RESULT_TOKEN_COUNT_OFFSET]
 jae .digest_done
 mov rax,rcx
 shl rax,5
 lea r9,[r8+rax]
 xor r15,[r9+NEBOC_TOKEN_DIGEST_OFFSET]
 imul r15,r11
 xor r15,[r9+NEBOC_TOKEN_LENGTH_OFFSET]
 imul r15,r11
 inc rcx
 jmp .digest
.digest_done:
 mov r9,[rbx+NEBOC_LEX_RESULT_TOKEN_COUNT_OFFSET]
 inc r9
 cmp r9,NEBOC_INCREMENTAL_MAX_NODES
 ja .limit
 mov r10,[rbx+NEBOC_LEX_RESULT_FALLBACK_OFFSET]
 cmp r9,[r13+NEBOC_INCREMENTAL_BUDGET_NODES_OFFSET]
 ja .budget_fallback
 mov rax,[rbx+NEBOC_LEX_RESULT_SOURCE_LENGTH_OFFSET]
 cmp rax,[r13+NEBOC_INCREMENTAL_BUDGET_BYTES_OFFSET]
 ja .budget_fallback
 jmp .reuse
.budget_fallback:
 mov r10,NEBOC_INCREMENTAL_FALLBACK_BUDGET
.reuse:
 xor edx,edx
 mov rcx,r9
 test r12,r12
 jz .cold
 cmp r10,NEBOC_INCREMENTAL_FALLBACK_NONE
 jne .cold
 cmp r15,[r12+NEBOC_TREE_TOKEN_DIGEST_OFFSET]
 jne .partial_reuse
 cmp r9,[r12+NEBOC_TREE_NODE_COUNT_OFFSET]
 jne .partial_reuse
 mov rdx,r9
 xor ecx,ecx
 jmp .write
.partial_reuse:
 mov rdx,[rbx+NEBOC_LEX_RESULT_REUSED_OFFSET]
 cmp rdx,r9
 jbe .partial_count
 mov rdx,r9
.partial_count:
 mov rcx,r9
 sub rcx,rdx
 jmp .write
.cold:
 test r10,r10
 jnz .cold_reason_ready
 mov r10,NEBOC_INCREMENTAL_FALLBACK_COLD
.cold_reason_ready:
 xor edx,edx
 mov rcx,r9
.write:
 mov rax,[rbx+NEBOC_LEX_RESULT_SOURCE_DIGEST_OFFSET]
 mov [r14+NEBOC_TREE_SOURCE_DIGEST_OFFSET],rax
 mov [r14+NEBOC_TREE_TOKEN_DIGEST_OFFSET],r15
 mov [r14+NEBOC_TREE_NODE_COUNT_OFFSET],r9
 mov [r14+NEBOC_TREE_REUSED_OFFSET],rdx
 mov [r14+NEBOC_TREE_REBUILT_OFFSET],rcx
 mov rax,[rbx+NEBOC_LEX_RESULT_CHANGED_START_OFFSET]
 mov [r14+NEBOC_TREE_CHANGED_START_OFFSET],rax
 mov rax,[rbx+NEBOC_LEX_RESULT_CHANGED_END_OFFSET]
 mov [r14+NEBOC_TREE_CHANGED_END_OFFSET],rax
 mov rax,[rbx+NEBOC_LEX_RESULT_REVISION_OFFSET]
 mov [r14+NEBOC_TREE_REVISION_OFFSET],rax
 mov [r14+NEBOC_TREE_FALLBACK_OFFSET],r10
 mov qword [r14+NEBOC_TREE_ACTIVE_OFFSET],1
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_syntax_tree_changed_ranges
 ; rdi=current tree, rsi=previous tree, rdx=single bounded range output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdi+NEBOC_TREE_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rsi+NEBOC_TREE_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_TREE_TOKEN_DIGEST_OFFSET]
 cmp rax,[rsi+NEBOC_TREE_TOKEN_DIGEST_OFFSET]
 jne .changed
 mov qword [rdx+NEBOC_CHANGED_START_OFFSET],0
 mov qword [rdx+NEBOC_CHANGED_END_OFFSET],0
 mov qword [rdx+NEBOC_CHANGED_COUNT_OFFSET],0
 xor eax,eax
 ret
.changed:
 mov rax,[rdi+NEBOC_TREE_CHANGED_START_OFFSET]
 mov [rdx+NEBOC_CHANGED_START_OFFSET],rax
 mov rax,[rdi+NEBOC_TREE_CHANGED_END_OFFSET]
 mov [rdx+NEBOC_CHANGED_END_OFFSET],rax
 mov qword [rdx+NEBOC_CHANGED_COUNT_OFFSET],1
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_syntax_tree_reuse_report
 ; rdi=lexer result, rsi=tree, rdx=report output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdi+NEBOC_LEX_RESULT_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rsi+NEBOC_TREE_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_LEX_RESULT_REVISION_OFFSET]
 cmp rax,[rsi+NEBOC_TREE_REVISION_OFFSET]
 jne .source
 mov rax,[rdi+NEBOC_LEX_RESULT_REUSED_OFFSET]
 mov [rdx+NEBOC_REUSE_TOKENS_REUSED_OFFSET],rax
 mov rax,[rdi+NEBOC_LEX_RESULT_REBUILT_OFFSET]
 mov [rdx+NEBOC_REUSE_TOKENS_REBUILT_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_REUSED_OFFSET]
 mov [rdx+NEBOC_REUSE_NODES_REUSED_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_REBUILT_OFFSET]
 mov [rdx+NEBOC_REUSE_NODES_REBUILT_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_FALLBACK_OFFSET]
 mov [rdx+NEBOC_REUSE_FALLBACK_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_REVISION_OFFSET]
 mov [rdx+NEBOC_REUSE_REVISION_OFFSET],rax
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_syntax_tree_validate_against_cold_parse
 ; rdi=lexer result, rsi=tree.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_LEX_RESULT_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rsi+NEBOC_TREE_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,FNV64_OFFSET
 mov r11,FNV64_PRIME
 xor ecx,ecx
 mov r8,[rdi+NEBOC_LEX_RESULT_TOKENS_OFFSET]
.digest:
 cmp rcx,[rdi+NEBOC_LEX_RESULT_TOKEN_COUNT_OFFSET]
 jae .compare
 mov rdx,rcx
 shl rdx,5
 lea r9,[r8+rdx]
 xor rax,[r9+NEBOC_TOKEN_DIGEST_OFFSET]
 imul rax,r11
 xor rax,[r9+NEBOC_TOKEN_LENGTH_OFFSET]
 imul rax,r11
 inc rcx
 jmp .digest
.compare:
 cmp rax,[rsi+NEBOC_TREE_TOKEN_DIGEST_OFFSET]
 jne .source
 mov rax,[rdi+NEBOC_LEX_RESULT_SOURCE_DIGEST_OFFSET]
 cmp rax,[rsi+NEBOC_TREE_SOURCE_DIGEST_OFFSET]
 jne .source
 mov rax,[rdi+NEBOC_LEX_RESULT_REVISION_OFFSET]
 cmp rax,[rsi+NEBOC_TREE_REVISION_OFFSET]
 jne .source
 mov rax,[rdi+NEBOC_LEX_RESULT_TOKEN_COUNT_OFFSET]
 inc rax
 cmp rax,[rsi+NEBOC_TREE_NODE_COUNT_OFFSET]
 jne .source
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_snapshot_compact
 ; rdi=snapshot pointer array, rsi=count, rdx=latest count to retain,
 ; rcx=protected revision (zero for none), r8=report output.
 test r8,r8
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_INCREMENTAL_MAX_SNAPSHOTS
 ja .limit
 test rdx,rdx
 jz .invalid
 cmp rdx,rsi
 ja .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 xor ecx,ecx
 xor r11d,r11d
.validate:
 cmp rcx,r12
 jae .validated
 mov rdi,[rbx+rcx*8]
 test rdi,rdi
 jz .invalid_saved
 cmp qword [rdi+NEBOC_SNAPSHOT_ACTIVE_OFFSET],1
 ja .invalid_saved
 cmp qword [rdi+NEBOC_SNAPSHOT_REVISION_OFFSET],0
 je .invalid_saved
 test rcx,rcx
 jnz .file_match
 mov r11,[rdi+NEBOC_SNAPSHOT_FILE_OFFSET]
.file_match:
 cmp r11,[rdi+NEBOC_SNAPSHOT_FILE_OFFSET]
 jne .invalid_source
 lea r9,[rcx+1]
.unique:
 cmp r9,r12
 jae .next_validate
 mov rax,[rbx+r9*8]
 test rax,rax
 jz .invalid_saved
 mov rdx,[rdi+NEBOC_SNAPSHOT_REVISION_OFFSET]
 cmp rdx,[rax+NEBOC_SNAPSHOT_REVISION_OFFSET]
 je .invalid_source
 inc r9
 jmp .unique
.next_validate:
 inc rcx
 jmp .validate
.validated:
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 xor ecx,ecx
.compact:
 cmp rcx,r12
 jae .write
 mov rdi,[rbx+rcx*8]
 cmp qword [rdi+NEBOC_SNAPSHOT_ACTIVE_OFFSET],1
 jne .next
 cmp qword [rdi+NEBOC_SNAPSHOT_HANDLES_OFFSET],0
 jne .protected
 test r14,r14
 jz .rank
 cmp r14,[rdi+NEBOC_SNAPSHOT_REVISION_OFFSET]
 je .protected
.rank:
 xor edx,edx
 xor r11d,r11d
.newer:
 cmp r11,r12
 jae .rank_ready
 mov rax,[rbx+r11*8]
 cmp qword [rax+NEBOC_SNAPSHOT_ACTIVE_OFFSET],1
 jne .newer_next
 mov rax,[rax+NEBOC_SNAPSHOT_REVISION_OFFSET]
 cmp rax,[rdi+NEBOC_SNAPSHOT_REVISION_OFFSET]
 jbe .newer_next
 inc rdx
.newer_next:
 inc r11
 jmp .newer
.rank_ready:
 cmp rdx,r13
 jb .retain
 mov qword [rdi+NEBOC_SNAPSHOT_ACTIVE_OFFSET],0
 inc r9
 jmp .next
.protected:
 inc r10
.retain:
 inc r8
.next:
 inc rcx
 jmp .compact
.write:
 mov [r15+NEBOC_COMPACT_RETAINED_OFFSET],r8
 mov [r15+NEBOC_COMPACT_REMOVED_OFFSET],r9
 mov [r15+NEBOC_COMPACT_PROTECTED_OFFSET],r10
 xor eax,eax
 jmp .done
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_incremental_parser_set_budget
 ; rdi=budget, rsi=max nodes, rdx=max source bytes, rcx=time units.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,NEBOC_INCREMENTAL_MAX_NODES
 ja .limit
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_INCREMENTAL_MAX_SOURCE_BYTES
 ja .limit
 test rcx,rcx
 jz .invalid
 mov [rdi+NEBOC_INCREMENTAL_BUDGET_NODES_OFFSET],rsi
 mov [rdi+NEBOC_INCREMENTAL_BUDGET_BYTES_OFFSET],rdx
 mov [rdi+NEBOC_INCREMENTAL_BUDGET_TIME_OFFSET],rcx
 mov qword [rdi+NEBOC_INCREMENTAL_BUDGET_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_incremental_report
 ; rdi=lexer result, rsi=tree, rdx=summary output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdi+NEBOC_LEX_RESULT_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rsi+NEBOC_TREE_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_LEX_RESULT_REVISION_OFFSET]
 cmp rax,[rsi+NEBOC_TREE_REVISION_OFFSET]
 jne .source
 mov [rdx+NEBOC_INCREMENTAL_REPORT_REVISION_OFFSET],rax
 mov rax,[rdi+NEBOC_LEX_RESULT_TOKEN_COUNT_OFFSET]
 mov [rdx+NEBOC_INCREMENTAL_REPORT_TOKENS_OFFSET],rax
 mov rax,[rdi+NEBOC_LEX_RESULT_REUSED_OFFSET]
 mov [rdx+NEBOC_INCREMENTAL_REPORT_TOKENS_REUSED_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_NODE_COUNT_OFFSET]
 mov [rdx+NEBOC_INCREMENTAL_REPORT_NODES_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_REUSED_OFFSET]
 mov [rdx+NEBOC_INCREMENTAL_REPORT_NODES_REUSED_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_CHANGED_START_OFFSET]
 mov [rdx+NEBOC_INCREMENTAL_REPORT_CHANGED_START_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_CHANGED_END_OFFSET]
 mov [rdx+NEBOC_INCREMENTAL_REPORT_CHANGED_END_OFFSET],rax
 mov rax,[rsi+NEBOC_TREE_FALLBACK_OFFSET]
 mov [rdx+NEBOC_INCREMENTAL_REPORT_FALLBACK_OFFSET],rax
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_check_cold
 ; rdi=lexer request, rsi=parse request. Force an explicit cold reference.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push rbx
 push r12
 push r13
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rsp
 mov rsi,rbx
 mov rdi,r13
 mov ecx,NEBOC_LEX_REQUEST_SIZE/8
 rep movsq
 mov qword [r13+NEBOC_LEX_REQUEST_PREVIOUS_OFFSET],0
 mov qword [r13+NEBOC_LEX_REQUEST_EDITS_OFFSET],0
 mov qword [r13+NEBOC_LEX_REQUEST_EDIT_COUNT_OFFSET],0
 mov rdi,r13
 call neboc_incremental_lexer_lex
 test eax,eax
 jnz .done
 mov rdi,r12
 call neboc_incremental_parser_parse
.done:
 add rsp,64
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_check_incremental
 ; rdi=lexer request, rsi=parse request.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 call neboc_incremental_lexer_lex
 test eax,eax
 jnz .done
 mov rdi,r12
 call neboc_incremental_parser_parse
.done:
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
