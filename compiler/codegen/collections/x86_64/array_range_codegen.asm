; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F03 deterministic emitter for authenticated Array/Range plans.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/lowering/collections/array_range_plan.inc"
%include "compiler/codegen/collections/x86_64/array_range_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal
extern neboc_assembly_writer_append_u64_decimal

section .rodata
prefix:
 db 10,'section .text',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    mov rax, '
prefix_len equ $-prefix
suffix: db 10,'    ret',10
suffix_len equ $-suffix
for_prefix:
 db 10,'section .text',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    sub rsp, 128',10
for_prefix_len equ $-for_prefix
for_header: db '._for_header'
for_header_len equ $-for_header
for_latch: db '._for_latch'
for_latch_len equ $-for_latch
for_exit: db '._for_exit'
for_exit_len equ $-for_exit
for_data: db '._for_data'
for_data_len equ $-for_data
colon_nl: db ':',10
colon_nl_len equ $-colon_nl
newline: db 10
newline_len equ $-newline
slot_init_a: db '    mov qword [rsp + '
slot_init_a_len equ $-slot_init_a
slot_init_b: db '], 0',10
slot_init_b_len equ $-slot_init_b
slot_load_a: db '    mov rcx, [rsp + '
slot_load_a_len equ $-slot_load_a
slot_load_b: db ']',10
slot_load_b_len equ $-slot_load_b
count_cmp_a: db '    cmp rcx, '
count_cmp_a_len equ $-count_cmp_a
count_cmp_b: db 10,'    jae ._for_exit'
count_cmp_b_len equ $-count_cmp_b
range_value_a: db '    mov rax, rcx',10,'    imul rax, '
range_value_a_len equ $-range_value_a
range_value_b: db 10,'    add rax, '
range_value_b_len equ $-range_value_b
array_value_a: db '    lea rdx, [rel ._for_data'
array_value_a_len equ $-array_value_a
array_value_b: db ']',10,'    mov rax, [rdx + rcx*8]',10
array_value_b_len equ $-array_value_b
jump_a: db '    jmp '
jump_a_len equ $-jump_a
slot_inc_a: db '    inc qword [rsp + '
slot_inc_a_len equ $-slot_inc_a
slot_inc_b: db ']',10
slot_inc_b_len equ $-slot_inc_b
return_item: db '    add rsp, 128',10,'    ret',10
return_item_len equ $-return_item
final_a: db '    mov rax, '
final_a_len equ $-final_a
final_b: db 10,'    add rsp, 128',10,'    ret',10
final_b_len equ $-final_b
rodata_prefix: db 10,'section .rodata',10
rodata_prefix_len equ $-rodata_prefix
dq_prefix: db '    dq '
dq_prefix_len equ $-dq_prefix

section .text

NEBOC_ABI_FUNCTION neboc_array_range_codegen_emit_start
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov qword [r12+NEBOC_AR_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+NEBOC_AR_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_AR_CODEGEN_HASH_OFFSET],0
 mov r13,[r12+NEBOC_AR_CODEGEN_PLAN_OFFSET]
 mov r14,[r12+NEBOC_AR_CODEGEN_WRITER_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,NEBOC_AR_PLAN_MAGIC
 cmp [r13+NEBOC_AR_PLAN_MAGIC_OFFSET],rax
 jne .source
 mov rax,NEBOC_ARRAY_RANGE_LAYOUT_ID
 cmp [r13+NEBOC_AR_PLAN_LAYOUT_ID_OFFSET],rax
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_AR_PLAN_HASHED_BYTES
 call hash_bytes
 cmp rax,[r13+NEBOC_AR_PLAN_HASH_OFFSET]
 jne .source
 cmp qword [r13+NEBOC_AR_PLAN_LOOP_COUNT_OFFSET],0
 je .constant_program
 mov r15,[r12+NEBOC_AR_CODEGEN_SEMANTIC_OFFSET]
 test r15,r15
 jz .invalid
 mov rax,[r15+NEBOC_AR_SEMANTIC_HASH_OFFSET]
 cmp rax,[r13+NEBOC_AR_PLAN_SEMANTIC_HASH_OFFSET]
 jne .source
 mov rax,[r15+NEBOC_AR_LOOP_COUNT_OFFSET]
 cmp rax,[r13+NEBOC_AR_PLAN_LOOP_COUNT_OFFSET]
 jne .source
 mov rdi,r12
 call emit_for_program
 test eax,eax
 jnz .writer
 jmp .emitted
.constant_program:
 mov rdi,r14
 lea rsi,[rel prefix]
 mov edx,prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r14
 mov rsi,[r13+NEBOC_AR_PLAN_RESULT_VALUE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r14
 lea rsi,[rel suffix]
 mov edx,suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
.emitted:
 mov qword [r12+NEBOC_AR_CODEGEN_EMITTED_OFFSET],NEBOC_AR_CODEGEN_EMITTED_START
 mov rax,[r13+NEBOC_AR_PLAN_HASH_OFFSET]
 mov [r12+NEBOC_AR_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_AR_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+NEBOC_AR_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Emit every depth-zero iterator in source order. Nested records are emitted
; recursively by their owning record and use disjoint fixed stack slots.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
emit_for_program:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,[r12+NEBOC_AR_CODEGEN_PLAN_OFFSET]
 mov r14,[r12+NEBOC_AR_CODEGEN_WRITER_OFFSET]
 mov r15,[r12+NEBOC_AR_CODEGEN_SEMANTIC_OFFSET]
 mov rdi,r14
 lea rsi,[rel for_prefix]
 mov edx,for_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 xor ebx,ebx
.top_loop:
 cmp rbx,[r15+NEBOC_AR_LOOP_COUNT_OFFSET]
 jae .final
 mov rsi,rbx
 imul rsi,NEBOC_FOR_RECORD_SIZE
 add rsi,[r15+NEBOC_AR_LOOPS_OFFSET]
 cmp qword [rsi+NEBOC_FOR_DEPTH_OFFSET],0
 jne .top_next
 mov rdi,r12
 call emit_for_loop
 test eax,eax
 jnz .done
.top_next:
 inc rbx
 jmp .top_loop
.final:
 mov rdi,r14
 lea rsi,[rel final_a]
 mov edx,final_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_AR_PLAN_RESULT_VALUE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel final_b]
 mov edx,final_b_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r12
 call emit_for_data
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; codegen request*, loop record* -> status
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
emit_for_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+NEBOC_AR_CODEGEN_WRITER_OFFSET]
 mov r15,[r12+NEBOC_AR_CODEGEN_SEMANTIC_OFFSET]
 mov rbx,[r13+NEBOC_FOR_DEPTH_OFFSET]
 shl rbx,3
 mov [rsp],rbx
 ; index slot = 0
 mov rdi,r14
 lea rsi,[rel slot_init_a]
 mov edx,slot_init_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,rbx
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel slot_init_b]
 mov edx,slot_init_b_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 ; header label and index load
 mov rdi,r14
 lea rsi,[rel for_header]
 mov edx,for_header_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel slot_load_a]
 mov edx,slot_load_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel slot_load_b]
 mov edx,slot_load_b_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel count_cmp_a]
 mov edx,count_cmp_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_COUNT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel count_cmp_b]
 mov edx,count_cmp_b_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,newline_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 ; materialize the current iterator item in RAX.
 cmp qword [r13+NEBOC_FOR_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 jne .array_value
 mov rdi,r14
 lea rsi,[rel range_value_a]
 mov edx,range_value_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_STEP_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel range_value_b]
 mov edx,range_value_b_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_START_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,newline_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 jmp .action
.array_value:
 mov rdi,r14
 lea rsi,[rel array_value_a]
 mov edx,array_value_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel array_value_b]
 mov edx,array_value_b_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
.action:
 mov rax,[r13+NEBOC_FOR_ACTION_OFFSET]
 cmp rax,NEBOC_FOR_ACTION_BREAK
 je .break
 cmp rax,NEBOC_FOR_ACTION_CONTINUE
 je .continue
 cmp rax,NEBOC_FOR_ACTION_RETURN_ITEM
 je .return
 cmp rax,NEBOC_FOR_ACTION_NESTED
 je .nested
 test rax,rax
 jnz .bad
 jmp .latch
.break:
 mov rsi,for_exit
 mov edx,for_exit_len
 jmp .jump
.continue:
 mov rsi,for_latch
 mov edx,for_latch_len
 jmp .jump
.jump:
 mov [rsp+8],rsi
 mov [rsp+16],rdx
 mov rdi,r14
 lea rsi,[rel jump_a]
 mov edx,jump_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,newline_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 jmp .latch
.return:
 mov rdi,r14
 lea rsi,[rel return_item]
 mov edx,return_item_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 jmp .latch
.nested:
 mov rsi,[r13+NEBOC_FOR_CHILD_INDEX_OFFSET]
 cmp rsi,[r15+NEBOC_AR_LOOP_COUNT_OFFSET]
 jae .bad
 imul rsi,NEBOC_FOR_RECORD_SIZE
 add rsi,[r15+NEBOC_AR_LOOPS_OFFSET]
 mov rdi,r12
 call emit_for_loop
 test eax,eax
 jnz .done
.latch:
 mov rdi,r14
 lea rsi,[rel for_latch]
 mov edx,for_latch_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel slot_inc_a]
 mov edx,slot_inc_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel slot_inc_b]
 mov edx,slot_inc_b_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel jump_a]
 mov edx,jump_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel for_header]
 mov edx,for_header_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,newline_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel for_exit]
 mov edx,for_exit_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r13+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Emit immutable Array/Slice payloads referenced by iterator records.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
emit_for_data:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,[r12+NEBOC_AR_CODEGEN_SEMANTIC_OFFSET]
 mov r14,[r12+NEBOC_AR_CODEGEN_WRITER_OFFSET]
 mov rdi,r14
 lea rsi,[rel rodata_prefix]
 mov edx,rodata_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 xor ebx,ebx
.record:
 cmp rbx,[r13+NEBOC_AR_LOOP_COUNT_OFFSET]
 jae .ok
 mov r15,rbx
 imul r15,NEBOC_FOR_RECORD_SIZE
 add r15,[r13+NEBOC_AR_LOOPS_OFFSET]
 cmp qword [r15+NEBOC_FOR_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 je .next
 mov rdi,r14
 lea rsi,[rel for_data]
 mov edx,for_data_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rdi,r14
 mov rsi,[r15+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov qword [rsp],0
.value:
 mov rax,[rsp]
 cmp rax,[r15+NEBOC_FOR_COUNT_OFFSET]
 jae .next
 mov rdi,r14
 lea rsi,[rel dq_prefix]
 mov edx,dq_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov rax,[r15+NEBOC_FOR_DATA_INDEX_OFFSET]
 add rax,[rsp]
 mov rdx,[r13+NEBOC_AR_VALUES_OFFSET]
 mov rsi,[rdx+rax*8]
 mov rdi,r14
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .done
 mov rdi,r14
 lea rsi,[rel newline]
 mov edx,newline_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 inc qword [rsp]
 jmp .value
.next:
 inc rbx
 jmp .record
.ok:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%undef call
hash_bytes:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rdi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
