; G152 revision-bound AutoImportPlan. It produces semantic TextEdits but never
; performs an implicit edit during build/check.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/selective_import_parser.inc"

section .text

; AutoImportPlan.new(plan, snapshot_revision, current_revision, symbol_id,
;                    destination_module, visibility)
NEBOC_ABI_FUNCTION neboc_auto_import_plan
 test rdi,rdi
 jz .argument
 test rdi,7
 jnz .argument
 mov r10,rcx
 push rdi
 mov ecx,NEBOC_AUTO_IMPORT_PLAN_SIZE/8
 xor eax,eax
 rep stosq
 pop rdi
 mov rcx,r10
 test rsi,rsi
 jz .source
 cmp rsi,rdx
 jne .source
 test rcx,rcx
 jz .source
 test r8,r8
 jz .source
 cmp r9,NEBOC_VIS_PUBLIC
 jne .source                         ; private/internal candidates are closed
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_SNAPSHOT_OFFSET],rsi
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_SYMBOL_OFFSET],rcx
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_DESTINATION_OFFSET],r8
 mov qword [rdi+NEBOC_AUTO_IMPORT_PLAN_FLAGS_OFFSET],NEBOC_AUTO_IMPORT_PLAN_VALID|NEBOC_AUTO_IMPORT_PLAN_PUBLIC
 mov rax,14695981039346656037
 mov r11,1099511628211
 xor rax,rsi
 imul rax,r11
 xor rax,rcx
 imul rax,r11
 xor rax,r8
 imul rax,r11
 test rax,rax
 jnz .digest
 mov eax,1
.digest:
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_DIGEST_OFFSET],rax
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Bind one insertion/replacement to the authenticated plan. The edit is
; pointer-bearing only as caller-owned transport; the plan digest never hashes
; the pointer address.
NEBOC_ABI_FUNCTION neboc_auto_import_plan_set_edit
 test rdi,rdi
 jz .argument
 test qword [rdi+NEBOC_AUTO_IMPORT_PLAN_FLAGS_OFFSET],NEBOC_AUTO_IMPORT_PLAN_VALID
 jz .source
 cmp rsi,rdx
 ja .source
 test r8,r8
 jz .source
 test rcx,rcx
 jz .source
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_EDIT_START_OFFSET],rsi
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_EDIT_END_OFFSET],rdx
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_REPLACEMENT_OFFSET],rcx
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_REPLACEMENT_LENGTH_OFFSET],r8
 mov rax,[rdi+NEBOC_AUTO_IMPORT_PLAN_DIGEST_OFFSET]
 xor rax,rsi
 rol rax,13
 xor rax,rdx
 rol rax,13
 xor rax,r8
 mov [rdi+NEBOC_AUTO_IMPORT_PLAN_DIGEST_OFFSET],rax
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; autoImport.edits(plan, current_revision, out_edit)
NEBOC_ABI_FUNCTION neboc_auto_import_edits
 test rdi,rdi
 jz .argument
 test rdx,rdx
 jz .argument
 mov r8,rdi
 mov rdi,rdx
 mov ecx,NEBOC_IMPORT_EDIT_SIZE/8
 xor eax,eax
 rep stosq
 mov rdi,r8
 test qword [rdi+NEBOC_AUTO_IMPORT_PLAN_FLAGS_OFFSET],NEBOC_AUTO_IMPORT_PLAN_VALID
 jz .source
 cmp rsi,[rdi+NEBOC_AUTO_IMPORT_PLAN_SNAPSHOT_OFFSET]
 jne .source
 cmp qword [rdi+NEBOC_AUTO_IMPORT_PLAN_REPLACEMENT_LENGTH_OFFSET],0
 je .source
 mov rax,[rdi+NEBOC_AUTO_IMPORT_PLAN_EDIT_START_OFFSET]
 mov [rdx+NEBOC_IMPORT_EDIT_START_OFFSET],rax
 mov rax,[rdi+NEBOC_AUTO_IMPORT_PLAN_EDIT_END_OFFSET]
 mov [rdx+NEBOC_IMPORT_EDIT_END_OFFSET],rax
 mov rax,[rdi+NEBOC_AUTO_IMPORT_PLAN_REPLACEMENT_OFFSET]
 mov [rdx+NEBOC_IMPORT_EDIT_REPLACEMENT_OFFSET],rax
 mov rax,[rdi+NEBOC_AUTO_IMPORT_PLAN_REPLACEMENT_LENGTH_OFFSET]
 mov [rdx+NEBOC_IMPORT_EDIT_REPLACEMENT_LENGTH_OFFSET],rax
 mov rax,[rdi+NEBOC_AUTO_IMPORT_PLAN_DIGEST_OFFSET]
 mov [rdx+NEBOC_IMPORT_EDIT_DIGEST_OFFSET],rax
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
