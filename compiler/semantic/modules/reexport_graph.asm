; G152 bounded explicit reexport graph and public API impact.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/selective_import_parser.inc"
%include "compiler/parser/module_parser.inc"

section .text

; Resolve an exported value through explicit selective reexport edges.
; rdi=request, rsi=unit index, rdx=SymbolId. Success: eax=0,
; rdx=original declaration record, ecx=owner index. Failure: eax=status,
; edx=module diagnostic. The canonical records and ImportAst are read only;
; a facade never acquires a second declaration or a copied SymbolId.
NEBOC_ABI_FUNCTION neboc_module_resolve_export
 test rdi,rdi
 jz .argument
 cmp rsi,NEBOC_MODULE_MAX_UNITS
 jae .argument
 test rdx,rdx
 jz .missing
 mov r8,rdi
 mov r9,[r8+NEBOC_MODULE_RECORDS_OFFSET]
 test r9,r9
 jz .argument
 mov r10,rsi
 mov r11,rdx
 xor edi,edi                    ; visited unit bits; bit 63 means reexport
.visit:
 bts rdi,r10
 jc .cycle
 mov rdx,r10
 shl rdx,7
 add rdx,r9
 test qword [rdx+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_EXPORT
 jz .facade
 cmp r11,[rdx+NEBOC_MODULE_RECORD_EXPORT_HASH_OFFSET]
 jne .facade
 bt rdi,63
 jnc .found
 cmp qword [rdx+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_PUBLIC
 jne .visibility
.found:
 mov ecx,r10d
 xor eax,eax
 ret
.facade:
 test qword [rdx+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_REEXPORT
 jz .missing
 mov rsi,[r8+NEBOC_MODULE_IMPORT_ASTS_OFFSET]
 test rsi,rsi
 jz .argument
 mov rax,r10
 imul rax,NEBOC_IMPORT_AST_SIZE
 add rsi,rax
 cmp qword [rsi+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne .missing
 test qword [rsi+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_EXPORT
 jz .missing
 xor ecx,ecx
.selected:
 cmp rcx,[rsi+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET]
 jae .missing
 cmp rcx,NEBOC_SELECTIVE_MAX
 jae .argument
 cmp r11,[rsi+rcx*8+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET]
 je .target
 inc ecx
 jmp .selected
.target:
 mov rax,[rsi+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 xor r10d,r10d
.find:
 cmp r10,NEBOC_MODULE_MAX_UNITS
 jae .missing_unit
 mov rdx,r10
 shl rdx,7
 cmp rax,[r9+rdx+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 je .follow
 inc r10
 jmp .find
.follow:
 bts rdi,63
 jmp .visit
.visibility:
 mov edx,NEBOC_MODULE_DIAG_REEXPORT_VISIBILITY
 jmp .failure
.cycle:
 mov edx,NEBOC_MODULE_DIAG_IMPORT_CYCLE
 jmp .failure
.missing_unit:
 mov edx,neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_MISSING_UNIT
 jmp .failure
.missing:
 mov edx,NEBOC_MODULE_DIAG_MISSING_EXPORT
.failure:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 mov edx,NEBOC_MODULE_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; ReexportGraph.init(graph, edge_storage, capacity)
NEBOC_ABI_FUNCTION neboc_reexport_graph_init
 test rdi,rdi
 jz .argument
 test rsi,rsi
 jz .argument
 test rdi,7
 jnz .argument
 test rsi,7
 jnz .argument
 test rdx,rdx
 jz .source
 cmp rdx,NEBOC_SELECTIVE_MAX
 ja .limit
 mov [rdi+NEBOC_REEXPORT_GRAPH_EDGES_OFFSET],rsi
 mov qword [rdi+NEBOC_REEXPORT_GRAPH_COUNT_OFFSET],0
 mov [rdi+NEBOC_REEXPORT_GRAPH_CAPACITY_OFFSET],rdx
 mov rax,14695981039346656037
 mov [rdi+NEBOC_REEXPORT_GRAPH_DIGEST_OFFSET],rax
 mov rdi,rsi
 imul rcx,rdx,NEBOC_REEXPORT_EDGE_SIZE/8
 xor eax,eax
 rep stosq
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; ReexportGraph.add(graph, candidate_edge). Only explicit public edges are
; admitted. Duplicate public names and a reverse reachable edge fail closed.
NEBOC_ABI_FUNCTION neboc_reexport_graph_add
 test rdi,rdi
 jz .argument
 test rsi,rsi
 jz .argument
 test rdi,7
 jnz .argument
 test rsi,7
 jnz .argument
 mov r8,[rdi+NEBOC_REEXPORT_GRAPH_EDGES_OFFSET]
 test r8,r8
 jz .source
 mov rcx,[rdi+NEBOC_REEXPORT_GRAPH_COUNT_OFFSET]
 cmp rcx,[rdi+NEBOC_REEXPORT_GRAPH_CAPACITY_OFFSET]
 jae .limit
 mov rax,[rsi+NEBOC_REEXPORT_EDGE_ORIGIN_OFFSET]
 test rax,rax
 jz .source
 cmp rax,[rsi+NEBOC_REEXPORT_EDGE_SOURCE_OFFSET]
 je .source
 cmp qword [rsi+NEBOC_REEXPORT_EDGE_VISIBILITY_OFFSET],NEBOC_VIS_PUBLIC
 jne .source
 mov rax,[rsi+NEBOC_REEXPORT_EDGE_KIND_OFFSET]
 cmp rax,NEBOC_NAMESPACE_TYPE
 jb .source
 cmp rax,NEBOC_NAMESPACE_MODULE
 ja .source
 test qword [rsi+NEBOC_REEXPORT_EDGE_SYMBOL_OFFSET],-1
 jz .source
 xor edx,edx
.scan:
 cmp rdx,rcx
 jae .copy
 mov r9,rdx
 imul r9,NEBOC_REEXPORT_EDGE_SIZE
 lea r10,[r8+r9]
 mov rax,[r10+NEBOC_REEXPORT_EDGE_SYMBOL_OFFSET]
 cmp rax,[rsi+NEBOC_REEXPORT_EDGE_SYMBOL_OFFSET]
 jne .cycle
 mov rax,[r10+NEBOC_REEXPORT_EDGE_KIND_OFFSET]
 cmp rax,[rsi+NEBOC_REEXPORT_EDGE_KIND_OFFSET]
 je .source                         ; duplicate exported identity
.cycle:
 mov rax,[r10+NEBOC_REEXPORT_EDGE_ORIGIN_OFFSET]
 cmp rax,[rsi+NEBOC_REEXPORT_EDGE_SOURCE_OFFSET]
 jne .next
 mov rax,[r10+NEBOC_REEXPORT_EDGE_SOURCE_OFFSET]
 cmp rax,[rsi+NEBOC_REEXPORT_EDGE_ORIGIN_OFFSET]
 je .source                         ; bounded two-way cycle
.next:
 inc rdx
 jmp .scan
.copy:
 mov r9,rcx
 imul r9,NEBOC_REEXPORT_EDGE_SIZE
 add r9,r8
 mov r10,14695981039346656037
 mov r11,1099511628211
 xor edx,edx
.copy_qword:
 cmp edx,5
 jae .publish
 mov rax,[rsi+rdx*8]
 mov [r9+rdx*8],rax
 xor r10,rax
 imul r10,r11
 inc rdx
 jmp .copy_qword
.publish:
 test r10,r10
 jnz .digest_ready
 mov r10,1
.digest_ready:
 mov [r9+NEBOC_REEXPORT_EDGE_DIGEST_OFFSET],r10
 xor [rdi+NEBOC_REEXPORT_GRAPH_DIGEST_OFFSET],r10
 inc qword [rdi+NEBOC_REEXPORT_GRAPH_COUNT_OFFSET]
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; imports.publicApiImpact(graph, baseline_digest, out_report)
NEBOC_ABI_FUNCTION neboc_imports_public_api_impact
 test rdi,rdi
 jz .argument
 test rdx,rdx
 jz .argument
 mov qword [rdx+NEBOC_API_IMPACT_ADDED_OFFSET],0
 mov qword [rdx+NEBOC_API_IMPACT_REMOVED_OFFSET],0
 mov qword [rdx+NEBOC_API_IMPACT_AMBIGUOUS_OFFSET],0
 mov qword [rdx+NEBOC_API_IMPACT_BREAKING_OFFSET],0
 mov qword [rdx+NEBOC_API_IMPACT_DIGEST_OFFSET],0
 mov rax,[rdi+NEBOC_REEXPORT_GRAPH_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_REEXPORT_GRAPH_CAPACITY_OFFSET]
 ja .source
 mov [rdx+NEBOC_API_IMPACT_ADDED_OFFSET],rax
 mov rax,[rdi+NEBOC_REEXPORT_GRAPH_DIGEST_OFFSET]
 mov [rdx+NEBOC_API_IMPACT_DIGEST_OFFSET],rax
 test rsi,rsi
 jz .compatible
 cmp rsi,rax
 je .compatible
 mov qword [rdx+NEBOC_API_IMPACT_REMOVED_OFFSET],1
 mov qword [rdx+NEBOC_API_IMPACT_BREAKING_OFFSET],1
.compatible:
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Historical internal name now delegates to the real add operation.
NEBOC_ABI_FUNCTION neboc_reexport_graph
 jmp neboc_reexport_graph_add

section .note.GNU-stack noalloc noexec nowrite progbits
