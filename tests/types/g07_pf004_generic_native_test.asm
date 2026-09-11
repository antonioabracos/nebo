; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF004 direct scalar specialization plan and System V ABI tests — 28 cases
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_api_contract.inc"
%include "compiler/lowering/generics/generic_ir_contract.inc"
%include "compiler/lowering/generics/generic_native_contract.inc"
%include "runtime/generics/generic_identity_runtime.inc"
extern neboc_generic_native_plan
extern neboc_identity_Bool
extern neboc_identity_Int
extern neboc_identity_Float
extern neboc_identity_Char
extern neboc_host_process_exit

%macro PLANCASE 4
 dq %1,%2,%3,%4
%endmacro
section .rodata align=8
plan_cases:
 PLANCASE neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL,NEBOC_ABI_CLASS_INTEGER,NEBOC_NATIVE_HELPER_BOOL,neboc_generics_constraints_overload_e_dispatch_NATIVE_REGISTER_RDI
 PLANCASE neboc_generics_constraints_overload_e_dispatch_TYPE_INT,NEBOC_ABI_CLASS_INTEGER,NEBOC_NATIVE_HELPER_INT,neboc_generics_constraints_overload_e_dispatch_NATIVE_REGISTER_RDI
 PLANCASE neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT,NEBOC_ABI_CLASS_SSE,NEBOC_NATIVE_HELPER_FLOAT,neboc_generics_constraints_overload_e_dispatch_NATIVE_REGISTER_XMM0
 PLANCASE neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR,NEBOC_ABI_CLASS_INTEGER,NEBOC_NATIVE_HELPER_CHAR,neboc_generics_constraints_overload_e_dispatch_NATIVE_REGISTER_RDI
plan_count equ ($-plan_cases)/(4*8)

int_values: dq 0,1,-1,0x7fffffffffffffff,0x8000000000000000
int_count equ ($-int_values)/8
bool_values: dq 0,1
bool_count equ ($-bool_values)/8
char_values: dq 0,0x7f,0x80,0xd7ff,0xe000,0x10ffff
char_count equ ($-char_values)/8
float_values: dq 0x0000000000000000,0x8000000000000000,0x3ff8000000000000,0x7ff0000000000000,0xfff0000000000000,0x7ff8000000000042
float_count equ ($-float_values)/8

section .bss align=16
native_request: resb neboc_generics_constraints_overload_e_dispatch_NATIVE_REQUEST_SIZE

section .text
fail:
 mov edi,r15d
 jmp neboc_host_process_exit

clear_request:
 lea rdi,[rel native_request]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_NATIVE_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 ret

global _start
_start:
 mov r15d,1
 lea r14,[rel plan_cases]
 mov r13d,plan_count
.plan_loop:
 call clear_request
 mov rax,[r14]
 mov [rel native_request+neboc_generics_constraints_overload_e_dispatch_NATIVE_TYPE_ID_OFFSET],rax
 mov qword [rel native_request+neboc_generics_constraints_overload_e_dispatch_NATIVE_TARGET_ID_OFFSET],NEBOC_TARGET_X86_64_SYSV
 mov qword [rel native_request+NEBOC_NATIVE_IR_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_IR_REQUIRED_FLAGS
 mov rax,[r14+8]
 mov [rel native_request+NEBOC_NATIVE_IR_ABI_CLASS_OFFSET],rax
 lea rdi,[rel native_request]
 call neboc_generic_native_plan
 test eax,eax
 jnz fail
 mov rax,[rel native_request+NEBOC_NATIVE_HELPER_ID_OFFSET]
 cmp rax,[r14+16]
 jne fail
 mov rax,[rel native_request+neboc_generics_constraints_overload_e_dispatch_NATIVE_PARAMETER_REGISTER_OFFSET]
 cmp rax,[r14+24]
 jne fail
 cmp qword [rel native_request+NEBOC_NATIVE_VALUE_WIDTH_OFFSET],8
 jne fail
 cmp qword [rel native_request+NEBOC_NATIVE_STACK_BYTES_OFFSET],0
 jne fail
 cmp qword [rel native_request+neboc_generics_constraints_overload_e_dispatch_NATIVE_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_NATIVE_REQUIRED_FLAGS
 jne fail
 add r14,32
 inc r15d
 dec r13d
 jnz .plan_loop

 ; Plan rejects bad flags, class, target, type and null (cases 5..9).
 mov r15d,5
 mov qword [rel native_request+NEBOC_NATIVE_IR_FLAGS_OFFSET],0
 lea rdi,[rel native_request]
 call neboc_generic_native_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 inc r15d
 mov qword [rel native_request+NEBOC_NATIVE_IR_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_IR_REQUIRED_FLAGS
 mov qword [rel native_request+NEBOC_NATIVE_IR_ABI_CLASS_OFFSET],NEBOC_ABI_CLASS_SSE
 lea rdi,[rel native_request]
 call neboc_generic_native_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 inc r15d
 mov qword [rel native_request+neboc_generics_constraints_overload_e_dispatch_NATIVE_TARGET_ID_OFFSET],99
 lea rdi,[rel native_request]
 call neboc_generic_native_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 inc r15d
 mov qword [rel native_request+neboc_generics_constraints_overload_e_dispatch_NATIVE_TARGET_ID_OFFSET],NEBOC_TARGET_X86_64_SYSV
 mov qword [rel native_request+neboc_generics_constraints_overload_e_dispatch_NATIVE_TYPE_ID_OFFSET],neboc_generics_constraints_overload_e_dispatch_TYPE_TEXT
 lea rdi,[rel native_request]
 call neboc_generic_native_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 inc r15d
 xor edi,edi
 call neboc_generic_native_plan
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail

 ; Each helper is a direct, allocation-free identity with stable ABI registers.
 mov rbx,0x1122334455667788
 mov r12,0x7766554433221100
 mov r15d,10
 lea r14,[rel bool_values]
 mov r13d,bool_count
.bool_loop:
 mov rdi,[r14]
 call neboc_identity_Bool
 cmp rax,[r14]
 jne fail
 add r14,8
 inc r15d
 dec r13d
 jnz .bool_loop

 lea r14,[rel int_values]
 mov r13d,int_count
.int_loop:
 mov rdi,[r14]
 call neboc_identity_Int
 cmp rax,[r14]
 jne fail
 add r14,8
 inc r15d
 dec r13d
 jnz .int_loop

 lea r14,[rel char_values]
 mov r13d,char_count
.char_loop:
 mov rdi,[r14]
 call neboc_identity_Char
 cmp rax,[r14]
 jne fail
 add r14,8
 inc r15d
 dec r13d
 jnz .char_loop

 lea r14,[rel float_values]
 mov r13d,float_count
.float_loop:
 movq xmm0,[r14]
 call neboc_identity_Float
 movq rax,xmm0
 cmp rax,[r14]
 jne fail
 add r14,8
 inc r15d
 dec r13d
 jnz .float_loop

 mov rax,0x1122334455667788
 cmp rbx,rax
 jne fail
 mov rax,0x7766554433221100
 cmp r12,rax
 jne fail
 xor edi,edi
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
