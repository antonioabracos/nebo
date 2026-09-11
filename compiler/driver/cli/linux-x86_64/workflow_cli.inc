; G045 bounded, read-only workflow definition verifier.
section .rodata
cli_workflow_magic: db 'NEBO-WORKFLOW-V1',10
cli_workflow_magic_len equ $-cli_workflow_magic
cli_workflow_version: db 'version='
cli_workflow_version_len equ $-cli_workflow_version
cli_workflow_name: db 'name='
cli_workflow_name_len equ $-cli_workflow_name
cli_workflow_initial: db 'initial='
cli_workflow_initial_len equ $-cli_workflow_initial
cli_workflow_state: db 'state='
cli_workflow_state_len equ $-cli_workflow_state
cli_workflow_transition: db 'transition='
cli_workflow_transition_len equ $-cli_workflow_transition
cli_workflow_step: db 'step='
cli_workflow_step_len equ $-cli_workflow_step
cli_workflow_idempotency: db 'idempotency='
cli_workflow_idempotency_len equ $-cli_workflow_idempotency
cli_workflow_compensation: db 'compensation='
cli_workflow_compensation_len equ $-cli_workflow_compensation
cli_workflow_report:
 db 'workflow-verify v1',10
 db 'format=NEBO-WORKFLOW-V1',10
 db 'versioned=YES',10
 db 'state-machine=YES',10
 db 'durable-steps=YES',10
 db 'idempotency=EXPLICIT',10
 db 'compensation=EXPLICIT',10
 db 'mutation=NO',10
 db 'network=FORBIDDEN',10
cli_workflow_report_end:
cli_workflow_error:
 db 'NEBO-G045-WORKFLOW-VERIFY-088: invalid incomplete or unversioned workflow definition',10
cli_workflow_error_end:

section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL

; RDI=line prefix, ECX=prefix length. EAX=1 only for a non-empty line value.
cli_workflow_contains_line_value:
 push rbx
 push r12
 mov r12,rdi
 mov ebx,ecx
 mov r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp r8,rbx
 jb .absent
 sub r8,rbx
 xor r9d,r9d
.candidate:
 cmp r9,r8
 ja .absent
 test r9,r9
 jz .compare
 lea rax,[rel cli_source]
 cmp byte [rax+r9-1],10
 jne .next
.compare:
 lea rsi,[rel cli_source]
 add rsi,r9
 mov rdi,r12
 mov ecx,ebx
 repe cmpsb
 jne .next
 lea rax,[rel cli_source]
 add rax,r9
 add rax,rbx
 cmp byte [rax],32
 jbe .next
 lea rdx,[rel cli_workflow_version]
 cmp r12,rdx
 jne .present
 cmp byte [rax],'1'
 jb .next
 cmp byte [rax],'9'
 ja .next
 jmp .present
.next:
 inc r9
 jmp .candidate
.present:
 mov eax,1
 jmp .done
.absent:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

cli_workflow_verify:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],cli_workflow_magic_len
 jb .bad
 lea rsi,[rel cli_source]
 lea rdi,[rel cli_workflow_magic]
 mov ecx,cli_workflow_magic_len
 repe cmpsb
 jne .bad
 lea rdi,[rel cli_workflow_version]
 mov ecx,cli_workflow_version_len
 call cli_workflow_contains_line_value
 test eax,eax
 jz .bad
 lea rdi,[rel cli_workflow_name]
 mov ecx,cli_workflow_name_len
 call cli_workflow_contains_line_value
 test eax,eax
 jz .bad
 lea rdi,[rel cli_workflow_initial]
 mov ecx,cli_workflow_initial_len
 call cli_workflow_contains_line_value
 test eax,eax
 jz .bad
 lea rdi,[rel cli_workflow_state]
 mov ecx,cli_workflow_state_len
 call cli_workflow_contains_line_value
 test eax,eax
 jz .bad
 lea rdi,[rel cli_workflow_transition]
 mov ecx,cli_workflow_transition_len
 call cli_workflow_contains_line_value
 test eax,eax
 jz .bad
 lea rdi,[rel cli_workflow_step]
 mov ecx,cli_workflow_step_len
 call cli_workflow_contains_line_value
 test eax,eax
 jz .bad
 lea rdi,[rel cli_workflow_idempotency]
 mov ecx,cli_workflow_idempotency_len
 call cli_workflow_contains_line_value
 test eax,eax
 jz .bad
 lea rdi,[rel cli_workflow_compensation]
 mov ecx,cli_workflow_compensation_len
 call cli_workflow_contains_line_value
 test eax,eax
 jz .bad
 lea rdi,[rel cli_workflow_report]
 mov esi,cli_workflow_report_end-cli_workflow_report
 call cli_write_stdout
 xor eax,eax
 ret
.bad:
 lea rdi,[rel cli_workflow_error]
 mov esi,cli_workflow_error_end-cli_workflow_error
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 ret

%undef call
