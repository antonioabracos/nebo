; PROJECT-PRESSURE-F08 bounded large-project and pressure state machine.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/memory/project_pressure.inc"

section .text
; rdi=project rsi=id -> rax=module or zero.
project_find:
 mov rax,[rdi+NEBOC_PROJECT_MODULES_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+NEBOC_PROJECT_MODULE_COUNT_OFFSET]
 jae .missing
 cmp [rax+NEBOC_PROJECT_MODULE_ID_OFFSET],rsi
 je .done
 add rax,NEBOC_PROJECT_MODULE_SIZE
 inc rcx
 jmp .loop
.missing: xor eax,eax
.done: ret

NEBOC_ABI_FUNCTION neboc_project_model_load
 ; rdi=project rsi=manifest rdx=limits.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov r8,[rsi+NEBOC_PROJECT_MANIFEST_MODULES_OFFSET]
 test r8,r8
 jz .invalid
 mov r9,[rsi+NEBOC_PROJECT_MANIFEST_COUNT_OFFSET]
 test r9,r9
 jz .invalid
 cmp r9,NEBOC_PROJECT_MAX_MODULES
 ja .limit
 cmp r9,[rdx+NEBOC_PROJECT_LIMIT_MODULES_OFFSET]
 ja .limit
 cmp qword [rdx+NEBOC_PROJECT_LIMIT_BYTES_OFFSET],0
 je .invalid
 mov r10,[rdx+NEBOC_PROJECT_LIMIT_DIAGNOSTIC_COUNT_OFFSET]
 cmp r10,NEBOC_PROJECT_MAX_DIAGNOSTICS
 ja .limit
 cmp r10,[rdx+NEBOC_PROJECT_LIMIT_DIAGNOSTIC_CAPACITY_OFFSET]
 ja .invalid
 test r10,r10
 jz .validate
 cmp qword [rdx+NEBOC_PROJECT_LIMIT_DIAGNOSTICS_OFFSET],0
 je .invalid
.validate:
 xor ecx,ecx
 xor r10d,r10d
 xor r11d,r11d
 xor eax,eax
.module:
 cmp rcx,r9
 jae .publish
 cmp qword [r8+NEBOC_PROJECT_MODULE_ID_OFFSET],0
 je .invalid
 cmp qword [r8+NEBOC_PROJECT_MODULE_BYTES_OFFSET],0
 je .invalid
 test rcx,rcx
 jz .canonical
 mov rax,[r8-NEBOC_PROJECT_MODULE_SIZE+NEBOC_PROJECT_MODULE_ID_OFFSET]
 cmp rax,[r8+NEBOC_PROJECT_MODULE_ID_OFFSET]
 jae .invalid
.canonical:
 add r10,[r8+NEBOC_PROJECT_MODULE_BYTES_OFFSET]
 jc .limit
 add r11,[r8+NEBOC_PROJECT_MODULE_LOC_OFFSET]
 add r8,NEBOC_PROJECT_MODULE_SIZE
 inc rcx
 jmp .module
.publish:
 cmp r10,[rdx+NEBOC_PROJECT_LIMIT_BYTES_OFFSET]
 ja .limit
 mov r8,rdi
 xor eax,eax
 mov ecx,NEBOC_PROJECT_SIZE/8
 rep stosq
 mov rax,[rsi+NEBOC_PROJECT_MANIFEST_MODULES_OFFSET]
 mov [r8+NEBOC_PROJECT_MODULES_OFFSET],rax
 mov rax,[rsi+NEBOC_PROJECT_MANIFEST_COUNT_OFFSET]
 mov [r8+NEBOC_PROJECT_MODULE_COUNT_OFFSET],rax
 mov [r8+NEBOC_PROJECT_TOTAL_BYTES_OFFSET],r10
 mov rax,[rdx+NEBOC_PROJECT_LIMIT_BYTES_OFFSET]
 mov [r8+NEBOC_PROJECT_MAX_BYTES_OFFSET],rax
 mov rax,[rdx+NEBOC_PROJECT_LIMIT_DIAGNOSTICS_OFFSET]
 mov [r8+NEBOC_PROJECT_DIAGNOSTICS_OFFSET],rax
 mov rax,[rdx+NEBOC_PROJECT_LIMIT_DIAGNOSTIC_COUNT_OFFSET]
 mov [r8+NEBOC_PROJECT_DIAGNOSTIC_COUNT_OFFSET],rax
 mov rax,[rdx+NEBOC_PROJECT_LIMIT_DIAGNOSTIC_CAPACITY_OFFSET]
 mov [r8+NEBOC_PROJECT_DIAGNOSTIC_CAPACITY_OFFSET],rax
 mov [r8+NEBOC_PROJECT_LOC_OFFSET],r11
 mov qword [r8+NEBOC_PROJECT_WORKERS_OFFSET],4
 mov qword [r8+NEBOC_PROJECT_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_project_lazy_module
 ; rdi=project rsi=id rdx=out module pointer.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdi+NEBOC_PROJECT_ACTIVE_OFFSET],1
 jne .invalid
 mov r8,rdi
 call project_find
 test rax,rax
 jz .invalid_source
 cmp qword [rax+NEBOC_PROJECT_MODULE_STATE_OFFSET],NEBOC_PROJECT_MODULE_READY
 je .ready
 mov qword [rax+NEBOC_PROJECT_MODULE_STATE_OFFSET],NEBOC_PROJECT_MODULE_READY
 inc qword [r8+NEBOC_PROJECT_MATERIALIZED_OFFSET]
 inc qword [r8+NEBOC_PROJECT_QUERIES_OFFSET]
.ready:
 mov [rdx],rax
 xor eax,eax
 ret
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_project_chunk_diagnostics
 ; rdi=project rsi=max items rdx=output rcx=capacity r8=out count.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 mov r9,[rdi+NEBOC_PROJECT_DIAGNOSTIC_CURSOR_OFFSET]
 mov r10,[rdi+NEBOC_PROJECT_DIAGNOSTIC_COUNT_OFFSET]
 sub r10,r9
 cmp r10,rsi
 cmova r10,rsi
 cmp r10,rcx
 cmova r10,rcx
 mov r11,[rdi+NEBOC_PROJECT_DIAGNOSTICS_OFFSET]
 imul rax,r9,NEBOC_PROJECT_DIAGNOSTIC_SIZE
 add r11,rax
 xor ecx,ecx
.copy:
 cmp rcx,r10
 jae .publish
 mov rax,[r11]
 mov [rdx],rax
 mov rax,[r11+8]
 mov [rdx+8],rax
 add r11,NEBOC_PROJECT_DIAGNOSTIC_SIZE
 add rdx,NEBOC_PROJECT_DIAGNOSTIC_SIZE
 inc rcx
 jmp .copy
.publish:
 add [rdi+NEBOC_PROJECT_DIAGNOSTIC_CURSOR_OFFSET],r10
 mov [r8],r10
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_project_incremental_link_plan
 ; rdi=project rsi=changed ids rdx=count rcx=out ids r8=capacity r9=out count.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r9,r9
 jz .invalid
 cmp rdx,r8
 ja .limit
 push rbx
 push r12
 mov rbx,[rdi+NEBOC_PROJECT_MODULES_OFFSET]
 xor r10d,r10d
 xor r11d,r11d
.module:
 cmp r10,[rdi+NEBOC_PROJECT_MODULE_COUNT_OFFSET]
 jae .done
 xor r12d,r12d
.changed:
 cmp r12,rdx
 jae .next
 mov rax,[rsi+r12*8]
 cmp rax,[rbx+NEBOC_PROJECT_MODULE_ID_OFFSET]
 je .emit
 inc r12
 jmp .changed
.emit:
 mov [rcx+r11*8],rax
 inc r11
.next:
 add rbx,NEBOC_PROJECT_MODULE_SIZE
 inc r10
 jmp .module
.done:
 cmp r11,rdx
 jne .invalid_saved
 mov [r9],r11
 mov [rdi+NEBOC_PROJECT_OBJECTS_OFFSET],r11
 pop r12
 pop rbx
 xor eax,eax
 ret
.invalid_saved:
 pop r12
 pop rbx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_project_file_watch
 ; rdi=project rsi=event(id,sequence) records rdx=count rcx=policy r8=report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_PROJECT_MAX_EVENTS
 ja .limit
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 push rbx
 push r12
 mov rbx,rsi
 xor r9d,r9d
 xor r10d,r10d
.event:
 cmp r9,rdx
 jae .publish
 mov rax,r9
 shl rax,4
 mov rsi,[rbx+rax]
 call project_find
 test rax,rax
 jz .invalid_saved
 xor r11d,r11d
.prior:
 cmp r11,r9
 jae .unique
 mov rax,r11
 shl rax,4
 mov rax,[rbx+rax]
 mov r12,r9
 shl r12,4
 cmp rax,[rbx+r12]
 je .duplicate
 inc r11
 jmp .prior
.unique: inc r10
 jmp .next
.duplicate: inc qword [rdi+NEBOC_PROJECT_COALESCED_OFFSET]
.next: inc r9
 jmp .event
.publish:
 mov [r8+NEBOC_PROJECT_WATCH_UNIQUE_OFFSET],r10
 mov rax,rdx
 sub rax,r10
 mov [r8+NEBOC_PROJECT_WATCH_COALESCED_OFFSET],rax
 pop r12
 pop rbx
 xor eax,eax
 ret
.invalid_saved:
 pop r12
 pop rbx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_project_pressure_policy
 ; rdi=project rsi=0 normal,1 reduce,2 serialize,3 graceful failure.
 test rdi,rdi
 jz .invalid
 cmp rsi,3
 ja .invalid
 je .pressure_fail
 mov [rdi+NEBOC_PROJECT_PRESSURE_OFFSET],rsi
 mov eax,4
 cmp esi,1
 cmove eax,esi
 cmp esi,1
 jne .serialized
 mov eax,2
.serialized:
 cmp esi,2
 jne .save
 mov eax,1
.save:
 mov [rdi+NEBOC_PROJECT_WORKERS_OFFSET],rax
 test esi,esi
 jz .done
 inc qword [rdi+NEBOC_PROJECT_EVICTIONS_OFFSET]
.done: xor eax,eax
 ret
.pressure_fail: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_project_progress_snapshot
 ; rdi=project rsi=report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_PROJECT_COMPLETED_OFFSET]
 mov [rsi+NEBOC_PROJECT_PROGRESS_COMPLETED_OFFSET],rax
 mov rax,[rdi+NEBOC_PROJECT_MODULE_COUNT_OFFSET]
 sub rax,[rdi+NEBOC_PROJECT_COMPLETED_OFFSET]
 mov [rsi+NEBOC_PROJECT_PROGRESS_PENDING_OFFSET],rax
 mov rax,[rdi+NEBOC_PROJECT_BLOCKED_OFFSET]
 mov [rsi+NEBOC_PROJECT_PROGRESS_BLOCKED_OFFSET],rax
 mov rax,[rdi+NEBOC_PROJECT_MATERIALIZED_OFFSET]
 mov [rsi+NEBOC_PROJECT_PROGRESS_MATERIALIZED_OFFSET],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_project_scalability_report
 ; rdi=project rsi=8-qword report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_PROJECT_MODULE_COUNT_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_PROJECT_TOTAL_BYTES_OFFSET]
 mov [rsi+8],rax
 mov rax,[rdi+NEBOC_PROJECT_LOC_OFFSET]
 mov [rsi+16],rax
 mov rax,[rdi+NEBOC_PROJECT_MATERIALIZED_OFFSET]
 mov [rsi+24],rax
 mov rax,[rdi+NEBOC_PROJECT_QUERIES_OFFSET]
 mov [rsi+32],rax
 mov rax,[rdi+NEBOC_PROJECT_OBJECTS_OFFSET]
 mov [rsi+40],rax
 mov rax,[rdi+NEBOC_PROJECT_DIAGNOSTIC_COUNT_OFFSET]
 mov [rsi+48],rax
 mov rax,[rdi+NEBOC_PROJECT_WORKERS_OFFSET]
 mov [rsi+56],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_project_synthetic_corpus
 ; rdi=module buffer rsi=count rdx=base bytes rcx=seed.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,NEBOC_PROJECT_MAX_MODULES
 ja .limit
 test rdx,rdx
 jz .invalid
 xor r8d,r8d
.generate:
 cmp r8,rsi
 jae .done
 lea rax,[r8+1]
 mov [rdi+NEBOC_PROJECT_MODULE_ID_OFFSET],rax
 mov r9,rcx
 add r9,r8
 and r9,7
 add r9,rdx
 mov [rdi+NEBOC_PROJECT_MODULE_BYTES_OFFSET],r9
 mov rax,r9
 shr rax,2
 inc rax
 mov [rdi+NEBOC_PROJECT_MODULE_LOC_OFFSET],rax
 mov qword [rdi+NEBOC_PROJECT_MODULE_STATE_OFFSET],NEBOC_PROJECT_MODULE_LAZY
 mov rax,r8
 imul rax,0x9e37
 xor rax,rcx
 xor rax,r9
 mov [rdi+NEBOC_PROJECT_MODULE_HASH_OFFSET],rax
 add rdi,NEBOC_PROJECT_MODULE_SIZE
 inc r8
 jmp .generate
.done: xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_project_report
 jmp neboc_project_scalability_report

NEBOC_ABI_FUNCTION neboc_cli_build_memory_budget
 ; rdi=project rsi=new byte ceiling; cannot undercut live state.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_PROJECT_TOTAL_BYTES_OFFSET]
 jb .limit
 mov [rdi+NEBOC_PROJECT_MAX_BYTES_OFFSET],rsi
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
