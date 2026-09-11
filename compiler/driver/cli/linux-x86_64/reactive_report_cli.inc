; Bounded local dependency-graph analysis for `neboc reactive-report`.
%ifndef NEBO_REACTIVE_REPORT_CLI_INC
%define NEBO_REACTIVE_REPORT_CLI_INC 1

section .rodata
reactive_report_heading: db 'reactive-report v1',10
reactive_report_heading_len equ $-reactive_report_heading
reactive_report_nodes: db 'nodes='
reactive_report_nodes_len equ $-reactive_report_nodes
reactive_report_edges: db 'edges='
reactive_report_edges_len equ $-reactive_report_edges
reactive_report_cost: db 'cost='
reactive_report_cost_len equ $-reactive_report_cost
reactive_report_budget: db 'budget=64',10
reactive_report_budget_len equ $-reactive_report_budget
reactive_report_hotspot: db 'hotspot=0',10
reactive_report_hotspot_len equ $-reactive_report_hotspot
reactive_report_cycle: db 'cycle-policy=reject',10
reactive_report_cycle_len equ $-reactive_report_cycle
reactive_report_scope: db 'scope=local',10
reactive_report_scope_len equ $-reactive_report_scope
reactive_report_error: db 'NEBO-REACTIVE-REPORT-001: expected a complete bounded DataflowGraph program',10
reactive_report_error_len equ $-reactive_report_error
reactive_report_start_atom: db 'start()'
reactive_report_start_atom_len equ $-reactive_report_start_atom
reactive_report_new_atom: db 'DataflowGraph.new('
reactive_report_new_atom_len equ $-reactive_report_new_atom
reactive_report_source_atom: db '.source('
reactive_report_source_atom_len equ $-reactive_report_source_atom
reactive_report_node_atom: db '.node('
reactive_report_node_atom_len equ $-reactive_report_node_atom
reactive_report_connect_atom: db '.connect('
reactive_report_connect_atom_len equ $-reactive_report_connect_atom
reactive_report_compile_atom: db '.compile('
reactive_report_compile_atom_len equ $-reactive_report_compile_atom
reactive_report_run_atom: db '.run('
reactive_report_run_atom_len equ $-reactive_report_run_atom
reactive_report_snapshot_atom: db '.snapshot('
reactive_report_snapshot_atom_len equ $-reactive_report_snapshot_atom
reactive_report_restore_atom: db '.restore('
reactive_report_restore_atom_len equ $-reactive_report_restore_atom
reactive_report_newline: db 10

section .bss align=16
reactive_report_source_count: resq 1
reactive_report_node_count: resq 1
reactive_report_edge_count: resq 1

section .text
; rdi=pattern, esi=length -> rax=non-overlapping count in bounded cli_source.
reactive_report_count:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13d,esi
 xor ebx,ebx
 xor r8d,r8d
.scan:
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 sub rax,r13
 jc .done
 cmp r8,rax
 ja .done
 lea r10,[rel cli_source]
 cmp byte [r10+r8],'/'
 jne .begin_compare
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 lea r11,[r8+1]
 cmp r11,rax
 jae .done
 cmp byte [r10+r8+1],'/'
 jne .begin_compare
 add r8,2
.skip_comment:
 cmp r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 jae .done
 cmp byte [r10+r8],10
 je .skip_comment_done
 inc r8
 jmp .skip_comment
.skip_comment_done:
 inc r8
 jmp .scan
.begin_compare:
 xor r9d,r9d
.compare:
 cmp r9,r13
 jae .match
 lea r10,[rel cli_source]
 mov al,[r10+r8]
 cmp al,[r12+r9]
 jne .next
 inc r8
 inc r9
 jmp .compare
.match:
 inc rbx
 jmp .scan
.next:
 sub r8,r9
 inc r8
 jmp .scan
.done:
 mov rax,rbx
 pop r13
 pop r12
 pop rbx
 ret

; rdi=value, writes decimal followed by newline to stdout.
reactive_report_write_u64:
 sub rsp,40
 mov rax,rdi
 lea rsi,[rsp+39]
 mov byte [rsi],10
 mov ecx,1
 test rax,rax
 jnz .digits
 dec rsi
 mov byte [rsi],'0'
 inc ecx
 jmp .emit
.digits:
 mov r8d,10
.digit_loop:
 xor edx,edx
 div r8
 add dl,'0'
 dec rsi
 mov [rsi],dl
 inc ecx
 test rax,rax
 jnz .digit_loop
.emit:
 mov rdi,rsi
 mov esi,ecx
 call cli_write_stdout
 add rsp,40
 ret

cli_reactive_report:
 push r12
 push r13
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 test rax,rax
 jz .invalid
 lea r11,[rel cli_source]
.trim_end:
 dec rax
 mov dl,[r11+rax]
 cmp dl,' '
 je .trim_continue
 cmp dl,9
 je .trim_continue
 cmp dl,10
 je .trim_continue
 cmp dl,13
 je .trim_continue
 cmp dl,'}'
 jne .invalid
 jmp .start
.trim_continue:
 test rax,rax
 jnz .trim_end
 jmp .invalid
.start:
 lea rdi,[rel reactive_report_start_atom]
 mov esi,reactive_report_start_atom_len
 call reactive_report_count
 cmp rax,1
 jne .invalid
 lea rdi,[rel reactive_report_new_atom]
 mov esi,reactive_report_new_atom_len
 call reactive_report_count
 cmp rax,1
 jne .invalid
 lea rdi,[rel reactive_report_source_atom]
 mov esi,reactive_report_source_atom_len
 call reactive_report_count
 test rax,rax
 jz .invalid
 mov [rel reactive_report_source_count],rax
 lea rdi,[rel reactive_report_node_atom]
 mov esi,reactive_report_node_atom_len
 call reactive_report_count
 test rax,rax
 jz .invalid
 mov [rel reactive_report_node_count],rax
 lea rdi,[rel reactive_report_connect_atom]
 mov esi,reactive_report_connect_atom_len
 call reactive_report_count
 test rax,rax
 jz .invalid
 mov [rel reactive_report_edge_count],rax
 lea rdi,[rel reactive_report_compile_atom]
 mov esi,reactive_report_compile_atom_len
 call reactive_report_count
 test rax,rax
 jz .invalid
 lea rdi,[rel reactive_report_run_atom]
 mov esi,reactive_report_run_atom_len
 call reactive_report_count
 test rax,rax
 jz .invalid
 lea rdi,[rel reactive_report_snapshot_atom]
 mov esi,reactive_report_snapshot_atom_len
 call reactive_report_count
 test rax,rax
 jz .invalid
 lea rdi,[rel reactive_report_restore_atom]
 mov esi,reactive_report_restore_atom_len
 call reactive_report_count
 test rax,rax
 jz .invalid
 mov r12,[rel reactive_report_source_count]
 add r12,[rel reactive_report_node_count]
 mov r13,r12
 add r13,[rel reactive_report_edge_count]
 cmp r13,64
 ja .invalid
 lea rdi,[rel reactive_report_heading]
 mov esi,reactive_report_heading_len
 call cli_write_stdout
 lea rdi,[rel reactive_report_nodes]
 mov esi,reactive_report_nodes_len
 call cli_write_stdout
 mov rdi,r12
 call reactive_report_write_u64
 lea rdi,[rel reactive_report_edges]
 mov esi,reactive_report_edges_len
 call cli_write_stdout
 mov rdi,[rel reactive_report_edge_count]
 call reactive_report_write_u64
 lea rdi,[rel reactive_report_cost]
 mov esi,reactive_report_cost_len
 call cli_write_stdout
 mov rdi,r13
 call reactive_report_write_u64
 lea rdi,[rel reactive_report_budget]
 mov esi,reactive_report_budget_len
 call cli_write_stdout
 lea rdi,[rel reactive_report_hotspot]
 mov esi,reactive_report_hotspot_len
 call cli_write_stdout
 lea rdi,[rel reactive_report_cycle]
 mov esi,reactive_report_cycle_len
 call cli_write_stdout
 lea rdi,[rel reactive_report_scope]
 mov esi,reactive_report_scope_len
 call cli_write_stdout
 xor eax,eax
 jmp .done
.invalid:
 lea rdi,[rel reactive_report_error]
 mov esi,reactive_report_error_len
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
.done:
 pop r13
 pop r12
 ret

%endif
