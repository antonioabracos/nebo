; C03-F02-A1 one-item private synthetic test runner planner.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/modules/test_runner_plan.inc"

section .rodata
tr_label_prefix: db 'nebo_test_runner_'
tr_label_prefix_len equ $-tr_label_prefix
tr_int: db 'Int'
tr_self: db 'self'
tr_hex: db '0123456789abcdef'

section .text

; test_runner_plan(request*) -> status.
NEBOC_ABI_FUNCTION neboc_test_runner_plan
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,40
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 test rbx,7
 jnz .invalid
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_FUNCTION_SYMBOL],0
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_TARGET_HASH],0
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_LABEL_LEN],0
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_ERROR],NEBOC_TEST_RUNNER_ERROR_NONE
 mov r12,[rbx+NEBOC_TEST_RUNNER_REQUEST_BUILDER]
 mov r13,[rbx+NEBOC_TEST_RUNNER_REQUEST_TOKENS]
 mov r14,[rbx+NEBOC_TEST_RUNNER_REQUEST_TOKEN_COUNT]
 mov r15,[rbx+NEBOC_TEST_RUNNER_REQUEST_SOURCE]
 test r12,r12
 jz .invalid_error
 test r13,r13
 jz .invalid_error
 test r15,r15
 jz .invalid_error
 mov rax,[rbx+NEBOC_TEST_RUNNER_REQUEST_TEST_PTR]
 test rax,rax
 jz .invalid_error
 mov rcx,[rbx+NEBOC_TEST_RUNNER_REQUEST_TEST_LEN]
 test rcx,rcx
 jz .invalid_error
 mov rax,[rbx+NEBOC_TEST_RUNNER_REQUEST_TARGET_PTR]
 test rax,rax
 jz .invalid_error
 mov rcx,[rbx+NEBOC_TEST_RUNNER_REQUEST_TARGET_LEN]
 test rcx,rcx
 jz .invalid_error
 mov rax,[rbx+NEBOC_TEST_RUNNER_REQUEST_LABEL]
 test rax,rax
 jz .invalid_error

 mov qword [rsp],0                    ; public function ordinal
 mov qword [rsp+8],0                  ; exact-name count
 mov qword [rsp+16],0                 ; valid match count
 mov qword [rsp+24],0                 ; selected symbol
 mov rbp,[r12+NEBOC_AST_BUILDER_DATA_OFFSET]
 mov r10,[r12+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r11d,r11d
.scan:
 cmp r11,r10
 jae .scan_done
 mov rax,r11
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,rbp
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .next
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jnz .next
 inc qword [rsp]
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rdx,r14
 jae .invalid_error
 mov rcx,rdx
 imul rcx,NEBOC_TOKEN_SIZE
 add rcx,r13
 cmp qword [rcx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .invalid_error
 mov rdi,[rbx+NEBOC_TEST_RUNNER_REQUEST_TEST_PTR]
 mov rsi,[rbx+NEBOC_TEST_RUNNER_REQUEST_TEST_LEN]
 mov rdx,[rcx+NEBOC_TOKEN_START_OFFSET]
 mov r8,[rcx+NEBOC_TOKEN_END_OFFSET]
 sub r8,rdx
 cmp r8,rsi
 jne .next
 add rdx,r15
 mov rcx,rsi
 mov rsi,rdx
 call .equal
 test eax,eax
 jz .next
 inc qword [rsp+8]

 ; Exact zero-parameter receiver-first (Int.self) function.
 mov rax,r11
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,rbp
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .next
 mov rdx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rdx,rdx
 jz .invalid_error
 dec rdx
 imul rdx,NEBOC_AST_NODE_SIZE
 add rdx,rbp
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RECEIVER
 jne .invalid_error
 mov rcx,[rdx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rcx,r14
 jae .invalid_error
 imul rcx,NEBOC_TOKEN_SIZE
 add rcx,r13
 lea rdi,[rel tr_int]
 mov esi,3
 mov rdx,[rcx+NEBOC_TOKEN_START_OFFSET]
 mov r8,[rcx+NEBOC_TOKEN_END_OFFSET]
 sub r8,rdx
 cmp r8,3
 jne .next
 add rdx,r15
 mov rcx,3
 mov rsi,rdx
 call .equal
 test eax,eax
 jz .next
 mov rax,r11
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,rbp
 mov rdx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 dec rdx
 imul rdx,NEBOC_AST_NODE_SIZE
 add rdx,rbp
 mov rcx,[rdx+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp rcx,r14
 jae .invalid_error
 imul rcx,NEBOC_TOKEN_SIZE
 add rcx,r13
 lea rdi,[rel tr_self]
 mov esi,4
 mov rdx,[rcx+NEBOC_TOKEN_START_OFFSET]
 mov r8,[rcx+NEBOC_TOKEN_END_OFFSET]
 sub r8,rdx
 cmp r8,4
 jne .next
 add rdx,r15
 mov rcx,4
 mov rsi,rdx
 call .equal
 test eax,eax
 jz .next
 inc qword [rsp+16]
 mov rax,[rsp]
 inc rax                              ; ordinal 1 -> SymbolId 2
 mov [rsp+24],rax
.next:
 inc r11
 jmp .scan

.scan_done:
 cmp qword [rsp+8],0
 je .not_found
 cmp qword [rsp+8],1
 ja .ambiguous
 cmp qword [rsp+16],1
 jne .signature

 mov rdi,[rbx+NEBOC_TEST_RUNNER_REQUEST_TARGET_PTR]
 mov rsi,[rbx+NEBOC_TEST_RUNNER_REQUEST_TARGET_LEN]
 call .fnv1a64
 mov [rbx+NEBOC_TEST_RUNNER_REQUEST_TARGET_HASH],rax
 mov rdi,[rbx+NEBOC_TEST_RUNNER_REQUEST_LABEL]
 lea rsi,[rel tr_label_prefix]
 xor ecx,ecx
.prefix:
 cmp rcx,tr_label_prefix_len
 jae .hex
 mov dl,[rsi+rcx]
 mov [rdi+rcx],dl
 inc rcx
 jmp .prefix
.hex:
 mov rdx,rax
 mov r8d,16
.hex_loop:
 mov r9,rdx
 and r9,15
 lea rsi,[rel tr_hex]
 mov r9b,[rsi+r9]
 mov r10,r8
 dec r10
 mov [rdi+tr_label_prefix_len+r10],r9b
 shr rdx,4
 dec r8
 jnz .hex_loop
 mov byte [rdi+tr_label_prefix_len+16],0
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_LABEL_LEN],tr_label_prefix_len+16
 mov rax,[rsp+24]
 mov [rbx+NEBOC_TEST_RUNNER_REQUEST_FUNCTION_SYMBOL],rax

 ; Fail closed if a source-level function name exactly equals the reserved
 ; generated label, even though ordinary functions lower to numeric labels.
 mov r10,[r12+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r11d,r11d
.collision_scan:
 cmp r11,r10
 jae .success
 mov rax,r11
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,rbp
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .collision_next
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rdx,r14
 jae .invalid_error
 imul rdx,NEBOC_TOKEN_SIZE
 add rdx,r13
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,tr_label_prefix_len+16
 jne .collision_next
 mov rsi,[rdx+NEBOC_TOKEN_START_OFFSET]
 add rsi,r15
 mov rdi,[rbx+NEBOC_TEST_RUNNER_REQUEST_LABEL]
 call .equal
 test eax,eax
 jnz .collision
.collision_next:
 inc r11
 jmp .collision_scan
.success:
 xor eax,eax
 jmp .done
.not_found:
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_ERROR],NEBOC_TEST_RUNNER_ERROR_NOT_FOUND
 jmp .source_error
.signature:
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_ERROR],NEBOC_TEST_RUNNER_ERROR_SIGNATURE
 jmp .source_error
.ambiguous:
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_ERROR],NEBOC_TEST_RUNNER_ERROR_AMBIGUOUS
 jmp .source_error
.collision:
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_ERROR],NEBOC_TEST_RUNNER_ERROR_COLLISION
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_error:
 test rbx,rbx
 jz .invalid
 mov qword [rbx+NEBOC_TEST_RUNNER_REQUEST_ERROR],NEBOC_TEST_RUNNER_ERROR_ARGUMENT
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.source_error:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi expected bytes, rsi actual bytes, rcx length.
.equal:
 xor edx,edx
.equal_loop:
 cmp rdx,rcx
 jae .equal_yes
 mov al,[rdi+rdx]
 cmp al,[rsi+rdx]
 jne .equal_no
 inc rdx
 jmp .equal_loop
.equal_yes:
 mov eax,1
 ret
.equal_no:
 xor eax,eax
 ret

.fnv1a64:
 mov rax,0xcbf29ce484222325
 mov r8,0x100000001b3
 xor ecx,ecx
.fnv_loop:
 cmp rcx,rsi
 jae .fnv_done
 movzx edx,byte [rdi+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .fnv_loop
.fnv_done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
