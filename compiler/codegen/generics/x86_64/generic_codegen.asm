; Nebo Assembly — GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF005 deterministic concrete generic specialization emitter
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_api_contract.inc"
%include "compiler/semantic/generics/generic_semantic.inc"
%include "compiler/semantic/generics/generic_vertical.inc"
%include "compiler/codegen/generics/x86_64/generic_codegen.inc"
extern neboc_assembly_writer_append_bytes

section .rodata
bool_prefix: db 10,'section .text',10,'global nebo_identity_Bool',10,'nebo_identity_Bool:',10,'    mov rax, rdi',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    push rbp',10,'    mov rbp, rsp',10,'    mov rdi, '
bool_prefix_len equ $-bool_prefix
bool_suffix: db 10,'    call nebo_identity_Bool',10,'    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
bool_suffix_len equ $-bool_suffix
int_prefix: db 10,'section .text',10,'global nebo_identity_Int',10,'nebo_identity_Int:',10,'    mov rax, rdi',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    push rbp',10,'    mov rbp, rsp',10,'    mov rdi, '
int_prefix_len equ $-int_prefix
int_suffix: db 10,'    call nebo_identity_Int',10,'    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
int_suffix_len equ $-int_suffix
concrete_prefix: db 10,'section .text',10,'global nebo_concrete_identity_Int',10,'nebo_concrete_identity_Int:',10,'    lea rax, [rdi + 1]',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    push rbp',10,'    mov rbp, rsp',10,'    mov rdi, '
concrete_prefix_len equ $-concrete_prefix
concrete_suffix: db 10,'    call nebo_concrete_identity_Int',10,'    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
concrete_suffix_len equ $-concrete_suffix
char_prefix: db 10,'section .text',10,'global nebo_identity_Char',10,'nebo_identity_Char:',10,'    mov rax, rdi',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    push rbp',10,'    mov rbp, rsp',10,'    mov rdi, '
char_prefix_len equ $-char_prefix
char_suffix: db 10,'    call nebo_identity_Char',10,'    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
char_suffix_len equ $-char_suffix
float_prefix: db 10,'section .text',10,'global nebo_identity_Float',10,'nebo_identity_Float:',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    push rbp',10,'    mov rbp, rsp',10,'    mov rax, '
float_prefix_len equ $-float_prefix
float_suffix: db 10,'    movq xmm0, rax',10,'    call nebo_identity_Float',10,'    xor eax, eax',10,'    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
float_suffix_len equ $-float_suffix
empty_program: db 10,'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    xor eax, eax',10,'    ret',10
empty_program_len equ $-empty_program
generics_constraints_overload_e_dispatch_hex_digits: db '0123456789abcdef'

section .data
hex_value: db '0x0000000000000000'
hex_value_len equ $-hex_value

section .text
; request*, bytes*, length -> status
g07c_append:
 mov rax,[rdi+neboc_generics_constraints_overload_e_dispatch_CODEGEN_WRITER_OFFSET]
 test rax,rax
 jz .bad
 mov rdi,rax
 jmp neboc_assembly_writer_append_bytes
.bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; RAX value -> stable 0x + 16 lowercase digits
g07c_format_hex:
 lea rdi,[rel hex_value+2+16]
 lea rsi,[rel generics_constraints_overload_e_dispatch_hex_digits]
 mov ecx,16
.loop:
 mov rdx,rax
 and edx,15
 mov dl,[rsi+rdx]
 dec rdi
 mov [rdi],dl
 shr rax,4
 dec ecx
 jnz .loop
 ret

NEBOC_ABI_FUNCTION neboc_generics_constraints_overload_e_dispatch_generic_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_generics_constraints_overload_e_dispatch_CODEGEN_VERTICAL_OFFSET]
 test r13,r13
 jz .invalid
 cmp qword [r13+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FOUND_OFFSET],1
 jne .invalid_source
 cmp qword [r13+neboc_generics_constraints_overload_e_dispatch_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .invalid_source
 test qword [r13+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FLAGS_OFFSET],NEBOC_VERTICAL_REQUIRED_FLAGS
 jz .invalid_source
 test qword [r13+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FLAGS_OFFSET],NEBOC_VERTICAL_FLAG_CALL_PRESENT
 jz .empty
 mov rax,[r13+NEBOC_VERTICAL_RECEIVER_DATA_OFFSET]
 call g07c_format_hex
 mov rax,[r13+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET]
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL
 je .bool
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_INT
 je .int
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT
 je .float
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR
 je .char
 jmp .invalid_source
.bool:
 lea r14,[rel bool_prefix]
 mov r15d,bool_prefix_len
 lea rbx,[rel bool_suffix]
 mov qword [rsp],bool_suffix_len
 jmp .emit
.int:
 cmp qword [r13+NEBOC_VERTICAL_SELECTED_OFFSET],NEBOC_SELECTED_CONCRETE
 je .concrete
 lea r14,[rel int_prefix]
 mov r15d,int_prefix_len
 lea rbx,[rel int_suffix]
 mov qword [rsp],int_suffix_len
 jmp .emit
.concrete:
 lea r14,[rel concrete_prefix]
 mov r15d,concrete_prefix_len
 lea rbx,[rel concrete_suffix]
 mov qword [rsp],concrete_suffix_len
 jmp .emit
.char:
 lea r14,[rel char_prefix]
 mov r15d,char_prefix_len
 lea rbx,[rel char_suffix]
 mov qword [rsp],char_suffix_len
 jmp .emit
.float:
 lea r14,[rel float_prefix]
 mov r15d,float_prefix_len
 lea rbx,[rel float_suffix]
 mov qword [rsp],float_suffix_len
.emit:
 mov rdi,r12
 mov rsi,r14
 mov rdx,r15
 call g07c_append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel hex_value]
 mov edx,hex_value_len
 call g07c_append
 test eax,eax
 jnz .writer
 mov rdi,r12
 mov rsi,rbx
 mov rdx,[rsp]
 call g07c_append
 test eax,eax
 jnz .writer
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_VERTICAL_SYMBOL_HASH_OFFSET]
 xor rax,[r13+NEBOC_VERTICAL_RECEIVER_DATA_OFFSET]
 mov [r12+neboc_generics_constraints_overload_e_dispatch_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.empty:
 mov rdi,r12
 lea rsi,[rel empty_program]
 mov edx,empty_program_len
 call g07c_append
 test eax,eax
 jnz .writer
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_CODEGEN_EMITTED_OFFSET],1
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_CODEGEN_ERROR_OFFSET],1
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_source:
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_CODEGEN_ERROR_OFFSET],2
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
