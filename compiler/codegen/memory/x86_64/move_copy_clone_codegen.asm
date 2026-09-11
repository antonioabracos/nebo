; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-F02 deterministic native ownership emitter
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/semantic/memory/move_copy_clone.inc"
%include "compiler/lowering/memory/move_copy_clone_plan.inc"
%include "compiler/codegen/memory/x86_64/move_copy_clone_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal

section .rodata
prefix:
 db 10,'section .text',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
prefix_len equ $-prefix
value_prefix: db '    mov rax, '
value_prefix_len equ $-value_prefix
suffix: db 10,'    ret',10
suffix_len equ $-suffix

event_data: db 10,'section .rodata',10,'align 8',10,'nebo_ownership_events:',10
 event_data_len equ $-event_data
 event_qword: db ' dq '
 event_qword_len equ $-event_qword
 newline: db 10
 backing_prefix: db 'section .bss',10,'align 16',10,'nebo_ownership_backing: resb '
 backing_prefix_len equ $-backing_prefix
 execute_prefix: db '    sub rsp, 8',10,'    lea rdi, [rel nebo_ownership_events]',10,'    mov esi, '
 execute_prefix_len equ $-execute_prefix
 execute_middle: db 10,'    lea rdx, [rel nebo_ownership_backing]',10,'    mov ecx, '
 execute_middle_len equ $-execute_middle
 execute_suffix: db 10,'    extern nebo_runtime_ownership_execute',10,'    call nebo_runtime_ownership_execute',10,'    add rsp, 8',10
 execute_suffix_len equ $-execute_suffix

section .text

%macro WRITE_BYTES 2
 mov rdi,r14
 lea rsi,[rel %1]
 mov edx,%2
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
%endmacro
%macro WRITE_VALUE 1
 mov rdi,r14
 mov rsi,%1
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
%endmacro

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_move_copy_clone_codegen_emit_start
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_HASH_OFFSET],0
 mov r13,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_PLAN_OFFSET]
 mov r14,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_memory_x86_64_native_vertical]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r13,7
 jnz .invalid
 test r14,7
 jnz .invalid
 mov rax,neboc_text_char_unicode_e_bytes_PLAN_MAGIC
 cmp [r13+neboc_text_char_unicode_e_bytes_PLAN_MAGIC_OFFSET],rax
 jne .source
 mov rdi,r13
 mov ecx,neboc_text_char_unicode_e_bytes_PLAN_HASHED_BYTES
 call hash_bytes
 cmp rax,[r13+neboc_text_char_unicode_e_bytes_PLAN_HASH_OFFSET]
 jne .source
 cmp qword [r13+NEBOC_PLAN_EVENT_COUNT_OFFSET],NEBOC_OWNERSHIP_MAX_EVENTS
 ja .source
 xor ebx,ebx
 mov [rsp],rbx
 cmp qword [r13+NEBOC_PLAN_EVENT_COUNT_OFFSET],0
 je .body
 WRITE_BYTES event_data,event_data_len
 lea r15,[r13+NEBOC_PLAN_EVENTS_OFFSET]
.events:
 cmp rbx,[r13+NEBOC_PLAN_EVENT_COUNT_OFFSET]
 jae .backing
 cmp qword [r15],NEBOC_OWN_EVENT_ARENA_INIT
 je .reserve
 cmp qword [r15],NEBOC_OWN_EVENT_CLONE
 jne .serialized
.reserve:
 mov rax,[r15+24]
 cmp rax,1048576
 ja .source
 add rax,15
 and rax,-16
 add [rsp],rax
.serialized:
 %assign field 0
 %rep 6
 WRITE_BYTES event_qword,event_qword_len
 WRITE_VALUE [r15+field]
 WRITE_BYTES newline,1
 %assign field field+8
 %endrep
 add r15,NEBOC_OWNERSHIP_EVENT_SIZE
 inc rbx
 jmp .events
.backing:
 WRITE_BYTES backing_prefix,backing_prefix_len
 mov rax,[rsp]
 inc rax
 WRITE_VALUE rax
 WRITE_BYTES newline,1
.body:
 WRITE_BYTES prefix,prefix_len
 cmp qword [r13+NEBOC_PLAN_EVENT_COUNT_OFFSET],0
 je .value
 WRITE_BYTES execute_prefix,execute_prefix_len
 WRITE_VALUE [r13+NEBOC_PLAN_EVENT_COUNT_OFFSET]
 WRITE_BYTES execute_middle,execute_middle_len
 WRITE_VALUE [rsp]
 WRITE_BYTES execute_suffix,execute_suffix_len
.value:
 WRITE_BYTES value_prefix,value_prefix_len
 WRITE_VALUE [r13+neboc_text_char_unicode_e_bytes_PLAN_RESULT_VALUE_OFFSET]
 mov rdi,r14
 lea rsi,[rel suffix]
 mov edx,suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_EMITTED_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_EMITTED_START
 mov rax,[r13+neboc_text_char_unicode_e_bytes_PLAN_HASH_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_DIAG_CLONE_UNAVAILABLE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

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
.done: ret

section .note.GNU-stack noalloc noexec nowrite progbits
