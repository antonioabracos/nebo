; ANALYSIS-F01 native read-only analysis substrate oracle.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
global _start
extern neboc_analysis_session_new
extern neboc_analysis_control_flow
extern neboc_analysis_dominators
extern neboc_analysis_use_def
extern neboc_analysis_live_ranges
extern neboc_analysis_data_flow
extern neboc_analysis_effects
extern neboc_analysis_ownership
extern neboc_analysis_call_graph
extern neboc_analysis_cost
extern neboc_analysis_query
extern neboc_host_process_exit

%define SNAPSHOT 0x5200480100000001

section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 100,8,4096,query_cache,4
blocks:
 dq 0,0,1,1
 dq 1,1,2,1
 dq 2,3,1,1
 dq 3,4,2,2
edges:
 dq 0,1,NEBOC_ANALYSIS_EDGE_KNOWN
 dq 0,2,NEBOC_ANALYSIS_EDGE_KNOWN
 dq 1,3,NEBOC_ANALYSIS_EDGE_KNOWN
 dq 2,3,NEBOC_ANALYSIS_EDGE_KNOWN
events:
 dq 10,1,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 11,1,NEBOC_ANALYSIS_EVENT_USE
 dq 12,2,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 13,1,NEBOC_ANALYSIS_EVENT_USE
 dq 14,2,NEBOC_ANALYSIS_EVENT_USE
 dq 15,1,NEBOC_ANALYSIS_EVENT_USE
calls:
 dq 42,43,NEBOC_ANALYSIS_EDGE_KNOWN
 dq 42,0,NEBOC_ANALYSIS_EDGE_UNKNOWN
function: dq SNAPSHOT,42,blocks,4,edges,4,events,6,calls,2
gen_masks: dq 1,2,4,8
kill_masks: dq 0,0,0,0
node: dq SNAPSHOT,99,3,4,2,9,1,2,3,4,5
cost_model: dq 10,20,30,40,50,7
query_key: dq 0x101,SNAPSHOT,0x202,0x303,1

section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
query_cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE*4
cfg: resb NEBOC_ANALYSIS_CFG_SIZE
dom_result: resb NEBOC_ANALYSIS_DOM_SIZE
dom_masks: resq 4
postdom_masks: resq 4
usedef: resb NEBOC_ANALYSIS_USEDEF_SIZE
definitions: resq 4
uses: resq 4
ranges_result: resb NEBOC_ANALYSIS_RANGES_SIZE
ranges: resb NEBOC_ANALYSIS_RANGE_SIZE*4
dataflow: resb NEBOC_ANALYSIS_DATAFLOW_SIZE
flow_in: resq 4
flow_out: resq 4
effect_fact: resb NEBOC_ANALYSIS_FACT_SIZE
ownership_fact: resb NEBOC_ANALYSIS_FACT_SIZE
call_graph: resb NEBOC_ANALYSIS_CALLGRAPH_SIZE
cost_result: resb NEBOC_ANALYSIS_COST_SIZE
query_result_a: resb NEBOC_ANALYSIS_QUERY_RESULT_SIZE
query_result_b: resb NEBOC_ANALYSIS_QUERY_RESULT_SIZE

section .text
_start:
 sub rsp,8
 lea rdi,[rel session]
 lea rsi,[rel compiler_snapshot]
 lea rdx,[rel options]
 call neboc_analysis_session_new
 test eax,eax
 jne .fail1
 lea rdi,[rel session]
 lea rsi,[rel function]
 lea rdx,[rel cfg]
 call neboc_analysis_control_flow
 test eax,eax
 jne .fail2
 cmp qword [rel cfg+NEBOC_ANALYSIS_CFG_BLOCK_COUNT_OFFSET],4
 jne .fail3
 cmp qword [rel cfg+NEBOC_ANALYSIS_CFG_EDGE_COUNT_OFFSET],4
 jne .fail4

 lea rax,[rel cfg]
 mov [rel dom_result+NEBOC_ANALYSIS_DOM_CFG_OFFSET],rax
 lea rax,[rel dom_masks]
 mov [rel dom_result+NEBOC_ANALYSIS_DOM_MASKS_OFFSET],rax
 lea rax,[rel postdom_masks]
 mov [rel dom_result+NEBOC_ANALYSIS_POSTDOM_MASKS_OFFSET],rax
 mov qword [rel dom_result+NEBOC_ANALYSIS_DOM_CAPACITY_OFFSET],4
 lea rdi,[rel session]
 lea rsi,[rel cfg]
 lea rdx,[rel dom_result]
 call neboc_analysis_dominators
 test eax,eax
 jne .fail5
 cmp qword [rel dom_masks],1
 jne .fail6
 cmp qword [rel dom_masks+8],3
 jne .fail7
 cmp qword [rel dom_masks+16],5
 jne .fail8
 cmp qword [rel dom_masks+24],9
 jne .fail9
 cmp qword [rel postdom_masks],9
 jne .fail10
 cmp qword [rel postdom_masks+8],10
 jne .fail11
 cmp qword [rel postdom_masks+16],12
 jne .fail12
 cmp qword [rel postdom_masks+24],8
 jne .fail13

 lea rax,[rel function]
 mov [rel usedef+NEBOC_ANALYSIS_USEDEF_FUNCTION_OFFSET],rax
 mov qword [rel usedef+NEBOC_ANALYSIS_USEDEF_SYMBOL_OFFSET],1
 lea rax,[rel definitions]
 mov [rel usedef+NEBOC_ANALYSIS_USEDEF_DEFS_OFFSET],rax
 mov qword [rel usedef+NEBOC_ANALYSIS_USEDEF_DEF_CAPACITY_OFFSET],4
 lea rax,[rel uses]
 mov [rel usedef+NEBOC_ANALYSIS_USEDEF_USES_OFFSET],rax
 mov qword [rel usedef+NEBOC_ANALYSIS_USEDEF_USE_CAPACITY_OFFSET],4
 lea rdi,[rel session]
 lea rsi,[rel usedef]
 call neboc_analysis_use_def
 test eax,eax
 jne .fail14
 cmp qword [rel usedef+NEBOC_ANALYSIS_USEDEF_DEF_COUNT_OFFSET],1
 jne .fail15
 cmp qword [rel usedef+NEBOC_ANALYSIS_USEDEF_USE_COUNT_OFFSET],3
 jne .fail16
 cmp qword [rel definitions],10
 jne .fail17
 cmp qword [rel uses],11
 jne .fail18
 cmp qword [rel uses+8],13
 jne .fail19
 cmp qword [rel uses+16],15
 jne .fail20

 lea rax,[rel function]
 mov [rel ranges_result+NEBOC_ANALYSIS_RANGES_FUNCTION_OFFSET],rax
 lea rax,[rel ranges]
 mov [rel ranges_result+NEBOC_ANALYSIS_RANGES_OUTPUT_OFFSET],rax
 mov qword [rel ranges_result+NEBOC_ANALYSIS_RANGES_CAPACITY_OFFSET],4
 lea rdi,[rel session]
 lea rsi,[rel ranges_result]
 call neboc_analysis_live_ranges
 test eax,eax
 jne .fail21
 cmp qword [rel ranges_result+NEBOC_ANALYSIS_RANGES_COUNT_OFFSET],2
 jne .fail22
 cmp qword [rel ranges+NEBOC_ANALYSIS_RANGE_SYMBOL_OFFSET],1
 jne .fail23
 cmp qword [rel ranges+NEBOC_ANALYSIS_RANGE_FIRST_OFFSET],0
 jne .fail24
 cmp qword [rel ranges+NEBOC_ANALYSIS_RANGE_LAST_OFFSET],5
 jne .fail25
 cmp qword [rel ranges+NEBOC_ANALYSIS_RANGE_SIZE+NEBOC_ANALYSIS_RANGE_SYMBOL_OFFSET],2
 jne .fail26
 cmp qword [rel ranges+NEBOC_ANALYSIS_RANGE_SIZE+NEBOC_ANALYSIS_RANGE_FIRST_OFFSET],2
 jne .fail27
 cmp qword [rel ranges+NEBOC_ANALYSIS_RANGE_SIZE+NEBOC_ANALYSIS_RANGE_LAST_OFFSET],4
 jne .fail28

 lea rax,[rel cfg]
 mov [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_CFG_OFFSET],rax
 mov qword [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_DIRECTION_OFFSET],NEBOC_ANALYSIS_DIRECTION_FORWARD
 lea rax,[rel gen_masks]
 mov [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_GEN_OFFSET],rax
 lea rax,[rel kill_masks]
 mov [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_KILL_OFFSET],rax
 mov qword [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_INITIAL_OFFSET],0
 lea rax,[rel flow_in]
 mov [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_IN_OFFSET],rax
 lea rax,[rel flow_out]
 mov [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_OUT_OFFSET],rax
 mov qword [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_CAPACITY_OFFSET],4
 mov qword [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_MAX_ITERATIONS_OFFSET],20
 lea rdi,[rel session]
 lea rsi,[rel dataflow]
 call neboc_analysis_data_flow
 test eax,eax
 jne .fail29
 cmp qword [rel flow_out],1
 jne .fail30
 cmp qword [rel flow_out+8],3
 jne .fail31
 cmp qword [rel flow_out+16],5
 jne .fail32
 cmp qword [rel flow_out+24],15
 jne .fail33
 mov qword [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_DIRECTION_OFFSET],NEBOC_ANALYSIS_DIRECTION_BACKWARD
 lea rdi,[rel session]
 lea rsi,[rel dataflow]
 call neboc_analysis_data_flow
 test eax,eax
 jne .fail34
 cmp qword [rel flow_in],15
 jne .fail35
 cmp qword [rel flow_in+8],10
 jne .fail36
 cmp qword [rel flow_in+16],12
 jne .fail37
 cmp qword [rel flow_in+24],8
 jne .fail38

 lea rdi,[rel session]
 lea rsi,[rel node]
 lea rdx,[rel effect_fact]
 call neboc_analysis_effects
 test eax,eax
 jne .fail39
 cmp qword [rel effect_fact+NEBOC_ANALYSIS_FACT_PRIMARY_OFFSET],3
 jne .fail40
 cmp qword [rel effect_fact+NEBOC_ANALYSIS_FACT_SECONDARY_OFFSET],4
 jne .fail41
 lea rdi,[rel session]
 lea rsi,[rel node]
 lea rdx,[rel ownership_fact]
 call neboc_analysis_ownership
 test eax,eax
 jne .fail42
 cmp qword [rel ownership_fact+NEBOC_ANALYSIS_FACT_PRIMARY_OFFSET],2
 jne .fail43
 cmp qword [rel ownership_fact+NEBOC_ANALYSIS_FACT_SECONDARY_OFFSET],9
 jne .fail44

 lea rdi,[rel session]
 lea rsi,[rel function]
 lea rdx,[rel call_graph]
 call neboc_analysis_call_graph
 test eax,eax
 jne .fail45
 cmp qword [rel call_graph+NEBOC_ANALYSIS_CALLGRAPH_CALL_COUNT_OFFSET],2
 jne .fail46
 cmp qword [rel call_graph+NEBOC_ANALYSIS_CALLGRAPH_UNKNOWN_COUNT_OFFSET],1
 jne .fail47

 lea rdi,[rel session]
 lea rsi,[rel node]
 lea rdx,[rel cost_model]
 lea rcx,[rel cost_result]
 call neboc_analysis_cost
 test eax,eax
 jne .fail48
 cmp qword [rel cost_result+NEBOC_ANALYSIS_COST_TOTAL_OFFSET],550
 jne .fail49

 lea rdi,[rel session]
 lea rsi,[rel query_key]
 lea rdx,[rel query_result_a]
 call neboc_analysis_query
 test eax,eax
 jne .fail50
 cmp qword [rel query_result_a+NEBOC_ANALYSIS_QUERY_RESULT_CACHE_HIT_OFFSET],0
 jne .fail51
 lea rdi,[rel session]
 lea rsi,[rel query_key]
 lea rdx,[rel query_result_b]
 call neboc_analysis_query
 test eax,eax
 jne .fail52
 cmp qword [rel query_result_b+NEBOC_ANALYSIS_QUERY_RESULT_CACHE_HIT_OFFSET],1
 jne .fail53
 mov rax,[rel query_result_a+NEBOC_ANALYSIS_QUERY_RESULT_VALUE_OFFSET]
 cmp rax,[rel query_result_b+NEBOC_ANALYSIS_QUERY_RESULT_VALUE_OFFSET]
 jne .fail54

 ; A stale compiler snapshot invalidates every query without mutating inputs.
 mov qword [rel compiler_snapshot+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET],0xdead
 lea rdi,[rel session]
 lea rsi,[rel query_key]
 lea rdx,[rel query_result_b]
 call neboc_analysis_query
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail55
 mov rax,SNAPSHOT
 mov [rel compiler_snapshot+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET],rax

 ; Invalid CFG edges and fixed-point budgets fail explicitly.
 mov qword [rel edges+NEBOC_ANALYSIS_EDGE_TO_OFFSET],9
 lea rdi,[rel session]
 lea rsi,[rel function]
 lea rdx,[rel cfg]
 call neboc_analysis_control_flow
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail56
 mov qword [rel edges+NEBOC_ANALYSIS_EDGE_TO_OFFSET],1
 lea rdi,[rel session]
 lea rsi,[rel function]
 lea rdx,[rel cfg]
 call neboc_analysis_control_flow
 test eax,eax
 jne .fail57
 mov qword [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_DIRECTION_OFFSET],NEBOC_ANALYSIS_DIRECTION_FORWARD
 mov qword [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_MAX_ITERATIONS_OFFSET],1
 lea rdi,[rel session]
 lea rsi,[rel dataflow]
 call neboc_analysis_data_flow
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail58
 cmp qword [rel dataflow+NEBOC_ANALYSIS_DATAFLOW_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 jne .fail59

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 59
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
