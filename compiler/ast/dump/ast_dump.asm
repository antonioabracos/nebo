; Nebo Assembly — MF020 canonical deterministic AST dump
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"
%include "compiler/ast/dump/ast_dump.inc"

extern neboc_ast_store_verify_immutable

section .rodata
ast_dump_header: db 'A','S','T','v','1',10
ast_dump_hex: db '0123456789abcdef'

section .text

; ast_dump_required_size(store*, out_size*)
NEBOC_ABI_FUNCTION neboc_ast_dump_required_size
 test rdi,rdi
 jz .required_invalid
 test rsi,rsi
 jz .required_invalid
 mov qword [rsi],0
 mov rax,[rdi+NEBOC_AST_STORE_COUNT_OFFSET]
 mov rcx,NEBOC_AST_DUMP_NODE_LINE_SIZE
 mul rcx
 test rdx,rdx
 jnz .required_limit
 add rax,NEBOC_AST_DUMP_HEADER_SIZE
 jc .required_limit
 mov [rsi],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.required_limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.required_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; ast_dump_canonical(AstDumpRequest*)
NEBOC_ABI_FUNCTION neboc_ast_dump_canonical
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .dump_invalid
 mov qword [r12+NEBOC_AST_DUMP_LENGTH_OFFSET],0
 mov r13,[r12+NEBOC_AST_DUMP_STORE_OFFSET]
 mov r14,[r12+NEBOC_AST_DUMP_BUFFER_OFFSET]
 mov r15,[r12+NEBOC_AST_DUMP_CAPACITY_OFFSET]
 test r13,r13
 jz .dump_invalid
 test r14,r14
 jz .dump_invalid
 mov rdi,r13
 call neboc_ast_store_verify_immutable
 test eax,eax
 jnz .dump_done
 mov qword [rsp],0
 mov rdi,r13
 lea rsi,[rsp]
 call neboc_ast_dump_required_size
 test eax,eax
 jnz .dump_done
 cmp r15,[rsp]
 jb .dump_limit

 lea rsi,[rel ast_dump_header]
 mov rdi,r14
 mov ecx,NEBOC_AST_DUMP_HEADER_SIZE
 rep movsb
 mov r15,rdi                         ; current output pointer
 mov rbx,1                           ; NodeId
.dump_node_loop:
 cmp rbx,[r13+NEBOC_AST_STORE_COUNT_OFFSET]
 ja .dump_finish
 mov rdi,r15
 mov rax,rbx
 call ast_dump_write_hex64
 mov r15,rdi
 mov rax,rbx
 dec rax
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,[r13+NEBOC_AST_STORE_DATA_OFFSET]
 mov r10,rax                         ; node pointer
 xor r11,r11                         ; qword field index
.dump_field_loop:
 mov byte [r15],'|'
 inc r15
 mov rax,[r10+r11*8]
 mov rdi,r15
 call ast_dump_write_hex64
 mov r15,rdi
 inc r11
 cmp r11,NEBOC_AST_NODE_QWORDS
 jb .dump_field_loop
 mov byte [r15],10
 inc r15
 inc rbx
 jmp .dump_node_loop
.dump_finish:
 mov rax,r15
 sub rax,r14
 mov [r12+NEBOC_AST_DUMP_LENGTH_OFFSET],rax
 cmp rax,[rsp]
 jne .dump_internal
 xor eax,eax
 jmp .dump_done
.dump_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .dump_done
.dump_internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .dump_done
.dump_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.dump_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Internal: RDI=destination, RAX=value. Returns RDI advanced by 16 bytes.
ast_dump_write_hex64:
 push rcx
 push rdx
 push r11
 lea r11,[rel ast_dump_hex]
 mov ecx,16
.hex_loop:
 mov rdx,rax
 shr rdx,60
 mov dl,[r11+rdx]
 mov [rdi],dl
 inc rdi
 shl rax,4
 dec ecx
 jnz .hex_loop
 pop r11
 pop rdx
 pop rcx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
